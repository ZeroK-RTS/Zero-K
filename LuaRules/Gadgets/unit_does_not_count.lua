-- $Id: unit_does_not_count.lua 4190 2009-03-27 01:27:59Z carrepairer $
function gadget:GetInfo()
	return {
		name = "Does Not Count",
		desc = "v2.5 Makes certain units not count for a team's alive status by killing them",
		author = "KDR_11k (David Becker)",
		date = "2008-02-04",
		license = "Public domain",
		layer = 1,
		enabled = false
	}
end

---- CHANGELOG -----
--	jK:
--		-- cleanup
--		-- don't create units instead show just a message until the bug is fixed 
--	CarRepairer:	
--		- All units of an ally team are accounted for, rather than a single player team
--		- Instead of using customparams in each individual unit file, uses the doesNotCountList array
--		- Accounts for units that may have been created before init of this gadget, such as deployment.
--		- Accounts for replacecomm gadget. Due to gadget layering and commander replacement, was causing alive unit count to hit 0.
--		- Ignores features
--		- Added kludge
--		- Accounts for Gaia

-- use the custom param doesntcount=1 to mark a unit as not counted:
--
-- [customParams]
-- {
--     doesntcount=1;
-- }
--
-- Uses I can think of include making mines explode when the team has nothing useful left
-- or implementing C&C-style no buildings = dead rules.

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

if Spring.GetModOption("nodoesnotcount",true,false)  then
	return false
end 

if (not gadgetHandler:IsSyncedCode()) then
  function gadget:AllyDead(allyID)
    local playersInAlly = ""

    local teams = Spring.GetTeamList(allyID)
    if teams then
      for _,teamID in ipairs(teams) do
        local players = Spring.GetPlayerList(teamID)
        for _,playerID in ipairs(players) do
          local playerName,_,spec = Spring.GetPlayerInfo(playerID)
          if (not spec) then
            playersInAlly = playersInAlly .. playerName .. ", "
          end
        end
      end
    end

    Spring.Echo("DoesNotCount: Ally " .. allyID .. " consists of: " .. playersInAlly)
  end

  function gadget:Initialize()
    gadgetHandler:AddSyncAction("DoesntCount_AllyDead", AllyDead)
    Spring.Echo("Doesn't count initialized")
  end

  return
end

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local spGetTeamInfo     = Spring.GetTeamInfo
local spGetTeamList     = Spring.GetTeamList
local spGetTeamUnits    = Spring.GetTeamUnits
local spDestroyUnit     = Spring.DestroyUnit
local spGetAllUnits     = Spring.GetAllUnits
local spGetAllyTeamList = Spring.GetAllyTeamList
local spAreTeamsAllied  = Spring.AreTeamsAllied
local spGetUnitTeam     = Spring.GetUnitTeam
local spGetUnitDefID    = Spring.GetUnitDefID
local spGetUnitIsStunned= Spring.GetUnitIsStunned
local spGetUnitHealth   = Spring.GetUnitHealth

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

local gaiaAlliance, gaiaTeam

local aliveCount = {}
local destroyedAlliances = {}

local destroy_type = 'destroy'

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
	if (ud.customParams.doesntcount) then
		doesNotCountList[ud.id] = tobool(ud.customParams.doesntcount) or nil
	elseif (ud.isFeature) then
		doesNotCountList[ud.id] = true
	elseif (not ud.canAttack) and (not ud.speed) and (not ud.isFactory) then
		doesNotCountList[ud.id] = true
	end
end

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function addAllianceUnit(teamID)
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID)
	aliveCount[allianceID] = aliveCount[allianceID] + 1 
	--Spring.Echo("added alliance=" .. teamID, 'count='..aliveCount[allianceID]) 
end


function removeAllianceUnit(teamID)
	local _, _, _, _, _, allianceID = spGetTeamInfo(teamID)
	aliveCount[allianceID] = aliveCount[allianceID] - 1
	--Spring.Echo("removed alliance=" .. teamID, 'count='..aliveCount[allianceID]) 

	if (aliveCount[allianceID]<=0) then destroyAlliance(allianceID) end
end


function checkAllUnits()
	aliveCount = {}
	for _,allianceID in ipairs(spGetAllyTeamList()) do
		if allianceID ~= gaiaAlliance then
			aliveCount[allianceID] = 0
		end
	end
	
	for _, unitID in ipairs(spGetAllUnits()) do
		 local teamID = spGetUnitTeam(unitID)
		 local unitDefID = spGetUnitDefID(unitID)
		 gadget:UnitFinished(unitID, unitDefID, teamID)
	end
end


function destroyAlliance(allianceID)
	if not destroyedAlliances[allianceID] then
		if destroy_type == 'debug' then
			destroyedAlliances[allianceID] = true
			Spring.Echo("DoesNotCount: DEBUG")
			Spring.Echo("DoesNotCount: Ally " .. allianceID .. " doesn't have any active units left.")
			Spring.Echo("DoesNotCount: If this is true, then please selfdestroy.")
			SendToUnsynced("DoesntCount_AllyDead",allianceID) --// we can't get playernames in synced script
			
		elseif destroy_type == 'destroy' then

			
			Spring.Echo("DoesNotCount: Destroying alliance " .. allianceID)
			local teamList = spGetTeamList(allianceID)
			if teamList then
				for _,t in ipairs(teamList) do
					local teamUnits = spGetTeamUnits(t) 
					for _,u in ipairs(teamUnits) do
						spDestroyUnit(u, true)
					end
				end
			end
			
		elseif destroy_type == 'losecontrol' then
			
		end
	end
end

--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function gadget:UnitFinished(u, ud, team)
	if   (team ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(not select(3,spGetUnitIsStunned(u)))
	then
		addAllianceUnit(team)
	end
end


function gadget:UnitDestroyed(u, ud, team)
	if   (team ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(not select(3,spGetUnitIsStunned(u)))
	then
		removeAllianceUnit(team)
	end
end


function gadget:UnitGiven(u, ud, newTeam, oldTeam)
	--note the order of UnitGiven and UnitTaken in the event queue
	-- -> first we add the unit and _then_ remove it from the ally unit counter!
	if   (newTeam ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(not select(3,spGetUnitIsStunned(u)))
	then
		addAllianceUnit(newTeam)
	end
end


function gadget:UnitTaken(u, ud, oldTeam, newTeam)
	if   (oldTeam ~= gaiaTeam)
	  and(not doesNotCountList[ud])
	  and(select(5,spGetUnitHealth(u))>=1)
	then
		removeAllianceUnit(oldTeam)	
	end
end


function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = Spring.GetTeamInfo(gaiaTeam)
	checkAllUnits()
	destroy_type = Spring.GetModOptions() and Spring.GetModOptions().doesnotcountmode or 'debug'
    Spring.Echo("Doesn't count initialized")
end
