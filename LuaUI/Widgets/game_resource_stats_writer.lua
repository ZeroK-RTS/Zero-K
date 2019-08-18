function widget:GetInfo()
  return {
    name      = "Resource Stat Writer",
    desc      = "Writes resource statistics to a file at game end.",
    author    = "Google Frog",
    date      = "July 11, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end


function WriteResourceStatsToFile(reallyBigString, teamNames)
	Spring.Echo("Recieved data")
	
	local filename
	local dateTable = os.date("*t")
	if dateTable then
		if dateTable.month < 10 then
			dateTable.month = "0" .. dateTable.month
		end
		if dateTable.day < 10 then
			dateTable.day = "0" .. dateTable.day
		end
		if dateTable.hour < 10 then
			dateTable.hour = "0" .. dateTable.hour
		end
		if dateTable.min < 10 then
			dateTable.min = "0" .. dateTable.min
		end
		filename = "ResourceStats/" .. dateTable.year .. " " .. dateTable.month .. " " .. dateTable.day .. " " .. dateTable.hour .. " " .. dateTable.min .. ".txt"
	else
		filename = "ResourceStats/recent.txt"
	end
	
	local file = assert(io.open(filename,'w'), "Error saving team economy data to " .. filename)
	
	local allyTeamList = Spring.GetAllyTeamList()
	for i=1,#allyTeamList do
		local allyTeamID = allyTeamList[i]
		local teamList = Spring.GetTeamList(allyTeamID)
		local toSend = allyTeamID
		for j=1,#teamList do
			local teamID = teamList[j]
			toSend = toSend .. " " .. teamID .. " " .. (teamNames[teamID] or "no_name")
		end
		--Spring.SendCommands("wbynum 255 SPRINGIE: allyTeamPlayerMap " .. toSend)
		file:write(toSend)
		file:write("\n")
	end
	
	file:write(reallyBigString)

	file:close()
end
	
function widget:Initialize()
	widgetHandler:RegisterGlobal("WriteResourceStatsToFile", WriteResourceStatsToFile)
end
