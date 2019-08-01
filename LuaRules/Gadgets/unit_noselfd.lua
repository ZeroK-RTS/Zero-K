if (not gadgetHandler:IsSyncedCode()) then return false end

function gadget:GetInfo()
	return {
		name      = "No Self-D",
		desc      = "Prevents self-destruction when a unit changes hands.",
		author    = "quantum",
		date      = "July 13, 2008",
		license   = "GNU GPL, v2 or later",
		layer     = -10,
		enabled   = true
	}
end

local spGetUnitSelfDTime = Spring.GetUnitSelfDTime
local spGiveOrderToUnit  = Spring.GiveOrderToUnit
local emptyTable = {}
local CMD_SELFD = CMD.SELFD

function gadget:UnitGiven(unitID, unitDefID, unitTeam, oldTeam)
	if (spGetUnitSelfDTime(unitID) > 0) then --unit about to explode
		spGiveOrderToUnit(unitID, CMD_SELFD, emptyTable, 0) --cancel self-destruct
	end
end
