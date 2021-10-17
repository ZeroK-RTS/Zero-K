function Spring.Utilities.Traceback(condition)
	if condition then
		Spring.Echo(debug.traceback())
	end
end

local cmdNames = {} -- [cmdID] = "NAME"

for key, value in pairs(CMD) do
	if type(key) == "number" then -- also contains reverse mappings and stuff like OPT_CTRL, but those are strings
		cmdNames[key] = value
	end
end
cmdNames[ 20] = "ATTACK" -- more salient than LOOPBACKATTACK which it shares cmdID with
cmdNames[105] = "MANUALFIRE" -- DGUN is a legacy alias, worse for being a weapon type
cmdNames[150] = "FAILED" -- not listed; in theory can't reach Lua but better be safe

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