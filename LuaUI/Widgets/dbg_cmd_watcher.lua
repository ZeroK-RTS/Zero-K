function widget:GetInfo()
	return {
		name      = "Command Watcher",
		desc      = "Watches commands and messages visible to the player.",
		author    = "_Shaman",
		date      = "November 11, 2018",
		license   = "Lubglub",
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
