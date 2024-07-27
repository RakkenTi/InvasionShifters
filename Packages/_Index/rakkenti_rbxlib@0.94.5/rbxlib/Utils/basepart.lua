--[[

@rakken
Basepart related utility functions.
Why did I make it like this? Idk.

]]

--// Services
local TweenService = game:GetService("TweenService")

--// Main
local Basepart = {}

function Basepart.SetMassless(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
			v.Massless = bool
		end
	end
end

function Basepart.SetPhysicalProperties(root: Instance, _PhysicalProperties: PhysicalProperties)
	for _, v in root:GetDescendants() do
		if v:IsA("BasePart") then
			v.CustomPhysicalProperties = _PhysicalProperties
		end
	end
end

function Basepart.SetCollide(root: Instance, bool: boolean)
	for _, v in root:GetDescendants() do
		if v:IsA("BasePart") then
			v.CanCollide = bool
		end
	end
end

function Basepart.SetGroup(root: Instance, groupName: string)
	for _, v in root:GetDescendants() do
		if v:IsA("BasePart") then
			v.CollisionGroup = groupName
		end
	end
end

function Basepart.Fade(
	root: Instance,
	ti: TweenInfo,
	transparency: number,
	callback: () -> nil,
	filter: { any: boolean }
)
	for _, v in root:GetDescendants() do
		if v:IsA("BasePart") and not filter[v.Name] then
			TweenService:Create(v, ti, { Transparency = transparency }):Play()
		end
	end
	if callback then
		task.delay(ti.Time, callback)
	end
end

return Basepart
