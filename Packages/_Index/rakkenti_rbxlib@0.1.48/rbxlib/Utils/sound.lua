--[[

@rakken
Create Sound Instances Easily.

]]

--// Services
local SoundService = game:GetService("SoundService")

--// Main
local Sounds = {}

function Sounds.new(id: number)
	local sound = Instance.new("Sound")
	sound.Parent = SoundService
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = 1
	return sound
end

function Sounds.Play(root: Instance)
	for _, sound in root:GetDescendants() do
		if sound:IsA("Sound") then
			sound:Play()
		end
	end
end

return Sounds
