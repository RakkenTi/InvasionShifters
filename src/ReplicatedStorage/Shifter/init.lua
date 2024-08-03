--[[

@rakken/Invasion
Shifter Module
Created in a Rojo workspace and package to Wally, 
Therefore please contact me before tampering with the internals.

Notes:
Anything within the Cient module is only to be ran on the clientside.
l
]]

--// Services
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Stopwatch = Utils.stopwatch
local Property = Utils.property

local AssetConfig = require(script.AssetConfig)
local Types = require(script.Types)

--// Module-Constants
local Log = Utils.log.new("[Shifter]")

--// Constants
local ShifterAssets = AssetConfig.ShifterAssets
local ShifterTitans = ShifterAssets.Titans :: Folder
local PlayerDataDB = DataStoreService:GetDataStore("PlayerData") -- Not using rbxlib.Data due to PlayerDataService conflictions in the main game.

--// Variables
local PreviousActionName = ""

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
	player.Character = self.TitanModel
	--~~[[ Main ]]~~--
	self:_activateTitanController()
	task.delay(2, function()
		Log:warn("Applying Titan Weight.")
		Shifter._loadWeightConfig(self.TitanModel, self.config)
	end)
	game:GetService("Debris"):AddItem(PlayerCharacter, 10)
end

function Shifter._onTitanAction(player: Player, actionname: string, ...)
	if PreviousActionName ~= actionname then
		Log:printheader(`onTitanAction: [{player}] | [{actionname}] [{... or "No Parameters"}]`)
		PreviousActionName = actionname
	end
	local self = Shifter._shifters[player.UserId] :: Class
	--~~[[ Actions ]]~~--
	--~~[[ Reserver Action Names: NapeEject ]]~~--
	if actionname == "NapeEject" then
		self.servermodule[actionname](player, self._characters[player.UserId], ...)
	else
		self.servermodule[actionname](player, ...)
	end
end

-- Pairin with ODM
function Shifter._onLimbHit(player: Player, Limb: BasePart, Damage: number)
	Log:print(`[{player}] hit titan limb. Limb: [{Limb}] | Damage: [{Damage}]`)
	if not Limb then
		Log:warn(`Limb missing, exitting..`)
		return
	end
	if not Limb:HasTag("ShifterHitbox") then
		Log:warn(`[{player}] bypassed ShifterHitbox check. Possible exploiter.`)
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
	local shifter = (
		Limb:GetAttribute("ShifterPlayer") and Players:GetPlayerByUserId(Limb:GetAttribute("ShifterPlayer"))
	)
		or TitanModel:GetAttribute("ShifterPlayer")
			and Players:GetPlayerByUserId(TitanModel:GetAttribute("ShifterPlayer"))
	local ShifterClass = Shifter._shifters[shifter.UserId]
	--[[ 	if Limb.Name ~= "ShifterNape" and Limb.Name ~= "ShifterArm" and Limb.Name ~= "ShifterLeg" then
		Log:warn(`Invalid Shifter Hitbox Name: [{Limb.Name}]. ODMPlayer: [{player}] ShifterPlayer: [{shifter}]`)
		return
	end ]]

	if not shifter then
		Log:warn(`[{TitanModel.Name}] missing ShifterPlayer attribute. Fatal error.`)
		return
	end

	if not ShifterClass then
		Log:warn(`[{shifter.UserId}] missing shifter class. Fatal error.`)
		return
	end

	-- player: player who hit
	ShifterClass.servermodule.OnLimbHit(player, shifter, Limb, Damage)
end

--// Special Testing Only function (mostly!)
function Shifter._initPlayerCollisionGroup()
	warn("init player group")
	PhysicsService:RegisterCollisionGroup("Players")
	game:GetService("Players").PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			Property.BatchSet(
				character:GetDescendants(),
				{ CollisionGroup = "Players" },
				nil,
				nil,
				{ "HumanoidRootPart" }
			)
		end)
	end)
end

function Shifter._initCollisionGroups()
	warn("init coll group")
	if not PhysicsService:IsCollisionGroupRegistered("Players") then
		Shifter._initPlayerCollisionGroup()
	end
	warn("registering groups")
	PhysicsService:RegisterCollisionGroup("ShifterParts")
	PhysicsService:RegisterCollisionGroup("PhasethroughShifterTitans")
	PhysicsService:RegisterCollisionGroup("ShifterPlayerHitbox")
	PhysicsService:RegisterCollisionGroup("TitanHRP")
end

function Shifter._configureCollisionGroups()
	repeat
		task.wait(2)
		Shifter._initCollisionGroups()
		Log:warn("Waiting for collision groups to register..")
	until PhysicsService:IsCollisionGroupRegistered("ShifterParts")
		and PhysicsService:IsCollisionGroupRegistered("PhasethroughShifterTitans")
		and PhysicsService:IsCollisionGroupRegistered("ShifterPlayerHitbox")
		and PhysicsService:IsCollisionGroupRegistered("VFXRubble")
		and PhysicsService:IsCollisionGroupRegistered("TitanHRP")
	PhysicsService:CollisionGroupSetCollidable("VFXRubble", "TitanHRP", false)
	PhysicsService:CollisionGroupSetCollidable("Default", "ShifterParts", true)
	PhysicsService:CollisionGroupSetCollidable("VFXRubble", "ShifterParts", false)
	PhysicsService:CollisionGroupSetCollidable("PhasethroughShifterTitans", "VFXRubble", false)
	PhysicsService:CollisionGroupSetCollidable("ShifterPlayerHitbox", "VFXRubble", false)
	PhysicsService:CollisionGroupSetCollidable("ShifterParts", "PhasethroughShifterTitans", false)
	PhysicsService:CollisionGroupSetCollidable("PhasethroughShifterTitans", "Default", true)
	PhysicsService:CollisionGroupSetCollidable("ShifterPlayerHitbox", "Default", false)
	PhysicsService:CollisionGroupSetCollidable("ShifterPlayerHitbox", "ShifterParts", false)
	PhysicsService:CollisionGroupSetCollidable("ShifterPlayerHitbox", "Players", true)
	PhysicsService:CollisionGroupSetCollidable("PhasethroughShifterTitans", "ShifterPlayerHitbox", false)
	PhysicsService:CollisionGroupSetCollidable("PhasethroughShifterTitans", "Players", false)
end

function Shifter._createSignals()
	Satellite.Create("RemoteEvent", "onTitanCreated") -- Used for TransformationSequence. Server notifies all clients that a titan has been created.
	Satellite.Create("RemoteEvent", "TitanAction") -- A remote for Server Defined Titan Actions that a client can fire to activate.
	Satellite.Create("UnreliableRemoteEvent", "UnreliableTitanAction") -- Mainly for IK Control, same code block as TitanAction, but as an unreliable event.
	Satellite.Create("RemoteEvent", "CreateTitan") -- The Start of Transformation Sequence. Sends a signal for all clients to replicate a transformation vfx. This is done on the client.
	Satellite.Create("RemoteEvent", "TransformationVFXFinished") -- The Second Step. Client fires this remote and the server will handle the next step of titan transformation on the server.
	Satellite.Create("RemoteEvent", "ActivateTitan") -- Activates Titan Controller on Client. Reponsible for movement/animations
	Satellite.Create("RemoteEvent", "ReplicateTitanVFX") -- For displaying/replicating Titan Action VFX on clients.
	Satellite.Create("UnreliableRemoteEvent", "UnreliableReplicateTitanVFX") -- Same as ReplicateTitanVFX, but unreliable
	Satellite.Create("RemoteEvent", "ShifterLimbHit") -- Link between ODMClass and this module
	Satellite.Create("RemoteEvent", "SetupCollisionGroups") -- Collision Groups On Client
	Satellite.ListenTo("CreateTitan"):Connect(Shifter.new)
	Satellite.ListenTo("TransformationVFXFinished"):Connect(Shifter._onTransformationSequenceFinish)
	Satellite.ListenTo("TitanAction"):Connect(Shifter._onTitanAction)
	Satellite.ListenTo("UnreliableTitanAction"):Connect(Shifter._onTitanAction)
	Satellite.ListenTo("ShifterLimbHit"):Connect(Shifter._onLimbHit)
end

function Shifter._loadWeightConfig(TitanModel: Model, Config: { Default: Types.DefaultShifterConfig })
	local HumanoidRootPart = TitanModel:WaitForChild("HumanoidRootPart") :: BasePart
	local Weight = Config.Default.WeightForce
	local VectorForce = Instance.new("VectorForce")
	local VectorForceAtt = Instance.new("Attachment")
	--~~[[ Weight ]]~~--
	VectorForce.Force = Vector3.new(0, Weight, 0)
	VectorForceAtt.Parent = HumanoidRootPart
	VectorForce.Attachment0 = VectorForceAtt
	VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	VectorForce.Parent = HumanoidRootPart
end

function Shifter._loadTitanConfig(TitanModel: Model, Config: { Default: Types.DefaultShifterConfig })
	Log:print("Loading Titan Config")
	local Humanoid = TitanModel:WaitForChild("Humanoid") :: Humanoid
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	local HumanoidConfig = Config.Default.Stats.Humanoid
	--~~[[ Humanoid ]]~~--
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
		if v:HasTag("ShifterHitbox") and v:IsA("BasePart") then
			local TitanRef = Instance.new("ObjectValue")
			TitanRef.Name = "_shifterTitanReference"
			TitanRef.Value = TitanModel
			TitanRef.Parent = v
			v.Transparency = 1
			v:SetAttribute("ShifterPlayer", shifter.UserId)
		end
		if v:HasTag("ShifterPlayerHitbox") and v:IsA("BasePart") then
			--v.CanCollide = false
			v.Transparency = 1
			v.CollisionGroup = "ShifterPlayerHitbox"
		end
	end
end

--[[ Public Functions ]]
function Shifter.new(player: Player, force: boolean)
	Log:printheader(`[{player}] initiating a titan sequence. `)
	local character = player.Character or player.CharacterAdded:Wait()
	local ShifterName = player:GetAttribute("ShifterName")
	if not ShifterName or ShifterName == "" or not ShifterTitans:FindFirstChild(ShifterName) then
		Log:warn(`Data for [{player}] missing ShifterName entry in PlayerData dictionary..`)
		return
	end
	if character:GetAttribute("isShifting") then
		return
	end
	character:SetAttribute("isShifting", true)
	local TitanModel = ShifterTitans:FindFirstChild(ShifterName) and ShifterTitans[ShifterName]:Clone() :: Model
	TitanModel:AddTag("isTitan")
	TitanModel:SetAttribute("isForced", force)
	local Config = require(script.Client:WaitForChild(ShifterName):WaitForChild("TitanConfig"))
	if not TitanModel then
		Log:error(
			`No TitanModel called [{ShifterName}}] has been found. Player Source: [{player}}. Possible exploiter.`
		)
		return
	end

	TitanModel:SetAttribute("ShifterPlayer", player.UserId)

	local self = setmetatable({}, Shifter)
	self.player = player :: Player
	self.shiftername = ShifterName :: string
	self.TitanModel = TitanModel :: Model
	self.TitanModel.Name = "Shifter_" .. self.TitanModel.Name
	self._shifters[player.UserId] = self
	self.servermodule = require(script.Server[ShifterName])
	self.config = Config
	--~~[[ Model Config ]]~~--
	local TitanModelDescendants = TitanModel:GetDescendants()
	local HumanoidRootPart = TitanModel:WaitForChild("HumanoidRootPart") :: BasePart
	HumanoidRootPart.CollisionGroup = "TitanHRP"

	Property.BatchSet(
		TitanModelDescendants,
		{ Massless = true, CollisionGroup = "ShifterParts" },
		nil,
		nil,
		{ "BasePart" },
		{ Hitbox = true, HumanoidRootPart = true, IKPart = true }
	)
	Property.BatchSet(TitanModelDescendants, {
		Anchored = false,
	}, nil, nil, { "BasePart" }, { IKPart = true })

	Shifter._setupHitboxTags(TitanModel, player)
	self._loadTitanConfig(TitanModel, Config)
	self:_startTransformationSequence()
	return self
end

--~~[[ Forcer ]]~~--

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 30) :: Humanoid
	if player:GetAttribute("ForcedShifter") and player:GetAttribute("ShifterName") ~= "" then
		humanoid.BreakJointsOnDeath = false
	end
	humanoid.Died:Once(function()
		if
			player:GetAttribute("ForcedShifter")
			and player:GetAttribute("ShifterName") ~= ""
			and humanoid.Parent
			and not humanoid.Parent:HasTag("isTitan")
		then
			humanoid:Destroy()
			Shifter.new(player, true)
			player:SetAttribute("ShifterName", "")
		end
	end)
end

function Shifter._setupForcedPlayersBehaviour()
	Utils.players.OnPlayerAdded(function(player: Player)
		local PlayerData = PlayerDataDB:GetAsync("Player_" .. player.UserId)
		local ShifterNameData = PlayerData.Data and PlayerData.Data.GameData and PlayerData.Data.GameData.ShifterName -- Data:GetData(player, "ShifterName") :: string
		local character = player.Character or player.CharacterAdded:Wait()
		player:SetAttribute("ShifterName", ShifterNameData)
		onCharacterAdded(player, character)
		player.CharacterAdded:Connect(function(_character: Model)
			onCharacterAdded(player, _character)
		end)
		while player:IsDescendantOf(Players) do
			local ShifterName = player:GetAttribute("ShifterName")
			if ShifterName ~= "" then
				player:SetAttribute("ForcedShifter", true)
			else
				player:SetAttribute("ForcedShifter", nil)
			end
			task.wait(5)
		end
		Log:print("Disconnecting shifter checker.")
	end)
end

function Shifter.Start()
	Log:printheader("Shifter Server Initializing..")
	Stopwatch.Start()
	Shifter._initCollisionGroups()
	Shifter._configureCollisionGroups()
	Shifter._startServerTitanModules()
	Shifter._createSignals()
	Shifter._setupForcedPlayersBehaviour()
	Log:printheader(`Shifter Server Initialized in {Stopwatch.Stop()}s.`)
end

--~~[[ Types ]]~~--
export type Class = typeof(Shifter.new(...))

return Shifter
