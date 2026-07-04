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

function Spring.Utilities.IsNanOrInf(...)
	local myargs = {...}
	for i = 1, #myargs do
		local x = myargs[i]
		if x ~= x or x == math.huge or x == -math.huge then
			return true
		end
	end
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

function Spring.Utilities.TraceFullEcho(...)
	if not debug then
		Spring.Echo("TraceFullEcho not available", ...)
		-- debug is not in luarules
		return
	end
	local myargs = {...}
	infostr = ""
	for i,v in ipairs(myargs) do
		infostr = infostr .. tostring(v) .. "\t"
	end
	if infostr ~= "" then
		infostr = "Trace:[" .. infostr .. "]\n"
	end
	local functionstr = "" -- "Trace:["
	for i = 2, 16 do
		if debug.getinfo(i) then
			local funcName = (debug and debug.getinfo(i) and debug.getinfo(i).name)
			if funcName then
				functionstr = functionstr .. tostring(i-1) .. ": " .. tostring(funcName) .. " "
				local arguments = ""
				local funcName = (debug and debug.getinfo(i) and debug.getinfo(i).name) or "??"
				if funcName ~= "??" then
					for j = 1, 10 do
						local name, value = debug.getlocal(i, j)
						if not name then
							break
						end
						local sep = ((arguments == "") and "") or  "; "
						arguments = arguments .. sep .. ((name and tostring(name)) or "name?") .. "=" .. tostring(value)
					end
				end
				functionstr  = functionstr .. " Locals:(" .. arguments .. ")" .. "\n"
			else
				break
			end
		else
			break
		end
	end
	Spring.Echo(infostr .. functionstr)
end