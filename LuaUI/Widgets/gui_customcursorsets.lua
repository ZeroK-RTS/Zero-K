function widget:GetInfo() return {
	name        = "Custom Cursor Sets",
	desc        = "v1.003 Choose different cursor sets.",
	author      = "CarRepairer",
	date        = "2012-01-11",
	license     = "GNU GPL, v2 or later",
	layer       = -100000,
	enabled     = true,
	alwaysStart = true,
} end

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
	'cursorLevel',
	'cursorRaise',
	'cursorRamp',
	'cursorRestore2',
	'cursorSmooth',
}

local function ShowCursor ()
	for i = 1, #cursorNames do
		local cursor = cursorNames[i]
		Spring.ReplaceMouseCursor (cursor, cursor)
	end
end

local function HideCursor ()
	for i = 1, #cursorNames do
		Spring.ReplaceMouseCursor(cursorNames[i], "cursorempty")
	end
end

include("keysym.h.lua")
local KEYSYMS_F5 = KEYSYMS.F5
function widget:KeyPress(key, modifier, isRepeat)
	if (key ~= KEYSYMS_F5) then
		return
	end

	if Spring.IsGUIHidden() then
		ShowCursor ()
	else
		HideCursor ()
	end
end
