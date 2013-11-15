function widget:GetInfo()
  return {
    name      = "Custom Cursor Sets",
    desc      = "v1.0 Choose different cursor sets.",
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
		type = 'list',
		OnChange = function (self) 
			if self.value == 'zk' then
				RestoreCursor()
			else
				SetCursor( self.value ); 
			end
		end,
		items = {
			{ key = 'zk', name = 'Animated', },
			{ key = 'zk_static', name = 'Static', },
			{ key = 'ca', name = 'CA Classic', },
			{ key = 'ca_static', name = 'CA Static', },
			{ key = 'erom', name = 'Erom', },
			{ key = 'masse', name = 'Masse', },
			{ key = 'Lathan', name = 'Lathan', },
			{ key = 'k_haos_girl', name = 'K_haos_girl', },
		},
		value = 'zk',
	}
}


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
