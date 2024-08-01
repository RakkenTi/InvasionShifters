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
	WeightForce = -10000000,
	DefaultAnimations = {
		Idle = 18728045236,
		Run = 18584417783,
		Walk = 18728038872,
		Jump = 18728206691,
		Shift = 18740018626,
		Heavy = 18744680727,
		Roar = 18746235561,
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
			WalkSpeed = 100,
			RunSpeed = 240,
			UseJumpPower = false,
			JumpHeight = 100,
			HipHeight = 36,
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
	JumpStaminaCost = 10,
	MovementAnimations = {
		BowRun = 18727875380,
	},
	LMBSequence = {
		18728361064, -- AttackHit1
		18728365676, -- AttackHit2
		18728368473, -- AttackHit3
	},
	ShifterSFX = {
		Impact = { 2011915907, 6 },
		Rumble = { 6677463885, 1 },
		Sparks = { 4591549719, 2 },
		Strike = { 6677463428, 2 },
		Wind = { 6677464347, 3 },
		Roar = { 18729793631, 2 },
	},
	Combat = {
		LMB = {
			ComboDamageIndex = {
				80, -- First Hit
				120, -- Second Hit
				200, -- Third Hit
			},
			Hitbox = {
				Vector3Offset = Vector3.new(0, -40, 0),
				Size = Vector3.new(110, 40, 40),
			},
			ComboTimeout = 2,
		},
		Heavy = {
			Cooldown = 6,
			StaminaCost = 100,
			Damage = 10000,
			Hitbox = {
				Vector3Offset = Vector3.new(0, -40, 0),
				Size = Vector3.new(120, 60, 60),
			},
		},
		Roar = {
			ForceMagnitude = 300,
			StaminaAdd = 200,
			Range = 300,
			Cooldown = 20,
			Duration = 5,
		},
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
