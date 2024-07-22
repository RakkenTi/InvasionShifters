--[[

@rakken
Create Animation Instances Easily.

]]

--// Main
local Anim = {}

function Anim.new(id: number)
	local Animation = Instance.new("Animation")
	Animation.AnimationId = "rbxassetid://" .. id
	return Animation
end

return Anim
