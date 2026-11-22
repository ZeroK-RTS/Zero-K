--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GetInfo()
	return {
		name      = "Unit Composition Spawning API",
		desc      = "Implements unit spawning and composition building functions",
		author    = "Stiofan",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0, -- Before terraforming gadget (I dont know when would be appropriate)
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetGameFrame = Spring.GetGameFrame

local modOptions = Spring.GetModOptions()
local GaiaTeamID = Spring.GetGaiaTeamID()
local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local classGroupings, sectionGroupings, taggedUnitDefNames , taggedUnitDefIDs = VFS.Include("LuaRules/Configs/unit_class_groupings.lua")
local allCompositions = VFS.Include("LuaRules/Configs/unit_compositions.lua")
local SPACING_MIN = 0
local SPACING_MAX = 96
local Y_OFFSET = 0

--Utilities
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- adds 2 Unit Lists together! accounts for different "spellings"
local function AddUnitLists(tableList)
	local returnList = {}
	for index, table in ipairs(tableList) do
		for i, v in pairs(table) do
			if type(v) == "table" then
				returnList[#returnList +1] = v
			elseif type(i) =="table" then
				returnList[#returnList +1] = i
			elseif type(i) =="string"and type(v) == "number" then
				returnList[#returnList +1] = {unitDefName = i, unitCount = v}
			else
				Spring.Echo("Input of AddUnitLists unit_composition_spawner has error")
				Spring.Utilities.TableEcho(table)
			end
		end
	end
	return returnList
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--
local function CheckTagAndGroupMatch(tagsToMatch,groupsToMatch)
	for index, tag in ipairs(tagsToMatch) do
		for index, group in ipairs(groupsToMatch) do
			if tag == group  then
				return true
			end
		end
	end
	return false
end

local function GetUnitDefListByGroupSectionAndMoveType(taggedUnitDefNameTable,classGroups,sectionGroups,moveGroups)
	local returnUnitList
	for unitDefName, unitDefTags in pairs(taggedUnitDefNameTable) do
		--pyramid is meh, but break doesnt go to the next loop does it?
		if not classGroups or CheckTagAndGroupMatch(unitDefTags.classTags,classGroups) then
			if not sectionGroups or CheckTagAndGroupMatch(unitDefTags.sectionTags,sectionGroups) then
				if not moveGroups or 
				unitDefTags.movementTags[1] == "static" or 
				-- this ends up with mostly BW in bombs as an issue maybe, other gs and planes are not bound to normal roles, they are too finiky for that
				unitDefTags.movementTags[1] == "air" or 
				CheckTagAndGroupMatch(unitDefTags.movementTags,moveGroups) then
					if not returnUnitList then
						returnUnitList = {unitDefName}
					else
						table.insert(returnUnitList,unitDefName)
					end
				end
			end
		end
	end
	return returnUnitList
end

local function GetRandomUnitsFromDefListByCount(targetCount,unitDefNameList,multiRandomise)
	if not unitDefNameList then
		return {}
	end
	local unitDefName = unitDefNameList[math.random(#unitDefNameList)]
	if not multiRandomise then
		local returnUnitArray = {} 
		returnUnitArray[1] = {unitDefName = unitDefName, unitCount = targetCount}
		return  returnUnitArray
	end
	local unitCount = 0
	local unitDefArrayKeys = {}
	local returnUnitArray = {}
	while unitCount < targetCount do
		if not unitDefArrayKeys[unitDefName] then
			local unitArrayKey = #returnUnitArray + 1
			unitDefArrayKeys[unitDefName] = unitArrayKey
			returnUnitArray[unitArrayKey] = {unitDefName = unitDefName, unitCount = 1}
		else
			local unitArrayKey = unitDefArrayKeys[unitDefName]
			local newUnitCount = returnUnitArray[unitArrayKey].unitCount + 1
			returnUnitArray[unitArrayKey] = {unitDefName = unitDefName, unitCount = newUnitCount}
		end
		unitCount = unitCount + 1
		unitDefName = unitDefNameList[math.random(#unitDefNameList)]
	end
	return returnUnitArray
end


local function GetRandomUnitsFromDefListForCost(budget,unitDefNameList,multiRandomise)
	if not unitDefNameList then
		--Spring.Echo("unitDefName ended up empty")
		--Spring.Echo(unitDefNameList)
		return {},budget,0
	end
	local unitDefArrayKeys = {}
	local returnUnitArray = {}
	local excess = 0
	local unitCount = 0
	local shuffledUnitDefNameList = unitDefNameList
	if not shuffledUnitDefNameList then
		--There is some typo I cant seem to find that will run into issues on nil here
		shuffledUnitDefNameList = {[[amphimpulse]],[[amphraid]],[[hoverdepthcharge]],[[hoverraid]],[[amphriot]],}
	end
	Spring.Utilities.PermuteList(shuffledUnitDefNameList)
	local unitDefName
	local unitCost
	local loopWithHit = true
	while loopWithHit do --while theres at least one unit that may fit into budget we continue
		loopWithHit = false
		for i = 1,  #shuffledUnitDefNameList, 1 do --we walk a shuffled list of all options instead of randomising to try and spend all budget
			unitDefName = shuffledUnitDefNameList[i]
			unitCost = Spring.Utilities.GetUnitCost(nil,UnitDefNames[unitDefName].id)--GetCostFromUnitDefName(unitDefName)
			if not multiRandomise and unitCost <= budget then --we found a shuffled unit that fits and spend all budget
				unitCount = math.floor(budget/unitCost)
				returnUnitArray[1] = {unitDefName = unitDefName, unitCount = unitCount}
				excess = budget%unitCost
				return returnUnitArray,excess,unitCount
			elseif unitCost <= budget then -- we found something that fits and add it to return table before looking for another 
			-- TODO There is an argument to randomise here instead of walking the array, but it spends most budget this way
				if not unitDefArrayKeys[unitDefName] then
					local unitArrayKey = #returnUnitArray + 1
					unitDefArrayKeys[unitDefName] = unitArrayKey
					returnUnitArray[unitArrayKey] = {unitDefName = unitDefName, unitCount = 1}
				else
					local unitArrayKey = unitDefArrayKeys[unitDefName]
					local newUnitCount = returnUnitArray[unitArrayKey].unitCount + 1
					returnUnitArray[unitArrayKey] = {unitDefName = unitDefName, unitCount = newUnitCount}
				end
				budget = budget - unitCost
				loopWithHit = true
				unitCount = unitCount + 1
			end
		end
		Spring.Utilities.PermuteList(shuffledUnitDefNameList)
	end
	--[[Spring.Echo(unitDefCountList)
	for key, value in pairs(unitDefCountList) do
		Spring.Echo(key)
		Spring.Echo(value)
	end--]]
	return returnUnitArray,budget,unitCount
end

--[[ 
unitTypeAndRatio should be "scout"= 2 where 2 is the fraction of the budget allocated on the budget
 so for:{
 	scout = 2,
	skirm = 1,
 } 
	2/3 of the budget goes into scouts
	1/3 goes into skirmishers
A more complex setup would be
{
	{classGroup = scout, budgetFraction = 2, minUnits = 1, multiRandomise = true, wreckChance = 0.5},
	{classGroup = skirm, budgetFraction = 1, minUnits =2, multiRandomise = false},
	{classGroup = cloakriot, budgetFraction 0.2, minUnits = 5}
}
returns something akin to 
{ unitDefName = "vehriot",count = 2,wreckChance = 0.5,spacing = 64}
]]
local function CompositionBuilder(budget,unitGroupAndParams,sectionGroups,movementGroups,customTaggedUnitDefNames)
	local returnComposition = {}
	local typeComposition = {}
	local budgetTotalFraction = 0
	local excessBudget = 0
	--Spring.Echo(unitTypeAndRatio)
	if not sectionGroups then
		sectionGroups = {"baseGame","extraUnits"}
	end
	if not movementGroups then
		movementGroups = {"veh","bot","amph","hover","spider"}
	end
	if not customTaggedUnitDefNames then --if wished one can modify the base configs somewhere and supply them again.
		customTaggedUnitDefNames = taggedUnitDefNames
	end
	for index, data in pairs(unitGroupAndParams) do
		local budgetFraction = 1
		if type(data) == "table" and data.classGroup then
			budgetFraction = data.fraction or budgetFraction
		elseif type(data) == "number" then
			budgetFraction = data or 1
		else
			Spring.Echo("Input of Compositionbuilder in unit_composition_spawner has error")
		end
		if not budgetFraction then
			budgetFraction = 1
		end
		budgetTotalFraction = budgetTotalFraction + budgetFraction
	end
	if budgetTotalFraction <= 0 then
		error("the total budgetfraction ends up 0 or negative")
	end
	--its meh that we loop twice but otherwise we can't get the total Fractions right? I suppose using % would work, but that is more math on the end user
	for index, data in pairs(unitGroupAndParams) do
		local classGroups = nil
		local sectionGroups = sectionGroups
		local budgetFraction = 1
		local multiRandomise = true --math.random() < 0.3
		local minUnits = 0
		local wreckChance = 0
		local unitCount
		if type(data) == "table" and data.classGroup then
			classGroups = data.classGroup or classGroups
			sectionGroups = sectionGroups or sectionGroups
			budgetFraction = data.budgetFraction or budgetFraction
			multiRandomise = data.multiRandomise or multiRandomise
			minUnits = data.minUnits or minUnits
			wreckChance = data.wreckChance or wreckChance
		elseif type(data) == "number" then
			classGroups = index
			budgetFraction = data or 1
		else
			Spring.Echo("Input of Compositionbuilder in unit_composition_spawner has error")
		end
		--there is likely a more satisfying way to do the excess?
		local budgetToSpend = budget*budgetFraction/budgetTotalFraction + excessBudget
		--Spring.Utilities.TableEcho(classGroups)
		--A specific unitDefName is supplied
		if UnitDefNames[classGroups] then
			local count = math.floor(budgetToSpend/Spring.Utilities.GetUnitCost(nil,UnitDefNames[classGroups].id))
			if count < minUnits then
				count = minUnits
			end
			if count > 0 then
				typeComposition = {{unitDefName = classGroups, unitCount = count}}
			else
				typeComposition = {}
			end
			--Spring.Utilities.TableEcho(typeComposition)
		else
		-- a grouping is supplied
			if type(classGroups) ~= table then
				--Spring.Echo(classGroups)
				--Spring.Echo(budgetFraction)
				classGroups = {classGroups}
				--Spring.Utilities.TableEcho(classGroups)
			end
			local selectedUnitDefList = GetUnitDefListByGroupSectionAndMoveType(customTaggedUnitDefNames,classGroups,sectionGroups,movementGroups)
			--Spring.Utilities.TableEcho(selectedUnitDefList)
			typeComposition,excessBudget,unitCount = GetRandomUnitsFromDefListForCost(budgetToSpend,selectedUnitDefList,multiRandomise)
			--Spring.Utilities.TableEcho(typeComposition)
			if unitCount < minUnits then
				local unitsToMin = minUnits - unitCount
				local minUnitComposition = GetRandomUnitsFromDefListByCount(unitsToMin,selectedUnitDefList,multiRandomise)
				typeComposition = AddUnitLists({minUnitComposition,typeComposition})
			end
		end
		--Spring.Utilities.TableEcho(typeComposition)
		for index, value in ipairs(typeComposition) do
			value.wreckChance = wreckChance
		end
		returnComposition = AddUnitLists({returnComposition,typeComposition})
	end
	return returnComposition
end

-- { { unitDefName = "vehriot",count = 2,wreckChance = 0.5,spacing = 64}}
-- alternate queue type {"vehriot" = 2, "cloakassault" = 3}
local function QueueListSpawn(unitDefParamTable,x,z,teamID,noGoZones) --TODO removed global deciders in favor of per unit things
	local spawnedUnits = {}
	local timeToGroundOffset = 5
	local firstSearchSuccess = true
	for index, data in pairs(unitDefParamTable) do -- { 1 ={ unitDefName = "vehriot",count = 2,wreckChance = 0.5,spacing = 64}}
		local unitDefName = nil
		local spawnCount = 1
		local spawnAsWreckChance = 0 --TODO hmm chance vs ratio... I suppose we can have wrecks, and normal units defined, but a chance covers that too
		local spacing = nil --if unset is randomised a little per spawn
		local dropPod = true
		local spawnPattern = "centered"
		if type(data) == "table" and data.unitDefName then
			unitDefName = data.unitDefName
			spawnCount = data.unitCount or 1
			spawnAsWreckChance = data.wreckChance or spawnAsWreckChance
			spacing = data.spacing or nil
			dropPod = data.dropPod or dropPod
			spawnPattern = data.spawnPattern or spawnPattern
			--Spring.Echo(unitDefName)
			--Spring.Echo(spawnCount)
		elseif type(data) == "number" then -- alternate queue type {"vehriot" = 2, "cloakassault" = 3}
			unitDefName = index
			spawnCount = data
			--Spring.Echo(unitDefName)
			--Spring.Echo(spawnCount)
		else
			Spring.Echo("type set on queued unit is wrong")
		end
		for i = 1, spawnCount, 1 do
			local unitID = nil
			--Spring.MarkerAddPoint(x, 0, z, "SearchStart")
			local localX,localZ,facing,sX,sZ,searchSuccess = GG.NoGoZonesGetValidSpawnPositionForUnit(UnitDefNames[unitDefName].id,{x,z},false,noGoZones)
			if spawnPattern == "centered" and firstSearchSuccess and searchSuccess then
				x,z = localX,localZ --TODO there is a different spawnpattern possible by using the following point for the next spawn start
				firstSearchSuccess = false
			end
			if searchSuccess then
				local localY = Spring.GetGroundHeight(localX, localZ) + Y_OFFSET 
				if dropPod then
					--GG.DropUnit(unitDefName, x, y, z, facing, teamID, useSetUnitVelocity, timeToGround, fallGravity, absSpawnHeight, absBrakeHeight, dyncommID, staticDyncommLevel, dynamicCommanderOnly)
					-- TODO mess with till its neat!
					unitID = GG.DropUnit(unitDefName,localX,localY,localZ,facing,teamID,true, 100 + timeToGroundOffset)
				else
					unitID = Spring.CreateUnit(unitDefName,localX,localY,localZ,facing,teamID)
				end
			else
				Spring.Echo("Search for spawnpoint failed")
			end
			if unitID then
				timeToGroundOffset = timeToGroundOffset + 5
				local localSpacing = spacing
				if not localSpacing then
					localSpacing = math.random (SPACING_MIN,SPACING_MAX)
				end
				noGoZones = GG.NoGoZonesAddNoGoZone(localX,localZ,math.max(sX, sZ)+localSpacing,noGoZones)
				if spawnAsWreckChance == 1 or spawnAsWreckChance > math.random() then
					Spring.CreateUnitWreck(unitID)
					--TODO for factories this causes a looping error in the factory flattening gadget until another factory is placed. Seems to be harmless, but is best handled still
					Spring.DestroyUnit(unitID,false,true,nil,true)
				else
					spawnedUnits[unitID] = true
				end
			else
				Spring.echo("Failed to Spawn")
			end
		end
	end
	return spawnedUnits, noGoZones
end

--[[
example comp building func
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
    elseif (budget < 2000) then
        return compositionType.mediumCost[math.random(#compositionType.mediumCost)]
    elseif (budget < 7500) then
        return compositionType.highCost[math.random(#compositionType.highCost)]
    elseif (budget >= 7500) then
        return compositionType.ludicrousCost[math.random(#compositionType.ludicrousCost)]
    end
    return {assault = 1}
end
]]

-- TODO remove or keep functions that show off how stuff works?
local function spawningTest()
	local spawnList = {}
	-- For Cost test
	local riot = GetRandomUnitsFromDefListForCost(2000,classGroupings.riot)
	-- for cost test, with multirandom
	local assault = GetRandomUnitsFromDefListForCost(2000,classGroupings.assault,true)
	
	-- count test
	local raider = GetRandomUnitsFromDefListByCount(3,classGroupings.raider)
	-- count test, with multirandom
	local skirm = GetRandomUnitsFromDefListByCount(3,classGroupings.skirm,true)
	
	-- direct insert test
	local dante = {striderdante = 1,athena = 2}
	-- complex direct insert test
	local aa = {
		{unitDefName = [[vehaa]], unitCount = 3, wreckChance = 0.5, spacing = 1000}, -- spacing accounts for future spawns, so order does matter sorta
		{unitDefName = [[spideraa]], unitCount = 3, wreckChance = 1, spacing = 1}
	}
	spawnList = GG.UnitSpawnerAddUnitLists({raider,riot,skirm,assault,dante,aa})

	--GG.UnitSpawnerQueueListSpawn(spawnList,math.random(1,mapSizeX),math.random(1,mapSizeZ),GaiaTeamID)
	GG.UnitSpawnerQueueListSpawn(spawnList,math.random(1,mapSizeX),math.random(1,mapSizeZ),GaiaTeamID)
	
	--mass editing test
	for index, value in ipairs(spawnList) do
		value.wreckChance = 1
	end
	
	GG.UnitSpawnerQueueListSpawn(spawnList,math.random(1,mapSizeX),math.random(1,mapSizeZ),GaiaTeamID)
end

local function CompositionBuilderTest()
	local spawnList = GG.UnitSpawnerCompositionBuilder(
	1800,
		{
			--{classGroup = "ecoLight", budgetFraction = 0, minUnits = 2, multiRandomise = true, wreckChance = 1},
			assault = 1,
			skirm = 1,
			turretLight = 1,
			--energypylon = 1
		},{"baseGame","extraUnits"},{"veh","bot","hover"}
	)
	local x,z = math.random(1,mapSizeX),math.random(1,mapSizeZ)
	GG.UnitSpawnerQueueListSpawn(spawnList,x,z,GaiaTeamID)
	Spring.MarkerAddPoint(x, 0, z, "TEST!")
end

function gadget:GameStart()
	Y_OFFSET = 20 -- The offset seems in flavour for drops, though is silly for pregame wrecks and structures
	
	--local test = GetUnitDefListByGroupSectionAndMoveType(taggedUnitDefNames,{"skirm"},{"baseGame","extraUnits"})
	--Spring.Utilities.TableEcho(test)
	
	--local staticUnits, movetypeDefID, movetypes = VFS.Include("LuaRules/Configs/CAI/unitMovetype.lua")
	--Spring.Utilities.TableEcho(movetypeDefID)
	
	--Spring.Utilities.TableEcho(taggedUnitDefNames)
	--Spring.Echo("spawningTest")
	--spawningTest()
	--Spring.Echo("compositionTest")
	--CompositionBuilderTest()
	
end

GG.UnitSpawnerAddUnitLists = AddUnitLists
--GG.UnitSpawnerGetGroupCompositionByBudgetAndType = GetGroupCompositionByBudgetAndType
GG.GetRandomUnitsFromDefListForCost = GetRandomUnitsFromDefListForCost
GG.UnitSpawnerGetRandomUnitsFromDefListByCount = GetRandomUnitsFromDefListByCount
GG.UnitSpawnerCompositionBuilder = CompositionBuilder
GG.UnitSpawnerQueueListSpawn = QueueListSpawn