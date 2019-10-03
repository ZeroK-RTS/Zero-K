--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Transport Speed",
    desc      = "Lowers the speed of transports when they transport large loads.",
    author    = "Google Frog",
    date      = "31 August 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local mass = {}

for i=1,#UnitDefs do
	local ud = UnitDefs[i]
	mass[i] = ud.mass
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local inTransport = {}

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if unitID then
		inTransport[unitID] = nil
	end
	if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(transportID) then
		local tudid = Spring.GetUnitDefID(transportID)
		Spring.SetUnitRulesParam(transportID, "massOverride", mass[tudid])
		Spring.SetUnitRulesParam(transportID, "selfMoveSpeedChange", 1)
		GG.UpdateUnitAttributes(transportID)
	end
end

function gadget:UnitLoaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if Spring.ValidUnitID(unitID) and Spring.ValidUnitID(transportID) then
		local tudid = Spring.GetUnitDefID(transportID)
		if tudid and unitDefID then
			local effectiveMass = mass[tudid] + (Spring.GetUnitRulesParam(unitID, "massOverride") or mass[unitDefID])
			local speedFactor = math.min(1, 2 * mass[tudid]/(effectiveMass))
			Spring.SetUnitRulesParam(transportID, "massOverride", effectiveMass)
			Spring.SetUnitRulesParam(transportID, "selfMoveSpeedChange", speedFactor)
			GG.UpdateUnitAttributes(transportID)
			
			inTransport[unitID] = transportID
		end
	end
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if inTransport[unitID] then
		local transportID = inTransport[unitID]
		if not Spring.GetUnitIsDead(transportID) then
			local tudid = Spring.GetUnitDefID(transportID)
			Spring.SetUnitRulesParam(transportID, "massOverride", mass[tudid])
			Spring.SetUnitRulesParam(transportID, "selfMoveSpeedChange", 1)
			GG.UpdateUnitAttributes(transportID)
		end
		inTransport[unitID] = nil
	end
end
