function widget:GetInfo()
	return {
		name	= "In-game Ignore",
		desc	= "Adds ignore/unignore commands.",
		author	= "_Shaman",
		date	= "8-1-2016",
		license	= "Apply as needed",
		layer	= 0,
		enabled	= true,
	}
end

local function ProcessString(str)
	local strtbl = {}
	for w in string.gmatch(str, "%S+") do
		strtbl[#strtbl+1] = w
	end
	return strtbl
end

function widget:TextCommand(command)
	local prcmd = ProcessString(command)
	if string.lower(prcmd[1]) == "ignore" then
		if prcmd[2] then
			Spring.Echo("game_message: Ignoring " .. prcmd[2])
			widgetHandler:Ignore(prcmd[2])
		end
	end
	if string.lower(prcmd[1]) == "ignorelist" then
		local IgnoreList = widgetHandler:GetIgnoreList()
		ignorestring = "game_message: You are ignoring " .. #IgnoreList .. " users:"
		for name,_ in pairs(IgnoreList) do
			ignorestring = ignorestring .. "\n- " .. name
		end
		Spring.Echo(ignorestring)
	end
	if string.lower(prcmd[1]) == "unignore" then
		local IgnoreList = widgetHandler:GetIgnoreList()
		if not IgnoreList[prcmd[2]] then
			Spring.Echo("game_message: You were not ignoring " .. prcmd[2])
			return
		end
		Spring.Echo("game_message: Unignoring " .. prcmd[2])
		widgetHandler:Unignore(prcmd[2])
	end
end

function widget:GetConfigData()
	return widgetHandler:GetIgnoreList()
end

function widget:SetConfigData(data)
	data = data or {}
	for ignoree,_ in pairs(data) do
		widgetHandler:Ignore(ignoree)
	end
end
