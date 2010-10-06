-- $Id$


if (gadgetHandler:IsSyncedCode()) then

function gadget:GetInfo()
  return {
    name      = "Factory Reverse Build Control",
    desc      = "Prevents factory reverse build bugs/sploits",
    author    = "KingRaptor (L.J. Lim) (rewrote by jK)",
    date      = "18 February 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true --  loaded by default?
  }
end

local function RefundUnit(unitID, unitDefID, teamID)
	local _,_,_,_,buildProgress = Spring.GetUnitHealth(unitID)
	local refund = UnitDefs[unitDefID].metalCost * buildProgress
	Spring.AddTeamResource(teamID, "m", refund)
	--Spring.AddTeamResource(teamID, "e", refund)
end

local function IsFactory(udef)
	return udef.TEDClass == "PLANT" or udef.isFactory
end

function gadget:AllowUnitBuildStep(_, _, unitID, unitDefID, step)
	if (step < 0) and IsFactory(UnitDefs[unitDefID]) then
		local buildID = Spring.GetUnitIsBuilding(unitID)
		if (buildID) then
			local teamID = Spring.GetUnitTeam(buildID)
			local buildDefID = Spring.GetUnitDefID(buildID)
			RefundUnit(buildID, buildDefID, teamID)
			Spring.DestroyUnit(buildID, false, true)
		end
	end
	return true
end

end
