--[[

@rakken
Jaw-Titan Controller

]]

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Modules
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local TaikaGui = rbxlib.TaikaGui
local Utils = rbxlib.Utils
local reference = Utils.reference

--// Module-Constants
local character = script.Parent
local humanoid = character:FindFirstAncestorOfClass("Humanoid") or character:WaitForChild("Humanoid") :: Humanoid
local rootpart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator
local gui = TaikaGui.new("Debug", "Minima")

--// Constants
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = { character }

--// Variables
--~~[[ Misc ]]~~--
local TitanSettings
local maxThresholdTime
local originPressTime = 0
local JumpAnimationIndex = "Jump"
--~~[[ Bools ]]~~--
local canRun = true
local isRunning = false
local isM1Held = false
local isWHeld = false
local isSHeld = false
--~~[[ Stamina ]]~~--
local Stamina = 0 :: number
--~~[[ Anims ]]~~--
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
	Animations.Climb.Priority = Enum.AnimationPriority.Action
	Animations.LightLeft.Priority = Enum.AnimationPriority.Action2
	Animations.LightRight.Priority = Enum.AnimationPriority.Action2
end

local function onJump(isEnteringJump: boolean)
	if isEnteringJump == true then
		Animations[JumpAnimationIndex]:Play()
	end
end

local function LoadAnimationConfig()
	local useAlternativeJump = TitanSettings.Animations.UseAlternativeJumpAnimation

	if useAlternativeJump then
		JumpAnimationIndex = "ShortJump"
	end
end

--~~[[ Titan Actions ]]~~--
local inq = falseD
local function LightAttack()
	if inq then
		return
	end
	inq = true
	if Animations.LightLeft.IsPlaying then
		Animations.LightLeft.Stopped:Wait()
		Animations.LightRight:Play()
	else
		Animations.LightLeft:Play()
	end

	if Animations.LightRight.IsPlaying then
		Animations.LightRight.Stopped:Wait()
		Animations.LightLeft:Play()
	end
	inq = false
end

--~~[[ Control Functions ]]~~--
local function OnInputBegan(input: InputObject, GameProcessedEvent: boolean)
	if GameProcessedEvent then
		return
	end

	if input.KeyCode == Enum.KeyCode.S then
		isSHeld = true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isM1Held = true
		while isM1Held do
			task.wait(0.1)
			LightAttack()
		end
	end

	if input.KeyCode == Enum.KeyCode.W then
		isWHeld = true
		local currTime = tick()
		if (currTime - originPressTime <= maxThresholdTime) and canRun == true then
			isRunning = true
			humanoid.WalkSpeed = TitanSettings.Humanoid.RunSpeed
		else
			isRunning = false
			originPressTime = currTime
		end
	end
end

local function OnInputEnded(input: InputObject)
	if input.KeyCode == Enum.KeyCode.W then
		humanoid.WalkSpeed = TitanSettings.Humanoid.WalkSpeed
		isWHeld = false
		isRunning = false
	end
	if input.KeyCode == Enum.KeyCode.S then
		isSHeld = false
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isM1Held = false
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

local function UpdateStamina()
	if isRunning and Stamina >= TitanSettings.Stamina.MinStamina then
		Stamina -= TitanSettings.Stamina.StaminaConsumptionRate
	elseif Stamina <= TitanSettings.Stamina.MaxStamina then
		Stamina += TitanSettings.Stamina.StaminaRegenRate
	end
	if Stamina < TitanSettings.Stamina.MinStaminaThreshold then
		canRun = false
	else
		canRun = true
	end
	Stamina = math.clamp(Stamina, TitanSettings.Stamina.MinStamina, TitanSettings.Stamina.MaxStamina)
end

local function UpdateClimb()
	local range = TitanSettings.Constants.ClimbRange
	local RaycastResult = game.Workspace:Raycast(
		rootpart.Position - Vector3.new(0, 26, 0),
		rootpart.CFrame.LookVector * range,
		raycastParams
	)
	local Wall = RaycastResult and RaycastResult.Instance or nil
	if Wall and Wall:IsA("BasePart") and Wall.Anchored ~= true then
		return
	end
	if Wall and isWHeld then
		rootpart.Anchored = false
		rootpart.AssemblyLinearVelocity = Vector3.new(
			rootpart.AssemblyLinearVelocity.X,
			TitanSettings.Constants.ClimbSpeed,
			rootpart.AssemblyLinearVelocity.Z
		)
		Animations.Run:Stop()
		Animations.Walk:Stop()
		Animations.Jump:Stop()
		Animations.Freefall:Stop()
		Animations.Climb:AdjustSpeed(1)
		if not Animations.Climb.IsPlaying then
			Animations.Climb:Play()
		end
	elseif Wall and isSHeld then
		rootpart.Anchored = false
		rootpart.AssemblyLinearVelocity = Vector3.new(
			rootpart.CFrame.LookVector.Unit.X,
			-TitanSettings.Constants.ClimbSpeed,
			rootpart.CFrame.LookVector.Unit.Z
		)
		Animations.Run:Stop()
		Animations.Walk:Stop()
		Animations.Jump:Stop()
		Animations.Freefall:Stop()
		Animations.Climb:AdjustSpeed(-1)
		if not Animations.Climb.IsPlaying then
			Animations.Climb:Play()
		end
	elseif Wall and not isWHeld then
		Animations.Run:Stop()
		Animations.Walk:Stop()
		Animations.Jump:Stop()
		Animations.Freefall:Stop()
		Animations.Climb:AdjustSpeed(0)
		rootpart.Anchored = true
	else
		rootpart.Anchored = false
		Animations.Climb:Stop()
	end
end

--~~/// [[ General ]] ///~~--
local function SetupConnections()
	humanoid.Running:Connect(function(speed: number)
		OnRunning(speed)
	end)
	RunService.Heartbeat:Connect(function()
		UpdateMiscAnims()
		UpdateJumpBehaviour()
		UpdateStamina()
		UpdateClimb()
	end)
	humanoid.Jumping:Connect(onJump)
end

--~~/// [[ Debug ]] ///~~--
local function CreateDebugGui()
	gui:Construct("Frame", "MainContainer")
		:LoadPreset()
		:SetProperty({
			Active = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		})
		:ParentToGui()
		:Construct("TextLabel", "StaminaInfo")
		:LoadPreset()
		:ParentToElement("MainContainer")
		:SetProperty({
			Active = false,
			Position = UDim2.fromScale(0.1, 0.9),
			Size = UDim2.fromScale(0.1, 0.05),
		})

	local TextLabel = gui:RetrieveSelectedElement() :: TextLabel

	RunService.Heartbeat:Connect(function()
		TextLabel.Text = `Stamina: {math.floor(Stamina)}`
	end)
end

--[[ Public Functions ]]
function JawController.Start(_TitanSettings)
	TitanSettings = _TitanSettings
	Stamina = TitanSettings.Stamina.MaxStamina
	maxThresholdTime = TitanSettings.Constants.MaxDoubleTapWThresholdTimeForRun
	LoadAnimationTracks()
	LoadAnimationConfig()
	SetupAnimations()
	SetupConnections()
	CreateDebugGui()
	JawController.StartControls()
end

function JawController.StartControls()
	UserInputService.InputBegan:Connect(OnInputBegan)
	UserInputService.InputEnded:Connect(OnInputEnded)
end

return JawController
