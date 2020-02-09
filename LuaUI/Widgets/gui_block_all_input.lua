function widget:GetInfo()
	return {
		name      = "Block all input",
		desc      = "Blocks all input (except escape)." ,
		author    = "GoogleFrog",
		date      = "4 November 2018",
		layer     = 0,
		enabled   = true,  --  loaded by default
	}
end

include("keysym.h.lua")
local ACTIVE = true

function widget:MousePress(x,y,button)
	return ACTIVE
end

function widget:MouseRelease(x,y,button)
	return ACTIVE
end

function widget:MouseWheel(up,value)
	return ACTIVE
end

function widget:KeyPress(key, mods, isRepeat, label, unicode)
	if key == KEYSYMS.ESCAPE then
		Spring.SendCommands("quitforce")
	end
	return ACTIVE
end

function widget:KeyRelease()
	return ACTIVE
end
