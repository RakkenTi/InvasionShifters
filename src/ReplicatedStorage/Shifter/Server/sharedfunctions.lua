--[[

Shared functions between each server handler


]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Utils = rbxlib.Utils

--// Module-Constants
local Log = Utils.log.new("[Shifter Shared Functions]")
local Sound = Utils.sound

--// Constants

--// Variables

--// Main
local SharedFunctions = {}

--[[ Private Functions ]]

--[[ Public Functions ]]
function SharedFunctions.GetDamage(
	TitanConfig,
	characterGettingHit: Model,
	TitanDealingDamage: Model?,
	StartDamage: number
)
	if
		characterGettingHit:GetAttribute("DamageReductionFactor")
		or characterGettingHit:GetAttribute("PassiveDamageReductionFactor")
	then -- Blocking or Passive Damage (Warhammer)
		local DamageReductionFactor = characterGettingHit:GetAttribute("DamageReductionFactor") :: number
		local PassiveDamageReductionFactor = characterGettingHit:GetAttribute("PassiveDamageReductionFactor")
		if DamageReductionFactor then
			Log:print("Applying Blocking Damage Reduction")
			StartDamage *= DamageReductionFactor
		end
		if PassiveDamageReductionFactor then
			Log:print("Applying Passive Damage Reduction")
			StartDamage *= PassiveDamageReductionFactor
		end
		local BlockHitSound = Sound.new(18760066871)
		BlockHitSound.Volume = 7
		BlockHitSound.Parent = SoundService
		BlockHitSound:Play()
		game:GetService("Debris"):AddItem(BlockHitSound, 10)
	end
	if TitanDealingDamage and TitanDealingDamage:GetAttribute("isBeserk") then -- Attack Titan
		StartDamage *= TitanConfig.Custom.Combat.Beserk.DamageMultplier
	end
	return StartDamage
end

function SharedFunctions.ApplyStun(characterToApplyStunTo: Model, StunCooldown: number, StunDuration: number)
	if not characterToApplyStunTo:HasTag("isTitan") then
		return
	end
	Log:print("Attempting to apply stun.")
	if characterToApplyStunTo:GetAttribute("canStun") or characterToApplyStunTo:GetAttribute("canStun") == nil then
		if characterToApplyStunTo:GetAttribute("isBlocking") then
			StunDuration /= 2
		end
		Log:warn("Applying stun.")
		characterToApplyStunTo:SetAttribute("canStun", false)
		characterToApplyStunTo:SetAttribute("Stunned", true)
		task.delay(StunDuration, function()
			Log:warn("Stun removed.")
			characterToApplyStunTo:SetAttribute("Stunned", false)
			task.wait(StunCooldown)
			Log:warn("Stun cooldown done.")
			characterToApplyStunTo:SetAttribute("canStun", true)
		end)
	end
end

return SharedFunctions
