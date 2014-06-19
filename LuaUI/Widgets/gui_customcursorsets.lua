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
	cursorsets = {
		name = 'Cursor Sets',
		type = 'radioButton',
		OnChange = function (self) 
			if self.value == 'zk' then
				RestoreCursor()
			else
				SetCursor( self.value ); 
			end
		end,
		items = {
			{ key = 'zk', name = 'Animated', 		icon='anims/cursornormal_0.png' },
			{ key = 'zk_static', name = 'Static', 	icon='anims/cursornormal_0.png' },
			{ key = 'ca', name = 'CA Classic', 		icon='anims/ca/cursornormal_0.png' },
			{ key = 'ca_static', name = 'CA Static', 		icon='anims/ca/cursornormal_0.png' },
			{ key = 'erom', name = 'Erom', 			icon='anims/erom/cursornormal_0.png' },
			{ key = 'masse', name = 'Masse', 		icon='anims/masse/cursornormal_0.png' },
			{ key = 'Lathan', name = 'Lathan', 		icon='anims/lathan/cursornormal_0.png' },
			{ key = 'k_haos_girl', name = 'K_haos_girl', 	icon='anims/k_haos_girl/cursornormal_0.png' },
		},
		value = 'zk',
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
			
			if options.cursorsets.value == 'zk' then
				RestoreCursor()
			else
				SetCursor( options.cursorsets.value )
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
