--[[

@rakken

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local Utils = require(script.Parent.Parent.Utils)

--// Module-Constnats
local Log = Utils.log.new("[TaikaGui // State]")

--// Main
local State = {}

function State.Load(self, state: string, tweenInfo: TweenInfo)
	local SelectedClass = self:RetrieveSelectedClass()
	local StateTable = SelectedClass.states
	local Element = SelectedClass.instance
	SelectedClass.lastStateUsed = state
	Utils.property.SetTable(Element, StateTable)
	return self
end

function State.Create(self, name: string, stateTable: {})
	local SelectedClass = self:RetrieveSelectedClass()
	Log:assert(not SelectedClass.states[name], `State with name: [{name}] already exists.`)
	SelectedClass.states[name] = stateTable
	return self
end

return State
