--[[

@rakken
Class for tweening numbers using IntValues.

]]

--// Services
local TweenService = game:GetService("TweenService")

--// Main
local NumberTweener = {}
NumberTweener.__index = NumberTweener

function NumberTweener.new()
	local self = setmetatable({}, NumberTweener)
	self.intvalue = Instance.new("IntValue")
	self.tweeninfo = TweenInfo.new(0.5)
	self.goal = 0

	-- init
	self.intvalue.Parent = script

	return self
end

function NumberTweener:SetGoal(goal: number)
	self.goal = goal

	return self
end

function NumberTweener:SetInfo(tweeninfo: TweenInfo)
	self.tweeninfo = tweeninfo

	return self
end

function NumberTweener:GetInstance()
	return self.intvalue
end

function NumberTweener:BindTextToValue(textinstance: TextLabel | TextButton | { Text: string })
	self.intvalue:GetPropertyChangedSignal("Value"):Connect(function()
		textinstance.Text = self.intvalue.Value
	end)

	return self
end

function NumberTweener:ListenToValue(func: number)
	self.intvalue:GetPropertyChangedSignal("Value"):Connect(function()
		func(self.intvalue.Value)
	end)

	return self
end

function NumberTweener:Play()
	TweenService:Create(self.intvalue, self.tweeninfo, { Value = self.goal }):Play()

	return self
end

return NumberTweener
