--[[

@rakken
Basepart related utility functions.
Why did I make it like this? Idk.

]]

--// Services
local TweenService = game:GetService("TweenService")

--// Main
local Basepart = {}

function Basepart.RemoveWelds(t: Instance)
	for _, v in t:GetDescendants() do
		if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("Motor6D") then
			v:Destroy()
		end
	end
end

function Basepart.SetOwner(root: Instance, player: Player)
	for _, v in root:GetDescendants() do
		if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
			v:SetNetworkOwner(player)
		end
	end
end

function Basepart.WeldTogether(root: Instance, ...: BasePart)
	local parts = { ... }
	local previous = root
	for _, v in ipairs(parts) do
		local wc = Instance.new("WeldConstraint")
		wc.Part0 = previous
		wc.Part1 = v
		wc.Name = root.Name .. "_" .. v.Name
		wc.Parent = root
		previous = v
	end
end

function Basepart.Fade(
	root: Instance | { Instance },
	ti: TweenInfo,
	transparency: number,
	callback: () -> nil,
	filter: { any: boolean }
)
	local t = typeof(root) == "Instance" and root:GetDescendants() or root
	for _, v in ipairs(t) do
		if v:IsA("BasePart") and not v:HasTag("FadeFilter") then
			if filter and filter[v.Name] then
				continue
			end
			TweenService:Create(v, ti, { Transparency = transparency }):Play()
		end
	end

	if callback then
		task.delay(ti.Time, callback)
	end
end

return Basepart
