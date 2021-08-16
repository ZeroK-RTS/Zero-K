function Spring.Utilities.Traceback(condition)
	if condition then
		Spring.Echo(debug.traceback())
	end
end

local cmdNames = {
	-- engine commands; note the gaps (for instance there is no 3)
	[  0] = "STOP",
	[  1] = "INSERT",
	[  2] = "REMOVE",
	[  5] = "WAIT",
	[  6] = "TIMEWAIT",
	[  7] = "DEATHWAIT",
	[  8] = "SQUADWAIT",
	[  9] = "GATHERWAIT",
	[ 10] = "MOVE",
	[ 15] = "PATROL",
	[ 16] = "FIGHT",
	[ 20] = "ATTACK",
	[ 21] = "AREA_ATTACK",
	[ 25] = "GUARD",
	[ 30] = "AISELECT",
	[ 35] = "GROUPSELECT",
	[ 36] = "GROUPADD",
	[ 37] = "GROUPCLEAR",
	[ 40] = "REPAIR",
	[ 45] = "FIRE_STATE",
	[ 50] = "MOVE_STATE",
	[ 55] = "SETBASE",
	[ 60] = "INTERNAL",
	[ 65] = "SELFD",
	[ 75] = "LOAD_UNITS",
	[ 76] = "LOAD_ONTO",
	[ 80] = "UNLOAD_UNITS",
	[ 81] = "UNLOAD_UNIT",
	[ 85] = "ONOFF",
	[ 90] = "RECLAIM",
	[ 95] = "CLOAK",
	[100] = "STOCKPILE",
	[105] = "MANUALFIRE",
	[110] = "RESTORE",
	[115] = "REPEAT",
	[120] = "TRAJECTORY",
	[125] = "RESURRECT",
	[130] = "CAPTURE",
	[135] = "AUTOREPAIRLEVEL",
	[145] = "IDLEMODE",
	[150] = "FAILED",
}
for cmdName, cmdID in pairs(VFS.Include("LuaRules/Configs/customcmds.lua", nil, VFS.GAME)) do
	cmdNames[cmdID] = cmdName
end

function Spring.Utilities.CommandNameByID(cmdID) -- returns a human-parsable string
	local ret
	if type(cmdID) ~= "number" then
		ret = "INVALID"
	elseif cmdID >= 0 then
		ret = cmdNames[cmdID] or "UNKNOWN"
	elseif UnitDefs[-cmdID] then
		ret = "BUILD " .. UnitDefs[-cmdID].name
	else
		ret = "INVALID BUILD"
	end

	return ret .. " (" .. tostring(cmdID) .. ")"
end