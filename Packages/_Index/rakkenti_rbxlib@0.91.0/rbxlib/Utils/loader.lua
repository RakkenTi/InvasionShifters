--[[

@rakken
Class for loading children/descendant modules.

]]

--// Modules
local _Log = require(script.Parent.log)
local Stopwatch = require(script.Parent.stopwatch)

--// Module-Constants
local Log = _Log.new("[Client Loader]")

--// Main
local Loader = {}

function Loader.LoadChildren(root: Instance)
	for _, module in root:GetChildren() do
		if module:IsA("ModuleScript") then
			Stopwatch.Start()

			require(module)

			Log:print(`loaded [{module}] | Took {Stopwatch.Stop()}s`)
		end
	end
end

function Loader.LoadDescendants(root: Instance)
	for _, module in root:GetDescendants() do
		if module:IsA("ModuleScript") then
			Stopwatch.Start()

			require(module)

			Log:print(`loaded [{module}] | Took {Stopwatch.Stop()}s`)
		end
	end
end

return Loader
