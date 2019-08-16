function widget:GetInfo()
	return {
		name        = "Hide Interface and Mouse Cursor",
		desc        = "Implements a hide interface action as well as mouse cursor sets.",
		author      = "CarRepairer",
		date        = "2012-01-11",
		license     = "GNU GPL, v2 or later",
		layer       = -100000,
		enabled     = true,
		alwaysStart = true,
	}
end

include("keysym.h.lua")

local cursorDir = ""

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

local function ShowCursor()
	for i = 1, #cursorNames do
		local cursor = cursorNames[i]
		local cursorPath = cursorDir .. cursor
		Spring.ReplaceMouseCursor(cursor, cursorPath)
	end
end

local function HideCursor()
	for i = 1, #cursorNames do
		Spring.ReplaceMouseCursor(cursorNames[i], "cursorempty")
	end
end

function widget:Update()
	WG.crude.SetHotkey("HideInterface")
	widgetHandler:RemoveCallIn("Update")
end

options_path = 'Settings/HUD Panels/Extras'

options = {
	hideinterfaceandcursor = {
		name = 'Hide Interface',
		desc = 'Toggle to show/hide the interface and mouse cursor.',
		hotkey = {key = 'f5', mod = 'C'},
		type = 'button',
		action = 'hideinterfaceandcursor',
		noAutoControlFunc = true,
		path = 'Hotkeys/Misc',
		OnChange = function(self)
			Spring.SendCommands("HideInterface")
			if Spring.IsGUIHidden() then
				HideCursor()
			else
				ShowCursor()
			end
		end,
	},
	cursor_animated = {
		name = 'Large cursor',
		desc = 'Double cursor size. WARNING: won\'t render cursors at all on some older graphics cards!',
		type = 'bool',
		value = false,
		OnChange = function (self)
			cursorDir = (self.value and "zk_large/") or ""
			if not Spring.IsGUIHidden() then
				ShowCursor()
			end
		end,
		path = 'Settings/Interface/Mouse Cursor'
	},
}

function WG.SetCursorVisibility(visible)
	if visible then
		ShowCursor()
	else
		HideCursor()
	end
end

function WG.ShowInterface()
	if Spring.IsGUIHidden() then
		Spring.SendCommands("HideInterface")
		ShowCursor()
	end
end

function WG.HideInterface()
	if not Spring.IsGUIHidden() then
		Spring.SendCommands("HideInterface")
		HideCursor()
	end
end

function widget:KeyPress(key)
	if key == KEYSYMS.ESCAPE then
		WG.ShowInterface()
	end
end
