local module = {}

local function createIKForLimb(ik, chainroot, endeffector, target)
	ik.Type = Enum.IKControlType.Transform
	ik.EndEffector = endeffector
	ik.ChainRoot = chainroot
	ik.Target = target
	ik.Pole = nil
	ik.SmoothTime = 0.01
	chainroot.Anchored = false
end

-- TODO: Foot Placing

function module:ApplyIKToModel(model)
	local humanoid = model:FindFirstChild("Humanoid")
	if humanoid and not module:IsIKPresent(model) then
		local rt = humanoid.RigType
		if rt == Enum.HumanoidRigType.R6 then
			print("Avatar is R6, no IK needed")
		elseif rt == Enum.HumanoidRigType.R15 then
			-- Left Arm
			local lefthand_target = model:FindFirstChild("vr_lefthand")
			local lefthand = model:FindFirstChild("LeftHand")
			local leftupperarm = model:FindFirstChild("LeftUpperArm")
			local leftarmik = Instance.new('IKControl')
			leftarmik.Parent = humanoid
			createIKForLimb(leftarmik, leftupperarm, lefthand, lefthand_target)
			-- Right Arm
			local righthand_target = model:FindFirstChild("vr_righthand")
			local righthand = model:FindFirstChild("RightHand")
			local rightupperarm = model:FindFirstChild("RightUpperArm")
			local rightarmik = Instance.new('IKControl')
			rightarmik.Parent = humanoid
			createIKForLimb(rightarmik, rightupperarm, righthand, righthand_target)
			-- Left Leg
			local leftfoot_target = model:FindFirstChild("vr_leftfoot")
			local leftfoot = model:FindFirstChild("LeftFoot")
			local leftupperleg = model:FindFirstChild("LeftUpperLeg")
			local leftlegik = Instance.new('IKControl')
			leftlegik.Parent = humanoid
			createIKForLimb(leftlegik, leftupperleg, leftfoot, leftfoot_target)
			-- Right Leg
			local rightfoot_target = model:FindFirstChild("vr_rightfoot")
			local rightfoot = model:FindFirstChild("RightFoot")
			local rightupperleg = model:FindFirstChild("RightUpperLeg")
			local rightlegik = Instance.new('IKControl')
			rightlegik.Parent = humanoid
			createIKForLimb(rightlegik, rightupperleg, rightfoot, rightfoot_target)
		end
	else
		if not humanoid then
			warn("No Humanoid present!")
		elseif module:IsIKPresent(model) then
			warn("IK already created!")
		end
	end
end

function module:IsIKJoint(partname)
	if partname == "LeftUpperArm" or partname == "LeftLowerArm" or partname == "LeftHand" then
		return true
	end
	if partname == "RightUpperArm" or partname == "RightLowerArm" or partname == "RightHand" then
		return true
	end
	if partname == "LeftUpperLeg" or partname == "LeftLowerLeg" or partname == "LeftFoot" then
		return true
	end
	if partname == "RightUpperLeg" or partname == "RightLowerLeg" or partname == "RightFoot" then
		return true
	end
	return false
end

function module:IsIKPresent(model)
	local h = model:FindFirstChild("Humanoid")
	if h then
		for _, p in h:GetChildren() do
			if p:IsA('IKControl') then
				return true
			end
		end
	end
	return false
end

return module