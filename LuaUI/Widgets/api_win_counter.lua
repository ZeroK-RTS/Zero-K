-- Standalone win counter designed to be used through WG.
-- This will increment winner scores on game end on a per-player basis, and preserve them from game to game if the player's retain their allies. 
-- The actual allyTeam and player ids don't matter, just the player groups.
-- If players on the same allyTeam are on different teams (i.e. all controlling the same units) between games, the scores will still be preserved,
-- as the players in question are still working on the same side between games.

function widget:GetInfo()
  return {
	name	  = "Win Counter",
	desc	  = "Local win counter, used with a playerlist",
	author	= "Shadowfury333",
	date	  = "2014-08-30",
	license   = "GNU GPL, v2 or later",
	layer	 = -1,
	api = true,
	alwaysStart = true,
	enabled   = true,
  }
  --Declares WG.WinCounter_currentWinTable: Table, {string playerName, {"team" = number allyTeam, "wins" = number wins, "wonLastGame" = boolean won previous game}}
  --																				| Table, {"hasWins = boolean somePlayerHasWins}
  --		 WG.WinCounter_Increment:  Function, (number allyTeam) -> nil, Increments win counter for selected allyTeam
  --		 WG.WinCounter_Reset:		   Function, () -> nil, Resets the win count table
  --		 WG.WinCounter_Set:			   Function, (string playerName | number playerID, number winCount, boolean forAllyTeam (, boolean wonLastGame)) -> nil, 
  --										Sets win count for given player and optionally all players on their allyTeam
end

local lastWinTable = {}
local currentWinTable = {} --NB: This is constructed with info for all non-spec players in the current game at game start
local loadedFromConfig = false

local function Set(player, winCount, forAllyTeam, wonLastGame)
	local name = ""
	if type(player) == "number" then
		name = Spring.GetPlayerInfo(player, false)
	elseif type(player) == "string" then
		name = player
	end

	if wonLastGame ~= nil then
		local allyTeams = Spring.GetAllyTeamList()
		for i=1, #allyTeams do
			local playerTeams = Spring.GetTeamList(allyTeams[i])
			for j=1, #playerTeams do
				local players = Spring.GetPlayerList(playerTeams[j])
				for k=1, #players do
					local playerName = Spring.GetPlayerInfo(players[k], false)
					if playerName ~= nil and currentWinTable[playerName] ~= nil then
						currentWinTable[playerName].wonLastGame = false
					end
				end
			end
		end
	end

	if type(winCount) == "number" and winCount >= 0 and name ~= nil and currentWinTable[name] ~= nil and type(currentWinTable[name]) == "table" then
		if forAllyTeam then
			local alliedTeams = Spring.GetTeamList(currentWinTable[name].allyTeam)
			for i=1, #alliedTeams do
				local players = Spring.GetPlayerList(alliedTeams[i])
				for j=1, #players do
					local playerName = Spring.GetPlayerInfo(players[j], false)
					if currentWinTable[playerName] ~= nil then
						currentWinTable[playerName].wins = winCount
						if wonLastGame ~= nil then
							currentWinTable[playerName].wonLastGame = wonLastGame
						end
					end
				end
			end
		else
			currentWinTable[name].wins = winCount
			if wonLastGame ~= nil then
				currentWinTable[name].wonLastGame = wonLastGame
			end
		end

		if winCount > 0 then 
			currentWinTable.hasWins = true
		else
			currentWinTable.hasWins = false
			for k,v in pairs(currentWinTable) do
				if type(v) == "table" then
					if v.wins > 0 then currentWinTable.hasWins = true; break end
				end
			end
		end

		WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
	end
end

local function IncrementAllyTeamWins(allyTeamNumber) --We need to figure out playerName to get current wins for allyTeam
	local playerName = nil
	playerTeams = Spring.GetTeamList(allyTeamNumber)
	if playerTeams ~= nil and #playerTeams >= 1 then
		players = Spring.GetPlayerList(playerTeams[1])
		for i=1, #players do
			local name,_,isSpec = Spring.GetPlayerInfo(players[i], false)
			if not isSpec then
				playerName = name
				break
			end
		end
	end
	if playerName ~= nil and currentWinTable[playerName] ~= nil then
		local wins = currentWinTable[playerName].wins or 0
		Set(playerName, wins + 1, true, true) 
	end 
end

local function Reset()
	Spring.Echo("Resetting win data")
	-- local players = Spring.GetPlayerList()
	local allyTeams = Spring.GetAllyTeamList()
	local allyTeamCount = 0
	local playerCount = 0
	currentWinTable = {}
	-- Spring.Echo("#allyTeams: "..#allyTeams)
	for i=1, #allyTeams do
		local playerTeams = Spring.GetTeamList(allyTeams[i])
		-- Spring.Echo("#playerTeams on allyTeam "..allyTeams[i]..": "..#playerTeams)
		if #playerTeams > 0 then				--Spring counts all startboxes as ally teams, even if they are not used by any players. 
			allyTeamCount = allyTeamCount + 1   --This needs to be worked around, as maps may be set up with more startboxes than necessary.
		end

		for j=1, #playerTeams do
			-- Drill down to player level, in case there are multiple non-spec players on one team, they should all be noted
			local players = Spring.GetPlayerList(playerTeams[j])
			-- Spring.Echo("#players on team "..playerTeams[j]..": "..#players)
			for k=1, #players do
				local name,_,isSpec = Spring.GetPlayerInfo(players[k], false)
				if playerTeams[j] ~= 0 or (playerTeams[j] == 0 and not isSpec) then --Logic taken from Deluxe Player List, though adapted to one line
					-- Spring.Echo("Resetting: "..name)
					playerCount = playerCount + 1
					currentWinTable[name] = {allyTeam = allyTeams[i], wonLastGame = false, wins = 0}
				end
			end
		end
	end
	currentWinTable.count = playerCount
	currentWinTable.allyTeamCount = allyTeamCount
	currentWinTable.hasWins = false
	WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
end

function widget:Initialize()
	WG.WinCounter_Set = Set
	WG.WinCounter_Reset = Reset
	WG.WinCounter_Increment = IncrementAllyTeamWins
	if not loadedFromConfig then
		Reset()
	end
end

function widget:Shutdown()
	WG.WinCounter_Set = nil
	WG.WinCounter_Reset = nil
	WG.WinCounter_Increment = nil
end

function widget:GameOver(winningAllyTeams)
	-- Don't do anything if the game was exited
	if #winningAllyTeams == 0 then return end

	-- Reset who won last game
	local players = Spring.GetPlayerList()
	for i=1, #players do
		local playerName = Spring.GetPlayerInfo(players[i], false)
		if currentWinTable[playerName] ~= nil then 
			currentWinTable[playerName].wonLastGame = false 
		end
	end

	for i=1, #winningAllyTeams do
		local winningAllyTeam = winningAllyTeams[i]
		local winningPlayerTeams = Spring.GetTeamList(winningAllyTeam)
		for i=1, #winningPlayerTeams do
			local players = Spring.GetPlayerList(winningPlayerTeams[i])
			for j=1, #players do
				local playerName = Spring.GetPlayerInfo(players[j], false)
				if currentWinTable[playerName] ~= nil then
					currentWinTable[playerName].wins = (currentWinTable[playerName].wins or 0) + 1
					currentWinTable[playerName].wonLastGame = true
				end
			end
		end
		currentWinTable.hasWins = true
		WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
	end
end

function widget:GetConfigData()
	Spring.Echo("Writing last game win data")
	return currentWinTable
end

function widget:SetConfigData(data)
	loadedFromConfig = true
	local teamPlayerMatch = true
	Spring.Echo("Loading last game win data")
	lastWinTable = data
	Reset() --Pre-emptively resetting scores, in case last game and this game have different allyTeams
	Spring.Echo("Last game player count: "..(lastWinTable.count or 0)..", This game player count: "..currentWinTable.count )
	Spring.Echo("Last game allyTeam count: "..(lastWinTable.allyTeamCount or 0)..", This game allyTeam count: "..currentWinTable.allyTeamCount )
	--If the player or allyTeam count changed, or this widget has broken config data, reset scores
	if lastWinTable ~= nil and next(lastWinTable) ~= nil and lastWinTable.count == currentWinTable.count and lastWinTable.allyTeamCount == currentWinTable.allyTeamCount then 
		Spring.Echo("Player and team counts match, continuing")
		--Table for verifying what allyTeams from last game map to this game, if all players remained the same. Assumes allyTeam and player counts remained the same
		local lastToCurrentTeamMap = {}
		for lastGamePlayerName,lastGameTeamAndWins in pairs(lastWinTable) do --Check if all players are still on the same allyTeams
			if type(lastGameTeamAndWins) == "table" then
				if currentWinTable[lastGamePlayerName] == nil then --If a player from last game isn't here, then allyTeams have changed. Reset scores
					Spring.Echo(lastGamePlayerName.." was in last game but is now absent, resetting scores")
					teamPlayerMatch = false
					break
				elseif lastGameTeamAndWins ~= nil then
					local lastGameTeam = lastGameTeamAndWins.allyTeam
					if lastToCurrentTeamMap[lastGameTeam] == nil then --If this player's allyTeam is not in the map, add it. Otherwise, check that the allyTeam map is consistent
						lastToCurrentTeamMap[lastGameTeam] = currentWinTable[lastGamePlayerName].allyTeam
						Spring.Echo("Testing last game's team "..lastGameTeam.." mapped to this game's team "..(currentWinTable[lastGamePlayerName].allyTeam))
					elseif lastToCurrentTeamMap[lastGameTeam] ~= currentWinTable[lastGamePlayerName].allyTeam then 
						Spring.Echo(lastGamePlayerName.." changed team since last game, resetting scores")
						teamPlayerMatch = false
						break --If a player from last game changed who their allyTeammates are, this check will fail. Reset scores
					end
				else
					Spring.Echo(lastGamePlayerName.." has no win record, this shouldn't happen")
					teamPlayerMatch = false
					break
				end
			end
		end
		if teamPlayerMatch then
			Spring.Echo("All players and teams match from last game, using last game's scores as base")
			for name,v in pairs(currentWinTable) do
				if type(v) == "table" then
					v.wins = lastWinTable[name].wins
					v.wonLastGame = lastWinTable[name].wonLastGame
			--	  Spring.Echo(k.." has "..v.wins.." wins for team ", v.allyTeam)
			--  else
			--	  Spring.Echo(k..": "..v)
				end
				currentWinTable.hasWins = lastWinTable.hasWins --This gets updated on GameOver
			end
		end
	end

	WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
end
