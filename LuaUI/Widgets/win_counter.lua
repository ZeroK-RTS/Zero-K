
function widget:GetInfo()
  return {
    name      = "Win Counter",
    desc      = "Local win counter, used with a playerlist",
    author    = "Shadowfury333",
    date      = "2014-08-30",
    license   = "GNU GPL, v2 or later",
    layer     = -1,
    enabled   = true,
  }
  --Declares WG.WinCounter_currentWinTable: Table, {string playerName, {"team" = number team, "wins" = number wins}}
  --         WG.WinCounter_Reset:           Function, () -> nil, Resets the win count table
  --         WG.WinCounter_Set:             Function, (string playerName | number playerID, number winCount) -> nil, Sets win count for given player
end

local lastWinTable = {}
local currentWinTable = {} --NB: This is constructed with info for all players in the current game at game start
local loadedFromConfig = false

local function Set(player, winCount)
    local name = ""
    if type(player) == "number" then
        name = Spring.GetPlayerInfo(player)
    elseif type(player) == "string" then
        name = player
    end
    if name ~= nil and currentWinTable[name] ~= nil and type(currentWinTable[name]) == "table" then
        currentWinTable[name].wins = winCount
    end
end

local function Reset()
    Spring.Echo("Resetting win data")
    local players = Spring.GetPlayerList()
    local teams = Spring.GetTeamList()
    currentWinTable = {}
    for i=1, #players do
        local name,_,_,teamID = Spring.GetPlayerInfo(players[i])
        currentWinTable[name] = {team = teamID, wins = 0}
    end
    currentWinTable.count = #players
    currentWinTable.teamCount = #teams
    Spring.Echo("Player Count: "..currentWinTable.count)
    WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
end

function widget:Initialize()
    WG.WinCounter_Set = Set
    WG.WinCounter_Reset = Reset
    if not loadedFromConfig then
        Reset()
    end
end

function widget:Shutdown()
    WG.WinCounter_Set = nil
    WG.WinCounter_Reset = nil
end

function widget:GameOver()
    local players = Spring.GetPlayerList();
    for i=1, #players do
        local playerName = Spring.GetPlayerInfo(players[i])
        if currentWinTable[playerName] ~= nil then
            local _,_,isDead = Spring.GetTeamInfo(currentWinTable[playerName].team or 0)
            if not isDead then
                currentWinTable[playerName].wins = (currentWinTable[playerName].wins or 0) + 1
            end
        end
        Spring.Echo(playerName.."'s current win count: "..currentWinTable[playerName].wins)
    end
    WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
end

function widget:GetConfigData()
    Spring.Echo("Writing last game win data")
    Spring.Echo("Player Count: "..currentWinTable.count)
    return currentWinTable
end

function widget:SetConfigData(data)
    loadedFromConfig = true
    local teamPlayerMatch = true
    Spring.Echo("Getting last game win data")
    lastWinTable = data
    Reset() --Pre-emptively resetting scores, in case last game and this game have different teams
    Spring.Echo("Last game player count: "..(lastWinTable.count or 0)..", This game player count: "..currentWinTable.count )
    Spring.Echo("Last game team count: "..(lastWinTable.teamCount or 0)..", This game team count: "..currentWinTable.teamCount )
    if lastWinTable ~= nil and lastWinTable ~= {} and lastWinTable.count == currentWinTable.count and lastWinTable.teamCount == currentWinTable.teamCount then --If the player or team count changed, reset scores
        Spring.Echo("Player counts match, continuing")
        --Map for verifying what teams from last game map to this game, if all players and teams remained the same. Assumes team and player counts remained the same
        local lastToCurrentTeamMap = {}
        for lastGamePlayerName,lastGameTeamAndWins in pairs(lastWinTable) do --Check if all players are still on the same teams
            if type(lastGameTeamAndWins) == "table" then
                if currentWinTable[lastGamePlayerName] == nil then --If a player from last game isn't here, then teams have changed. Reset scores
                    Spring.Echo(lastGamePlayerName.." was in last game, now absent, resetting scores")
                    teamPlayerMatch = false
                    break
                elseif lastGameTeamAndWins ~= nil then
                    local lastGameTeam = lastGameTeamAndWins.team
                    if lastToCurrentTeamMap[lastGameTeam] == nil then --If this player's team is not in the map, add it. Otherwise, check that the team map is consistent
                        lastToCurrentTeamMap[lastGameTeam] = currentWinTable[lastGamePlayerName].team
                        Spring.Echo("Testing last game's team "..lastGameTeam.." mapped to this game's team "..(currentWinTable[lastGamePlayerName].team))
                    elseif lastToCurrentTeamMap[lastGameTeam] ~= currentWinTable[lastGamePlayerName].team then 
                        Spring.Echo(lastGamePlayerName.." changed team since last game, resetting scores")
                        teamPlayerMatch = false
                        break --If a player from last game changed who their teammates are, this check will fail. Reset scores
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
            currentWinTable = lastWinTable
        end
    end

    WG.WinCounter_currentWinTable = currentWinTable --Set at end rather than modified throughout to remove contention risks
end