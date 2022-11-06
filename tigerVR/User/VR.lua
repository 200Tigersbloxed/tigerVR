local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VRService = game:GetService('VRService')
local RunService = game:GetService('RunService')
local WorkSpace = game:GetService('Workspace')
local Players = game:GetService('Players')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local AvatarTools = require(tigerVR.Avatar.AvatarTools)
local Config = require(tigerVR.User.Config)

local module = {}

function module.isVR()
	if RunService:IsServer() then
		warn("Cannot isVR from Server! Please use a RemoteEvent or hook into OnPlayerFrame.")
		return
	end
	return VRService.VREnabled
end

function module:GetVRCFrames()
	if RunService:IsServer() then
		warn("Cannot GetVRCFrames from Server! Please use a RemoteEvent or hook into OnPlayerFrame.")
		return
	end
	local rigtype = AvatarTools:GetPlayerRigType(Players.LocalPlayer)
	local HeadScale = WorkSpace.CurrentCamera.HeadScale
	local cfHMD = VRService:GetUserCFrame(Enum.UserCFrame.Head)
	local cfLH = VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
	local cfRH = VRService:GetUserCFrame(Enum.UserCFrame.RightHand)
	local data = {
		["Head"] = (WorkSpace.CurrentCamera.CFrame*CFrame.new(cfHMD.p*HeadScale))*CFrame.fromEulerAnglesXYZ(cfHMD:ToEulerAnglesXYZ()),
		["LeftHand"] = (WorkSpace.CurrentCamera.CFrame*CFrame.new(cfLH.p*HeadScale))*CFrame.fromEulerAnglesXYZ(cfLH:ToEulerAnglesXYZ())
			* CFrame.Angles(math.rad(90), 0, 0),
		["RightHand"] = (WorkSpace.CurrentCamera.CFrame*CFrame.new(cfRH.p*HeadScale))*CFrame.fromEulerAnglesXYZ(cfRH:ToEulerAnglesXYZ())
			* CFrame.Angles(math.rad(90), 0, 0)
	}
	if rigtype == Enum.HumanoidRigType.R6 then
		data['LeftHand'] = data['LeftHand'] * CFrame.new(Vector3.new(0, 1, 0))
		data['RightHand'] = data['RightHand'] * CFrame.new(Vector3.new(0, 1, 0))
	end
	return data
end

function module:GetExtendedTracking()
	if RunService:IsServer() then
		warn("Cannot GetExtendedTracking from Server! Please use a RemoteEvent or hook into OnPlayerFrame.")
		return
	end
	local usercache = Config:GetOrCreatePlayerCache(Players.LocalPlayer)
	if not usercache then return nil end
	local isET = usercache:FindFirstChild('ExtendTracking').Value
	if not isET or isET == false then return nil end
	local data = {
		["Trackers"] = {},
		["FaceWeights"] = {}
	}
	local et = usercache:FindFirstChild('ExtendedTracking')
	if not et then return nil end
	for _, part in et:FindFirstChild('Trackers'):GetChildren() do
		if part:IsA('BasePart') then
			table.insert(data["Trackers"], part)
		end
	end
	for _, weight in et:FindFirstChild('FaceWeights'):GetChildren() do
		if weight:IsA('NumberValue') then
			table.insert(data['FaceWeights'], {
				['Weight'] = weight.Name,
				['Value'] = weight.Value
			})
		end
	end
	return data
end

return module
