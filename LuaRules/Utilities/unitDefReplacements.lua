-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function Spring.Utilities.GetHumanName(ud, unitID)
	if unitID then
		local name = Spring.GetUnitRulesParam(unitID, "comm_name")
		if name then
			local level = Spring.GetUnitRulesParam(unitID, "comm_level")
			if level then
				return name .. " " .. WG.Translate("common", "lvl") .. " " .. (level + 1)
			else
				return name
			end
		end
	end

	local name_override = ud.customParams.statsname or ud.name
	return WG.Translate ("units", name_override .. ".name") or ud.humanName
end

function Spring.Utilities.GetDescription(ud, unitID)
	local name_override = ud.customParams.statsname or ud.name
	local desc = WG.Translate ("units", name_override .. ".description") or ud.tooltip
	if unitID then
		local buildPower = Spring.GetUnitRulesParam(unitID, "buildpower_mult")
		if buildPower then
			buildPower = buildPower*10
			desc = desc .. ", " .. WG.Translate("common", "builds_at") .. " " .. buildPower .. " m/s"
		end
	end
	return desc
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

function Spring.Utilities.GetUnitCanBuild(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return 0
	end
	local ud = UnitDefs[unitDefID]
	local buildPower = (ud and ((ud.customParams.nobuildpower and 0) or ud.buildSpeed)) or 0
	return buildPower > 0
end

function Spring.Utilities.GetUnitBuildSpeed(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return 0
	end
	local ud = UnitDefs[unitDefID]
	local buildPower = (ud and ((ud.customParams.nobuildpower and 0) or ud.buildSpeed)) or 0
	if unitID then
		local mult = Spring.GetUnitRulesParam(unitID, "buildpower_mult")
		if mult then
			return mult * buildPower
		end
	end
	return buildPower
end