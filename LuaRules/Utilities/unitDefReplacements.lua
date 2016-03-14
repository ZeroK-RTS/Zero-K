-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local function GetGridTooltip (unitID)
	local gridCurrent = Spring.GetUnitRulesParam(unitID, "OD_gridCurrent")
	if not gridCurrent then return end

	local windStr = ""
	local minWind = Spring.GetUnitRulesParam(unitID, "minWind")
	if minWind then
		windStr = "\n" ..  WG.Translate("common", "wind_range") .. " " .. math.round(minWind, 1) .. " - " .. math.round(Spring.GetGameRulesParam("WindMax") or 2.5, 1)
	end

	if gridCurrent < 0 then
		return WG.Translate("common", "disabled_no_grid") .. windStr
	end
	local gridMaximum = Spring.GetUnitRulesParam(unitID, "OD_gridMaximum") or 0
	local gridMetal = Spring.GetUnitRulesParam(unitID, "OD_gridMetal") or 0

	return WG.Translate("common", "grid") .. ": " .. math.round(gridCurrent,2) .. "/" .. math.round(gridMaximum,2) .. " E => " .. math.round(gridMetal,2) .. " M " .. windStr
end

local function GetMexTooltip (unitID)
	local metalMult = Spring.GetUnitRulesParam(unitID, "overdrive_proportion")
	if not metalMult then return end

	local currentIncome = Spring.GetUnitRulesParam(unitID, "current_metalIncome")
	local mexIncome = Spring.GetUnitRulesParam(unitID, "mexIncome") or 0
	local baseFactor = Spring.GetUnitRulesParam(unitID, "resourceGenerationFactor") or 1

	if currentIncome == 0 then
		return WG.Translate("common", "disabled_base_metal") .. ": " .. math.round(mexIncome,2)
	end

	return WG.Translate("common", "income") .. ": " .. math.round(mexIncome*baseFactor,2) .. " + " .. math.round(metalMult*100) .. "% " .. WG.Translate("common", "overdrive")
end

local function GetTerraformTooltip(unitID)
	local spent = Spring.GetUnitRulesParam(unitID, "terraform_spent")
	if not spent then return end

	return WG.Translate("common", "terraform") .. " - " .. WG.Translate("common", "estimated_cost") .. ": " .. math.floor(spent) .. " / " .. math.floor(Spring.GetUnitRulesParam(unitID, "terraform_estimate") or 0)
end

local function GetZenithTooltip (unitID)
	local meteorsControlled = Spring.GetUnitRulesParam(unitID, "meteorsControlled")
	if not meteorsControlled then return end

	return WG.Translate("units", "zenith.description") .. " - " .. WG.Translate("common", "meteors_controlled") .. " " .. meteorsControlled .. "/500"
end

local function GetAvatarTooltip(unitID)
	local profileID = Spring.GetUnitRulesParam(unitID, "comm_profileID")
	if not profileID then return end

	local teamID = Spring.GetUnitTeam(unitID)
	local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)

	local name
	if isAI then
		name = select(2, Spring.GetAIInfo(teamID))
	else
		name = Spring.GetPlayerInfo(playerID)
	end

	return name or ""
	-- todo: for extra My Com Feel, use the original owner's name
end

local function GetCustomTooltip (unitID)
	return GetGridTooltip(unitID)
	or GetMexTooltip(unitID)
	or GetTerraformTooltip(unitID)
	or GetZenithTooltip(unitID)
	or GetAvatarTooltip(unitID)
end

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
	if Spring.ValidUnitID(unitID) then
		local customTooltip = GetCustomTooltip(unitID)
		if customTooltip then
			return customTooltip
		end

		local buildPower = Spring.GetUnitRulesParam(unitID, "buildpower_mult")
		if buildPower then
			buildPower = buildPower*10
			desc = desc .. ", " .. WG.Translate("common", "builds_at") .. " " .. buildPower .. " m/s"
		end
	end
	return desc
end

function Spring.Utilities.GetHelptext(ud, unitID)
	local name_override = ud.customParams.statsname or ud.name
	return WG.Translate ("units", name_override .. ".helptext") or ud.customParams.helptext or WG.Translate("common", "no_helptext")
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