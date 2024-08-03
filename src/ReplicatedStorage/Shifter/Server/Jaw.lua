--[[

@rakken
Jaw-Titan Server Side

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--// Modules
local AssetConfig = require(script.Parent.Parent.AssetConfig)
local ShifterFunctions = require(script.Parent.sharedfunctions)
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
local ShifterSFX = ShifterAssets.SFX :: Folder
local TitanSpecialSFX = {} :: { [any]: Sound }
local MinimalSteamAura = ShifterVFX.Auras.MinimalSteam:GetChildren() :: { ParticleEmitter }

--// Variables
local LightAttackDB = {}
local RoarDB = {}

--// Main
local JawServer = {}

--~~[[ Init ]]~~--
for _, sound: Sound in ShifterSFX.Special:GetChildren() do
	TitanSpecialSFX[sound.Name] = sound:Clone()
	TitanSpecialSFX[sound.Name].Parent = game:GetService("SoundService")
end

--[[ Private Functions ]]

--[[ Public Functions ]]
function JawServer.NapeHarden(player: Player, hardnape: BasePart, state: boolean)
	local Character = player.Character
	if not Character then
		return
	end
	Character:SetAttribute("isNapeHarden", state)
	if state then
		Log:print("Nape Harden")
		TweenService:Create(hardnape, TitanConfig.Custom.NapeHardenTweenInfo, { Transparency = 0 }):Play()
		local sound = TitanSpecialSFX.Harden:Clone()
		sound.Parent = hardnape
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 10)
	else
		Log:print("Undo Nape Harden")
		TweenService:Create(hardnape, TitanConfig.Custom.NapeHardenTweenInfo, { Transparency = 1 }):Play()
	end
end

function JawServer.TitanLightHit(player: Player, HitIndex: number)
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "LightHit", player, HitIndex)
end

function JawServer.LightHit(player: Player, CharacterList: { Model })
	local JawTitan = player.Character
	if LightAttackDB[player] then
		return
	end
	LightAttackDB[player] = true
	for _, character in pairs(CharacterList) do
		local Damage =
			ShifterFunctions.GetDamage(TitanConfig, character, JawTitan, TitanConfig.Custom.Combat.LightAttack.Damage)
		ShifterFunctions.ApplyStun(
			character,
			TitanConfig.Custom.Combat.LightAttack.StunCooldown,
			TitanConfig.Custom.Combat.LightAttack.StunDuration
		)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
	task.delay(0.75, function()
		LightAttackDB[player] = nil
	end)
end

function JawServer.NapeEject(player: Player, dead: boolean?)
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
	--~~[[ Main ]]~~--
	local playerCharacter = player.Character
	local playerHumanoid = playerCharacter:FindFirstAncestorOfClass("Humanoid")
		or playerCharacter:WaitForChild("Humanoid", 10) :: Humanoid
	playerHumanoid.Health = playerHumanoid.MaxHealth
	playerCharacter:PivotTo(CFrame.new((UpperTorso.CFrame * CFrame.new(0, 0, 16)).Position))
	playerCharacter.Parent = game.Workspace
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "NapeEject", player)
	if dead == true then
		playerHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		Satellite.Send("ReplicateTitanVFX", player, "General", "Ragdoll")
	end
end

function JawServer.BiteVFX(player: Player)
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "BiteVFX", player)
end

function JawServer.BiteAttack(player: Player, hitlist: { Model })
	local JawTitan = player.Character
	for _, character in pairs(hitlist) do
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		local Damage =
			ShifterFunctions.GetDamage(TitanConfig, character, JawTitan, TitanConfig.Custom.Combat.Bite.BiteDamage)
		ShifterFunctions.ApplyStun(
			character,
			TitanConfig.Custom.Combat.Bite.StunCooldown,
			TitanConfig.Custom.Combat.Bite.StunDuration
		)
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end
end

function JawServer.NapeGuard(player: Player, state: boolean)
	local TitanModel = player.Character
	TitanModel:SetAttribute("NapeGuard", state)
end

function JawServer.BiteGrab(player: Player, hit: Model)
	local Ayano = AyanoM.new()
	local TitanModel = player.Character :: Model
	local TargetHumanoid = hit:FindFirstChildOfClass("Humanoid")
	local TitanMouth = TitanModel:FindFirstChild("TitanHead")
		and TitanModel["TitanHead"]:FindFirstChild("Teeth") :: BasePart
	local HumanoidRootPart = hit:FindFirstChild("HumanoidRootPart") :: BasePart
	if not TitanMouth then
		Log:warn(`[{player}] missing TitanMouth.`)
	end
	if not HumanoidRootPart or not TargetHumanoid then
		Log:warn(`[{hit}] missing HumanoidRootPart or Humanoid.`)
		return
	end
	hit:SetAttribute("TitanGrabbed", true)
	local Weld = Ayano:TrackInstance(Instance.new("Weld"))
	Weld.Part0 = TitanMouth
	Weld.Part1 = HumanoidRootPart
	Weld.C0 = CFrame.new(Vector3.new(0, 5, 2)) * CFrame.fromOrientation(0, math.rad(110), 0)
	Weld.C1 = CFrame.new(Vector3.zero) * CFrame.fromOrientation(0, math.rad(30), 0)
	Weld.Name = "GrabWeld"
	Weld.Parent = TitanModel
	hit:SetAttribute("ShifterGrabbed", true)
	TargetHumanoid.BreakJointsOnDeath = false
	TargetHumanoid.EvaluateStateMachine = false
	TargetHumanoid.PlatformStand = true

	local function Ungrab()
		if TitanModel:GetAttribute("UnGrab") then
			hit:SetAttribute("TitanGrabbed", nil)
			hit:SetAttribute("ShifterGrabbed", nil)
			Ayano:Clean()
			TitanModel:SetAttribute("UnGrab", false)
			TargetHumanoid.PlatformStand = false
			TargetHumanoid.BreakJointsOnDeath = true
			TargetHumanoid.EvaluateStateMachine = true
		end
	end

	local function Eat()
		if TitanModel:GetAttribute("Eat") then
			TitanModel:SetAttribute("Eat", false)
			TitanModel:SetAttribute("UnGrab", true)
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
			TitanModel:SetAttribute("UnGrab", true)
			Ungrab()
			TargetHumanoid.BreakJointsOnDeath = true
			TargetHumanoid.EvaluateStateMachine = true
		end
	end

	Ayano:Connect(TitanModel:GetAttributeChangedSignal("UnGrab"), Ungrab)
	Ayano:Connect(TitanModel:GetAttributeChangedSignal("Eat"), Eat)
	Ayano:Connect(TargetHumanoid.Died, Ungrab)
	Ayano:Connect(TargetHumanoid:GetPropertyChangedSignal("Health"), UpdateHealth)
end

function JawServer.Landed(player: Player)
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "Landed", player)
end

function JawServer.Eat(player: Player)
	local TitanModel = player.Character
	TitanModel:SetAttribute("Eat", true)
end

function JawServer.UnGrab(player: Player)
	local TitanModel = player.Character
	TitanModel:SetAttribute("UnGrab", true)
end

function JawServer.Died(player: Player)
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

function JawServer.Voided(player: Player)
	Log:print("Voided")
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
	task.delay(TitanConfig.Custom.Combat.Roar.Cooldown, function()
		RoarDB[player] = false
	end)
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "Roar", player)
	task.wait(TitanConfig.Custom.Combat.Roar.Duration)
	Satellite.SendAll("ReplicateTitanVFX", "Jaw", "Roar", player, true)
end

--~~[[ Stomps ]]~~--
function JawServer.LeftStomp(player: Player)
	Satellite.SendAllBut("ReplicateTitanVFX", player, "Jaw", "LeftStomp", player)
end

function JawServer.RightStomp(player: Player)
	Satellite.SendAll("ReplicateTitanVFX", player, "Jaw", "RightStomp", player)
end

-- Limb Hit Handlers

function JawServer._onNapeHit(playerWhoHit: Player, shifter: Player, Damage: number, Limb: BasePart)
	local TitanModel = shifter.Character
	local TitanHumanoid = TitanModel:FindFirstChildOfClass("Humanoid")
		or TitanModel:WaitForChild("Humanoid", 5) :: Humanoid
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s nape`)
	if TitanModel:GetAttribute("isNapeHarden") then
		local hit = TitanSpecialSFX.HardeningHit:Clone()
		hit.Parent = TitanModel.PrimaryPart
		hit:Play()
		game:GetService("Debris"):AddItem(hit, 10)
		return
	end
	if TitanModel:GetAttribute("NapeGuard") then
		Damage *= TitanConfig.Custom.Combat.NapeGuard.ReductionFactor
	end
	TitanHumanoid:TakeDamage(Damage)
	VFX.EmitParticle(Limb)
	Sound.Play(Limb)
end

function JawServer._onArmHit(playerWhoHit: Player, Limb: BasePart, shifter: Player)
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s arm`)
	local ArmHealth = Limb:GetAttribute("ArmHealth") or TitanConfig.Custom.Health.Arm
	if ArmHealth >= 0 then
		Limb:SetAttribute("ArmHealth", ArmHealth - 1)
		return
	end
	Limb:SetAttribute("ArmHealth", TitanConfig.Custom.Health.Arm)
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

function JawServer._onEyeHit(shifter: Player, Direction: "Left" | "Right")
	Satellite.Send("ReplicateTitanVFX", shifter, "Jaw", "EyeHit", shifter, Direction)
end

function JawServer.OnLimbHit(playerWhoHit: Player, shifter: Player, Limb: BasePart, Damage: number)
	if Limb.Name == "ShifterNape" then
		JawServer._onNapeHit(playerWhoHit, shifter, Damage, Limb)
	elseif Limb.Name == "ShifterRightEye" then
		if Limb:GetAttribute("inCooldown") then
			warn("Returning")
			return
		end
		Limb:SetAttribute("inCooldown", true)
		VFX.SetParticle(Limb, true)
		task.delay(TitanConfig.Custom.BlindDuration, function()
			Limb:SetAttribute("inCooldown", false)
			VFX.SetParticle(Limb, false)
		end)
		JawServer._onEyeHit(shifter, "Right")
	elseif Limb.Name == "ShifterLeftEye" then
		if Limb:GetAttribute("inCooldown") then
			warn("Returning")
			return
		end
		Limb:SetAttribute("inCooldown", true)
		VFX.SetParticle(Limb, true)
		task.delay(TitanConfig.Custom.BlindDuration, function()
			Limb:SetAttribute("inCooldown", false)
			VFX.SetParticle(Limb, false)
		end)
		JawServer._onEyeHit(shifter, "Left")
	elseif Limb.Name == "ShifterArm" then
		JawServer._onArmHit(playerWhoHit, Limb, shifter)
		--elseif Limb.Name == "ShifterLeg" then
		--JawServer._onLegHit(playerWhoHit, Limb, shifter, Damage)
	end
end

return JawServer
