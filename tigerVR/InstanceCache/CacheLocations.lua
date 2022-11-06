local ReplicatedStorage = game:GetService('ReplicatedStorage')
local WorkSpace = game:GetService('Workspace')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')

local module = {}

function module:GetGlobalCache()
	local cacheLocation = WorkSpace.Terrain:FindFirstChild('tigerVRCache')
	if not cacheLocation and RunService:IsServer() then
		local tigerVRCache = Instance.new('Folder')
		tigerVRCache.Name = "tigerVRCache"
		tigerVRCache.Parent = WorkSpace.Terrain
		return tigerVRCache
	end
	return cacheLocation
end

local function getusercache(player)
	local cacheLocation = module:GetGlobalCache()
	local stat, r = pcall(function()
		local pf = cacheLocation:FindFirstChild(tostring(player.UserId))
		if pf then
			return pf
		end
	end)
	if not stat then return nil else return r end
end

function module:GetOrCreateUserCache(player)
	local cacheLocation = module:GetGlobalCache()
	local pf = getusercache(player)
	if pf then
		return pf
	end
	if RunService:IsServer() then
		local newFolder = Instance.new('Folder')
		newFolder.Name = tostring(player.UserId)
		newFolder.Parent = cacheLocation
		return newFolder
	end
end

function module:GetUserCache(player)
	return getusercache(player)
end

function module:GetOrCreateServerCache()
	if RunService:IsClient() then
		warn("ServerCache cannot be accessed or created by the Client!")
		return
	end
	local f = ServerStorage:FindFirstChild('tigerVRServerCache')
	if not f then
		f = Instance.new('Folder')
		f.Name = "tigerVRServerCache"
		f.Parent = ServerStorage
	end
	return f
end

return module