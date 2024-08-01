--[[

@rakken
Tween setting properties easily

]]

--// Services
local TweenService = game:GetService("TweenService")

--// Main
local property = {}

--[[ Public Functions ]]
function property.BatchSet(
	t: { Instance },
	properties: {},
	tweenInfo: TweenInfo?,
	callback: (() -> nil)?,
	filter: { string }?,
	ignore: { [string]: boolean }?
)
	if filter then
		for _, v in ipairs(t) do
			for _, className in ipairs(filter) do
				if v:IsA(className) then
					if ignore and ignore[v.Name] then
						continue
					end
					property.SetTable(v, properties, tweenInfo)
					continue
				end
			end
		end
	else
		for _, v in ipairs(t) do
			if ignore and ignore[v.Name] then
				continue
			end
			property.SetTable(v, properties, tweenInfo)
		end
	end

	if callback and tweenInfo then
		task.wait(tweenInfo.Time)
	end
	if callback then
		callback()
	end
end

function property.SetTable(instance: Instance, properties: {}, tweenInfo: TweenInfo?, callback: (() -> nil)?)
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
