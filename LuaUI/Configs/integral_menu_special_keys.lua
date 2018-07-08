local specialKeys = {
	["`"] = KEYSYMS.BACKQUOTE,
	["-"] = KEYSYMS.MINUS,
	["="] = KEYSYMS.EQUALS,
	["\\"] = KEYSYMS.BACKSLASH,
	["["] = KEYSYMS.LEFTBRACKET,
	["]"] = KEYSYMS.RIGHTBRACKET,
	[";"] = KEYSYMS.SEMICOLON,
	["'"] = KEYSYMS.QUOTE,
	[","] = KEYSYMS.COMMA,
	["."] = KEYSYMS.PERIOD,
	["/"] = KEYSYMS.SLASH,
	["numpad0"] = KEYSYMS.KP0,
	["numpad1"] = KEYSYMS.KP1,
	["numpad2"] = KEYSYMS.KP2,
	["numpad3"] = KEYSYMS.KP3,
	["numpad4"] = KEYSYMS.KP4,
	["numpad5"] = KEYSYMS.KP5,
	["numpad6"] = KEYSYMS.KP6,
	["numpad7"] = KEYSYMS.KP7,
	["numpad8"] = KEYSYMS.KP8,
	["numpad9"] = KEYSYMS.KP9,
	["numpad."] = KEYSYMS.KP_PERIOD,
	["numpad/"] = KEYSYMS.KP_DIVIDE,
	["numpad*"] = KEYSYMS.KP_MULTIPLY,
	["numpad+"] = KEYSYMS.KP_PLUS,
	["numpad-"] = KEYSYMS.KP_MINUS,
	["numlock"] = KEYSYMS.NUMLOCK,
	["pause"] = KEYSYMS.BREAK,
}

local function ToKeysyms(key)
	if not key then
		return
	end
	key = string.upper(key)
	key = string.gsub(key, "ANY%+", "")
	if tonumber(key) then
		return KEYSYMS["N_" .. key]
	end
	local keyCode = KEYSYMS[string.upper(key)]
	return keyCode or specialKeys[key]
end

return specialKeys, ToKeysyms
