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
local ShifterFunctions = require(script.Parent.sharedfunctions)
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
local ShifterSFX = ShifterAssets.SFX :: Folder
local ShifterVFX = ShifterAssets.VFX :: Folder
local TitanSpecialSFX = {} :: { [any]: Sound }
local MinimalSteamAura = ShifterVFX.Auras.MinimalSteam:GetChildren() :: { ParticleEmitter }

--// Variables
local LightAttackDB = {}
local HeavyAttackDB = {}
local RoarDB = {}

--// Main
local AttackServer = {}

--~~[[ Init ]]~~--
for _, sound: Sound in ShifterSFX.Special:GetChildren() do
	TitanSpecialSFX[sound.Name] = sound:Clone()
	TitanSpecialSFX[sound.Name].Parent = game:GetService("SoundService")
end

--[[ Private Functions ]]

--[[ Public Functions ]]
--~~[[ Stomps ]]~~--
function AttackServer.LeftStomp(player: Player)
	Satellite.SendAllBut("ReplicateTitanVFX", player, "Attack", "LeftStomp", player)
end

function AttackServer.RightStomp(player: Player)
	Satellite.SendAllBut("ReplicateTitanVFX", player, "Attack", "RightStomp", player)
end

--~~[[ Grab ]]~~--
function AttackServer.Grab(player: Player, hit: Model, hand: BasePart)
	local Ayano = AyanoM.new()
	local TitanModel = player.Character :: Model
	local TargetHumanoid = hit:FindFirstChildOfClass("Humanoid")
	local HumanoidRootPart = hit:FindFirstChild("HumanoidRootPart") :: BasePart
	if not HumanoidRootPart or not TargetHumanoid then
		Log:warn(`[{hit}] missing HumanoidRootPart or Humanoid.`)
		return
	end
	hit:SetAttribute("TitanGrabbed", true)
	local Weld = Ayano:TrackInstance(Instance.new("Weld"))
	Weld.Part0 = hand
	Weld.Part1 = HumanoidRootPart
	Weld.C0 = CFrame.new(Vector3.new(0, -3, 0)) * CFrame.fromOrientation(math.rad(90), 0, 0)
	Weld.Name = "GrabWeld"
	Weld.Parent = hand
	hit:SetAttribute("ShifterGrabbed", true)
	TargetHumanoid.BreakJointsOnDeath = false
	TargetHumanoid.EvaluateStateMachine = false
	TargetHumanoid.PlatformStand = true

	local function Ungrab()
		print("HELLO")
		if TitanModel:GetAttribute("UnGrab" .. hand.Name) then
			hit:SetAttribute("TitanGrabbed", nil)
			hit:SetAttribute("ShifterGrabbed", nil)
			Ayano:Clean()
			TitanModel:SetAttribute("UnGrab" .. hand.Name, false)
			TargetHumanoid.PlatformStand = false
			TargetHumanoid.BreakJointsOnDeath = true
			TargetHumanoid.EvaluateStateMachine = true
		end
	end

	local function Eat()
		if TitanModel:GetAttribute("Eat") then
			TitanModel:SetAttribute("Eat", false)
			TitanModel:SetAttribute("UnGrab" .. hand.Name, true)
			local Chomp = TitanModel:FindFirstChild("TitanHead")
				and TitanModel.TitanHead:FindFirstChild("Teeth")
				and TitanModel.TitanHead.Teeth:FindFirstChild("Chomp") :: Attachment
			if Chomp then
				Sound.Play(Chomp)
				VFX.EmitParticle(Chomp)
			end
			Ungrab()
			TargetHumanoid.Health = 0
		end
	end

	local function UpdateHealth()
		if TargetHumanoid.Health <= 0 then
			TitanModel:SetAttribute("UnGrab" .. hand.Name, true)
			Ungrab()
			TargetHumanoid.BreakJointsOnDeath = true
			TargetHumanoid.EvaluateStateMachine = true
		end
	end

	Ayano:Connect(TitanModel:GetAttributeChangedSignal("UnGrab" .. hand.Name), Ungrab)
	Ayano:Connect(TitanModel:GetAttributeChangedSignal("Eat"), Eat)
	Ayano:Connect(TargetHumanoid.Died, Ungrab)
	Ayano:Connect(TargetHumanoid:GetPropertyChangedSignal("Health"), UpdateHealth)
end
function AttackServer.UnGrab(player: Player, hand: BasePart)
	warn(hand.Name)
	local TitanModel = player.Character
	TitanModel:SetAttribute("UnGrab" .. hand.Name, true)
end

--~~[[ Beserk ]]~~--
function AttackServer.Beserk(player: Player)
	local character = player.Character
	if character then
		character:SetAttribute("isBeserk", true)
		Satellite.SendAll("ReplicateTitanVFX", "Attack", "Beserk", player)
		task.delay(TitanConfig.Custom.Combat.Beserk.Duration, function()
			character:SetAttribute("isBeserk", false)
		end)
	end
end

--~~[[ Block ]]~~--
function AttackServer.Block(player: Player, state: boolean)
	Log:print(`[{player}] changing block state to [{state}]`)
	local character = player.Character
	if character then
		character:SetAttribute("isBlocking", state)
		character:SetAttribute(
			"DamageReductionFactor",
			state == true and TitanConfig.Custom.Combat.Block.DamageReductionFactor or nil
		)
	end
end

--~~[[ Hit ]]~~--
function AttackServer.TitanHit(player: Player, HitIndex: number, ...)
	Satellite.SendAll("ReplicateTitanVFX", "Attack", "TitanHit", player, HitIndex, ...)
end

function AttackServer.LightHit(player: Player, CharacterList: { Model }, AttackIndex: number)
	local AttackTitan = player.Character
	local StunCD = TitanConfig.Custom.Combat.LMB.StunCooldown
	local StunDuration = TitanConfig.Custom.Combat.LMB.StunDuration
	if LightAttackDB[player] then
		return
	end
	LightAttackDB[player] = true
	for _, character in pairs(CharacterList) do
		local Damage = ShifterFunctions.GetDamage(
			TitanConfig,
			character,
			AttackTitan,
			TitanConfig.Custom.Combat.LMB.ComboDamageIndex[AttackIndex]
		)
		ShifterFunctions.ApplyStun(character, StunCD, StunDuration)
		Log:print(`Attack titan dealing {Damage} dmg from light attack..`)
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
	task.delay(0.75, function()
		LightAttackDB[player] = nil
	end)
end

function AttackServer.HeavyHit(player: Player, CharacterList: { Model })
	local AttackTitan = player.Character
	local StunCD = TitanConfig.Custom.Combat.Heavy.StunCooldown
	local StunDuration = TitanConfig.Custom.Combat.Heavy.StunDuration
	if HeavyAttackDB[player] then
		return
	end
	HeavyAttackDB[player] = true
	for _, character in pairs(CharacterList) do
		local Damage =
			ShifterFunctions.GetDamage(TitanConfig, character, AttackTitan, TitanConfig.Custom.Combat.Heavy.Damage)
		ShifterFunctions.ApplyStun(character, StunCD, StunDuration)
		Log:print(`Attack titan dealing {Damage} dmg from heavy attack.`)
		local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
	task.delay(TitanConfig.Custom.Combat.Heavy.Cooldown / 1.5, function()
		HeavyAttackDB[player] = nil
	end)
end

function AttackServer.NapeEject(player: Player, dead: boolean)
	--~~[[ Character Destroy Behaviour Workaround]]~~--
	local TitanModel = player.Character :: Model
	TitanModel.Parent = nil
	local UpperTorso = TitanModel.UpperTorso :: BasePart
	local TitanHumanoid = TitanModel:FindFirstChild("Humanoid") :: Humanoid
	player.Character = nil
	TitanModel.Parent = game.Workspace
	UpperTorso.Anchored = true
	TitanHumanoid:Destroy()
	player:LoadCharacter()
	Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 0.5, function()
		Property.BatchSet(TitanModel:GetDescendants(), { CanCollide = false }, nil, nil, { "HumanoidRootPart" })
		TitanModel:SetAttribute("UnGrab", true)
		Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			TitanModel:Destroy()
		end, FadeFilter)
	end, FadeFilter)
	--~~[[ Sound ]]~~--
	local Steam = TitanSpecialSFX.Steam:Clone()
	Steam.Parent = TitanModel.PrimaryPart
	Steam:Play()
	Satellite.SendAll("ReplicateTitanVFX", "Attack", "NapeEject", player)
	--~~[[ Main ]]~~--
	local playerCharacter = player.Character or player.CharacterAdded:Wait()
	local playerHumanoid = playerCharacter:FindFirstAncestorOfClass("Humanoid")
		or playerCharacter:WaitForChild("Humanoid", 10) :: Humanoid
	playerCharacter:PivotTo(CFrame.new((UpperTorso.CFrame * CFrame.new(0, 0, 16)).Position))
	playerCharacter.Parent = game.Workspace
	if dead == true then
		playerHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		Satellite.Send("ReplicateTitanVFX", player, "General", "Ragdoll")
	end
end

function AttackServer.NapeGuard(player: Player, state: boolean)
	local TitanModel = player.Character
	TitanModel:SetAttribute("NapeGuard", state)
end

function AttackServer.Landed(player: Player)
	Satellite.SendAll("ReplicateTitanVFX", "Attack", "Landed", player)
end

function AttackServer.Died(player: Player)
	local TitanModel = player.Character
	local HumanoidRootPart = TitanModel.HumanoidRootPart :: BasePart
	local Humanoid = TitanModel.Humanoid :: Humanoid
	local SteamID = HttpService:GenerateGUID()
	local Steam = TitanSpecialSFX.Steam:Clone()
	Humanoid:Destroy()
	HumanoidRootPart.Anchored = true
	VFX.AddAura(MinimalSteamAura, TitanModel, SteamID)
	Steam.Parent = HumanoidRootPart
	Steam:Play()
	Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 0.5, function()
		Property.BatchSet(TitanModel:GetDescendants(), { CanCollide = false }, nil, nil, { "HumanoidRootPart" })
		TitanModel:SetAttribute("UnGrab", true)
		Basepart.Fade(TitanModel, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			player:LoadCharacter()
			TitanModel:Destroy()
			Steam:Destroy()
			VFX.RemoveAura(SteamID)
		end, FadeFilter)
	end, FadeFilter)
end

function AttackServer.Voided(player: Player)
	local character = player.Character
	if character then
		character:Destroy()
	end
	player:LoadCharacter()
end

function AttackServer.NapeEjectInit(player: Player)
	local SteamAuraID = HttpService:GenerateGUID()
	local TitanModel = player.Character
	VFX.AddAura(MinimalSteamAura, TitanModel, SteamAuraID, TitanConfig.Custom.AuraTweenInfo)
	task.delay(10, function()
		VFX.RemoveAura(SteamAuraID)
	end)
end

function AttackServer.Roar(player: Player)
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

function AttackServer.UpdateIK(player: Player, ...)
	Satellite.SendAllBut("UnreliableReplicateTitanVFX", player, ...)
end

function AttackServer.SetIK(_, IKControl: IKControl, state: boolean)
	if state == false then
		TweenService:Create(IKControl, TitanConfig.Custom.IKTweenInfo, { Weight = 0 }):Play()
	else
		TweenService:Create(IKControl, TitanConfig.Custom.IKTweenInfo, { Weight = 1 }):Play()
	end
end

return AttackServer
