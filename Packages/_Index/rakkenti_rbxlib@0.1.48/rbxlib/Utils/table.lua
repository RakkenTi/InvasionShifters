--[[

@rakken
Class for table utility functions

]]

--// Services
local HttpService = game:GetService("HttpService")

--// Main
local Table = {}

function Table.getDictLength(dict: {}): number
	local i = 0

	for _, _ in pairs(dict) do
		i += 1
	end

	return i
end

function Table.SearchDictByValue(dict: {}, value: any)
	for k, v in pairs(dict) do
		if v == value then
			return k
		end
	end
end

function Table.DeepCopy(original: {})
	local copy = {}

	for k, v in pairs(original) do
		if type(v) == "table" then
			v = Table.DeepCopy(v)
		end

		copy[k] = v
	end

	return copy
end

function Table.AddTableContentsToTable(tableToReceive: {}, tableToGive: {})
	for _, v in ipairs(tableToGive) do
		table.insert(tableToReceive, v)
	end
end

function Table.AddTableContentsToDict(dict: {}, table: {})
	for _, v in ipairs(table) do
		dict[HttpService:GenerateGUID()] = v
	end
end

function Table.AddDictContentsToDict(dictToReceive: {}, dictToGive: {})
	for key, value in pairs(dictToGive) do
		dictToReceive[key] = value
	end
end

function Table.AddDictKeysToDict(dictToReceive: {}, dictToGive: {})
	for key, _ in pairs(dictToGive) do
		dictToReceive[key] = true
	end
end

return Table
