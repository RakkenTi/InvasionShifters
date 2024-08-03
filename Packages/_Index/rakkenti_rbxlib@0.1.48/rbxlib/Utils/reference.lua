--[[

@rakken
Table of references for general use.

]]

--// Services
local Players = game:GetService("Players")

return {

	Client = {
		Camera = game.Workspace.CurrentCamera,
		Player = Players.LocalPlayer,
		Character = Players.LocalPlayer
			and (Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()),
		PlayerGui = Players.LocalPlayer and Players.LocalPlayer.PlayerGui,
		ScreenSize = game.Workspace:FindFirstChild("CurrentCamera") and game.Workspace.CurrentCamera.ViewportSize,
	},

	TweenInfos = {
		VerySlow = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		Slow = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		Normal = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		Swift = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		Fast = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	},

	Colors = {
		DarkGray = Color3.fromRGB(104, 104, 104),
		LightGray = Color3.fromRGB(226, 226, 226),
		MinimalGray = Color3.fromRGB(45, 45, 45),
		Black = Color3.fromRGB(0, 0, 0),
		White = Color3.fromRGB(255, 255, 255),
		SweetRed = Color3.fromRGB(200, 84, 86),
		SoftGreen = Color3.fromRGB(46, 208, 87),
		Cyan = Color3.fromRGB(108, 223, 213),
		BrightCyan = Color3.fromRGB(171, 255, 248),
		Gold = Color3.fromRGB(255, 228, 74),
		FaintYellow = Color3.fromRGB(241, 255, 147),
	},
}
