--!strict

type DataTemplateType = {
	GameData: {
		Shifter: boolean,
		ShifterName: string,
		Bloodline: string, -- If this has a value, the last name will instead be the bloodline
		-- Speed, Strength, and Durability have randomly generated
		-- values whenever the player creates a new save. This
		-- means they can get really lucky, or vise versa. Not
		-- sure why the owner thought this would be a good idea though...
		--	Medic : boolean,
		--	ODM : boolean,
		-- 	Horse : boolean,
		Branch: string,
		Rank: string,
		Titan: string,
		Speed: number,
		Strength: number,
		Durability: number,
		Insanity: number,
		BandageCount: number,

		Profiles: {},

		Hotbar: {},

		Bandages: {
			-- Represents the time the bandage was added or N/A if no bandage is on said limb
			Head: DateTime | string,
			Torso: DateTime | string,
			["Left Arm"]: DateTime | string,
			["Right Arm"]: DateTime | string,
			["Left Leg"]: DateTime | string,
			["Right Leg"]: DateTime | string,
		},

		Injuries: {
			-- Here, the health of each limb is simply a value
			-- ranging from 0 - 100.
			Head: number,
			Torso: number,
			["Left Arm"]: number,
			["Right Arm"]: number,
			["Left Leg"]: number,
			["Right Leg"]: number,
		},

		PersonalData: {
			HumanKills: number,
			MindlessTitanKills: number,
			HumanAssists: number,
			MindlessTitanAssists: number,
			AbnormalKills: number,
			AbnormalAssists: number,
			--		Eyes : number,
			--		Eyebrows : number,
			--		Mouth : number,
			--		Scars : number,
			HairColor: string,
			isCharacterCreated: boolean,
		},
		Skills: { number },

		CharacterAppearance: {},
	},
}

-- We define the default data here.
local DataTemplate: DataTemplateType = {
	GameData = {
		Shifter = false,
		ShifterName = "",
		Titan = "nil",
		Bloodline = "N/A",
		Branch = "Civilian",
		Rank = "Civilian",
		--	Medic : false,
		--	ODM : false,
		-- 	Horse : false,
		--	Branch : Civilian,
		--	Rank : Civilian,
		Speed = 3,
		Strength = 3,
		Durability = 3,
		Insanity = 0,
		BandageCount = 0,

		Profiles = {},

		Hotbar = {},

		Bandages = {
			Head = "N/A",
			Torso = "N/A",
			["Left Arm"] = "N/A",
			["Right Arm"] = "N/A",
			["Left Leg"] = "N/A",
			["Right Leg"] = "N/A",
		},

		Injuries = {
			Head = 100,
			Torso = 100,
			["Left Arm"] = 100,
			["Right Arm"] = 100,
			["Left Leg"] = 100,
			["Right Leg"] = 100,
		},
		PersonalData = {
			HumanKills = 0,
			MindlessTitanKills = 0,
			HumanAssists = 0,
			MindlessTitanAssists = 0,
			AbnormalKills = 0,
			AbnormalAssists = 0,
			--		Eyes : 1,
			--		Eyebrows : 1,
			--		Mouth : 1,
			--		Scars : 0,
			HairColor = "N/A",
			isCharacterCreated = false,
			Name = "",
		},
		Skills = {},

		CharacterAppearance = {},
	},
}

return DataTemplate
