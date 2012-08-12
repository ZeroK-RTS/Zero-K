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

-- modifies primary directly; if you don't want to do that then make a copy and pass that
function Spring.Utilities.MergeTable(primary, secondary, deep)
	for i, v in pairs(secondary) do
		-- key not used in primary, assign it the value at same key in secondary
		if not primary[i] then
			if (deep and type(v) == "table") then
				primary[i] = Spring.Utilities.CopyTable(v, true)
			else
				primary[i] = v
			end
		-- values at key in both primary and secondary are tables, merge those
		elseif type(primary[i]) == "table" and type(v) == "table"  then
			Spring.Utilities.MergeTable(primary[i], v, deep)
		end
	end
end