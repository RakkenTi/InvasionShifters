--[[

@rakken
Tween setting properties easily

]]

--// Services
local TweenService = game:GetService("TweenService")

--// Main
local property = {}

--[[ Public Functions ]]
--

function property.SetTable(instance: Instance, properties: {}, tweenInfo: TweenInfo?, callback: () -> nil)
	if tweenInfo then
		local tween = TweenService:Create(instance, tweenInfo, properties)
		tween:Play()
		if callback then
			tween.Completed:Once(callback)
		end
	else
		for propertyIndex, value in pairs(properties) do
			instance[propertyIndex] = value
		end
	end
end

return property
