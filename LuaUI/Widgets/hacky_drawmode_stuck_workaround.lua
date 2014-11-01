function widget:GetInfo()
	return {
		name      = "Drawmove Stuck Workaround",
		desc      = "Fixes most cases of the 'stuck in drawing move' bug.",
		author    = "silentwings",
		date      = "11 October 2014",
		license   = "Public Domain",
		layer     = 100000,
		enabled   = true 
	}
end

-- See http://springrts.com/mantis/view.php?id=4455
include('keysym.h.lua')
local BACKQUOTE = KEYSYMS.BACKQUOTE
local BACKSLASH = KEYSYMS.BACKSLASH
local PAR = KEYSYMS.WORLD_23
local RETURN = KEYSYMS.RETURN
function widget:KeyPress(key, mods, isRepeat)
    if key == RETURN and (Spring.GetKeyState(BACKQUOTE) or Spring.GetKeyState(BACKSLASH) or Spring.GetKeyState(PAR)) then
        return true
    end
end

function widget:Initialize()
	if (Game.version:find('91.0') == 1) then
		widgetHandler:RemoveWidget()
	end
end