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
local myTeamID
local gameOn = false
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
	local MP, MC, KP, NC, NUC = spGetPlayerStatistics(myPlayerID, true)
	local playerStats = {
		teamID = myTeamID,
		MP = MP,
		MC = MC,
		KP = KP,
		NC = NC,
		NUC = NUC
	}
	WG.apmStats[myPlayerID] = playerStats
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
	local teamID = select(4,spGetPlayerInfo(playerID, false))
	local MP = tonumber(VFS.UnpackU16(msg:sub(7)))
	local MC = tonumber(VFS.UnpackU16(msg:sub(9)))
	local KP = tonumber(VFS.UnpackU16(msg:sub(11)))
	local NC = tonumber(VFS.UnpackU16(msg:sub(13)))
	local NUC = tonumber(VFS.UnpackU16(msg:sub(15)))
	timedPlayerList[playerID].inactiveTime = timedPlayerList[playerID].inactiveTime or 0
	local activeTime = spGetGameSeconds() - timedPlayerList[playerID].inactiveTime
	local MPS = round(MP/activeTime)
	local playerStats = {
		teamID = teamID,
		MPS = round(MP/activeTime),
		MCM = round(MC*60/activeTime),
		KPM = round(KP*60/activeTime),
		APM = round(NC*60/activeTime),
	}
	WG.apmStats[playerID] = playerStats
end



function widget:Initialize()
	local _, _, isSpec, teamID = spGetPlayerInfo(myPlayerID, false)
	if not isSpec then
		myTeamID = teamID
	end
	SetTimedPlayerList()
	WG.apmStats = WG.apmStats or {}
end

function widget:RecvLuaMsg(msg, playerID)
	if playerID == myPLayerID then
		return true
	end
	if (msg:sub(1,6)=="pStats") then
		if not gameOn then
			ProcessPlayerStats(msg, playerID)
		else
			storedPlayerStats[playerID] = msg
		end
	elseif (msg:sub(1,12)=="inactiveTime") then
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
	SendMyPlayerStats()
end

function widget:PlayerChanged(playerID)
	if playerID == myPlayerID and gameOn then
		timedPlayerList[playerID].inactiveStartTime = spGetGameSeconds()
		SendMyPlayerStats()
	end
end

function widget:PlayerRemoved(playerID)
	if playerID ~= myPlayerID and gameOn then
		timedPlayerList[playerID].inactiveStartTime = timedPlayerList[playerID].inactiveStartTime or spGetGameSeconds()
	end
end

function widget:PlayerAdded(playerID)
	if (playerID ~= myPlayerID) and gameOn then
		local timeStamp = spGetGameSeconds()
		if timedPlayerList[playerID].inactiveStartTime then
			timedPlayerList[playerID].inactiveTime = (spGetGameSeconds()-(timedPlayerList[playerID].inactiveStartTime))
			timedPlayerList[playerID].inactiveStartTime = nil
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
			data.inactiveTime = spGetGameSeconds()-timedPlayerList[playerID].inactiveStartTime
		end
		SendPlayerInactiveTime(playerID)
	end
	SendMyPlayerStats()
	for playerID, msg in pairs(storedPlayerStats) do
		ProcessPlayerStats(msg, playerID)
	end
end
