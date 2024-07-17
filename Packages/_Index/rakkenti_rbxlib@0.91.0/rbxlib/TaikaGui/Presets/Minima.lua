local Reference = require(script.Parent.Parent.Parent.Utils).reference

return {

	ScreenGui = {

		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	},

	Frame = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Reference.Colors.Black,
		BackgroundTransparency = 0.2,
		Position = UDim2.fromScale(0.5, 0.5),
		BorderSizePixel = 0,
	},

	ImageLabel = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	},

	ImageButton = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Visible = true,
		ZIndex = 1,
		ScaleType = Enum.ScaleType.Fit,
	},

	UIStroke = {

		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Color = Color3.fromRGB(223, 223, 223),
		Thickness = 1,
	},

	TextButton = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(226, 226, 226),
		Visible = true,
		TextScaled = true,
		FontFace = Font.fromEnum(Enum.Font.FredokaOne),
	},

	TextBox = {

		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		TextScaled = false,
		TextSize = 14,
		TextColor3 = Color3.fromRGB(212, 212, 212),
		PlaceholderColor3 = Color3.fromRGB(102, 102, 102),
	},

	TextLabel = {

		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(226, 226, 226),
		Visible = true,
		TextScaled = true,
		FontFace = Font.fromEnum(Enum.Font.FredokaOne),
	},

	CanvasGroup = {

		Active = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Reference.Colors.Black,
		BackgroundTransparency = 0.2,
		Position = UDim2.fromScale(0.5, 0.5),
	},

	ScrollingFrame = {

		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AutomaticCanvasSize = "Y",
		CanvasSize = UDim2.fromScale(0, 2),
		ScrollBarThickness = 8,
		BorderSizePixel = 0,
		ScrollBarImageColor3 = Reference.Colors.DarkGray,
	},

	UICorner = {

		CornerRadius = UDim.new(0.55, 0),
	},

	UIListLayout = {

		Padding = UDim.new(0.1, 0),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	},

	UIGridLayout = {

		CellPadding = UDim2.fromScale(0.05, 0.05),
		CellSize = UDim2.fromScale(0.2, 0.2),
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	},

	Custom = {

		Logo = {

			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		},

		BackgroundImage = {

			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(100, 100),
			Image = "rbxassetid://121480522",
		},

		Container = {

			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.2,
			BackgroundColor3 = Reference.Colors.Black,
		},
	},
}
