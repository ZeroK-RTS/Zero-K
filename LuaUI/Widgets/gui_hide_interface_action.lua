function widget:GetInfo() 
	return {
		name        = "Hide Interface Action",
		desc        = "Implements a hide interface action that also hides mouse cursor.",
		author      = "CarRepairer",
		date        = "2012-01-11",
		license     = "GNU GPL, v2 or later",
		layer       = -100000,
		enabled     = true,
		alwaysStart = true,
	} 
end

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

function widget:Update()
	WG.crude.SetHotkey("HideInterface")
	widgetHandler:RemoveCallIn("Update")
end

options_path = 'Settings/HUD Panels/Extras'

options = {
	hideinterfaceandcursor = {
		name = 'Hide Interface',
		desc = 'Toggle to show/hide the interface and mouse cursor.',
		hotkey = {key = 'f5', mod = ''},
		type = 'button',
		action = 'hideinterfaceandcursor',
		noAutoControlFunc = true,
		OnChange = function(self)
			Spring.SendCommands("HideInterface")
			if Spring.IsGUIHidden() then
				HideCursor()
			else
				ShowCursor()
			end
		end,
	},
}
