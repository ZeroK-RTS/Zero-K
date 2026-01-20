
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local econMultEnabled = nil
local buildTimes = {}
local unitRanges = {}
local planetwarsStructure = {}
local buildPlate = {}
local buildPowerCache = {}
local rangeCache = {}
local baseDefCache = {}
local dynComm = {}
local variableCostUnit = {
	[UnitDefNames["terraunit"].id] = true
}

local spGetUnitAllyTeam = Spring.GetUnitAllyTeam

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	buildTimes[i] = ud.buildTime
	if ud.customParams.level or ud.customParams.dynamic_comm then
		dynComm[i] = true
	end
	if ud.customParams.planetwars_structure then
		planetwarsStructure[i] = true
	end
	if ud.customParams.child_of_factory then
		buildPlate[i] = true
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function GetCachedBaseBuildPower(unitDefID, ud)
	if not buildPowerCache[unitDefID] then
		ud = ud or UnitDefs[unitDefID]
		buildPowerCache[unitDefID] = (ud and ((ud.customParams.nobuildpower and 0) or ud.buildSpeed)) or 0
	end
	return buildPowerCache[unitDefID]
end

local function GetCachedBaseRange(unitDefID, ud)
	if not rangeCache[unitDefID] then
		ud = ud or UnitDefs[unitDefID]
		rangeCache[unitDefID] = ud.maxWeaponRange
	end
	return rangeCache[unitDefID]
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local debugSent = false

function Spring.Utilities.GetUnitCost(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if not (unitDefID and buildTimes[unitDefID]) then
		return 50
	end
	local cost = buildTimes[unitDefID]
	if unitID then
		if variableCostUnit[unitDefID] then
			local paramCost = Spring.GetUnitRulesParam(unitID, "terraform_estimate")
			if not paramCost and not debugSent and GG then
				Spring.Utilities.UnitEcho(unitID, "variableCostUnit missing cost")
				Spring.Echo("unitID, unitDefID, cost", unitID, unitDefID, cost)
				debugSent = true
			end
			cost = paramCost or cost
		end
		cost = cost * ((GG and (GG.att_CostMult[unitID] or 1)) or (Spring.GetUnitRulesParam(unitID, "costMult") or 1))
	end
	if not cost then
		Spring.Echo("Spring.Utilities.GetUnitCost nil cost, unitID", unitID, "unitDefID", unitDefID)
		error("Spring.Utilities.GetUnitCost nil cost")
	end
	return cost
end

function Spring.Utilities.GetUnitValue(unitID, unitDefID)
	local cost = Spring.Utilities.GetUnitCost(unitID, unitDefID)
	local _, buildProgress = Spring.GetUnitIsBeingBuilt(unitID)
	return cost * buildProgress
end

function Spring.Utilities.GetUnitCanBuild(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return false
	end
	return GetCachedBaseBuildPower(unitDefID) > 0
end

function Spring.Utilities.GetUnitBuildSpeed(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return 0
	end
	if econMultEnabled == nil then
		econMultEnabled = (Spring.GetGameRulesParam("econ_mult_enabled") and true) or false
	end
	local buildPower = GetCachedBaseBuildPower(unitDefID)
	local mult = 1
	if unitID then
		mult = mult * (Spring.GetUnitRulesParam(unitID, "totalStaticBuildpowerMult") or 1)
	end
	if unitID then
		if econMultEnabled then
			mult = mult * (Spring.GetGameRulesParam("econ_mult_" .. (spGetUnitAllyTeam(unitID) or "")) or 1)
		end
	elseif econMultEnabled and Spring.GetMyAllyTeamID then
		mult = mult * (Spring.GetGameRulesParam("econ_mult_" .. (Spring.GetMyAllyTeamID() or "")) or 1)
	end
	return mult * buildPower, buildPower
end

local spGetUnitBuildSpeed = Spring.Utilities.GetUnitBuildSpeed

function Spring.Utilities.GetUnitRange(unitID, unitDefID)
	unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
	if not unitDefID then
		return false
	end
	if not dynComm[unitDefID] then
		local range = GetCachedBaseRange(unitDefID)
		return (range > 0) and range
	end
	return Spring.GetUnitRulesParam(unitID, "comm_max_range") or GetCachedBaseRange(unitDefID), Spring.GetUnitRulesParam(unitID, "primary_weapon_range")
end

function Spring.Utilities.GetBaseDefID(unitDefID)
	if not unitDefID then
		return unitDefID
	end
	if baseDefCache then
		return baseDefCache[unitDefID]
	end
	local ud = UnitDefs[unitDefID]
	local bud = ud.customParams.baseDef and UnitDefNames[ud.customParams.baseDef]
	baseDefCache[unitDefID] = bud and bud.id or unitDefID
	return baseDefCache[unitDefID]
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local function GetGridTooltip(unitID, windMult)
	local gridCurrent = Spring.GetUnitRulesParam(unitID, "OD_gridCurrent")
	if not gridCurrent then return end

	local windStr = ""
	local minWind = Spring.GetUnitRulesParam(unitID, "minWind")
	if minWind then
		if econMultEnabled == nil then
			econMultEnabled = (Spring.GetGameRulesParam("econ_mult_enabled") and true) or false
		end
		local maxWind = (Spring.GetGameRulesParam("WindMax") or 2.5)
		if econMultEnabled then
			local mult = (Spring.GetGameRulesParam("econ_mult_" .. (spGetUnitAllyTeam(unitID) or "")) or 1)
			minWind = minWind * mult
			maxWind = maxWind * mult
		end
		windMult = windMult or 1
		minWind = math.round(minWind * windMult, 1)
		maxWind = math.round(maxWind * windMult, 1)
		windStr = "\n" ..  WG.Translate("interface", "wind_range") .. " " .. minWind .. " - " .. maxWind
	end

	if gridCurrent < 0 then
		return WG.Translate("interface", "disabled_no_grid") .. windStr
	end
	local gridMaximum = Spring.GetUnitRulesParam(unitID, "OD_gridMaximum") or 0
	local gridMetal = Spring.GetUnitRulesParam(unitID, "OD_gridMetal") or 0

	return WG.Translate("interface", "grid") .. ": " .. math.round(gridCurrent,2) .. "/" .. math.round(gridMaximum,2) .. " E => " .. math.round(gridMetal,2) .. " M " .. windStr
end

local function GetMexTooltip(unitID, ud)
	local metalMult = Spring.GetUnitRulesParam(unitID, "overdrive_proportion")
	if not metalMult then return end

	local currentIncome = Spring.GetUnitRulesParam(unitID, "current_metalIncome")
	local mexIncome = (Spring.GetUnitRulesParam(unitID, "mexIncome") or 0) * (ud.customParams.metal_extractor_mult or 0) * (Spring.GetUnitRulesParam(unitID, "totalStaticMetalMult") or 1)

	if currentIncome == 0 then
		return WG.Translate("interface", "disabled_base_metal") .. ": " .. math.round(mexIncome,2)
	end

	return WG.Translate("interface", "income") .. ": " .. math.round(mexIncome,2) .. " + " .. math.round(metalMult*100) .. "% " .. WG.Translate("interface", "overdrive")
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
	
	return (WG.Translate("units", "zenith.description") or "Meteor Controller") .. " - " .. (WG.Translate("interface", "meteors_controlled") or "Meteors controlled")
				.. " " .. (meteorsControlled or "0") .. "/" .. (Spring.GetUnitRulesParam(unitID, "meteorsControlledMax") or 300)
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

local function GetPlateTooltip(unitID, ud)
	local unitDefID = ud.id
	if not buildPlate[unitDefID] then
		return false
	end
	local disabled = (Spring.GetUnitRulesParam(unitID, "nofactory") == 1)
	if not disabled then
		return
	end
	local name_override = ud.customParams.statsname or ud.name
	local desc = WG.Translate ("units", name_override .. ".description") or ud.tooltip
	local buildSpeed = spGetUnitBuildSpeed(unitID, unitDefID)
	if buildSpeed > 0 and not ud.customParams.nobuildpower then
		desc = WG.Translate("interface", "builds_at", {desc = desc, bp = math.round(buildSpeed, 1)}) or desc
	end
	return desc .. " Disabled - Too far from operational factory"
end

local function GetCustomTooltip (unitID, ud, windMult)
	return GetGridTooltip(unitID, windMult)
	or GetMexTooltip(unitID, ud)
	or GetTerraformTooltip(unitID)
	or GetZenithTooltip(unitID)
	or GetAvatarTooltip(unitID)
	or GetPlanetwarsTooltip(unitID, ud)
	or GetPlateTooltip(unitID, ud)
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
	local desc = (WG and WG.Translate ("units", name_override .. ".description")) or ud.tooltip
	local isValidUnit = Spring.ValidUnitID(unitID)
	if isValidUnit then
		local customTooltip = GetCustomTooltip(unitID, ud)
		if customTooltip then
			return customTooltip
		end
	end
	
	local buildSpeed = spGetUnitBuildSpeed(unitID, ud.id)
	if buildSpeed > 0 then
		return (WG and WG.Translate("interface", "builds_at", {desc = desc, bp = math.round(buildSpeed, 1)})) or desc
	end
	return desc
end

Spring.Utilities.GetHumanNameForWreck = Spring.Utilities.GetHumanName
Spring.Utilities.GetDescriptionForWreck = Spring.Utilities.GetDescription

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

if Spring.GetModOptions().techk == "1" and WG then
	local function GetTechLevel(unitID)
		if unitID then
			return Spring.GetUnitRulesParam(unitID, "tech_level") or 1
		end
		return (WG.SelectedTechLevel or 1)
	end
	
	Spring.Utilities.GetUnitMaxHealth = function(unitID, unitDefID, healthOverride)
		if healthOverride then
			return healthOverride * math.pow(2, GetTechLevel(unitID) - 1)
		end
		local ud = UnitDefs[unitDefID]
		return ud.health * math.pow(2, GetTechLevel(unitID) - 1)
	end
	
	Spring.Utilities.GetUnitCost = function(unitID, unitDefID)
		unitDefID = unitDefID or Spring.GetUnitDefID(unitID)
		if not (unitDefID and buildTimes[unitDefID]) then
			return 50
		end
		local cost = buildTimes[unitDefID]
		if unitID then
			if variableCostUnit[unitDefID] then
				cost = Spring.GetUnitRulesParam(unitID, "terraform_estimate")
			end
			cost = cost * ((GG and (GG.att_CostMult[unitID] or 1)) or (Spring.GetUnitRulesParam(unitID, "costMult") or 1))
		else
			cost = cost * math.pow(2, (WG.SelectedTechLevel or 1) - 1)
		end
		if not cost then
			Spring.Echo("TECHK, Spring.Utilities.GetUnitCost nil cost, unitID", unitID, "unitDefID", unitDefID)
			error("TECHK, Spring.Utilities.GetUnitCost nil cost")
		end
		return cost
	end

	Spring.Utilities.GetHumanName = function(ud, unitID)
		if not ud then
			return ""
		end
		
		local prefix = ""
		local level = GetTechLevel(unitID)
		local preLevel = level
		while preLevel > 23 do
			prefix = prefix .. "Absurd "
			preLevel = preLevel - 23
		end
		while preLevel > 12 do
			prefix = prefix .. "LEGENDARY "
			preLevel = preLevel - 12
		end
		while preLevel > 7 do
			prefix = prefix .. "Über "
			preLevel = preLevel - 7
		end
		while preLevel > 3 do
			prefix = prefix .. "Super "
			preLevel = preLevel - 3
		end
		while preLevel > 1 do
			prefix = prefix .. "Adv. "
			preLevel = preLevel - 1
		end

		if unitID then
			local name = Spring.GetUnitRulesParam(unitID, "comm_name")
			if name then
				local level = Spring.GetUnitRulesParam(unitID, "comm_level")
				if level then
					return prefix .. name .. " " .. WG.Translate("interface", "lvl") .. " " .. (level + 1)
				else
					return prefix .. name
				end
			end
		end

		local name_override = ud.customParams.statsname or ud.name
		return prefix .. (WG.Translate ("units", name_override .. ".name") or ud.humanName)
	end

	Spring.Utilities.GetDescription = function(ud, unitID)
		if not ud then
			return ""
		end

		local name_override = ud.customParams.statsname or ud.name
		local desc = (WG and WG.Translate ("units", name_override .. ".description")) or ud.tooltip
		local isValidUnit = Spring.ValidUnitID(unitID)
		if isValidUnit then
			local tech = GetTechLevel(unitID) or 1
			local customTooltip = GetCustomTooltip(unitID, ud, math.pow(3, tech - 1))
			if customTooltip then
				return customTooltip
			end
		end
		
		local buildSpeed = spGetUnitBuildSpeed(unitID, ud.id)
		if buildSpeed > 0 then
			if not unitID then
				local mult = math.pow(2, (WG.SelectedTechLevel or 1) - 1)
				buildSpeed = buildSpeed * mult
			end
			return (WG and WG.Translate("interface", "builds_at", {desc = desc, bp = math.round(buildSpeed, 1)})) or desc
		end
		return desc
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function Spring.Utilities.UnitEcho(unitID, st)
	if type(st) == "boolean" then
		st = st and "T" or "F"
	end
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
