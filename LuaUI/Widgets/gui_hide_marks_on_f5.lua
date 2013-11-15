function widget:GetInfo()
  return {
    name      = "Hide map marks and cursor",
    desc      = "Hides map marks and cursor on f5",
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

--------------------------------------------------------------------------------
--Mouse cursor icons

local cursorNames = {
  'cursornormal',
  'cursorareaattack',
  'cursorattack',
  'cursorattack',
  'cursorbuildbad',
  'cursorbuildgood',
  'cursorcapture',
  'cursorcentroid',
  'cursordwatch',
  'cursorwait',
  'cursordgun',
  'cursorattack',
  'cursorfight',
  'cursorattack',
  'cursorgather',
  'cursorwait',
  'cursordefend',
  'cursorpickup',
  'cursormove',
  'cursorpatrol',
  'cursorreclamate',
  'cursorrepair',
  'cursorrevive',
  'cursorrepair',
  'cursorrestore',
  'cursorrepair',
  'cursorselfd',
  'cursornumber',
  'cursorwait',
  'cursortime',
  'cursorwait',
  'cursorunload',
  'cursorwait',
}
  
--------------------------------------------------------------------------------
  
function widget:KeyPress(key, modifier, isRepeat)
	if ( key == KEYSYMS.F5) then
		if Spring.IsGUIHidden() then
			Spring.SendCommands("mapmarks 1")
			for i=1, #cursorNames do
				local cursor = cursorNames[i]
				local topLeft = (cursor == 'cursornormal')
				Spring.ReplaceMouseCursor(cursor, cursor, topLeft)
			end
		else
			Spring.SendCommands("mapmarks 0")
			for i=1, #cursorNames do
				local cursor = cursorNames[i]
				local topLeft = (cursor == 'cursornormal' and cursorSet ~= 'k_haos_girl')
				Spring.ReplaceMouseCursor(cursor, "empty/"..cursor, topLeft)
			end
		end 
	end 
 end

 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------