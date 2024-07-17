--[[

@rakken
good for recording time

]]

local Stopwatch = {}
Stopwatch.CurrentTime = tick()

function Stopwatch.Start(): nil
	Stopwatch.CurrentTime = tick()
end

function Stopwatch.Stop()
	return tick() - Stopwatch.CurrentTime
end

return Stopwatch
