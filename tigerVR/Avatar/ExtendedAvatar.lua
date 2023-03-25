local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local WorkSpace = game:GetService('Workspace')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local AvatarTools = require(tigerVR.Avatar.AvatarTools)
local AvatarInstance = require(tigerVR.Avatar.AvatarInstance)
local Config = require(tigerVR.User.Config)
local DataConversion = require(tigerVR.Net.DataConversion)
local AnimationTool = require(tigerVR.Animation.AnimationTool)

local module = {}

module.TrackerBodyPart = {
	Torso = 0,
	LeftFoot = 1,
	RightFoot = 2
}

local function failfbt(player)
	if AvatarTools:DoesPlayerHaveADummyAvatar(player) then
		AvatarInstance:DestroyVRAvatar(player)
	end
	AvatarInstance:CreateVRAvatar(player)
	local playercache = Config:GetOrCreatePlayerCache(player)
	if not playercache then return end
	playercache.CalibrationState.Value = 0
	playercache.CalibrationDummy = nil
end

local function getpc()
	if RunService:IsClient() then
		local playerCache = Config.GetOrCreatePlayerCache(nil, Players.LocalPlayer)
		return playerCache
	end
end

function module:BeginFBTCalibration()
	if RunService:IsServer() then
		warn("FBT Calibration can only be done by the Client!")
		return
	end
	tigerVR.Remotes.FBT.Begin:FireServer()
	--[[
	wait(0.6)
	local avatar = AvatarInstance:GetVRAvatar(Players.LocalPlayer)
	local pc = getpc()
	if pc == nil or avatar == nil then return end
	local rig = AvatarTools:GetPlayerRigType(Players.LocalPlayer)
	local folder
	if rig == Enum.HumanoidRigType.R6 then
		folder = pc['OriginalCFrames']['R6']
	elseif rig == Enum.HumanoidRigType.R15 then
		folder = pc['OriginalCFrames']['R15']
	else
		warn('No valid HumanoidRigType! Original CFrames will be broken!')
		return
	end
	-- Set the Part CFrames back to origin
	for _, part in avatar:GetChildren() do
		if part:IsA('BasePart') then
			local val = folder:FindFirstChild(part.Name)
			if val ~= nil then
				part:PivotTo(val.Value)
			end
		end
	end]]
end

local function getlmcp(lm)
	local humanoid = lm:FindFirstChild('Humanoid')
	if humanoid then
		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			return lm:FindFirstChild('Torso'), lm:FindFirstChild('Left Leg'), lm:FindFirstChild('Right Leg')
		elseif humanoid.RigType == Enum.HumanoidRigType.R15 then
			return lm:FindFirstChild('UpperTorso'), lm:FindFirstChild('vr_leftfoot'), lm:FindFirstChild('vr_rightfoot')
		else
			return nil, nil, nil
		end
	end
end

-- it works, but is this logic correct?
local function findclosesttracker(part, trackers)
	local closestTracker
	local closestTrackerMag = 0
	for _, tracker in trackers do
		local mag = (part.Position - tracker.Position).Magnitude
		if not closestTracker then
			closestTracker = tracker
			closestTrackerMag = mag
		elseif mag < closestTrackerMag then
			closestTracker = tracker
			closestTrackerMag = mag
		end
	end
	if closestTracker:FindFirstChild('WeldConstraint') then return nil end
	return closestTracker
end

local function weldtrackertoart(tracker, part)
	local wc = Instance.new('WeldConstraint', tracker)
	wc.Part0 = tracker
	wc.Part1 = part
	return wc
end

function module:ApplyFBTCalibration(trackers)
	if RunService:IsServer() then
		warn("FBT Calibration can only be done by the Client!")
		return
	end
	local playercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer)
	if not playercache then return end
	local newdummy = playercache.CalibrationDummy.Value
	-- remove old welds
	for _, tracker in trackers do
		for _, child in tracker:GetChildren() do
			if child:IsA('WeldConstraint') then
				child:Destroy()
			end
		end
	end
	-- make new welds
	local torso, leftfoot, rightfoot = getlmcp(newdummy)
	if not torso or not leftfoot or not rightfoot then failfbt() return end
	local torsoTracker = nil
	local leftFootTracker = nil
	local rightFootTracker = nil
	if #trackers <= 0 then
		failfbt()
	elseif #trackers == 1 then
		-- Align only the torso
		torsoTracker = findclosesttracker(torso, trackers)
		if torsoTracker then
			torsoTracker:WaitForChild('CalibratedTo').Value = torso
			weldtrackertoart(torsoTracker, torso)
			torso.Anchored = false
		end
	elseif #trackers == 2 then
		-- Align LeftFoot and RightFoot
		leftFootTracker = findclosesttracker(leftfoot, trackers)
		if leftFootTracker then
			leftFootTracker:WaitForChild('CalibratedTo').Value = leftfoot
			weldtrackertoart(leftFootTracker, leftfoot)
			leftfoot.Anchored = false
		end
		rightFootTracker = findclosesttracker(rightfoot, trackers)
		if rightFootTracker then
			rightFootTracker:WaitForChild('CalibratedTo').Value = rightfoot
			weldtrackertoart(rightFootTracker, rightfoot)
			rightfoot.Anchored = false
		end
	elseif #trackers == 3 then
		-- Align Torso, LeftFoot, and RightFoot
		torsoTracker = findclosesttracker(torso, trackers)
		if torsoTracker then
			torsoTracker:WaitForChild('CalibratedTo').Value = torso
			weldtrackertoart(torsoTracker, torso)
			torso.Anchored = false
		end
		leftFootTracker = findclosesttracker(leftfoot, trackers)
		if leftFootTracker then
			leftFootTracker:WaitForChild('CalibratedTo').Value = leftfoot
			weldtrackertoart(leftFootTracker, leftfoot)
			leftfoot.Anchored = false
		end
		rightFootTracker = findclosesttracker(rightfoot, trackers)
		if rightFootTracker then
			rightFootTracker:WaitForChild('CalibratedTo').Value = rightfoot
			weldtrackertoart(rightFootTracker, rightfoot)
			rightfoot.Anchored = false
		end
	end
	tigerVR.Remotes.FBT.Finish:FireServer()
end

function module:CreateTrackers(data)
	if RunService:IsServer() then
		warn("Cannot CreateTrackers on Server!")
		return
	end
	local count = #data['Trackers']
	local playercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer) 
	if not playercache then return end
	local folder = playercache:FindFirstChild('ExtendedTracking'):FindFirstChild('Trackers')
	for _, trackerProperty in data['Trackers'] do
		local tracker = folder:FindFirstChild(trackerProperty['Name'])
		if not tracker then
			tracker = tigerVR.InstanceCache.TemplateTracker:Clone()
			tracker.Name = trackerProperty['Name']
			tracker.Parent = folder
		end
	end
end

function module:GetTrackers()
	if RunService:IsServer() then
		warn("Cannot GetTrackers on Server!")
		return
	end
	local playercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer) 
	if not playercache then return end
	return playercache:FindFirstChild('ExtendedTracking'):FindFirstChild('Trackers'):GetChildren()
end

function module:AlignTrackersInWorld(trackerdata, animspeed)
	if RunService:IsServer() then
		warn("Cannot AlignTrackersInWorld on Server!")
		return
	end
	if not animspeed then animspeed = 0.1 end
	local playercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer) 
	if not playercache then return end
	local folder = playercache:FindFirstChild('ExtendedTracking'):FindFirstChild('Trackers')
	if not folder then return end
	for _, trackerProperty in trackerdata['Trackers'] do
		local tracker = folder:FindFirstChild(trackerProperty['Name'])
		if tracker then
			-- https://devforum.roblox.com/t/how-do-you-get-the-exact-position-of-the-controllers-in-vr/95209/9
			local v3 = DataConversion.double3toVector3(trackerProperty['Position']) * math.pi
			local qX, qY, qZ, qW = DataConversion.double4toFloats(trackerProperty['Rotation'])
			local trackercframe = CFrame.new(v3.X, v3.Y, v3.Z, -qX, -qY, qZ, qW)
			local HeadScale = WorkSpace.CurrentCamera.HeadScale
			local cframe = (WorkSpace.CurrentCamera.CFrame*CFrame.new(trackercframe.p*HeadScale))*CFrame.fromEulerAnglesXYZ(trackercframe:ToEulerAnglesXYZ())
			if AnimationTool:IsPartBeingAnimated(tracker) then
				while wait() do
					if not AnimationTool:IsPartBeingAnimated(tracker) then
						break
					end
				end
			end
			AnimationTool:AnimatePart(tracker, cframe, animspeed)
		end
	end
end

function module:GetTrackerByTrackerBodyPart(trackerBodyPart)
	if RunService:IsServer() then
		warn("Cannot GetTrackerByTrackerBodyPart on Server!")
		return
	end
	local playercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer) 
	if not playercache then return end
	local folder = playercache:FindFirstChild('ExtendedTracking'):FindFirstChild('Trackers')
	if not folder then return end
	for _, tracker in folder:GetChildren() do
		local trackerAttachment = tracker:WaitForChild('CalibratedTo').Value
		if trackerAttachment then
			if trackerBodyPart == module.TrackerBodyPart.Torso then
				if trackerAttachment.Name == "UpperTorso" or trackerAttachment.Name == "Torso" then
					return tracker
				end
			elseif trackerBodyPart == module.TrackerBodyPart.LeftFoot then
				if trackerAttachment.Name == "LeftFoot" or trackerAttachment.Name == "Left Leg" then
					return tracker
				end
			elseif trackerBodyPart == module.TrackerBodyPart.RightFoot then
				if trackerAttachment.Name == "RightFoot" or trackerAttachment.Name == "Right Leg" then
					return tracker
				end
			end
		else
			return
		end
	end
end

function module:ApplyFaceWeights(data, animspeed)
	if RunService:IsServer() then
		warn("Cannot ApplyFaceWeights on Server!")
		return
	end
	if not animspeed then animspeed = 0.1 end
	local playercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer) 
	if not playercache then return end
	local folder = playercache:FindFirstChild('ExtendedTracking'):FindFirstChild('FaceWeights')
	if not folder then return end
	for _, faceWeight in data['FaceWeights'] do
		local name = faceWeight['Name']
		local value = tonumber(faceWeight['Value'])
		local fw = folder:FindFirstChild(name)
		if fw then
			if AnimationTool:IsPartBeingAnimated(fw) then
				while wait() do
					if not AnimationTool:IsPartBeingAnimated(fw) then
						break
					end
				end
			end
			AnimationTool:AnimateNumberValue(fw, value, animspeed)
		end
	end
end

return module