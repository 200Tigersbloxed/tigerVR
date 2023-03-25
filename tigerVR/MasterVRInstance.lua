local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local WorkSpace = game:GetService('Workspace')
local Players = game:GetService('Players')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local CacheLocations = require(tigerVR.InstanceCache.CacheLocations)
local AvatarTools = require(tigerVR.Avatar.AvatarTools)
local AvatarInstance = require(tigerVR.Avatar.AvatarInstance)
local ExtendedAvatar = require(tigerVR.Avatar.ExtendedAvatar)
local AvatarIK = require(tigerVR.Avatar.AvatarIK)
local Config = require(tigerVR.User.Config)
local VR = require(tigerVR.User.VR)
local NetworkInterface = require(tigerVR.Net.NetworkInterface)
local MenuCreator = require(tigerVR.UX.MenuCreator)
local Bindings = require(tigerVR.User.Bindings)
local Collisions = require(tigerVR.Physics.Collisions)
local Raycasting = require(tigerVR.Physics.Raycasting)

local module = {}

local didInit = false

local function getconfig()
	if RunService:IsClient() then
		local playerCache = Config.GetOrCreatePlayerCache(nil, Players.LocalPlayer)
		playerCache.IsVR.Value = VR.isVR()
		local config = Config.CreateConfigData(playerCache.IsVR.Value, playerCache.Debug.Value, playerCache.ExtendTracking.Value)
		return config
	end
end

local function startclient()
	local config = getconfig()
	if config['IsVR'] or config['Debug'] then
		tigerVR.Remotes.InitVR:FireServer()
		if not config['Debug'] then
			Players.LocalPlayer.CameraMinZoomDistance = 0
			Players.LocalPlayer.CameraMaxZoomDistance = 0
		end
	end
end

local function ischildbyname(folder, name)
	for _, part in folder:GetChildren() do
		if part.Name == name then
			return true
		end
	end
	return false
end

local function fromnames(ps)
	local t = {}
	for _, p in ps do
		table.insert(t, p.Name)
	end
	return t
end

local function getfaceweights(fw)
	if RunService:IsClient() then
		local weights = {}
		for _, weight in fw do
			weights[weight.Name] = {["Name"] = weight.Name, ["Value"] = weight.Value}
		end
		return weights
	end
end

local tools = {}

local function scanTools()
	local char = Players.LocalPlayer.Character
	if char then
		for _, tool in char:GetChildren() do
			if tool:IsA('Tool') then
				if not table.find(tools, tool) then
					table.insert(tools, tool)
					tigerVR.Remotes.OnToolEvent:FireServer(true)
					tool.Unequipped:Connect(function()
						table.remove(tools, table.find(tools, tool))
					end)
				end
			end
		end
	end
end

-- client-only pc
local pc

local function initremotes()
	if not didInit then
		if RunService:IsServer() then
			-- InitVR should be snappable on respawn
			tigerVR.Remotes:WaitForChild('InitVR').OnServerEvent:Connect(function(player)
				local playerConfig = Config:GetOrCreatePlayerCache(player)
				playerConfig.IsVR.Value = true
				if not AvatarTools:DoesPlayerHaveADummyAvatar(player) then
					local newdummy = AvatarInstance:CreateVRAvatar(player)
				end
			end)
			
			tigerVR.Remotes.OnPlayerFrame.OnServerEvent:Connect(function(player, playerConfig, localmodelcframes, trackerCount)
				Config.UpdateConfig(player, playerConfig)
				AvatarInstance:ReplicateCFrames(player, localmodelcframes)
				AvatarInstance:SetVisibility(player, trackerCount)
				--if facialweights then AvatarInstance:ReplicateFacialWeights(player, facialweights) end
			end)
			
			tigerVR.Remotes.RequestExtendedData.OnServerEvent:Connect(function(player, enable)
				local ss = CacheLocations:GetOrCreateServerCache()
				local f = ss:FindFirstChild('ExtendedPlayers')
				if not f then
					f = Instance.new('Folder')
					f.Name = "ExtendedPlayers"
					f.Parent = ss
				end
				local pc = Config:GetOrCreatePlayerCache(player)
				if enable then
					pc.ExtendTracking.Value = true
					local np = Instance.new("StringValue")
					np.Name = player.Name
					np.Parent = f
				else
					pc.ExtendTracking.Value = false
					if ischildbyname(f, player.Name) then
						f[player.Name]:Destroy()
					end
				end
			end)
			
			tigerVR.Remotes.ResetAvatar.OnServerEvent:Connect(function(player)
				if AvatarTools:DoesPlayerHaveADummyAvatar(player) then
					AvatarInstance:DestroyVRAvatar(player)
				end
				wait(0.2)
				AvatarInstance:CreateVRAvatar(player)
			end)
			
			tigerVR.Remotes.OnToolEvent.OnServerEvent:Connect(function(player)
				local character = WorkSpace:WaitForChild(player.Name)
				local model = AvatarInstance:GetVRAvatar(player)
				local rig = AvatarTools:GetPlayerRigType(player)
				local source
				local target
				if rig == Enum.HumanoidRigType.R6 then
					source = character:WaitForChild("Right Arm")
					target = model:WaitForChild("Right Arm")
				elseif rig == Enum.HumanoidRigType.R15 then
					source = character:WaitForChild("RightHand")
					target = model:WaitForChild("RightHand")
				end
				if source and target then
					local grip = source:FindFirstChild("RightGrip")
					if grip then
						grip.Part0 = target
						grip.Parent = target
					end
				end
			end)
			
			tigerVR.Remotes.FBT.Begin.OnServerEvent:Connect(function(player)
				local playercache = Config:GetOrCreatePlayerCache(player)
				if AvatarTools:DoesPlayerHaveADummyAvatar(player) then
					AvatarInstance:DestroyVRAvatar(player)
				end
				if playercache.CalibrationDummy.Value ~= nil then
					playercache.CalibrationDummy.Value:Destroy()
				end
				playercache.CalibrationState.Value = 1
				wait(0.5)
				local newdummy = AvatarInstance:CreateVRAvatar(player)
				playercache.CalibrationDummy.Value = newdummy
				local char = WorkSpace:WaitForChild(player.Name)
			end)
			
			tigerVR.Remotes.FBT.Finish.OnServerEvent:Connect(function(player)
				local playercache = Config:GetOrCreatePlayerCache(player)
				playercache.CalibrationState.Value = 2
				local dummy = AvatarTools:GetDummyAvatar(player)
				AvatarIK:ApplyIKToModel(dummy)
			end)
			
			Players.PlayerAdded:Connect(function(player)
				local pcs = Config:GetOrCreatePlayerCache(player)
				
				player.CharacterAdded:Connect(function(character)
					-- Facial Tracking is a WIP
					--AvatarInstance:InitFacialTracking(player, pc)
				end)
				
				player.CharacterRemoving:Connect(function(character)
					AvatarInstance:DestroyVRAvatar(player)
					pcs.CalibrationState.Value = 0
				end)
			end)
			
			Players.PlayerRemoving:Connect(function(player)
				-- Remove their User Config and Player Config
				local uc = CacheLocations:GetUserCache(player)
				if uc then
					uc:Destroy()
				end
				-- Remove them from ExtendedTracking Players (if registered)
				local ss = CacheLocations:GetOrCreateServerCache()
				local f = ss:FindFirstChild('ExtendedPlayers')
				if f then
					for _, val in f:GetChildren() do
						if val.Name == player.Name then
							val:Destroy()
						end
					end
				end
			end)
			coroutine.wrap(function()
				while wait(NetworkInterface.refreshtime) do
					pcall(function()
						local ss = CacheLocations:GetOrCreateServerCache()
						local f = ss:FindFirstChild('ExtendedPlayers')
						if f then
							NetworkInterface:ApplyUserTrackingInfo(fromnames(f:GetChildren()))
						end
					end)
				end
			end)()
		end
		if RunService:IsClient() then
			while wait() do 
				local b = Config.DoesPlayerHaveCache(nil, Players.LocalPlayer)
				if b then
					pc = Config:GetOrCreatePlayerCache(Players.LocalPlayer)
					break
				end
			end
			--Players.LocalPlayer.CharacterAdded:Wait()
			startclient()
			
			tigerVR.Remotes.OnVRDummy.OnClientEvent:Connect(function(dummy)
				if dummy then
					-- Created
					MenuCreator.CreateMenu()
					if dummy.Head:FindFirstChild("Nametag") ~= nil then
						require(dummy.Head.Nametag.TXVRUIModule).init()
					end
					-- Set original
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
					for _, part in dummy:GetChildren() do
						if part:IsA('BasePart') then
							local val = folder:FindFirstChild(part.Name)
							if val ~= nil then
								val.Value = part.CFrame
							end
						end
					end
				else
					-- Destroyed
					local folder = pc["ExtendedTracking"]['Trackers']
					if folder then
						for _, tracker in folder:GetChildren() do
							for _, c in tracker:GetChildren() do
								if c:IsA('WeldConstraint') then
									c:Destroy()
								elseif c:IsA('ObjectValue') then
									c.Value = nil
								end
							end
						end
					end
				end
			end)
			
			tigerVR.Remotes:WaitForChild('OnExtendedData').OnClientEvent:Connect(function(netextendedtrackingdata)
				local ot = pc.OverrideExtendTracking.Value
				if ot == true then return end
				ExtendedAvatar:CreateTrackers(netextendedtrackingdata)
				ExtendedAvatar:AlignTrackersInWorld(netextendedtrackingdata)
			end)
			
			Players.LocalPlayer.CharacterAdded:Connect(function(char)
				startclient()
			end)
			
			Players.LocalPlayer.CharacterRemoving:Connect(function(character)
				for _, tracker in pc.ExtendedTracking.Trackers:GetChildren() do
					tracker:Destroy()
				end
			end)
			
			RunService.RenderStepped:Connect(function()
				if not pc then
					while wait() do
						local b = Config.DoesPlayerHaveCache(nil, Players.LocalPlayer)
						if b then
							pc = b
							break
						end
					end
				end
				-- Only Align if we have an Avatar to Align, and we're not Calibrating FBT
				if AvatarTools:DoesPlayerHaveADummyAvatar(Players.LocalPlayer) then
					local rig = AvatarTools:GetPlayerRigType(Players.LocalPlayer)
					local vrcf = VR:GetVRCFrames()
					AvatarInstance:AlignVRAvatarByVRAvatarPart(Players.LocalPlayer, AvatarInstance.VRAvatarParts.Head, vrcf['Head'])
					if rig == Enum.HumanoidRigType.R6 then
						AvatarInstance:AlignVRAvatarByVRAvatarPart(Players.LocalPlayer, AvatarInstance.VRAvatarParts.LeftHand, vrcf['LeftHand'])
						AvatarInstance:AlignVRAvatarByVRAvatarPart(Players.LocalPlayer, AvatarInstance.VRAvatarParts.RightHand, vrcf['RightHand'])
					end
					AvatarInstance:AlignVRAvatarByPartName(Players.LocalPlayer, "vr_lefthand", vrcf['LeftHand'])
					AvatarInstance:AlignVRAvatarByPartName(Players.LocalPlayer, "vr_righthand", vrcf['RightHand'])
					local trackerCount = #pc.ExtendedTracking.Trackers:GetChildren()
					if pc.CalibrationState.Value == 1 then
						local dummy = AvatarInstance:GetVRAvatar(Players.LocalPlayer)
						local leftFoot
						local rightFoot
						if rig == Enum.HumanoidRigType.R6 then
							leftFoot = dummy:WaitForChild("Left Leg")
							rightFoot = dummy:WaitForChild("Right Leg")
						elseif rig == Enum.HumanoidRigType.R15 then
							leftFoot = dummy:WaitForChild("LeftFoot")
							rightFoot = dummy:WaitForChild("RightFoot")
						end
						local vr_leftfoot = dummy:WaitForChild("vr_leftfoot")
						local vr_rightfoot = dummy:WaitForChild("vr_rightfoot")
						vr_leftfoot:PivotTo(leftFoot.CFrame)
						vr_rightfoot:PivotTo(rightFoot.CFrame)
					end
					local cframes = AvatarInstance:GetAllCFrames()
					tigerVR.Remotes.OnPlayerFrame:FireServer(getconfig(), cframes, trackerCount)
					-- Facial Tracking is a WIP
					--local weights = pc.ExtendedTracking.FaceWeights:GetChildren()
					--tigerVR.Remotes.OnPlayerFrame:FireServer(getconfig(), cframes, getfaceweights(weights))
					AvatarInstance:ReplicateCFrames(Players.LocalPlayer, cframes)
					if pc.CalibrationState.Value == 0 and (trackerCount >= 0 or trackerCount == 2) then
						AvatarInstance.aligntorso_nofbt()
					end
					AvatarInstance:SetVisibility(Players.LocalPlayer, trackerCount, 0.5)
					local menu = MenuCreator:GetMenu()
					local head = AvatarInstance:ReturnVRAvatarByPartName(Players.LocalPlayer, "Head")
					if menu and head then
						local parts = {}
						local e, model = pcall(function()
							return AvatarTools.GetDummyAvatar(nil, Players.LocalPlayer)
						end)
						if model then
							for _, part in model:GetDescendants() do
								if part:IsA('BasePart') then
									if part.Name ~= "tvrwindow" then table.insert(parts, part) end
								end
							end
						end
						for _, part in workspace:WaitForChild(Players.LocalPlayer.Name):GetDescendants() do
							if part:IsA('BasePart') then
								table.insert(parts, part)
							end
						end
						local b, r = Raycasting.IsPartFacingPart(nil, head, menu, parts)
						if b then
							menu.SurfaceGui.Enabled = true
						else
							menu.SurfaceGui.Enabled = false
						end
					end
					scanTools()
				end
			end)
		end
		didInit = true
	end
end

function module:run()
	initremotes()
	if RunService:IsServer() then
		-- Disable Collision with Dummy Models
		Collisions.Init()
		NetworkInterface:init()
	end
	if RunService:IsClient() then
		Bindings.Setup()
		Bindings:AddKeyCode(Enum.KeyCode.ButtonL3, "jump", function()
			local humanoid = Players.LocalPlayer.Character:WaitForChild('Humanoid')
			local s = humanoid:GetState()
			if s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall then return end
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end)
	end
end

function module:ApplyConfig(config)
	if RunService:IsServer() then
		if config.EnableCustomNametags then tigerVR.InstanceCache.EnableCustomNametags.Value = config.EnableCustomNametags end
	end
end

return module