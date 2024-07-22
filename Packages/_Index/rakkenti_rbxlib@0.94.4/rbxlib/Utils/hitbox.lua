--[[

@rakken
Simple Hitbox Module.
Spatial Query based hitbox

]]

--// Services
local RunService = game:GetService("RunService")

--// Modules

--// Module-Constants

--// Variables

--// Main
local Hitbox = {}
Hitbox.__index = Hitbox

--[[ Private Functions ]]

--[[ Public Functions ]]
function Hitbox.new(Size: Vector3, CF: CFrame, ignore: { Player }?)
	local self = setmetatable({}, Hitbox)
	local Filter = {}

	if ignore then
		for _, player in ipairs(ignore) do
			local character = player.Character
			if character then
				table.insert(Filter, character)
			end
		end
	end

	self.batch = false
	self.callback = nil
	self.batchhit = nil
	self.heartbeat = nil :: RBXScriptConnection?
	self.show = false
	self.filter = Filter
	self.hitfilter = {} :: { Humanoid }
	self.size = Size
	self.cframe = CF
	self.params = OverlapParams.new()
	self.params.FilterDescendantsInstances = self.filter
	return self
end

type Class = typeof(Hitbox.new(...))

function Hitbox.SetVisibility(self: Class, bool: boolean)
	self.show = bool
end

function Hitbox.Adjust(self: Class, Size: Vector3, CF: CFrame)
	self.size = Size
	self.cframe = CF
end

function Hitbox.Clear(self: Class)
	table.clear(self.hitfilter)
end

function Hitbox.SetCallback(self: Class, callback: (Model) -> nil, batch: boolean)
	self.callback = callback
	self.batch = batch
end

function Hitbox.Once(self: Class)
	local HitListFilter = self.hitfilter
	local QueryContents = game.Workspace:GetPartBoundsInBox(self.cframe, self.size, self.params)
	if self.show then
		local hitbox = Instance.new("Part")
		hitbox.Parent = game.Workspace
		hitbox.CFrame = self.cframe
		hitbox.Size = self.size
		hitbox.Transparency = 0.9
		hitbox.CanCollide = false
		hitbox.Color = Color3.fromRGB(255, 0, 0)
		hitbox.Anchored = true
		hitbox.CanQuery = false
		hitbox.CanTouch = false
		task.delay(1, function()
			hitbox:Destroy()
		end)
	end
	if QueryContents then
		local hitcharacters = {}
		for _, instance: Instance in ipairs(QueryContents) do
			local character = instance.Parent :: Model
			local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
			if not character or not humanoid or HitListFilter[humanoid] then
				continue
			end
			if not self.batch then
				if self.callback then
					self.callback(character)
				end
			else
				table.insert(hitcharacters, character)
			end
			HitListFilter[humanoid] = true
		end
		if self.batch then
			self.callback(hitcharacters)
		end
	end
end

function Hitbox.Start(self: Class)
	self.heartbeat = RunService.Heartbeat:Connect(function()
		self:Once()
	end)
end

function Hitbox.Stop(self: Class)
	if self.heartbeat then
		self.heartbeat:Disconnect()
	end
end

function Hitbox.Destroy(self: Class)
	self:Stop()
	table.clear(self.filter)
	table.clear(self.hitfilter)
	table.clear(self)
	self = nil
end

return Hitbox
