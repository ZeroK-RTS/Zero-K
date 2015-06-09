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

--if Spring.GetModOption("zkmode",false,nil) == nil then
--	Spring.Echo("game_message: <Game Over> Testing mode. Gadget removed.")
--	return
--end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetTeamInfo     = Spring.GetTeamInfo
local spGetTeamList     = Spring.GetTeamList
local spGetTeamUnits    = Spring.GetTeamUnits
local spDestroyUnit     = Spring.DestroyUnit
local spGetAllUnits     = Spring.GetAllUnits
local spGetAllyTeamList = Spring.GetAllyTeamList
local spGetPlayerInfo	= Spring.GetPlayerInfo
local spGetPlayerList	= Spring.GetPlayerList
local spAreTeamsAllied  = Spring.AreTeamsAllied
local spGetUnitTeam     = Spring.GetUnitTeam
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitIsStunned= Spring.GetUnitIsStunned
local spGetUnitHealth   = Spring.GetUnitHealth
local spGetUnitAllyTeam = Spring.GetUnitAllyTeam
local spTransferUnit	= Spring.TransferUnit
spGetGameRulesParam     = Spring.GetGameRulesParam
local spKillTeam	= Spring.KillTeam
local spGameOver	= Spring.GameOver
local spEcho       = Spring.Echo

local COMM_VALUE = UnitDefNames.armcom1.metalCost or 1200
local ECON_SUPREMACY_MULT = 25

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------
local gaiaTeamID = Spring.GetGaiaTeamID()
local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(gaiaTeamID))
local chickenAllyTeamID

local aliveCount = {}
local aliveValue = {}
local destroyedAlliances = {}
local allianceToReveal

local finishedUnits = {}	-- this stores a list of all units that have ever been completed, so it can distinguish between incomplete and partly reclaimed units
local toDestroy = {}

local modOptions = Spring.GetModOptions() or {}
local noElo = tobool(modOptions.noelo)

local revealed = false
local gameover = false

local nilUnitDef = {id=-1}
local function GetUnitDefIdByName(defName)
  return (UnitDefNames[defName] or nilUnitDef).id
end

local doesNotCountList = {
	[GetUnitDefIdByName("armflea")] = true,
	[GetUnitDefIdByName("corroach")] = true,
	[GetUnitDefIdByName("armtick")] = true,
	[GetUnitDefIdByName("spherepole")] = true,
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

local function EchoUIMessage(message)
	spEcho("game_message: " .. message)
end

local function UnitWithinBounds(unitID)
	local x, y, z = Spring.GetUnitPosition(unitID)
	return (x > -500) and (x < Game.mapSizeX + 500) and (y > -1000) and (z > -500) and (z < Game.mapSizeZ + 500)
end

-- if only one allyteam left, declare it the victor
local function CheckForVictory()
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
		EchoUIMessage(( (lastAllyTeam and ("Alliance " .. lastAllyTeam)) or "Nobody") .. " wins!")
		spGameOver({lastAllyTeam})
	end
end

local function RevealAllianceUnits(allianceID)
	allianceToReveal = allianceID
	local teamList = spGetTeamList(allianceID)
	for i=1,#teamList do
		local t = teamList[i]
		local teamUnits = spGetTeamUnits(t) 
		for j=1,#teamUnits do
			local u = teamUnits[j]
			-- purge extra-map units
			if not UnitWithinBounds(u) then
				Spring.DestroyUnit(u)
			else
				Spring.SetUnitAlwaysVisible(u, true)
			end
		end
	end
end

-- purge the alliance! for the horde!
local function DestroyAlliance(allianceID)
	if not destroyedAlliances[allianceID] then
		destroyedAlliances[allianceID] = true
		local teamList = spGetTeamList(allianceID)
		if teamList == nil then return end	-- empty allyteam, don't bother
		
		if Spring.IsCheatingEnabled() then
			EchoUIMessage("Game Over: DEBUG")
			EchoUIMessage("Game Over: Allyteam " .. allianceID .. " has met the game over conditions.")
			EchoUIMessage("Game Over: If this is true, then please resign.")
			return	-- don't perform victory check
		else -- kaboom
			EchoUIMessage("Alliance " .. allianceID .. " has been destroyed!")
			for i=1,#teamList do
				local t = teamList[i]
				local teamUnits = spGetTeamUnits(t) 
				for j=1,#teamUnits do
					local u = teamUnits[j]
					local pwUnits = (GG.PlanetWars or {}).unitsByID
					if pwUnits and pwUnits[u] then
						GG.allowTransfer = true
						spTransferUnit(u, gaiaTeamID, true)		-- don't blow up PW buildings
						GG.allowTransfer = false
					else
						toDestroy[u] = true
					end
				end
				spKillTeam(t)
			end
		end
	end
	CheckForVictory()
end
GG.DestroyAlliance = DestroyAlliance

local function AddAllianceUnit(u, ud, teamID)
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID)
	aliveCount[teamID] = aliveCount[teamID] + 1
	
	aliveValue[teamID] = aliveValue[teamID] + UnitDefs[ud].metalCost
end

local function RemoveAllianceUnit(u, ud, teamID)
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID)
	aliveCount[teamID] = aliveCount[teamID] - 1
	
	aliveValue[teamID] = aliveValue[teamID] - UnitDefs[ud].metalCost
	if aliveValue[teamID] < 0 then
		aliveValue[teamID] = 0
	end

	if (CountAllianceUnits(allianceID) <= 0) and (allianceID ~= chickenAllyTeamID) then
		Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Game Over> Purging allyTeam " .. allianceID)
		DestroyAlliance(allianceID)
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
	if Spring.IsCheatingEnabled() then
		return
	end
	local allylist = spGetAllyTeamList()
	local activeAllies = {}
	local lastActive = nil
	for i=1,#allylist do
		repeat
		local a = allylist[i]
		if (a == gaiaAllyTeamID) then break end -- continue
		if (destroyedAlliances[a]) then break end -- continue
		local teamlist = spGetTeamList(a)
		if (not teamlist) then break end -- continue
		local activeTeams = 0
		for i=1,#teamlist do
			local t = teamlist[i]
			-- any team without units is dead to us; so only teams who are active AND have units matter
			-- except chicken, who are alive even without units
			local numAlive = aliveCount[t]
			if #(Spring.GetTeamUnits(t)) == 0 then numAlive = 0 end
			if (numAlive > 0) or (GG.waitingForComm or {})[t] or (GetTeamIsChicken(t)) then	
				local playerlist = spGetPlayerList(t, true) -- active players
				if playerlist then
					for j=1,#playerlist do
						local _,active,spec = spGetPlayerInfo(playerlist[j])
						if active and not spec then
							activeTeams = activeTeams + 1
						end
					end
				end
				-- count AI teams as active
				local _,_,_,isAiTeam = spGetTeamInfo(t)
				if isAiTeam then
					activeTeams = activeTeams + 1
				end
			end
		end
		if activeTeams > 0 then
			activeAllies[#activeAllies+1] = a
			lastActive = a
		end
		until true
	end -- for

	if #activeAllies == 2 then
		if revealed then return end
		if activeAllies[1] == chickenAllyTeamID or activeAllies[2] == chickenAllyTeamID then
			return
		end
		-- run value comparison
		local supreme = CompareArmyValues(activeAllies[1], activeAllies[2])
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
		-- remove every unit except for last active alliance
		for i=1, #allylist do
			local a = allylist[i]
			if (a ~= lastActive)and(a ~= gaiaAllyTeamID) then
				DestroyAlliance(a)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- callins
--------------------------------------------------------------------------------

function gadget:TeamDied (teamID)
	ProcessLastAlly()
end

function gadget:UnitFinished(u, ud, team)
	if (team ~= gaiaTeamID)
	  and(not doesNotCountList[ud])
	  and(not finishedUnits[u])
	then
		finishedUnits[u] = true
		AddAllianceUnit(u, ud, team)
	end
end

function gadget:UnitCreated(u, ud, team)
	if revealed then
		local allyTeam = select(6, spGetTeamInfo(team))
		if allyTeam == allianceToReveal then
			Spring.SetUnitAlwaysVisible(u, true)
		end
	end
end

function gadget:UnitDestroyed(u, ud, team)
	if spGetGameRulesParam("loadPurge") == 1 then
		return
	end
	
	if (team ~= gaiaTeamID)
	  and(not doesNotCountList[ud])
	  and finishedUnits[u]
	then
		finishedUnits[u] = nil
		RemoveAllianceUnit(u, ud, team)
	end
	toDestroy[u] = nil
end

-- note: Taken comes before Given
function gadget:UnitGiven(u, ud, newTeam, oldTeam)
	if (newTeam ~= gaiaTeamID)
	  and(not doesNotCountList[ud])
	  and finishedUnits[u]
	then
		AddAllianceUnit(u, ud, newTeam)
	end
end

function gadget:UnitTaken(u, ud, oldTeam, newTeam)
	if (oldTeam ~= gaiaTeamID)
	  and(not doesNotCountList[ud])
	  and finishedUnits[u]
	then
		RemoveAllianceUnit(u, ud, oldTeam)	
	end
end

function gadget:Initialize()
	local teams = spGetTeamList()
	for i=1,#teams do
		aliveValue[teams[i]] = 0
		if GetTeamIsChicken(teams[i]) then
			Spring.Log(gadget:GetInfo().name, LOG.INFO, "<Game Over> Chicken team found")
			chickenAllyTeamID = select(6, Spring.GetTeamInfo(teams[i]))
			--break
		end
	end
	
	CheckAllUnits()
	
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "Game Over initialized")
end

function gadget:GameFrame(n)
	-- check for last ally:
	-- end condition: only 1 ally with human players, no AIs in other ones
	if (n % 45 == 0) then
		if toDestroy then
			for u in pairs(toDestroy) do
				spDestroyUnit(u, true)
			end
		end
		toDestroy = {}
		if not gameover and not spGetGameRulesParam("loadedGame") then
			ProcessLastAlly()
		end
	end
end

function gadget:GameOver()
	gameover = true
	if noElo then
		Spring.SendCommands("wbynum 255 SPRINGIE:noElo")
	end
	Spring.Log(gadget:GetInfo().name, LOG.INFO, "GAME OVER!!")
end
