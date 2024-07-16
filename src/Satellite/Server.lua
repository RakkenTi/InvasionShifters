--[[

@rakken
Satellite Client

Features:
- Send Remote Events
- Various Send Methods (All, Within)
- Automatic safety checks (No duplicates)
- Retrieve Remote Events, 
- All remote events stored in one place
]]

--// Players
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local Utils = require(script.Parent.Parent.Utils)
local GoodSignal = require(script.Parent.Parent.GoodSignal)

--// Types
type EventTypes = "RemoteEvent" | "RemoteFunction" | "UnreliableRemoteEvent" | "BindableEvent"

--// Module-Constants
local Log = Utils.log.new("[Satellite Client]")

--// Constants
local Events = script.Parent.__events

--// Main
local Server = {}
Server._bindables = {}

function Server.Create(class: EventTypes, id: string)
	if Events:FindFirstChild(id) then
		Log:warn(`Event with name: [{id}] already exists.`)
		return
	end

	if class == "BindableEvent" then
		local signal = GoodSignal.new()
		Server._bindables[id] = signal
		return signal
	end

	local event = Instance.new(class)
	event.Name = id
	event.Parent = Events

	return event
end

function Server.Send(eventsource: any, player: Player, ...)
	local event = eventsource :: Instance

	if Server._bindables[eventsource] then
		local signal = Server._bindables[eventsource]
		signal:Fire(...)
		return
	end

	if typeof(event) == "string" then
		event = Server.Retrieve(eventsource)
	end

	if event:IsA("RemoteEvent") or event:IsA("UnreliableRemoteEvent") then
		event:FireClient(player, ...)
	end

	if event:IsA("RemoteFunction") then
		Log:error(`Server tried to invoke client with remote: [{event}] | [{player}]. Denied access.`)
	end
end

function Server.SendWithin(eventname: string, pos: Vector3, radius: number, ...)
	local event = Server.Retrieve(eventname) :: Instance

	for _, player in ipairs(Utils.players.SearchPlayers(pos, radius)) do
		Server.Send(event, player, ...)
	end
end

function Server.SendAll(eventname: string, ...)
	for _, player in Players:GetPlayer() do
		Server.Send(eventname, player, ...)
	end
end

function Server.ListenTo(eventname: string)
	local event = Server.Retrieve(eventname) :: Instance

	if event:IsA("RemoteEvent") or event:IsA("UnreliableRemoteEvent") then
		return event.OnServerEvent
	end

	if event:IsA("RemoteFunction") then
		return event
	end
end

function Server.Retrieve(id: string): CustomEvent
	return Events:WaitForChild(id)
end

return Server
