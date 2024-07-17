--[[

@rakken
Base Shifter Titan Class
All Shifter's inherit from this class.

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

--// Modules
local Settings = require(script.Parent.settings)
local rbxlib = Settings.dependencies.rbxlib
local Data = rbxlib.Data
local Utils = rbxlib.Utils
local VfxU = Utils.vfx
local Property = Utils.property
local Satellite = rbxlib.Satellite

--// Module-Constants
local Log = rbxlib.Utils.log.new("[TitanBase]")

--// Constants
local TransformationColorCorrection = {
	Brightness = -0.2,
	TintColor = Color3.fromRGB(186, 112, 114),
	Contrast = 0.1,
	Saturation = -0.1,
}

local DefaultColorCorrectionData = {
	Brightness = 0,
	Contrast = 0,
	Saturation = 0,
	TintColor = Color3.fromRGB(255, 255, 255),
}

local TransformationTweenData = TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

--// Variables
local TransformationSFX = {} :: { Sound }

--// Paths
local ShifterAssets = Settings.dependencies.assets :: Folder
local SFXAssets = ShifterAssets.SFX
local LightningAuras = ShifterAssets.VFX.Auras.Lightning:GetChildren() :: { ParticleEmitter }

--// Main

--[=[
    @class BaseShifterClass

    Base Class for all Shifters.
    All Shifters inherit from this class.

]=]
local BaseShifterClass = {}
BaseShifterClass.__index = BaseShifterClass

--[[ Private Functions ]]
--~~[[ Client Replication ]]~~--
local function Transform(player: Player, ShifterName: string, TitanModel: Model)
	TransformationSFX.Rumble:Play()
	task.wait(0.5)
	local Particles = {}
	local ColorCorrection = Instance.new("ColorCorrectionEffect")
	local TransformationParticles = ShifterAssets.VFX.Transformations[ShifterName]:Clone() :: Model
	local character = player.Character or player.CharacterAdded:Wait()
	local HumanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	TransformationSFX.Sparks:Play()

	for _, basepart in character:GetChildren() do
		if basepart:IsA("BasePart") then
			for _, particle in ipairs(LightningAuras) do
				local Clone = particle:Clone()
				local OriginalBrightness = Clone.Brightness
				Clone.Brightness = 0
				Clone.Name = "TransformParticles"
				Clone.Parent = basepart
				TweenService:Create(
					Clone,
					TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{ Brightness = OriginalBrightness }
				):Play()
				table.insert(Particles, Clone)
			end
		end
	end

	ColorCorrection.Parent = Lighting
	Property.SetTable(ColorCorrection, TransformationColorCorrection, TransformationTweenData)

	task.wait(0.7)

	TransformationSFX.Impact:Play()
	TransformationSFX.Strike:Play()

	local connection
	connection = RunService.RenderStepped:Connect(function(delta: number)
		TransformationParticles:PivotTo(CFrame.new(HumanoidRootPart.Position))
	end)
	TransformationParticles.Parent = game.Workspace
	VfxU.SetParticle(TransformationParticles.Main.Top, true)
	VfxU.SetBeam(TransformationParticles.Main.Top, true)
	VfxU.SetParticle(TransformationParticles.Smoke, true)
	task.wait(1)
	VfxU.SetParticle(TransformationParticles.Main.Main, true)
	task.wait(3.5)
	VfxU.SetParticle(TransformationParticles, false)
	VfxU.SetBeam(TransformationParticles, false)
	for _, particle in ipairs(Particles) do
		particle:Destroy()
	end
	task.wait(2)
	connection:Disconnect()
	TransformationParticles:Destroy()
	Property.SetTable(ColorCorrection, DefaultColorCorrectionData, TransformationTweenData)
end
--~~[[ End of Client Replication ]]~~--

local function SetupSounds()
	for _, sound in SFXAssets.Transformation:GetChildren() do
		TransformationSFX[sound.Name] = sound
		sound.Parent = SoundService
	end
end

local function InitServer()
	Satellite.Create("RemoteEvent", "TitanTransform")
end

local function InitClient()
	SetupSounds()
	Satellite.ListenTo("TitanTransform"):Connect(Transform)
end

--[[ Public Functions ]]

--[=[
    @within BaseShifterClass
    Initiates a titan transformation based on the player's ShifterName data.
]=]
function BaseShifterClass.new(player: Player)
	local self = setmetatable({}, BaseShifterClass)
	local ShifterName = Data:GetData(player, "ShifterName") :: string
	local TitanModel = ShifterAssets.Titans[ShifterName]:Clone()
	Satellite.SendAll("TitanTransform", player, ShifterName, TitanModel)
	task.wait(4)
	return self
end

function BaseShifterClass.LMB() end
function BaseShifterClass.RMB() end
function BaseShifterClass.Drop() end
function BaseShifterClass.Block() end
function BaseShifterClass.NapeHarden() end
function BaseShifterClass.FistHarden() end
function BaseShifterClass.Special() end
function BaseShifterClass.NapeProtect() end
function BaseShifterClass.ToggleMode() end
function BaseShifterClass.NapeEject() end

--~~/// [[ Init ]] ///~~--

if RunService:IsServer() then
	InitServer()
end

if RunService:IsClient() then
	InitClient()
end

return BaseShifterClass
