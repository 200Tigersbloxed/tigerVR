local ReplicatedStorage = game:GetService('ReplicatedStorage')
local WorkSpace = game:GetService('Workspace')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local AvatarTools = require(tigerVR.Avatar.AvatarTools)
local CacheLocations = require(tigerVR.InstanceCache.CacheLocations)
local Config = require(tigerVR.User.Config)

local module = {}

module.VRAvatarParts = {
	["Head"] = 0,
	["LeftHand"] = 1,
	["RightHand"] = 2
}

module.IK = nil

--[[
	This was going to be used to weld the Character to the dummy, however this restricts Character movement,
	so it was decided to scrap this idea. If you can figure out how to do this with character movement, please do!
]]
--[[function module:WeldModel(character, newdummy)
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") then
			if newdummy:FindFirstChild(part.Name) ~= nil then
				local dummypart = newdummy:FindFirstChild(part.Name)
				dummypart:PivotTo(part.CFrame)
				local att0 = Instance.new('Attachment')
				att0.Parent = part
				local att1 = Instance.new('Attachment')
				att1.Parent = dummypart
				local RigidConstraint = Instance.new('RigidConstraint')
				RigidConstraint.Attachment0 = att0
				RigidConstraint.Attachment1 = att1
				RigidConstraint.Parent = dummypart
				dummypart.Anchored = true
			else
				warn("Could not find part "..part.Name.." inside of the Dummy Avatar!")
			end
		end
	end
end]]

local function duplicateclothes(character, newdummy, pc)
	for _, object in character:GetChildren() do
		if object:IsA('Hat') or object:IsA('Accessory') then
			local allow = true
			for _, part in object:GetDescendants() do
				if part:IsA('WrapTarget') then allow = false end
				if part:IsA('WrapLayer') then allow = false end
			end
			if allow then object:Clone().Parent = newdummy end
		elseif object:IsA('Shirt') or object:IsA('Pants') or object:IsA('ShirtGraphic') then
			object:Clone().Parent = newdummy
		elseif object:IsA('BasePart') or object:IsA('MeshPart') then
			local clone = newdummy:FindFirstChild(object.Name)
			if clone then
				if clone:IsA('MeshPart') then
					clone:ApplyMesh(object)
				end
			end
			if object.Name == "Head" then
				for _, decal in pc:GetChildren() do
					if decal:IsA('Decal') then
						decal:Clone().Parent = newdummy.Head
					end
				end
				for _, decal in object:GetChildren() do
					if decal:IsA('Decal') then
						decal:Clone().Parent = newdummy.Head
						decal:Clone().Parent = pc
						decal:Destroy()
					end
				end
			end
		end
	end
	for _, specialeffect in character:GetDescendants() do
		if specialeffect:IsA('Sparkles') then specialeffect.Enabled = false end
		if specialeffect:IsA('Trail') then specialeffect.Enabled = false end
		if specialeffect:IsA('Smoke') then specialeffect.Enabled = false end
		if specialeffect:IsA('ParticleEmitter') then specialeffect.Enabled = false end
		if specialeffect:IsA('Beam') then specialeffect.Enabled = false end
	end
	for _, hat in newdummy:GetChildren() do
		if hat:IsA('Hat') or hat:IsA('Accessory') then
			for _, specialeffect in hat:GetDescendants() do
				if specialeffect:IsA('Sparkles') then specialeffect.Enabled = true end
				if specialeffect:IsA('Trail') then specialeffect.Enabled = true end
				if specialeffect:IsA('Smoke') then specialeffect.Enabled = true end
				if specialeffect:IsA('ParticleEmitter') then specialeffect.Enabled = true end
				if specialeffect:IsA('Beam') then specialeffect.Enabled = true end
			end
		end
	end
	if tigerVR.InstanceCache.EnableCustomNametags.Value then
		local nametag = tigerVR.InstanceCache.Nametag:Clone()
		nametag.Label.Text = Players:WaitForChild(character.Name).DisplayName
		nametag.Parent = newdummy.Head
	end
end

local function CreateWeld(part0, part1)
	local weld = Instance.new('WeldConstraint')
	weld.Part0 = part0
	weld.Part1 = part1
	weld.Name = part0.Name.."-"..part1.Name
	weld.Parent = part0
	part0.Anchored = false
end

function module:CreateVRAvatar(player, ignoreWelds)
	local character = WorkSpace:WaitForChild(player.Name)
	local newdummy = nil
	local rigtype = AvatarTools:GetPlayerRigType(player)
	if rigtype == Enum.HumanoidRigType.R6 then
		newdummy = tigerVR.InstanceCache.R6Dummy:Clone()
	elseif rigtype == Enum.HumanoidRigType.R15 then
		newdummy = tigerVR.InstanceCache.R15Dummy:Clone()
	else
		warn(player.Name.." does not have a valid HumanoidRigType! ("..tostring(rigtype)..") Cannot continue.")
		return false
	end
	newdummy.Name = player.Name
	local cacheFolder = CacheLocations:GetOrCreateUserCache(player)
	local pc = cacheFolder:WaitForChild("PlayerCache")
	newdummy.Parent = cacheFolder
	for _, part in character:GetChildren() do
		if part:IsA('Humanoid') then
			for _, thingy in part:GetChildren() do
				if thingy:IsA('HumanoidDescription') then
					local hd = thingy:Clone()
					hd.Parent = newdummy.Humanoid
					newdummy.Humanoid:ApplyDescription(hd)
				elseif thingy:IsA('NumberValue') then
					local nt = thingy:Clone()
					nt.Parent = newdummy.Humanoid
				end
			end
		end
	end
	newdummy:PivotTo(character.PrimaryPart:GetPivot())
	for _, part in newdummy:GetChildren() do
		if part:IsA('BasePart') or part:IsA('MeshPart') then
			--part.Transparency = 1
			part.Anchored = true
		end
	end
	if not ignoreWelds then
		--module:WeldModel(character, newdummy)
		if module.IK == nil and rigtype == Enum.HumanoidRigType.R15 then
			-- Weld Upper and Lowers
			-- + Left
			-- ++ LeftUpperArm -> LeftLowerArm
			local lupperarm = newdummy:WaitForChild('LeftUpperArm')
			local llowerarm = newdummy:WaitForChild('LeftLowerArm')
			CreateWeld(lupperarm, llowerarm)
			-- ++ LeftLowerArm -> LeftHand
			local lhand = newdummy:WaitForChild('LeftHand')
			CreateWeld(llowerarm, lhand)
			-- ++ LeftUpperLeg -> LeftLowerLeg
			local lupperleg = newdummy:WaitForChild('LeftUpperLeg')
			local llowerleg = newdummy:WaitForChild('LeftLowerLeg')
			CreateWeld(lupperleg, llowerleg)
			-- ++ LeftLowerLeg -> LeftFoot
			local lfoot = newdummy:WaitForChild('LeftFoot')
			CreateWeld(llowerleg, lfoot)
			-- + Right
			-- ++ RightUpperArm -> RightLowerArm
			local rupperarm = newdummy:WaitForChild('RightUpperArm')
			local rlowerarm = newdummy:WaitForChild('RightLowerArm')
			CreateWeld(rupperarm, rlowerarm)
			-- ++ RightLowerArm -> RightHand
			local rhand = newdummy:WaitForChild('RightHand')
			CreateWeld(rlowerarm, rhand)
			-- ++ RightUpperLeg -> RightLowerLeg
			local rupperleg = newdummy:WaitForChild('RightUpperLeg')
			local rlowerleg = newdummy:WaitForChild('RightLowerLeg')
			CreateWeld(rupperleg, rlowerleg)
			-- ++ RightLowerLeg -> RightFoot
			local rfoot = newdummy:WaitForChild('RightFoot')
			CreateWeld(rlowerleg, rfoot)
			-- + Torso
			-- ++ LowerTorso -> UpperTorso
			local ltorso = newdummy:WaitForChild('LowerTorso')
			local utorso = newdummy:WaitForChild('UpperTorso')
			CreateWeld(ltorso, utorso)
		end
	end
	duplicateclothes(character, newdummy, pc)
	tigerVR.Remotes.OnVRDummy:FireClient(player, newdummy)
	return newdummy
end

function module:DestroyVRAvatar(player)
	if AvatarTools:DoesPlayerHaveADummyAvatar(player) then
		AvatarTools:GetDummyAvatar(player):Destroy()
		tigerVR.Remotes.OnVRDummy:FireClient(player)
	end
end

function module:GetVRAvatar(player, getLocal)
	local userCache = CacheLocations:GetUserCache(player)
	local model
	if getLocal then
		model = userCache:FindFirstChild(player.Name.."-localdummy")
	else
		model = userCache:FindFirstChild(player.Name)
	end
	return model
end

function module.aligntorso_nofbt()
	if RunService:IsServer() then
		warn("aligntorso_nofbt is a derivative of FBT functions, which are not usable by the Server!")
		return
	end
	local model = module:GetVRAvatar(Players.LocalPlayer)
	local rigtype = AvatarTools:GetPlayerRigType(Players.LocalPlayer)
	if not model or not rigtype then return end
	if rigtype == Enum.HumanoidRigType.R6 then
		local head = model:WaitForChild('Head')
		local torso = model:WaitForChild('Torso')
		local cf = CFrame.new(Vector3.new(0, (head.Size.Y * -1) * 1.5, 0))
		torso.CFrame = head.CFrame:ToWorldSpace(cf)
	elseif rigtype == Enum.HumanoidRigType.R15 then
		local head = model:WaitForChild('Head')
		local uppertorso = model:WaitForChild('UpperTorso')
		local back = 0
		local ut_cf = CFrame.new(Vector3.new(0, (head.Size.Y * -1) * 1.29, back))
		uppertorso.CFrame = head.CFrame:ToWorldSpace(ut_cf)
	end
end

function module:AlignVRAvatarByVRAvatarPart(player, vravatarpart, cframe, isLocal)
	local rigtype = AvatarTools:GetPlayerRigType(player)
	local model = module:GetVRAvatar(player, isLocal)
	if not model or not rigtype then return end
	if vravatarpart == module.VRAvatarParts.Head then
		model:FindFirstChild('Head'):PivotTo(cframe)
	elseif vravatarpart == module.VRAvatarParts.LeftHand then
		if rigtype == Enum.HumanoidRigType.R6 then
			model:FindFirstChild('Left Arm'):PivotTo(cframe)
		elseif rigtype == Enum.HumanoidRigType.R15 then
			model:FindFirstChild('LeftHand'):PivotTo(cframe)
		end
	elseif vravatarpart == module.VRAvatarParts.RightHand then
		if rigtype == Enum.HumanoidRigType.R6 then
			model:FindFirstChild('Right Arm'):PivotTo(cframe)
		elseif rigtype == Enum.HumanoidRigType.R15 then
			model:FindFirstChild('RightHand'):PivotTo(cframe)
		end
	end
end

function module:AlignVRAvatarByPartName(player, partname, cframe)
	local model = module:GetVRAvatar(player)
	if not model then return end
	pcall(function()
		local p = model:FindFirstChild(partname)
		p:PivotTo(cframe)
	end)
end

function module:ReturnVRAvatarByPartName(player, partname)
	local model = module:GetVRAvatar(player)
	if not model then return end
	local e, r = pcall(function()
		local p = model:FindFirstChild(partname)
		return p
	end)
	return r
end

function module:GetAllCFrames(dummy)
	if RunService:IsServer() then
		warn("Cannot GetAllCFrames on the Server!")
		return
	end
	if not dummy then
		dummy = module:GetVRAvatar(Players.LocalPlayer)
	end
	if not dummy then return nil end
	local data = {}
	for _, part in dummy:GetChildren() do
		if part:IsA('BasePart') then
			data[part.Name] = part.CFrame
		end
	end
	return data
end

function module:ReplicateCFrames(player, cframes)
	local dummy = module:GetVRAvatar(player)
	if not dummy then return end
	for name, cframe in cframes do
		pcall(function()
			local part = dummy:FindFirstChild(name)
			if part then
				part:PivotTo(cframe)
			end
		end)
	end
end

local loadedanimtracks = {}
-- {["playerName"] = {["Corrugator"] = (track)}}

local function doesavatarhavedynamichead(charcter)
	local i = 0
	for _, part in charcter:GetDescendants() do
		if part:IsA('FaceControls') then
			i = i + 1
		end
	end
	return i > 0
end

function module:InitFacialTracking(player, pc)
	if RunService:IsClient() then
		warn("Cannot InitFacialTracking on Client")
		return
	end
	local character = WorkSpace:WaitForChild('StarterCharacter')
	if not doesavatarhavedynamichead(character) then
		warn("Character "..tostring(character.Name).." does not have any FaceControls!")
	end
	local humanoid = character:WaitForChild('Humanoid')
	local animator = humanoid:WaitForChild('Animator')
	for _, t in humanoid:GetPlayingAnimationTracks() do
		t:Stop()
	end
	humanoid.AnimationPlayed:Connect(function(animation)
		if animation.Name == "Animation" then
			animation:Stop()
		end
	end)
	loadedanimtracks[player.Name] = {}
	for _, animation in tigerVR.InstanceCache.FacialAnimations:GetChildren() do
		loadedanimtracks[player.Name][animation.Name] = animator:LoadAnimation(animation)
		loadedanimtracks[player.Name][animation.Name].Priority = Enum.AnimationPriority.Action
		loadedanimtracks[player.Name][animation.Name]:Play()
	end
end

function module:ReplicateFacialWeights(player, weights)
	if RunService:IsClient() then
		warn("Cannot ReplicateFacialWeights on Client")
		return
	end
	local character = WorkSpace:WaitForChild(player.Name)
	if not doesavatarhavedynamichead(character) then return end
	-- in this instance, weights is FaceWeights:GetChildren()
	for _, fw in weights do
		local playerAnims = loadedanimtracks[player.Name]
		if playerAnims then
			local track = playerAnims[fw.Name]
			if track then
				local v = fw.Value
				if fw.Value <= 0 then
					v = 0.0001
				elseif fw.Value > 1 then
					v = 1
				end
				track:AdjustWeight(v)
			end
		end
	end
end

local function visiblebase(rigtype, dummy, transparency)
	dummy:FindFirstChild('Head').Transparency = transparency
	if rigtype == Enum.HumanoidRigType.R6 then
		dummy:FindFirstChild('Left Arm').Transparency = transparency
		dummy:FindFirstChild('Right Arm').Transparency = transparency
		dummy:FindFirstChild('Torso').Transparency = transparency
	elseif rigtype == Enum.HumanoidRigType.R15 then
		dummy:FindFirstChild('LeftUpperArm').Transparency = transparency
		dummy:FindFirstChild('LeftLowerArm').Transparency = transparency
		dummy:FindFirstChild('LeftHand').Transparency = transparency
		dummy:FindFirstChild('RightUpperArm').Transparency = transparency
		dummy:FindFirstChild('RightLowerArm').Transparency = transparency
		dummy:FindFirstChild('RightHand').Transparency = transparency
		dummy:FindFirstChild('UpperTorso').Transparency = transparency
		dummy:FindFirstChild('LowerTorso').Transparency = transparency
	end
end

local function visiblelegs(rigtype, dummy, transparency)
	if rigtype == Enum.HumanoidRigType.R6 then
		dummy:FindFirstChild('Left Leg').Transparency = transparency
		dummy:FindFirstChild('Right Leg').Transparency = transparency
	elseif rigtype == Enum.HumanoidRigType.R15 then
		dummy:FindFirstChild('LeftUpperLeg').Transparency = transparency
		dummy:FindFirstChild('LeftLowerLeg').Transparency = transparency
		dummy:FindFirstChild('LeftFoot').Transparency = transparency
		dummy:FindFirstChild('RightUpperLeg').Transparency = transparency
		dummy:FindFirstChild('RightLowerLeg').Transparency = transparency
		dummy:FindFirstChild('RightFoot').Transparency = transparency
	end
end

local function shouldpartbevisible(partname, trackercount)
	if partname == "Head" then return true end
	if partname == "Left Arm" or partname == "LeftHand" or partname == "LeftUpperArm" or partname == "LeftLowerArm" then return true end
	if partname == "Right Arm" or partname == "RightHand" or partname == "RightUpperArm" or partname == "RightLowerArm" then return true end
	if partname == "Torso" or partname == "UpperTorso" or partname == "LowerTorso" then return true end
	if trackercount >= 2 then
		if partname == "Left Leg" or partname == "LeftFoot" or partname == "LeftUpperLeg" or partname == "LeftLowerLeg" then return true end
		if partname == "Right Leg" or partname == "RightFoot" or partname == "RightUpperLeg" or partname == "RightLowerLeg" then return true end
	end
end

-- TODO: Only hide things we need to
function module:SetVisibility(player, trackerCount)
	if AvatarTools:DoesPlayerHaveADummyAvatar(player) then
		local dummy = AvatarTools:GetDummyAvatar(player)
		local rigtype = AvatarTools:GetPlayerRigType(player)
		if not dummy or not rigtype then return end
		if RunService:IsClient() then
			--if trackerCount <= 0 or trackerCount == 1 then visiblebase(rigtype, dummy, 0.5) end
			visiblebase(rigtype, dummy, 0.5)
			if trackerCount >= 2 then visiblelegs(rigtype, dummy, 0.5) end
			for _, part in dummy:GetChildren() do
				if part:IsA('Hat') or part:IsA('Accessory') then
					if part:FindFirstChild('Handle') then
						part:FindFirstChild('Handle').Transparency = 1
					end
				end
			end 
		end
		if RunService:IsServer() then
			for _, part in WorkSpace:WaitForChild(player.Name):GetChildren() do
				if part:IsA('BasePart') then
					if dummy:FindFirstChild(part.Name) and part.Transparency < 1 then
						if shouldpartbevisible(part.Name, trackerCount) then
							dummy:FindFirstChild(part.Name).Transparency = part.Transparency
						end
						part.Transparency = 1
					end
					--[[if part.Name == "Head" then
						for _, decal in part:GetChildren() do
							if decal:IsA('Decal') then
								decal:Destroy()
							end
						end
					end]]
				elseif part:IsA('Hat') or part:IsA('Accessory') then
					if part:FindFirstChild('Handle') then
						part:FindFirstChild('Handle').Transparency = 1
					end
				end
			end
			for _, part in dummy:GetChildren() do
				if part:IsA('BasePart') then
					if not shouldpartbevisible(part.Name, trackerCount) then
						part.Transparency = 1
					end
				elseif part:IsA('Hat') or part:IsA('Accessory') then
					for _, hp in part:GetChildren() do
						if hp:IsA('BasePart') then hp.Transparency = 0 end
					end
				end
			end 
		end
	end
end

return module