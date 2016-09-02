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

local IgnoreList = {}

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
			IgnoreList[prcmd[2]] = true
		end
	end
	if string.lower(prcmd[1]) == "ignorelist" then
		ignorestring = "game_message: You are ignoring the following users:"
		for name,_ in pairs(IgnoreList) do
			ignorestring = ignorestring .. "\n-" .. name
		end
		Spring.Echo(ignorestring)
	end
	if string.lower(prcmd[1]) == "unignore" then
		if prcmd[2] and IgnoreList[prcmd[2]] then
			Spring.Echo("game_message: Unignoring " .. prcmd[2])
			widgetHandler:Unignore(prcmd[2])
			IgnoreList[prcmd[2]] = nil
		end
	end
end

function widget:GetConfigData()
	return IgnoreList
end

function widget:SetConfigData(data)
	data = data or {}
	for ignoree,_ in pairs(data) do
		IgnoreList[ignoree] = true
	end
end

function widget:Initialize()
	local alreadyignored = {}
	alreadyignored = widgetHandler:GetIgnoreList()
	for ignoree,_ in pairs(IgnoreList) do
		widgetHandler:Ignore(ignoree)
	end
	for ignoree,_ in pairs(alreadyignored) do -- no point in telling WH to ignore already ignored users.
		IgnoreList[ignoree] = true
	end
end
