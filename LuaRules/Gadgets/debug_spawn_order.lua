if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Logs unit spawn order",
	layer   = 0,
	enabled = true,
} end

local counter = 0
function gadget:UnitCreated(unitID)
	counter = counter + 1
	Spring.SetUnitRulesParam(unitID, "spawn_order", counter)
end
