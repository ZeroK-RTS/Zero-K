-- $Id$
function gadget:GetInfo()
  return {
    name      = "Special Decloak.",
    desc      = "Overrides engine's decloak.",
    author    = "CarRepairer",
    date      = "2009-3-2",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if not tobool(Spring.GetModOptions().specialdecloak) then
	return false
end

if (not gadgetHandler:IsSyncedCode()) then
  return false  --  silent removal
end

local spGetUnitAllyTeam		= Spring.GetUnitAllyTeam
local spGetUnitPosition		= Spring.GetUnitPosition
local spGetUnitsInSphere	= Spring.GetUnitsInSphere
local spGetTeamList			= Spring.GetTeamList
local spGetAllyTeamList		= Spring.GetAllyTeamList
local spSetUnitLosState		= Spring.SetUnitLosState
local spSetUnitLosMask		= Spring.SetUnitLosMask
local spGetUnitIsCloaked 	= Spring.GetUnitIsCloaked
local spGetUnitDefID    	= Spring.GetUnitDefID
local spGetTeamInfo    		= Spring.GetTeamInfo

local echo = Spring.Echo
local cloakedUnits = {}
local enAlliances = {}
local teamLists = {}

local gaiaAlliance, gaiaTeam


------------------------------------------------

local function CheckUnitAgainstTeams(teamList, x,y,z, decloakRad)
	for _,teamID in ipairs(teamList) do
		if spGetUnitsInSphere(x,y,z, decloakRad, teamID)[1] then
			return true
		end
	end
	return false
end

local function CheckUnit(unitID, allianceID, x,y,z, decloakRad)
	for enAllianceID,_ in pairs(enAlliances[allianceID]) do
		if CheckUnitAgainstTeams(teamLists[enAllianceID], x,y,z, decloakRad) then
			--echo ('revealing', unitID, enAllianceID)
			spSetUnitLosMask(unitID, enAllianceID, {los=true} )
			spSetUnitLosState(unitID, enAllianceID, {los=true} )
		else
			spSetUnitLosMask(unitID, enAllianceID, {los=false} )
		end
	end
end

function SetupLists()
	enAlliances = {}
	teamLists = {}
	
	local allyList = {}
	local allyList_temp = spGetAllyTeamList()
	
	for _,allianceID in ipairs(allyList_temp) do
		if allianceID ~= gaiaAlliance then
			table.insert( allyList, allianceID )	
		end
	end
			
	for _,allianceID in ipairs(allyList) do
		enAlliances[allianceID] 	= {}
		teamLists[allianceID] 		= {}
		
		for _,enAllianceID in ipairs(allyList) do
			if enAllianceID ~= allianceID then
				enAlliances[allianceID][enAllianceID] = true
			end
		end
		
		local teamList = spGetTeamList(allianceID)
		for _,teamID in ipairs(teamList) do
			table.insert( teamLists[allianceID], teamID )
		end
		
	end
	
end
----------------------------------

function gadget:GameFrame(f)
	if f % 8 ~= 0 then return end


	for unitID, data in pairs(cloakedUnits) do
		
		local x,y,z = spGetUnitPosition(unitID)
		if x then
			CheckUnit(unitID, data.unitAlliance, x,y,z, data.decloakRad)
		end
	end

end

function gadget:UnitCloaked(unitID,unitDefID,teamID)
	local ud = UnitDefs[unitDefID]
	if not ud then return end
	local decloakRad = ud.customParams.specialdecloakrange
	if decloakRad+0 > 0 then
		cloakedUnits[unitID] = {unitAlliance = spGetUnitAllyTeam(unitID), decloakRad = decloakRad }
	end
end

function gadget:UnitDecloaked(unitID, unitDefID, unitTeam)
	cloakedUnits[unitID] = nil
	local allyList = spGetAllyTeamList()
	for _,allianceID in ipairs(allyList) do
		if allianceID ~= gaiaAlliance then
			spSetUnitLosMask(unitID, allianceID, {los=false} )
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	cloakedUnits[unitID] = nil
end

function gadget:Initialize()
	gaiaTeam = Spring.GetGaiaTeamID()
	_,_,_,_,_, gaiaAlliance = spGetTeamInfo(gaiaTeam)
	
	SetupLists()
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in ipairs(allUnits) do
		if spGetUnitIsCloaked(unitID) then
			gadget:UnitCloaked(unitID, spGetUnitDefID(unitID), _)
		end
	end
end












