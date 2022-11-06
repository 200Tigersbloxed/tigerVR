local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local AvatarInstance = require(tigerVR.Avatar.AvatarInstance)
local AvatarTools = require(tigerVR.Avatar.AvatarTools)

local module = {}

function module:CreateMenu()
	if RunService:IsServer() then
		warn("Cannot CreateMenu on Server!")
		return
	end
	local model = AvatarInstance:GetVRAvatar(Players.LocalPlayer)
	local rigtype = AvatarTools:GetPlayerRigType(Players.LocalPlayer)
	if model then
		local newMenu = tigerVR.InstanceCache:FindFirstChild('tvrwindow'):Clone()
		newMenu.Parent = model
		local arm
		if rigtype == Enum.HumanoidRigType.R6 then
			arm = model:WaitForChild('Left Arm')
		elseif rigtype == Enum.HumanoidRigType.R15 then
			arm = model:WaitForChild('LeftHand')
		end
		if arm then
			local rc = arm:FindFirstChild('ChatWindowConstraint')
			if rc then
				rc.Attachment1 = newMenu.Attachment
				local scr = newMenu:FindFirstChild('MainModule')
				if scr then
					require(scr):Init()
				end
			end
		end
	end
end

function module:GetMenu()
	local model = AvatarInstance:GetVRAvatar(Players.LocalPlayer)
	if model then
		local menu = model:FindFirstChild('tvrwindow')
		if menu then
			return menu
		end
	end
end

return module
