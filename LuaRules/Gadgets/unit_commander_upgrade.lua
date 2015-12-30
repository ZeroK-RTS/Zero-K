function gadget:GetInfo()
  return {
    name      = "Comander Upgrade",
    desc      = "",
    author    = "Google Frog",
    date      = "30 December 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
   return false
end

local INLOS = {inlos = true}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	
	Spring.SetUnitRulesParam(unitID, "comm_level", 0, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_chassis", 1, INLOS)
	
	Spring.SetUnitRulesParam(unitID, "comm_weapon_1", 1, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_weapon_count", 1, INLOS)
	
	Spring.SetUnitRulesParam(unitID, "comm_module_1", 5, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_module_2", 5, INLOS)
	Spring.SetUnitRulesParam(unitID, "comm_module_count", 2, INLOS)
end

function gadget:Initialize()
	
	-- load active units
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local teamID = Spring.GetUnitTeam(unitID)
		gadget:UnitCreated(unitID, unitDefID, teamID)
	end
	
end
