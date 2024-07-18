--[[

@rakken
Roblox Utility Library - Gui Class
Calucalator Library for Gui Size / Offset conversions.

]]

--// Variables
local ScreenSize = game.Workspace.CurrentCamera.ViewportSize

--// Main
local UtilsGui = {}

function UtilsGui.ScaleToOffset(Scale: UDim2): UDim2
	warn(ScreenSize.X * Scale.X.Scale)

	return UDim2.fromOffset(ScreenSize.X * Scale.X.Scale, ScreenSize.Y * Scale.Y.Scale)
end

function UtilsGui.OffsetToScale(Offset: UDim2): UDim2
	return UDim2.new(Offset.X.Offset / ScreenSize.X, Offset.Y.Offset / ScreenSize.Y)
end

function UtilsGui.GetValue(valuename: string)
	return UtilsGui.values[valuename]
end

return UtilsGui
