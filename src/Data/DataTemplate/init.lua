--!strict

type DataTemplateType = {

	PlayerData: {

		Currency: number,
		Gamepasses: {},
		DevProducts: {},
		LastEquippedAvatar: {},
		Settings: {},
	},

	PlayerOwnedData: {

		Horse: {},
		Tack: {},
		Avatar: {},
	},
}

-- We define the default data here.
local DataTemplate: DataTemplateType = {

	PlayerData = {

		Currency = 0,
		Gamepasses = {},
		DevProducts = {},
		LastEquippedAvatar = {},
		Settings = require(script.Settings),
	},

	PlayerOwnedData = {

		Horse = {},
		Tack = {},
		Avatar = {},
	},
}

return DataTemplate
