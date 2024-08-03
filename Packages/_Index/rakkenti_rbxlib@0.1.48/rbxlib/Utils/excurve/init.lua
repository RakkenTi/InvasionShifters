local isLoaded = false
if not isLoaded then
	isLoaded = true
	warn([[
	
	
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


@Rakken
Discord/rakken
	
	
	]])
end

--[[

<---------------------------------------------------------------------------------->
ExFloat.NewAnchor(debugMode)
-- Generates a simple single stud anchor to use for the path for a curve. Not necessary to use. Used primarily for debugging.
-- Part is not automatically parented to workspace, and is invisible by DEFAULT.
-- Moreso for debugging, if debugMode is true, the part becomes visible.

]]

return {
	["Float"] = require(script.float),
	["Bezier"] = require(script.bezier),
	["Quickbox"] = require(script.quickbox),
	NewAnchor = function(debugMode: boolean | "If true, anchor parts will be visible.")
		local part = Instance.new("Part")
		part.Transparency = debugMode and 0 or 1
		part.CanCollide = false
		part.Anchored = true
		part.Size = Vector3.new(1, 1, 1)
		part.BrickColor = BrickColor.new("Black")
		return part
	end,
}
