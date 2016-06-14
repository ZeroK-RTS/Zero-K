-- Do not load this in gadgets
if not WG then
	return
end

local allyContext = {
	display = i18n("ally_context", {default="Team:"}),
	name = "ally",
	persist = true,
	color = config.chat.allyChatColor,
}
local sayContext = {
	display = i18n("say_context", {default="All:"}),
	name = "say",
	persist = true,
	color = config.chat.sayChatColor,
}
local specContext = {
	display = i18n("spec_context", {default="Spec:"}),
	name = "spec",
	persist = true,
	color = config.chat.specChatColor,
}

local function _SetDefaultContext()
	if not Spring.GetSpectatingState() then
		SetDefaultContext(allyContext)
	else
		SetDefaultContext(specContext)
	end
end
_SetDefaultContext()

function PlayerChanged(playerID)
	_SetDefaultContext()
end

local function GetRestrictedChat()
	if not Spring.GetSpectatingState() then
		return allyContext
	else
		return specContext
	end
end

local function CanSpecChat()
	return Spring.GetSpectatingState() or config.chat.canSpecChat
end

local function KeyPress(key, mods, ...)
	if key == Spring.GetKeyCode("enter") or key == Spring.GetKeyCode("numpad_enter") then
		if mods.alt then
			SetContext(GetRestrictedChat())
		elseif mods.shift and CanSpecChat() then
			SetContext(specContext)
		elseif mods.ctrl or (GetCurrentContext() == nil or not GetCurrentContext().persist) then
			SetContext(sayContext)
		else
			return false
		end
		return true
	end
end

local function ParseKey(key, mods, isRepeat)
	if mods.alt then
		if GetCurrentContext().name == GetRestrictedChat().name then
			SetContext(sayContext)
		else
			SetContext(GetRestrictedChat())
		end
	elseif mods.shift and CanSpecChat() then
		if GetCurrentContext().name == specContext.name then
			SetContext(sayContext)
		else
			SetContext(specContext)
		end
	elseif mods.ctrl then
		SetContext(sayContext)
	else
		return false
	end
	ShowContext()
	return true
end

local function SetConsoleText(txt)
	ebConsole:SetText(txt)
	ebConsole.cursor = #GetText() + 1
end

local function AllowedContextSwitch()
	local contextName = GetCurrentContext().name
	return contextName == allyContext.name or contextName == sayContext.name or contextName == specContext.name
end

context = {
	{
		name = allyContext.name,
		tryEnter = function(txt)
			if not AllowedContextSwitch() then return false end
			local prefix = txt:lower():sub(1, 3)
			if prefix == "/t " then
				SetConsoleText(txt:sub(4))
				return allyContext
			elseif prefix:sub(1, 2) == "a:" then
				SetConsoleText(txt:sub(3))
				return allyContext
			end
		end,
		exec = function(txt)
			Spring.SendCommands("say a:" .. txt)
		end,
		keyPress = function(...)
			return KeyPress(...)
		end,
		parseKey = function(...)
			return ParseKey(...)
		end,
	},
	{
		name = sayContext.name,
		tryEnter = function(txt)
			if not AllowedContextSwitch() then return false end
			local prefix = txt:lower():sub(1, 5)
			if prefix == "/a " then
				SetConsoleText(txt:sub(6))
				return sayContext
			end
		end,
		exec = function(txt)
			Spring.SendCommands("say " .. txt)
		end,
		keyPress = function(...)
			return KeyPress(...)
		end,
		parseKey = function(...)
			return ParseKey(...)
		end,
	},
	{
		name = specContext.name,
		tryEnter = function(txt)
			if not AllowedContextSwitch() then return false end
			if not CanSpecChat() then return false end
			local prefix = txt:lower():sub(1, 6)
			if prefix == "/s " then
				SetConsoleText(txt:sub(7))
				return specContext
			elseif prefix:sub(1, 2) == "s:" then
				SetConsoleText(txt:sub(3))
				return specContext
			end
		end,
		exec = function(txt)
			Spring.SendCommands("say s:" .. txt)
		end,
		keyPress = function(...)
			return KeyPress(...)
		end,
		parseKey = function(...)
			return ParseKey(...)
		end,
	},
}
