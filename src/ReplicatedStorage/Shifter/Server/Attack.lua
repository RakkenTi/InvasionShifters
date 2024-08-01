--[[

@rakken
Attack-Titan Server Side

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--// Modules
local AssetConfig = require(script.Parent.Parent.AssetConfig)
local TitanConfig = require(script.Parent.Parent.Client.Attack.TitanConfig)
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
local LightAttackDB = {}
local HeavyAttackDB = {}
local RoarDB = {}

--// Main
local AtackServer = {}

--[[ Private Functions ]]

--[[ Public Functions ]]
function AtackServer.LightHit(player: Player, CharacterList: { Model }, AttackIndex: number)
	if LightAttackDB[player] then
		return
	end
	LightAttackDB[player] = true
	local Damage = TitanConfig.Custom.Combat.LMB.ComboDamageIndex[AttackIndex]
	Log:print(`Attack titan dealing {Damage} dmg from light attack..`)
	for _, character in pairs(CharacterList) do
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
	task.delay(0.75, function()
		LightAttackDB[player] = nil
	end)
end

function AtackServer.HeavyHit(player: Player, CharacterList: { Model })
	if HeavyAttackDB[player] then
		return
	end
	HeavyAttackDB[player] = true
	local Damage = TitanConfig.Custom.Combat.Heavy.Damage
	Log:print(`Attack titan dealing {Damage} dmg from heavy attack.`)
	for _, character in pairs(CharacterList) do
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
	task.delay(TitanConfig.Custom.Combat.Heavy.Cooldown / 1.5, function()
		HeavyAttackDB[player] = nil
	end)
end

function AtackServer.NapeEject(player: Player)
	--~~[[ Character Destroy Behaviour Workaround]]~~--
	local TitanModel = player.Character :: Model
	TitanModel.Parent = nil
	local UpperTorso = TitanModel.UpperTorso :: BasePart
	local TitanHumanoid = TitanModel:FindFirstChild("Humanoid") :: Humanoid
	player.Character = nil
	player:LoadCharacter()
	TitanModel.Parent = game.Workspace
	UpperTorso.Anchored = true
	TitanHumanoid:Destroy()
	Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 0.5, function()
		Property.BatchSet(TitanModel:GetDescendants(), { CanCollide = false }, nil, nil, { "HumanoidRootPart" })
		TitanModel:SetAttribute("UnGrab", true)
		Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			TitanModel:Destroy()
		end, FadeFilter)
	end, FadeFilter)

	--~~[[ Main ]]~~--
	local playerCharacter = player.Character
	local playerHumanoid = playerCharacter:FindFirstAncestorOfClass("Humanoid")
		or playerCharacter:WaitForChild("Humanoid", 10) :: Humanoid
	playerHumanoid.Health = playerHumanoid.MaxHealth
	playerCharacter:PivotTo(CFrame.new((UpperTorso.CFrame * CFrame.new(0, 0, 16)).Position))
	playerCharacter.Parent = game.Workspace
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "NapeEject", player)
end

function AtackServer.NapeGuard(player: Player, state: boolean)
	local TitanModel = player.Character
	TitanModel:SetAttribute("NapeGuard", state)
end

function AtackServer.Landed(player: Player)
	Satellite.SendAll("ReplicateTitanVFX", "Attack", "Landed", player)
end

function AtackServer.Eat(player: Player)
	local TitanModel = player.Character
	TitanModel:SetAttribute("Eat", true)
end

function AtackServer.UnGrab(player: Player)
	local TitanModel = player.Character
	TitanModel:SetAttribute("UnGrab", true)
end

function AtackServer.Died(player: Player)
	local TitanModel = player.Character
	local HumanoidRootPart = TitanModel.HumanoidRootPart :: BasePart
	local Humanoid = TitanModel.Humanoid :: Humanoid
	Humanoid:Destroy()
	HumanoidRootPart.Anchored = true
	Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 0.5, function()
		Property.BatchSet(TitanModel:GetDescendants(), { CanCollide = false }, nil, nil, { "HumanoidRootPart" })
		TitanModel:SetAttribute("UnGrab", true)
		Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			TitanModel:Destroy()
		end, FadeFilter)
		player:LoadCharacter()
	end, FadeFilter)
end

function AtackServer.Voided(player: Player)
	local character = player.Character
	if character then
		character:Destroy()
	end
	player:LoadCharacter()
end

function AtackServer.NapeEjectInit(player: Player)
	local SteamAuraID = HttpService:GenerateGUID()
	local TitanModel = player.Character
	VFX.AddAura(MinimalSteamAura, TitanModel, SteamAuraID, TitanConfig.Custom.AuraTweenInfo)
	task.delay(10, function()
		VFX.RemoveAura(SteamAuraID)
	end)
end

function AtackServer.Roar(player: Player)
	if RoarDB[player] then
		return
	end
	RoarDB[player] = true
	task.delay(10, function()
		RoarDB[player] = false
	end)
	Satellite.SendAll("ReplicateTitanVFX", "Attack", "Roar", player)
	task.wait(TitanConfig.Custom.Combat.Roar.Duration)
	Satellite.SendAll("ReplicateTitanVFX", "Attack", "Roar", player, true)
end

-- Limb Hit Handlers

function AtackServer._onNapeHit(playerWhoHit: Player, shifter: Player, Damage: number)
	local TitanModel = shifter.Character
	local TitanHumanoid = TitanModel:FindFirstChildOfClass("Humanoid")
		or TitanModel:WaitForChild("Humanoid", 5) :: Humanoid
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s nape`)
	if TitanModel:GetAttribute("NapeGuard") then
		Damage *= TitanConfig.Custom.Combat.NapeGuard.ReductionFactor
	end
	TitanHumanoid:TakeDamage(Damage)
end

function AtackServer._onArmHit(playerWhoHit: Player, Limb: BasePart, shifter: Player)
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s arm`)
	local TitanModel = Limb.Parent
		and Limb.Parent.Parent
		and Limb.Parent.Parent:IsA("Model")
		and Limb.Parent.Parent :: Model

	if not TitanModel then
		Log:warn(`[{Limb}] titan arm missing titan model parent (.Parent.Parent)`)
		return
	end

	local Position = Limb:GetAttribute("pos")
	local LowerArm = (
		(Position == "left") and TitanModel:FindFirstChild("LeftLowerArm")
		or ((Position == "right") and TitanModel:FindFirstChild("RightLowerArm"))
		or nil
	) :: BasePart
	local UpperArm = (
		(Position == "left") and TitanModel:FindFirstChild("LeftUpperArm")
		or ((Position == "right") and TitanModel:FindFirstChild("RightUpperArm"))
		or nil
	) :: BasePart

	if not LowerArm or not UpperArm then
		Log:warn(`Missing [LowerArm][{LowerArm}] or [UpperArm][{UpperArm}] from Titan.`)
		return
	end
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "ArmHit", shifter, Position)
end

--[[
function JawServer._onLegHit(playerWhoHit: Player, Limb: BasePart, shifter: Player, Damage: number)
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s nape leg`)
end
]]

function AtackServer.OnLimbHit(playerWhoHit: Player, shifter: Player, Limb: BasePart, Damage: number)
	if Limb.Name == "ShifterNape" then
		AtackServer._onNapeHit(playerWhoHit, shifter, Damage)
	elseif Limb.Name == "ShifterArm" then
		AtackServer._onArmHit(playerWhoHit, Limb, shifter)
		--elseif Limb.Name == "ShifterLeg" then
		--JawServer._onLegHit(playerWhoHit, Limb, shifter, Damage)
	end
end

return AtackServer
