--[[

@rakken/Invasion
Shifter Module
Created in a Rojo workspace and package to Wally, 
Therefore please contact me before tampering with the internals.

Notes:
Anything within the Client module is only to be ran on the clientside.

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Data = rbxlib.Data
local Stopwatch = Utils.stopwatch
local Basepart = Utils.basepart
local AssetConfig = require(script.AssetConfig)
local TitanConfig = require(script.Client.Jaw.TitanConfig)
local Types = require(script.Types)

--// Module-Constants
local Log = Utils.log.new("[Shifter]")

--// Constants
local ShifterAssets = AssetConfig.ShifterAssets
local ShifterTitans = ShifterAssets.Titans :: Folder

--// Variables

--// Main
local Shifter = {}
Shifter.__index = Shifter
Shifter._shifters = {}
Shifter._characters = {}

--[[ Private Functions ]]

function Shifter._startTransformationSequence(self: Class)
	Satellite.SendAll("onTitanCreated", self.player, self.shiftername)
end

function Shifter._activateTitanController(self: Class)
	Satellite.Send("ActivateTitan", self.player, self.player, self.shiftername, self.shiftermodel)
end

function Shifter._startServerTitanModules()
	require(script.Server)()
end

function Shifter._onTransformationSequenceFinish(player: Player)
	Log:printheader(`onTransformationSequenceFinish: [{player}]`)

	--~~[[ Character Stuff ]]~~--
	local self = Shifter._shifters[player.UserId] :: Class
	local PlayerCharacter = self.player.Character :: Model
	self.shiftermodel.Parent = game.Workspace
	self.shiftermodel:PivotTo(PlayerCharacter:GetPivot())
	self._characters[player.UserId] = PlayerCharacter
	PlayerCharacter.Parent = nil
	player.Character = self.shiftermodel
	self._characters[player.UserId].Parent = ReplicatedStorage
	local PlayerAnimate = PlayerCharacter:WaitForChild("Animate") :: Script
	PlayerAnimate.Enabled = false
	--~~[[ Main ]]~~--

	self:_activateTitanController()
end

function Shifter._onTitanAction(player: Player, actionname: string, ...)
	Log:printheader(`onTitanAction: [{player}] | [{actionname}] [{... and unpack(...) or "No Parameters"}]`)
	local self = Shifter._shifters[player.UserId] :: Class
	--~~[[ Actions ]]~~--
	--~~[[ Reserver Action Names: NapeEject ]]~~--
	if actionname == "NapeEject" then
		self.servermodule[actionname](player, self._characters[player.UserId], ...)
	else
		self.servermodule[actionname](player, ...)
	end
end

function Shifter._initCollisionGroup()
	PhysicsService:RegisterCollisionGroup("ShifterTitans")
end

function Shifter._createSignals()
	Satellite.Create("RemoteEvent", "onTitanCreated")
	Satellite.Create("RemoteEvent", "TitanAction") -- A remote for Server Defined Titan Actions that a client can fire to activate.
	Satellite.Create("RemoteEvent", "CreateTitan") -- The Start of Transformation Sequence. Sends a signal for all clients to replicate a transformation vfx. This is done on the client.
	Satellite.Create("RemoteEvent", "TransformationVFXFinished") -- The Second Step. Client fires this remote and the server will handle the next step of titan transformation on the server.
	Satellite.Create("RemoteEvent", "ActivateTitan") -- Activates Titan Controller on Client. Reponsible for movement/animations
	Satellite.Create("RemoteEvent", "ReplicateTitanVFX") -- For displaying/replicating Titan Action VFX on clients.
	Satellite.ListenTo("CreateTitan"):Connect(Shifter.new)
	Satellite.ListenTo("TransformationVFXFinished"):Connect(Shifter._onTransformationSequenceFinish)
	Satellite.ListenTo("TitanAction"):Connect(Shifter._onTitanAction)
end

function Shifter._loadTitanConfig(ShifterModel: Model, Config: { Default: Types.DefaultShifterConfig })
	Log:print("Loading Titan Config")
	local Humanoid = ShifterModel:WaitForChild("Humanoid") :: Humanoid
	local HumanoidConfig = Config.Default.Stats.Humanoid
	if HumanoidConfig then
		Log:print("Loading Humanoid Config")
		for property: string, value: any in pairs(HumanoidConfig) do
			local success = pcall(function()
				Humanoid[property] = value
			end)
			if success then
				Log:print(`[{property}]: [{value}]`)
			end
		end
		Log:print("Loaded Humanoid Config")
	end
end

--[[ Public Functions ]]
function Shifter.new(player: Player)
	Log:printheader(`[{player}] initiating a titan sequence. `)
	local ShifterName = Data:GetData(player, "ShifterName") :: string
	local ShifterModel = ShifterTitans:FindFirstChild(ShifterName) and ShifterTitans[ShifterName]:Clone() :: Model
	ShifterModel:AddTag("isTitan")
	Basepart.SetMassless(ShifterModel, true)
	Basepart.SetGroup(ShifterModel, "ShifterTitans")
	local Config = require(script.Client:WaitForChild(ShifterName):WaitForChild("TitanConfig"))

	if not ShifterModel then
		Log:error(
			`No TitanModel called [{ShifterName}}] has been found. Player Source: [{player}}. Possible exploiter.`
		)
		return
	end

	local self = setmetatable({}, Shifter)
	self.player = player :: Player
	self.shiftername = ShifterName :: string
	self.shiftermodel = ShifterModel :: Model
	self.shiftermodel.Name = "Shifter_" .. self.shiftermodel.Name
	self._shifters[player.UserId] = self
	self.servermodule = require(script.Server[ShifterName])
	--~~[[ Model Config ]]~~--
	Basepart.SetMassless(ShifterModel, true)
	self._loadTitanConfig(ShifterModel, Config)
	self:_startTransformationSequence()
	return self
end

function Shifter.Start()
	Stopwatch.Start()
	Log:printheader("Shifter Server Initializing..")
	Shifter._createSignals()
	Shifter._startServerTitanModules()
	Shifter._initCollisionGroup()
	Log:printheader(`Shifter Server Initialized in {Stopwatch.Stop()}'s.`)
end

--~~[[ Types ]]~~--
export type Class = typeof(Shifter.new(...))

return Shifter
