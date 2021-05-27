-- TODO: CACHE INCLUDE FILE
local CMD_JUMP = Spring.Utilities.CMD.JUMP
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local jumpRange = tonumber(UnitDefs[unitDefID].customParams.jump_range)

local retreating = false

local function RetreatThread(hx, hy, hz)
	local reload, disarmed
	while retreating do
		reload = Spring.GetUnitRulesParam(unitID, "jumpReload") or 1
		disarmed = (Spring.GetUnitRulesParam(unitID, "disarmed") or 0) == 1
		if reload >= 1 and not disarmed then
			local ux, uy, uz = Spring.GetUnitPosition(unitID)
			local moveDistance = math.sqrt((ux - hx)^2 + (uz - hz)^2)
			local disScale = jumpRange/moveDistance*0.95
			local cx, cy, cz = ux + disScale*(hx - ux), hy, uz + disScale*(hz - uz)
			GiveClampedOrderToUnit(unitID, CMD.INSERT, { 0, CMD_JUMP, CMD.OPT_INTERNAL, cx, cy, cz}, CMD.OPT_ALT)
		else
			Sleep(33)
		end
	end
end
		

function RetreatFunction(hx, hy, hz)
	retreating = true
	StartThread(RetreatThread, hx, hy, hz)
end

function StopRetreatFunction()
	retreating = false
end
