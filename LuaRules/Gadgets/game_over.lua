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

if (gadgetHandler:IsSyncedCode()) then

--if Spring.GetModOption("zkmode",false,nil) == nil then
--	Spring.Echo("<Game Over> Testing mode. Gadget removed.")
--	return
--end

--------------------------------------------------------------------------------
-- vars
--------------------------------------------------------------------------------

local function nullFunc() end

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

local spKillTeam = Spring.KillTeam or nullFunc
local spGameOver = Spring.GameOver or nullFunc

local gaiaTeamID = Spring.GetGaiaTeamID()
local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(gaiaTeamID))
local chickenAllyTeamID

local aliveCount = {}
local destroyedAlliances = {}

local finishedUnits = {}	-- this stores a list of all units that have ever been completed, so it can distinguish between incomplete and partly reclaimed units
local toDestroy = {}

local destroy_type = 'destroy'
local commends = false

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

local commsAlive = {}
local allyTeams = spGetAllyTeamList()
for i=1,#allyTeams do
	commsAlive[allyTeams[i]] = {}
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
	end
	return count
end

local function HasNoComms(allianceID)
	for unitID in pairs(commsAlive[allianceID]) do
		return false
	end
	return true
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
		Spring.Echo(( (lastAllyTeam and ("Team " .. lastAllyTeam)) or "Nobody") .. " wins!")
		spGameOver({lastAllyTeam})
	end
end

-- purge the alliance!
local function DestroyAlliance(allianceID)
	if not destroyedAlliances[allianceID] then
		destroyedAlliances[allianceID] = true
		local teamList = spGetTeamList(allianceID)
		if teamList == nil then return end	-- empty allyteam, don't bother
		
		if destroy_type == 'debug' then
			Spring.Echo("Game Over: DEBUG")
			Spring.Echo("Game Over: Allyteam " .. allianceID .. " has met the game over conditions.")
			Spring.Echo("Game Over: If this is true, then please resign.")
			return	-- don't perform victory check
		elseif destroy_type == 'destroy' then	-- kaboom
			Spring.Echo("Game Over: Destroying alliance " .. allianceID)
			for i=1,#teamList do
				local t = teamList[i]
				local teamUnits = spGetTeamUnits(t) 
				for j=1,#teamUnits do
					local u = teamUnits[j]
					if GG.pwUnitsByID and GG.pwUnitsByID[u] then
						spTransferUnit(u, gaiaTeam, true)		-- don't blow up PW buildings
					else
						toDestroy[u] = true
					end
				end
				spKillTeam(t)
			end
		elseif destroy_type == 'losecontrol' then	-- no orders can be issued to team
			Spring.Echo("Game Over: Destroying alliance " .. allianceID)
			for i=1,#teamList do
				spKillTeam(teamList[i])
			end
		end
	end
	CheckForVictory()
end
GG.DestroyAlliance = DestroyAlliance

local function AddAllianceUnit(u, ud, teamID)
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID)
	aliveCount[teamID] = aliveCount[teamID] + 1
	--Spring.Echo("added alliance=" .. teamID, 'count='..aliveCount[allianceID])
	if UnitDefs[ud].customParams.commtype then
		commsAlive[allianceID][u] = true
	end	
end

local function RemoveAllianceUnit(u, ud, teamID)
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID)
	aliveCount[teamID] = aliveCount[teamID] - 1
	--Spring.Echo("removed alliance=" .. teamID, 'count='..aliveCount[allianceID]) 
	if UnitDefs[ud].customParams.commtype then
		commsAlive[allianceID][u] = nil
	end
	if ((CountAllianceUnits(allianceID) <= 0) or (commends and HasNoComms(allianceID))) and (allianceID ~= chickenAllyTeamID) then
		Spring.Echo("purge allyTeam" .. allianceID)
		DestroyAlliance(allianceID)
	end
end

-- used during initialization
local function CheckAllUnits()
	aliveCount = {}
	local teams = spGetTeamList()
	for i=1,#teams do
		local teamID = teams[i]
		if teamID ~= gaiaTeam then
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
    if Spring.IsCheatingEnabled() or destroy_type == 'debug' then
	  return
    end
    local allylist = spGetAllyTeamList()
    local activeAllies = 0
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
			activeAllies = activeAllies + 1
			lastActive = a
		end
		until true
    end -- for

    if activeAllies < 2 then
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

function gadget:UnitFinished(u, ud, team)
	if (team ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(not finishedUnits[u])
	then
		finishedUnits[u] = true
		AddAllianceUnit(u, ud, team)
	end
end

function gadget:UnitDestroyed(u, ud, team)
	if (team ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and finishedUnits[u]
	then
		finishedUnits[u] = nil
		RemoveAllianceUnit(u, ud, team)
	end
	toDestroy[u] = nil
end

function gadget:UnitGiven(u, ud, newTeam, oldTeam)
	--note the order of UnitGiven and UnitTaken in the event queue
	-- -> first we add the unit and _then_ remove it from the ally unit counter!
	if (newTeam ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(not select(3,spGetUnitIsStunned(u)))
	then
		AddAllianceUnit(u, ud, newTeam)
	end
end

function gadget:UnitTaken(u, ud, oldTeam, newTeam)
	if (oldTeam ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(select(5,spGetUnitHealth(u))>=1)
	then
		RemoveAllianceUnit(u, ud, oldTeam)	
	end
end

function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	CheckAllUnits()
	destroy_type = Spring.GetModOptions() and Spring.GetModOptions().defeatmode or 'destroy'
	commends = Spring.GetModOptions() and tobool(Spring.GetModOptions().commends)
	
	local teams = spGetTeamList()
	for i=1,#teams do
		if GetTeamIsChicken(teams[i]) then
			Spring.Echo("<Game Over> Chicken team found")
			chickenAllyTeamID = select(6, Spring.GetTeamInfo(teams[i]))
			break
		end
	end
	
    Spring.Echo("Game Over initialized")
end

function gadget:GameFrame(n)
  -- check for last ally:
  -- end condition: only 1 ally with human players, no AIs in other ones
  if (n % 45 == 0) then
	for u in pairs(toDestroy) do
		spDestroyUnit(u, true)
	end
	toDestroy = {}
	if not gameover then
		ProcessLastAlly()
	end
  end
end

function gadget:GameOver()
	gameover = true
	Spring.Echo("GAME OVER!!")
end

else -- UNSYNCED

end
