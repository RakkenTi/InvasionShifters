--[[

@rakken
Titan: Attack Titan
Notes;

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
		canRoar = true,
		canHeavy = true,
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
local TitanSFX = {} :: { [any]: Sound }
local TitanSpecialSFX = {} :: { [any]: Sound }
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
	Ayano2:Clean()
	table.clear(TitanData)
	table.clear(TitanAnimations)
	table.clear(TitanLMBAnimations)
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
	Log:print("Initializing Titan Data")
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

function Titan._Landed()
	Satellite.Send("TitanAction", "Landed")
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
	Rubble.Crater.Create(CFrame.new(_rightfoot.Position), Rubble.Presets.Crater.Medium, Filter, ConfigCrater)
	Rubble.Explosion.Create(CFrame.new(_rightfoot.Position), Rubble.Presets.Explosion.Medium, Filter, ConfigCrater)
	Rubble.Crater.Create(CFrame.new(_leftfoot.Position), Rubble.Presets.Crater.Medium, Filter, ConfigCrater)
	Rubble.Explosion.Create(CFrame.new(_leftfoot.Position), Rubble.Presets.Explosion.Medium, Filter, ConfigCrater)
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

function Titan.onRoar(shifter: Player, isDone: boolean)
	print("attack titan roar")
	local shifterCharacter = shifter.Character
	if isDone then
		Titan._effectList.Roar[shifterCharacter] = nil
	end
	Titan._effectList.Roar[shifterCharacter] = true
	TitanSFX.Roar:Play()
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
end

function Titan._activateGenericReplicator()
	Satellite.ListenTo("ReplicateTitanVFX"):Connect(Titan._onReplicationRequest)
	RunService.Heartbeat:Connect(Titan._updateRoarKnockback)
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
function Titan._onHit(HitCharacters: { [any]: Model })
	if Utils.table.getDictLength(HitCharacters) > 0 then
		print(HitCharacters)
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
	then
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
	local Hitbox = Ayano:TrackInstance(SpatialHitbox.new(TitanConfig.Custom.Combat.Heavy.Hitbox.Size, nil, { player }))
	Hitbox:SetContinous(true)
	Hitbox:Bind(righthand, TitanConfig.Custom.Combat.Heavy.Hitbox.Vector3Offset)
	Hitbox:SetVisibility(true)
	Hitbox:SetCallback(Titan._onHeavyHit)
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
	--~~[[ Hitbox ]]~~--
	local Hand = (AttackIndex == RightIndex or AttackIndex == RightIndex2) and righthand or lefthand
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
	--~~[[ Animation ]]~~--
	CurrentAnimation.Stopped:Once(function()
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
		if input.KeyCode == Enum.KeyCode.E then
			Titan._Heavy()
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

function Titan.ActivateCustom()
	Titan._createCombatAnimations()
	Titan._activateCombatInput()
end

return Titan
