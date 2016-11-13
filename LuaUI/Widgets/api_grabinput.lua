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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Options

options_path = 'Settings/Interface/Mouse Cursor'
options_order = { 
	'grabinput',
}

options = {
	grabinput = {
		name = "Lock Cursor to Window",
		tooltip = "Prevents the cursor from leaving the Window/Screen",
		type = "bool",
		value = true,
		noHotkey = true,
		OnChange = function (self)
			Spring.SendCommands("grabinput " .. ((self.value and "1") or "0"))
		end
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
