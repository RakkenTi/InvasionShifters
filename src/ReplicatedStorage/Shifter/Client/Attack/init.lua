--[[

@rakken
Titan: Attack Titan
Notes;
WTF

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
local CameraShake = Utils.camerashake

--// Module-Constants
local OriginalTitanConfig = Utils.table.DeepCopy(TitanConfig) :: typeof(TitanConfig)
local Ayano = Utils.ayano.new()
local Ayano2 = Utils.ayano.new()
local Log = Utils.log.new("[Attack Client]")
local ColorCorrectionData = TitanConfig.Default.ColorCorrectionData
local selfRaycastParams = RaycastParams.new()
selfRaycastParams.FilterDescendantsInstances = { Reference.Client.Player.Character }

--// Constants
local ShifterAssets = AssetConfig.ShifterAssets :: Folder
local ShifterVFX = ShifterAssets.VFX :: Folder
local ShifterLightningAura = ShifterVFX.Auras.SmallLightning:GetChildren() :: { ParticleEmitter }
local TitanSteamAura = ShifterVFX.Auras.Steam:GetChildren() :: { ParticleEmitter }
local BeserkAura = ShifterVFX.Auras.Beserk:GetChildren() :: { ParticleEmitter }
local BeserkHighlight = ShifterVFX.Highlights.Beserk :: Highlight
local ShifterTransformationParticles = ShifterVFX.Transformations.UniversalShiftModified2 :: Model
local SwordModel = ShifterAssets.Models.Sword :: Model
local player = Reference.Client.Player
local character = player.Character
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootpart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator
local lefthand = nil :: BasePart?
local righthand = nil :: BasePart?
local leftfoot = nil :: BasePart?
local rightfoot = nil :: BasePart?
local ikcontrol = nil :: IKControl?
local head = nil :: BasePart?
local Camera = game.Workspace.CurrentCamera
local IKPart = nil :: BasePart?
local canCleanup = false :: boolean
local BasicHitVFX = ShifterVFX.Hit.BasicHit :: BasePart
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
		canRun = true,
		canRoar = true,
		canHeavy = true,
		canBeserk = true,
		isStunned = false,
		isIKEnabled = true,
		isBlocking = false,
		isOnGround = false,
		isAttacking = false,
		isRunning = false,
		isSHeld = false,
		isWHeld = false,
		isLMBHeld = false,
		isBeserk = false,
	},
}

--// Variables
local TitanSFX = {} :: { [any]: Sound }
local TitanSpecialSFX = {} :: { [any]: Sound }
local TitanAnimations = {} :: Types.DefaultAnimationTracks
local TitanGrabAnimations = {} :: { [any]: AnimationTrack }
local TitanLMBAnimations = {} :: { [any]: AnimationTrack }
local TitanStunAnimations = {} :: { AnimationTrack }

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
	Log:printheader("Cleaning Connections")
	repeat
		Log:print("Clean queue active. Waiting for permission to cleanup..")
		task.wait()
	until canCleanup or override
	canCleanup = false
	Ayano:Clean()
	Ayano2:Clean()
	table.clear(TitanData)
	table.clear(TitanAnimations)
	table.clear(TitanLMBAnimations)
	table.clear(TitanGrabAnimations)
	table.clear(TitanStunAnimations)
	Log:warn("Successfully cleaned up.")
end

local function UpdateCharacterData()
	character = player.Character or player.CharacterAdded:Wait()
	rootpart = character:WaitForChild("HumanoidRootPart")
	righthand = character:WaitForChild("RightHand")
	lefthand = character:WaitForChild("LeftHand")
	rightfoot = character:WaitForChild("RightFoot")
	leftfoot = character:WaitForChild("LeftFoot")
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	head = character:WaitForChild("Head")
	ikcontrol = humanoid:WaitForChild("IKControl")
	IKPart = character:WaitForChild("IKPart")
	selfRaycastParams.FilterDescendantsInstances = { character }
	Ayano2:Connect(humanoid.HealthChanged, function()
		if humanoid.Health <= 0 then
			Log:warn("Warhammer titan died. Cleaning up.")
			Titan._NapeEject(true)
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
	Log:print("Initializing Titan Data")
	table.clear(TitanData)
	table.clear(TitanAnimations)
	character:SetAttribute("Health", humanoid.Health)
	TitanData = Table.DeepCopy(DefaultTitanData)
end

function Titan._initHumanoidStates()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
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
	TitanAnimations.Block.Priority = Enum.AnimationPriority.Action2
	TitanAnimations.Roar.Priority = Enum.AnimationPriority.Action3
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
	if
		TitanData.Stats.Stamina < TitanConfig.Default.Stats.Stamina.MinimumThreshold
		or TitanData.States.napeEject
		or TitanData.States.isAttacking
		or TitanData.States.isBlocking
	then
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

--~~[[ Movement VFX/SFX ]]~~--
--~~/// [[ Misc ]] ///~~--
function Titan._onRightStomp()
	if not TitanData.States.isOnGround and not TitanData.States.isClimbing then
		return
	end
	Satellite.Send("TitanAction", "RightStomp")
	Titan.onRightStomp(player)
end

function Titan._onLeftStomp()
	if not TitanData.States.isOnGround and not TitanData.States.isClimbing then
		return
	end
	Satellite.Send("TitanAction", "LeftStomp")
	Titan.onLeftStomp(player)
end

function Titan._setupMovementEffects()
	local WalkTrack = TitanAnimations.Walk
	local RunTrack = TitanAnimations.Run
	Ayano:Connect(WalkTrack:GetMarkerReachedSignal("RightStomp"), Titan._onRightStomp)
	Ayano:Connect(RunTrack:GetMarkerReachedSignal("RightStomp"), Titan._onRightStomp)
	Ayano:Connect(WalkTrack:GetMarkerReachedSignal("LeftStomp"), Titan._onLeftStomp)
	Ayano:Connect(RunTrack:GetMarkerReachedSignal("LeftStomp"), Titan._onLeftStomp)
end

--~~[[ Stamina ]]~~--
function Titan._consumeStaminna(amount: number)
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
			Ayano2:Connect(humanoid.HealthChanged, function()
				if humanoid.Health <= 0 then
					Log:print("Cleaning up Stamina Gui")
					Titan._disableIK()
					connection:Disconnect()
					StaminaGui.Enabled = false
				end
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

function Titan._Landed()
	Satellite.Send("TitanAction", "Landed")
end

--~~[[ State Handler ]]~~--
function Titan._handleFreefall()
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall and not TitanAnimations.Freefall.IsPlaying then
		TitanAnimations.Freefall:Play()
	elseif humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and TitanAnimations.Freefall.IsPlaying then
		TitanAnimations.Freefall:Stop()
	end
end

function Titan._activateGroundChecker()
	Ayano:Connect(RunService.Heartbeat, function()
		Titan._handleFreefall()
		local raycast = game.Workspace:Raycast(rootpart.Position, Vector3.new(0, -70, 0), selfRaycastParams)
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

--~~[[ General ]]~~--
function Titan._setCamera()
	Reference.Client.Camera.CameraSubject = humanoid
end

--~~[[ Stuns ]]~~--
function Titan._onHealthChanged()
	local OldHealth = character:GetAttribute("Health")
	local NewHealth = humanoid.Health
	if OldHealth > NewHealth and TitanData.States.isStunned then
		local StunAnim = TitanStunAnimations[math.random(1, #TitanStunAnimations)]
		StunAnim:Play()
	end
	character:SetAttribute("Health", NewHealth)
end

function Titan._activateStunReplicator()
	Ayano:Connect(humanoid:GetPropertyChangedSignal("Health"), Titan._onHealthChanged)
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
	Titan._setupMovementEffects()
	Titan._initDefaultMovementController()
	Titan._activateStaminaSystem()
	Titan._activateGroundChecker()
	Titan._activateStunReplicator()
	Titan._activateNapeSystem()
	Titan.ActivateCustom()
	Log:printheader("Titan Activated.")
end

--~~[[ Ran once by client on player join. ]]~~--
function Titan.Start()
	Titan._createTitanSFX()
	Titan._activateGenericReplicator()
end

function Titan.PlayTransformationCutscene() end

--~~/// [[ Transform Replicator ]] ///~~--

function Titan.CreateTransformationVFX(shifter: Player)
	Log:print("Replicating Transformation VFX")
	local TransformAyano = Utils.ayano.new()
	if shifter == player then
		local _character = player.Character
		local _humanoid = _character and _character:FindFirstChildOfClass("Humanoid")
		if _humanoid then
			local _animator = _humanoid:FindFirstChildOfClass("Animator")
			if _animator then
				local animation =
					_animator:LoadAnimation(Ayano:TrackInstance(Anim.new(TitanConfig.Default.DefaultAnimations.Shift)))
				animation:Play()
				animation.Stopped:Once(function()
					animation:Play()
					animation:AdjustSpeed(0)
					animation.TimePosition = animation.Length - 0.05
				end)
			end
		end
	end
	local Sword = TransformAyano:TrackInstance(SwordModel:Clone()) :: Model
	local TransformationParticles = TransformAyano:TrackInstance(ShifterTransformationParticles:Clone()) :: BasePart
	local SwordWeld = TransformAyano:TrackInstance(Instance.new("Weld")) :: Weld
	local StraightSparks = TransformationParticles.Main.Part.Main.StraightSparks :: ParticleEmitter
	local LittleShootStuff = TransformationParticles.Main.Part.Main.LittleShootStuff :: ParticleEmitter
	local BottomAttachment = TransformationParticles.Bottom :: Attachment
	local TopAttachment = TransformationParticles.Top :: Attachment
	local TransformationID = HttpService:GenerateGUID()
	local SteamID = HttpService:GenerateGUID()
	local TemporaryColorCorrection = Instance.new("ColorCorrectionEffect")
	local FlashColorCorrection = TransformAyano:TrackInstance(Instance.new("ColorCorrectionEffect"))
	local shifterCharacter = shifter.Character
	local playerRightArm = shifterCharacter:WaitForChild("Right Arm", 5)
	local srootpart = shifterCharacter:WaitForChild("HumanoidRootPart", 5) :: BasePart
	if srootpart then
		srootpart.Anchored = true
	end

	--~~[[ Setup ]]~~--
	SwordWeld.C0 = CFrame.new(0, -1, 0)
	SwordWeld.Part0 = playerRightArm
	SwordWeld.Part1 = Sword.PrimaryPart
	SwordWeld.Parent = Sword.PrimaryPart
	Sword.Parent = shifterCharacter
	VFX.SetParticle(TransformationParticles, false)
	task.wait(1.25)

	--~~/// [[ Begin Sequence ]] ///~~--
	--~~[[ Add Aura ]]~~--
	TemporaryColorCorrection.Parent = Lighting
	FlashColorCorrection.Parent = Lighting
	Property.SetTable(
		TemporaryColorCorrection,
		ColorCorrectionData.OnTransformation,
		TitanConfig.Custom.ColorCorrectionTweenInfo
	)
	VFX.AddAura(ShifterLightningAura, shifterCharacter, TransformationID, TitanConfig.Custom.AuraTweenInfo)
	TitanSFX.Sparks:Play()
	task.wait(2.7)
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
	local hasTweened = false
	connection = Ayano:Connect(RunService.RenderStepped, function(delta: number)
		alpha = math.clamp(alpha + delta, 0.01, 1)
		local talpha = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		-- Update Shifter Character because the server might change it to the titan model.
		shifterCharacter = shifter.Character
		TransformationParticles.Main:ScaleTo(talpha)
		if shifterCharacter:HasTag("isTitan") and not hasTweened then
			hasTweened = true
			local Descendants = shifterCharacter:GetDescendants()
			for _, v in Descendants do
				if v:IsA("BasePart") then
					local oSize = v.Size
					v.Size = Vector3.zero
					v:SetAttribute("oSize", oSize)
				end
			end
			for _, v in Descendants do
				if v:IsA("BasePart") then
					local oSize = v:GetAttribute("oSize")
					local tween = TweenService:Create(v, TitanConfig.Custom.TitanGrowTweenInfo, { Size = oSize })
					tween:Play()
					task.wait(0.04)
				end
			end
		end
		if shifter ~= player then
			local playerChar = player.Character
			local prp = playerChar and playerChar.PrimaryPart
			local phrp = playerChar:FindFirstChild("HumanoidRootPart") :: BasePart
			local playerHum = playerChar:FindFirstChildOfClass("Humanoid") :: Humanoid
			if srootpart and prp and playerHum then
				local DifferenceVector = (prp.Position - srootpart.Position)
				local Velocity = Vector3.new(DifferenceVector.Unit.X, 0.8, DifferenceVector.Unit.Z)
					* TitanConfig.Default.Transformation.KnockbackMagnitude
				local Distance = (srootpart.Position - prp.Position).Magnitude
				local MinimumDistance = TitanConfig.Default.Transformation.Radius
				if Distance <= MinimumDistance then
					local MaxDamage = TitanConfig.Default.Transformation.TickDamage
					local AlphaDistance = 1 - (Distance / MinimumDistance)
					local DamageApplied = MaxDamage * AlphaDistance
					warn(DamageApplied)
					phrp.AssemblyLinearVelocity = Velocity
					playerHum:TakeDamage(DamageApplied)
				end
			end
		end
	end)
	BottomAttachment.Position = TopAttachment.Position
	TransformationParticles.Parent = game.Workspace
	VFX.SetParticle(TransformationParticles.Beam, true)
	TweenService:Create(BottomAttachment, TitanConfig.Custom.TransformBeamTweenInfo, { Position = Vector3.zero }):Play()
	--~~[[ Flash ]]~~--
	Property.SetTable(FlashColorCorrection, ColorCorrectionData.Flash, TitanConfig.Custom.FlashColorCorrectionTweenInfo)
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
	Property.SetTable(
		FlashColorCorrection,
		ColorCorrectionData.Default,
		TitanConfig.Custom.ColorCorrectionTweenInfo,
		function()
			TemporaryColorCorrection:Destroy()
		end
	)
	task.wait(6)
	VFX.RemoveAura(SteamID)
	TransformAyano:Clean()
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

function Titan.onLanded(shifter: Player)
	local shifterCharacter = shifter.Character
	if not shifterCharacter then
		return
	end
	local _rightfoot = shifterCharacter:WaitForChild("RightFoot", 15)
	local _leftfoot = shifterCharacter:WaitForChild("LeftFoot", 15)
	local Filter = { shifterCharacter }
	TitanSpecialSFX.Land:Play()
	Rubble.Crater.Create(CFrame.new(_rightfoot.Position), Rubble.Presets.Crater.Large, Filter, ConfigCrater)
	Rubble.Explosion.Create(CFrame.new(_rightfoot.Position), Rubble.Presets.Explosion.Medium, Filter, ConfigCrater)
	Rubble.Crater.Create(CFrame.new(_leftfoot.Position), Rubble.Presets.Crater.Large, Filter, ConfigCrater)
	Rubble.Explosion.Create(CFrame.new(_leftfoot.Position), Rubble.Presets.Explosion.Medium, Filter, ConfigCrater)
end

--~~[[ Hit ]]~~--
function Titan.onHit(shifter: Player, AttackIndex: number, cancelHit: boolean)
	local TitanCharacter = shifter.Character
	-- Right Hand
	if AttackIndex == 1 or AttackIndex == 3 then
		local RightHand = TitanCharacter:FindFirstChild("RightHand")
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
	if AttackIndex == 2 then
		local LeftHand = TitanCharacter:FindFirstChild("LeftHand")
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
	if cancelHit then
		return
	end
	TitanSFX.Hit:Play()
end

--~~[[ Stomps ]]~~--
function Titan.onRightStomp(shifter: Player)
	local shiftercharacter = shifter.Character

	local RightFoot = shiftercharacter:FindFirstChild("RightFoot") or shiftercharacter:WaitForChild("RightFoot", 5)
	local SoundFX = RightFoot.Walk:FindFirstChildOfClass("Sound")
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
	local SoundFX = LeftFoot.Walk:FindFirstChildOfClass("Sound")
	if SoundFX then
		SoundFX:Play()
	end
	if not LeftFoot then
		Log:warn("Could not setup movement sfx for left foot. LeftFoot missing.")
		return
	end
	VFX.EmitParticle(LeftFoot)
end

--~~[[ Roar ]]~~--
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

function Titan.onRoar(shifter: Player, isDone: boolean, beserkAlt: boolean)
	local shifterCharacter = shifter.Character
	local RoarAttachment = shifterCharacter:FindFirstChild("Teeth") and shifterCharacter.Teeth:FindFirstChild("Roar")
	local BottomRoarAttachment = shifterCharacter:FindFirstChild("HumanoidRootPart")
		and shifterCharacter.HumanoidRootPart:FindFirstChild("Upper Bottom") :: Attachment
	if beserkAlt then
		RoarAttachment = shifterCharacter:FindFirstChild("Teeth")
			and shifterCharacter.Teeth:FindFirstChild("BeserkRoar")
	end
	if isDone then
		if RoarAttachment then
			VFX.SetParticle(RoarAttachment, false)
		end
		if BottomRoarAttachment then
			VFX.SetParticle(BottomRoarAttachment, false)
		end
		Titan._effectList.Roar[shifterCharacter] = nil
		Ayano:Clean("Roar")
		return
	end
	local RoarShake = CameraShake.StartSustainedPreset("Vibration")
	if not beserkAlt then
		TitanSFX.Roar:Stop()
		TitanSFX.Roar:Play()
		Titan._effectList.Roar[shifterCharacter] = true
		Ayano:TrackThread(
			task.delay(10, function()
				Titan._effectList.Roar[shifterCharacter] = nil
			end),
			"Roar"
		)
	end
	task.delay(4, function()
		RoarShake:StartFadeOut(1)
	end)
	if RoarAttachment then
		VFX.SetParticle(RoarAttachment, true)
	end
	if BottomRoarAttachment then
		VFX.SetParticle(BottomRoarAttachment, true)
	end
end

function Titan.onBeserk(shifter: Player)
	local TitanCharacter = shifter.Character
	local BeserkID = HttpService:GenerateGUID()
	Titan.onRoar(shifter, false, true)
	TitanSFX.BeserkRoar:Play()
	local BeserkRoarShake = CameraShake.StartSustainedPreset("Explosion")
	task.delay(5, function()
		BeserkRoarShake:StartFadeOut(1)
		Titan.onRoar(shifter, true, true)
	end)
	if TitanCharacter then
		local highlight = BeserkHighlight:Clone()
		highlight.Enabled = true
		highlight.Parent = TitanCharacter
		VFX.AddAura(BeserkAura, TitanCharacter, BeserkID, TitanConfig.Custom.AuraTweenInfo)
		task.wait(TitanConfig.Custom.Combat.Beserk.Duration)
		VFX.RemoveAura(BeserkID)
		highlight:Destroy()
	end
end

function Titan._onReplicationRequest(titanName: string, action: string, shifter: Player, ...)
	if titanName ~= "Attack" then
		return
	end
	if action == "Landed" then
		Titan.onLanded(shifter)
	end
	if action == "Roar" then
		Titan.onRoar(shifter, ...)
	end
	if action == "RightStomp" then
		Titan.onRightStomp(shifter)
	end
	if action == "LeftStomp" then
		Titan.onLeftStomp(shifter)
	end
	if action == "TitanHit" then
		Titan.onHit(shifter, ...)
	end
	if action == "Beserk" then
		Titan.onBeserk(shifter)
	end
end

function Titan._activateGenericReplicator()
	Satellite.ListenTo("ReplicateTitanVFX"):Connect(Titan._onReplicationRequest)
	RunService.Heartbeat:Connect(Titan._updateRoarKnockback)
end

-- This is where the code differs for each titan.
--~~/// [[ Nape System ]] ///~~--
function Titan._NapeEject(dead: boolean?)
	local isOnGround = TitanData.States.isOnGround
	if (TitanData.States.isAttacking or TitanData.States.isRoaring or not isOnGround) and not dead then
		return
	end
	Titan._disableIK()
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
		Satellite.Send("TitanAction", "NapeEject", dead)
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
end

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
	for _, animationID: number in ipairs(TitanConfig.Custom.GrabSequence) do
		local AnimationTrack = animator:LoadAnimation(Anim.new(animationID))
		AnimationTrack.Priority = Enum.AnimationPriority.Action3
		table.insert(TitanGrabAnimations, AnimationTrack)
	end
	for _, animationID: number in ipairs(TitanConfig.Default.StunAnimations) do
		local AnimationTrack = animator:LoadAnimation(Anim.new(animationID))
		AnimationTrack.Priority = Enum.AnimationPriority.Action4
		table.insert(TitanStunAnimations, AnimationTrack)
	end
end
--~~[[ States ]]~~--
function Titan._onHit(HitCharacters: { [any]: Model })
	if Utils.table.getDictLength(HitCharacters) > 0 then
		Satellite.Send("TitanAction", "LightHit", HitCharacters, TitanData.Stats.AttackIndex)
	end
end
--~~[[ Heavy Attack ]]~~--
function Titan._onHeavyHit(HitCharacters: { Model })
	print(HitCharacters)
	if Utils.table.getDictLength(HitCharacters) > 0 then
		Satellite.Send("TitanAction", "HeavyHit", HitCharacters)
	end
end

function Titan._Heavy()
	if
		not TitanData.States.canHeavy
		or TitanData.Stats.Stamina < TitanConfig.Custom.Combat.Heavy.StaminaCost
		or TitanData.States.isAttacking
		or TitanData.States.isBlocking
		or TitanData.States.isRoaring
		or TitanData.States.isStunned
	then
		return
	end
	if righthand:FindFirstChild("GrabWeld") then
		return
	end
	TitanData.States.isAttacking = true
	--~~[[ Cost ]]~~--
	TitanData.States.canHeavy = false
	Ayano:TrackThread(task.delay(TitanConfig.Custom.Combat.Heavy.Cooldown, function()
		TitanData.States.canHeavy = true
	end))
	Titan._consumeStaminna(TitanConfig.Custom.Combat.Heavy.StaminaCost)
	--~~[[ Main ]]~~--
	TitanAnimations.Heavy:Play()
	if TitanData.States.isBeserk then
		TitanAnimations.Heavy:AdjustSpeed(TitanConfig.Custom.Combat.Beserk.AttackSpeedMultiplier)
	end
	TitanSpecialSFX.Swing:Play()
	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.Heavy.Hitbox.Size, nil, { player }))
	Hitbox:SetContinous(true)
	Hitbox:Bind(righthand, TitanConfig.Custom.Combat.Heavy.Hitbox.Vector3Offset)
	Hitbox:SetVisibility(true)
	Hitbox:SetCallback(Titan._onHeavyHit)
	Hitbox:SetLiveCallback(Titan._onHeavyLiveHit)
	Hitbox:Start()
	TitanAnimations.Heavy.Stopped:Once(function()
		TitanData.States.isAttacking = false
		Hitbox:Destroy()
	end)
end

--~~[[ Roar ]]~~--
function Titan._Roar()
	--~~[[ Checks ]]~~--
	if
		TitanData.States.isAttacking
		or not TitanData.States.canRoar
		or TitanData.States.isClimbing
		or (TitanAnimations.Roar :: AnimationTrack).IsPlaying
		or TitanData.States.isBlocking
		or TitanData.States.isStunned
	then
		return
	end
	--~~[[ Roar ]]~~--
	task.delay(TitanConfig.Custom.Combat.Roar.Cooldown, function()
		TitanData.States.canRoar = true
	end)
	TitanData.States.canRoar = false
	TitanData.States.isRoaring = true
	TitanAnimations.Roar:Play()
	TitanAnimations.Roar.Stopped:Once(function()
		TitanData.States.isRoaring = false
		Titan._endRun()
	end)
	Titan._addStamina(TitanConfig.Custom.Combat.Roar.StaminaAdd)
	Satellite.Send("TitanAction", "Roar")
end

--~~[[ Light Attack ]]~~--
function Titan._LMB()
	--~~[[ Checks ]]~~--
	local isAttacking = TitanData.States.isAttacking
	local AttackIndex = TitanData.Stats.AttackIndex
	local RightIndex = 1
	local RightIndex2 = 3
	local LeftIndex = 2
	if isAttacking or TitanData.States.isBlocking or TitanData.States.isRoaring or TitanData.States.isStunned then
		return
	end
	local Hand = (AttackIndex == RightIndex or AttackIndex == RightIndex2) and righthand or lefthand
	if Hand:FindFirstChild("GrabWeld") then
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
	if TitanData.States.isBeserk then
		CurrentAnimation:AdjustSpeed(TitanConfig.Custom.Combat.Beserk.AttackSpeedMultiplier)
	end
	TitanSpecialSFX.Swing:Play()
	--~~[[ Hitbox ]]~~--
	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.LMB.Hitbox.Size, nil, { player }))
	if
		(character:GetAttribute("ArmDisabled_right") and (RightIndex == AttackIndex or AttackIndex == RightIndex2))
		or (character:GetAttribute("ArmDisabled_left") and LeftIndex == AttackIndex)
	then
		task.wait(1)
		NextLMBState(Hitbox, AttackIndex)
		return
	end
	Hitbox:Bind(Hand, TitanConfig.Custom.Combat.LMB.Hitbox.Vector3Offset)
	Hitbox:SetContinous(true)
	Hitbox:SetVisibility(true)
	Hitbox:Start()
	Hitbox:SetCallback(Titan._onHit)
	Hitbox:SetLiveCallback(Titan._onLiveHit)
	--~~[[ Animation ]]~~--
	CurrentAnimation.Stopped:Once(function()
		TitanData.States.isAttacking = false
		NextLMBState(Hitbox, AttackIndex)
	end)
end

function Titan._onLiveHit(HitCharacter: Model)
	if HitCharacter:HasTag("isTitan") then
		local cancelSound = false
		if HitCharacter:GetAttribute("isBlocking") then
			cancelSound = true
		end
		Satellite.Send("TitanAction", "TitanHit", TitanData.Stats.AttackIndex, cancelSound)
	end
end

function Titan._onHeavyLiveHit(HitCharacter: Model)
	if HitCharacter:HasTag("isTitan") then
		Satellite.Send("TitanAction", "TitanHit", 1)
	end
end

--~~[[ Block ]]~~--
function Titan._HandleBlock()
	if TitanData.States.isBlocking then
		if TitanData.Stats.Stamina < TitanConfig.Custom.Combat.Block.MinimumStaminaRequired then
			Titan._Block(false)
			return
		end
		Titan._consumeStaminna(TitanConfig.Custom.Combat.Block.StaminaConsumption)
		if not TitanAnimations.Block.IsPlaying then
			TitanAnimations.Block:Play()
		end
	elseif not TitanData.States.isBlocking then
		TitanAnimations.Block:Stop()
	end
end

function Titan._Block(state: boolean)
	if TitanData.States.isAttacking and state then
		return
	end
	TitanData.States.isBlocking = state
	Satellite.Send("TitanAction", "Block", state)
end

--~~[[ Combat State Handling ]]~~--
function Titan._HandleStates()
	TitanData.States.isStunned = character:GetAttribute("Stunned")
	if TitanData.States.isStunned then
		humanoid.WalkSpeed = TitanConfig.Default.Stats.Humanoid.StunnedSpeed
	end
	if TitanData.States.isRoaring then
		humanoid.WalkSpeed = 0
	elseif not TitanData.States.isRoaring and humanoid.WalkSpeed == 0 then
		Titan._endRun() -- Start walk
	end
	if TitanData.States.isAttacking or TitanData.States.isBlocking and TitanData.States.isRunning then
		Titan._endRun()
	end
end

--~~[[ Combat Update Handling ]]~~--
function Titan._activateCombatUpdater()
	Ayano:Connect(RunService.Heartbeat, Titan._HandleBlock)
	Ayano:Connect(RunService.Heartbeat, Titan._HandleStates)
	Ayano:Connect(RunService.Heartbeat, Titan._HandleBeserk)
end

--~~[[ Beserk ]]~~--
function Titan._HandleBeserk()
	if TitanAnimations.Special.IsPlaying then
		humanoid.WalkSpeed = 0
	end
	if TitanData.States.isBeserk then
		TitanConfig.Default.Stats.Humanoid.RunSpeed = OriginalTitanConfig.Default.Stats.Humanoid.RunSpeed * 2
		TitanConfig.Default.Stats.Humanoid.WalkSpeed = OriginalTitanConfig.Default.Stats.Humanoid.WalkSpeed * 2
	else
		TitanConfig.Default.Stats.Humanoid.RunSpeed = OriginalTitanConfig.Default.Stats.Humanoid.RunSpeed
		TitanConfig.Default.Stats.Humanoid.WalkSpeed = OriginalTitanConfig.Default.Stats.Humanoid.WalkSpeed
	end
end

function Titan._Beserk()
	local CurrentStamina = TitanData.Stats.Stamina
	local StaminaCost = TitanConfig.Custom.Combat.Beserk.StaminaCost
	if
		CurrentStamina < StaminaCost
		or not TitanData.States.canBeserk
		or TitanData.States.isAttacking
		or TitanData.States.isBlocking
		or TitanData.States.isRoaring
	then
		return
	end
	TitanData.States.isRoaring = true
	Log:warn("Beserk mode starting")
	TitanData.States.canBeserk = false
	Titan._consumeStaminna(StaminaCost)
	TitanAnimations.Special:Play()
	TitanAnimations.Special.Stopped:Once(function()
		TitanData.States.isRoaring = false
		Titan._endRun()
	end)
	TitanData.States.isBeserk = true
	Satellite.Send("TitanAction", "Beserk")
	Ayano:TrackThread(task.delay(TitanConfig.Custom.Combat.Beserk.Duration, function()
		Log:warn("Beserk mode ended")
		TitanData.States.isBeserk = false
		task.wait(TitanConfig.Custom.Combat.Beserk.Cooldown)
		TitanData.States.canBeserk = true
	end))
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
				if TitanData.States.mode == "Attack" then
					Titan._LMB()
				end
			end
		end
		if input.KeyCode == Enum.KeyCode.E then
			if TitanData.States.mode == "Attack" then
				Titan._Heavy()
			end
		end
		if input.KeyCode == Enum.KeyCode.R then
			Titan._Roar()
		end
		if input.KeyCode == Enum.KeyCode.F then
			Titan._Block(true)
		end
		if input.KeyCode == Enum.KeyCode.G then
			Titan._Beserk()
		end
	end)
	Ayano:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TitanData.States.isLMBHeld = false
		end
		if input.KeyCode == Enum.KeyCode.F then
			Titan._Block(false)
		end
	end)
end

--~~[[ Inverse Kinematics [IK] ]]~~--
function Titan._initIKSystem()
	ikcontrol.Target = IKPart
end

function Titan._adjustIKPart()
	if not TitanData.States.isIKEnabled then
		return
	end
	local IKPos = head.Position + Camera.CFrame.LookVector.Unit * 100
	IKPart.Position = IKPos
	Satellite.Send("UnreliableTitanAction", "UpdateIK", ikcontrol, IKPart, IKPos)
end

function Titan._disableIK()
	Log:print("Disabling IK")
	TitanData.States.isIKEnabled = false
	TweenService:Create(ikcontrol, TitanConfig.Custom.IKTweenInfo, { Weight = 0 }):Play()
	Satellite.Send("UnreliableTitanAction", "SetIK", ikcontrol, false)
end

function Titan._enableIK()
	if humanoid.Health <= 0 then
		return
	end
	Log:print("Enabling IK")
	TitanData.States.isIKEnabled = true
	TweenService:Create(ikcontrol, TitanConfig.Custom.IKTweenInfo, { Weight = 1 }):Play()
	Satellite.Send("UnreliableTitanAction", "SetIK", ikcontrol, true)
end

function Titan._updateIKState()
	local DotProduct = Camera.CFrame.LookVector.Unit:Dot(rootpart.CFrame.LookVector.Unit)
	if DotProduct < -0.95 and TitanData.States.isIKEnabled == true then
		Titan._disableIK()
	elseif DotProduct > -0.95 and TitanData.States.isIKEnabled == false then
		Titan._enableIK()
	end
end

function Titan._updateIK()
	Titan._adjustIKPart()
	Titan._updateIKState()
end

function Titan._activateIKController()
	Titan._initIKSystem()
	Ayano:Connect(RunService.Heartbeat, Titan._updateIK)
end

--~~[[ Grab System ]]~~--
function Titan._switchMode()
	if TitanData.States.mode == "Attack" then
		TitanData.States.mode = "Grab"
	else
		TitanData.States.mode = "Attack"
	end
end

function Titan._Grab(direction: "Left" | "Right")
	if
		TitanData.States.mode ~= "Grab"
		or TitanData.States.isAttacking
		or TitanData.States.isBlocking
		or TitanData.States.isRoaring
		or TitanData.States.isStunned
	then
		return
	end
	--~~[[ Checks ]]~~--
	local isAttacking = TitanData.States.isAttacking
	local GrabIndex = direction == "Left" and 1 or 2
	local LeftIndex = 1
	local RightIndex = 2
	local Hand = (GrabIndex == RightIndex) and righthand or lefthand
	if isAttacking then
		return
	end
	if Hand:FindFirstChild("GrabWeld") then
		warn("GrabWeld")
		Satellite.Send("TitanAction", "UnGrab", Hand)
		return
	end
	if
		(character:GetAttribute("ArmDisabled_right") and (RightIndex == GrabIndex))
		or (character:GetAttribute("ArmDisabled_left") and LeftIndex == GrabIndex)
	then
		return
	end
	--~~[[ Pass Checks ]]~~--
	TitanData.States.isAttacking = true
	local CurrentAnimation = TitanGrabAnimations[GrabIndex]
	CurrentAnimation:Play()
	--~~[[ Hitbox ]]~~--

	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.Grab.Hitbox.Size, nil, { player }))
	Hitbox:Bind(Hand, TitanConfig.Custom.Combat.Grab.Hitbox.Vector3Offset)
	Hitbox:SetVisibility(true)
	Hitbox:Start()
	Hitbox:SetCallback(function(hit: Model)
		if hit:HasTag("isTitan") then
			return
		end
		Satellite.Send("TitanAction", "Grab", hit, Hand)
		Hitbox:Destroy()
	end)
	--~~[[ Animation ]]~~--
	CurrentAnimation.Stopped:Once(function()
		TitanData.States.isAttacking = false
		Hitbox:Destroy()
	end)
end

function Titan._activateGrabSystem()
	Ayano:Connect(UserInputService.InputBegan, function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == Enum.KeyCode.Z then
			Titan._switchMode()
		end
		if input.KeyCode == Enum.KeyCode.Q then
			Titan._Grab("Left")
		end
		if input.KeyCode == Enum.KeyCode.E then
			Titan._Grab("Right")
		end
	end)
end

function Titan.ActivateCustom()
	Titan._createCombatAnimations()
	Titan._activateCombatInput()
	Titan._activateCombatUpdater()
	Titan._activateIKController()
	Titan._activateGrabSystem()
end

return Titan
