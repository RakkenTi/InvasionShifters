--// Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

if RunService:IsServer() then
	return true
end

--// Paths
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = game.Workspace.CurrentCamera
local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart

--// Constants
local Log = require(script.Parent.log).new("[Mouse]")

--// Variables
local params = RaycastParams.new()
params.FilterDescendantsInstances = { character }

--// Main
local Mouse = {
	Hit = {} :: { Distance: number, Instance: Instance, Material: Enum.Material, Position: Vector3, Normal: Vector3 } | any,
	M1Held = false,
	M2Held = false,
	X = UserInputService:GetMouseLocation().X,
	Y = UserInputService:GetMouseLocation().Y,
	Binds = {
		M1 = {},
		M2 = {},
	},
}

function Mouse:Push(distance: number)
	local MousePos = UserInputService:GetMouseLocation()
	local MouseRay = camera:ViewportPointToRay(MousePos.X, MousePos.Y)

	return MouseRay.Origin + MouseRay.Direction.Unit * distance
end

function Mouse:GetMouseDirection()
	local raycastparams = RaycastParams.new()
	raycastparams.FilterDescendantsInstances = {}

	local MousePos = UserInputService:GetMouseLocation()
	local MouseRay = camera:ViewportPointToRay(MousePos.X, MousePos.Y)

	local raycast = game.Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 5, raycastparams)

	if raycast then
		return CFrame.lookAt(hrp.Position, raycast.Position).LookVector.Unit
	end

	return nil
end

function Mouse:GetMouseDirectionFrom(origin: Vector3, _params: RaycastParams)
	local raycastparams = RaycastParams.new()
	raycastparams.FilterDescendantsInstances = {}

	local MousePos = UserInputService:GetMouseLocation()
	local MouseRay = camera:ViewportPointToRay(MousePos.X, MousePos.Y)

	local raycast = game.Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 5, _params or raycastparams)

	if raycast then
		return CFrame.lookAt(origin, raycast.Position).LookVector.Unit
	end

	return nil
end

function Mouse:BindToPrimary(name: string, callback: () -> nil)
	if Mouse.Binds.M1[name] then
		Log:print(`Overwriting already created bind: [{name}].`)
	end
	if not callback then
		Log:warn("Missing callback.")
		return
	end

	Mouse.Binds.M1[name] = callback

	Log:print(`Binded callback with name: [{name}]`)
end

function Mouse:BindToSecondary(name: string, callback: () -> nil)
	if Mouse.Binds.M2[name] then
		Log:warn(`Already created bind: [{name}].`)
		return
	end
	if not callback then
		Log:warn("Missing callback.")
		return
	end

	Mouse.Binds.M2[name] = callback

	Log:warn(`Binded callback with name: [{name}]`)
end

function Mouse:UnbindFromPrimary(name: string)
	Mouse.Binds.M1[name] = nil
end

function Mouse:UnbindFromSecondary(name: string)
	Mouse.Binds.M2[name] = nil
end

--// Init

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Mouse.M1Held = true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		Mouse.M2Held = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if gpe then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 and Mouse.M1Held == true then
		Mouse.M1Held = false

		for name, func in pairs(Mouse.Binds.M1) do
			Log:print(`Executing function: [{name}].`)

			func()
		end
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 and Mouse.M2Held == true then
		Mouse.M2Held = false

		for name, func in pairs(Mouse.Binds.M2) do
			Log:print(`Executing function: [{name}].`)

			func()
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local MousePos = UserInputService:GetMouseLocation()
	local MouseRay = camera:ViewportPointToRay(MousePos.X, MousePos.Y)
	local Raycast = game.Workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 5000, params)

	Mouse.X = MousePos.X
	Mouse.Y = MousePos.Y

	if Raycast then
		Mouse.Hit = Raycast
	else
		Mouse.Hit = nil
	end
end)

return Mouse
