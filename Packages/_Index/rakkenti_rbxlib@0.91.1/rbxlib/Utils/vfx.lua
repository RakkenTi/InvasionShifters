--[[

@rakken
VFX-Related utility functions

]]

--// Main
local VFX = {}

--[[ Public Functions ]]
function VFX.SetParticle(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = bool
		end
	end
end

function VFX.SetBeam(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("Beam") then
			v.Enabled = bool
		end
	end
end

return VFX
