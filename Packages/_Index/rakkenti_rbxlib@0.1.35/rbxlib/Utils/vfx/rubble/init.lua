--[[
@rakken
VFX Rubble Module
Creates rubble.
]]

--// Services
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

--// Modules
local Types = require(script.types)
local Presets = require(script.presets)
local AyanoModule = require(script.Parent.Parent.ayano)
local Property = require(script.Parent.Parent.property)

--// Module-Constants

--// Constants
local RubbleFolder = Instance.new("Folder")
local FULL_ROTATION = math.pi * 2

--~~[[ Collision Handling ]]~~--
if RunService:IsServer() then
	repeat
		PhysicsService:RegisterCollisionGroup("VFXRubble")
		task.wait(2)
	until PhysicsService:IsCollisionGroupRegistered("VFXRubble")
		and PhysicsService:IsCollisionGroupRegistered("Default")
	PhysicsService:CollisionGroupSetCollidable("VFXRubble", "Default", true)
else
	repeat
		task.wait(2)
	until PhysicsService:IsCollisionGroupRegistered("VFXRubble")
end

--// Main

local Rubble = {}
Rubble.Presets = Presets
Rubble.Crater = {}
Rubble.Explosion = {}

--[[ Private Functions ]]
local function GetDegreeToRadVariance(Variance: number)
	return math.rad(math.random(-Variance, Variance)),
		math.rad(math.random(-Variance, Variance)),
		math.rad(math.random(-Variance, Variance))
end

local function GetRandomVector3WithinRange(min: number, max: number)
	return Vector3.new(math.random(min, max), math.random(min, max), math.random(min, max))
end

--~~/// [[ Public Functions ]] ///~~--
--~~[[ Crater ]]~~--
function Rubble.Crater.Create(
	center: CFrame,
	template: Types.CraterTemplate,
	filter: { Instance },
	callback: (({ BasePart }) -> nil)?
)
	--~~[[ Template Variables ]]~~--
	local degreeVariance = template.DegreeVariance
	local fadeTweenInfo = template.FadeTweenInfo
	local startOffset = template.StartOffset
	local minRadius = template.MinimumRadius
	local maxRadius = template.MaximumRadius
	local minSize = template.MinimumSize
	local maxSize = template.MaximumSize
	local tweeninfo = template.TweenInfo
	local segments = template.Segments
	local duration = template.Duration
	local tweenDur = tweeninfo.Time
	--~~[[ Internal Variables ]]~~--
	local Maid = AyanoModule.new()
	local Theta = FULL_ROTATION / segments
	local RaycastParam = RaycastParams.new()
	RaycastParam.FilterDescendantsInstances = filter or {}

	--~~[[ Main ]]~~--
	local partList = {}
	for i = 1, segments do
		local Orientation = CFrame.fromOrientation(0, Theta * i, 0)
		local RayStart = center * Orientation * CFrame.new(0, 5, -math.random(minRadius, maxRadius))
		local Raycast = game.Workspace:Raycast(RayStart.Position, -RayStart.UpVector.Unit * 100, RaycastParam)
		if Raycast and Raycast.Instance then
			local Part = Maid:TrackInstance(Instance.new("Part"))
			local StartPosition = Raycast.Position - RayStart.UpVector.Unit * startOffset
			local PartCFrame = CFrame.lookAt(StartPosition, StartPosition + Raycast.Normal.Unit)
			local dgv1, dgv2, dgv3 = GetDegreeToRadVariance(degreeVariance)
			Part.Size = GetRandomVector3WithinRange(minSize, maxSize)
			Part.Anchored = true
			Part.CanQuery = false
			Part.CanTouch = false
			Part.CollisionGroup = "VFXRubble"
			Part.CFrame = PartCFrame * CFrame.Angles(dgv1, dgv2, dgv3)
			Part.Color = Raycast.Instance.Color
			Part.Material = Raycast.Instance.Material
			Part.Parent = RubbleFolder
			local Tween = TweenService:Create(Part, tweeninfo, { Position = Raycast.Position })
			Tween:Play()
			table.insert(partList, Part)
		end
	end

	if callback then
		callback(partList)
	end

	--~~[[ After ]]~~--
	task.delay(tweenDur + duration, function()
		Property.BatchSet(partList, { Anchored = false, CanCollide = false })
		Property.BatchSet(partList, { Transparency = 1 }, fadeTweenInfo)
		Maid:DelayClean(10)
	end)
end

--~~[[ Explosion ]]~~--
function Rubble.Explosion.Create(
	center: CFrame,
	template: Types.ExplosionTemplate,
	filter: { Instance },
	callback: (({ BasePart }, "OnCreate" | "OnMidpoint" | "OnEnd") -> nil)?
)
	--~~[[ Template Variables ]]~~--
	local degreeVariance = template.DegreeVariance
	local startOffset = template.StartOffset
	local minRadius = template.MinimumRadius
	local maxRadius = template.MaximumRadius
	local minSize = template.MinimumSize
	local maxSize = template.MaximumSize
	local segments = template.Segments
	local lifetime = template.Lifetime
	local magnitude = template.Magnitude
	--~~[[ Internal Variables ]]~~--
	local Maid = AyanoModule.new()
	local Theta = FULL_ROTATION / segments
	local PartList = {}
	local RaycastParam = RaycastParams.new()
	RaycastParam.FilterDescendantsInstances = filter or {}

	--~~[[ Main ]]~~--
	for i = 1, segments do
		local Orientation = CFrame.fromOrientation(0, Theta * i, 0)
		local RayStart = center * Orientation * CFrame.new(0, 5, -math.random(minRadius, maxRadius))
		local Raycast = game.Workspace:Raycast(RayStart.Position, -RayStart.UpVector.Unit * 100, RaycastParam)
		if Raycast and Raycast.Instance then
			local Part = Maid:TrackInstance(Instance.new("Part"))
			local StartPosition = Raycast.Position - RayStart.UpVector.Unit * startOffset
			local dgv1, dgv2, dgv3 = GetDegreeToRadVariance(degreeVariance)
			local PartCFrame = CFrame.lookAt(StartPosition, StartPosition + Raycast.Normal.Unit)
			Part.Size = GetRandomVector3WithinRange(minSize, maxSize)
			Part.CanCollide = true
			Part.CanQuery = false
			Part.CanTouch = false
			Part.CFrame = PartCFrame * CFrame.Angles(dgv1, dgv2, dgv3)
			Part.Color = Raycast.Instance.Color
			Part.Material = Raycast.Instance.Material
			Part.CollisionGroup = "VFXRubble"
			Part.Parent = RubbleFolder
			Part:ApplyImpulse(Part.CFrame.LookVector.Unit * magnitude * Part.Mass)
			table.insert(PartList, Part)
		end
	end
	if callback then
		callback(PartList, "OnCreate")
		task.delay(lifetime / 2, function()
			callback(PartList, "OnMidpoint")
			task.delay(lifetime / 2, function()
				if callback then
					callback(PartList, "OnEnd")
				end
				Maid:Clean()
			end)
		end)
	else
		task.delay(lifetime, function()
			if callback then
				callback(PartList, "OnEnd")
			end
			Maid:Clean()
		end)
	end
end

--~~[[ Init ]]~~--
RubbleFolder.Name = "Rubble"
RubbleFolder.Parent = game.Workspace

return Rubble
