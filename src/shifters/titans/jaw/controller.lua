--[[

@rakken
Jaw-Titan Animator

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Utils = rbxlib.Utils
local reference = Utils.reference

--// Module-Constants
local character = script.Parent
local humanoid = character:FindFirstAncestorOfClass("Humanoid") or character:WaitForChild("Humanoid") :: Humanoid
local rootpart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator

--// Constants
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = { character }

--// Variables
local TitanSettings
local maxThresholdTime
local originPressTime = 0
local JumpAnimationIndex = "Jump"
local AnimationInstances = character:WaitForChild("Animations"):GetChildren() :: { Animation }
local Animations = {} :: {
	Climb: AnimationTrack,
	Heavy: AnimationTrack,
	Jump: AnimationTrack,
	Idle: AnimationTrack,
	LightLeft: AnimationTrack,
	LightRight: AnimationTrack,
	Roar: AnimationTrack,
	Run: AnimationTrack,
	Walk: AnimationTrack,
	Freefall: AnimationTrack,
	ShortJump: AnimationTrack,
}

--// Main
local JawController = {}

--~~/// [[ Local Function ]] ///~~--
--~~[[ Animation Functions  ]]~~--
local function LoadAnimationTracks()
	for _, animation: Animation in AnimationInstances do
		Animations[animation.Name] = animator:LoadAnimation(animation)
	end
end

local function StopAllAnimations()
	for _, animation: AnimationTrack in pairs(Animations) do
		animation:Stop()
	end
end

local function PlayAnimation(AnimationTrack: AnimationTrack) end

local function updateWalkAndRun()
	if humanoid.WalkSpeed >= TitanSettings.Humanoid.RunSpeed then
		if Animations.Walk.IsPlaying then
			Animations.Walk:Stop()
		end
		Animations.Run:Play()
	elseif humanoid.WalkSpeed <= TitanSettings.Humanoid.RunSpeed then
		if Animations.Run.IsPlaying then
			Animations.Run:Stop()
		end
		Animations.Walk:Play()
	end
end

local function stopWalkAndRun()
	Animations.Walk:Stop()
	Animations.Run:Stop()
end

local function UpdateMiscAnims()
	local LastState = humanoid:GetState()
	if LastState == Enum.HumanoidStateType.Freefall then
		if not Animations[JumpAnimationIndex].IsPlaying and not Animations.Freefall.IsPlaying then
			Animations.Freefall:Play()
		end
		Animations.Run:Stop()
		Animations.Walk:Stop()
	else
		Animations.Freefall:Stop()
	end
end

local function OnRunning(speed: number)
	if Animations.Climb.IsPlaying then
		return
	end
	if speed < 5 then
		stopWalkAndRun()
	elseif speed > 5 then
		updateWalkAndRun()
	end
end

local function SetupAnimations()
	Animations.Idle.Priority = Enum.AnimationPriority.Idle
	Animations.Idle.Looped = true
	Animations.Idle:Play()
end

local function onJump(isEnteringJump: boolean)
	if isEnteringJump == true then
		Animations[JumpAnimationIndex]:Play()
	end
end

local function LoadAnimationConfig()
	local useAlternativeJump = TitanSettings.Animations.useAlternativeJumpAnimation

	if useAlternativeJump then
		JumpAnimationIndex = "ShortJump"
	end
end
--~~[[ Control Functions ]]~~--
local function OnInputBegan(input: InputObject, GameProcessedEvent: boolean)
	if GameProcessedEvent then
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		local currTime = os.time()
		if currTime - originPressTime <= maxThresholdTime then
			humanoid.WalkSpeed = TitanSettings.Humanoid.RunSpeed
		else
			originPressTime = currTime
			humanoid.WalkSpeed = TitanSettings.Humanoid.WalkSpeed
		end
	end
end

local function UpdateJumpBehaviour()
	local raycast = game.Workspace:Raycast(rootpart.Position, Vector3.new(0, -38, 0), raycastParams)
	if raycast and raycast.Instance then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	else
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end
end

--~~/// [[ General ]] ///~~--
local function SetupConnections()
	humanoid.Running:Connect(function(speed: number)
		OnRunning(speed)
	end)
	humanoid.Jumping:Connect(onJump)
	RunService.Heartbeat:Connect(function()
		UpdateMiscAnims()
		UpdateJumpBehaviour()
	end)
end

--[[ Public Functions ]]
function JawController.Start(_TitanSettings)
	TitanSettings = _TitanSettings
	maxThresholdTime = TitanSettings.Constants.maxDoubleTapWThresholdTimeForRun
	LoadAnimationTracks()
	LoadAnimationConfig()
	SetupAnimations()
	SetupConnections()
	JawController.StartControls()
end

function JawController.StartControls()
	UserInputService.InputBegan:Connect(OnInputBegan)
end

return JawController
