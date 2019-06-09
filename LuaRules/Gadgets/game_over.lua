--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name      = "Game Over",
		desc      = "GAME OVER!! (handles conditions thereof)",
		author    = "SirMaverick, Google Frog, KDR_11k, CarRepairer (unified by KingRaptor)",
		date      = "2009",
		license   = "GPL",
		layer     = 1, 
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--	End game if only one allyteam with players AND units is left.
--	An allyteam is counted as dead if none of
--	its active players have units left.
--------------------------------------------------------------------------------

local isScriptMission = VFS.FileExists("mission.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetTeamInfo       = Spring.GetTeamInfo
local spGetTeamList       = Spring.GetTeamList
local spGetTeamUnits      = Spring.GetTeamUnits
local spDestroyUnit       = Spring.DestroyUnit
local spGetAllUnits       = Spring.GetAllUnits
local spGetAllyTeamList   = Spring.GetAllyTeamList
local spGetPlayerInfo     = Spring.GetPlayerInfo
local spGetPlayerList     = Spring.GetPlayerList
local spAreTeamsAllied    = Spring.AreTeamsAllied
local spGetUnitTeam       = Spring.GetUnitTeam
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spTransferUnit      = Spring.TransferUnit
local spGetGameRulesParam = Spring.GetGameRulesParam
local spKillTeam          = Spring.KillTeam
local spGameOver          = Spring.GameOver
local spEcho              = Spring.Echo

local COMM_VALUE = UnitDefNames.armcom1.metalCost or 1200
local ECON_SUPREMACY_MULT = 25
local MISSION_PLAYER_ALLY_TEAM_ID = 0

local SPARE_PLANETWARS_UNITS = false
local SPARE_REGULAR_UNITS = false

local DEBUG_MSG = false

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local gaiaTeamID = Spring.GetGaiaTeamID()
local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(gaiaTeamID, false))
local chickenAllyTeamID

local aliveCount = {}
local aliveValue = {}
local destroyedAlliances = {}
local allianceToReveal

local finishedUnits = {} -- this stores a list of all units that have ever been completed, so it can distinguish between incomplete and partly reclaimed units
local toDestroy = {}
local alliancesToDestroy

local modOptions = Spring.GetModOptions() or {}
local commends = tobool(modOptions.commends)
local noElo = tobool(modOptions.noelo)
local campaignBattleID = Spring.GetModOptions().singleplayercampaignbattleid and true
local planetIndex = Spring.GetModOptions().singleplayercampaignbattleid
planetIndex = planetIndex and tonumber(planetIndex)

local revealed = false
local gameIsOver = false
local gameOverSent = false

local inactiveWinAllyTeam = false

local nilUnitDef = {id=-1}
local function GetUnitDefIdByName(defName)
  return (UnitDefNames[defName] or nilUnitDef).id
end

local doesNotCountList 
if campaignBattleID then
	doesNotCountList = {
		[GetUnitDefIdByName("terraunit")] = true,
	}
else
	doesNotCountList = {
		[GetUnitDefIdByName("spiderscout")] = true,
		[GetUnitDefIdByName("shieldbomb")] = true,
		[GetUnitDefIdByName("cloakbomb")] = true,
		[GetUnitDefIdByName("amphbomb")] = true,
		[GetUnitDefIdByName("gunshipbomb")] = true,
		[GetUnitDefIdByName("terraunit")] = true,
	}

	-- auto detection of doesnotcount units
	for name, ud in pairs(UnitDefs) do
		if (ud.customParams.dontcount) then
			doesNotCountList[ud.id] = true
		elseif (ud.isFeature) then
			doesNotCountList[ud.id] = true
		elseif (not ud.canAttack) and (not ud.speed) and (not ud.isFactory) then
			doesNotCountList[ud.id] = true
		end
	end
end

local commsAlive = {}
local allyTeams = spGetAllyTeamList()
for i = 1, #allyTeams do
	commsAlive[allyTeams[i]] = {}
end

local aiTeamResign = not (isScriptMission or campaignBattleID or (Spring.GetModOptions().disableAiTeamResign == 1))

local vitalConstructorAllyTeam = {}
local vitalAlive = {}
for i = 1, #allyTeams do
	local allyTeamID = allyTeams[i]
	vitalAlive[allyTeamID] = {}
	if aiTeamResign then
		local teamList = Spring.GetTeamList(allyTeamID)
		vitalConstructorAllyTeam[allyTeamID] = true
		for j = 1, #teamList do
			local isAiTeam = select(4, Spring.GetTeamInfo(teamList[j], false))
			if not isAiTeam then
				vitalConstructorAllyTeam[allyTeamID] = false
				break
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Mission handling
--------------------------------------------------------------------------------
local isMission = (Spring.GetModOptions().singleplayercampaignbattleid and true) or false

local PLAYER_ALLY_TEAM_ID = 0
local PLAYER_TEAM_ID = 0
local function KillTeam(teamID)
	if isMission then
		if teamID == PLAYER_TEAM_ID then
			GG.MissionGameOver(false)
		end
	else
		spKillTeam(teamID)
	end
end

local function SetGameOver(winningAllyTeamID)
	if DEBUG_MSG then
		Spring.Echo("GameOver", winningAllyTeamID)
	end
	if isMission then
		if winningAllyTeamID == PLAYER_ALLY_TEAM_ID then
			GG.MissionGameOver(true)
		end
	else
		spGameOver({winningAllyTeamID})
	end
end

function GG.IsAllyTeamAlive(allyTeamID)
	return not destroyedAlliances[allyTeamID]
end

--------------------------------------------------------------------------------
-- local funcs
--------------------------------------------------------------------------------
local function GetTeamIsChicken(teamID)
	local luaAI = Spring.GetTeamLuaAI(teamID)
	if luaAI and string.find(string.lower(luaAI), "chicken") then
		return true
	end
	return false
end

local function CountAllianceUnits(allianceID)
	local teamlist = spGetTeamList(allianceID) or {}
	local count = 0
	for i=1,#teamlist do
		local teamID = teamlist[i]
		count = count + (aliveCount[teamID] or 0)
		if (GG.waitingForComm or {})[teamID] then
			count = count + 1
		end
	end
	return count
end

local function CountAllianceValue(allianceID)
	local teamlist = spGetTeamList(allianceID) or {}
	local value = 0
	for i=1,#teamlist do
		local teamID = teamlist[i]
		value = value + (aliveValue[teamID] or 0)
		if (GG.waitingForComm or {})[teamID] then
			value = value + COMM_VALUE
		end
	end
	return value
end

local function HasNoComms(allianceID)
	return not next(commsAlive[allianceID])
end

local function HasNoVitalUnits(allianceID)
	return not next(vitalAlive[allianceID])
end

local function EchoUIMessage(message)
	spEcho("game_message: " .. message)
end

local function UnitWithinBounds(unitID)
	local x, y, z = Spring.GetUnitPosition(unitID)
	return (x > -500) and (x < Game.mapSizeX + 500) and (y > -1000) and (z > -500) and (z < Game.mapSizeZ + 500)
end

local function Draw() -- declares a draw
	if gameOverSent then
		return
	end
	EchoUIMessage("The game ended in a draw!")
	SetGameOver(gaiaAllyTeamID) -- exit uses {} so use Gaia for draw to differentiate
	gameOverSent = true
end

-- if only one allyteam left, declare it the victor
local function CheckForVictory()
	if DEBUG_MSG then
		Spring.Echo("CheckForVictory")
	end
	if Spring.IsCheatingEnabled() or gameOverSent then
		return
	end
	local allylist = spGetAllyTeamList()
	local count = 0
	local lastAllyTeam
	for _,a in pairs(allylist) do
		if not destroyedAlliances[a] and (a ~= gaiaAllyTeamID) then
			--Spring.Echo("Alliance " .. a .. " remains in the running")
			count = count + 1
			lastAllyTeam = a
		end
	end
	if count < 2 then
		if ((not lastAllyTeam) or (count == 0)) then
			Draw()
		else
			if not (isMission or isScriptMission) then
				local name = Spring.GetGameRulesParam("allyteam_long_name_" .. lastAllyTeam)
				EchoUIMessage(name .. " wins!")
			end
			SetGameOver(lastAllyTeam)
			gameOverSent = true
		end
	end
end

local function RevealAllianceUnits(allianceID)
	if DEBUG_MSG then
		Spring.Echo("RevealAllianceUnits", allianceID)
	end
	allianceToReveal = allianceID
	local teamList = spGetTeamList(allianceID)
	for i=1,#teamList do
		local t = teamList[i]
		local teamUnits = spGetTeamUnits(t) 
		for j=1,#teamUnits do
			local unitID = teamUnits[j]
			-- purge extra-map units
			if not UnitWithinBounds(unitID) then
				Spring.DestroyUnit(unitID)
			else
				Spring.SetUnitAlwaysVisible(unitID, true)
			end
		end
	end
end

-- purge the alliance! for the horde!
local function DestroyAlliance(allianceID, delayLossToNextGameFrame)
	if DEBUG_MSG then
		Spring.Echo("DestroyAlliance", allianceID, delayLossToNextGameFrame)
	end
	if delayLossToNextGameFrame then
		alliancesToDestroy = alliancesToDestroy or {}
		alliancesToDestroy[#alliancesToDestroy + 1] = allianceID
		return
	end
	if not destroyedAlliances[allianceID] then
		destroyedAlliances[allianceID] = true
		local teamList = spGetTeamList(allianceID)
		if teamList == nil or (#teamList == 0) then 
			return -- empty allyteam, don't bother
		end
		
		local explodeUnits = true
		if GG.GalaxyCampaignHandler then
			local defeatConfig = GG.GalaxyCampaignHandler.GetDefeatConfig(allianceID)
			if defeatConfig then
				if defeatConfig.allyTeamLossObjectiveID then
					local objParameter = "objectiveSuccess_" .. defeatConfig.allyTeamLossObjectiveID
					Spring.SetGameRulesParam(objParameter, (Spring.GetGameRulesParam(objParameter) or 0) + ((allianceID == MISSION_PLAYER_ALLY_TEAM_ID and 0) or 1))
				end
				if defeatConfig.defeatOtherAllyTeamsOnLoss then
					local otherTeams = defeatConfig.defeatOtherAllyTeamsOnLoss
					for i = 1, #otherTeams do
						DestroyAlliance(otherTeams[i])
					end
				end
				if defeatConfig.doNotExplodeOnLoss then
					explodeUnits = false
				end
			end
		end
		
		if Spring.IsCheatingEnabled() then
			EchoUIMessage("Game Over: DEBUG")
			EchoUIMessage("Game Over: Allyteam " .. allianceID .. " has met the game over conditions.")
			EchoUIMessage("Game Over: If this is true, then please resign.")
			return -- don't perform victory check
		else -- kaboom
			if not (isMission or isScriptMission) then
				local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allianceID)
				EchoUIMessage(name .. " has been destroyed!")
			end

			local frame = Spring.GetGameFrame() + 50
			local function QueueDestruction(unitID)
				local destroyFrame = frame - math.ceil((math.random()*7)^2)
				toDestroy[destroyFrame] = toDestroy[destroyFrame] or {}
				toDestroy[destroyFrame][unitID] = true
			end

			for i = 1, #teamList do
				local t = teamList[i]
				
				if explodeUnits then
					local teamUnits = spGetTeamUnits(t) 
					for j = 1, #teamUnits do
						local unitID = teamUnits[j]
						local pwUnits = (GG.PlanetWars or {}).unitsByID
						if pwUnits and pwUnits[unitID] then
							if SPARE_PLANETWARS_UNITS then
								GG.allowTransfer = true
								spTransferUnit(unitID, gaiaTeamID, true)		-- don't blow up PW buildings
								GG.allowTransfer = false
							else
								QueueDestruction(unitID)
							end
						elseif not SPARE_REGULAR_UNITS then
							QueueDestruction(unitID)
						end
					end
				end
				Spring.SetTeamRulesParam(t, "isDead", 1, {public = true})
				KillTeam(t)
			end
		end
	end
	CheckForVictory()
end
GG.DestroyAlliance = DestroyAlliance

local function CauseVictory(allyTeamID)
	if DEBUG_MSG then
		Spring.Echo("CauseVictory", allyTeamID)
	end
	local allylist = spGetAllyTeamList()
	local count = 0
	for _,a in pairs(allylist) do
		if a ~= allyTeamID and a ~= gaiaAllyTeamID then
			DestroyAlliance(a)
		end
	end
	--GameOver(lastAllyTeam)
end
GG.CauseVictory = CauseVictory

local function CanAddCommander()
	if not isScriptMission then
		return true
	end
	local frame = Spring.GetGameFrame()
	return frame < 10
end

local function AddAllianceUnit(unitID, unitDefID, teamID)
	if DEBUG_MSG then
		Spring.Echo("AddAllianceUnit", unitID, unitDefID, teamID)
	end
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID, false)
	aliveCount[teamID] = aliveCount[teamID] + 1
	
	aliveValue[teamID] = aliveValue[teamID] + UnitDefs[unitDefID].metalCost

	if CanAddCommander() and UnitDefs[unitDefID].customParams.commtype then
		commsAlive[allianceID][unitID] = true
	end
	
	if GG.GalaxyCampaignHandler and GG.GalaxyCampaignHandler.VitalUnit(unitID) then
		vitalAlive[allianceID][unitID] = true
	elseif vitalConstructorAllyTeam[allianceID] then
		local ud = UnitDefs[unitDefID]
		if ud.isBuilder or ud.isFactory then
			vitalAlive[allianceID][unitID] = true
		end
	end
end

local function CheckMissionDefeatOnUnitLoss(unitID, allianceID)
	if DEBUG_MSG then
		Spring.Echo("CheckMissionDefeatOnUnitLoss", unitID, allianceID)
	end
	local defeatConfig = GG.GalaxyCampaignHandler.GetDefeatConfig(allianceID)
	if defeatConfig.ignoreUnitLossDefeat then
		return false
	end
	if defeatConfig.defeatIfUnitDestroyed and defeatConfig.defeatIfUnitDestroyed[unitID] then
		if (not gameOverSent) and type(defeatConfig.defeatIfUnitDestroyed[unitID]) == "number" then
			local objParameter = "objectiveSuccess_" .. defeatConfig.defeatIfUnitDestroyed[unitID]
			local value = (allianceID == MISSION_PLAYER_ALLY_TEAM_ID and 0) or 1
			Spring.SetGameRulesParam(objParameter, (Spring.GetGameRulesParam(objParameter) or 0) + value)
		end
		return true
	end
	if not (defeatConfig.vitalCommanders or defeatConfig.vitalUnitTypes) then
		return (CountAllianceUnits(allianceID) <= 0) -- Default loss condition
	end
	if defeatConfig.vitalCommanders and not HasNoComms(allianceID) then
		return false
	end
	if defeatConfig.vitalUnitTypes and not HasNoVitalUnits(allianceID) then
		return false
	end
	return true
end

local function RemoveAllianceUnit(unitID, unitDefID, teamID, delayLossToNextGameFrame)
	if DEBUG_MSG then
		Spring.Echo("RemoveAllianceUnit", unitID, unitDefID, teamID, delayLossToNextGameFrame)
	end
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID, false)
	aliveCount[teamID] = aliveCount[teamID] - 1
	
	aliveValue[teamID] = aliveValue[teamID] - UnitDefs[unitDefID].metalCost
	if aliveValue[teamID] < 0 then
		aliveValue[teamID] = 0
	end

	if UnitDefs[unitDefID].customParams.commtype then
		commsAlive[allianceID][unitID] = nil
	end
	
	if vitalAlive[allianceID] and vitalAlive[allianceID][unitID] then
		vitalAlive[allianceID][unitID] = nil
	end

	if allianceID == chickenAllyTeamID then
		return
	end
	
	if campaignBattleID then
		if CheckMissionDefeatOnUnitLoss(unitID, allianceID) then
			Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Game Over> Purging allyTeam " .. allianceID)
			DestroyAlliance(allianceID, delayLossToNextGameFrame)
		end
		return
	elseif vitalConstructorAllyTeam[allianceID] and HasNoVitalUnits(allianceID) then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Game Over> Purging allyTeam " .. allianceID)
		DestroyAlliance(allianceID, delayLossToNextGameFrame)
	end
	
	if (CountAllianceUnits(allianceID) <= 0) or (commends and HasNoComms(allianceID)) then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Game Over> Purging allyTeam " .. allianceID)
		DestroyAlliance(allianceID, delayLossToNextGameFrame)
	end
end

local function CompareArmyValues(ally1, ally2)
	local value1, value2 = CountAllianceValue(ally1), CountAllianceValue(ally2)
	if value1 > ECON_SUPREMACY_MULT*value2 then
		return ally1
	elseif value2 > ECON_SUPREMACY_MULT*value1 then
		return ally2
	end
	return nil
end

-- used during initialization
local function CheckAllUnits()
	aliveCount = {}
	local teams = spGetTeamList()
	for i=1,#teams do
		local teamID = teams[i]
		if teamID ~= gaiaTeamID then
			aliveCount[teamID] = 0
		end
	end
	local units = spGetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local teamID = spGetUnitTeam(unitID)
		local unitDefID = spGetUnitDefID(unitID)
		gadget:UnitFinished(unitID, unitDefID, teamID)
	end
end

-- check for active players
local function ProcessLastAlly()
	if DEBUG_MSG then
		Spring.Echo("ProcessLastAlly")
	end
	if Spring.IsCheatingEnabled() then
		return
	end
	local allylist = spGetAllyTeamList()
	local activeAllies = {}
	local droppedAllies = {}
	local lastActive = nil
	for i = 1, #allylist do
		repeat
		local a = allylist[i]
		if (a == gaiaAllyTeamID) then break end -- continue
		if (destroyedAlliances[a]) then break end -- continue
		local teamlist = spGetTeamList(a)
		if (not teamlist) then break end -- continue
		local hasActiveTeam = false
		local hasDroppedTeam = false
		for i=1,#teamlist do
			local t = teamlist[i]
			-- any team without units is dead to us; so only teams who are active AND have units matter
			-- except chicken, who are alive even without units
			local numAlive = aliveCount[t]
			if #(Spring.GetTeamUnits(t)) == 0 then numAlive = 0 end
			if (numAlive > 0) or (GG.waitingForComm or {})[t] or (GetTeamIsChicken(t)) then	
				-- count AI teams as active
				local _,_,_,isAiTeam = spGetTeamInfo(t, false)
				if isAiTeam then
					hasActiveTeam = true
				else
					local playerlist = spGetPlayerList(t) -- active players
					if playerlist then
						for j = 1, #playerlist do
							local name,active,spec = spGetPlayerInfo(playerlist[j], false)
							if not spec then
								if active then
									hasActiveTeam = true
								else
									hasDroppedTeam = true
								end
							else
							end
						end
					end
				end
			end
		end
		if hasActiveTeam then
			activeAllies[#activeAllies+1] = a
			lastActive = a
		elseif hasDroppedTeam then
			droppedAllies[#droppedAllies+1] = a
		end
		until true
	end -- for
	
	if #activeAllies > 1 and inactiveWinAllyTeam then
		inactiveWinAllyTeam = false
		Spring.SetGameRulesParam("inactivity_win", -1)
	end
	
	if #activeAllies == 2 then
		if revealed or activeAllies[1] == chickenAllyTeamID or activeAllies[2] == chickenAllyTeamID then
			return
		end
		-- run value comparison
		local supreme = (not campaignBattleID) and CompareArmyValues(activeAllies[1], activeAllies[2])
		if supreme then
			EchoUIMessage("AllyTeam " .. supreme .. " has an overwhelming numerical advantage!")
			for i=1, #allylist do
				local a = allylist[i]
				if (a ~= supreme) and (a ~= gaiaAllyTeamID) then
					RevealAllianceUnits(a)
					revealed = true
				end
			end
		end
	elseif #activeAllies < 2 then
		if #droppedAllies > 0 then
			if lastActive then
				inactiveWinAllyTeam = lastActive
				Spring.SetGameRulesParam("inactivity_win", lastActive)
			else
				Draw()
			end
		else
			if #activeAllies == 1 then
				-- remove every unit except for last active alliance
				for i=1, #allylist do
					local a = allylist[i]
					if (a ~= lastActive) and (a ~= gaiaAllyTeamID) then
						DestroyAlliance(a)
					end
				end
			else -- no active team. For example two roaches were left and blew up each other
				Draw()
			end
		end
	end
end

local function CheckInactivityWin(cmd, line, words, player)
	if DEBUG_MSG then
		Spring.Echo("ProcessLastAlly", cmd, line, words, player)
	end
	if inactiveWinAllyTeam and not gameIsOver then
		if player then 
			local name,_,spec,_,allyTeamID = Spring.GetPlayerInfo(player, false)
			if allyTeamID == inactiveWinAllyTeam and not spec then
				Spring.Echo((name or "") .. " has forced a win due to dropped opposition.")
				CauseVictory(inactiveWinAllyTeam)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function gadget:TeamDied (teamID)
	if DEBUG_MSG then
		Spring.Echo("gadget:TeamDied", teamID)
	end
	if not gameIsOver then
		ProcessLastAlly()
	end
end

-- supposed to solve game over not being called when resigning during pause
-- not actually called yet (PlayerChanged is unsynced at present)
function gadget:PlayerChanged (playerID)
	if gameIsOver then
		return
	end

	ProcessLastAlly()
end

function gadget:UnitFinished(unitID, unitDefID, teamID)
	if (teamID ~= gaiaTeamID) and (not doesNotCountList[unitDefID]) and (not finishedUnits[unitID]) then
		finishedUnits[unitID] = true
		AddAllianceUnit(unitID, unitDefID, teamID)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	if revealed then
		local allyTeam = select(6, spGetTeamInfo(teamID, false))
		if allyTeam == allianceToReveal then
			Spring.SetUnitAlwaysVisible(unitID, true)
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, teamID)
	if spGetGameRulesParam("loadPurge") == 1 then
		return
	end
	
	if (teamID ~= gaiaTeamID)
	  and(not doesNotCountList[unitDefID])
	  and finishedUnits[unitID]
	then
		finishedUnits[unitID] = nil
		RemoveAllianceUnit(unitID, unitDefID, teamID)
	end
end

-- note: Taken comes before Given
function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeamID)
	if (newTeam ~= gaiaTeamID)
	  and (not doesNotCountList[unitDefID])
	  and finishedUnits[unitID]
	then
		AddAllianceUnit(unitID, unitDefID, newTeam)
	end
end

function gadget:UnitTaken(unitID, unitDefID, oldTeamID, newTeam)
	if (oldTeamID ~= gaiaTeamID)
	  and (not doesNotCountList[unitDefID])
	  and finishedUnits[unitID]
	then
		RemoveAllianceUnit(unitID, unitDefID, oldTeamID, true)
	end
end

function gadget:Initialize()
	local teams = spGetTeamList()
	for i=1,#teams do
		aliveValue[teams[i]] = 0
		if GetTeamIsChicken(teams[i]) then
			Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Game Over> Chicken team found")
			chickenAllyTeamID = select(6, Spring.GetTeamInfo(teams[i], false))
			--break
		end
	end
	CheckAllUnits()
	
	gadgetHandler:AddChatAction('inactivitywin', CheckInactivityWin, "")
	
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "Game Over initialized")
end

function gadget:GameFrame(n)
	if toDestroy[n] then
		for unitID in pairs(toDestroy[n]) do
			if Spring.ValidUnitID(unitID) then
				local allyTeamID = Spring.GetUnitAllyTeam(unitID)
				if destroyedAlliances[allyTeamID] then
					spDestroyUnit(unitID, true)
				end
			end
		end
		toDestroy[n] = nil
	end
	
	
	if alliancesToDestroy then
		for i = 1, #alliancesToDestroy do
			DestroyAlliance(alliancesToDestroy[i])
		end
		alliancesToDestroy = nil
	end
	
	-- check for last ally:
	-- end condition: only 1 ally with human players, no AIs in other ones
	if (n % 45 == 0) then
		if not gameIsOver and not spGetGameRulesParam("loadedGame") then
			if DEBUG_MSG then
				Spring.Echo("planetIndex", planetIndex, type(planetIndex))
			end
			if planetIndex ~= 18 then
				ProcessLastAlly()
			end
		end
	end
end

function gadget:GameOver()
	if DEBUG_MSG then
		Spring.Echo("gadget:GameOver")
	end
	gameIsOver = true
	if noElo then
		Spring.SendCommands("wbynum 255 SPRINGIE:noElo")
	end
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "GAME OVER!!")
end
