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
local Players = game:GetService("Players")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Data = rbxlib.Data
local Stopwatch = Utils.stopwatch
local Basepart = Utils.basepart
local AssetConfig = require(script.AssetConfig)
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
	Satellite.Send("ActivateTitan", self.player, self.player, self.shiftername, self.TitanModel)
end

function Shifter._startServerTitanModules()
	require(script.Server)()
end

function Shifter._onTransformationSequenceFinish(player: Player)
	Log:printheader(`onTransformationSequenceFinish: [{player}]`)

	--~~[[ Character Stuff ]]~~--
	local self = Shifter._shifters[player.UserId] :: Class
	local PlayerCharacter = self.player.Character :: Model
	self.TitanModel.Parent = game.Workspace
	self.TitanModel:PivotTo(PlayerCharacter:GetPivot())
	self._characters[player.UserId] = PlayerCharacter
	PlayerCharacter.Parent = nil
	player.Character = self.TitanModel
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

function Shifter._onLimbHit(player: Player, Limb: BasePart, Damage: number)
	Log:print(`[{player}] hit titan limb. Limb: [{Limb}] | Damage: [{Damage}]`)
	if not Limb:HasTag("ShifterHitbox") then
		Log:warn(`[{player}] bypassed ShifterHitbox check. Possible exploiter.`)
		return
	end
	local shifter = Limb:GetAttribute("ShifterPlayer") and Players:GetPlayerByUserId(Limb:GetAttribute("ShifterPlayer"))
	if Limb.Name ~= "ShifterNape" and Limb.Name ~= "ShifterArm" and Limb.Name ~= "LimbFeet" then
		Log:warn(`Invalid Shifter Hitbox Name: [{Limb.Name}]. ODMPlayer: [{player}] ShifterPlayer: [{shifter}]`)
		return
	end
	local TitanReference = Limb:FindFirstChild("_shifterTitanReference") :: ObjectValue
	if not TitanReference then
		Log:warn(`[{Limb.Name}] missing _shifterTitanReference ObjectValue.`)
		return
	end
	local TitanModel = TitanReference.Value
	if not TitanModel then
		Log:warn(`[{Limb.Name}] has _shifterTitanReference, but value is nil.`)
		return
	end
	local Humanoid = TitanModel:FindFirstAncestorOfClass("Humanoid")
		or TitanModel:WaitForChild("Humanoid", 10) :: Humanoid
	if not Humanoid then
		Log:warn(`[{TitanModel.Name}] missing humanoid. Fatal error.`)
		return
	end
	Humanoid:TakeDamage(Damage)
end

function Shifter._initCollisionGroup()
	PhysicsService:RegisterCollisionGroup("ShifterTitans")
end

function Shifter._createSignals()
	Satellite.Create("RemoteEvent", "onTitanCreated") -- Used for TransformationSequence. Server notifies all clients that a titan has been created.
	Satellite.Create("RemoteEvent", "TitanAction") -- A remote for Server Defined Titan Actions that a client can fire to activate.
	Satellite.Create("RemoteEvent", "CreateTitan") -- The Start of Transformation Sequence. Sends a signal for all clients to replicate a transformation vfx. This is done on the client.
	Satellite.Create("RemoteEvent", "TransformationVFXFinished") -- The Second Step. Client fires this remote and the server will handle the next step of titan transformation on the server.
	Satellite.Create("RemoteEvent", "ActivateTitan") -- Activates Titan Controller on Client. Reponsible for movement/animations
	Satellite.Create("RemoteEvent", "ReplicateTitanVFX") -- For displaying/replicating Titan Action VFX on clients.
	Satellite.Create("RemoteEvent", "ShifterLimbHit") -- Link between ODMClass and this module
	Satellite.ListenTo("CreateTitan"):Connect(Shifter.new)
	Satellite.ListenTo("TransformationVFXFinished"):Connect(Shifter._onTransformationSequenceFinish)
	Satellite.ListenTo("TitanAction"):Connect(Shifter._onTitanAction)
	Satellite.ListenTo("ShifterLimbHit"):Connect(Shifter._onLimbHit)
end

function Shifter._loadTitanConfig(TitanModel: Model, Config: { Default: Types.DefaultShifterConfig })
	Log:print("Loading Titan Config")
	local Humanoid = TitanModel:WaitForChild("Humanoid") :: Humanoid
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
		pcall(function()
			Humanoid["MaxHealth"] = HumanoidConfig.MaxHealth
		end)
		pcall(function()
			Humanoid["Health"] = HumanoidConfig.Health
		end)
		Log:print("Loaded Humanoid Config")
	else
		Log:warn("No humanoid config.")
	end
end

function Shifter._setupHitboxTags(TitanModel: Model, shifter: Player)
	for _, v in TitanModel:GetDescendants() do
		if v:HasTag("ShifterHitbox") then
			local TitanRef = Instance.new("ObjectValue")
			TitanRef.Name = "_shifterTitanReference"
			TitanRef.Value = TitanModel
			TitanRef.Parent = v
			v:SetAttribute("ShifterPlayer", shifter.UserId)
		end
	end
end

--[[ Public Functions ]]
function Shifter.new(player: Player)
	Log:printheader(`[{player}] initiating a titan sequence. `)
	local ShifterName = Data:GetData(player, "ShifterName") :: string
	local TitanModel = ShifterTitans:FindFirstChild(ShifterName) and ShifterTitans[ShifterName]:Clone() :: Model
	Shifter._setupHitboxTags(TitanModel, player)
	TitanModel:AddTag("isTitan")
	Basepart.SetMassless(TitanModel, true)
	Basepart.SetGroup(TitanModel, "ShifterTitans")
	local Config = require(script.Client:WaitForChild(ShifterName):WaitForChild("TitanConfig"))

	if not TitanModel then
		Log:error(
			`No TitanModel called [{ShifterName}}] has been found. Player Source: [{player}}. Possible exploiter.`
		)
		return
	end

	local self = setmetatable({}, Shifter)
	self.player = player :: Player
	self.shiftername = ShifterName :: string
	self.TitanModel = TitanModel :: Model
	self.TitanModel.Name = "Shifter_" .. self.TitanModel.Name
	self._shifters[player.UserId] = self
	self.servermodule = require(script.Server[ShifterName])
	--~~[[ Model Config ]]~~--
	Basepart.SetMassless(TitanModel, true)
	self._loadTitanConfig(TitanModel, Config)
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
