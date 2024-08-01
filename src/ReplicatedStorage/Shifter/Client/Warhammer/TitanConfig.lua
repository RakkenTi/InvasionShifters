--[[
TEMPLATE
THIS TEMPLATE REPRESENTS THE JAW TITAN

@rakken
ShifterConfig
Make sure to see the DefaultShifterConfig to find the mandatory animations.
NOTICE WHEN EDITING CONFIG: Once finished editing the config, send it to @rakken because it will be overwritten by rojo.


Notes:
LeftAttack and RightAttack are the alternating m1 animations.
Heavy is the heavy attack animation.
Freefall is the animation that plays while a titan is falling, 
it is usually a single set of keyframes representing a state of freefall.
]]

--// Types
local Types = require(script.Parent.Parent.Parent.Types)

local DefaultData = {
	DefaultAnimations = {
		Idle = 18727861854,
		Run = 18727870788,
		Walk = 18727854931,
		--DeShift = 0,
	},
	ColorCorrectionData = {
		OnTransformation = {
			Brightness = -0.2,
			TintColor = Color3.fromRGB(186, 112, 114),
			Contrast = 0.1,
			Saturation = -0.1,
		},
		Default = {
			Brightness = 0,
			TintColor = Color3.fromRGB(255, 255, 255),
			Contrast = 0,
			Saturation = 0,
		},
	},
	Stats = {
		Humanoid = {
			MaxHealth = 30000,
			Health = 30000,
			WalkSpeed = 120,
			RunSpeed = 260,
			JumpHeight = 50,
			HipHeight = 40,
		},
		Stamina = {
			Minimum = 5,
			Maximum = 10000,
			MinimumThreshold = 50,
			ConsumptionRate = 0.01,
			RegenerationRate = 0.025,
		},
	},
	DoubleTapThresholdTime = 0.25,
} :: Types.DefaultShifterConfig

local CustomData = {
	MovementAnimations = {
		BowRun = 18727875380,
	},
	LMBSequence = {
		18740264157, -- AttackHit1
		18740266498, -- AttackHit2
	},
	ShifterSFX = {
		Impact = { 2011915907, 6 },
		Rumble = { 6677463885, 1 },
		Sparks = { 4591549719, 2 },
		Strike = { 6677463428, 2 },
		Wind = { 6677464347, 3 },
		Roar = { 18598031027, 2 },
		TransformRoar = { 18598031027, 2, 0.8 },
	},
	TransformBeamTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TitanFadeOutTweenInfo = TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	ColorCorrectionTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	AuraTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TitanGrowTweenInfo = TweenInfo.new(1.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
}

return {
	Default = DefaultData,
	Custom = CustomData,
}
