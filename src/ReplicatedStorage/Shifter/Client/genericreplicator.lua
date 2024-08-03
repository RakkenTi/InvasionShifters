--[[

@rakken
Handles generic replication tasks

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local Rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Utils = Rbxlib.Utils
local Satellite = Rbxlib.Satellite

--// Module-Constants
local Log = Utils.log.new("[Generic Replicator]")
local Stopwatch = Utils.stopwatch
local Reference = Utils.reference

--// Constants
local player = Reference.Client.Player

--// Variables

--// Main
local GenericReplicator = {}

--[[ Private Functions ]]
local function UpdateIKPart(IKControl: IKControl, Part: BasePart, Pos: Vector3)
	if not IKControl.Target then
		IKControl.Target = Part
	end
	Part.Position = Pos
end

local function Ragdoll()
	Log:print("Ragdollling")
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
			or character:WaitForChild("Humanoid", 5) :: Humanoid
		Log:print("Ragdolled")
		humanoid.PlatformStand = true
		task.wait(4)
		humanoid.PlatformStand = false
	end
end

local function OnTitanVFX(category: string, action: string)
	if category ~= "General" then
		return
	end
	if action == "Ragdoll" then
		Ragdoll()
	end
end

local function initIKReplicator()
	Satellite.ListenTo("UnreliableReplicateTitanVFX"):Connect(UpdateIKPart)
	Satellite.ListenTo("ReplicateTitanVFX"):Connect(OnTitanVFX)
end

--[[ Public Functions ]]
function GenericReplicator.Start()
	Stopwatch:Start()
	Log:print("Intializing Generic Replicator..")
	initIKReplicator()
	Log:print(`Generic Replicated started in {Stopwatch}s`)
end

return GenericReplicator
