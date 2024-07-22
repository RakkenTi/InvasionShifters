export type DefaultShifterConfig = {
	DefaultAnimations: {
		Freefall: number,
		Heavy: number,
		Idle: number,
		Jump: number,
		Run: number,
		Walk: number,
	},
	ColorCorrectionData: {
		OnTransformation: {
			Brightness: number,
			TintColor: Color3,
			Contrast: number,
			Saturation: number,
		},
		Default: {
			Brightness: number,
			TintColor: Color3,
			Contrast: number,
			Saturation: number,
		},
	},
	Stats: {
		Humanoid: {
			WalkSpeed: number,
			RunSpeed: number,
			JumpHeight: number,
			HipHeight: number,
		},
		Stamina: {
			Minimum: number,
			Maximum: number,
			MinimumThreshold: number,
			ConsumptionRate: number,
			RegenerationRate: number,
		},
	},
	DoubleTapThresholdTime: number,
}

export type DefaultAnimationTracks = {
	Climb: AnimationTrack,
	Freefall: AnimationTrack,
	Heavy: AnimationTrack,
	Idle: AnimationTrack,
	Jump: AnimationTrack,
	LeftAttack: AnimationTrack,
	RightAttack: AnimationTrack,
	Roar: AnimationTrack,
	Run: AnimationTrack,
	Walk: AnimationTrack,
}

export type DefaultShifterController = {
	PlayTransformationCutscene: () -> nil,
	CreateTransformationVFX: (player: Player) -> nil,
}

return true
