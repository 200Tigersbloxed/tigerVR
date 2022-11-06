local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')
local CacheLocations = require(tigerVR.InstanceCache.CacheLocations)

local module = {}

function module.CreateConfigData(IsVR, Debug, ExtendTracking)
	return {
		["IsVR"] = IsVR,
		["Debug"] = Debug,
		["ExtendTracking"] = ExtendTracking
	}
end

function module:AddTrackingToConfigData(configData, headCFrame, lefthandCFrame, righthandCFrame)
	local newConfigData = configData
	newConfigData['Head'] = headCFrame
	newConfigData['LeftHand'] = lefthandCFrame
	newConfigData['RightHand'] = righthandCFrame
	return newConfigData
end

function module:AddExtendedTrackingToConfigData(configData, extendedtracking)
	local newConfigData = configData
	newConfigData['ExtendedTrackingData'] = extendedtracking
end

function module.UpdateConfig(player, configData)
	if not configData then return end
	if RunService:IsServer() then
		local playerCache = module:GetOrCreatePlayerCache(player)
		for key, value in configData do
			pcall(function()
				local val = playerCache:FindFirstChild(key)
				if val and not val:IsA('Folder') then
					val.Value = value
				end
			end)
		end
	end
end

function module.FromPlayerConfig(player)
	local playerConfig = module:GetOrCreatePlayerCache(player)
	local config = {}
	for _, val in playerConfig:GetChildren() do
		if not val:IsA('Folder') then
			config[val.Name] = val.Value
		end
	end
	return config
end

function module:DoesPlayerHaveCache(player)
	local cache = CacheLocations:GetOrCreateUserCache(player)
	if not cache then return false end
	local playerCache = cache:FindFirstChild('PlayerCache')
	if not playerCache then return false end
	return true
end

function module:GetOrCreatePlayerCache(player)
	local cache = CacheLocations:GetOrCreateUserCache(player)
	local playerCache = cache:FindFirstChild('PlayerCache')
	if not playerCache then
		if RunService:IsServer() then
			playerCache = tigerVR.InstanceCache.PlayerCache:Clone()
			playerCache.Parent = cache
		else
			warn("No UserCache for "..player.Name)
			return nil
		end
	end
	return playerCache
end

return module
