if (not gadgetHandler:IsSyncedCode()) then return false end

function gadget:GetInfo()
	return {
		name      = "Factory Reverse Build Control",
		desc      = "Prevents factory reverse build bugs/sploits",
		author    = "KingRaptor (L.J. Lim) (rewritten by jK)",
		date      = "18 February 2010",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false
	}
end

local spAddTeamResource   = Spring.AddTeamResource
local spDestroyUnit       = Spring.DestroyUnit
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitHealth     = Spring.GetUnitHealth
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetUnitTeam       = Spring.GetUnitTeam

function gadget:AllowUnitBuildStep(_, _, unitID, unitDefID, step)
	if (step < 0) and UnitDefs[unitDefID].isFactory then
		local buildID = spGetUnitIsBuilding(unitID)
		if (buildID) then
			local buildDefID = spGetUnitDefID(buildID)
			local refund = UnitDefs[buildDefID].metalCost * select(5, spGetUnitHealth(buildID))
			local teamID = spGetUnitTeam(buildID)
			spAddTeamResource(teamID, "m", refund)
			spDestroyUnit(buildID, false, true)
		end
	end
	return true
end