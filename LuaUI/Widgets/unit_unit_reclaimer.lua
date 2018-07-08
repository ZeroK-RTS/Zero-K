function widget:GetInfo() return {
	name    = "Specific Unit Reclaimer",
	desc    = "Reclaims targeted unit types in an area",
	author  = "Google Frog",
	date    = "May 12, 2008",
	license = "GNU GPL, v2 or later",
	layer   = -1338,
	enabled = true
} end

local EMPTY_TABLE = {}

function widget:CommandNotify(cmdID, params, options)

	if not options.ctrl or (cmdID ~= CMD.RECLAIM) or (#params ~= 4) then
		return
	end

	local cx, cy, cz = params[1], params[2], params[3]
	local mx, my = Spring.WorldToScreenCoords(cx, cy, cz)
	local cType, targetID = Spring.TraceScreenRay(mx, my)

	if (cType ~= "unit") then
		return
	end

	if not options.shift and not options.meta then
		Spring.GiveOrder (CMD.STOP, EMPTY_TABLE, 0)
		options.shift = true
		options.coded = options.coded + CMD.OPT_SHIFT
	end

	local myAllyTeam = Spring.GetMyAllyTeamID()
	if myAllyTeam ~= Spring.GetUnitAllyTeam(targetID) then
		return
	end

	local cr = params[4]
	local areaUnits = Spring.GetUnitsInCylinder(cx, cz, cr)
	local unitDefID = Spring.GetUnitDefID(targetID)

	local paramTable = {-1}
	for i = 1, #areaUnits do
		local unitID = areaUnits[i]
		if Spring.GetUnitDefID(unitID) == unitDefID and Spring.GetUnitAllyTeam(unitID) == myAllyTeam then
			paramTable[1] = unitID
			WG.CommandInsert(CMD.RECLAIM, paramTable, options)
		end
	end

	return true
end
