function widget:GetInfo()
  return {
    name      = "Custom Cursor Sets",
    desc      = "v1.003 Choose different cursor sets.",
    author    = "CarRepairer",
    date      = "2012-01-11",
    license   = "GNU GPL, v2 or later",
    layer     = -100000,
    handler   = true,
    experimental = false,	
    enabled   = true,
	alwaysStart = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local echo = Spring.Echo

--------------------------------------------------------------------------------

function RestoreCursor() end
function SetCursor(cursorSet) end

options_path = 'Settings/Interface/Mouse Cursor'
options = {
	cursor_animated = {
		name = 'Extended cursor animation',
		desc = 'Some cursors get more varied animations. WARNING: won\'t render cursors at all on some older graphics cards!',
		type = 'bool',
		value = false,
		OnChange = function (self) 
			if not self.value then
				RestoreCursor()
			else
				SetCursor('zk_large'); 
			end
		end,
		noHotkey = true,
	}
}

--------------------------------------------------------------------------------
include("keysym.h.lua")
--------------------------------------------------------------------------------
--Mouse cursor icons

local cursorNames = {
  'cursornormal',
  'cursorareaattack',
  'cursorattack',
  'cursorbuildbad',
  'cursorbuildgood',
  'cursorcapture',
  'cursorcentroid',
  'cursordwatch',
  'cursorwait',
  'cursordgun',
  'cursorfight',
  'cursorgather',
  'cursordefend',
  'cursorpickup',
  'cursormove',
  'cursorpatrol',
  'cursorreclamate',
  'cursorrepair',
  'cursorrevive',
  'cursorrestore',
  'cursorselfd',
  'cursornumber',
  'cursortime',
  'cursorunload',
}

SetCursor = function(cursorSet)
  for _, cursor in ipairs(cursorNames) do
    local topLeft = (cursor == 'cursornormal' and cursorSet ~= 'k_haos_girl')
    Spring.ReplaceMouseCursor(cursor, cursorSet.."/"..cursor, topLeft)
  end
end

RestoreCursor = function()
  for _, cursor in ipairs(cursorNames) do
    local topLeft = (cursor == 'cursornormal')
    Spring.ReplaceMouseCursor(cursor, cursor, topLeft)
  end
end



----------------------

 
 
 function widget:KeyPress(key, modifier, isRepeat)
	if ( key == KEYSYMS.F5) then
		if Spring.IsGUIHidden() then
			
			if not options.cursor_animated.value then
				RestoreCursor()
			else
				SetCursor( 'zk_large' )
			end
			
		else
			
			
			for i=1, #cursorNames do
				local cursor = cursorNames[i]
				local topLeft = (cursor == 'cursornormal' and cursorSet ~= 'k_haos_girl')
				Spring.ReplaceMouseCursor(cursor, "empty/"..cursor, topLeft)
			end
		end 
	end 
 end

 

 
----------------------
