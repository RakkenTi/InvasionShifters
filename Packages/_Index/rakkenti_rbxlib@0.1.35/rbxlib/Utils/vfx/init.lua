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
	Spreads = {},
	Trails = {},
	Rubble = require(script.rubble),
}

--[[ Public Functions ]]
function VFX.SetParticle(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("ParticleEmitter") and not v:HasTag(IGNORE_PARTICLE_SET_TAG) then
			v.Enabled = bool
		end
	end
end

function VFX.EmitParticle(root: Instance)
	for _, v in root:GetDescendants() do
		if v:IsA("ParticleEmitter") and not v:HasTag(IGNORE_PARTICLE_SET_TAG) then
			v:Emit(v:GetAttribute("EmitCount"))
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

function VFX.AddTrail(Trail: BasePart, root: Instance | { Instance }, id: string?)
	local t = typeof(root) == "Instance" and root:GetDescendants() or root
	local trailId = id or "TrailVFX"
	VFX.Trails[trailId] = {}
	for _, basepart in ipairs(t) do
		if basepart:IsA("BasePart") then
			local TrailClone = Trail:Clone()
			local TrailWeldConstraint = Instance.new("WeldConstraint")
			TrailClone.CanCollide = false
			TrailClone.CanQuery = false
			TrailClone.CanTouch = false
			TrailClone.Transparency = 1
			TrailClone.CFrame = basepart.CFrame
			TrailClone.Parent = game.Workspace
			TrailWeldConstraint.Part0 = TrailClone
			TrailWeldConstraint.Part1 = basepart
			TrailWeldConstraint.Parent = basepart
			table.insert(VFX.Trails[trailId], TrailClone)
			table.insert(VFX.Trails[trailId], TrailWeldConstraint)
			for _, v in TrailClone:GetDescendants() do
				table.insert(VFX.Trails[trailId], v)
			end
		end
	end
end

function VFX.RemoveTrail(id: string)
	local Trails = VFX.Trails[id]
	for _, v: Instance in ipairs(Trails) do
		if v:IsA("Trail") then
			v.Enabled = false
		end
		game:GetService("Debris"):AddItem(v, 15)
	end
end

function VFX.AddAura(
	AuraParticles: { ParticleEmitter },
	root: Instance | { Instance },
	id: string?,
	tweenInfo: TweenInfo?
)
	local t = typeof(root) == "Instance" and root:GetDescendants() or root
	local particleId = id or "AuraVFXParticles"
	VFX.Auras[particleId] = {}
	for _, basepart in ipairs(t) do
		if basepart:IsA("BasePart") then
			for _, particle in ipairs(AuraParticles) do
				local Clone = particle:Clone()
				Clone:AddTag(IGNORE_PARTICLE_SET_TAG)
				local OriginalBrightness = Clone.Brightness
				Clone.Parent = basepart
				if tweenInfo then
					Clone.Brightness = 0
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

function VFX.SpreadInstance(Instances: { Instance }, root: Instance | { Instance }, id: string?)
	local t = typeof(root) == "Instance" and root:GetDescendants() or root
	local tId = id or "InstanceSpread"
	VFX.Spreads[tId] = {}
	for _, basepart in ipairs(t) do
		if basepart:IsA("BasePart") then
			for _, instance in ipairs(Instances) do
				local clone = instance:Clone()
				table.insert(VFX.Spreads[tId], clone)
				clone.Parent = basepart
			end
		end
	end
end

function VFX.RemoveSpread(id: string)
	local Spread = VFX.Spreads[id]

	for _, instance in ipairs(Spread) do
		instance:Destroy()
	end
end

return VFX
