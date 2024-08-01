--[[

@rakken
Titan: Jaw Titan
Notes:
💀
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
local EyeAyano = Utils.ayano.new()
local DashAyano = Utils.ayano.new()
local PartAyano = Utils.ayano.new()
local GrabTrackerAyano = Utils.ayano.new()
local Log = Utils.log.new("[Jaw Client]")
local ColorCorrectionData = TitanConfig.Default.ColorCorrectionData
local selfRaycastParams = RaycastParams.new()
selfRaycastParams.FilterDescendantsInstances = { Reference.Client.Player.Character }

--// Constants
local ShifterAssets = AssetConfig.ShifterAssets :: Folder
local ShifterVFX = ShifterAssets.VFX :: Folder
local ShifterLightningAura = ShifterVFX.Auras.SmallLightning:GetChildren() :: { ParticleEmitter }
local TitanSteamAura = ShifterVFX.Auras.Steam:GetChildren() :: { ParticleEmitter }
local TitanTrail = ShifterVFX.Trails.Trail :: BasePart
local BasicHitVFX = ShifterVFX.Hit.BasicHit :: BasePart
local ShifterTransformationParticles = ShifterVFX.Transformations.UniversalShiftModified2 :: Model
local player = Reference.Client.Player
local character = player.Character
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootpart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator
local head = nil :: BasePart?
local hardnape = nil :: BasePart?
local leftlowerarm = nil :: BasePart?
local rightlowerarm = nil :: BasePart?
local Eyegui = nil :: ScreenGui?
local canCleanup = false
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
		mode = "Attack",
		napeEject = false,
		canRun = true,
		canRoar = true,
		canAttackDash = true,
		isHarden = false,
		canGrabDash = true,
		isGuardingNape = false,
		isDashing = false,
		isRoaring = false,
		isOnGround = false,
		isAttacking = false,
		isClimbing = false,
		isRunning = false,
		isSHeld = false,
		isWHeld = false,
		isLMBHeld = false,
	},
}

--// Variables
local TitanSFX = {} :: { Sound }
local TitanSpecialSFX = {} :: { Sound }
local TitanAnimations = {} :: Types.DefaultAnimationTracks
local TitanLightAttackAnimations = {} :: { AnimationTrack }
local TitanCombatAnimations = {} :: { any: AnimationTrack }
local TitanMiscAnimations = {} :: { any: AnimationTrack }

--// Titan Variables
local TitanData = {} :: typeof(DefaultTitanData)

--// Main
local Titan = {}
Titan._effectList = {
	Roar = {} :: { Player },
}

--~~/// [[ Defaults ]] ///~~--
--~~[[ Non Module Functions ]]~~--
local function Cleanup(override: boolean?)
	repeat
		task.wait()
	until canCleanup or override
	canCleanup = false
	Log:printheader("Cleaning Connections")
	Ayano:Clean()
	Ayano2:Clean()
	table.clear(TitanData)
	table.clear(TitanAnimations)
	table.clear(TitanLightAttackAnimations)
	table.clear(TitanCombatAnimations)
	table.clear(TitanMiscAnimations)
end

local function UpdateCharacterData()
	character = player.Character or player.CharacterAdded:Wait()
	rootpart = character:WaitForChild("HumanoidRootPart")
	leftlowerarm = character:WaitForChild("LeftLowerArm")
	rightlowerarm = character:WaitForChild("RightLowerArm")
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	head = character:WaitForChild("TitanHead"):WaitForChild("Head")
	hardnape = character:WaitForChild("TitanHead"):WaitForChild("NapeHarden")
	selfRaycastParams.FilterDescendantsInstances = { character }
	Ayano2:Connect(humanoid.HealthChanged, function()
		if humanoid.Health <= 0 then
			Log:warn("Jaw titan died. Cleaning up.")
			TitanAnimations.DeShift:Play()
			TitanAnimations.DeShift.Stopped:Wait()
			canCleanup = true
			Cleanup()
			Satellite.Send("TitanAction", "Died")
		end
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
	table.clear(TitanLightAttackAnimations)
	table.clear(TitanCombatAnimations)
	table.clear(TitanMiscAnimations)
	TitanData = Table.DeepCopy(DefaultTitanData)
end

function Titan._initHumanoidStates()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	--[[ 	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) ]]
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
	for _, sound: Sound in ShifterAssets.SFX.Special:GetChildren() do
		TitanSpecialSFX[sound.Name] = sound:Clone()
		TitanSpecialSFX[sound.Name].Parent = game:GetService("SoundService")
	end
end

--~~[[ Animation ]]~~--
function Titan._onRunning(speed: number)
	TitanData.Stats.CurrentSpeed = speed
end

function Titan._updateAnimations()
	if TitanData.Stats.CurrentSpeed < 5 or TitanData.States.isClimbing or TitanData.States.napeEject then
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
	Log:warnheader("Run action began")
	TitanData.States.isRunning = true
	humanoid.WalkSpeed = TitanConfig.Default.Stats.Humanoid.RunSpeed
end

function Titan._endRun()
	if TitanData.States.napeEject then
		return
	end
	Log:warnheader("Run action ended")
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
function Titan._consumeStamina(amount: number)
	TitanData.Stats.Stamina = math.clamp(TitanData.Stats.Stamina - amount, 0, TitanConfig.Default.Stats.Stamina.Maximum)
end

function Titan._addStamina(amount: number)
	TitanData.Stats.Stamina = math.clamp(TitanData.Stats.Stamina + amount, 0, TitanConfig.Default.Stats.Stamina.Maximum)
end

function Titan._updateStamina()
	--~~[[ Stamina Drain ]]~~--
	local StaminaConsumptionRate = TitanConfig.Default.Stats.Stamina.ConsumptionRate
	local StaminaRegenerationRate = TitanConfig.Default.Stats.Stamina.RegenerationRate
	if TitanData.States.isRunning then
		Titan._consumeStamina(StaminaConsumptionRate)
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
				StaminaTextLabel.Text = `Stamina: {math.round(TitanData.Stats.Stamina)} | Health: {math.round(
					humanoid.Health
				)} | Mode: {TitanData.States.mode}`
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
	Titan.ActivateCustom()
	Log:printheader("Titan Activated.")
end

function Titan.Start()
	Titan._createTitanSFX()
	Titan._activateReplicator()
	Titan._setupGrabReplicator()
end

function Titan.PlayTransformationCutscene() end

function Titan.CreateTransformationVFX(shifter: Player)
	Log:print("Replicating Transformation VFX")
	if shifter == player then
		local _character = player.Character
		local _humanoid = _character and _character:FindFirstChildOfClass("Humanoid")
		if _humanoid then
			local _animator = _humanoid:FindFirstChildOfClass("Animator")
			if _animator then
				_animator
					:LoadAnimation(Ayano:TrackInstance(Anim.new(TitanConfig.Default.DefaultAnimations.Shift)))
					:Play()
			end
		end
	end
	local TransformationParticles = ShifterTransformationParticles:Clone() :: BasePart
	local StraightSparks = TransformationParticles.Main.Part.Main.StraightSparks :: ParticleEmitter
	local LittleShootStuff = TransformationParticles.Main.Part.Main.LittleShootStuff :: ParticleEmitter
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
	--~~[[ Add Aura ]]~~--
	VFX.AddAura(ShifterLightningAura, shifterCharacter, TransformationID, TitanConfig.Custom.AuraTweenInfo)
	TitanSFX.Sparks:Play()
	task.wait(1)

	--~~/// [[ Begin Sequence ]] ///~~--
	task.wait(0.5)

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
	TransformationParticles.Main:ScaleTo(0.1)
	if srootpart then
		srootpart.Anchored = true
		TransformationParticles.Position = srootpart.Position
	end
	local alpha = 0
	connection = Ayano:Connect(RunService.RenderStepped, function(delta: number)
		alpha = math.clamp(alpha + delta, 0.01, 1)
		local talpha = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		-- Update Shifter Character because the server might change it to the titan model.
		shifterCharacter = shifter.Character
		TransformationParticles.Main:ScaleTo(talpha)
	end)
	BottomAttachment.Position = TopAttachment.Position
	TransformationParticles.Parent = game.Workspace
	VFX.SetParticle(TransformationParticles.Beam, true)
	TweenService:Create(BottomAttachment, TitanConfig.Custom.TransformBeamTweenInfo, { Position = Vector3.zero }):Play()
	task.wait(1.25)
	if shifter == player then
		Satellite.Send("TransformationVFXFinished")
	end
	VFX.SetParticle(TransformationParticles.Main.Part.Main, true)
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
function Titan._NapeEject()
	local isOnGround = TitanData.States.isOnGround
	if TitanData.States.isAttacking or TitanData.States.isRoaring or not isOnGround then
		return
	end
	TitanData.States.napeEject = true
	Log:printheader("Action: Nape Eject")
	for _, track: AnimationTrack in pairs(TitanAnimations) do
		track:Stop()
	end
	Log:print("Stopped Animations.")
	humanoid.WalkSpeed = 0
	TitanAnimations.Idle:Stop()
	Log:print("Playing deshift.")
	TitanAnimations.DeShift:Play()
	Cleanup(true)
	Log:print("NapeEjectInit")
	Satellite.Send("TitanAction", "NapeEjectInit")
	task.wait()
	Ayano:TrackThread(task.delay(1, function()
		Log:print("Attempting NapeEjectAction.")
		Satellite.Send("TitanAction", "NapeEject")
	end))
end

function Titan._initNapeControls()
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
	Titan._initNapeUpdater()
end

--~~/// [[ Custom ]] ///~~--
--~~[[ Movement ]]~~--
function Titan._activateJumpChecker()
	Ayano:Connect(RunService.Heartbeat, function()
		local isOnGround = TitanData.States.isOnGround
		if isOnGround then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
	end)
end

function Titan._Landed()
	Satellite.Send("TitanAction", "Landed")
end

function Titan._activateGroundChecker()
	Ayano:Connect(RunService.Heartbeat, function()
		local raycast = game.Workspace:Raycast(rootpart.Position, Vector3.new(0, -50, 0), selfRaycastParams)
		if raycast and raycast.Instance then
			TitanData.States.isOnGround = true
		else
			TitanData.States.isOnGround = false
		end
	end)
	Ayano:Connect(humanoid.StateChanged, function(oldstate: Enum.HumanoidStateType, newstate: Enum.HumanoidStateType)
		if (oldstate == Enum.HumanoidStateType.Freefall) or (newstate == Enum.HumanoidStateType.Landed) then
			Titan._Landed()
		end
	end)
end

function Titan._UpdateClimb()
	local range = TitanConfig.Custom.Climbing.ClimbRange
	local RaycastResult = game.Workspace:Raycast(
		rootpart.Position - Vector3.new(0, 32, 0),
		rootpart.CFrame.LookVector * range,
		selfRaycastParams
	)
	local Wall = RaycastResult and RaycastResult.Instance or nil
	if Wall and Wall:IsA("BasePart") and Wall.Anchored ~= true then
		return
	end
	if Wall and TitanData.States.isWHeld then
		rootpart.Anchored = false
		rootpart.AssemblyLinearVelocity = Vector3.new(
			rootpart.AssemblyLinearVelocity.X,
			TitanConfig.Custom.Climbing.ClimbSpeed + humanoid.WalkSpeed,
			rootpart.AssemblyLinearVelocity.Z
		)
		TitanAnimations.Run:Stop()
		TitanAnimations.Walk:Stop()
		TitanMiscAnimations.Jump:Stop()
		TitanMiscAnimations.Freefall:Stop()
		TitanMiscAnimations.Climb:AdjustSpeed(1)
		TitanData.States.isClimbing = true
		if not TitanMiscAnimations.Climb.IsPlaying then
			TitanMiscAnimations.Climb:Play()
		end
	elseif Wall and TitanData.States.isSHeld then
		rootpart.Anchored = false
		rootpart.AssemblyLinearVelocity = Vector3.new(
			rootpart.AssemblyLinearVelocity.X,
			-TitanConfig.Custom.Climbing.ClimbSpeed,
			rootpart.AssemblyLinearVelocity.Z
		)
		TitanAnimations.Run:Stop()
		TitanAnimations.Walk:Stop()
		TitanMiscAnimations.Jump:Stop()
		TitanMiscAnimations.Freefall:Stop()
		TitanMiscAnimations.Climb:AdjustSpeed(-1)
		TitanData.States.isClimbing = true
		if not TitanMiscAnimations.Climb.IsPlaying then
			TitanMiscAnimations.Climb:Play()
		end
	elseif Wall and not TitanData.States.isWHeld and not TitanData.States.isSHeld then
		TitanAnimations.Run:Stop()
		TitanAnimations.Walk:Stop()
		TitanMiscAnimations.Jump:Stop()
		TitanMiscAnimations.Freefall:Stop()
		TitanMiscAnimations.Climb:AdjustSpeed(0)
		rootpart.Anchored = true
	else
		rootpart.Anchored = false
		TitanMiscAnimations.Climb:Stop()
		TitanData.States.isClimbing = false
	end
end

function Titan._activateClimber()
	Ayano:Connect(RunService.Heartbeat, Titan._UpdateClimb)
end

--~~[[ Animations ]]~~--
function Titan._updateMiscAnims()
	local LastState = humanoid:GetState()
	if LastState == Enum.HumanoidStateType.Freefall then
		if not TitanMiscAnimations.Jump.IsPlaying and not TitanMiscAnimations.Freefall.IsPlaying then
			TitanMiscAnimations.Freefall:Play()
		end
		TitanAnimations.Run:Stop()
		TitanAnimations.Walk:Stop()
	else
		TitanMiscAnimations.Freefall:Stop()
	end
end

function Titan._createMiscAnimations()
	for animationName: string, animationID: number in pairs(TitanConfig.Custom.MiscAnimations) do
		local AnimationTrack = animator:LoadAnimation(Anim.new(animationID))
		AnimationTrack.Priority = Enum.AnimationPriority.Action
		TitanMiscAnimations[animationName] = AnimationTrack
	end
	TitanMiscAnimations.Climb.Priority = Enum.AnimationPriority.Action2
end

function Titan._onJump(isEnteringJump: boolean)
	if isEnteringJump then
		TitanSpecialSFX.Jump:Play()
		TitanMiscAnimations.Jump:Play()
		Titan._consumeStamina(TitanConfig.Custom.JumpStaminaCost)
	end
end

function Titan._activateMiscAnimator()
	Ayano:Connect(RunService.Heartbeat, Titan._updateMiscAnims)
	Ayano:Connect(humanoid.Jumping, Titan._onJump)
end

function Titan._createCombatAnimations()
	for _, animationID: number in ipairs(TitanConfig.Custom.LMBSequence) do
		local AnimationTrack = animator:LoadAnimation(Anim.new(animationID))
		AnimationTrack.Priority = Enum.AnimationPriority.Action3
		table.insert(TitanLightAttackAnimations, AnimationTrack)
	end
	for animationName: string, animationID: number in pairs(TitanConfig.Custom.CombatAnimations) do
		local AnimationTrack = animator:LoadAnimation(Anim.new(animationID))
		AnimationTrack.Priority = Enum.AnimationPriority.Action3
		TitanCombatAnimations[animationName] = AnimationTrack
	end
end

--~~[[ Combat ]]~~--
function Titan._Roar()
	--~~[[ Checks ]]~~--
	if
		TitanData.States.isAttacking
		or not TitanData.States.canRoar
		or TitanData.States.isClimbing
		or (TitanCombatAnimations.Roar :: AnimationTrack).IsPlaying
	then
		return
	end
	--~~[[ Roar ]]~~--
	task.delay(TitanConfig.Custom.Combat.Roar.Cooldown, function()
		TitanData.States.canRoar = true
	end)
	TitanData.States.canRoar = false
	TitanData.States.isRoaring = true
	TitanCombatAnimations.Roar:Play()
	TitanCombatAnimations.Roar.Stopped:Once(function()
		TitanData.States.isRoaring = false
		Titan._endRun()
	end)
	Titan._addStamina(TitanConfig.Custom.Combat.Roar.StaminaAdd)
	Satellite.Send("TitanAction", "Roar")
end

function Titan._switchMode()
	--~~[[ Checks ]]~~--
	if TitanData.States.mode == "Grab" then
		TitanData.States.mode = "Attack"
	else
		TitanData.States.mode = "Grab"
	end
end

-- Bite
function Titan._BiteGrab()
	if TitanData.States.isDashing or not TitanData.States.canGrabDash then
		return
	end

	--~~[[ Passed Checks ]]~~--
	TitanData.States.canGrabDash = false
	local Cost = TitanConfig.Custom.Combat.Bite.GrabStaminaCost
	local Cooldown = TitanConfig.Custom.Combat.Bite.GrabCooldown
	Titan._consumeStamina(Cost)
	Ayano:TrackThread(task.delay(Cooldown, function()
		TitanData.States.canGrabDash = true
	end))
	Satellite.Send("TitanAction", "BiteVFX")
	TitanData.States.isDashing = true
	humanoid.AutoRotate = false
	local TitanCF = rootpart.CFrame
	local TitanDirection = rootpart.CFrame.LookVector
	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.Bite.BiteHitbox, nil, { player }))
	Hitbox:Bind(rootpart, TitanConfig.Custom.Combat.Bite.Offset)
	Hitbox:SetVisibility(true)
	Hitbox:Start()
	Hitbox:SetCallback(function(hit: Model)
		if hit:HasTag("isTitan") then
			return
		end
		Hitbox:Stop()
		Satellite.Send("TitanAction", "BiteGrab", hit)
	end)
	DashAyano:Clean()
	local AlignPosition = DashAyano:TrackInstance(Instance.new("AlignPosition"))
	local AlignOrienation = DashAyano:TrackInstance(Instance.new("AlignOrientation"))
	local RootAttachment = DashAyano:TrackInstance(Instance.new("Attachment"))
	local ToAttachment = DashAyano:TrackInstance(Instance.new("Attachment"))
	local DashDistance = TitanConfig.Custom.Combat.Bite.DashMagnitude
	--~~[[ Attachments ]]~~--
	RootAttachment.Parent = rootpart
	ToAttachment.WorldPosition = TitanCF.Position + TitanDirection * DashDistance
	ToAttachment.Parent = game.Workspace.Terrain
	--~~[[ Align Position ]]~~--
	AlignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
	AlignPosition.Attachment0 = RootAttachment
	AlignPosition.Attachment1 = ToAttachment
	AlignPosition.RigidityEnabled = false
	AlignPosition.Responsiveness = 50
	AlignPosition.MaxForce = math.huge
	AlignPosition.Parent = rootpart
	--~~[[ Align Orienation ]]~~--
	AlignOrienation.AlignType = Enum.AlignType.AllAxes
	AlignOrienation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AlignOrienation.RigidityEnabled = true
	AlignOrienation.CFrame = TitanCF
	AlignOrienation.Attachment0 = RootAttachment
	AlignOrienation.Parent = rootpart
	--~~[[ Animations ]]~~--
	TitanAnimations.Walk:AdjustSpeed(0)
	TitanAnimations.Run:AdjustSpeed(0)
	TitanCombatAnimations.Grab:Play()
	task.wait(0.3)
	Hitbox:Stop()
	--~~[[ Cleanup ]]~~--
	DashAyano:Clean()
	humanoid.AutoRotate = true
	TitanAnimations.Walk:AdjustSpeed(1)
	TitanAnimations.Run:AdjustSpeed(1)
	TitanData.States.isDashing = false
end

function Titan._BiteAttack()
	if TitanData.States.isDashing or not TitanData.States.canAttackDash then
		return
	end

	--~~[[ Passed Checks ]]~~--
	TitanData.States.canAttackDash = false
	local Cost = TitanConfig.Custom.Combat.Bite.AttackStaminaCost
	local Cooldown = TitanConfig.Custom.Combat.Bite.AttackCooldown
	Titan._consumeStamina(Cost)
	Ayano:TrackThread(task.delay(Cooldown, function()
		TitanData.States.canAttackDash = true
	end))
	Satellite.Send("TitanAction", "BiteVFX")
	TitanData.States.isDashing = true
	humanoid.AutoRotate = false
	local TitanCF = rootpart.CFrame
	local TitanDirection = rootpart.CFrame.LookVector
	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.Bite.BiteHitbox, nil, { player }))
	Hitbox:Bind(rootpart, TitanConfig.Custom.Combat.Bite.Offset)
	Hitbox:SetVisibility(true)
	Hitbox:SetContinous(true)
	Hitbox:Start()
	Hitbox:SetCallback(function(hit)
		Satellite.Send("TitanAction", "BiteAttack", hit)
	end)
	DashAyano:Clean()
	local AlignPosition = DashAyano:TrackInstance(Instance.new("AlignPosition"))
	local AlignOrienation = DashAyano:TrackInstance(Instance.new("AlignOrientation"))
	local RootAttachment = DashAyano:TrackInstance(Instance.new("Attachment"))
	local ToAttachment = DashAyano:TrackInstance(Instance.new("Attachment"))
	local DashDistance = TitanConfig.Custom.Combat.Bite.DashMagnitude
	--~~[[ Attachments ]]~~--
	RootAttachment.Parent = rootpart
	ToAttachment.WorldPosition = TitanCF.Position + TitanDirection * DashDistance
	ToAttachment.Parent = game.Workspace.Terrain
	--~~[[ Align Position ]]~~--
	AlignPosition.Mode = Enum.PositionAlignmentMode.TwoAttachment
	AlignPosition.Attachment0 = RootAttachment
	AlignPosition.Attachment1 = ToAttachment
	AlignPosition.RigidityEnabled = false
	AlignPosition.Responsiveness = 50
	AlignPosition.MaxForce = math.huge
	AlignPosition.Parent = rootpart
	--~~[[ Align Orienation ]]~~--
	AlignOrienation.AlignType = Enum.AlignType.AllAxes
	AlignOrienation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AlignOrienation.RigidityEnabled = true
	AlignOrienation.CFrame = TitanCF
	AlignOrienation.Attachment0 = RootAttachment
	AlignOrienation.Parent = rootpart
	--~~[[ Animations ]]~~--
	TitanAnimations.Walk:AdjustSpeed(0)
	TitanAnimations.Run:AdjustSpeed(0)
	TitanCombatAnimations.Bite:Play()
	task.wait(0.3)
	Hitbox:Stop()
	--~~[[ Cleanup ]]~~--
	DashAyano:Clean()
	humanoid.AutoRotate = true
	TitanAnimations.Walk:AdjustSpeed(1)
	TitanAnimations.Run:AdjustSpeed(1)
	TitanData.States.isDashing = false
end

-- M1

local function NextLMBState(_Hitbox, AttackIndex)
	TitanData.States.isAttacking = false
	if _Hitbox then
		_Hitbox:Destroy()
	end
	if AttackIndex == TitanData.Stats.MaxAttackIndex then
		TitanData.Stats.AttackIndex = 1
	else
		TitanData.Stats.AttackIndex = math.clamp(AttackIndex + 1, 1, TitanData.Stats.MaxAttackIndex)
	end
end

function Titan._LMB()
	--~~[[ Checks ]]~~--
	local isAttacking = TitanData.States.isAttacking
	local isRoaring = TitanData.States.isRoaring
	local AttackIndex = TitanData.Stats.AttackIndex
	local RightIndex = 2
	local LeftIndex = 1
	local Arm = leftlowerarm :: BasePart
	if isAttacking or isRoaring then
		return
	end
	--~~[[ Pass Checks 1 ]]~~--
	--~~[[ Sounds ]]~~----
	--~~[[ Hitbox/Main ]]~~--
	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.Hitbox.LMB.Size, nil, { player }))
	Hitbox:SetVisibility(true)
	TitanData.States.isAttacking = true
	local CurrentAnimation = TitanLightAttackAnimations[AttackIndex]
	if
		(character:GetAttribute("ArmDisabled_right") and RightIndex == AttackIndex)
		or (character:GetAttribute("ArmDisabled_left") and LeftIndex == AttackIndex)
	then
		task.wait(1)
		NextLMBState(Hitbox, AttackIndex)
		return
	end
	if AttackIndex == RightIndex then
		Arm = rightlowerarm
	end
	--~~[[ Pass Checks 2 ]]~~
	Hitbox:Bind(Arm, TitanConfig.Custom.Combat.Hitbox.LMB.CFrameOffset)
	TitanSpecialSFX.Swing:Play()
	CurrentAnimation:Play()
	Hitbox:SetContinous(true)
	Hitbox:SetCallback(Titan._onHit)
	Hitbox:SetLiveCallback(Titan._onLiveHit)
	Hitbox:Start()
	CurrentAnimation.Stopped:Once(function()
		TitanData.States.isAttacking = false
		NextLMBState(Hitbox, AttackIndex)
	end)
end

function Titan._onLiveHit(HitCharacter: Model)
	if HitCharacter:HasTag("isTitan") then
		Satellite.Send("TitanAction", "TitanLightHit", TitanData.Stats.AttackIndex)
	end
end

function Titan._onHit(HitCharacters: { Model })
	if Utils.table.getDictLength(HitCharacters) > 0 then
		Satellite.Send("TitanAction", "LightHit", HitCharacters)
	end
end

--~~[[ End of M1 ]]~~--

function Titan._Eat()
	if not character:FindFirstChild("GrabWeld") then
		return
	end
	local EatTrack = TitanCombatAnimations.Eat :: AnimationTrack
	EatTrack:Play()
	EatTrack.Stopped:Once(function()
		if character:GetAttribute("ArmDisabled_right") then
			Log:warn("Cancelling Eat. Arm is disabled.")
			return
		end
		Satellite.Send("TitanAction", "Eat")
	end)
end

--~~/// [[ Nape ]] ///~~--
function Titan._NapeGuard(bool: boolean)
	if bool then
		TitanCombatAnimations.NapeGuard:Play()
	else
		TitanCombatAnimations.NapeGuard:Stop()
	end
	TitanData.States.isGuardingNape = bool
	Satellite.Send("TitanAction", "NapeGuard", bool)
end

function Titan._NapeHarden(state: boolean?)
	TitanData.States.isHarden = state or not TitanData.States.isHarden
	if TitanData.States.isHarden == true then
		if TitanData.Stats.Stamina >= TitanConfig.Custom.Combat.NapeHarden.MinimumStaminaRequired then
			Satellite.Send("TitanAction", "NapeHarden", hardnape, TitanData.States.isHarden)
		end
	else
		Satellite.Send("TitanAction", "NapeHarden", hardnape, TitanData.States.isHarden)
	end
end

function Titan._NapeUpdate()
	local Stamina = TitanData.Stats.Stamina
	local MinimumStaminaRequirement = TitanConfig.Custom.Combat.NapeHarden.MinimumStaminaRequired
	local NapeHardenCost = TitanConfig.Custom.Combat.NapeHarden.StaminaDrain
	if TitanData.States.isHarden then
		if Stamina <= MinimumStaminaRequirement then
			TitanData.States.isHarden = false
			Satellite.Send("TitanAction", "NapeHarden", hardnape, false)
			return
		end
		Titan._consumeStamina(NapeHardenCost)
	end
end

function Titan._initNapeUpdater()
	Ayano:Connect(RunService.Heartbeat, function()
		Titan._NapeUpdate()
	end)
end

--~~/// [[ Combat Input ]] ///~~--
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
		if input.KeyCode == Enum.KeyCode.Q and not TitanData.States.isAttacking and not TitanData.States.isDashing then
			Titan._NapeGuard(true)
		end
		if input.KeyCode == Enum.KeyCode.E and not TitanData.States.isGuardingNape then
			if character:FindFirstChild("GrabWeld") then
				Satellite.Send("TitanAction", "UnGrab")
				return
			end
			if TitanData.States.mode == "Attack" then
				Titan._BiteAttack()
			else
				Titan._BiteGrab()
			end
		end
		if input.KeyCode == Enum.KeyCode.R and not TitanData.States.isGuardingNape then
			Titan._Roar()
		end
		if input.KeyCode == Enum.KeyCode.Z then
			Titan._switchMode()
		end
		if input.KeyCode == Enum.KeyCode.C then
			Titan._Eat()
		end
		if input.KeyCode == Enum.KeyCode.F then
			Titan._NapeHarden()
		end
	end)
	Ayano:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TitanData.States.isLMBHeld = false
		end
		if input.KeyCode == Enum.KeyCode.Q then
			Titan._NapeGuard(false)
		end
	end)
end

--~~/// [[ Misc ]] ///~~--
function Titan._onRightStomp()
	if not TitanData.States.isOnGround and not TitanData.States.isClimbing then
		return
	end
	Satellite.Send("TitanAction", "RightStomp")
end

function Titan._onLeftStomp()
	if not TitanData.States.isOnGround and not TitanData.States.isClimbing then
		return
	end
	Satellite.Send("TitanAction", "LeftStomp")
end

function Titan._setupMovementSFX()
	local WalkTrack = TitanAnimations.Walk
	local RunTrack = TitanAnimations.Run
	local ClimbTrack = TitanMiscAnimations.Climb :: AnimationTrack
	Ayano:Connect(WalkTrack:GetMarkerReachedSignal("RightStomp"), Titan._onRightStomp)
	Ayano:Connect(RunTrack:GetMarkerReachedSignal("RightStomp"), Titan._onRightStomp)
	Ayano:Connect(WalkTrack:GetMarkerReachedSignal("LeftStomp"), Titan._onLeftStomp)
	Ayano:Connect(RunTrack:GetMarkerReachedSignal("LeftStomp"), Titan._onLeftStomp)
	Ayano:Connect(ClimbTrack:GetMarkerReachedSignal("LeftStomp"), Titan._onLeftStomp)
	Ayano:Connect(ClimbTrack:GetMarkerReachedSignal("RightStomp"), Titan._onRightStomp)
end

function Titan._updateCombatEffects()
	if TitanData.States.isRoaring then
		humanoid.WalkSpeed = 0
	end
end

function Titan._activateCombatEffects()
	Ayano:Connect(RunService.Heartbeat, Titan._updateCombatEffects)
end

function Titan._activateCombatController()
	Titan._activateCombatInput()
	Titan._activateCombatEffects()
end

--~~/// [[ Replicator ]] ///~~--
local function ConfigCrater(partList: { BasePart }, state: "OnCreate" | "OnMidpoint" | "OnEnd")
	if not state then
		Property.BatchSet(partList, { CanCollide = false })
	end
	if state == "OnMidpoint" then
		local ti = TweenInfo.new(2, Enum.EasingStyle.Linear)
		for _, v in ipairs(partList) do
			if v:IsA("BasePart") then
				TweenService:Create(v, ti, { Transparency = 1 }):Play()
			end
		end
	end
end

function Titan.onRightStomp(shifter: Player)
	local shiftercharacter = shifter.Character

	local RightFoot = shiftercharacter:FindFirstChild("RightFoot") or shiftercharacter:WaitForChild("RightFoot", 5)
	local SoundFX = RightFoot:FindFirstChildOfClass("Attachment")
		and RightFoot:FindFirstChildOfClass("Attachment"):FindFirstChildOfClass("Sound")
	if SoundFX then
		SoundFX:Play()
	end
	if not RightFoot then
		Log:warn("Could not setup movement sfx for right foot. RightFoot missing.")
		return
	end
	VFX.EmitParticle(RightFoot)
end

function Titan.onLeftStomp(shifter: Player)
	local shiftercharacter = shifter.Character

	local LeftFoot = shiftercharacter:FindFirstChild("LeftFoot") or shiftercharacter:WaitForChild("LeftFoot", 5)
	local SoundFX = LeftFoot:FindFirstChildOfClass("Attachment")
		and LeftFoot:FindFirstChildOfClass("Attachment"):FindFirstChildOfClass("Sound")
	if SoundFX then
		SoundFX:Play()
	end
	if not LeftFoot then
		Log:warn("Could not setup movement sfx for left foot. LeftFoot missing.")
		return
	end
	VFX.EmitParticle(LeftFoot)
end

function Titan.onHit(shifter: Player, AttackIndex: number)
	local TitanCharacter = shifter.Character
	-- Right Hand
	if AttackIndex == 2 then
		local RightHandModel = TitanCharacter:FindFirstChild("RightHand")
		local RightHand = RightHandModel:FindFirstChild("RightHand")
		warn(RightHandModel, RightHand)
		if RightHand then
			local HitEffect = BasicHitVFX:Clone()
			HitEffect.Anchored = false
			HitEffect.CanCollide = false
			HitEffect.Transparency = 1
			HitEffect.Parent = game.Workspace
			HitEffect.CFrame = RightHand.CFrame
			BasePart.WeldTogether(RightHand, HitEffect)
			VFX.EmitParticle(HitEffect)
			game:GetService("Debris"):AddItem(HitEffect, 5)
		end
	end
	if AttackIndex == 1 then
		local LeftHandModel = TitanCharacter:FindFirstChild("LeftHand")
		local LeftHand = LeftHandModel:FindFirstChild("LeftHand")
		if LeftHand then
			local HitEffect = BasicHitVFX:Clone()
			HitEffect.Anchored = false
			HitEffect.CanCollide = false
			HitEffect.Transparency = 1
			HitEffect.Parent = game.Workspace
			HitEffect.CFrame = LeftHand.CFrame
			BasePart.WeldTogether(LeftHand, HitEffect)
			VFX.EmitParticle(HitEffect)
			game:GetService("Debris"):AddItem(HitEffect, 5)
		end
	end
	TitanSFX.Hit:Play()
end

function Titan.onLanded(shifter: Player)
	local shifterCharacter = shifter.Character
	if not shifterCharacter then
		return
	end
	local Filter = { shifterCharacter }
	local RightFoot = shifterCharacter:FindFirstChild("RightFoot") :: BasePart
	local LeftFoot = shifterCharacter:FindFirstChild("LeftFoot") :: BasePart
	local RightHand = shifterCharacter:FindFirstChild("RightHand") :: Model
	local LeftHand = shifterCharacter:FindFirstChild("LeftHand") :: Model

	TitanSpecialSFX.Land:Play()

	if RightFoot then
		Rubble.Crater.Create(CFrame.new(RightFoot.Position), Rubble.Presets.Crater.Small, Filter, ConfigCrater)
		Rubble.Explosion.Create(CFrame.new(RightFoot.Position), Rubble.Presets.Explosion.Small, Filter, ConfigCrater)
	end
	if LeftFoot then
		Rubble.Crater.Create(CFrame.new(LeftFoot.Position), Rubble.Presets.Crater.Small, Filter, ConfigCrater)
		Rubble.Explosion.Create(CFrame.new(LeftFoot.Position), Rubble.Presets.Explosion.Small, Filter, ConfigCrater)
	end
	if RightHand then
		Rubble.Crater.Create(
			CFrame.new(RightHand:GetPivot().Position),
			Rubble.Presets.Crater.Small,
			Filter,
			ConfigCrater
		)
		Rubble.Explosion.Create(
			CFrame.new(RightHand:GetPivot().Position),
			Rubble.Presets.Explosion.Small,
			Filter,
			ConfigCrater
		)
	end
	if LeftHand then
		Rubble.Crater.Create(
			CFrame.new(LeftHand:GetPivot().Position),
			Rubble.Presets.Crater.Small,
			Filter,
			ConfigCrater
		)
		Rubble.Explosion.Create(
			CFrame.new(LeftHand:GetPivot().Position),
			Rubble.Presets.Explosion.Small,
			Filter,
			ConfigCrater
		)
	end
end

function Titan.onBiteVFX(shifter: Player)
	local TitanModel = shifter.Character
	local TitanTeeth = TitanModel:FindFirstChild("TitanHead")
		and TitanModel.TitanHead:FindFirstChild("Teeth") :: BasePart
	if TitanTeeth then
		local BiteSound = TitanTeeth:FindFirstChild("Bite") :: Sound
		if BiteSound then
			BiteSound:Play()
		end
	end
	VFX.AddAura(TitanSteamAura, TitanModel, "JawDash" .. shifter.UserId)
	VFX.AddTrail(TitanTrail, TitanModel, "JawTrail")
	task.wait(0.1)
	VFX.RemoveAura("JawDash" .. shifter.UserId)
	VFX.RemoveTrail("JawTrail")
end

function Titan.onArmHit(shifter: Player, Position: "right" | "left")
	Log:print("init arm hit")
	local DisableAttribute = "ArmDisabled_" .. Position
	if player == shifter then
		character:SetAttribute(DisableAttribute, true)
	end

	local TitanModel = shifter.Character :: Model
	if not TitanModel then
		Log:warn("No character.")
		return
	end
	local LowerArmRef = (Position == "left" and leftlowerarm)
		or ((Position == "right") and rightlowerarm or nil) :: BasePart
	local UpperArmRef = (
		(Position == "left") and TitanModel:FindFirstChild("LeftUpperArm")
		or ((Position == "right") and TitanModel:FindFirstChild("RightUpperArm"))
		or nil
	) :: BasePart
	local HandRef = (
		(Position == "left")
			and TitanModel:FindFirstChild("LeftHand")
			and TitanModel.LeftHand:FindFirstChild("LeftHand")
		or ((Position == "right") and TitanModel:FindFirstChild("RightHand") and TitanModel.RightHand:FindFirstChild(
			"RightHand"
		))
		or nil
	) :: Model

	if not LowerArmRef or not UpperArmRef or not HandRef then
		Log:warn(
			`Missing [LowerArm][{LowerArmRef}] or [UpperArm][{UpperArmRef}] or [Hand][{HandRef}] from Titan[{TitanModel}].`
		)
		return
	end

	local Hand = PartAyano:TrackInstance(HandRef:Clone()) :: BasePart
	local LowerArm = PartAyano:TrackInstance(LowerArmRef:Clone()) :: BasePart
	local CutArm = UpperArmRef:FindFirstChild("CutArm") :: BasePart
	BasePart.RemoveWelds(LowerArm)
	BasePart.RemoveWelds(Hand)

	LowerArm.CanCollide = false
	LowerArm.CFrame = UpperArmRef.CFrame
	LowerArm.Parent = game.Workspace
	LowerArm.CanCollide = true
	LowerArm.CollisionGroup = "PhasethroughShifterTitans"

	Hand.CanCollide = false
	Hand.CFrame = HandRef.CFrame
	Hand.Parent = game.Workspace
	Hand.CanCollide = true
	Hand.CollisionGroup = "PhasethroughShifterTitans"

	Hand.Massless = false
	Hand.CustomPhysicalProperties = nil

	LowerArm.Massless = false
	LowerArm.CustomPhysicalProperties = nil

	UpperArmRef.CanCollide = false
	LowerArmRef.Transparency = 1
	UpperArmRef.Transparency = 1
	HandRef.Transparency = 1
	CutArm.Transparency = 0

	Ayano:TrackThread(task.delay(1, function()
		BasePart.Fade({ Hand, LowerArm }, TitanConfig.Custom.TitanFadeOutTweenInfo, 1, function()
			local AURA_TAG = "SteamGrowIn_" .. Position
			PartAyano:CleanInstances()
			VFX.AddAura(TitanSteamAura, { LowerArmRef, UpperArmRef, Hand }, AURA_TAG, TitanConfig.Custom.AuraTweenInfo)
			BasePart.Fade({ HandRef, LowerArmRef }, TitanConfig.Custom.TitanFadeOutTweenInfo, 0, function()
				CutArm.Transparency = 1
				UpperArmRef.Transparency = 0
				VFX.RemoveAura(AURA_TAG)
				character:SetAttribute(DisableAttribute, false)
			end)
		end)
	end))
end

function Titan.onNapeEject(shifter: Player)
	Log:print("Replicating NapeEject")
	local shifterCharacter = shifter.Character or shifter.CharacterAdded:Wait()
	if player == shifter then
		Log:print("Setting camera to new character")
		local _humanoid = shifterCharacter:WaitForChild("Humanoid", 10) :: Humanoid
		Reference.Client.Camera.CameraSubject = _humanoid
	end
end

function Titan._updateRoarKnockback()
	character = player.Character
	if not character then
		return
	end
	local CurrentRoaringTitans = Titan._effectList.Roar
	for titancharacter: Model, _ in pairs(CurrentRoaringTitans) do
		if titancharacter == character then
			continue
		end
		local LowerTorso = titancharacter:FindFirstChild("LowerTorso") :: BasePart
		if LowerTorso then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
			if not rootPart then
				return
			end
			local Distance = (rootPart.Position - LowerTorso.Position).Magnitude
			if Distance >= TitanConfig.Custom.Combat.Roar.Range then
				return
			end
			local Direction = (rootPart.Position - LowerTorso.Position).Unit
			local ModifiedForceDirection = Vector3.new(Direction.Unit.X, 0.8, Direction.Unit.Z)
			rootPart.AssemblyLinearVelocity = ModifiedForceDirection * TitanConfig.Custom.Combat.Roar.ForceMagnitude
		end
	end
end

function Titan.onRoar(shifter: Player, isDone: boolean)
	local shifterCharacter = shifter.Character
	if not shifterCharacter then
		return
	end
	local RoarAttachment = shifterCharacter:FindFirstChild("TitanHead")
		and shifterCharacter.TitanHead:FindFirstChild("Teeth")
		and shifterCharacter.TitanHead.Teeth:FindFirstChild("Roar")
	local BottomRoarAttachment = shifterCharacter:FindFirstChild("HumanoidRootPart")
		and shifterCharacter.HumanoidRootPart:FindFirstChild("Upper Bottom") :: Attachment
	if isDone then
		if RoarAttachment then
			VFX.SetParticle(RoarAttachment, false)
		end
		if BottomRoarAttachment then
			VFX.SetParticle(BottomRoarAttachment, false)
		end
		Titan._effectList.Roar[shifterCharacter] = nil
		Ayano:Clean("Roar")
	else
		TitanSFX.Roar:Stop()
		TitanSFX.Roar:Play()
		if RoarAttachment then
			VFX.SetParticle(RoarAttachment, true)
		end
		if BottomRoarAttachment then
			VFX.SetParticle(BottomRoarAttachment, true)
		end
		Titan._effectList.Roar[shifterCharacter] = true
		Ayano:TrackThread(
			task.delay(10, function()
				Titan._effectList.Roar[shifterCharacter] = nil
			end),
			"Roar"
		)
	end
end

function Titan.onEyeHit(direction: "Left" | "Right")
	if direction == "Left" then
		Property.SetTable(Eyegui.LeftEye, { BackgroundTransparency = 0 }, TitanConfig.Custom.BlindTweenInfo)
		Ayano:TrackThread(task.delay(TitanConfig.Custom.BlindDuration, function()
			Property.SetTable(Eyegui.LeftEye, { BackgroundTransparency = 1 }, TitanConfig.Custom.BlindTweenInfo)
		end))
	elseif direction == "Right" then
		Property.SetTable(Eyegui.RightEye, { BackgroundTransparency = 0 }, TitanConfig.Custom.BlindTweenInfo)
		Ayano:TrackThread(task.delay(TitanConfig.Custom.BlindDuration, function()
			Property.SetTable(Eyegui.RightEye, { BackgroundTransparency = 1 }, TitanConfig.Custom.BlindTweenInfo)
		end))
	end
end

function Titan.onReplicationRequest(titanName: string, action: string, shifter: Player, ...)
	if titanName ~= "Jaw" then
		return
	end
	if action == "Roar" then
		Titan.onRoar(shifter, ...)
	end
	if action == "NapeEject" then
		Titan.onNapeEject(shifter)
	end
	if action == "ArmHit" then
		Titan.onArmHit(shifter, ...)
	end
	if action == "BiteVFX" then
		Titan.onBiteVFX(shifter)
	end
	if action == "Landed" then
		Titan.onLanded(shifter)
	end
	if action == "LightHit" then
		Titan.onHit(shifter, ...)
	end
	if action == "EyeHit" then
		Titan.onEyeHit(...)
	end
	if action == "RightStomp" then
		Titan.onRightStomp(shifter)
	end
	if action == "LeftStomp" then
		Titan.onLeftStomp(shifter)
	end
end

function Titan._activateReplicator()
	Satellite.ListenTo("ReplicateTitanVFX"):Connect(Titan.onReplicationRequest)
	RunService.Heartbeat:Connect(Titan._updateRoarKnockback)
end

--~~[[ Eye ]]~~--
local function getEyeFrame(direction: "Left" | "Right")
	local Frame = Instance.new("Frame")
	Frame.AnchorPoint = Vector2.new(0, 0.5)
	Frame.Size = UDim2.fromScale(0.5, 1)
	Frame.Position = UDim2.fromScale(direction == "Left" and 0 or 0.5, 0.5)
	return Frame
end

function Titan._createEyeGui()
	EyeAyano:Clean()
	Eyegui = EyeAyano:TrackInstance(Instance.new("ScreenGui"))
	Eyegui.IgnoreGuiInset = true
	Eyegui.Parent = Reference.Client.PlayerGui
	local RightEye = EyeAyano:TrackInstance(getEyeFrame("Right"))
	local LeftEye = EyeAyano:TrackInstance(getEyeFrame("Left"))
	RightEye.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	LeftEye.BackgroundColor3 = RightEye.BackgroundColor3
	LeftEye.BackgroundTransparency = 1
	RightEye.BackgroundTransparency = 1
	RightEye.Name = "RightEye"
	LeftEye.Name = "LeftEye"
	RightEye.Parent = Eyegui
	LeftEye.Parent = Eyegui
end

function Titan._setupGrabBehaviour(_character: Model)
	warn(_character)
	local _humanoid = _character:FindFirstChildOfClass("Humanoid") or _character:WaitForChild("Humanoid", 5)
	local _animator = _humanoid:FindFirstChildOfClass("Animator")
	warn(_animator)
	if animator then
		local grabbedTrack = _animator:LoadAnimation(Anim.new(18746713677))
		GrabTrackerAyano:Clean()
		GrabTrackerAyano:Connect(RunService.Heartbeat, function()
			if character:GetAttribute("ShifterGrabbed") and not grabbedTrack.IsPlaying then
				grabbedTrack:Play()
			end
			if not character:GetAttribute("ShifterGrabbed") and grabbedTrack.IsPlaying then
				grabbedTrack:Stop()
			end
		end)
	end
end

function Titan._setupGrabReplicator()
	Titan._setupGrabBehaviour(character)
	player.CharacterAdded:Connect(Titan._setupGrabBehaviour)
end

--~~[[ General ]]~~--
function Titan.ActivateCustom()
	Log:printheader("Initiating Custom Controller")
	Titan._createEyeGui()
	Titan._createMiscAnimations()
	Titan._createCombatAnimations()
	Titan._activateCombatController()
	Titan._activateMiscAnimator()
	Titan._activateClimber()
	Titan._activateNapeSystem()
	Titan._activateGroundChecker()
	Titan._activateJumpChecker()
	Titan._setupMovementSFX()
end

return Titan
