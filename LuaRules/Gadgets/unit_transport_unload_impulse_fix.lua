
function gadget:GetInfo()
  return {
    name      = "Transport Unload Impulse Fix",
    desc      = "Fixes Newton + Transport impulse capacitor",
    author    = "Google Frog",
    date      = "31 March 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:UnitUnloaded(unitID, unitDefID, unitTeam, transportID, transportTeam)
	if Spring.ValidUnitID(unitID) and not Spring.GetUnitIsDead(transportID) then
		Spring.SetUnitVelocity(unitID, 0, 0, 0)
	end
end