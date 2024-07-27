--[[

@rakken
Satellite Client

Features:
- Send Remote Events, BindableEvents, BindableFunctions
- Various Send Methods (All, Within)
- Automatic safety checks (No duplicates)
- Retrieve Remote Events, BindableEvents, BindableFunctions
- All events stored in one place
]]

--// Services
local HttpService = game:GetService("HttpService")

--// Modules
local GoodSignal = require(script.Parent.Parent.GoodSignal)
local Utils = require(script.Parent.Parent.Utils)

--// Types
type EventTypes = "RemoteEvent" | "UnreliableRemoteEvent" | "BindableEvent"

--// Module-Constants
local Log = Utils.log.new("[Satellite Client]")

--// Constants
local Events = script.Parent.__events

--// Main
Log:disable()

local Client = {}
Client._bindables = {}

function Client.Create(class: "BindableEvent", id: string)
	if not id then
		id = HttpService:GenerateGUID()
	end

	if Events:FindFirstChild(id) then
		Log:warn(`Event with name: [{id}] already exists.`)
		return
	end

	if class == "BindableEvent" then
		local signal = GoodSignal.new()
		Client._bindables[id] = signal
		return signal
	end

	local event = Instance.new(class)
	event.Name = id
	event.Parent = Events

	return event
end

function Client.ListenTo(id: string)
	local event = Client.Retrieve(id) :: Instance

	if Client._bindables[id] then
		return Client._bindables[id]
	end

	if event:IsA("RemoteEvent") or event:IsA("UnreliableRemoteEvent") then
		return event.OnClientEvent
	end

	if event:IsA("RemoteFunction") then
		Log:error(`Server cannot send remote events. ID: [{id}]`)
		return false
	end
	return false
end

function Client.Send(id: string, ...)
	local event = Client.Retrieve(id) :: Instance

	if Client._bindables[id] then
		local signal = Client._bindables[id]
		signal:Fire(...)
		return
	end

	if event:IsA("RemoteEvent") or event:IsA("UnreliableRemoteEvent") then
		Log:print("Firing to server")
		event:FireServer(...)
	end

	if event:IsA("RemoteFunction") then
		return event:InvokeServer(...)
	end
end

function Client.Retrieve(id: string): Instance
	return Client._bindables[id] or Events:WaitForChild(id)
end

return Client
