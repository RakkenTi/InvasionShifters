--[[

@rakken
Titan: Jaw Titan
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
local VFX = Utils.vfx

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
local ShifterLightningAura = ShifterVFX.Auras.Lightning:GetChildren() :: { ParticleEmitter }
local TitanSteamAura = ShifterVFX.Auras.Steam:GetChildren() :: { ParticleEmitter }
local ShifterTransformationParticles = ShifterVFX.Transformations.UniversalShift :: Model
local player = Reference.Client.Player
local character = player.Character
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootpart = character:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator
local head = character:FindFirstChild("Titan Head") and character:FindFirstChild("Titan Head"):WaitForChild("Head")
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
		canRoar = true,
		napeEject = false,
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
local function Cleanup()
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
	character = player.Character
	rootpart = character:WaitForChild("HumanoidRootPart")
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	animator = humanoid:WaitForChild("Animator") :: Animator
	head = character:FindFirstChild("Titan Head") and character:FindFirstChild("Titan Head"):WaitForChild("Head")
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
	table.clear(TitanLightAttackAnimations)
	table.clear(TitanCombatAnimations)
	table.clear(TitanMiscAnimations)
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
	for soundname, soundid: number in pairs(TitanConfig.Custom.ShifterSFX) do
		TitanSFX[soundname] = Sound.new(soundid)
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
	if RunService:IsStudio() then
		Titan._activateGui()
	end
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
end

function Titan.PlayTransformationCutscene() end

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
	connection = Ayano:Connect(RunService.RenderStepped, function()
		-- Update Shifter Character because the server might change it to the titan model.
		shifterCharacter = shifter.Character
		if not shifterCharacter then
			return
		end
		local HumanoidRootPart = shifterCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
		if not HumanoidRootPart then
			return
		end
		TransformationParticles.Position = HumanoidRootPart.Position
	end)
	BottomAttachment.Position = TopAttachment.Position
	TransformationParticles.Parent = game.Workspace
	VFX.SetParticle(TransformationParticles.Beam, true)
	TweenService:Create(BottomAttachment, TitanConfig.Custom.TransformBeamTweenInfo, { Position = Vector3.zero }):Play()
	task.wait(1.25)
	if shifter == player then
		Satellite.Send("TransformationVFXFinished")
	end
	VFX.SetParticle(TransformationParticles, true)
	task.wait(3.5)
	VFX.SetParticle(TransformationParticles, false)
	VFX.SetBeam(TransformationParticles, false)
	VFX.RemoveAura(TransformationID)
	VFX.AddAura(TitanSteamAura, shifterCharacter, SteamID, TitanConfig.Custom.AuraTweenInfo)
	task.wait(2)
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
	humanoid.WalkSpeed = 0
	TitanAnimations.Idle:Stop()
	TitanAnimations.Walk:Play(0.15, 1, 1)
	TitanAnimations.Walk:AdjustSpeed(0)
	Cleanup()
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

function Titan._activateGroundChecker()
	Ayano:Connect(RunService.Heartbeat, function()
		local raycast = game.Workspace:Raycast(rootpart.Position, Vector3.new(0, -38, 0), selfRaycastParams)
		if raycast and raycast.Instance then
			TitanData.States.isOnGround = true
		else
			TitanData.States.isOnGround = false
		end
	end)
end

function Titan._UpdateClimb()
	local range = TitanConfig.Custom.Climbing.ClimbRange
	local RaycastResult = game.Workspace:Raycast(
		rootpart.Position - Vector3.new(0, 26, 0),
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
		TitanMiscAnimations.Jump:Play()
		Titan._consumeStaminna(TitanConfig.Custom.JumpStaminaCost)
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
		TitanData.Stats.Stamina < TitanConfig.Custom.Combat.Roar.StaminaThreshold
		or TitanData.Stats.Stamina <= TitanConfig.Custom.Combat.Roar.StaminaCost
		or TitanData.States.isAttacking
		or TitanData.States.isClimbing
	then
		return
	end
	--~~[[ Roar ]]~~--
	TitanData.States.isRoaring = true
	TitanCombatAnimations.Roar:Play()
	TitanCombatAnimations.Roar.Stopped:Once(function()
		TitanData.States.isRoaring = false
		Titan._endRun()
	end)
	Titan._consumeStaminna(TitanConfig.Custom.Combat.Roar.StaminaCost)
	Satellite.Send("TitanAction", "Roar")
end

function Titan._LMB()
	--~~[[ Checks ]]~~--
	local isAttacking = TitanData.States.isAttacking
	local isRoaring = TitanData.States.isRoaring
	local AttackIndex = TitanData.Stats.AttackIndex
	if isAttacking or isRoaring then
		return
	end
	--~~[[ Pass Checks ]]~~--
	local HitboxCFrame = CFrame.new((head:GetPivot() * TitanConfig.Custom.Combat.Hitbox.LMB.CFrameOffset).Position)
	local Hitbox = SpatialHitbox.new(TitanConfig.Custom.Combat.Hitbox.LMB.Size, HitboxCFrame, { player })
	Hitbox:SetVisibility(true)
	TitanData.States.isAttacking = true
	local CurrentAnimation = TitanLightAttackAnimations[AttackIndex]
	CurrentAnimation:Play()
	Hitbox:SetCallback(Titan._onHit, true)
	Hitbox:Once()
	CurrentAnimation.Stopped:Once(function()
		TitanData.States.isAttacking = false
		Hitbox:Destroy()
		if AttackIndex == TitanData.Stats.MaxAttackIndex then
			TitanData.Stats.AttackIndex = 1
		else
			TitanData.Stats.AttackIndex = math.clamp(AttackIndex + 1, 1, TitanData.Stats.MaxAttackIndex)
		end
	end)
end

function Titan._onHit(HitCharacters: { Model })
	if #HitCharacters > 0 then
		Satellite.Send("TitanAction", "LightHit", HitCharacters)
	end
end

function Titan._activateCombatInput()
	Ayano:Connect(UserInputService.InputBegan, function(input: InputObject, GameProcessedEvent: boolean)
		if GameProcessedEvent then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TitanData.States.isLMBHeld = true
			while TitanData.States.isLMBHeld do
				task.wait(0.1)
				Titan._LMB()
			end
		end
		if input.KeyCode == Enum.KeyCode.R then
			Titan._Roar()
		end
	end)
	Ayano:Connect(UserInputService.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			TitanData.States.isLMBHeld = false
		end
	end)
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
			local ModifiedForceDirection = Vector3.new(Direction.Unit.X, 0.1, Direction.Unit.Y)
			rootPart:ApplyImpulse(ModifiedForceDirection * TitanConfig.Custom.Combat.Roar.ForceMagnitude)
		end
	end
end

function Titan.onRoar(shifter: Player, isDone: boolean)
	local shifterCharacter = shifter.Character
	if not shifterCharacter then
		return
	end
	if isDone then
		VFX.SetParticle(shifterCharacter, false)
		Titan._effectList.Roar[shifterCharacter] = nil
		Ayano:Clean("Roar")
	else
		TitanSFX.Roar:Play()
		VFX.SetParticle(shifterCharacter, true)
		Titan._effectList.Roar[shifterCharacter] = true
		Ayano:TrackThread(
			task.delay(10, function()
				Titan._effectList.Roar[shifterCharacter] = nil
			end),
			"Roar"
		)
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
end

function Titan._activateReplicator()
	Satellite.ListenTo("ReplicateTitanVFX"):Connect(Titan.onReplicationRequest)
	RunService.Heartbeat:Connect(Titan._updateRoarKnockback)
end

--~~[[ General ]]~~--
function Titan.ActivateCustom()
	Log:printheader("Initiating Custom Controller")
	Titan._createMiscAnimations()
	Titan._createCombatAnimations()
	Titan._activateCombatController()
	Titan._activateMiscAnimator()
	Titan._activateClimber()
	Titan._activateNapeSystem()
	Titan._activateGroundChecker()
	Titan._activateJumpChecker()
end

return Titan
