--[[

@rakken
Class for formatting numbers to shorter versions using abbreviations.

]]

--// Main

local Format = {}

local Abbreviations = {
	K = 4,
	M = 7,
	B = 10,
}

function Format.Format(number: number)
	if not number then
		warn(`Missing number argument.`)
		return
	end

	if typeof(number) ~= "number" then
		number = tonumber(number)
		return
	end

	local s_number = tostring(math.floor(number))
	local abbreviation
	local length = #s_number

	for abb, digits in pairs(Abbreviations) do
		if length >= digits and length < (digits + 3) then
			abbreviation = abb

			break
		end
	end

	if abbreviation then
		local digits = Abbreviations[abbreviation]

		if digits < 7 then
			local comma_index = (length - digits) + 1
			return s_number:sub(1, comma_index) .. "," .. s_number:sub(1 + comma_index, -1)
		end

		local divisor = 10 ^ (length - (length - digits) - 1)
		local rounded = (number / divisor)
		local output = string.format("%.2f", rounded) .. abbreviation

		return output
	else
		return number
	end
end

return Format
