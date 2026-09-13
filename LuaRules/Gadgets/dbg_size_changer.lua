--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Size Changer",
		desc      = "Changes the sizes of units so their centre of mass may be seen.",
		author    = "GoogleFrog",
		date      = "10 April 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,  --  loaded by default?
	}
end

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	Spring.UnitScript.CallAsUnit(unitID, Spring.UnitScript.Scale, Spring.GetUnitRootPiece(unitID), 2)
end
