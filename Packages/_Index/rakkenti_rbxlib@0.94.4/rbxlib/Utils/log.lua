--[[

@rakken
Class for logging messages with special features

]]

--// Services
local RunService = game:GetService("RunService")

--// Main
local log = {
	Presets = {
		["WARNING"] = "[WARNING]",
		["CRITICAL_ERROR"] = "[CRITICAL ERROR]",
		["DEBUG"] = "[DEBUG]",
		["ERROR"] = "[ERROR]",
		["LOG"] = "[LOG]",
	},
}

log.__index = log

if RunService:IsClient() then
	log.TAG = "[C]"
else
	log.TAG = "[S]"
end

function log:disable()
	self.disabled = true
end

function log:enable()
	self.disabled = false
end

function log.new(tag: string)
	return setmetatable({
		tag = tag,
		disabled = false,
	}, log)
end

function log:print(message: string, PresetTag: string?)
	if self.disabled then
		return
	end

	if PresetTag then
		print(`{log.TAG} {message} {PresetTag}] | Trace: [{debug.info(2, "s")}]`)
		return
	end

	print(`{log.TAG} {self.tag} | {message} | Trace: [{debug.info(2, "s")}]`)
end

function log:warn(message: string, PresetTag: string?)
	if self.disabled then
		return
	end
	if PresetTag then
		warn(`{log.TAG} {message} {PresetTag} | Trace: [{debug.info(2, "s")}]`)
		return
	end

	warn(`{log.TAG} {self.tag} | {message} | Trace: [{debug.info(2, "s")}]`)
end

function log:assertwarn(condition: any, message: string, PresetTag: string?)
	if self.disabled then
		return
	end
	if condition then
		return
	end
	if PresetTag then
		warn(`{log.TAG} {message} {PresetTag} | Trace: [{debug.info(2, "s")}]`)
		return
	end

	warn(`{log.TAG} {self.tag} | {message} | Trace: [{debug.info(2, "s")}]`)
end

function log:assert(condition, message: string, PresetTag: string?)
	if self.disabled then
		return
	end
	if PresetTag then
		assert(condition, `{log.TAG} {message} {PresetTag} | Trace: [{debug.info(2, "s")}]`)
		return
	end

	assert(condition, `{self.tag} | {message} | Trace: [{debug.info(2, "s")}]`)
end

function log:message(message: string, source: Instance?, line: number?, PresetTag: string?)
	if self.disabled then
		return
	end
	if PresetTag then
		game:GetService("TestService")
			:Message(`{log.TAG} {message} {PresetTag} | Trace: [{debug.info(2, "s")}`, source, line)
		return
	end

	game:GetService("TestService"):Message(`{self.tag} | {message}`, source, line)
end

function log:error(message: string, level: number?, PresetTag: string?)
	if PresetTag then
		error(`{self.tag} | {message} {PresetTag} | Trace: [{debug.info(2, "s")}`)
		return
	end

	error(message, level)
end

function log:printheader(message: string)
	if self.disabled then
		return
	end
	print(`<------------------------------> | [{message}] | <------------------------------>||`)
end

function log:warnheader(message: string)
	warn(`<------------------------------> | [{message}] | <------------------------------>||`)
end

function log:messageheader(message: string, source: Instance?, line: number?)
	if self.disabled then
		return
	end
	game:GetService("TestService")
		:Message(`<------------------------------> | [{message}] | <------------------------------>||`, source, line)
end

return log
