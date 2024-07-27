--[[

@rakken
VFX-Related utility functions

]]

--// Constants
local IGNORE_PARTICLE_SET_TAG = ".IgnoreParticleSet"
local IGNORE_BEAM_SET_TAG = ".IgnoreBeamSet"

--// Services
local TweenService = game:GetService("TweenService")

--// Main
local VFX = {
	Auras = {},
}

--[[ Public Functions ]]
function VFX.SetParticle(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("ParticleEmitter") and not v:HasTag(IGNORE_PARTICLE_SET_TAG) then
			v.Enabled = bool
		end
	end
end

function VFX.SetBeam(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("Beam") and not v:HasTag(IGNORE_BEAM_SET_TAG) then
			v.Enabled = bool
		end
	end
end

function VFX.AddAura(AuraParticles: { ParticleEmitter }, root: Instance, id: string?, tweenInfo: TweenInfo?)
	local particleId = id or "AuraVFXParticles"
	VFX.Auras[particleId] = {}
	for _, basepart in root:GetDescendants() do
		if basepart:IsA("BasePart") then
			for _, particle in ipairs(AuraParticles) do
				local Clone = particle:Clone()
				Clone:AddTag(IGNORE_PARTICLE_SET_TAG)
				local OriginalBrightness = Clone.Brightness
				Clone.Brightness = 0
				Clone.Parent = basepart
				if tweenInfo then
					TweenService:Create(Clone, tweenInfo, { Brightness = OriginalBrightness }):Play()
				end
				table.insert(VFX.Auras[particleId], Clone)
			end
		end
	end
end

function VFX.RemoveAura(id: string)
	local AuraParticles = VFX.Auras[id]
	for _, particle in ipairs(AuraParticles) do
		particle.Enabled = false
	end
	task.delay(10, function()
		for _, particle in ipairs(AuraParticles) do
			if particle then
				particle:Destroy()
			end
		end
	end)
	table.clear(AuraParticles)
end

return VFX
