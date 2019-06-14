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
local teamResourceShare = {}
local allyTeamResourceShares = {}
local unitAlreadyFinished = {}

local spAddTeamResource   = Spring.AddTeamResource
local spEcho              = Spring.Echo
local spGetGameSeconds    = Spring.GetGameSeconds
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetTeamInfo       = Spring.GetTeamInfo
local spGetTeamList       = Spring.GetTeamList
local spGetTeamResources  = Spring.GetTeamResources
local spGetTeamUnits      = Spring.GetTeamUnits
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitTeam       = Spring.GetUnitTeam
local spGetPlayerList     = Spring.GetPlayerList
local spTransferUnit      = Spring.TransferUnit
local spUseTeamResource   = Spring.UseTeamResource
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetUnitHealth     = Spring.GetUnitHealth
local spSetUnitHealth     = Spring.SetUnitHealth

local useAfkDetection = (Spring.GetModOptions().enablelagmonitor ~= "0")

include("LuaRules/Configs/constants.lua")

-- in seconds. The delay considered is (ping + time spent afk)
local TO_AFK_THRESHOLD = 30 -- going above this marks you AFK
local FROM_AFK_THRESHOLD = 5 -- going below this marks you non-AFK
local PING_TIMEOUT = 2000 -- ms

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Factory and Lineage

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if GG.wasMorphedTo and GG.wasMorphedTo[unitID] then --copy playerLineageUnits for unit Morph
		local newUnitID = GG.wasMorphedTo[unitID]
		local originalPlayerIDs = playerLineageUnits[unitID]
		if originalPlayerIDs ~= nil and #originalPlayerIDs > 0 then
			-- playerLineageUnits of the morphed unit will be the same as its pre-morph
			playerLineageUnits[newUnitID] = {unpack(originalPlayerIDs)} --NOTE!: this copy value to new table instead of copying table-reference (to avoid bug)
		end
		unitAlreadyFinished[newUnitID] = true --for reverse build -- what is reverse build?
	end

	playerLineageUnits[unitID] = nil --to delete any units that do not need returning.
	unitAlreadyFinished[unitID] = nil
end

function gadget:UnitFinished(unitID, unitDefID, unitTeam)
	if unitAlreadyFinished[unitID] or not playerLineageUnits[unitID] then
		return
	end

	if Spring.GetUnitRulesParam(unitID, "ploppee") then
		return
	end

	unitAlreadyFinished[unitID] = true
	playerLineageUnits[unitID] = {}
end

local mouseActivityTime = {}

function gadget:RecvLuaMsg(msg, playerID)
	if msg:find("AFK",1,true) then
		mouseActivityTime[playerID] = tonumber(msg:sub(4))
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
	
	if onlyActive then
		if (active and ping <= PING_TIMEOUT) then
			return customKeys.elo and tonumber(customKeys.elo) or 0
		end
		return false
	end
	
	if spec or not (active and ping <= PING_TIMEOUT) then
		return false
	end
	
	local lastActionTime = spGetGameSeconds() - (mouseActivityTime[playerID] or 0)
	
	if useAfkDetection and (lastActionTime >= TO_AFK_THRESHOLD or lastActionTime >= FROM_AFK_THRESHOLD and playerIsAfk[playerID]) then
		playerIsAfk[playerID] = true
		return false
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
			resourceShare = resourceShare + 1
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
					end
					-- remove all teams after the previous owner (inclusive)
					if delete then
						playerLineageUnits[unitID][i] = nil
					end
				end
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
			-- Transfer Units
			for j = 1, #units do
				local unitID = units[j]
				if allyTeamID == spGetUnitAllyTeam(unitID) then
					if givePlayerID then
						-- add this team to the playerLineageUnits list, then send the unit away
						if playerLineageUnits[unitID] == nil then
							playerLineageUnits[unitID] = {givePlayerID}
						else
							-- this unit belonged to someone else before me, add me to the end of the list
							playerLineageUnits[unitID][#playerLineageUnits[unitID]+1] = givePlayerID
						end
					end
					TransferUnit(unitID, recieveTeamID)
				end
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
	local teamList = Spring.GetTeamList(allyTeamID)
	
	local totalResourceShares = 0
	local giveAwayTeams = {}
	local giveAwayAiTeams = {}
	local recieveRank = false
	local recieveTeamID = false
	local recieveAiTeamID = false
	local backupAiTeam = false
	
	for i = 1, #teamList do
		local teamID = teamList[i]
		local resourceShare, teamRank, isHostedAiTeam, isBackupAi = UpdateTeamActivity(teamID)
		totalResourceShares = totalResourceShares + resourceShare
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
	local teamList = Spring.GetTeamList()
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

----------------------------------------------------------------------------------------
-- External Functions
----------------------------------------------------------------------------------------
local externalFunctions = {}
function externalFunctions.GetResourceShares()
	return allyTeamResourceShares, teamResourceShare
end

function gadget:Initialize()
	local teamList = Spring.GetTeamList()
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
end
