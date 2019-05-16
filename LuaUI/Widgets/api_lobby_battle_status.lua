--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Lobby Battle Status",
		desc      = "Communicates with the lobby about the status of the battle.",
		author    = "GoogleFrog",
		date      = "16 May 2019",
		license   = "GPL-v2",
		layer     = 0,
		enabled   = true,
		api	      = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Globals

local DELIM = "_"

local GAME_INIT = "ingameInfoInit" .. DELIM
local GAME_START = "ingameInfoStart" .. DELIM

local RELOAD_MODE = false

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

-- BOOL Is playing
-- NAT0 total PlayerCount
-- NAT0 Team 1 players
-- NAT0 Team 2 players
-- BOOL is FFA
-- BOOL is replay
-- BOOL is vs AI
-- BOOL is vs Chickens
-- BOOL is campaign
-- STRG is PLANET NAME

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
	for _, n in pairs(playersOnTeam) do
		if playersFirstTeam then
			playerSecondTeam = n
		else
			playersFirstTeam = n
		end
	end
	local playerList = Spring.GetPlayerList()
	
	local retString = ""
	retString = retString .. (((not Spring.GetSpectatingState()) and "1") or "0") .. DELIM
	retString = retString .. ((playerList and #playerList) or 1) .. DELIM
	retString = retString .. (playersFirstTeam or 0) .. DELIM
	retString = retString .. (playerSecondTeam or 0) .. DELIM
	retString = retString .. ((playerTeamCount > 2 and "1") or "0") .. DELIM
	retString = retString .. ((aiTeamCount > 0 and "1") or "0") .. DELIM
	retString = retString .. ((Spring.IsReplay() and "1") or "0") .. DELIM
	retString = retString .. ((chickenTeamID and "1") or "0") .. DELIM
	retString = retString .. ((Spring.GetModOptions().singleplayercampaignbattleid and "1") or "0") .. DELIM
	retString = retString .. ((WG.campaign_planetInformation and WG.campaign_planetInformation.name) or "") .. DELIM
	
	return retString
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

local gameString
function widget:GameFrame(n)
	if n == 0 or RELOAD_MODE then
		gameString = gameString or GetGameTypeCoded()
		SendGameStart(gameString)
	end
	widgetHandler:RemoveWidget()
end

function widget:Update(dt)
	if (not RELOAD_MODE) and Spring.GetGameFrame() > 0 then
		widgetHandler:RemoveWidget()
	end
	gameString = gameString or GetGameTypeCoded()
	SendPreGame(gameString)
	widgetHandler:RemoveCallIn("Update")
end

function widget:Initialize() 
	if not (Spring.GetMenuName and Spring.SendLuaMenuMsg and Spring.GetMenuName()) then
		widgetHandler:RemoveWidget()
	end
end
