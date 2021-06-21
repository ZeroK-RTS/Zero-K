-- TODO: CACHE INCLUDE FILE
local CMD_JUMP = Spring.Utilities.CMD.JUMP
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local jumpRange = tonumber(UnitDefs[unitDefID].customParams.jump_range)
local retreattype = UnitDefs[unitDefID].customParams.jumpretreattype or "always"

local retreating = false

local function RetreatThread(hx, hy, hz)
	--Spring.Echo("RetreatThread")
	local reload, disarmed, ux, uy, uz, moveDistance, disScale, cx, cy, cz, isstunned
	while retreating do
		reload = Spring.GetUnitRulesParam(unitID, "jumpReload") or 1
		disarmed = (Spring.GetUnitRulesParam(unitID, "disarmed") or 0) == 1
		isstunned = Spring.GetUnitIsStunned(unitID)
		--Spring.Echo("Reload: " .. tostring(reload) .. " / 1\nDisarmed: " .. tostring(disarmed))
		if reload >= 1 and not disarmed and not isstunned then
			ux, uy, uz = Spring.GetUnitPosition(unitID)
			moveDistance = math.sqrt(((ux - hx) * (ux - hx)) + ((uz - hz) * (uz - hz)))
			--Spring.Echo("MoveDistance: " .. moveDistance)
			if moveDistance >= 200 and moveDistance < jumpRange then -- jump to finish reteating.
				GiveClampedOrderToUnit(unitID, CMD.INSERT, { 0, CMD_JUMP, CMD.OPT_INTERNAL, hx, hy, hz}, CMD.OPT_ALT)
				retreating = false
			elseif moveDistance < 200 then -- don't jump around in haven or waste it near it.
				retreating = false -- stop watching reload states.
			else
				disScale = jumpRange/moveDistance*0.95
				cx, cy, cz = ux + disScale*(hx - ux), hy, uz + disScale*(hz - uz)
				GiveClampedOrderToUnit(unitID, CMD.INSERT, { 0, CMD_JUMP, CMD.OPT_INTERNAL, cx, cy, cz}, CMD.OPT_ALT)
				if retreattype == "once" then
					retreating = false
				end
			end
		end
		Sleep(66)
	end
end

function RetreatFunction(hx, hy, hz)
	if retreattype == "none" then
		return
	end
	if not retreating then
		retreating = true
		StartThread(RetreatThread, hx, hy, hz)
	end
end

function StopRetreatFunction()
	retreating = false
end
