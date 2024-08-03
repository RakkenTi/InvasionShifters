--[[

[OLD MODULE]
@Rakken / rakken on diiscord
Experimental Curve Generation Module
Bezier Curve Version



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
 
 

  ____   ______  ______ _____  ______  _____    _____  _    _  _____ __      __ ______   _____ 
 |  _ \ |  ____||___  /|_   _||  ____||  __ \  / ____|| |  | ||  __ \\ \    / /|  ____| / ____|
 | |_) || |__      / /   | |  | |__   | |__) || |     | |  | || |__) |\ \  / / | |__   | (___  
 |  _ < |  __|    / /    | |  |  __|  |  _  / | |     | |  | ||  _  /  \ \/ /  |  __|   \___ \ 
 | |_) || |____  / /__  _| |_ | |____ | | \ \ | |____ | |__| || | \ \   \  /   | |____  ____) |
 |____/ |______|/_____||_____||______||_|  \_\ \_____| \____/ |_|  \_\   \/    |______||_____/                                        


-- Should probably use Zonito's module if you are going to use parts. This is moreso for models.
-- Only for cubic and quadratic.

<---------------------------------------------------------------------------------->


]]

local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local debug_mode = script:GetAttribute("DEBUG_MODE") or false

local ExBezier = {
	Completed = {},
}
ExBezier.__index = ExBezier

function ExBezier:Lerp(a, b, c)
	return a + (b - a) * c
end

function ExBezier:GetPositionAtT(t: number)
	if self.curvetype == "Cubic" then
		local l1 = self:Lerp(self.p0, self.p1, t)
		local l2 = self:Lerp(self.p1, self.p2, t)
		local l3 = self:Lerp(self.p2, self.p3, t)
		local qa = self:Lerp(l1, l2, t)
		local qb = self:Lerp(l2, l3, t)
		local cubic = self:Lerp(qa, qb, t)
		return cubic
	end
	if self.curvetype == "Quadratic" then
		local l1 = self:Lerp(self.p0, self.p1, t)
		local l2 = self:Lerp(self.p1, self.p2, t)
		local quadratic = self:Lerp(l1, l2, t)
		return quadratic
	end
	return false
end

function ExBezier.new(
	instance,
	p0: Vector3,
	p1: Vector3,
	p2: Vector3,
	p3: Vector3 | "If p3, is specified, this becomes a cubic bezier curve."?
)
	local self = setmetatable({}, ExBezier)
	self.p0 = p0
	self.p1 = p1
	self.p2 = p2
	if p3 then
		self.p3 = p3
		self.curvetype = "Cubic"
	else
		self.curvetype = "Quadratic"
	end
	self.alpha = 0
	self.connection = nil
	self.Completed.isOnceRan = false
	self.Completed.isCompleted = false
	self.instance = instance
	return self
end

function ExBezier:Play(
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection,
	speed: number | "Speed multiplier for instance on bezier curve. Default is 1."
)
	if self.alpha >= 1 then
		self.alpha = 0
	end

	if self.connection then
		self.connection:Disconnect()
	end

	self.Cancel = false

	self.connection = RunService.Heartbeat:Connect(function(deltaTime)
		if debug_mode then
			if game.Workspace:FindFirstChild("excurve_bezier_v") then
				game.Workspace:FindFirstChild("excurve_bezier_v"):Destroy()
			end
			local debug_folder = Instance.new("Folder")
			debug_folder.Name = "excurve_bezier_v"
			debug_folder.Parent = game.Workspace
			local resolution = script:GetAttribute("DEBUG_RESOLUTION")
			for i = 0, 1, 1 / resolution do
				local cube = Instance.new("Part")
				cube.Size = Vector3.new(1, 1, 1)
				cube.Position = self:GetPositionAtT(i)
				cube.Anchored = true
				cube.CanCollide = false
				cube.Color = Color3.fromRGB(255, 147, 23)
				cube.Parent = debug_folder
			end
		end

		if self.Cancel then
			if self.connection then
				self.connection:Disconnect()
			end
		end

		self.alpha += deltaTime * (speed or 1)

		if self.alpha >= 1 then
			self.Completed.isCompleted = true
			return
		end

		local true_alpha =
			TS:GetValue(self.alpha, style or Enum.EasingStyle.Linear, direction or Enum.EasingDirection.Out)
		self.instance:PivotTo(CFrame.new(self:GetPositionAtT(true_alpha)))
	end)
end

function ExBezier:Destroy()
	if game.Workspace:FindFirstChild("excurve_bezier_v") then
		game.Workspace:FindFirstChild("excurve_bezier_v"):Destroy()
	end
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	setmetatable(self, nil)
	table.clear(self)
	self = nil
	return true
end

function ExBezier.Completed:Wait()
	repeat
		task.wait()
	until self.isCompleted == true
	return true
end

function ExBezier.Completed:Connect(callback: (number) -> nil)
	repeat
		task.wait()
	until self.isCompleted == true
	callback(tick())
	return true
end

function ExBezier.Completed:Once(callback: (number) -> nil)
	repeat
		task.wait()
	until self.isCompleted == true
	if not self.isOnceRan then
		self.isOnceRan = true
		callback(tick())
	end
	return false
end

function ExBezier:Stop()
	self.Cancel = false
	self.Completed.isOnceRan = false
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	self.alpha = 0
end

function ExBezier:Pause()
	self.Cancel = true
end

local isLoaded = false
if not isLoaded then
	isLoaded = true
	warn(
		[[                                                                                                                                                                                                                                              
    ,---,.                                                      ,----..                                                         
  ,'  .'  \                         ,--,                       /   /   \                                                        
,---.' .' |                 ,----,,--.'|               __  ,-.|   :     :         ,--,   __  ,-.                                
|   |  |: |               .'   .`||  |,              ,' ,'/ /|.   |  ;. /       ,'_ /| ,' ,'/ /|    .---.            .--.--.    
:   :  :  /   ,---.    .'   .'  .'`--'_       ,---.  '  | |' |.   ; /--`   .--. |  | : '  | |' |  /.  ./|   ,---.   /  /    '   
:   |    ;   /     \ ,---, '   ./ ,' ,'|     /     \ |  |   ,';   | ;    ,'_ /| :  . | |  |   ,'.-' . ' |  /     \ |  :  /`./   
|   :     \ /    /  |;   | .'  /  '  | |    /    /  |'  :  /  |   : |    |  ' | |  . . '  :  / /___/ \: | /    /  ||  :  ;_     
|   |   . |.    ' / |`---' /  ;--,|  | :   .    ' / ||  | '   .   | '___ |  | ' |  | | |  | '  .   \  ' ..    ' / | \  \    `.  
'   :  '; |'   ;   /|  /  /  / .`|'  : |__ '   ;   /|;  : |   '   ; : .'|:  | : ;  ; | ;  : |   \   \   ''   ;   /|  `----.   \ 
|   |  | ; '   |  / |./__;     .' |  | '.'|'   |  / ||  , ;   '   | '/  :'  :  `--'   \|  , ;    \   \   '   |  / | /  /`--'  / 
|   :   /  |   :    |;   |  .'    ;  :    ;|   :    | ---'    |   :    / :  ,      .-./ ---'      \   \ ||   :    |'--'.     /  
|   | ,'    \   \  / `---'        |  ,   /  \   \  /           \   \ .'   `--`----'                '---"  \   \  /   `--'---'   
`----'       `----'                ---`-'    `----'             `---`                                      `----'                                                                                                                                            
@Rakken
Discord/rakken
	]]
	)
end

return ExBezier
