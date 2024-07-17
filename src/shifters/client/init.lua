--[[

@rakken
Invasion's Shifter Module
Client Environment

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Modules
local Settings = require(script.Parent.settings)
local rbxlib = Settings.dependencies.rbxlib
local Satellite = rbxlib.Satellite

--// Module-Constants

--// Variables

--// Main

local ShifterClient = {}

--[[ Private Functions ]]

local function HandleInput()
	UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then
			return
		end
		if input.KeyCode == Settings.universal.Input.shifter_transformation_key then
			Satellite.Send("ShifterAction", input.KeyCode)
		end
	end)
end

local function HandleSignals() end

--[[ Public Functions ]]

function ShifterClient.Start()
	HandleInput()
	HandleSignals()
end

return ShifterClient
