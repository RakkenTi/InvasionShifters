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
	titan_init_signal_suffix = "TitanInit_",
	titan_script_init_signal_suffix = "TitanScriptInit_",
}
