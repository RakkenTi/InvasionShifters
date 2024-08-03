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
		Idle = 18770293797,
		Run = 18770281601,
		AltRun = 18770289213,
		Walk = 18770270694,
		Jump = 18770313660,
		Block = 18770318365,
		Shift = 18770485408,
		Freefall = 18770699354,
		DeShift = 18770705804,
		Special = 18774212469,
		Special2 = 18776171308,
	} :: Types.DefaultAnimationTracks,
	StunAnimations = {
		18760521992,
		18760565098,
		18760570664,
		18760572223,
	},
	Transformation = {
		KnockbackMagnitude = 100,
		Radius = 250,
		TickDamage = 1.5,
	},
	ColorCorrectionData = {
		OnTransformation = {
			Brightness = -0.2,
			TintColor = Color3.fromRGB(186, 112, 114),
			Contrast = 0.1,
			Saturation = -0.1,
		},
		Flash = {
			Brightness = 3.5,
			TintColor = Color3.fromRGB(201, 160, 103),
			Contrast = 0.4,
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
			MaxHealth = 22500,
			Health = 22500,
			WalkSpeed = 100,
			RunSpeed = 175,
			NoBowRunSpeed = 240,
			UseJumpPower = false,
			JumpHeight = 100,
			HipHeight = 50,
			RaisedHipHeight = 55,
			StunnedSpeed = 20,
		},
		Stamina = {
			Minimum = 5,
			Maximum = 7500,
			MinimumThreshold = 50,
			ConsumptionRate = 0.01,
			RegenerationRate = 0.025,
		},
	},
	DoubleTapThresholdTime = 0.25,
}

local CustomData = {
	PassiveDamageReductionFactor = 0.9, -- Damage Reduction that's always on, stacks with block.
	JumpStaminaCost = 10,
	MovementAnimations = {
		BowRun = 18727875380,
	},
	LMBSequence = {
		18770297053, -- Hit1, Right Punch
		18770309882, -- Hit2, Left Punch
	},
	GrabSequence = {
		18759242352, -- Left Grab
		18759245214, -- Right Grab
	},
	ShifterSFX = {
		Impact = { 2011915907, 6 },
		Rumble = { 6677463885, 1 },
		Sparks = { 4591549719, 2 },
		Strike = { 6677463428, 2 },
		Wind = { 6677464347, 3 },
		Roar = { 18729793631, 1 },
		BeserkRoar = { 18758983179, 8 },
		Hit = { 18762205756, 5 },
		Spike = { 18728088362, 5 },
		WeaponCharge = { 3744392667, 2 },
	},
	Combat = {
		LMB = {
			ComboDamageIndex = {
				50, -- First Hit
				75, -- Second Hit
				100, -- Third Hit
			},
			Hitbox = {
				Vector3Offset = Vector3.new(0, -40, 0),
				Size = Vector3.new(110, 40, 40),
			},
			ComboTimeout = 2,
			StunDuration = 4,
			StunCooldown = 10,
		},
		Grab = {
			Hitbox = {
				Vector3Offset = Vector3.new(0, -5, 0),
				Size = Vector3.new(35, 35, 35),
			},
		},
		Heavy = {
			Cooldown = 45,
			StaminaCost = 150,
			Damage = 750,
			Hitbox = {
				Vector3Offset = Vector3.new(0, -40, 0),
				Size = Vector3.new(120, 60, 60),
			},
			StunDuration = 6,
			StunCooldown = 20,
		},
		Roar = {
			ForceMagnitude = 300,
			StaminaAdd = 200,
			Range = 300,
			Cooldown = 60,
			Duration = 5,
		},
		Block = {
			DamageReductionFactor = 0.75, -- Damage is multiplied by this number.
			StaminaConsumption = 1,
			MinimumStaminaRequired = 100,
		},
		Bow = {
			StaminaCost = 500,
			Cooldown = 10,
			Damage = 200,
			ForceMagnitude = 750,
		},
		Spike = {
			Duration = 6,
			StaminaCost = 500,
			Cooldown = 20,
			Damage = 100, -- Per Spike
			SpikeCount = 35,
			Radius = 250,
			MinimumRadius = 80,
			DegreeVariance = 45,
		},
	},
	Health = {
		Arm = 2,
	},
	TransformBeamTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TitanFadeOutTweenInfo = TweenInfo.new(9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	ColorCorrectionTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	FlashColorCorrectionTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	AuraTweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	TitanGrowTweenInfo = TweenInfo.new(1.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
	IKTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	BowDrawTweenInfo = TweenInfo.new(5),
	BowFadeTweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	BowArrowFadeTweenInfo = TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	CameraAdjustTweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	SpikeGrowTweenInfo = TweenInfo.new(1.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
	HumanoidBowCameraOffset = Vector3.new(50, 40, -30),
}

return {
	Default = DefaultData,
	Custom = CustomData,
}
