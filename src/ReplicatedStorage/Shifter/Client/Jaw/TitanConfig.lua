--[[
TEMPLATE
THIS TEMPLATE REPRESENTS THE JAW TITAN

@rakken
ShifterConfig
Make sure to see the DefaultShifterConfig to find the mandatory animations.

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
		Heavy = 18533364349,
		Idle = 18533372177,
		Run = 18533393887,
		Walk = 18533400786,
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
			HipHeight = 26,
		},
		Stamina = {
			Minimum = 5,
			Maximum = 100,
			MinimumThreshold = 50,
			ConsumptionRate = 0.01,
			RegenerationRate = 0.025,
		},
	},
	DoubleTapThresholdTime = 0.25,
} :: Types.DefaultShifterConfig

local CustomData = {
	LMBSequence = {
		18533378062, -- Left Attack
		18533384595, -- Right Attack
	},
	Climbing = {
		ClimbRange = 40,
		ClimbSpeed = 20, -- Affected by current humanoid WalkSpeed. True climbspeed formula: (ClimbSpeed + Humanoid.WalkSpeed)
	},
	Combat = {
		LightAttack = {
			Damage = 80.5,
		},
		HeavyAttack = {
			Damage = 150,
			Cooldown = 60,
		},
		Roar = {
			Damage = 0,
			ForceMagnitude = 100,
			StaminaThreshold = 80,
			StaminaCost = 80,
			TickCount = 30, -- Duration. 1 tick is 0.1s. Careful with this.
			Range = 100,
		},
		Hitbox = {
			LMB = {
				CFrameOffset = CFrame.new(0, 10, -20),
				Size = Vector3.new(30, 30, 50),
			},
		},
	},
	MiscAnimations = {
		Freefall = 18538824689,
		Climb = 18533359107,
		Jump = 18534652407,
	},
	CombatAnimations = {
		Roar = 18533389680,
	},
	ShifterSFX = {
		Impact = 2011915907,
		Rumble = 6677463885,
		Sparks = 4591549719,
		Strike = 6677463428,
		Wind = 6677464347,
		Roar = 18598031027,
	},
	JumpStaminaCost = 10,
	TransformBeamTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TitanFadeOutTweenInfo = TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	ColorCorrectionTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	AuraTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

return {
	Default = DefaultData,
	Custom = CustomData,
}
