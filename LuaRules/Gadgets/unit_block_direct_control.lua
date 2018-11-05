if not gadgetHandler:IsSyncedCode() then return end

function gadget:GetInfo()
	return {
		name    = "Block direct control",
		desc    = "Disables FPS mode.",
		author  = "GoogleFrog",
		date    = "5 November 2018",
		license   = "GNU GPL, v2 or later",
		layer   = 0,
		enabled = true
	}
end

function gadget:AllowDirectUnitControl(unitID, unitDefID)
	return false
end
