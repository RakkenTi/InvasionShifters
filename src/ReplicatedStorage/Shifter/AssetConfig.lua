--[[

@rakken
Configure as needed.

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Config
return {
	ShifterAssets = ReplicatedStorage:WaitForChild("ShifterAssets") :: Folder,
}
