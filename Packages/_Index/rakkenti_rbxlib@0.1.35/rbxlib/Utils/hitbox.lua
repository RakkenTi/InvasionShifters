--[[

@rakken
Simple Hitbox Module.
Spatial Query based hitbox

]]

--// Services
local RunService = game:GetService("RunService")

--// Modules
local Log = require(script.Parent.log).new("[Hitbox]")

--// Module-Constants

--// Variables

--// Main
local Hitbox = {}
Hitbox.__index = Hitbox

--[[ Private Functions ]]

--[[ Public Functions ]]
function Hitbox.new(Size: Vector3, Offset: CFrame | Vector3, ignore: { Player }?)
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
	self.livecallback = nil
	self.batchhit = nil
	self.heartbeat = nil :: RBXScriptConnection?
	self.bindpart = nil :: BasePart?
	self.bindpartoffset = nil :: CFrame? | Vector3?
	self.show = false
	self.filter = Filter
	self.hitfilter = {} :: { Humanoid }
	self.hitlistconfilter = {} :: { Model: boolean }
	self.hitlist = {} :: { character: boolean }
	self.size = Size
	self.offset = Offset
	self.continuous = false
	self.params = OverlapParams.new()
	self.params.FilterDescendantsInstances = self.filter
	return self
end

type Class = typeof(Hitbox.new(...))

function Hitbox.Bind(self: Class, bindpart: BasePart, offset: CFrame)
	self.bindpart = bindpart
	self.bindpartoffset = offset
end

function Hitbox.SetVisibility(self: Class, bool: boolean)
	self.show = bool
end

function Hitbox.Adjust(self: Class, Size: Vector3, Offset: CFrame | Vector3)
	self.size = Size
	self.offset = Offset
end

function Hitbox.Clear(self: Class)
	table.clear(self.hitfilter)
end

function Hitbox.SetCallback(self: Class, callback: (Model | { Model }) -> nil, batch: boolean)
	self.callback = callback
	self.batch = batch
end

function Hitbox.SetLiveCallback(self: Class, callback: (Model) -> nil)
	self.livecallback = callback
end

function Hitbox.Once(self: Class)
	local HitListFilter = self.hitfilter
	if self.bindpart and self.bindpartoffset then
		if typeof(self.bindpartoffset) == "CFrame" then
			self.offset = self.bindpart.CFrame * self.bindpartoffset
		else
			self.offset = self.bindpart.CFrame + self.bindpartoffset
		end
	end
	if not self.offset then
		Log:warn("No CFrame available for hitbox.")
		return
	end
	if typeof(self.offset) == "Vector3" then
		self.offset = CFrame.new(self.offset)
	end
	local QueryContents = game.Workspace:GetPartBoundsInBox(self.offset, self.size, self.params)
	if self.show then
		local hitbox = Instance.new("Part")
		hitbox.Parent = game.Workspace
		hitbox.CFrame = self.offset
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
			if self.continuous then
				if not self.hitlist[character] and self.livecallback then
					self.livecallback(character)
				end
				self.hitlist[character] = character
			end
			if not self.batch then
				if self.callback and not self.continuous then
					self.callback(character)
				end
			else
				table.insert(hitcharacters, character)
			end
			HitListFilter[humanoid] = true
		end
		if self.batch and not self.continuous then
			self.callback(hitcharacters)
		end
	end
end

function Hitbox.SetContinous(self: Class, bool: boolean)
	self.continuous = bool
end

function Hitbox.Start(self: Class)
	self.hitlist = {}
	self.heartbeat = RunService.Heartbeat:Connect(function()
		self:Once()
	end)
end

function Hitbox.Stop(self: Class)
	if self.heartbeat then
		self.heartbeat:Disconnect()
	end
	if self.continuous then
		self.callback(self.hitlist)
	end
	self.hitlist = {}
	self.callback = nil
end

function Hitbox.Destroy(self: Class)
	self:Stop()
	table.clear(self.filter)
	table.clear(self.hitfilter)
	table.clear(self)
	self = nil
end

return Hitbox
