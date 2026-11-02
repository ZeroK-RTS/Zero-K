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
		layer     = math.huge, -- (I dont know when would be appropriate)
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modOptions = Spring.GetModOptions()
local GaiaTeamID = Spring.GetGaiaTeamID()
local maxStartboxcount = Spring.GetGameRulesParam("startbox_max_n") or 2 -- TODO this seems to have some issue. Startboxjutsu is not good enough
local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ

local allCompositions = VFS.Include("LuaRules/Configs/unit_compositions.lua")
local mobileCompositions = allCompositions.mobileCompositions
local staticCompositions = allCompositions.staticCompositions
local mixedCompositions = allCompositions.mixedCompositions
local noGoZones = GG.NoGoZonesGetMexAndGeoNoGoZones()

local startingWreckCount = tonumber(modOptions.starting_wrecks_count) or 0
local startingWreckValue = tonumber(modOptions.starting_wrecks_value) or 1000

local startingNeutralCount = tonumber(modOptions.starting_neutral_count) or 0
local startingNeutralValue = tonumber(modOptions.starting_neutral_value) or 1000
local startingNeutralMobileChance = tonumber(modOptions.starting_neutral_mobile) or 0

local CENTER_CAMP_MULT = 3

local function CheckStartboxOverlap(x,z)
	local overlaps = false
	for i = 0, maxStartboxcount, 1 do
		if GG.CheckStartbox(i,x,z) then
			--Spring.MarkerAddPoint(x, 0, z, "Overlap?")
			overlaps = true
		end
	end
	return overlaps
end

local function GetMixedComposition(staticValue,mobileValue)
	local mobileComposition = GG.UnitSpawnerGetGroupCompositionByBudgetAndType(mobileValue,mobileCompositions)
	local mobileUnitComposition = GG.UnitSpawnerCompositionBuilder(mobileValue,mobileComposition)
	local staticComposition = GG.UnitSpawnerGetGroupCompositionByBudgetAndType(staticValue,staticCompositions)
	local staticUnitComposition = GG.UnitSpawnerCompositionBuilder(staticValue,staticComposition)

	return GG.UnitSpawnerAddUnitLists({mobileUnitComposition,staticUnitComposition})
end

local function SpawnNeutralCamps(campCount,campValue,mobileRatio)
	local unitIDs
	for i = 1, campCount/2, 1 do
		local unitComposition
		if mobileRatio == 1 then
			local mobileComposition = GG.UnitSpawnerGetGroupCompositionByBudgetAndType(campValue,mobileCompositions)
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,mobileComposition)
		elseif mobileRatio == 0 then
			local staticComposition = GG.UnitSpawnerGetGroupCompositionByBudgetAndType(campValue,staticCompositions)
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,staticComposition)
		else
			local mobileBudget = campValue*mobileRatio
			local staticBudget = campValue - mobileBudget
			unitComposition = GetMixedComposition(staticBudget,mobileBudget)
		end
		--TODO neutral devastation modoption, chance or ratio of neutrals to start dead
		--for index, value in ipairs(unitComposition) do
			--value.wreckChance = math.random(0,1)
		--end
		
		--TODO my map and startbox jutsu is not as strong, but also not too integral to show off the underlying stuff. small startboxes get close spawns
		--we mirror for an attempt at fairness.
		local x,z = math.random(0,mapSizeX),math.random(mapSizeZ)
		local x2,z2 = mapSizeX-x,mapSizeZ-z
		local iteration = 0
		while CheckStartboxOverlap(x,z) and CheckStartboxOverlap(x2,z2) do
			x,z = math.random(0,mapSizeX),math.random(0,mapSizeZ)
			x2,z2 = mapSizeX-x,mapSizeZ-z
			if iteration > 10 then
				x,z = mapSizeX/2,mapSizeZ/2
				x2,z2 = mapSizeX-x,mapSizeZ-z
				break
			end
			iteration = iteration +1
		end
		Spring.Echo("Start neutrals")
		for key, value in pairs(unitComposition) do
			Spring.Echo(value.unitDefName .." = "..value.unitCount)
		end
		
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID,noGoZones)
		Spring.MarkerAddPoint(x, 0, z, "Reports of Remnants")
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x2,z2,GaiaTeamID,noGoZones)
		Spring.MarkerAddPoint(x2, 0, z2, "Reports of Remnants")
	end
	--uneven number results in big map center camp :o 
	if campCount % 2 == 1 then
		local unitComposition
		campValue = campValue * CENTER_CAMP_MULT
		if mobileRatio == 1 then
			local mobileComposition = GG.UnitSpawnerGetGroupCompositionByBudgetAndType(campValue,mobileCompositions)
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,mobileComposition)
		elseif mobileRatio == 0 then
			local staticComposition = GG.UnitSpawnerGetGroupCompositionByBudgetAndType(campValue,staticCompositions)
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,staticComposition)
		else
			local mobileBudget = campValue*mobileRatio
			local staticBudget = campValue - mobileBudget
			unitComposition = GetMixedComposition(staticBudget,mobileBudget)
		end
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID,noGoZones)
		Spring.MarkerAddPoint(mapSizeX/2, 0, mapSizeZ/2, "Reports of large Remnants")
	end
end

-- duplicate of spawning neutral camps without the startbox check
local function SpawnWreckClump(campCount,campValue)
	local unitIDs
	local unitComposition
	local campValue = campValue * 2 -- to make value about equal to output wrecks, since we lose about 60%
	
	for i = 1, campCount/2, 1 do
		local mobileRatio = math.random()
		local mobileBudget = campValue*mobileRatio
		local staticBudget = campValue - mobileBudget
		Spring.Echo(mobileBudget)
		Spring.Echo(staticBudget)
		unitComposition = GetMixedComposition(staticBudget,mobileBudget)
		for index, value in ipairs(unitComposition) do
			value.wreckChance = 1
		end
		--we mirror for an attempt at fairness.
		local x,z = math.random(0,mapSizeX),math.random(mapSizeZ)
		local x2,z2 = mapSizeX-x,mapSizeZ-z
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID,noGoZones)
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x2,z2,GaiaTeamID,noGoZones)
	end
	--uneven number results in big map center field
	if campCount % 2 == 1 then
		local unitComposition
		campValue = campValue * CENTER_CAMP_MULT
		unitComposition = GetMixedComposition(campValue/2,campValue/2)
		for index, value in ipairs(unitComposition) do
			value.wreckChance = 1
		end
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID,noGoZones)
	end
end


function gadget:Initialize()

end

function gadget:GameStart()
	-- 512 is the size of a mapsize "unit"
	Spring.Echo(mapSizeX)
	Spring.Echo(mapSizeZ)
	
	maxStartboxcount = Spring.GetGameRulesParam("startbox_max_n")

	if startingNeutralCount and startingNeutralValue and startingNeutralCount >= 0 and startingNeutralValue >= 0 then
		SpawnNeutralCamps(startingNeutralCount,startingNeutralValue,startingNeutralMobileChance)
	end
	if startingWreckCount and startingWreckValue and startingWreckCount >= 0 and startingWreckValue >= 0 then
		SpawnWreckClump(startingWreckCount,startingWreckValue)
	end
end