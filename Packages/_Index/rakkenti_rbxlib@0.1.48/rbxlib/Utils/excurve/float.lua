--[[

@Rakken / rakken on diiscord
OLD MODULE [made a year ago]
WTF IS THIS CODE
Experimental Curve Generation Module
Float Cruve Version



    ,---,.              ,----..                                                       
  ,'  .' |             /   /   \                                                      
,---.'   |            |   :     :         ,--,  __  ,-.                               
|   |   .' ,--,  ,--, .   |  ;. /       ,'_ /|,' ,'/ /|    .---.           .--.--.    
:   :  |-, |'. \/ .`| .   ; /--`   .--. |  | :'  | |' |  /.  ./|  ,---.   /  /    '   
:   |  ;/| '  \/  / ; ;   | ;    ,'_ /| :  . ||  |   ,'.-' . ' | /     \ |  :  /`./   
|   :   .'  \  \.' /  |   : |    |  ' | |  . .'  :  / /___/ \: |/    /  ||  :  ;_     
|   |  |-,   \  ;  ;  .   | '___ |  | ' |  | ||  | '  .   \  ' .    ' / | \  \    `.  
'   :  ;/|  / \  \  \ '   ; : .'|:  | : ;  ; |;  : |   \   \   '   ;   /|  `----.   \ 
|   |    \./__;   ;  \'   | '/  :'  :  `--'   \  , ;    \   \  '   |  / | /  /`--'  / 
|   :   .'|   :/\  \ ;|   :    / :  ,      .-./---'      \   \ |   :    |'--'.     /  
|   | ,'  `---'  `--`  \   \ .'   `--`----'               '---" \   \  /   `--'---'   
`----'                  `---`                                    `----'               



  _____ _____ _____ _______ _____ ____  _   _          _______     __
 |  __ \_   _/ ____|__   __|_   _/ __ \| \ | |   /\   |  __ \ \   / /
 | |  | || || |       | |    | || |  | |  \| |  /  \  | |__) \ \_/ / 
 | |  | || || |       | |    | || |  | | . ` | / /\ \ |  _  / \   /  
 | |__| || || |____   | |   _| || |__| | |\  |/ ____ \| | \ \  | |   
 |_____/_____\_____|  |_|  |_____\____/|_| \_/_/    \_\_|  \_\ |_|   


  ______  _       ____         _______  _____  _    _  _____ __      __ ______   _____ 
 |  ____|| |     / __ \    /\ |__   __|/ ____|| |  | ||  __ \\ \    / /|  ____| / ____|
 | |__   | |    | |  | |  /  \   | |  | |     | |  | || |__) |\ \  / / | |__   | (___  
 |  __|  | |    | |  | | / /\ \  | |  | |     | |  | ||  _  /  \ \/ /  |  __|   \___ \ 
 | |     | |____| |__| |/ ____ \ | |  | |____ | |__| || | \ \   \  /   | |____  ____) |
 |_|     |______|\____//_/    \_\|_|   \_____| \____/ |_|  \_\   \/    |______||_____/ 
                                                                                       
                                                                                       

-- Note, I may use "path" and "curve" interchangeably here.


<---------------------------------------------------------------------------------->
ExFloat.New(part, orderedPositions, speed)
-- Creates new ExFloat path. Takes in a model or path, ordered array of positions, and a set speed.
-- The path will move smoothly through the positions, at the given speed.
-- The path can be manually moved using ExFloat:Step(), or automatically moved, like a tween, using ExFloat:Play()
-- Speed determines the amount of time it takes to complete this curve.

<---------------------------------------------------------------------------------->
ExFloat:Play(style, direction, special_factor, useRunService)
-- Plays the ExFloat path automatically using either a for loop or Heartbeat. Arguments are: style, direction, special_factor and useRunService.
-- Style is Enum.EasingStyle, same use as tweening. If no style, and direction are given, it will assume a linear path.
-- special_factor is used but not necessary if useRunService is not set to true. The default number is 0.01, and it is used in the for loop as the incremental number. Ex: for i = 0.01, 5, special_factor (0.01)
-- useRunService determines if Heartbeat is used to play the path or not. True will use it, false will not.

<---------------------------------------------------------------------------------->
ExFloat:Step(time_index, style, direction)
-- Alternative to ExFloat. Used for higher level of customization. If the client/server is already running Heartbeat, they should probably use this instead
-- Time_index is a value that represents where the instance being moved through the path will be at. It is like the alpha, but not a value of 0-1, but a value from 0-MaxAlphaTime.
-- MaxAlphaTime is the maximum time that it will take for the instance to go from start to finish. For example, it will take 5 seconds to complete a path.
-- MaxAlphaTime is determined by the speed set in ExFloat.New
-- Style and direction work the same as in ExFloat:Play(). They are not necessary

<---------------------------------------------------------------------------------->
ExFloat.Completed:Wait()
-- Yields until the path time index has travelled through 100% of the path. Basically resumes when the path is fully traversed. | self.isCompleted == true

<---------------------------------------------------------------------------------->S
ExFloat.Completed:Connect(callback)
-- Same conditions as ExFloat.Completed:Wait(), however runs the function inside the parameter. Can be ran multiple times | self.isCompleted == true

<---------------------------------------------------------------------------------->S
ExFloat.Completed:Once(callback)
-- Same conditions as ExFloat.Completed:Wait(), however runs the function inside the parameter. Can be ran multiple times | self.isCompleted == true
-- TIP: Useful for when manually moving the path through ExFloat:Step() instead of ExFloat:Play()

<---------------------------------------------------------------------------------->S
ExFloat:AdjustSpeed(Speed)
-- Changes the speed of the curve.
-- Does this by rebuilding the path using the same positions and recalculating the MaxAlphaTime using the new speed

<---------------------------------------------------------------------------------->
ExFloat:Destroy(destroyInstance)
-- Destroys the object and Connections
-- Cleans up the metatables

<---------------------------------------------------------------------------------->
ExFloat:Stop()
-- Stops the curve.
-- RESETS the curve.

<---------------------------------------------------------------------------------->
ExFloat:Pause()
-- Stops the curve.
-- DOES NOT RESET the curve.
-- Can continue using :Play()

]]

local RunService = game:GetService("RunService")

local ExFloat = {
	Completed = {},
}

local tag = "[ExFloats]"

ExFloat.__index = ExFloat

function ExFloat.new(part: Model | BasePart, orderedPositions: {}, speed: number)
	local self = setmetatable({}, ExFloat)

	self.instance = part
	self.instance:PivotTo(CFrame.new(orderedPositions[1]))
	self._storedpos = orderedPositions
	self._storedspeed = speed
	self.Completed.isOnceRan = false
	self.Completed.isCompleted = false

	self.Curve = Instance.new("Vector3Curve")
	local x = self.Curve:X()
	local y = self.Curve:Y()
	local z = self.Curve:Z()

	self.PathAlpha = 0

	for i, p in orderedPositions do
		if i > 1 then
			self.PathAlpha += (p - orderedPositions[i - 1]).Magnitude / speed
		end
		x:InsertKey(FloatCurveKey.new(self.PathAlpha, p.X, Enum.KeyInterpolationMode.Cubic))
		y:InsertKey(FloatCurveKey.new(self.PathAlpha, p.Y, Enum.KeyInterpolationMode.Cubic))
		z:InsertKey(FloatCurveKey.new(self.PathAlpha, p.Z, Enum.KeyInterpolationMode.Cubic))
	end

	return self
end

function ExFloat:Step(time_index: number, style: Enum.EasingStyle, direction: Enum.EasingDirection)
	if time_index >= self.PathAlpha or self.Completed.isCompleted == true then
		self.Completed.isCompleted = true
		self.storedtimeindex = nil
		return true
	end
	if self.Cancel then
		self.Cancel = false
		self.storedtimeindex = time_index
		return true
	end
	if not style and not direction and not self.Completed.isCompleted then
		self.instance:PivotTo(CFrame.new(Vector3.new(table.unpack(self.Curve:GetValueAtTime(time_index)))))
	elseif style and not self.Completed.isCompleted then
		local alpha = time_index / self.PathAlpha
		self.instance:PivotTo(CFrame.new(Vector3.new(table.unpack(self.Curve:GetValueAtTime(self.PathAlpha * alpha)))))
	else
		warn(`{tag} Invalid arguments passed. Cannot play path.`)
		return false
	end
end

function ExFloat:Play(
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection,
	special_factor: number, -- Recommended value is between 0.01 and 0.1. Used for the for loop. Set to false to ignore
	useRunService: boolean -- "Determines if Heartbeat is used to play the path."
)
	self.Completed.isCompleted = false
	self.Completed.isOnceRan = false

	if useRunService == true then
		local time_index = self.storedtimeindex or 0

		self.beat = RunService.Heartbeat:Connect(function(delta)
			time_index += delta / 1.6676
			if time_index >= self.PathAlpha or self.Completed.isCompleted == true then
				self.Completed.isCompleted = true
				self.storedtimeindex = nil
				self.beat:Disconnect()
				return true
			end
			if self.Cancel then
				self.Cancel = false
				self.storedtimeindex = time_index
				if self.beat then
					self.beat:Disconnect()
				end
				return true
			end
			if not style and not direction and not self.Completed.isCompleted then
				self.instance:PivotTo(CFrame.new(Vector3.new(table.unpack(self.Curve:GetValueAtTime(time_index)))))
			elseif style and not self.Completed.isCompleted then
				local alpha = time_index / self.PathAlpha
				self.instance:PivotTo(
					CFrame.new(Vector3.new(table.unpack(self.Curve:GetValueAtTime(self.PathAlpha * alpha))))
				)
			else
				warn(`{tag} Invalid arguments passed. Cannot play path.`)
				return false
			end
			self.storedtimeindex = time_index
			task.wait()
		end)
		return
	end

	task.spawn(function()
		for time_index = self.storedtimeindex or 0, self.PathAlpha, special_factor or 0.01 do
			if self.Cancel then
				self.Cancel = false
				return
			end
			task.wait()
			if not style and not direction then
				self.instance:PivotTo(CFrame.new(Vector3.new(table.unpack(self.Curve:GetValueAtTime(time_index)))))
			elseif style then
				local alpha = time_index / self.PathAlpha
				self.instance:PivotTo(
					CFrame.new(Vector3.new(table.unpack(self.Curve:GetValueAtTime(self.PathAlpha * alpha))))
				)
			else
				warn(`{tag} Invalid arguments passed. Cannot play path.`)
				return false
			end
		end
		self.Completed.isCompleted = true
		self.storedtimeindex = nil
		return true
	end)
end

function ExFloat.Completed:Wait()
	repeat
		task.wait()
	until self.isCompleted == true
	return true
end

function ExFloat.Completed:Connect(callback: (number) -> nil)
	repeat
		task.wait()
	until self.isCompleted == true
	callback(tick())
	return true
end

function ExFloat.Completed:Once(callback: (number) -> nil)
	repeat
		task.wait()
	until self.isCompleted == true
	if not self.isOnceRan then
		self.isOnceRan = true
		callback(tick())
	end
	return false
end

function ExFloat:AdjustSpeed(Speed: number | "This will rebuild the path and set the speed to the new one.")
	self.Curve = Instance.new("Vector3Curve")
	self._storedspeed = Speed
	local x = self.Curve:X()
	local y = self.Curve:Y()
	local z = self.Curve:Z()

	self.PathAlpha = 0

	for i, p in self._storedpos do
		if i > 1 then
			self.PathAlpha += (p - self._storedpos[i - 1]).Magnitude / Speed
		end
		x:InsertKey(FloatCurveKey.new(self.PathAlpha, p.X, Enum.KeyInterpolationMode.Cubic))
		y:InsertKey(FloatCurveKey.new(self.PathAlpha, p.Y, Enum.KeyInterpolationMode.Cubic))
		z:InsertKey(FloatCurveKey.new(self.PathAlpha, p.Z, Enum.KeyInterpolationMode.Cubic))
	end
end

function ExFloat:Destroy(destroyInstance: boolean)
	if destroyInstance then
		self.instance:Destroy()
	end
	self.Curve:Destroy()
	if self.beat then
		self.beat:Disconnect()
	end
	table.clear(self)
	setmetatable(self, nil)
	self = nil
	return nil
end

function ExFloat:Stop()
	self.Cancel = false
	self.storedtimeindex = nil
	self.Completed.isOnceRan = false
end

function ExFloat:Pause()
	self.Cancel = true
end

local isLoaded = false
if not isLoaded then
	isLoaded = true
end

return ExFloat
