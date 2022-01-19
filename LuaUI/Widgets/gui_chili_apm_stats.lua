----------------------------------------------------------------------------
----------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name    = "EndGame APM stats",
		desc    = "Adding the engine APM stats back in, to be called from endgamewindow",
		author  = "DavetheBrave",
		date    = "2021",
		license = "public domain",
		layer   = -1,
		enabled = true
	}
end

local spGetTeamInfo = Spring.GetTeamInfo
local spGetTeamList = Spring.GetTeamList
local spGetGameSeconds = Spring.GetGameSeconds
local spGetPlayerStatistics = Spring.GetPlayerStatistics
local spGetPlayerInfo = Spring.GetPlayerInfo
local myPlayerID = Spring.GetMyPlayerID()
local timedPlayerList = {}
local storedPlayerStats = {}
local statsFinal = {}
local myTeamID
local gameOn = false
local wantStats = false
local SendLuaUIMsg = Spring.SendLuaUIMsg

local floor = math.floor
----------------------------------------------------------------------------
----------------------------------------------------------------------------

local function round(number)
	return floor(number+0.5)
end

local function SetTimedPlayerList()
	local gaiaTeamID = Spring.GetGaiaTeamID()
	for _,teamID in ipairs(Spring.GetTeamList()) do
		local _,leader,_,isAI,_,_ = Spring.GetTeamInfo(teamID, false)
		if not isAI then
			if teamID~=gaiaTeamID then
				timedPlayerList[leader] = {}
				timedPlayerList[leader].inactiveTime = 0
			end
		end
	end
end

local function SendMyPlayerStats()
	if not wantStats then
		return
	end
	local MP, MC, KP, NC, NUC = spGetPlayerStatistics(myPlayerID, true)
	timedPlayerList[myPlayerID].inactiveTime = timedPlayerList[myPlayerID].inactiveTime or 0
	local activeTime = spGetGameSeconds()-timedPlayerList[myPlayerID].inactiveTime
	local playerStats = {
		teamID = myTeamID,
		MPS = round(MP/activeTime),
		MCM = round(MC*60/activeTime),
		KPM = round(KP*60/activeTime),
		APM = round(NC*60/activeTime),
	}
	--If sending own stats, we need to clear previous set incase we have left the game and come back
	WG.AddPlayerStatsToPanel(playerStats, true)
	MP = VFS.PackU16(MP)
	MC = VFS.PackU16(MC)
	KP = VFS.PackU16(KP)
	NC = VFS.PackU16(NC)
	NUC = VFS.PackU16(NUC)
	SendLuaUIMsg("pStats"..MP..MC..KP..NC..NUC)
end

local function SendPlayerInactiveTime(playerID)
	local inactiveTimeStr = "inactiveTime"..VFS.PackU16(playerID)..VFS.PackU16(timedPlayerList[playerID].inactiveTime)
	SendLuaUIMsg(inactiveTimeStr)
end

local function ProcessPlayerInactiveTime(msg)
	local playerID = tonumber(VFS.UnpackU16(msg:sub(13)))
	local inactiveTime = tonumber(VFS.UnpackU16(msg:sub(15)))
	return inactiveTime, playerID
end

local function ProcessPlayerStats(msg, playerID)
	if not timedPlayerList[playerID] then
		return
	end
	local teamID = select(4,spGetPlayerInfo(playerID, false))
	local MP = tonumber(VFS.UnpackU16(msg:sub(7)))
	local MC = tonumber(VFS.UnpackU16(msg:sub(9)))
	local KP = tonumber(VFS.UnpackU16(msg:sub(11)))
	local NC = tonumber(VFS.UnpackU16(msg:sub(13)))
	local NUC = tonumber(VFS.UnpackU16(msg:sub(15)))
	timedPlayerList[playerID].inactiveTime = timedPlayerList[playerID].inactiveTime or 0
	local activeTime = spGetGameSeconds() - timedPlayerList[playerID].inactiveTime
	local playerStats = {
		teamID = teamID,
		MPS = round(MP/activeTime),
		MCM = round(MC*60/activeTime),
		KPM = round(KP*60/activeTime),
		APM = round(NC*60/activeTime),
	}
	WG.AddPlayerStatsToPanel(playerStats)
end



function widget:Initialize()
	local _, _, isSpec, teamID = spGetPlayerInfo(myPlayerID, false)
	--This will also get called if coming back into game as a spectator -- in that case we don't want to start logging stats again
	--so wantStats will be false
	if not isSpec then
		myTeamID = teamID
		wantStats = true
	end
	SetTimedPlayerList()
end

function widget:RecvLuaMsg(msg, playerID)
	if playerID == myPlayerID then
		return true
	end
	if (msg:sub(1,6)=="pStats") then
		if not gameOn then
			ProcessPlayerStats(msg, playerID)
		else
			storedPlayerStats[playerID] = msg
		end
	elseif (msg:sub(1,12)=="inactiveTime") and timedPlayerList[timedPlayerID] then
		--Ensure that the maximum amount of inactive time is getting sent for each player
		--Because local player won't have information on their own inactive time, and some others may not have
		--complete information if they have left and come back
		local inactiveTime, timedPlayerID = ProcessPlayerInactiveTime(msg)
		if inactiveTime > timedPlayerList[timedPlayerID].inactiveTime then
			timedPlayerList[timedPlayerID].inactiveTime = inactiveTime
		end
	end
end

function widget:Shutdown()
	--ensure that stats are getting sent even if player has left
	SendMyPlayerStats()
end

function widget:PlayerChanged(playerID)
	--ensure that stats are getting sent if a player is resigning early
	--log time after resign as inactive time
	if playerID == myPlayerID and gameOn and timedPlayerList[playerID] then
		timedPlayerList[playerID].inactiveStartTime = spGetGameSeconds()
		SendMyPlayerStats()
	end
end

function widget:PlayerRemoved(playerID)
	--this is useless for now
	if playerID ~= myPlayerID and gameOn and timedPlayerList[playerID] then
		timedPlayerList[playerID].inactiveStartTime = spGetGameSeconds()
	end
end

function widget:PlayerAdded(playerID)
	--When a player gets added, Spring.GetPlayerStatistics starts anew
	--So any time before this should be considered inactive time
	if (playerID ~= myPlayerID) and gameOn and timedPlayerList[playerID] then
		if timedPlayerList[playerID].inactiveStartTime then
			timedPlayerList[playerID].inactiveTimeDC = spGetGameSeconds()
			timedPlayerList[playerID].inactiveStartTime = false
		end
	end
end

function widget:GameStart()
	gameOn = true
end

function widget:GameOver()
	gameOn = false
	for playerID, data in pairs(timedPlayerList) do
		if data.inactiveStartTime then
			data.inactiveTimeRes = spGetGameSeconds()-timedPlayerList[playerID].inactiveStartTime
		end
		--If a player has some DC time, and also resigned early, the cumulative total needs to be considered
		data.inactiveTimeDC = data.inactiveTimeDC or 0
		data.inactiveTimeRes = data.inactiveTimeRes or 0
		data.inactiveTime = data.inactiveTimeDC + data.inactiveTimeRes
		SendPlayerInactiveTime(playerID)
	end
	SendMyPlayerStats()
	for playerID, msg in pairs(storedPlayerStats) do
		ProcessPlayerStats(msg, playerID)
	end
end
