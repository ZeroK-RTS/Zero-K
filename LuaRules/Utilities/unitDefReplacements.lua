-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function Spring.Utilities.GetHumanName(unitID, ud)
	if unitID then
		local name = Spring.GetUnitRulesParam(unitID, "comm_name")
		if name then
			local level = Spring.GetUnitRulesParam(unitID, "comm_level")
			if level then
				return name .. " level " .. level
			else
				return name
			end
		end
	end
	if ud then
		return ud.humanName
	end
	return ""
end