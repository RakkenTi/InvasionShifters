--[[

@rakken
Invasion's Shifter Module
Server Environment

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local ShifterTitans = require(script.Parent.titans)
local TitanBase = require(script.Parent.titanbase)
local Settings = require(script.Parent.settings)
local rbxlib = Settings.dependencies.rbxlib
local LogM = rbxlib.Utils.log
local Stopwatch = rbxlib.Utils.stopwatch
local Data = rbxlib.Data
local Satellite = rbxlib.Satellite

--// Module-Constants
local Log = LogM.new("[Shifter]")

--// Variables

--// Main
local ShifterServer = {}

--[[ Private Functions ]]
local function HandleClientAction(player: Player, actionkey: Enum.KeyCode)
	Log:print(`{player} is attempting a titan action. ActionKey: [{actionkey}]`)
	local isShifter = Data:GetData(player, "Shifter")
	if isShifter ~= true then
		Log:print(`{player} is not elligible for action. Denying request.`)
		return
	end
	local ShifterName = Data:GetData(player, "ShifterName")
	local ShifterClass = ShifterTitans[ShifterName]
	if not ShifterClass then
		Log:print(`{player}'s ShifterName: [{ShifterName}] is invalid.`)
		return
	end
	if actionkey == Settings.universal.Input.shifter_transformation_key then
		local ShifterClass = ShifterTitans[ShifterName]
		ShifterClass.new(player)
	end
end

local function CreateSignals()
	Satellite.Create("RemoteEvent", "ShifterAction")
end
local function HandleSignals()
	Satellite.ListenTo("ShifterAction"):Connect(HandleClientAction)
end

--[[ Public Functions ]]
function ShifterServer.Start()
	Stopwatch.Start()
	Log:printheader("Module starting..")
	CreateSignals()
	HandleSignals()
	Log:printheader(`Module started in {Stopwatch.Stop()}s`)
end

return ShifterServer
