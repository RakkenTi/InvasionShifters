export type DefaultAnimationTracks = {
	Freefall: AnimationTrack,
	Heavy: AnimationTrack,
	Idle: AnimationTrack,
	Jump: AnimationTrack,
	Run: AnimationTrack,
	AltRun: AnimationTrack,
	Walk: AnimationTrack,
	DeShift: AnimationTrack,
	Shift: AnimationTrack,
	Roar: AnimationTrack,
	LeftGrab: AnimationTrack,
	RightGrab: AnimationTrack,
	Block: AnimationTrack,
	Special: AnimationTrack,
	Special2: AnimationTrack,
}

export type DefaultShifterConfig = {
	WeightForce: number,
	DefaultAnimations: DefaultAnimationTracks,
	StunAnimations: { AnimationTrack | number },
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

export type DefaultShifterController = {
	PlayTransformationCutscene: () -> nil,
	CreateTransformationVFX: (player: Player) -> nil,
}

return true
