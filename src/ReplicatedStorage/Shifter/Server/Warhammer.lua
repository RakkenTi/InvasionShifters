--[[

@rakken
Warhammer-Titan Server Side

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--// Modules
local AssetConfig = require(script.Parent.Parent.AssetConfig)
local TitanConfig = require(script.Parent.Parent.Client.Jaw.TitanConfig)
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Property = Utils.property
local Basepart = Utils.basepart
local AyanoM = Utils.ayano
local Sound = Utils.sound
local VFX = Utils.vfx

--// Module-Constants
local Log = Utils.log.new("[Jaw Titan]")
local FadeFilter = {
	["HumanoidRootPart"] = true,
	["Hitbox"] = true,
}

--// Constants
local ShifterAssets = AssetConfig.ShifterAssets :: Folder
local ShifterVFX = ShifterAssets.VFX :: Folder
local MinimalSteamAura = ShifterVFX.Auras.MinimalSteam:GetChildren() :: { ParticleEmitter }

--// Variables

--// Main
local WarhammerServer = {}

--[[ Private Functions ]]

--[[ Public Functions ]]

return WarhammerServer
