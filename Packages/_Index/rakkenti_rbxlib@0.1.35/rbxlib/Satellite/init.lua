--[[

@rakken

SATELLITE 2.0.0

Signal Module. Includes Unreliable Remote Events.
Simple.

Does not optimize bandwith usage.

SUPPORTED TYPES:
- Bindable Event
- Remote Event
- Unreliable Event

TYPES:
1 --> Function
2 --> Unreliable

Wrapper Module

]]

--// Services
local RunService = game:GetService("RunService")

--// Main
if RunService:IsServer() then
	Instance.new("Folder", script).Name = "__events"
	return require(script.Server)
else
	script:WaitForChild("__events")
	return require(script.Client)
end
