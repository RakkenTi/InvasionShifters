--[[

@rakken
Titan: Warhammer Titan
Notes:

]]

--// Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

--// Modules
local Types = require(script.Parent.Parent.Types)
local AssetConfig = require(script.Parent.Parent.AssetConfig)
local TitanConfig = require(script.TitanConfig)
local rbxlib = require(ReplicatedStorage.Packages.rbxlib)
local Satellite = rbxlib.Satellite
local Utils = rbxlib.Utils
local Reference = Utils.reference
local Sound = Utils.sound
local Anim = Utils.anim
local Property = Utils.property
local SpatialHitbox = Utils.hitbox
local Table = Utils.table
local BasePart = Utils.basepart
local VFX = Utils.vfx
local Rubble = VFX.Rubble

--// Module-Constants
local Ayano = Utils.ayano.new()
local Ayano2 = Utils.ayano.new()
local Log = Utils.log.new("[Jaw Client]")
local ColorCorrectionData = TitanConfig.Default.ColorCorrectionData
local selfRaycastParams = RaycastParams.new()
selfRaycastParams.FilterDescendantsInstances = { Reference.Client.Player.Character }

--// Constants
local ShifterAssets = AssetConfig.ShifterAssets :: Folder
local ShifterVFX = ShifterAssets.VFX :: Folder
local ShifterLightningAura = ShifterVFX.Auras.SmallLightning:GetChildren() :: { ParticleEmitter }
local TitanSteamAura = ShifterVFX.Auras.Steam:GetChildren() :: { ParticleEmitter }
local ShifterTransformationParticles = ShifterVFX.Transformations.UniversalShiftModified :: Model
local player = Reference.Client.Player
local character = player.Character
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootpart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator
local lefthand = nil :: BasePart?
local righthand = nil :: BasePart?
local head = character:WaitForChild("Head")
local DefaultTitanData = {
	ChosenAnimation = nil,
	Running = {
		currentTick = tick(),
		originPressTime = tick(),
	},
	Stats = {
		AttackIndex = 1,
		MaxAttackIndex = #TitanConfig.Custom.LMBSequence,
		CurrentSpeed = 0,
		Stamina = TitanConfig.Default.Stats.Stamina.Maximum,
	},
	States = {
		canRun = true,
		isGuardingNape = false,
		isOnGround = false,
		isAttacking = false,
		isRunning = false,
		isSHeld = false,
		isWHeld = false,
		isLMBHeld = false,
	},
}

--// Variables
local TitanSFX = {} :: { Sound }
local TitanAnimations = {} :: Types.DefaultAnimationTracks
local TitanLMBAnimations = {}

--// Titan Variables
local TitanData = {} :: typeof(DefaultTitanData)

--// Main
local Titan = {}
Titan._effectList = {
	Roar = {} :: { Player },
}

--~~/// [[ Defaults ]] ///~~--
--~~[[ Non Module Functions ]]~~--
local function Cleanup()
	Log:printheader("Cleaning Connections")
	Ayano:Clean()
	table.clear(TitanData)
	table.clear(TitanAnimations)
end

local function UpdateCharacterData()
	character = player.Character or player.CharacterAdded:Wait()
	rootpart = character:WaitForChild("HumanoidRootPart")
	righthand = character:WaitForChild("RightHand")
	lefthand = character:WaitForChild("LeftHand")
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	head = character:WaitForChild("Head")
	selfRaycastParams.FilterDescendantsInstances = { character }
	Ayano2:Connect(humanoid.Died, function()
		Satellite.Send("TitanAction", "Died")
		Cleanup()
	end)
	Ayano2:Connect(character.ChildRemoved, function(instance)
		Log:warnheader("Voided")
		if instance.Name == "HumanoidRootPart" or instance.Name == "Hitbox" then
			Satellite.Send("TitanAction", "Voided")
			Cleanup()
		end
	end)
end

--~~[[ Private Functions ]]~~--

--~~[[ Init ]]~~--
function Titan._initData()
	table.clear(TitanData)
	table.clear(TitanAnimations)
	TitanData = Table.DeepCopy(DefaultTitanData)
end

function Titan._initHumanoidStates()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
end

function Titan._createDefaultTitanAnimations()
	local DefaultAnimations = TitanConfig.Default.DefaultAnimations
	for animationname: string, animationid: number in pairs(DefaultAnimations) do
		TitanAnimations[animationname] = animator:LoadAnimation(Anim.new(animationid))
	end
	TitanAnimations.Idle.Looped = true
	TitanAnimations.Idle.Priority = Enum.AnimationPriority.Idle
	TitanAnimations.Idle:Play()
end

function Titan._createTitanSFX()
	for soundname, sounddata: { number } in pairs(TitanConfig.Custom.ShifterSFX) do
		TitanSFX[soundname] = Sound.new(sounddata[1])
		TitanSFX[soundname].Volume = sounddata[2]
		if sounddata[3] then
			TitanSFX[soundname].PlaybackSpeed = sounddata[3]
		end
	end
end

--~~[[ Animation ]]~~--
function Titan._onJump(isEnteringJump: boolean)
	if isEnteringJump then
		TitanAnimations.Jump:Play()
		Titan._consumeStaminna(TitanConfig.Custom.JumpStaminaCost)
	end
end

function Titan._onRunning(speed: number)
	TitanData.Stats.CurrentSpeed = speed
end

function Titan._updateAnimations()
	if TitanData.Stats.CurrentSpeed < 5 or TitanData.States.napeEject or not TitanData.States.isOnGround then
		TitanAnimations.Walk:Stop()
		TitanAnimations.Run:Stop()
		return
	end
	if humanoid.WalkSpeed >= TitanConfig.Default.Stats.Humanoid.RunSpeed then
		if TitanAnimations.Walk.IsPlaying then
			TitanAnimations.Walk:Stop()
		end
		if not TitanAnimations.Run.IsPlaying then
			TitanAnimations.Run:Play(0.15, 1, 1)
		end
	elseif humanoid.WalkSpeed <= TitanConfig.Default.Stats.Humanoid.WalkSpeed then
		if TitanAnimations.Run.IsPlaying then
			TitanAnimations.Run:Stop()
		end
		if not TitanAnimations.Walk.IsPlaying then
			TitanAnimations.Walk:Play(0.15, 1, 1)
		end
	end
end

function Titan._initAnimator()
	Ayano:Connect(humanoid.Jumping, Titan._onJump)
	Ayano:Connect(humanoid.Running, Titan._onRunning)
	Ayano:Connect(RunService.RenderStepped, Titan._updateAnimations)
end

function Titan._playAnimation(track: AnimationTrack, name)
	Log:warnheader(name)
	TitanData.ChosenAnimation = track
end

--~~[[ Movement ]]~~--
function Titan._startRun()
	if TitanData.Stats.Stamina < TitanConfig.Default.Stats.Stamina.MinimumThreshold or TitanData.States.napeEject then
		return
	end
	TitanData.States.isRunning = true
	humanoid.WalkSpeed = TitanConfig.Default.Stats.Humanoid.RunSpeed
end

function Titan._endRun()
	if TitanData.States.napeEject then
		return
	end
	TitanData.States.isRunning = false
	humanoid.WalkSpeed = TitanConfig.Default.Stats.Humanoid.WalkSpeed
end

function Titan._setupForwardBackwardMovementInput()
	Ayano:Connect(UserInputService.InputBegan, function(input: InputObject, GameProcessedEvent: boolean)
		if GameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.S then
			TitanData.States.isSHeld = true
		end
		if input.KeyCode == Enum.KeyCode.W then
			TitanData.States.isWHeld = true
			TitanData.Running.currentTick = tick()
			if
				(
					TitanData.Running.currentTick - TitanData.Running.originPressTime
					<= TitanConfig.Default.DoubleTapThresholdTime
				) and TitanData.States.canRun
			then
				Titan._startRun()
			else
				TitanData.Running.originPressTime = TitanData.Running.currentTick
			end
		end
	end)
	Ayano:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.S then
			TitanData.States.isSHeld = false
		end
		if input.KeyCode == Enum.KeyCode.W then
			TitanData.States.isWHeld = false
			Titan._endRun()
		end
	end)
end
function Titan._initDefaultMovementController()
	Titan._setupForwardBackwardMovementInput()
end

--~~[[ Stamina ]]~~--
function Titan._consumeStaminna(amount: number)
	TitanData.Stats.Stamina = math.clamp(TitanData.Stats.Stamina - amount, 0, TitanConfig.Default.Stats.Stamina.Maximum)
end

function Titan._updateStamina()
	--~~[[ Stamina Drain ]]~~--
	local StaminaConsumptionRate = TitanConfig.Default.Stats.Stamina.ConsumptionRate
	local StaminaRegenerationRate = TitanConfig.Default.Stats.Stamina.RegenerationRate
	if TitanData.States.isRunning then
		Titan._consumeStaminna(StaminaConsumptionRate)
	else
		TitanData.Stats.Stamina =
			math.clamp(TitanData.Stats.Stamina + StaminaRegenerationRate, 0, TitanConfig.Default.Stats.Stamina.Maximum)
	end
	--~~[[ Update Stamina Consumers ]]~~--
	if TitanData.States.isRunning and TitanData.Stats.Stamina <= 5 then
		Titan._endRun()
	end
end

function Titan._activateGui()
	local StaminaGui = player.PlayerGui:FindFirstChild("StaminaDisplay") :: ScreenGui
	if StaminaGui then
		local StaminaTextLabel = StaminaGui:FindFirstChild("TextLabel") :: TextLabel
		if StaminaTextLabel then
			StaminaGui.Enabled = true
			local connection
			Ayano2:Connect(humanoid.Died, function()
				Log:print("Cleaning up Stamina Gui")
				connection:Disconnect()
				StaminaGui.Enabled = false
			end)
			connection = Ayano:Connect(RunService.Heartbeat, function()
				StaminaTextLabel.Text =
					`Stamina: {math.round(TitanData.Stats.Stamina)} | Health: {math.round(humanoid.Health)}`
			end)
		end
	end
end

function Titan._activateStaminaSystem()
	Ayano:Connect(RunService.Heartbeat, Titan._updateStamina)
	--if RunService:IsStudio() then
	Titan._activateGui()
	--end
end

--~~[[ State Handler ]]~~--
function Titan._activateGroundChecker()
	Ayano:Connect(RunService.Heartbeat, function()
		local raycast = game.Workspace:Raycast(rootpart.Position, Vector3.new(0, -70, 0), selfRaycastParams)
		if raycast and raycast.Instance then
			TitanData.States.isOnGround = true
		else
			TitanData.States.isOnGround = false
		end
	end)
	--[[ 	Ayano:Connect(humanoid.StateChanged, function(oldstate: Enum.HumanoidStateType, newstate: Enum.HumanoidStateType)
		if (oldstate == Enum.HumanoidStateType.Freefall) or (newstate == Enum.HumanoidStateType.Landed) then
			Titan._Landed()
		end
	end) ]]
end

--~~[[ General ]]~~--
function Titan._setCamera()
	Reference.Client.Camera.CameraSubject = humanoid
end

--~~[[ Public Functions ]]~~--
function Titan.Activate()
	Log:printheader("Titan Activating..")
	UpdateCharacterData()
	Titan._initData()
	Titan._setCamera()
	Titan._initHumanoidStates()
	Titan._createDefaultTitanAnimations()
	Titan._initAnimator()
	Titan._initDefaultMovementController()
	Titan._activateStaminaSystem()
	Titan._activateGroundChecker()
	Titan.ActivateCustom()
	Log:printheader("Titan Activated.")
end

--~~[[ Ran once by client on player join. ]]~~--
function Titan.Start()
	Titan._createTitanSFX()
end

function Titan.PlayTransformationCutscene() end

--~~/// [[ Transform Replicator ]] ///~~--

function Titan.CreateTransformationVFX(shifter: Player)
	Log:print("Replicating Transformation VFX")
	local TransformationParticles = ShifterTransformationParticles:Clone() :: BasePart
	local StraightSparks = TransformationParticles.Main.StraightSparks :: ParticleEmitter
	local LittleShootStuff = TransformationParticles.Main.LittleShootStuff :: ParticleEmitter
	local BottomAttachment = TransformationParticles.Bottom :: Attachment
	local TopAttachment = TransformationParticles.Top :: Attachment
	local TransformationID = HttpService:GenerateGUID()
	local SteamID = HttpService:GenerateGUID()
	local TemporaryColorCorrection = Instance.new("ColorCorrectionEffect")
	local shifterCharacter = shifter.Character
	local srootpart = shifterCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	if srootpart then
		srootpart.Anchored = true
	end

	--~~[[ Setup ]]~~--
	VFX.SetParticle(TransformationParticles, false)
	--~~/// [[ Begin Sequence ]] ///~~--
	task.wait(0.5)
	TitanSFX.Sparks:Play()

	--~~[[ Add Aura ]]~~--
	VFX.AddAura(ShifterLightningAura, shifterCharacter, TransformationID, TitanConfig.Custom.AuraTweenInfo)
	TemporaryColorCorrection.Parent = Lighting
	Property.SetTable(
		TemporaryColorCorrection,
		ColorCorrectionData.OnTransformation,
		TitanConfig.Custom.ColorCorrectionTweenInfo
	)
	task.wait(0.7)
	TitanSFX.Impact:Play()
	TitanSFX.Strike:Play()
	LittleShootStuff.Enabled = true
	StraightSparks.Enabled = true
	local connection = nil :: RBXScriptConnection?

	--~~[[ Attach Particle Model To Player ]]~~--

	if srootpart then
		srootpart.Anchored = true
		TransformationParticles.Position = srootpart.Position
	end
	connection = Ayano:Connect(RunService.RenderStepped, function()
		-- Update Shifter Character because the server might change it to the titan model.
		shifterCharacter = shifter.Character
	end)
	VFX.SetParticle(TransformationParticles.Beam, true)
	BottomAttachment.Position = TopAttachment.Position
	TransformationParticles.Parent = game.Workspace
	TweenService:Create(BottomAttachment, TitanConfig.Custom.TransformBeamTweenInfo, { Position = Vector3.zero }):Play()
	task.wait(1.25)
	if shifter == player then
		Satellite.Send("TransformationVFXFinished")
	end
	VFX.SetParticle(TransformationParticles, true)
	task.spawn(function()
		repeat
			local char = shifter.Character
			if char and char:HasTag("isTitan") then
				VFX.AddAura(TitanSteamAura, char, SteamID, TitanConfig.Custom.AuraTweenInfo)
			end
			task.wait()
		until char and char:HasTag("isTitan")
		Log:print("Titan character switched. Applying steam.")
	end)
	task.wait(3.5)
	shifterCharacter:ScaleTo(1)
	VFX.SetParticle(TransformationParticles, false)
	VFX.SetBeam(TransformationParticles, false)
	VFX.RemoveAura(TransformationID)
	task.wait(2)
	if srootpart then
		srootpart.Anchored = false
	end
	connection:Disconnect()
	TransformationParticles:Destroy()
	Property.SetTable(
		TemporaryColorCorrection,
		ColorCorrectionData.Default,
		TitanConfig.Custom.ColorCorrectionTweenInfo,
		function()
			TemporaryColorCorrection:Destroy()
		end
	)
	task.wait(6)
	VFX.RemoveAura(SteamID)
end

-- This is where the code differs for each titan.
--~~/// [[ Nape System ]] ///~~--

--[[ function Titan._initNapeControls()
	Ayano:Connect(UserInputService.InputBegan, function(input: InputObject, GameProcessedEvent: boolean)
		if GameProcessedEvent then
			return
		end
		if input.KeyCode == Enum.KeyCode.P then
			Titan._NapeEject()
		end
	end)
end
function Titan._activateNapeSystem()
	Titan._initNapeControls()
end ]]

--~~/// [[ Custom ]] ///~~--

--~~[[ Combat ]]~~--
--~~[[ Local Functions ]]~~--
local function NextLMBState(_Hitbox, AttackIndex)
	TitanData.States.isAttacking = false
	_Hitbox:Destroy()
	if AttackIndex == TitanData.Stats.MaxAttackIndex then
		TitanData.Stats.AttackIndex = 1
	else
		TitanData.Stats.AttackIndex = math.clamp(AttackIndex + 1, 1, TitanData.Stats.MaxAttackIndex)
	end
end
--~~[[ Combat Animations ]]~~--
function Titan._createCombatAnimations()
	for _, animationID: number in ipairs(TitanConfig.Custom.LMBSequence) do
		local AnimationTrack = animator:LoadAnimation(Anim.new(animationID))
		AnimationTrack.Priority = Enum.AnimationPriority.Action3
		table.insert(TitanLMBAnimations, AnimationTrack)
	end
end
--~~[[ States ]]~~--
function Titan._onHit(HitCharacters: { Model })
	if #HitCharacters > 0 then
		print(HitCharacters)
		Satellite.Send("TitanAction", "LightHit", HitCharacters, TitanData.Stats.AttackIndex)
	end
end
--~~[[ Light Attack ]]~~--
function Titan._LMB()
	--~~[[ Checks ]]~~--
	local isAttacking = TitanData.States.isAttacking
	local AttackIndex = TitanData.Stats.AttackIndex
	local RightIndex = 1
	local RightIndex2 = 3
	local LeftIndex = 2
	if isAttacking then
		return
	end
	--~~[[ Decay ]]~~--
	Ayano:TrackThread(
		task.delay(TitanConfig.Custom.Combat.LMB.ComboTimeout, function()
			TitanData.Stats.AttackIndex = 1
		end),
		"ComboDecay"
	)
	--~~[[ Pass Checks ]]~~--
	TitanData.States.isAttacking = true
	local CurrentAnimation = TitanLMBAnimations[AttackIndex]
	CurrentAnimation:Play()
	CurrentAnimation.Stopped:Once(function()
		local CFStart = (AttackIndex == RightIndex or AttackIndex == RightIndex2) and righthand.CFrame
			or lefthand.CFrame
		local CorrectedCFrame = CFrame.lookAt(CFStart.Position, CFStart.Position + rootpart.CFrame.LookVector.Unit)
		local HitboxCFrame = CorrectedCFrame * TitanConfig.Custom.Combat.LMB.Hitbox.CFrameOffset
		local Hitbox = SpatialHitbox.new(TitanConfig.Custom.Combat.LMB.Hitbox.Size, HitboxCFrame, { player })
		Hitbox:SetVisibility(true)
		if
			(character:GetAttribute("ArmDisabled_right") and (RightIndex == AttackIndex or AttackIndex == RightIndex2))
			or (character:GetAttribute("ArmDisabled_left") and LeftIndex == AttackIndex)
		then
			task.wait(1)
			NextLMBState(Hitbox, AttackIndex)
			return
		end
		Hitbox:SetCallback(Titan._onHit, true)
		Hitbox:Once()
		TitanData.States.isAttacking = false
		NextLMBState(Hitbox, AttackIndex)
	end)
end

--~~[[ Combat Input ]]~~--
function Titan._activateCombatInput()
	Ayano:Connect(UserInputService.InputBegan, function(input: InputObject, GameProcessedEvent: boolean)
		if GameProcessedEvent then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not TitanData.States.isGuardingNape then
			TitanData.States.isLMBHeld = true
			while TitanData.States.isLMBHeld do
				task.wait(0.1)
				Titan._LMB()
			end
		end
	end)
	Ayano:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TitanData.States.isLMBHeld = false
		end
	end)
end

function Titan.ActivateCustom()
	Titan._createCombatAnimations()
	Titan._activateCombatInput()
end

return Titan
