--[[

@rakken
camera shaker wrapper

]]

--// Services

--// Modules
local CameraShaker = require(script.Parent.Parent.Dependencies.CameraShaker)

--// Module-Constants
local camShake = nil :: typeof(CameraShaker.new(...))

--// Constants
local Camera = game.Workspace.CurrentCamera

--// Variables

--// Main
local CameraShake = {}

--[[ Private Functions ]]
function CameraShake._onShake(sCF: CFrame)
	Camera.CFrame *= sCF
end

--[[ Public Functions ]]
function CameraShake.Start()
	camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, CameraShake._onShake)
	camShake:Start()
end

function CameraShake.ShakeOnce(arg: {
	magnitude: number,
	roughness: number,
	fadeInTime: number,
	fadeOutTime: number,
	posInfluence: number,
	rotInfluence: number,
})
	camShake:ShakeOnce(CameraShaker.CameraShakeInstance.new(arg))
end

function CameraShake.ShakePreset(
	arg: "Bump" | "Explosion" | "Earthquake" | "BadTrip" | "HandheldCamera" | "Vibration" | "RoughDriving"
)
	arg = CameraShaker.Presets[arg]
	camShake:Shake(arg)
end

function CameraShake.StartSustainedPreset(
	arg: "Bump" | "Explosion" | "Earthquake" | "BadTrip" | "HandheldCamera" | "Vibration" | "RoughDriving"
)
	arg = CameraShaker.Presets[arg]
	return camShake:ShakeSustain(arg) :: { StartFadeOut: (dur: number) -> nil }
end

function CameraShake.StartSustained(arg: {
	magnitude: number,
	roughness: number,
	fadeInTime: number,
	fadeOutTime: number,
	posInfluence: number,
	rotInfluence: number,
})
	CameraShaker.CameraShakeInstance.new(arg)
	return camShake:ShakeSustain(arg) :: { StartFadeOut: (dur: number) -> nil }
end

function CameraShake.StopSustained(fadeOut: number)
	camShake:StopSustained(fadeOut)
end

--// Init
CameraShake.Start()

return CameraShake
