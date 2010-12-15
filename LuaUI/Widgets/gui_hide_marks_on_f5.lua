function widget:GetInfo()
  return {
    name      = "Hide map marks",
    desc      = "Hides map marks on f5",
    author    = "who cares",
    date      = "dec, 2010",
    license   = "PD, anything else would be uncilized",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
include("keysym.h.lua")

function widget:KeyPress(key, modifier, isRepeat)
	if ( key == KEYSYMS.F5) then
		if Spring.IsGUIHidden() then
			Spring.SendCommands("mapmarks 1")
		else
			Spring.SetMouseCursor("none")
			Spring.SendCommands("mapmarks 0")
		end 
	end 
 end

 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------