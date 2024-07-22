--[[

@rakken

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules

--// Constants
local Log = require(script.Parent.log)

--/// Main
local Module = {}
Module.__index = Module

--// Private Functions

--// Public Functions

function Module.new()
	Log:print("New Vacuum Instance created.", Log.Presets.LOG)

	local self = setmetatable({}, Module)
	self._AllConnections = {}
	self._AllTweens = {}

	return self
end

function Module:Connect(connection: RBXScriptConnection | thread)
	if not connection then
		Log:error(`Cannot connect to vacuum. No connection given. [{connection}]`)
		return
	end

	table.insert(self._AllConnections, connection)

	return connection
end

function Module:Tween(tween: Tween)
	if not tween then
		Log:error(`Cannot connect to vacuum. No tween given. [{tween}]`)
		return
	end

	table.insert(self._AllTweens, tween)

	return tween
end

function Module:CleanTweens()
	if #self._AllTweens == 0 then
		return
	end

	for _, tween: Tween in ipairs(self._AllTweens) do
		tween:Cancel()
	end
end

function Module:CleanConnections()
	if #self._AllConnections == 0 then
		return
	end

	for i, connection: Instance in ipairs(self._AllConnections) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end

		if typeof(connection) == "thread" then
			task.cancel(connection)
		end

		table.remove(self._AllConnections, i)
	end
end

--// Init

return Module
