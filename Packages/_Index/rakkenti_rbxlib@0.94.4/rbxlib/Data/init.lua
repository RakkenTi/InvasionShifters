--[[

@rakken

]]

--// Services
local Players = game:GetService("Players")

--// Modules
local Utils = require(script.Parent.Utils)
local Satellite = require(script.Parent.Satellite)
local ProfileService = require(script.ProfileService)
local DataTemplate = require(script.DataTemplate)

--// Variables
local PlayerKeyPrefix = "Player_"
local PlayerDataStore = ProfileService.GetProfileStore("PlayerData", DataTemplate)

--// Setup
local Log = Utils.log.new("[DATA]")

--// Satellite

local __Info = {
	Name = script.Name, -- Reference [NAME] for use by Satellite:JoinAntenna([NAME])
	Ref = script, -- Ref should always be equal to the script. By use ObjectValue
}

--// Variables
local DebugMode = script:GetAttribute("DebugMode")

--/// Main

local Module = {}
Module._profiles = {}

--// Private Functions

local function getPath(root: {}, targetkey: string)
	-- root = just the starting table, can hold tables inside it too.
	-- targetkey = name of key to search f

	for key, v in pairs(root) do
		if key == targetkey then
			return root
		end

		if typeof(v) == "table" then
			local success = getPath(v, targetkey)

			if success then
				return success
			end
		end
	end

	return nil
end

-- Send Signals to update anything that requires it when a player's data entry is changed.
local function SendSignals(player: Player, DataKeyName: string, NewValue: any)
	Satellite.Send("REMOTE.DATA_UPDATE_PLAYER", player, DataKeyName, NewValue)
	Satellite.Send("SERVER.DATA_UPDATE_PLAYER", player, DataKeyName, NewValue)
end

local function Init()
	--// Create Signal and CrossSignal that let's a player or server script know if a Player's data entry has been updated.

	Satellite.Create("RemoteEvent", "REMOTE.DATA_UPDATE_PLAYER")
	Satellite.Create("BindableEvent", "SERVER.DATA_UPDATE_PLAYER")

	Players.PlayerRemoving:Connect(function(player: Player)
		if Module._profiles[player] then
			if DebugMode then
				Log:print(`Player leaving: [{player.UserId}] | [{player.Name}]. Releasing profile.`, Log.Presets.LOG)
			end

			Module._profiles[player]:Release(Module)
		else
			if DebugMode then
				Log:warn(`Player [{player.UserId}] | [{player.Name}] has no profile when leaving.`, Log.Presets.WARNING)
			end
		end
	end)

	for _, player in Players:GetPlayers() do
		Module.InitPlayer(Module, player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		Module.InitPlayer(Module, player)
	end)

	Log:messageheader("DATA MODULE INIT COMPLETE")
end

--// Public Functions

-- Load's player data. Should be connected to PlayerAdded.
function Module:InitPlayer(player: Player)
	Log:print(`Getting profile for player [{player.Name}] | [{player.UserId}].`)

	if self._profiles[player] then
		return Log:warn(`Profile already loaded for ` .. player.Name)
	end

	local profile = PlayerDataStore:LoadProfileAsync(PlayerKeyPrefix .. player.UserId)

	if not profile then
		Log:warn(`Failed to load player data for [{player.Name}] | [{player.UserId}].`, Log.Presets.CRITICAL_ERROR)
		player:Kick("Failed to load data. Please rejoin.")
	end

	-- Don't touch
	profile:AddUserId(player.UserId)

	-- Reload template to profile
	profile:Reconcile()

	-- Called when Release() method is called on profile.

	profile:ListenToRelease(function()
		Log:warn(`Player [{player.Name}] | [{player.UserId}] profile released.`, Log.Presets.WARNING)
		self._profiles[player] = nil
		player:Kick()
	end)

	-- Handle case where player leaves before profile is loaded.
	if not player:IsDescendantOf(Players) then
		Log:warn(`Player [{player.Name}] | [{player.UserId}] left before profile is loaded.`)
		profile:Release()
		return
	end

	-- Finish setting up profile by adding it to table.
	self._profiles[player] = profile

	Log:print(`[{player.Name}] | [{player.UserId}]`)
end

function Module:GetProfile(player: Player, yield: boolean?)
	if DebugMode then
		Log:print(`Retrieving profile for: [{player.Name}] | [{player.UserId}].`)
	end

	local profile = self._profiles[player]

	if profile then
		return profile
	end
	if not yield then
		return nil
	end

	Log:warn(
		`Yielding until profile found for player: [{player.Name}] | [{player.UserId}]. | Trace: [{debug.info(2, "s")}]`,
		Log.Presets.ERROR
	)

	local i, s = 0, false

	repeat
		task.wait()
		i = i + 1

		if i > 120 and not s then
			s = true
			Log:warn(`Infinite yield for profile possible for [{player.Name}] | [{player.UserId}]`)
		end

		profile = self._profiles[player]

	until profile or i > 1000

	Log:assert(
		profile,
		`Profile could not be loaded for [{player.Name}] | [{player.UserId}]. [YIELD IS ON]`,
		Log.Presets.CRITICAL_ERROR
	)
	Log:warn(
		profile,
		`Yield successful, profile found for player: [{player.Name}] | [{player.UserId}]. [YIELD IS ON]`,
		Log.Presets.LOG
	)

	return profile
end

function Module:SetData(player: Player, key: string, data: any)
	if DebugMode then
		Log:print(`[{player.Name}] | [{player.UserId}] >> SETTING DATA`)
		Log:print(`KEY: [{key}] | DATA: [{data}] | Trace: [{debug.info(2, "s")}]`)
	end

	-- Get Profile
	local profile = self:GetProfile(player, true)
	local path = getPath(profile.Data, key)

	if DebugMode then
		Log:assert(
			path,
			`Could not get path for player: [{player.Name}] | [{player.UserId}]. Key: [{key}].`,
			Log.Presets.ERROR
		)
		Log:assert(
			path[key],
			`Could not get key in path for player: [{player.Name}] | [{player.UserId}]. Key: [{key}]. Path: [{path}].`,
			Log.Presets.ERROR
		)
	end

	-- Perform change in data
	path[key] = data

	-- Update Server and client.
	SendSignals(player, key, data)

	if DebugMode then
		Log:print(
			`Successfully changed data for [{player.Name}] | [{player.UserId}] | KEY: [{key}] | NEWVALUE: [{data}].`
		)
	end
end

function Module:GetData(player: Player, key: string)
	if DebugMode then
		Log:print(`[{player.Name}] | [{player.UserId}] >> RETRIEVING DATA`)
		Log:print(`KEY: [{key}] | PLAYER: [{player.Name}] | [{player.UserId}]. | Trace: [{debug.info(2, "s")}]`)
	end

	-- Get Profile
	local profile = self:GetProfile(player, true)
	local path = getPath(profile.Data, key)

	if DebugMode then
		Log:assert(
			path,
			`Could not get path for player: [{player.Name}] | [{player.UserId}]. Key: [{key}].`,
			Log.Presets.ERROR
		)
		Log:assert(
			path[key],
			`Could not get key in path for player: [{player.Name}] | [{player.UserId}]. Key: [{key}]. Path: [{path}].`,
			Log.Presets.ERROR
		)
	end

	return path[key]
end

--// Init
Init()

return Module
