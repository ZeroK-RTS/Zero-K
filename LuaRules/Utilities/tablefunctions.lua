-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--deep not safe with circular tables! defaults To false
function Spring.Utilities.CopyTable(tableToCopy, deep)
  local copy = {}
  for key, value in pairs(tableToCopy) do
    if (deep and type(value) == "table") then
      copy[key] = Spring.Utilities.CopyTable(value, true)
    else
      copy[key] = value
    end
  end
  return copy
end

function Spring.Utilities.MergeTable(primary, secondary, deep)
    local new = Spring.Utilities.CopyTable(primary, deep)
    for i, v in pairs(secondary) do
	    -- key not used in primary, assign it the value at same key in secondary
	    if not new[i] then
		    if (deep and type(v) == "table") then
			    new[i] = Spring.Utilities.CopyTable(v, true)
		    else
			    new[i] = v
		    end
	    -- values at key in both primary and secondary are tables, merge those
	    elseif type(new[i]) == "table" and type(v) == "table"  then
		    new[i] = Spring.Utilities.MergeTable(new[i], v, deep)
	    end
    end
    return new
end

function Spring.Utilities.TableToString(data)
	 local str = ""

    if(indent == nil) then
        indent = 0
    end
	local indenter = "    "
    -- Check the type
    if(type(data) == "string") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "number") then
        str = str .. (indenter):rep(indent) .. data .. "\n"
    elseif(type(data) == "boolean") then
        if(data == true) then
            str = str .. "true"
        else
            str = str .. "false"
        end
    elseif(type(data) == "table") then
        local i, v
        for i, v in pairs(data) do
            -- Check for a table in a table
            if(type(v) == "table") then
                str = str .. (indenter):rep(indent) .. i .. ":\n"
                str = str .. Spring.Utilities.TableToString(v, indent + 2)
            else
                str = str .. (indenter):rep(indent) .. i .. ": " .. Spring.Utilities.TableToString(v, 0)
            end
        end
	elseif(type(data) == "function") then
		str = str .. (indenter):rep(indent) .. 'function' .. "\n"
    else
        echo(1, "Error: unknown data type: %s", type(data))
    end

    return str
end

-- need this because SYNCED.tables are merely proxies, not real tables
local function MakeRealTable(proxy)
	local proxyLocal = proxy
	local ret = {}
	for i,v in spairs(proxyLocal) do
		if type(v) == "table" then
			ret[i] = MakeRealTable(v)
		else
			ret[i] = v
		end
	end
	return ret
end

local function TableEcho(data, name, indent)
	name = name or "TableEcho"
	Spring.Echo((indent or "") .. name .. " = {")
	indent = indent or "    "
	for name, v in pairs(data) do
		local ty =  type(v)
		if ty == "table" then
			TableEcho(v, name, indent .. "    ")
		elseif ty == "boolean" then
			Spring.Echo(indent .. name .. " = " .. (v and "true" or "false"))
		else
			Spring.Echo(indent .. name .. " = " .. v)
		end
	end
	Spring.Echo(indent .. "}")
end

Spring.Utilities.TableEcho = TableEcho