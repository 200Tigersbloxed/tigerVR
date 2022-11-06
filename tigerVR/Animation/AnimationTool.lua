local TweenService = game:GetService('TweenService')

local module = {}

local partsBeingAnimated = {}

function module:IsPartBeingAnimated(part)
	return table.find(partsBeingAnimated, part)
end

function module:AnimatePart(part, cframe, speed)
	coroutine.wrap(function()
		if not speed then speed = 0.1 end
		local info = TweenInfo.new(speed)
		local prop = {
			CFrame = cframe
		}
		local tween = TweenService:Create(part, info, prop)
		local location = 0
		tween.Changed:Connect(function(property)
			if property == 'PlaybackState' then
				if tween.PlaybackState == Enum.PlaybackState.Completed or tween.PlaybackState == Enum.PlaybackState.Cancelled then
					tween = nil
					table.remove(partsBeingAnimated, location)
				end
			end
		end)
		table.insert(partsBeingAnimated, part)
		location = table.getn(partsBeingAnimated)
		tween:Play()
	end)()
end

function module:AnimateNumberValue(numberValue, newValue, speed)
	coroutine.wrap(function()
		if not speed then speed = 0.1 end
		local info = TweenInfo.new(speed)
		local prop = {
			Value = newValue
		}
		local tween = TweenService:Create(numberValue, info, prop)
		local location = 0
		tween.Changed:Connect(function(property)
			if property == 'PlaybackState' then
				if tween.PlaybackState == Enum.PlaybackState.Completed or tween.PlaybackState == Enum.PlaybackState.Cancelled then
					tween = nil
					table.remove(partsBeingAnimated, location)
				end
			end
		end)
		table.insert(partsBeingAnimated, numberValue)
		location = table.getn(partsBeingAnimated)
		tween:Play()
	end)
end

return module
