return {

	ScreenGui = {

		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
	},

	Frame = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
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
		Color = Color3.fromRGB(223, 184, 130),
		Thickness = 0.5,
	},

	TextButton = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(226, 226, 226),
		Visible = true,
		TextScaled = true,
		FontFace = Font.fromEnum(Enum.Font.Arcade),
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
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(226, 226, 226),
		Visible = true,
		TextScaled = true,
		FontFace = Font.fromEnum(Enum.Font.Arcade),
	},

	CanvasGroup = {

		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(26, 26, 26),
		Position = UDim2.fromScale(0.5, 0.5),
	},

	ScrollingFrame = {

		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AutomaticCanvasSize = "Y",
		CanvasSize = UDim2.fromScale(0, 2),
	},

	Custom = {

		Logo = {

			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
		},

		Container = {

			Active = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		},
	},
}
