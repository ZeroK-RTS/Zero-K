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

local extendedCursors = {
	cursorattack = true,
	cursorwait   = true,
	cursordgun   = true,
	cursorpatrol = true,
	cursorrepair = true,
	cursorwait   = true,
}

local function ShowCursor (useExtended)
	for i = 1, #cursorNames do
		local cursor = cursorNames[i]

		local cursorPath = cursor
		if (useExtended and extendedCursors[cursor]) then
			cursorPath = "zk_large/" .. cursorPath
		end

		Spring.ReplaceMouseCursor (cursor, cursorPath)
	end
end

local function HideCursor ()
	for i = 1, #cursorNames do
		Spring.ReplaceMouseCursor(cursorNames[i], "cursorempty")
	end
end

options_path = 'Settings/Interface/Mouse Cursor'
options = {
	cursor_animated = {
		name = 'Extended cursor animation',
		desc = 'Some cursors get more varied animations. WARNING: won\'t render cursors at all on some older graphics cards!',
		type = 'bool',
		value = false,
		OnChange = function (self)
			if not Spring.IsGUIHidden() then
				ShowCursor (self.value)
			end
		end,
		noHotkey = true,
	}
}

include("keysym.h.lua")
function widget:KeyPress(key, modifier, isRepeat)
	if (key ~= KEYSYMS.F5) then
		return
	end

	if Spring.IsGUIHidden() then
		ShowCursor (options.cursor_animated.value)
	else
		HideCursor ()
	end
end
