--[[

@rakken
RbxLib

]]

local RunService = game:GetService("RunService")

local t = {
	GoodSignal = require(script.GoodSignal),
	Satellite = require(script.Satellite),
	TaikaGui = require(script.TaikaGui),
	Utils = require(script.Utils),
	Types = require(script.Types),
}

if not RunService:IsClient() then
	t.Data = require(script.Data)
	t.Currency = require(script.Currency)
end

return t
