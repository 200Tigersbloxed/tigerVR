local WorkSpace = game:GetService('Workspace')

local module = {}

function module:IsPartFacingPart(Part0, Part1, filterdescendants)
	--local ray = Ray.new(Part0.Position, Part1.CFrame.LookVector * 5000)
	local rayOrigin = Part0.Position
	local rayDestination = Part1.Position
	local rayDirection = rayDestination - rayOrigin
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.IgnoreWater = true
	if filterdescendants then raycastParams.FilterDescendantsInstances = filterdescendants end
	local raycastResult = WorkSpace:Raycast(rayOrigin, rayDirection, raycastParams)
	if raycastResult == nil then return false end
	if raycastResult.Instance == Part1 then return true end
	return false, raycastResult
end

return module
