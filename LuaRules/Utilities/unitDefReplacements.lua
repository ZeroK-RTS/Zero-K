
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local buildTimes = {}
local planetwarsStructure = {}
local variableCostUnit = {
	[UnitDefNames["terraunit"].id] = true
}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	buildTimes[i] = ud.buildTime
	if ud.customParams.level or ud.customParams.dynamic_comm then
		variableCostUnit[i] = true
	end
	if ud.customParams.planetwars_structure then
		planetwarsStructure[i] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local function GetGridTooltip(unitID)
	local gridCurrent = Spring.GetUnitRulesParam(unitID, "OD_gridCurrent")
	if not gridCurrent then return end

	local windStr = ""
	local minWind = Spring.GetUnitRulesParam(unitID, "minWind")
	if minWind then
		windStr = "\n" ..  WG.Translate("interface", "wind_range") .. " " .. math.round(minWind, 1) .. " - " .. math.round(Spring.GetGameRulesParam("WindMax") or 2.5, 1)
	end

	if gridCurrent < 0 then
		return WG.Translate("interface", "disabled_no_grid") .. windStr
	end
	local gridMaximum = Spring.GetUnitRulesParam(unitID, "OD_gridMaximum") or 0
	local gridMetal = Spring.GetUnitRulesParam(unitID, "OD_gridMetal") or 0

	return WG.Translate("interface", "grid") .. ": " .. math.round(gridCurrent,2) .. "/" .. math.round(gridMaximum,2) .. " E => " .. math.round(gridMetal,2) .. " M " .. windStr
end

local function GetMexTooltip(unitID)
	local metalMult = Spring.GetUnitRulesParam(unitID, "overdrive_proportion")
	if not metalMult then return end

	local currentIncome = Spring.GetUnitRulesParam(unitID, "current_metalIncome")
	local mexIncome = Spring.GetUnitRulesParam(unitID, "mexIncome") or 0
	local baseFactor = Spring.GetUnitRulesParam(unitID, "resourceGenerationFactor") or 1

	if currentIncome == 0 then
		return WG.Translate("interface", "disabled_base_metal") .. ": " .. math.round(mexIncome,2)
	end

	return WG.Translate("interface", "income") .. ": " .. math.round(mexIncome*baseFactor,2) .. " + " .. math.round(metalMult*100) .. "% " .. WG.Translate("interface", "overdrive")
end

local function GetTerraformTooltip(unitID)
	local spent = Spring.GetUnitRulesParam(unitID, "terraform_spent")
	if not spent then return end

	return WG.Translate("interface", "terraform") .. " - " .. WG.Translate("interface", "estimated_cost") .. ": " .. math.floor(spent) .. " / " .. math.floor(Spring.GetUnitRulesParam(unitID, "terraform_estimate") or 0)
end

local function GetZenithTooltip (unitID)
	local meteorsControlled = Spring.GetUnitRulesParam(unitID, "meteorsControlled")
	if not meteorsControlled then
		return
	end
	
	return (WG.Translate("units", "zenith.description") or "Meteor Controller") .. " - " .. (WG.Translate("interface", "meteors_controlled") or "Meteors controlled") .. " " .. (meteorsControlled or "0") .. "/300"
end

local function GetAvatarTooltip(unitID)
	local commOwner = Spring.GetUnitRulesParam(unitID, "commander_owner")
	if not commOwner then return end
	return commOwner or ""
end

local function GetPlanetwarsTooltip(unitID, ud)
	if not planetwarsStructure[ud.id] then
		return false
	end
	local disabled = (Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1)
	if not disabled then
		return
	end
	local name_override = ud.customParams.statsname or ud.name
	local desc = WG.Translate ("units", name_override .. ".description") or ud.tooltip
	return desc .. " - Disabled"
end

local function GetCustomTooltip (unitID, ud)
	return GetGridTooltip(unitID)
	or GetMexTooltip(unitID)
	or GetTerraformTooltip(unitID)
	or GetZenithTooltip(unitID)
	or GetAvatarTooltip(unitID)
	or GetPlanetwarsTooltip(unitID, ud)
end

function Spring.Utilities.GetHumanName(ud, unitID)
	if not ud then
		return ""
	end

	if unitID then
		local name = Spring.GetUnitRulesParam(unitID, "comm_name")
		if name then
			local level = Spring.GetUnitRulesParam(unitID, "comm_level")
			if level then
				return name .. " " .. WG.Translate("interface", "lvl") .. " " .. (level + 1)
			else
				return name
			end
		end
	end

	local name_override = ud.customParams.statsname or ud.name
	return WG.Translate ("units", name_override .. ".name") or ud.humanName
end

function Spring.Utilities.GetDescription(ud, unitID)
	if not ud then
		return ""
	end

	local name_override = ud.customParams.statsname or ud.name
	local desc = WG.Translate ("units", name_override .. ".description") or ud.tooltip
	if Spring.ValidUnitID(unitID) then
		local customTooltip = GetCustomTooltip(unitID, ud)
		if customTooltip then
			return customTooltip
		end

		local buildPower = Spring.GetUnitRulesParam(unitID, "buildpower_mult")
		if buildPower then
			buildPower = buildPower*10
			desc = desc .. ", " .. WG.Translate("interface", "builds_at") .. " " .. buildPower .. " m/s"
		end
	end
	return desc
end

function Spring.Utilities.GetHelptext(ud, unitID)
	local name_override = ud.customParams.statsname or ud.name
	return WG.Translate ("units", name_override .. ".helptext") or WG.Translate("interface", "no_helptext")
end

function Spring.Utilities.GetUnitHeight(ud)
	local customHeight = ud.customParams.custom_height
	return (customHeight and tonumber(customHeight)) or ud.height
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function Spring.Utilities.GetUnitCost(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if unitID and variableCostUnit[unitDefID] then
		local realCost = Spring.GetUnitRulesParam(unitID, "comm_cost") or Spring.GetUnitRulesParam(unitID, "terraform_estimate")
		if realCost then
			return realCost
		end
	end
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

function Spring.Utilities.UnitEcho(unitID, st)
	st = st or unitID
	if Spring.ValidUnitID(unitID) then
		local x,y,z = Spring.GetUnitPosition(unitID)
		Spring.MarkerAddPoint(x,y,z, st)
	else
		Spring.Echo("Invalid unitID")
		Spring.Echo(unitID)
		Spring.Echo(st)
	end
end

function Spring.Utilities.FeatureEcho(featureID, st)
	st = st or featureID
	if Spring.ValidFeatureID(featureID) then
		local x,y,z = Spring.GetFeaturePosition(featureID)
		Spring.MarkerAddPoint(x,y,z, st)
	else
		Spring.Echo("Invalid featureID")
		Spring.Echo(featureID)
		Spring.Echo(st)
	end
end
