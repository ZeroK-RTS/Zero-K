--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name        = "Lobby Battle Status",
		desc        = "Communicates with the lobby about the status of the battle.",
		author      = "GoogleFrog",
		date        = "16 May 2019",
		license     = "GPL-v2",
		layer       = 0,
		alwaysStart = true,
		enabled     = true,
		api         = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local DELIM = "_"

local GAME_INIT = "ingameInfoInit" .. DELIM
local GAME_START = "ingameInfoStart" .. DELIM

local gameString
local sentPreGame = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Game Type Detector

local function AddTeamEntity(allyTeamID, onTeam, teamCount)
	if onTeam[allyTeamID] then
		onTeam[allyTeamID] = onTeam[allyTeamID] + 1
		return teamCount
	end
	
	onTeam[allyTeamID] = 1
	return teamCount + 1
end

local function DataTableToString(dataTable)
	local retString = ""
	for name, value in pairs(dataTable) do
		retString = retString .. name .. DELIM .. tostring(value) .. DELIM
	end
	return retString
end

local function GetGameTypeCoded()
	-- Process the teams list.
	local gaiaTeamID = Spring.GetGaiaTeamID()
	local isSpectating = Spring.GetSpectatingState()
	
	local playerTeamCount = 0
	local aiTeamCount = 0
	local playersOnTeam = {}
	local aisOnTeam = {}
	
	local chickenTeamID = Spring.GetGameRulesParam("chickenTeamID")
	local chickenAllyTeamID

	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		if teamID ~= gaiaTeamID then
			local _,leader,isDead,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID)
			if isAI then
				aiTeamCount = AddTeamEntity(allyTeamID, aisOnTeam, aiTeamCount)
			else
				playerTeamCount = AddTeamEntity(allyTeamID, playersOnTeam, playerTeamCount)
			end
			if chickenTeamID == teamID then
				chickenAllyTeamID = allyTeamID
			end
		end
	end
	
	if chickenAllyTeamID and aisOnTeam[chickenAllyTeamID] then
		aisOnTeam[chickenAllyTeamID] = nil
		aiTeamCount = aiTeamCount - 1
	end
	
	-- Add info
	local playersFirstTeam
	local playerSecondTeam
	local teamPlayerCount = 0
	for _, n in pairs(playersOnTeam) do
		if playersFirstTeam then
			playerSecondTeam = n
		else
			playersFirstTeam = n
		end
		teamPlayerCount = teamPlayerCount + n
	end
	local playerList = Spring.GetPlayerList()
	
	local dataTable = {
		isPlayer = (not Spring.GetSpectatingState()),
		playerCount = ((playerList and #playerList) or 1),
		teamOnePlayers = (playersFirstTeam or 0),
		teamTwoPlayers = (playerSecondTeam or 0),
		teamPlayers = (teamPlayerCount or 0),
		isFFA = (playerTeamCount > 2),
		isAI = (aiTeamCount > 0),
		isReplay = Spring.IsReplay(),
		isChicken = (chickenTeamID and true) or false,
		isCampaign = (Spring.GetModOptions().singleplayercampaignbattleid and true) or false,
		planetName = (WG.campaign_planetInformation and WG.campaign_planetInformation.name) or "",
	}
	
	return DataTableToString(dataTable)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Communication

local function SendPreGame(data)
	Spring.SendLuaMenuMsg(GAME_INIT .. data)
end

local function SendGameStart(data)
	Spring.SendLuaMenuMsg(GAME_START .. data)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Update(dt)
	if Spring.GetGameFrame() > 1 then
		gameString = gameString or GetGameTypeCoded()
		SendGameStart(gameString)
		widgetHandler:RemoveWidget()
	elseif not sentPreGame then
		gameString = gameString or GetGameTypeCoded()
		SendPreGame(gameString)
		sentPreGame = true
	end
end

function widget:Initialize()
	if not (Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()) then
		widgetHandler:RemoveWidget()
	end
end
