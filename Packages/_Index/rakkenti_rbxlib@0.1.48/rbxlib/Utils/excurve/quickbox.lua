--[[

@Rakken / rakken on diiscord
Simple hitbox generation module.

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
 
 
   ____   _    _  _____  _____  _  __ ____    ____ __   __
  / __ \ | |  | ||_   _|/ ____|| |/ /|  _ \  / __ \\ \ / /
 | |  | || |  | |  | | | |     | ' / | |_) || |  | |\ V / 
 | |  | || |  | |  | | | |     |  <  |  _ < | |  | | > <  
 | |__| || |__| | _| |_| |____ | . \ | |_) || |__| |/ . \ 
  \___\_\ \____/ |_____|\_____||_|\_\|____/  \____//_/ \_\

-- There are definitely better collision hitbox modules out there, but this one is also good for simple projectiles.
-- Uses spatial queries. Not raycasts.

<---------------------------------------------------------------------------------->

]]

local RunService = game:GetService("RunService")

local Quickbox = {}
Quickbox.__index = Quickbox

function Quickbox.new(subject: Instance, oparams: OverlapParams)
	if subject:IsA("Model") then
		if not subject.PrimaryPart then
			warn(`[{subject}] has no PrimaryPart. Cannot make hitbox.`)
			return
		end
	end
	local self = setmetatable({}, Quickbox)
	self.subject = subject
	if subject:IsA("Model") then
		self.subject = subject.PrimaryPart
	end
	self.connection = nil
	self.oparams = oparams or OverlapParams.new()
	return self
end

function Quickbox:Start(callback: (typeof(Quickbox.new(...)), { BasePart }, any) -> nil, ...: any)
	if self.connection then
		warn(`[Quickbox] Hitbox already started.`)
		return
	end

	local part = self.subject :: BasePart
	local oparams = self.oparams
	local e_args = { ... }

	self.connection = RunService.Heartbeat:Connect(function()
		local hits = game.Workspace:GetPartsInPart(part, oparams)
		if #hits > 0 then
			callback(self, hits, unpack(e_args))
		end
	end)
end

function Quickbox:Stop()
	if self.connection then
		self.connection:Disconnect()
		return true
	end
	warn(`[Quickbox] Hitbox already stopped.`)
	return false
end

function Quickbox:Destroy()
	if self.connection then
		self.connection:Disconnect()
	end
	self.subject = nil
	self.oparms = nil
	table.clear(self)
	setmetatable(self, nil)
	return true
end

local isLoaded = false
if not isLoaded then
	isLoaded = true
	warn([[
	wdw
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |    ___       | || | _____  _____ | || |     _____    | || |     ______   | || |  ___  ____   | || |   ______     | || |     ____     | || |  ____  ____  | |
| |  .'   '.     | || ||_   _||_   _|| || |    |_   _|   | || |   .' ___  |  | || | |_  ||_  _|  | || |  |_   _ \    | || |   .'    `.   | || | |_  _||_  _| | |
| | /  .-.  \    | || |  | |    | |  | || |      | |     | || |  / .'   \_|  | || |   | |_/ /    | || |    | |_) |   | || |  /  .--.  \  | || |   \ \  / /   | |
| | | |   | |    | || |  | '    ' |  | || |      | |     | || |  | |         | || |   |  __'.    | || |    |  __'.   | || |  | |    | |  | || |    > `' <    | |
| | \  `-'  \_   | || |   \ `--' /   | || |     _| |_    | || |  \ `.___.'\  | || |  _| |  \ \_  | || |   _| |__) |  | || |  \  `--'  /  | || |  _/ /'`\ \_  | |
| |  `.___.\__|  | || |    `.__.'    | || |    |_____|   | || |   `._____.'  | || | |____||____| | || |  |_______/   | || |   `.____.'   | || | |____||____| | |
| |              | || |              | || |              | || |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                                                                                                                     
@Rakken
Discord/rakken
	]])
end

return Quickbox
