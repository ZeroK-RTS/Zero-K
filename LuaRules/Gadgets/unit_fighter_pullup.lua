if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo() return {
	name    = "Fighter pull-up",
	desc    = "Sets attack safety distance for fighter/bomber aircraft",
	author  = "raaar",
	date    = "2015",
	license = "PD",
	layer   = 3,
	enabled = true
} end

function gadget:UnitCreated(unitID, unitDefID)
	local dist = UnitDefs[unitDefID].customParams.fighter_pullup_dist
	if dist then
		Spring.MoveCtrl.SetAirMoveTypeData(unitID,{attackSafetyDistance=dist})
	end
end
