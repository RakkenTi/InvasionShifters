--[[

@rakken/Invasion
Shifter Manager
The manager is a client side 

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Modules
local Types = require(script.Parent.Types)
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Utils = rbxlib.Utils
local Satellite = rbxlib.Satellite
local Loader = Utils.loader
local Reference = Utils.reference
local Stopwatch = Utils.stopwatch

--// Module-Constants
local Log = Utils.log.new("[Shifter Manager]")
local player = Reference.Client.Player

--// Main
local ShifterClient = {}

--[[ Private Functions ]]
function ShifterClient._onTitanCreated(Shifter: Player, ShifterName: string)
	Log:printheader(`onTitanCreated: [{Shifter}] | [{ShifterName}]`)
	local Class = require(script[ShifterName]) :: Types.DefaultShifterController
	Class.PlayTransformationCutscene()
	Class.CreateTransformationVFX(Shifter)
end

function ShifterClient._activateTitan(Shifter: Player, ShifterName: string, TitanModel: Model)
	Log:printheader(`Activating Titan:  [{ShifterName}} | [{Shifter}]`)
	player.CameraMaxZoomDistance = 512
	player.CameraMinZoomDistance = 0.5
	local Class = require(script[ShifterName]) :: Types.DefaultShifterController
	Class.Activate(TitanModel)
end

function ShifterClient._setupConnections()
	Satellite.ListenTo("onTitanCreated"):Connect(ShifterClient._onTitanCreated)
	Satellite.ListenTo("ActivateTitan"):Connect(ShifterClient._activateTitan)
end

function ShifterClient._setupInput()
	UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if
			gpe
			or (
				Reference.Client.Player
				and Reference.Client.Player.Character
				and Reference.Client.Player.Character:HasTag("isTitan")
			)
		then
			return
		end
		if input.KeyCode == Enum.KeyCode.P then
			Satellite.Send("CreateTitan")
		end
	end)
end

--[[ Public Functions ]]
function ShifterClient.Start()
	Stopwatch.Start()
	Log:printheader("Shifter Client Initializing..")
	Loader.LoadChildren(script)
	ShifterClient._setupConnections()
	ShifterClient._setupInput()
	Log:printheader(`Shifter Client Initialized in {Stopwatch.Stop()}'s.`)
end
return ShifterClient
