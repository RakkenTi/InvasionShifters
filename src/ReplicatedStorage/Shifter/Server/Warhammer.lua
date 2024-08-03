--[[

@rakken
Attack-Titan Server Side

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Modules
local AssetConfig = require(script.Parent.Parent.AssetConfig)
local ShifterFunctions = require(script.Parent.sharedfunctions)
local TitanConfig = require(script.Parent.Parent.Client.Warhammer.TitanConfig)
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Property = Utils.property
local Basepart = Utils.basepart
local AyanoM = Utils.ayano
local Sound = Utils.sound
local VFX = Utils.vfx
local SpatialHitbox = Utils.hitbox

--// Module-Constants
local Log = Utils.log.new("[Warhammer Titan]")
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
local ArrowRef = ShifterAssets.Models.Arrow :: BasePart

--// Variables
local LightAttackDB = {}
local HeavyAttackDB = {}
local RoarDB = {}

--// Main
local WarhammerServer = {}

--~~[[ Init ]]~~--
for _, sound: Sound in ShifterSFX.Special:GetChildren() do
	TitanSpecialSFX[sound.Name] = sound:Clone()
	TitanSpecialSFX[sound.Name].Parent = game:GetService("SoundService")
end

--[[ Private Functions ]]

--[[ Public Functions ]]
--~~[[ Limbs ]]~~--

function WarhammerServer._onNapeHit(playerWhoHit: Player, shifter: Player, Damage: number, Limb: BasePart)
	local TitanModel = shifter.Character
	local TitanHumanoid = TitanModel:FindFirstChildOfClass("Humanoid")
		or TitanModel:WaitForChild("Humanoid", 5) :: Humanoid
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s nape`)
	--~~[[ Harden Hit Sound ]]~~--
	local hit = TitanSpecialSFX.HardeningHit:Clone()
	hit.Parent = TitanModel.PrimaryPart
	hit:Play()
	game:GetService("Debris"):AddItem(hit, 10)
	Damage = ShifterFunctions.GetDamage(TitanConfig, TitanModel, nil, Damage)
	TitanHumanoid:TakeDamage(Damage)
	VFX.EmitParticle(Limb)
	Sound.Play(Limb)
end

function WarhammerServer._onArmHit(playerWhoHit: Player, Limb: BasePart, shifter: Player)
	Log:print(`[{playerWhoHit}] hit [{shifter}]'s arm`)
	local ArmHealth = Limb:GetAttribute("ArmHealth") or TitanConfig.Custom.Health.Arm
	local TitanModel = Limb.Parent
		and Limb.Parent.Parent
		and Limb.Parent.Parent:IsA("Model")
		and Limb.Parent.Parent :: Model
	--~~[[ Harden Hit Sound ]]~~--
	local hit = TitanSpecialSFX.HardeningHit:Clone()
	hit.Parent = TitanModel.PrimaryPart
	hit:Play()
	if ArmHealth >= 0 then
		Log:print("Warhammer arm damaged")
		Limb:SetAttribute("ArmHealth", ArmHealth - 1)
		return
	end
	Log:print("Warhammer arm destroyed")
	Limb:SetAttribute("ArmHealth", TitanConfig.Custom.Health.Arm)
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
	game:GetService("Debris"):AddItem(hit, 10)
	Log:print("Replicating arm hit vfx to clients.")
	Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "ArmHit", shifter, Position, LowerArm, UpperArm)
end

function WarhammerServer.OnLimbHit(playerWhoHit: Player, shifter: Player, Limb: BasePart, Damage: number)
	if Limb.Name == "ShifterNape" then
		WarhammerServer._onNapeHit(playerWhoHit, shifter, Damage, Limb)
	elseif Limb.Name == "ShifterArm" then
		WarhammerServer._onArmHit(playerWhoHit, Limb, shifter)
	end
end

--~~[[ Mode ]]~~--
function WarhammerServer.SwitchMode(_, mode: "Attack" | "Bow", bow: BasePart, lefthand: BasePart)
	local Charge = lefthand:WaitForChild("Charge", 5)
	if mode == "Attack" then
		TweenService:Create(bow, TitanConfig.Custom.BowFadeTweenInfo, { Transparency = 1 }):Play()
	elseif mode == "Bow" then
		VFX.SetParticle(Charge, true)
		local tween = TweenService:Create(bow, TitanConfig.Custom.BowFadeTweenInfo, { Transparency = 0 })
		tween.Completed:Once(function()
			VFX.SetParticle(Charge, false)
		end)
		tween:Play()
	end
end

--~~[[ Stomps ]]~~--
function WarhammerServer.LeftStomp(player: Player)
	Satellite.SendAllBut("ReplicateTitanVFX", player, "Warhammer", "LeftStomp", player)
end

function WarhammerServer.RightStomp(player: Player)
	Satellite.SendAllBut("ReplicateTitanVFX", player, "Warhammer", "RightStomp", player)
end

--~~[[ Attack Stomp ]]~~--
function WarhammerServer.Stomp(player: Player, SpikeData)
	Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "Stomp", player, SpikeData)
end

function WarhammerServer.OnSpikeHit(playerHit: Player, shifter: Player)
	local character = playerHit.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local Damage = ShifterFunctions.GetDamage(
			TitanConfig,
			character,
			shifter.Character,
			TitanConfig.Custom.Combat.Spike.Damage
		)
		humanoid:TakeDamage(Damage)
	end
end

--~~[[ Block ]]~~--
function WarhammerServer.Block(player: Player, state: boolean)
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
function WarhammerServer.TitanHit(player: Player, HitIndex: number, ...)
	Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "TitanHit", player, HitIndex, ...)
end

function WarhammerServer.LightHit(player: Player, CharacterList: { Model }, AttackIndex: number)
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

function WarhammerServer.NapeEject(player: Player, dead: boolean)
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

function WarhammerServer.NapeGuard(player: Player, state: boolean)
	local TitanModel = player.Character
	TitanModel:SetAttribute("NapeGuard", state)
end

function WarhammerServer.Landed(player: Player)
	Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "Landed", player)
end

function WarhammerServer.Died(player: Player)
	local TitanModel = player.Character
	local HumanoidRootPart = TitanModel.HumanoidRootPart :: BasePart
	local UpperTorso = TitanModel.UpperTorso :: BasePart
	local Humanoid = TitanModel.Humanoid :: Humanoid
	local SteamID = HttpService:GenerateGUID()
	local Steam = TitanSpecialSFX.Steam:Clone()
	Humanoid:Destroy()
	HumanoidRootPart.Anchored = true
	VFX.AddAura(MinimalSteamAura, TitanModel, SteamID)
	Steam.Parent = HumanoidRootPart
	Steam:Play()
	player.Character = nil
	player.CharacterAdded:Once(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
			or character:WaitForChild("Humanoid", 5) :: Humanoid
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		end
		character:PivotTo(CFrame.new((UpperTorso.CFrame * CFrame.new(0, 0, 16)).Position))
	end)
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

function WarhammerServer.Voided(player: Player)
	local character = player.Character
	if character then
		character:Destroy()
	end
	player:LoadCharacter()
end

function WarhammerServer.NapeEjectInit(player: Player)
	local SteamAuraID = HttpService:GenerateGUID()
	local TitanModel = player.Character
	VFX.AddAura(MinimalSteamAura, TitanModel, SteamAuraID, TitanConfig.Custom.AuraTweenInfo)
	task.delay(10, function()
		VFX.RemoveAura(SteamAuraID)
	end)
end
--~~[[ Inverse Kinematics [IK] ]]~~--

function WarhammerServer.UpdateIK(player: Player, ...)
	Satellite.SendAllBut("UnreliableReplicateTitanVFX", player, ...)
end

function WarhammerServer.SetIK(_, IKControl: IKControl, state: boolean)
	if state == false then
		TweenService:Create(IKControl, TitanConfig.Custom.IKTweenInfo, { Weight = 0 }):Play()
	else
		TweenService:Create(IKControl, TitanConfig.Custom.IKTweenInfo, { Weight = 1 }):Play()
	end
end

--~~[[ Bow ]]~~--
function WarhammerServer.BowShotInit(player: Player, righthand: BasePart)
	local character = player.Character
	if character and righthand then
		Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "BowShotInit", player, righthand)
	end
end

function WarhammerServer.BowShotFull(player: Player, ArrowCFrame: CFrame)
	Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "BowShotFull", player)
	local ArrowServer = ArrowRef:Clone()
	local ArrowHitbox = ArrowServer:WaitForChild("Hitbox") :: BasePart
	VFX.SetParticle(ArrowServer, true)
	ArrowServer.CFrame = ArrowCFrame
	ArrowServer.Parent = game.Workspace
	ArrowServer:SetNetworkOwner(nil)
	ArrowHitbox:SetNetworkOwner(nil)

	local AlignOrientation = ArrowServer:WaitForChild("AlignOrientation") :: AlignOrientation
	--~~[[ Hitbox ]]~~--
	local characterFilter = {}
	local Hitbox = SpatialHitbox.new(ArrowHitbox.Size, nil, { player })
	AlignOrientation.Enabled = true
	Hitbox:SetVisibility(true)
	Hitbox:Bind(ArrowHitbox, CFrame.new(0, 0, 0))
	Hitbox:Start()
	Hitbox:SetLiveCallback(function(hit: Model)
		if characterFilter[hit] then
			return
		end
		local Damage =
			ShifterFunctions.GetDamage(TitanConfig, hit, player.Character, TitanConfig.Custom.Combat.Bow.Damage)
		characterFilter[hit] = true
		local humanoid = hit:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(Damage)
		end
	end)
	--~~[[ Trajectory Handling ]]~~--
	local ImpulseVector = -ArrowServer.CFrame.RightVector.Unit
		* ArrowServer.Mass
		* TitanConfig.Custom.Combat.Bow.ForceMagnitude
	ArrowServer:ApplyImpulse(ImpulseVector)
	task.delay(0.4, function()
		ArrowServer.CanCollide = true
	end)
	local connection
	local RaycastParams = RaycastParams.new()
	local oparams = OverlapParams.new()
	oparams.FilterDescendantsInstances = { player.Character, Hitbox }
	RaycastParams.FilterDescendantsInstances = { player.Character }

	local function StopArrow()
		Hitbox:Destroy()
		ArrowServer.Anchored = true
		game:GetService("Debris"):AddItem(ArrowServer, 4)
		local SpikeCount = TitanConfig.Custom.Combat.Spike.SpikeCount
		local Radius = TitanConfig.Custom.Combat.Spike.Radius
		local DegreeVariance = TitanConfig.Custom.Combat.Spike.DegreeVariance
		local SpikeData = {}
		--~~[[ Get Data ]]~~--
		for _ = 1, SpikeCount do
			local Raycast = game.Workspace:Raycast(
				ArrowServer.Position + Vector3.new(math.random(-Radius, Radius), 70, math.random(-Radius, Radius)),
				Vector3.new(0, -200, 0),
				RaycastParams
			)
			if Raycast then
				local SpikeInstanceData = {
					Position = Raycast.Position,
					Orientation = CFrame.fromOrientation(
						math.rad(math.random(-DegreeVariance, DegreeVariance)),
						math.rad(math.random(-DegreeVariance, DegreeVariance)),
						math.rad(math.random(-DegreeVariance, DegreeVariance))
					),
				}
				table.insert(SpikeData, SpikeInstanceData)
			end
		end
		Satellite.SendAll("ReplicateTitanVFX", "Warhammer", "Stomp", player, SpikeData)
	end

	connection = RunService.Heartbeat:Connect(function()
		if not ArrowServer then
			connection:Disconnect()
			StopArrow()
			return
		end
		AlignOrientation.CFrame =
			CFrame.lookAt(ArrowServer.Position, ArrowServer.Position + ArrowServer.AssemblyLinearVelocity)
		local hit = game.Workspace:GetPartsInPart(ArrowServer, oparams)
		if hit and #hit > 0 then
			connection:Disconnect()
			StopArrow()
		end
	end)
end

--~~[[ Passives ]]~~--
function WarhammerServer.ActivatePassive(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	character:SetAttribute("PassiveDamageReductionFactor", TitanConfig.Custom.PassiveDamageReductionFactor)
end

return WarhammerServer
