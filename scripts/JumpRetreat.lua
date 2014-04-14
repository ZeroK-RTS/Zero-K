VFS.Include("LuaRules/Configs/customcmds.h.lua")
local GiveClampedOrderToUnit = Spring.Utilities.GiveClampedOrderToUnit
local jumpRange = GG.jumpDefs[unitDefID].range

function RetreatFunction(hx, hy, hz)
	local jumpReload = Spring.GetUnitRulesParam(unitID,"jumpReload")
	if not jumpReload or jumpReload == 1 then
		local ux, uy, uz = Spring.GetUnitPosition(unitID)
		local moveDistance = math.sqrt((ux - hx)^2 + (uz - hz)^2)
		local disScale = jumpRange/moveDistance*0.95
		local cx, cy, cz = ux + disScale*(hx - ux), hy, uz + disScale*(hz - uz)
		GiveClampedOrderToUnit(unitID, CMD.INSERT, { 0, CMD_JUMP, CMD.OPT_INTERNAL, cx, cy, cz}, CMD.OPT_ALT)
	end
end