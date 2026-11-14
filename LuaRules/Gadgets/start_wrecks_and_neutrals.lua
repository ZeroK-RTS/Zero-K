--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GetInfo()
	return {
		name      = "Game Start Wrecks and neutrals Modoptions",
		desc      = "Implements Game start wrecks and neutral units",
		author    = "Stiofan",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local MAP_AREA_TO_CAMP_RATIO = 45
local MAP_AREA_TO_VALUE_MULT = 12
local AUTO_MAP_VALUE_OFFSET = -200
local AUTO_WRECK_COUNT_MULT = 1.5
local AUTO_WRECK_VALUE_MULT = 0.7

local NEUTRAL_ADDITIONAL_WRECK_RATIO = 0.8
local NEUTRAL_MOBILE_RATIO = 0.3
local NEUTRAL_EDGE_OFFSET = 700
local CENTER_CAMP_MULT = 3

local WeWantSpice = true

local modOptions = Spring.GetModOptions()
local autoNeutrals = tonumber(modOptions.starting_auto_neutrals) or 0
local autoWrecks = tonumber(modOptions.starting_auto_wrecks) or 0
local autoNeutralsMapToCount =  tonumber(modOptions.starting_auto_neutrals_map_to_count) or MAP_AREA_TO_CAMP_RATIO
local autoNeutralsMapToValue =  tonumber(modOptions.starting_auto_neutrals_map_to_value) or MAP_AREA_TO_VALUE_MULT

local startingWreckCount = tonumber(modOptions.starting_wrecks_count) or 0
local startingWreckValue = tonumber(modOptions.starting_wrecks_value) or 0

local startingNeutralCount = tonumber(modOptions.starting_neutral_count) or 0
local startingNeutralValue = tonumber(modOptions.starting_neutral_value) or 0
local startingNeutralMobileRatio = tonumber(modOptions.starting_neutral_mobile) or NEUTRAL_MOBILE_RATIO
local startingNeutralWreckRatio = tonumber(modOptions.starting_neutral_wrecks_ratio) or NEUTRAL_ADDITIONAL_WRECK_RATIO

local GaiaTeamID     = Spring.GetGaiaTeamID()
local GaiaAllyTeamID = select(6, Spring.GetTeamInfo(GaiaTeamID, false))
local maxStartboxcount = Spring.GetGameRulesParam("startbox_max_n") or 2 -- TODO this seems to have some issue. Startboxjutsu is not good enough
local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local WRECK_TO_UNIT_COST_MULT = 2.5 -- mult to get from wreck -> unit cost
local WATER_DAMAGE = (Game.waterDamage > 0)

local initalAllianceCount = -1 --subtract gaia
for index, allyTeamID in ipairs(Spring.GetAllyTeamList()) do
	local teamlist = Spring.GetTeamList(allyTeamID)
	if (#teamlist) >0 then
		initalAllianceCount = initalAllianceCount +1
	end
end
local neutralAllyTeamID = GaiaAllyTeamID
local startingNeutralsTeamInput = tonumber(modOptions.starting_neutrals_team) or 0

if startingNeutralsTeamInput > 0 and startingNeutralsTeamInput <= initalAllianceCount then -- if inbetween 0 and max teamcount, we have a team to spawn on!
	neutralAllyTeamID = startingNeutralsTeamInput -1 -- -1 for offset 
	if neutralAllyTeamID == GaiaAllyTeamID then --TODO there is likely a better solution, it seems sometimes Gaia is not the last team in the list
		neutralAllyTeamID = neutralAllyTeamID + 1
	end
else -- anything else translates to gaia neutrals
	neutralAllyTeamID = GaiaAllyTeamID
end
if startingNeutralsTeamInput > 0 and startingNeutralsTeamInput <= initalAllianceCount then -- if inbetween 0 and max teamcount, we have a team to spawn on!
	neutralAllyTeamID = startingNeutralsTeamInput -1 -- -1 for offset 
	if neutralAllyTeamID == GaiaAllyTeamID then --TODO there is likely a better solution, it seems sometimes Gaia is not the last team in the list
		neutralAllyTeamID = neutralAllyTeamID + 1
	end
else -- anything else translates to gaia zombies
	neutralAllyTeamID = GaiaAllyTeamID
end

local allCompositions = VFS.Include("LuaRules/Configs/unit_compositions.lua")
local mobileCompositions = allCompositions.mobileCompositions
local staticCompositions = allCompositions.staticCompositions
local mixedCompositions = allCompositions.mixedCompositions
local mexAndGeoNoGoZones = GG.NoGoZonesGetMexAndGeoNoGoZones()
local localNoGoZones = mexAndGeoNoGoZones

local MAP_SIZE_UNIT = 512 --Elmo to lobby mapsize
local CIRCLE_CHECK_COUNT = 15
local CIRCLE_CHECK_RADIUS = 700
local AREA_CHECK_ID = UnitDefNames["energypylon"].id -- small profile and water buildable!
local PLACEMENT_CHECK_ID = UnitDefNames["staticrearm"].id -- a lil bigger, but should be placable often

--Utility
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- TODO would this be a useful util function? maybe it already exists :o
local function GetRandomTeamIDFromAllyTeam(allyTeamID)
	local allyTeamList = Spring.GetTeamList(allyTeamID) or GaiaAllyTeamID
	local teamMateCount = 0
	local teamToSpawnOn
	if allyTeamID == GaiaAllyTeamID then
		return GaiaTeamID
	end
	
	for _,_ in ipairs(allyTeamList) do
		teamMateCount = teamMateCount + 1 
	end
	teamToSpawnOn = allyTeamList[math.random(1,teamMateCount)] or nil
	return teamToSpawnOn
end

-- TODO would this be a useful util function? maybe it already exists :o
local function CheckStartboxOverlap(x,z)
	for i = 0, maxStartboxcount, 1 do
		if GG.CheckStartbox(i,x,z) then
			--Spring.MarkerAddPoint(x, 0, z, "Overlap detected, rerolling")
			return true
		end
	end
	return false
end

-- TODO would this be a useful util function? maybe it already exists :o
local function CheckLavaAndStartbox(x,z,radius)
	local height = Spring.GetGroundHeight(x, z)
	if (WATER_DAMAGE and height <= 0) or Spring.TestBuildOrder(AREA_CHECK_ID, x, 0 ,z, 0) == 0 then
		return true
	end
	if CheckStartboxOverlap(x,z) then
		return true
	end
	local rx,rz
	local degreeIncrement = 360 / CIRCLE_CHECK_COUNT
	local currentAngle = 0
	while currentAngle <= 360 do
		rx = x + radius * math.cos(currentAngle)
		rz = z - radius * math.sin(currentAngle)
		--Spring.MarkerAddPoint(rx, 0, rz, "Circle check")
		if CheckStartboxOverlap(rx,rz) then
			return true
		end
		currentAngle = currentAngle + degreeIncrement
	end 
	return false
end

-- TODO would this be a useful util function?
local function GuesstimateUsableMapArea(mapSizeX,mapSizeZ)
	local mapUnitsX = mapSizeX/MAP_SIZE_UNIT
	local mapUnitsZ = mapSizeZ/MAP_SIZE_UNIT
	local usableArea = mapUnitsX * mapUnitsZ
	
	for xMapUnit = 0.5, mapUnitsX, 1 do
		local x = xMapUnit * MAP_SIZE_UNIT
		for zMapUnit = 0.5, mapUnitsZ, 1 do
			local z = zMapUnit * MAP_SIZE_UNIT
			local height = Spring.GetGroundHeight(x, z)
			if (WATER_DAMAGE and height <= 0) or Spring.TestBuildOrder(AREA_CHECK_ID, x, 0 ,z, 0) == 0 then
				--Spring.MarkerAddPoint(x, 0, z, "can't build here mylord")
				usableArea = usableArea -1
			end
		end
	end
	return usableArea
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetGroupCompositionByBudgetAndType(budget,compositionType)
    if not budget then
        budget = 300
    end
    if not compositionType then
        compositionType = allCompositions.mobileCompositions
    end
    if (budget < 500) then
        return compositionType.tinyCost[math.random(#compositionType.tinyCost)]
	elseif (budget < 1500) then
        return compositionType.lowCost[math.random(#compositionType.lowCost)]
    elseif (budget < 3000) then
        return compositionType.mediumCost[math.random(#compositionType.mediumCost)]
    elseif (budget < 7500) then
        return compositionType.highCost[math.random(#compositionType.highCost)]
    elseif (budget >= 7500) then
        return compositionType.ludicrousCost[math.random(#compositionType.ludicrousCost)]
    end
    return {assaults = 1}
end

local function GetMixedComposition(staticValue,mobileValue)
	local mobileComposition = GetGroupCompositionByBudgetAndType(mobileValue,mobileCompositions)
	local mobileUnitComposition = GG.UnitSpawnerCompositionBuilder(mobileValue,mobileComposition)
	local staticComposition = GetGroupCompositionByBudgetAndType(staticValue,staticCompositions)
	local staticUnitComposition = GG.UnitSpawnerCompositionBuilder(staticValue,staticComposition)
	return GG.UnitSpawnerAddUnitLists({mobileUnitComposition,staticUnitComposition})
end


local function SetupUnitComposition(campValue,mobileRatio)
	local unitComposition = {}
	if mobileRatio == 1 then
		local mobileComposition = GetGroupCompositionByBudgetAndType(campValue,mobileCompositions)
		unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,mobileComposition)
	elseif mobileRatio == 0 then
		local staticComposition = GetGroupCompositionByBudgetAndType(campValue,staticCompositions)
		unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,staticComposition)
	else
		local mobileBudget = campValue * mobileRatio
		local staticBudget = campValue - mobileBudget
		unitComposition = GetMixedComposition(staticBudget,mobileBudget)
	end
	return unitComposition
end

local function SpawnNeutralCamps(campCount,unitBudget,mobileRatio,additionWrecksRatio)
	local unitIDs
	local teamID = GaiaTeamID
	local wreckBudget = 0
	if additionWrecksRatio ~= 0 then
		wreckBudget = unitBudget * additionWrecksRatio * WRECK_TO_UNIT_COST_MULT
	end
	
	for i = 1, campCount/2, 1 do
		--we mirror for an attempt at fairness.
		local mapOffsetX, mapOffsetZ = NEUTRAL_EDGE_OFFSET, NEUTRAL_EDGE_OFFSET
		local x,z = math.random(mapOffsetX,mapSizeX-mapOffsetX),math.random(mapOffsetZ,mapSizeZ-mapOffsetZ)
		local x2,z2
		local iteration = 0
		
		x,z = GG.NoGoZonesGetValidSpawnPositionForUnit(PLACEMENT_CHECK_ID,{x,z},false,localNoGoZones)
		x2,z2 = mapSizeX-x,mapSizeZ-z
		-- My startbox jutsu has improved 
		while CheckLavaAndStartbox(x,z,CIRCLE_CHECK_RADIUS) or CheckLavaAndStartbox(x2,z2,CIRCLE_CHECK_RADIUS)  do
			x,z = math.random(mapOffsetX,mapSizeX-mapOffsetX),math.random(mapOffsetZ,mapSizeZ-mapOffsetZ)
			x,z = GG.NoGoZonesGetValidSpawnPositionForUnit(PLACEMENT_CHECK_ID,{x,z},false,localNoGoZones)
			x2,z2 = mapSizeX-x,mapSizeZ-z
			if iteration > 10 then
				x,z = mapSizeX/2,mapSizeZ/2
				x2,z2 = mapSizeX-x,mapSizeZ-z
				break
			end
			iteration = iteration +1
		end
		local unitComposition = SetupUnitComposition(unitBudget,mobileRatio)
		if wreckBudget > 0 then
			local wreckComposition = SetupUnitComposition(wreckBudget,mobileRatio)
			for index, value in ipairs(wreckComposition) do
				value.wreckChance = 1
				value.spacing = math.random(32,64)
			end
			unitComposition = GG.UnitSpawnerAddUnitLists({unitComposition,wreckComposition})
		end
		--Spring.Echo("Start neutrals")
		--Spring.Utilities.TableEcho(unitComposition)
		
		teamID = GetRandomTeamIDFromAllyTeam(neutralAllyTeamID)
		unitIDs,localNoGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,teamID,localNoGoZones)
		Spring.MarkerAddPoint(x, 0, z, "Reports of Remnants") -- important as they arent visible globaly
		teamID = GetRandomTeamIDFromAllyTeam(neutralAllyTeamID)
		unitIDs,localNoGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x2,z2,teamID,localNoGoZones)
		Spring.MarkerAddPoint(x2, 0, z2, "Reports of Remnants")
	end
	--uneven number results in big map center camp :o 
	if campCount % 2 == 1 then
		local unitComposition = SetupUnitComposition(unitBudget*CENTER_CAMP_MULT,mobileRatio)
		--Spring.Utilities.TableEcho(unitComposition)
		if wreckBudget > 0 then
			local wreckComposition = SetupUnitComposition(wreckBudget*CENTER_CAMP_MULT,mobileRatio)
			for index, value in ipairs(wreckComposition) do
				value.wreckChance = 1
				value.spacing = math.random(32,64)
			end
			unitComposition = GG.UnitSpawnerAddUnitLists({unitComposition,wreckComposition})
		end
		teamID = GetRandomTeamIDFromAllyTeam(neutralAllyTeamID)
		unitIDs,localNoGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,teamID,localNoGoZones)
		Spring.MarkerAddPoint(mapSizeX/2, 0, mapSizeZ/2, "Reports of large Remnants")
	end
end

-- duplicate of spawning neutral camps without the startbox check
local function SpawnWreckClump(wreckFieldCount,wreckFieldValue)
	local unitIDs
	local unitComposition
	local unitValue = wreckFieldValue * WRECK_TO_UNIT_COST_MULT
	for i = 1, wreckFieldCount/2, 1 do
		local mobileRatio = math.random()
		--we mirror for an attempt at fairness
		local x,z = math.random(0,mapSizeX),math.random(mapSizeZ)
		local x2,z2 = mapSizeX-x,mapSizeZ-z
		
		local unitComposition = SetupUnitComposition(unitValue,mobileRatio,1)
		for index, value in ipairs(unitComposition) do
			value.wreckChance = 1
			--value.spacing = math.random(0,64)
		end
		
		unitIDs,localNoGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID,localNoGoZones)
		Spring.MarkerAddPoint(x, 0, z, "Wreckfield") --people have eyes... but it may still be good to ping
		unitIDs,localNoGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x2,z2,GaiaTeamID,localNoGoZones)
		Spring.MarkerAddPoint(x2, 0, z2, "Wreckfield")
	end
	--uneven number results in big map center field
	if wreckFieldCount % 2 == 1 then
		unitValue = unitValue * CENTER_CAMP_MULT
		local unitComposition = SetupUnitComposition(unitValue,0.5,1)
		for index, value in ipairs(unitComposition) do
			value.wreckChance = 1
			--value.spacing = math.random(0,64)
		end
		unitIDs,localNoGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID,localNoGoZones)
	end
end

--it will be hard to do anything definitive without some startbox jutsu or map and mex analysis
local function GuesstimateCampCountAndValueByMapSize(mapSizeX,mapSizeZ)

	--not all map area is useable!
	local mapUnitArea = GuesstimateUsableMapArea(mapSizeX,mapSizeZ)

	--LETS START GUESSTIMATING!!!
	--get arbitrary values from mapsize!
	
	-- count...
	-- smallest maps are 8x8 so area 64 -- count can be 1-2, uneven camps are bigger and centered
	-- some medium small maps are 10x12 so 120 -could stomach 2-3?
	-- lets go with 45 area per camp base? with how maps work I would need a function to do it well..
	-- but this estimation is okay
	local campCount = math.floor(mapUnitArea/autoNeutralsMapToCount)
	
	-- value...
	-- 8x8 -> 64 so 64 * 100 -> 640m ?
	-- seems a lil much since 
	-- 10x12 -> 120 so 120 *100 -> 1200m for 2-3 camps?
	-- we ball, trial and error
	-- it may be smart to revamp things into a entire map budget split between the amount of camps rather than the inverse
	-- though this scales the neutrals nicely Imo
	local campValue = mapUnitArea * autoNeutralsMapToValue + AUTO_MAP_VALUE_OFFSET
	
	return campCount, campValue
end

local function SpawnNeutralsAndWrecks()
	
	local neutralCount,neutralValue = startingNeutralCount,startingNeutralValue
	local wreckCount,wreckValue = startingWreckCount, startingWreckValue
	
	if autoNeutrals ~= 0 or autoWrecks ~= 0 then
		local count,value = GuesstimateCampCountAndValueByMapSize(mapSizeX,mapSizeZ)
		if autoNeutrals ~= 0 then
			neutralCount,neutralValue = neutralCount + count, neutralValue + value
			if WeWantSpice then
				if 0.5 > math.random() then
					neutralCount = neutralCount + 1 -- an extra camp!
				else
					neutralValue = neutralValue + math.ceil(neutralValue*1/neutralCount) -- 1 camp of value spread between all
				end
			end
		end
		if autoWrecks ~= 0 then
			wreckCount,wreckValue = wreckCount + count*AUTO_WRECK_COUNT_MULT, wreckValue + value*AUTO_WRECK_VALUE_MULT
			if WeWantSpice then
				if 0.5 > math.random() then
					wreckCount = wreckCount + 1 -- an extra camp!
				else
					wreckValue = wreckValue + math.ceil(wreckValue*1/wreckCount) -- 1 camp of value spread between all
				end
			end
		end
	end
	if neutralCount > 0 and neutralValue > 0 then
		SpawnNeutralCamps(neutralCount,neutralValue,startingNeutralMobileRatio,startingNeutralWreckRatio)
	end
	
	if wreckCount > 0 and wreckValue > 0 then
		SpawnWreckClump(wreckCount,wreckValue)
	end
end
	
function gadget:Initialize()
	maxStartboxcount = Spring.GetGameRulesParam("startbox_max_n")
	
	SpawnNeutralsAndWrecks()
end

function gadget:GameStart()
	
	local testCount, testValue = GuesstimateCampCountAndValueByMapSize(mapSizeX,mapSizeZ)
	Spring.Echo("CampCount = "..testCount)
	Spring.Echo("CampStaticValue = "..testValue-testValue*startingNeutralMobileRatio)
	Spring.Echo("CampMobileValue = "..testValue*startingNeutralMobileRatio)
	

end