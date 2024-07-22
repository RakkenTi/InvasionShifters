--[[

@rakken
Module Loader for Server-Side of Shifters.

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Utils = rbxlib.Utils
local Loader = Utils.loader

return function()
	Loader.LoadChildren(script)
end
