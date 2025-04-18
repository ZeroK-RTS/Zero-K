--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Lag Monitor",
    desc      = "Gives away units of people who are lagging",
    author    = "KingRaptor, GoogleFrog rewrite",
    date      = "11/5/2012", --6/11/2013
    license   = "Public domain",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end
--------------------------------------------------------------------------------
--List of stuff in this gadget (to help us remember stuff for future debugging/improvement):

--Main logic:
--1) Periodic(CheckAFK & Ping) ---> mark player as AFK/Lagging --->  Check if player has Shared Command --> Check for Candidate with highest ELO -- > Loop(send unit away to candidate & remember unit Ownership).
--2) Periodic(CheckAFK & Ping) ---> IF AFK/Lagger is no longer lagging --> Return all units & delete unit Ownership.

--Everything else: anti-bug, syntax, methods, ect
local playerLineageUnits = {} --keep track of unit ownership: Is populated when gadget give away units, and when units is created. Depopulated when units is destroyed, or is finished construction, or when gadget return units to owner.
local unitPriorityState = {} -- Keep track of initial unit priority state.
local teamResourceShare = {}
local allyTeamResourceShares = {}
local unitAlreadyFinished = {}

local spEcho                  = Spring.Echo
local spGetGameSeconds        = Spring.GetGameSeconds
local spGetPlayerInfo         = Spring.GetPlayerInfo
local spGetTeamInfo           = Spring.GetTeamInfo
local spGetTeamList           = Spring.GetTeamList
local spGetTeamUnits          = Spring.GetTeamUnits
local spGetUnitAllyTeam       = Spring.GetUnitAllyTeam
local spGetUnitDefID          = Spring.GetUnitDefID
local spGetPlayerList         = Spring.GetPlayerList
local spTransferUnit          = Spring.TransferUnit
local spSetPlayerRulesParam   = Spring.SetPlayerRulesParam
local spGiveOrderToUnitArray  = Spring.GiveOrderToUnitArray
local spGetUnitCurrentCommand = Spring.GetUnitCurrentCommand

local useAfkDetection = (Spring.GetModOptions().enablelagmonitor == "on") or (Spring.GetModOptions().enablelagmonitor ~= "off" and not Spring.Utilities.Gametype.isCoop())
local MERGE_SHARE = tonumber(Spring.GetModOptions().mergeresourceshare or 0.5) or 0.5

include("LuaRules/Configs/constants.lua")

-- in seconds. The delay considered is (ping + time spent afk)
local TO_AFK_THRESHOLD = 38 -- going above this marks you AFK
local FROM_AFK_THRESHOLD = 5 -- going below this marks you non-AFK
local PING_TIMEOUT = 2000 -- ms

local CMD_WAIT = CMD.WAIT

local debugAllyTeam, debugPlayerLag, debugPlayerLagAll

local isRealFactoryDef = {}
local isBpHaverDef = {}

for unitDefID = 1, #UnitDefs do
	local ud = UnitDefs[unitDefID]
	if ud.buildSpeed > 0 and not ud.customParams.nobuildpower then
		isBpHaverDef[unitDefID] = true
		if ud.isFactory then
			isRealFactoryDef[unitDefID] = true
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local teamNames = {}
local function GetTeamName(teamID)
	return teamNames[teamID] or ("Unknown Player on team " .. (teamID or "???"))
end

local function PlayerIDToTeamID(playerID)
	local _, _, spectator, teamID = spGetPlayerInfo(playerID, false)
	if spectator then
		return false
	end
	return teamID
end

local function TeamIDToPlayerID(teamID)
	return select(2, spGetTeamInfo(teamID, false))
end

local function GetBpHaverAndWait(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	if not isBpHaverDef[unitDefID] then
		return false
	end
	if not isRealFactoryDef[unitDefID] then
		local cmdID = spGetUnitCurrentCommand(unitID)
		return true, (cmdID == CMD_WAIT)
	end
	--local cQueue = Spring.GetFactoryCommands(unitID, 1)
	-- Return false because factories lose wait when transfered, so should not be treated as having it set.
	return true, false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory and Lineage

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if GG.wasMorphedTo and GG.wasMorphedTo[unitID] then --copy playerLineageUnits for unit Morph
		local newUnitID = GG.wasMorphedTo[unitID]
		local originalPlayerIDs = playerLineageUnits[unitID]
		if originalPlayerIDs and (#originalPlayerIDs > 0) then
			-- playerLineageUnits of the morphed unit will be the same as its pre-morph
			playerLineageUnits[newUnitID] = {unpack(originalPlayerIDs)} --NOTE!: this copy value to new table instead of copying table-reference (to avoid bug)
		end
		unitAlreadyFinished[newUnitID] = true --for reverse build -- what is reverse build?
	end

	playerLineageUnits[unitID] = nil --to delete any units that do not need returning.
	unitAlreadyFinished[unitID] = nil
	unitPriorityState[unitID] = nil
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitAlreadyFinished[unitID] or not playerLineageUnits[unitID] then
		return
	end

	if Spring.GetUnitRulesParam(unitID, "ploppee") then
		return
	end

	unitAlreadyFinished[unitID] = true
end

local mouseActivityTime = {}

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("AFK",1,true) then
		mouseActivityTime[playerID] = tonumber(msg:sub(4))
		if (debugPlayerLag and debugPlayerLag[playerID]) or debugPlayerLagAll then
			Spring.Echo("Lagmonitor activity playerID", playerID, select(1, Spring.GetPlayerInfo(playerID)), mouseActivityTime[playerID])
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Transfer, handles factories

local function TransferUnit(unitID, newTeamID)
	GG.allowTransfer = true
	spTransferUnit(unitID, newTeamID, true)
	GG.allowTransfer = false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Activity updates

local playerIsAfk = {}
local function GetPlayerActivity(playerID, onlyActive)
	if not playerID then
		return false
	end
	local name, active, spec, team, allyTeam, ping, _, _, _, customKeys = spGetPlayerInfo(playerID)
	local doDebug = (debugPlayerLag and debugPlayerLag[playerID]) or debugPlayerLagAll
	if doDebug then
		Spring.Echo(" ======= Lagmonitor Debug Player " .. playerID .. " ======= ")
		Spring.Echo("onlyActive", onlyActive, "active", active, "ping", ping, "passTest", active and ping <= PING_TIMEOUT)
	end
	
	if onlyActive then
		if (active and ping <= PING_TIMEOUT) then
			return customKeys.elo and tonumber(customKeys.elo) or 0
		end
		return false
	end
	
	if doDebug then
		Spring.Echo("spec", spec, "passTest", spec or not (active and ping <= PING_TIMEOUT))
	end
	
	if spec or not (active and ping <= PING_TIMEOUT) then
		return false
	end
	
	local lastActionTime = spGetGameSeconds() - (mouseActivityTime[playerID] or 0)
	if doDebug then
		Spring.Echo("lastActionTime", lastActionTime, "useAfkDetection", useAfkDetection, "modopt", Spring.GetModOptions().enablelagmonitor, "passTest",
			useAfkDetection and (lastActionTime >= TO_AFK_THRESHOLD or lastActionTime >= FROM_AFK_THRESHOLD and playerIsAfk[playerID]))
	end
	
	if useAfkDetection and (lastActionTime >= TO_AFK_THRESHOLD or lastActionTime >= FROM_AFK_THRESHOLD and playerIsAfk[playerID]) then
		playerIsAfk[playerID] = true
		spSetPlayerRulesParam(playerID, "lagmonitor_lagging", 1)
		return false
	end
	
	if playerIsAfk[playerID] then
		spSetPlayerRulesParam(playerID, "lagmonitor_lagging", nil)
	end
	playerIsAfk[playerID] = false
	
	return customKeys.elo and tonumber(customKeys.elo) or 0
end

local function UpdateTeamActivity(teamID)
	local resourceShare = 0
	local teamRank = false
	local isHostedAi = false
	local isBackupAi = false
	local players = spGetPlayerList(teamID)
	for i = 1, #players do
		local activeRank = GetPlayerActivity(players[i])
		if activeRank then
			if resourceShare == 0 then
				resourceShare = 1
			else
				resourceShare = resourceShare + MERGE_SHARE
			end
			if (not teamRank) or (activeRank > teamRank) then
				teamRank = activeRank
			end
		end
	end
	
	local _, leaderID, _, isAiTeam, _, allyTeamID = spGetTeamInfo(teamID, false)
	if Spring.GetTeamRulesParam(teamID, "initialIsAiTeam") then
		if Spring.GetTeamLuaAI(teamID) then
			-- LuaAIs are always active, unless they exist for the purpose of backup.
			if Spring.GetTeamRulesParam(teamID, "backupai") == 1 then
				isBackupAi = true
			else
				resourceShare = resourceShare + 1
			end
		else
			isHostedAi = true
			local _, _, hostingPlayerID = Spring.GetAIInfo(teamID)
			-- isAiTeam is false for teams that were AI teams, but had their hosting player drop.
			-- AI teams without any hosting player are effectively dead.
			if GetPlayerActivity(hostingPlayerID, true) and isAiTeam then
				resourceShare = resourceShare + 1
			end
		end
	end
	
	if resourceShare > 0 and teamResourceShare[teamID] == 0 then
		local playerName = Spring.GetPlayerInfo(leaderID, false)
		local unitsRecieved = false
		
		if playerLineageUnits then
			local waitUnits = {}
			for unitID, playerList in pairs(playerLineageUnits) do --Return unit to the oldest inheritor (or to original owner if possible)
				local delete = false
				local unitAllyTeamID = spGetUnitAllyTeam(unitID)
				if unitAllyTeamID == allyTeamID then
					for i = 1, #playerList do
						local otherPlayerID = playerList[i]
						local otherTeamID = PlayerIDToTeamID(otherPlayerID)
						if (otherTeamID == teamID) then
							TransferUnit(unitID, teamID)
							unitsRecieved = true
							delete = true
							local bpHaver, hasWait = GetBpHaverAndWait(unitID)
							if bpHaver and hasWait then
								waitUnits[#waitUnits + 1] = unitID
							end
						end
						-- remove all teams after the previous owner (inclusive)
						if delete then
							playerLineageUnits[unitID][i] = nil
						end
					end
				end
			end
			
			if #waitUnits > 0 then
				spGiveOrderToUnitArray(waitUnits, CMD_WAIT, 0, 0)
			end
		end
		
		if unitsRecieved then
			spEcho("game_message: Player " .. playerName .. " is no longer lagging or AFK; returning all their units.")
		end
	end
	
	-- Note that AIs do not have a rank so a team with just an AI will have teamRank = false
	return resourceShare, teamRank, isHostedAi, isBackupAi
end

local function GetRawTeamShare(teamID)
	local _, _, isDead, isAiTeam = spGetTeamInfo(teamID, false)
	if isDead then
		return 0
	end

	local shares = 0
	if isAiTeam then
		shares = shares + 1
	end

	local players = spGetPlayerList(teamID)
	for i = 1, #players do
		local playerID = players[i]
		local _, active, spec = spGetPlayerInfo(playerID, false)
		if active and not spec then
			shares = shares + 1
		end
	end

	return shares
end

local function DoUnitGiveAway(allyTeamID, recieveTeamID, giveAwayTeams, doPlayerLineage)
	for i = 1, #giveAwayTeams do
		local giveTeamID = giveAwayTeams[i]
		local givePlayerID = doPlayerLineage and TeamIDToPlayerID(giveTeamID)
		
		-- Energy share is not set because the storage needs to be full for full overdrive.
		-- Also energy income is mostly private and a large energy influx to the rest of the
		-- team is likely to be wasted or overdriven inefficently.
		
		local units = spGetTeamUnits(giveTeamID) or {}
		if #units > 0 then -- transfer units when number of units in AFK team is > 0
			local waitUnits = {}
			-- Transfer Units
			for j = 1, #units do
				local unitID = units[j]
				if allyTeamID == spGetUnitAllyTeam(unitID) then
					if givePlayerID then
						-- add this team to the playerLineageUnits list, then send the unit away
						if not playerLineageUnits[unitID] then
							playerLineageUnits[unitID] = {givePlayerID}
						else
							-- this unit belonged to someone else before me, add me to the end of the list
							playerLineageUnits[unitID][#playerLineageUnits[unitID]+1] = givePlayerID
						end
					end
					TransferUnit(unitID, recieveTeamID)
					local bpHaver, hasWait = GetBpHaverAndWait(unitID)
					if bpHaver and not hasWait then
						waitUnits[#waitUnits + 1] = unitID
					end
				end
			end
			
			if #waitUnits > 0 then
				spGiveOrderToUnitArray(waitUnits, CMD_WAIT, 0, 0)
			end
		end
		
		local recieveName = GetTeamName(recieveTeamID)
		local giveName = GetTeamName(giveTeamID)
		local giveResigned = select(3, Spring.GetTeamInfo(giveTeamID, false))
		
		-- Send message
		if giveResigned then
			spEcho("game_message: " .. giveName .. " resigned, giving all units to " .. recieveName)
		elseif #units > 0 then
			spEcho("game_message: Giving all units of ".. giveName .. " to " .. recieveName .. " due to lag/AFK")
		end
	end
end

local function UpdateAllyTeamActivity(allyTeamID)
	local teamList = spGetTeamList(allyTeamID)
	
	local totalResourceShares = 0
	local giveAwayTeams = {}
	local giveAwayAiTeams = {}
	local recieveRank = false
	local recieveTeamID = false
	local recieveAiTeamID = false
	local backupAiTeam = false
	
	if debugAllyTeam and debugAllyTeam[allyTeamID] then
		Spring.Echo(" ======= Lagmonitor Debug " .. allyTeamID .. " ======= ")
	end
	
	for i = 1, #teamList do
		local teamID = teamList[i]
		local resourceShare, teamRank, isHostedAiTeam, isBackupAi = UpdateTeamActivity(teamID)
		totalResourceShares = totalResourceShares + resourceShare
		if debugAllyTeam and debugAllyTeam[allyTeamID] then
			local _, leader = Spring.GetTeamInfo(teamID)
			local name = leader and Spring.GetPlayerInfo(leader)
			Spring.Echo("playerID", leader or "none", "name", name or "none", "teamID", teamID, "share", resourceShare, "rank", teamRank, "isHostedAi", isHostedAiTeam, "isBackup", isBackupAi)
		end
		
		if not isBackupAi then
			if resourceShare == 0 then
				if teamResourceShare[teamID] ~= 0 then
					-- The team is newly afk.
					if isHostedAiTeam then
						giveAwayAiTeams[#giveAwayAiTeams + 1] = teamID
					else
						giveAwayTeams[#giveAwayTeams + 1] = teamID
					end
				end
			elseif isHostedAiTeam then
				recieveAiTeamID = teamID
			elseif teamRank and ((not recieveRank) or (teamRank > recieveRank)) then
				recieveRank = teamRank
				recieveTeamID = teamID
			end
		else
			backupAiTeam = teamID
		end
		
		teamResourceShare[teamID] = resourceShare
	end
	
	if debugAllyTeam and debugAllyTeam[allyTeamID] then
		Spring.Echo("totalResourceShares", totalResourceShares)
	end
	
	-- The backup AI team should be a LuaAI that exists only to take over from the circuitAIs.
	if backupAiTeam and not recieveAiTeamID then
		-- Remove backup status to give the team a resource share, and because circuitAIs cannot be reinitialised.
		Spring.SetTeamRulesParam(backupAiTeam, "backupai", 0)
		recieveAiTeamID = backupAiTeam
		totalResourceShares = totalResourceShares + 1 -- The backup did not count for resource shares.
		teamResourceShare[backupAiTeam] = 1
	end
	
	--for i = 1, #teamList do
	--	Spring.Echo("teamResourceShare[teamID]", teamList[i], teamResourceShare[teamList[i]])
	--end
	--if allyTeamID < 2 then
	--	Spring.Echo("totalResourceShares", recieveTeamID, totalResourceShares, recieveAiTeamID, backupAiTeam)
	--end
	
	if recieveAiTeamID then
		DoUnitGiveAway(allyTeamID, recieveAiTeamID, giveAwayAiTeams, false)
	end
	
	if recieveTeamID then
		DoUnitGiveAway(allyTeamID, recieveTeamID, giveAwayTeams, true)
	else
		-- Nobody can receive units, send resigned messages anyway
		for i = 1, #giveAwayTeams do
			local giveTeamID = giveAwayTeams[i]
			local giveResigned = select(3, Spring.GetTeamInfo(giveTeamID, false))
			if giveResigned then
				spEcho("game_message: " .. GetTeamName(giveTeamID) .. " resigned")
			end
		end
	end
	
	allyTeamResourceShares[allyTeamID] = totalResourceShares
end

local function InitializeAiTeamRulesParams()
	local teamList = spGetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, leaderID, _, isAiTeam, _, _, customKeys = spGetTeamInfo(teamID)
		if isAiTeam then
			Spring.SetTeamRulesParam(teamList[i], "initialIsAiTeam", 1)
		end
		if customKeys.backupai then
			Spring.SetTeamRulesParam(teamID, "backupai", 1)
		end
	end
end

function gadget:GameFrame(n)
	if n == 0 then
		InitializeAiTeamRulesParams()
	end
	if n % TEAM_SLOWUPDATE_RATE == 0 then -- Just before overdrive
		local allyTeamList = Spring.GetAllyTeamList()
		--Spring.Echo("============================")
		for i = 1, #allyTeamList do
			UpdateAllyTeamActivity(allyTeamList[i])
		end
	end
end

function gadget:GameOver()
	gadgetHandler:RemoveGadget() --shutdown after game over, so that at end of a REPLAY Lagmonitor doesn't bounce unit among player
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function LagmonitorDebugToggle(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	local allyTeamID = tonumber(words[1])
	Spring.Echo("Debug Lagmonitor for allyTeam " .. (allyTeamID or "nil"))
	if allyTeamID then
		if not debugAllyTeam then
			debugAllyTeam = {}
		end
		if debugAllyTeam[allyTeamID] then
			debugAllyTeam[allyTeamID] = nil
			if #debugAllyTeam == 0 then
				debugAllyTeam = {}
			end
			Spring.Echo("Disabled")
		else
			debugAllyTeam[allyTeamID] = true
			Spring.Echo("Enabled")
		end
	end
end

local function LagmonitorDebugPlayerToggle(cmd, line, words, player)
	if not Spring.IsCheatingEnabled() then
		return
	end
	local playerID = tonumber(words[1])
	Spring.Echo("Debug Lagmonitor for playerID " .. (playerID or "nil"))
	if playerID then
		if not debugPlayerLag then
			debugPlayerLag = {}
		end
		if debugPlayerLag[playerID] then
			debugPlayerLag[playerID] = nil
			if #debugPlayerLag == 0 then
				debugPlayerLag = {}
			end
			Spring.Echo("Disabled")
		else
			debugPlayerLag[playerID] = true
			Spring.Echo("Enabled")
		end
	else
		debugPlayerLagAll = not debugPlayerLagAll
	end
end

----------------------------------------------------------------------------------------
-- External Functions
----------------------------------------------------------------------------------------
local externalFunctions = {}
function externalFunctions.GetResourceShares()
	return allyTeamResourceShares, teamResourceShare
end

function gadget:Initialize()
	local teamList = spGetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, playerID, _, isAI, _, allyTeamID = Spring.GetTeamInfo(teamID, false)
		teamResourceShare[teamID] = 1
		allyTeamResourceShares[allyTeamID] = (allyTeamResourceShares[allyTeamID] or 0) + 1

		if isAI then
			teamNames[teamID] = select(2, Spring.GetAIInfo(teamID))
		else
			teamNames[teamID] = Spring.GetPlayerInfo(playerID, false)
		end
	end

	GG.Lagmonitor = externalFunctions
	if useAfkDetection then
		Spring.SetGameRulesParam("lagmonitor_seconds", TO_AFK_THRESHOLD)
	end

	gadgetHandler:AddChatAction("debuglag", LagmonitorDebugToggle, "Toggles Lagmonitor debug.")
	gadgetHandler:AddChatAction("debuglagplayer", LagmonitorDebugPlayerToggle, "Toggles Lagmonitor debug.")
end
