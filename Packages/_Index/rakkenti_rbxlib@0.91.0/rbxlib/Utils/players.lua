--[[

@rakken
Basic utility class for playe related things.

]]

--// Services
local Players = game:GetService("Players")

--// Main
local players = {}

function players.OnPlayerAdded(func: (Player, any?) -> any?)
	for _, player in Players:GetPlayers() do
		task.spawn(func, player)
	end
	Players.PlayerAdded:Connect(func)
end

function players.SearchPlayers(RootPos: Vector3, Radius: number)
	local AffectedPlayers = {}

	for _, player in Players:GetPlayers() do
		local character = player.Character

		if not character then
			continue
		end

		local hrp = character.HumanoidRootPart :: BasePart

		if not hrp then
			continue
		end

		local PlayerPosition = hrp.Position

		if (RootPos + PlayerPosition).Magnitude <= Radius then
			table.insert(AffectedPlayers, player)
		end
	end

	return AffectedPlayers
end

return players
