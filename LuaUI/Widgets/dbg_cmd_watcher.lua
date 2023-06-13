function widget:GetInfo()
	return {
		name      = "Command Watcher",
		desc      = "Watches commands and messages visible to the player.",
		author    = "Shaman",
		date      = "November 11, 2018",
		license   = "PD",
		layer     = 5,
		enabled   = false,
	}
end

function widget:GotChatMsg(msg, player)
	Spring.Echo("GotChatMsg: " .. msg)
end

function widget:TextCommand(msg)
	Spring.Echo("TextCommand: " .. msg)
end
