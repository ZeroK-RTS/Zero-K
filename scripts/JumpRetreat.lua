-- TODO: CACHE INCLUDE FILE
local CMD_JUMP = Spring.Utilities.CMD.JUMP
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local jumpRange = tonumber(UnitDefs[unitDefID].customParams.jump_range)

local firstTime = true

function RetreatFunction(hx, hy, hz)
	if firstTime then
		local jumpReload = Spring.GetUnitRulesParam(unitID,"jumpReload")
		if not jumpReload or jumpReload >= 1 then
			local ux, uy, uz = Spring.GetUnitPosition(unitID)
			local moveDistance = math.sqrt((ux - hx)^2 + (uz - hz)^2)
			local disScale = jumpRange/moveDistance*0.95
			local cx, cy, cz = ux + disScale*(hx - ux), hy, uz + disScale*(hz - uz)
			GiveClampedOrderToUnit(unitID, CMD.INSERT, { 0, CMD_JUMP, CMD.OPT_INTERNAL, cx, cy, cz}, CMD.OPT_ALT)
		end
		firstTime = false
	end
end

function StopRetreatFunction()
	firstTime = true
end
