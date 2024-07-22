--[[

@rakken
User Input Service Related Utility Functions

]]

--// Services
local UserInputService = game:GetService("UserInputService")

--// Main
local UIS = {}

--[[ Public Functions ]]
function UIS.BindVariablesToKeyCode(varT: { any }, KeyCode: Enum.KeyCode)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.KeyCode == Enum.KeyCode then
			for variablename, _ in ipairs(varT) do
				varT[variablename] = true
			end
		end
	end)
end

return UIS
