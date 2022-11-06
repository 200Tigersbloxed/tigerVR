local ReplicatedStorage = game:GetService('ReplicatedStorage')
local WorkSpace = game:GetService('Workspace')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local CacheLocations = require(tigerVR.InstanceCache.CacheLocations)

local module = {}

function module:GetPlayerRigType(player)
	local character = WorkSpace:FindFirstChild(player.Name)
	if character ~= nil then
		local humanoid = character:WaitForChild('Humanoid')
		return humanoid.RigType
	end
end

function module:DoesPlayerHaveADummyAvatar(player)
	local cache = CacheLocations:GetOrCreateUserCache(player)
	local b = false
	if cache and cache:FindFirstChild(player.Name) then
		b = true
	end
	return b
end

function module:GetDummyAvatar(player)
	local cache = CacheLocations:GetOrCreateUserCache(player)
	return cache:FindFirstChild(player.Name)
end

return module