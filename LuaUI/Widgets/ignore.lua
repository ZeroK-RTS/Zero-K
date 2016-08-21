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

if VFS.FileExists("ZeroKLobbyConfig.xml") then -- load ignore list from ZKL config. Temporary until server side ignore is exposed to lua.
	Spring.Echo("Ignorelist: Found ZKL Config. Loading ZKL ignore list.")
	local file = VFS.LoadFile("ZeroKLobbyConfig.xml")
	local beginof = string.find(file,"<IgnoredUsers>") + 15
	local endof = string.find(file,"</IgnoredUsers>") -1
	local ignorelist = string.sub(file,beginof,endof)
	ignorelist = string.gsub(ignorelist,"\n","~")
	ignorelist = string.gsub(ignorelist,"%s","")
	ignorelist = string.gsub(ignorelist,"string>","")
	ignorelist = string.gsub(ignorelist,"<","")
	ignorelist = string.gsub(ignorelist,"/","")
	ignorelist = string.gsub(ignorelist,"~"," ")
	local names = ProcessString(ignorelist)
	for i=1,#names do
		IgnoreList[names[i]] = true
        widgetHandler:Ignore(names[i])
	end
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
	for ignoree,_ in pairs(IgnoreList) do
		widgetHandler:Ignore(ignoree)
	end
end
