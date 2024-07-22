--[[

@rakken
Jaw-Titan Server Side

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--// Modules
local AssetConfig = require(script.Parent.Parent.AssetConfig)
local TitanConfig = require(script.Parent.Parent.Client.Jaw.TitanConfig)
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Basepart = Utils.basepart
local VFX = Utils.vfx

--// Module-Constants
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
local RoarDB = {}

--// Main
local JawServer = {}

--[[ Private Functions ]]

--[[ Public Functions ]]
function JawServer.LightHit(player: Player, CharacterList: { Model })
	if LightAttackDB[player] then
		return
	end
	LightAttackDB[player] = true
	local Damage = TitanConfig.Custom.Combat.LightAttack.Damage
	for _, character in ipairs(CharacterList) do
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
	task.delay(0.75, function()
		LightAttackDB[player] = nil
	end)
end

function JawServer.NapeEject(player: Player, OldCharacter: Model)
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
		Basepart.SetCollide(TitanModel, false)
		Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			TitanModel:Destroy()
		end, FadeFilter)
	end, FadeFilter)

	--~~[[ Main ]]~~--
	local playerCharacter = player.Character
	local playerHumanoid = playerCharacter:FindFirstAncestorOfClass("Humanoid")
		or playerCharacter:WaitForChild("Humanoid", 10) :: Humanoid
	local Animate = playerCharacter:WaitForChild("Animate") :: Script
	playerHumanoid.Health = playerHumanoid.MaxHealth
	playerCharacter:PivotTo(CFrame.new((UpperTorso.CFrame * CFrame.new(0, 0, 10)).Position))
	playerCharacter.Parent = game.Workspace
	Animate.Enabled = true
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "NapeEject", player)
end

function JawServer.Died(player: Player)
	local TitanModel = player.Character
	local HumanoidRootPart = TitanModel.HumanoidRootPart :: BasePart
	local Humanoid = TitanModel.Humanoid :: Humanoid
	Humanoid:Destroy()
	HumanoidRootPart.Anchored = true
	Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 0.5, function()
		Basepart.SetCollide(TitanModel, false)
		Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			TitanModel:Destroy()
		end, FadeFilter)
		player:LoadCharacter()
	end, FadeFilter)
end

function JawServer.Voided(player: Player)
	local character = player.Character
	if character then
		character:Destroy()
	end
	player:LoadCharacter()
end

function JawServer.NapeEjectInit(player: Player)
	local SteamAuraID = HttpService:GenerateGUID()
	local TitanModel = player.Character
	VFX.AddAura(MinimalSteamAura, TitanModel, SteamAuraID, TitanConfig.Custom.AuraTweenInfo)
	task.delay(10, function()
		VFX.RemoveAura(SteamAuraID)
	end)
end

function JawServer.Roar(player: Player)
	if RoarDB[player] then
		return
	end
	RoarDB[player] = true
	task.delay(10, function()
		RoarDB[player] = false
	end)
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "Roar", player)
	local TickCount = TitanConfig.Custom.Combat.Roar.TickCount
	local Damage = TitanConfig.Custom.Combat.Roar.Damage
	local Character = player.Character
	local HumanoidRootPart = Character.HumanoidRootPart :: BasePart
	for _ = 1, TickCount do
		task.wait(0.1)
		if Damage > 0 then
			for _, _player in Players:GetPlayers() do
				if player == _player then
					continue
				end
				local character = _player.Character
				local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
				if character and hrp then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					local distance = (HumanoidRootPart.Position - hrp.Position).Magnitude
					if humanoid and distance <= TitanConfig.Custom.Combat.Roar.Range then
						humanoid:TakeDamage(Damage)
					end
				end
			end
			if game.Workspace:FindFirstChild("Dummies") then
				for _, character in game.Workspace:FindFirstChild("Dummies"):GetChildren() do
					local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
					if character and hrp then
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						local distance = (HumanoidRootPart.Position - hrp.Position).Magnitude
						if humanoid and distance <= TitanConfig.Custom.Combat.Roar.Range then
							humanoid:TakeDamage(Damage)
						end
					end
				end
			end
		end
	end
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "Roar", player, true)
end

return JawServer
