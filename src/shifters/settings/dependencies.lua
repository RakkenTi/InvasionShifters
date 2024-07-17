--[[

@rakken
Titan Shifter Settings
Configure to fit the game's structure and needs.

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Main
return {
	assets = ReplicatedStorage:WaitForChild("ShifterAssets"),
	rbxlib = require(ReplicatedStorage.Packages.rbxlib),
}
