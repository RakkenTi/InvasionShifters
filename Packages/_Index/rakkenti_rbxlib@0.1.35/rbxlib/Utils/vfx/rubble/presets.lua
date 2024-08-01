--!strict

--~~/// [[ Types ]] ///~~--
local Types = require(script.Parent.types)

--~~[[ Crater ]]~~--
local CraterPresets: { [any]: Types.CraterTemplate } = {
	Small = {
		Segments = 12,
		Duration = 6,
		MinimumRadius = 9,
		MaximumRadius = 10,
		MinimumSize = 2,
		MaximumSize = 4,
		StartOffset = 2,
		DegreeVariance = 5,
		FadeTweenInfo = TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
	},
	Medium = {
		Segments = 16,
		Duration = 6,
		MinimumRadius = 12,
		MaximumRadius = 14,
		MinimumSize = 4,
		MaximumSize = 6,
		StartOffset = 5,
		DegreeVariance = 15,
		FadeTweenInfo = TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
	},
}

--~~[[ Explosion ]]~~--
local ExplosionPresets: { [any]: Types.ExplosionTemplate } = {
	Small = {
		Segments = 12,
		Lifetime = 14,
		MinimumRadius = 4,
		MaximumRadius = 6,
		MinimumSize = 1,
		MaximumSize = 2,
		StartOffset = -2,
		DegreeVariance = 25,
		Magnitude = 120,
	},
	Medium = {
		Segments = 20,
		Lifetime = 14,
		MinimumRadius = 8,
		MaximumRadius = 12,
		MinimumSize = 3,
		MaximumSize = 6,
		StartOffset = -6,
		DegreeVariance = 50,
		Magnitude = 220,
	},
}

--~~/// [[ Presets ]] ///~~--
local Presets = {}
Presets.Crater = CraterPresets
Presets.Explosion = ExplosionPresets
return Presets
