--[[

@rakken
Jaw-Titan Shifter Class

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Modules
local BaseTitanClass = require(script.Parent.Parent.titanbase)
local Settings = require(script.Parent.Parent.settings)
local TitanSettings = Settings.specific.jaw
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local reference = Utils.reference

--// Module-Constants
local TitanController = script.controller

--// Constants
local TitanInitSignalName = Settings.dependencies.titan_init_signal_suffix .. script.Name
local TitanScriptInitSignalName = Settings.dependencies.titan_script_init_signal_suffix .. script.Name

--// Variables

--// Main
local JawShifter = {}

--[[ Private Functions ]]
local function TitanInitClient()
	local player = reference.Client.Player :: Player
	local character = player.Character :: Model
	local camera = game.Workspace.CurrentCamera
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	camera.CameraSubject = humanoid
end

local function TitanScriptInitClient(Controller: ModuleScript)
	require(Controller).Start(TitanSettings)
end

local function InitClient()
	Satellite.ListenTo(TitanInitSignalName):Connect(TitanInitClient)
	Satellite.ListenTo(TitanScriptInitSignalName):Connect(TitanScriptInitClient)
end

local function InitServer()
	Satellite.Create("RemoteEvent", TitanInitSignalName)
	Satellite.Create("RemoteEvent", TitanScriptInitSignalName)
end

--[[ Public Functions ]]
function JawShifter.new(player: Player)
	local class = BaseTitanClass.new(player, TitanSettings)
	local Controller = TitanController:Clone()
	Controller.Parent = class.titan
	class.titanhumanoid.UseJumpPower = false
	class.titanhumanoid.JumpHeight = TitanSettings.Humanoid.JumpHeight
	class.titanhumanoid.HipHeight = TitanSettings.Humanoid.DefaultHipHeight
	Satellite.Send(TitanScriptInitSignalName, player, Controller)
end

--~~/// [[ Init  ]] ///~~--

if RunService:IsServer() then
	InitServer()
end

if RunService:IsClient() then
	InitClient()
end

return JawShifter
