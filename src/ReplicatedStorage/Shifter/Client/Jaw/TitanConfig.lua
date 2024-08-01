--[[
TEMPLATE
THIS TEMPLATE REPRESENTS THE JAW TITAN

@rakken
ShifterConfig
Make sure to see the DefaultShifterConfig to find the mandatory animations. //
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
	WeightForce = -1000000,
	DefaultAnimations = {
		Idle = 18533372177,
		Run = 18718072357,
		Walk = 18718069573,
		DeShift = 18680354232,
		Shift = 18739388492,
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
			MaxHealth = 10000,
			Health = 10000,
			WalkSpeed = 120,
			RunSpeed = 260,
			UseJumpPower = false,
			JumpHeight = 120,
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
	LMBSequence = {
		18533378062, -- Left Attack
		18533384595, -- Right Attack
	},
	Climbing = {
		ClimbRange = 60,
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
			ForceMagnitude = 200,
			StaminaAdd = 80,
			Range = 200,
			Cooldown = 20,
			Duration = 6,
		},
		Hitbox = {
			LMB = {
				CFrameOffset = CFrame.new(0, -20, -20),
				Size = Vector3.new(15, 30, 35),
			},
		},
		Bite = {
			BiteDamage = 60,
			BiteHitbox = Vector3.new(30, 40, 30),
			Offset = CFrame.new(0, -30, -70),
			DashMagnitude = 250,
			AttackCooldown = 15,
			AttackStaminaCost = 60,
			GrabCooldown = 5,
			GrabStaminaCost = 30,
		},
		NapeGuard = {
			ReductionFactor = 0.2, -- Multiplies the damage by this number.
		},
		NapeHarden = {
			Cooldown = 20,
			MinimumStaminaRequired = 50, -- Will switch off if under this much stamina.
			StaminaDrain = 0.8,
			Duration = 10,
		},
	},
	MiscAnimations = {
		Freefall = 18538824689,
		Climb = 18718640019,
		Jump = 18534652407,
	},
	CombatAnimations = {
		Roar = 18533389680,
		Bite = 18715607517,
		Grab = 18715607517,
		Eat = 18715730546,
		NapeGuard = 18715857909,
	},
	ShifterSFX = {
		Impact = { 2011915907, 6 },
		Rumble = { 6677463885, 1 },
		Sparks = { 4591549719, 2 },
		Strike = { 6677463428, 2 },
		Wind = { 6677464347, 3 },
		Roar = { 18729890558, 2 },
		Special = { 5951831903, 2 },
		Hit = { 6506292904, 1 },
		TransformRoar = { 18598031027, 2, 0.8 },
	},
	Health = {
		Arm = 15, -- Amount of slashes to break arm,
	},
	JumpStaminaCost = 10,
	BlindDuration = 4,
	NapeHardenTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	BlindTweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TransformBeamTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TitanFadeOutTweenInfo = TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	ColorCorrectionTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	AuraTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

return {
	Default = DefaultData,
	Custom = CustomData,
}
