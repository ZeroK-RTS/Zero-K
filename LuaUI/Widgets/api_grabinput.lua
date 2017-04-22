--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Grab Input",
		desc      = "Implements grab input option",
		author    = "GoogleFrog",
		date      = "11 Novemember 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

local ACTIVE_MESSAGE = "LobbyOverlayActive1"
local INACTIVE_MESSAGE = "LobbyOverlayActive0"

local lobbyOverlayActive = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Options

options_path = 'Settings/Interface/Mouse Cursor'
options_order = {
	'grabinput',
	'lobbyDisables',
}

-- Radio buttons are intentionally absent from these options to allow hotkeys to
-- toggle grabinput easily.
options = {
	grabinput = {
		name = "Lock Cursor to Window",
		tooltip = "Prevents the cursor from leaving the Window/Screen",
		type = "bool",
		value = true,
		OnChange = function (self)
			if options.lobbyDisables.value and lobbyOverlayActive then
				Spring.SendCommands("grabinput 0")
			else
				Spring.SendCommands("grabinput " .. ((self.value and "1") or "0"))
			end
		end
	},
	lobbyDisables = {
		name = "Lobby overlay disables lock",
		tooltip = "Disables input grabbing when the lobby overlay is visible.",
		type = "bool",
		value = true,
		noHotkey = false,
		OnChange = function (self)
			if self.value and lobbyOverlayActive then
				Spring.SendCommands("grabinput 1")
			else
				Spring.SendCommands("grabinput " .. ((options.grabinput.value and "1") or "0"))
			end
		end,
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Initialize()
	Spring.SendCommands("grabinput " .. ((options.grabinput.value and "1") or "0"))
end

function widget:Shutdown()
	-- For Chobby.
	Spring.SendCommands("grabinput 0")
end

function widget:RecvLuaMsg(msg)
	if msg == ACTIVE_MESSAGE then
		lobbyOverlayActive = true
		if options.lobbyDisables.value and options.grabinput.value then
			Spring.SendCommands("grabinput 0")
		end
	elseif msg == INACTIVE_MESSAGE then
		lobbyOverlayActive = false
		if options.lobbyDisables.value and options.grabinput.value then
			Spring.SendCommands("grabinput 1")
		end
	end
end
