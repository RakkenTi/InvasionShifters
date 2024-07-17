--[[

@rakken
Jaw-Titan Shifter Class

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local BaseTitanClass = require(script.Parent.Parent.titanbase)

--// Module-Constants

--// Variables

--// Main
local JawShifter = {}

--[[ Private Functions ]]

--[[ Public Functions ]]
function JawShifter.new(player: Player)
	BaseTitanClass.new(player)
end

return JawShifter
