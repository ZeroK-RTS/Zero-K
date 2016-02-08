-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function Spring.Utilities.GetHumanName(unitID, ud)
	if unitID then
		local name = Spring.GetUnitRulesParam(unitID, "comm_name")
		if name then
			local level = Spring.GetUnitRulesParam(unitID, "comm_level")
			if level then
				return name .. " Lvl "  .. (level + 1)
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

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local buildTimes = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local realBuildTime = ud.customParams.real_buildtime
	if realBuildTime then
		buildTimes[i] = tonumber(realBuildTime)
	else
		buildTimes[i] = ud.buildTime
	end
end

function Spring.Utilities.GetUnitCost(unitID, unitDefID)
	if unitID then
		local realCost = Spring.GetUnitRulesParam(unitID, "comm_cost")
		if realCost then
			return realCost
		end
	end
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if unitDefID and buildTimes[unitDefID] then
		return buildTimes[unitDefID] 
	end
	return 50
end