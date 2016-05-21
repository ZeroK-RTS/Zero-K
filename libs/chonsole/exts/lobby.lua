-- Do not load this in gadgets
if not WG then
	return
end

-- disable in case there's no liblobby installed
if not WG.LibLobby or not WG.LibLobby.lobby then
	Spring.Log("Chonsole", LOG.WARNING, i18n("liblobby_not_installed", {default = "liblobby is not installed. Lobby support disabled."}))
	return
end
Spring.Log("Chonsole", LOG.NOTICE, i18n("liblobby_is_installed", {default = "liblobby is installed. Lobby support enabled."}))

local channelColor = "\204\153\1"
local consoles = {} -- ID -> name mapping
local lobby = WG.LibLobby.lobby

lobby:AddListener("OnJoin",
	function(listener, chanName)
		local id = 1
		while true do
			if not consoles[id] then
				consoles[id] = chanName
				Spring.Echo("\255" .. channelColor .. i18n("joined", {default = "Joined"}) .. " [" .. tostring(id) .. ". " .. chanName .. "]")
				break
			end
			id = id + 1
		end
	end
)
lobby:AddListener("OnJoined",
	function(listener, chanName, userName)
		for id, name in pairs(consoles) do
			if name == chanName then
				consoles[id] = chanName
				Spring.Echo("\255" .. channelColor .. userName .. " " .. i18n("user_joined", {default = "joined"}) .. " [" .. tostring(id) .. ". " .. chanName .. "]")
				break
			end
		end
	end
)
lobby:AddListener("OnLeft",
	function(listener, chanName, userName)
		for id, name in pairs(consoles) do
			if name == chanName then
				consoles[id] = chanName
				Spring.Echo("\255" .. channelColor .. userName .. " " .. i18n("user_left", {default = "left"}) .. " [" .. tostring(id) .. ". " .. chanName .. "]")
				break
			end
		end
	end
)
lobby:AddListener("OnSaid", 
	function(listener, chanName, userName, message)
		for id, name in pairs(consoles) do
			if name == chanName then
				-- print channel message
				local msg = "\255" .. channelColor .. "[" .. tostring(id) .. ". " .. chanName .. "] <" .. userName .. "> " .. message .. "\b"
				Spring.Echo(msg)
				break
			end
		end
	end
)
lobby:AddListener("OnAccepted",
	function(listener)
		Spring.Echo("\255" .. channelColor .. i18n("connected_server", {default="Connected to server."}) .. "\b")
	end
)
lobby:AddListener("OnDenied",
	function(listener, reason)
		Spring.Echo("\255" .. channelColor .. i18n("failed_connect", {default="Failed connecting to server: "}) .. reason .. "\b")
	end
)
lobby:AddListener("OnDisconnected",
	function(listener)
		consoles = {}
		Spring.Echo("\255" .. channelColor .. i18n("disconnected_server", {default="Disconnected from server."}))
		if GetCurrentContext().name == "channel" then
			ResetCurrentContext()
		end
		-- check if we'll try to reconnect
		if lobby:GetConnectionStatus() == "disconnected" then
			-- FIXME: make this variable part of the API
			local delay = lobby.reconnectionDelay
			Spring.Echo("\255" .. channelColor .. i18n("announce_reconnect", {default="Attempting reconnect in %{delay} seconds.", delay=delay}) .. "\b")	
		end
	end
)

commands = {
	{
		command = "login",
		description = i18n("login_desc", {default = "Login to Spring Lobby"}),
		exec = function(command, cmdParts)
			Spring.Echo("\255" .. channelColor .. i18n("connecting_server", {default="Connecting to server..."}))
			lobby:AddListener("OnTASServer", function()
				lobby:Login(cmdParts[2], cmdParts[3], 3)
			end)
			lobby:Connect("springrts.com", 8200)
		end,
	},
	{
		command = "logout",
		description = i18n("logout_desc", {default="Logout from Spring Lobby"}),
		exec = function(command, cmdParts)
			if lobby:GetConnectionStatus() ~= "connected" then
				-- No need to print out an error message to the user, since it doesn't make any sense to logout while not connected anyway
				return
			end
			lobby:Exit("Leaving")
		end,
	},
	{
		command = "join",
		description = i18n("join_desc", {default="Join a channel"}),
		exec = function(command, cmdParts)
			if lobby:GetConnectionStatus() ~= "connected" then
				Spring.Echo("\255" .. channelColor .. i18n("login_first", {default="Cannot join a channel while disconnected. Login first."}) .. "\b")
				return
			end
			lobby:Join(cmdParts[2], cmdParts[3])
		end,
	},
	{
		command = "leave",
		description = i18n("leave_desc", {default="Leave a channel"}),
		exec = function(command, cmdParts)
			if lobby:GetConnectionStatus() ~= "connected" then
				-- No need to print out an error message to the user, since it doesn't make any sense to leave channels while not connected anyway
				return
			end

			local chanName = cmdParts[2]
			local currentContext = GetCurrentContext()
			if chanName == nil or chanName:trim() == "" then
				if currentContext.name == "channel" then
					chanName = consoles[currentContext.id]
				else
					return
				end
			end
			-- TODO: should probably use a listener instead but need to implement it
			for id, name in pairs(consoles) do
				if name == chanName then
					Spring.Echo("\255" .. channelColor .. i18n("left", {default="Left"}) .. " [" .. tostring(id) .. ". " .. chanName .. "]")
					if currentContext.name == "channel" and currentContext.id == id then
						ResetCurrentContext()
					end
					consoles[id] = nil
					break
				end
			end
			lobby:Leave(chanName)
		end,
	},
	-- TODO: support for private chat, /ignore, /friend, /friendlist, /channelist, /ignorelist
	-- TODO: preserve channel list. This may belong to liblobby instead.
	-- TODO: battleroom chat
	-- TODO: battleroom join/part messages
	-- TODO: friends coming online/offline
}

context = {
	{
		name = "channel",
		parse = function(txt)
			if tonumber(txt:trim():sub(2)) ~= nil and txt:sub(#txt, #txt) == " " then
				local id = tonumber(txt:trim():sub(2))
				if consoles[id] ~= nil then
					return true, { display = "\255" .. channelColor .. "[" .. tostring(id) .. ". " .. consoles[id] .. "]\b", name = "channel", id = id, persist = true }
				end
			end
		end,
		exec = function(str, context)
			lobby:Say(consoles[context.id], str)
		end
	},
}