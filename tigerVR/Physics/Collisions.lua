local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PhysicsService = game:GetService('PhysicsService')
local RunService = game:GetService('RunService')

local tigerVR = ReplicatedStorage:WaitForChild('tigerVR')

local module = {}

function module:Init()
	if RunService:IsClient() then
		warn("Cannot use Collisions on the Client!")
		return
	end
	PhysicsService:CreateCollisionGroup(tigerVR.InstanceCache.DummyCollisionGroup.Value)
	for _, part in tigerVR.InstanceCache.R6Dummy:GetDescendants() do
		if part:IsA('BasePart') then
			PhysicsService:SetPartCollisionGroup(part, tigerVR.InstanceCache.DummyCollisionGroup.Value)
		end
	end
	for _, part in tigerVR.InstanceCache.R15Dummy:GetDescendants() do
		if part:IsA('BasePart') then
			PhysicsService:SetPartCollisionGroup(part, tigerVR.InstanceCache.DummyCollisionGroup.Value)
		end
	end
	--debug
	--PhysicsService:SetPartCollisionGroup(workspace.Part, tigerVR.InstanceCache.DummyCollisionGroup.Value)
	PhysicsService:CollisionGroupSetCollidable(PhysicsService:GetCollisionGroupName(0), tigerVR.InstanceCache.DummyCollisionGroup.Value, false)
end

function module:DisablePartCollision(part)
	PhysicsService:SetPartCollisionGroup(part, tigerVR.InstanceCache.DummyCollisionGroup.Value)
end

function module:EnablePartCollision(part)
	PhysicsService:SetPartCollisionGroup(part, PhysicsService:GetCollisionGroupName(0))
end

return module
