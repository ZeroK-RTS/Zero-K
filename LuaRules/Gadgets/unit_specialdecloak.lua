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

local Echo = Spring.Echo
local cloakedUnits = {}

local gaiaAlliance, gaiaTeam

function check_unit(teamList, x,y,z, decloakRad)
	for _,teamID in ipairs(teamList) do
		if spGetUnitsInSphere(x,y,z, decloakRad, teamID)[1] then return true end
	end
	return false
end

function gadget:GameFrame(f)
	if f % 8 ~= 0 then return end
	
	local allyList = spGetAllyTeamList()
	for _,allianceID in ipairs(allyList) do
		if allianceID ~= gaiaAlliance then
			local teamList = spGetTeamList(allianceID)
			for unitID, data in pairs(cloakedUnits) do
				if data.unitAlliance ~= allianceID then
					local x,y,z = spGetUnitPosition(unitID)
					if x then
						if check_unit(teamList, x,y,z, data.decloakRad) then
							spSetUnitLosMask(unitID, allianceID, {los=true} )
							spSetUnitLosState(unitID, allianceID, {los=true} )
						else
							spSetUnitLosMask(unitID, allianceID, {los=false} )
						end
					end
				end
			end
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
	
	local allUnits = Spring.GetAllUnits()
	for _, unitID in ipairs(allUnits) do
		if spGetUnitIsCloaked(unitID) then
			gadget:UnitCloaked(unitID, spGetUnitDefID(unitID), _)
		end
	end
end












