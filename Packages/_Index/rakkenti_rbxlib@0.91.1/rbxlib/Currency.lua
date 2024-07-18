--[[

@rakken

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local Utils = require(script.Parent.Utils)
local Data = require(script.Parent.Data)

--// Setup
local Log = Utils.log.new("[CURRENCY]")

--/// Main

local Module = {}

--// Private Functions

local function Update(player: Player)
	Log:print(`Updated currency for: [{player}] | [{Data:GetData(player, "Currency")}]`)
	player:SetAttribute("Currency", Data:GetData(player, "Currency"))
end

--// Public Functions

function Module:Load(player: Player)
	Update(player)
end

function Module:Add(player: Player, amount: number)
	Data:SetData(player, "Currency", Data:GetData(player, "Currency") + amount)
	Update(player)
end

function Module:Subtract(player: Player, amount: number)
	Data:SetData(player, "Currency", Data:GetData(player, "Currency") - amount)
	Update(player)
end

function Module:Set(player: Player, amount: number)
	Data:SetData(player, "Currency", amount)
	Update(player)
end

function Module:Get(player: Player)
	return Data:GetData(player, "Currency")
end

--// Init
for _, player in Players:GetPlayers() do
	Update(player)
end

Log:printheader(`Currency Manager has started.`)

return Module
