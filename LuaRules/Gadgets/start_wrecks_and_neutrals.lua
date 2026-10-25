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

local allUnitGroups = VFS.Include("LuaRules/Configs/unit_class_groupings.lua")
local noGoZones = GG.NoGoZonesGetMexAndGeoNoGoZones()

local startingWreckCount = tonumber(modOptions.starting_wrecks_count) or 0
local startingWreckValue = tonumber(modOptions.starting_wrecks_value) or 1000

local startingNeutralCount = tonumber(modOptions.starting_neutral_count) or 0
local startingNeutralValue = tonumber(modOptions.starting_neutral_value) or 1000
local startingNeutralMobileChance = tonumber(modOptions.starting_neutral_mobile) or 0

local CENTER_CAMP_MULT = 3


-- TODO this could go into a config file
--TODO could also be a modoption input buuuut I am not featurecreaping it further juust yet. it proves the concepts and functionality of the tools
-- 
local mobileCamps = {
	{
		ecoLight = 1,
		turretsMedium = 0.1,
		raiders = 2,
		scouts = 3,
	},
	{
		ecoLight = 1,
		turretsAALight = 0.1,
		riots = 2,
		skirmishers = 2,
	},
	{
		ecoLight = 1,
		turretsLight = 0.1,
		assaults = 2,
		riots = 1,
	},
	{
		ecoLight = 1,
		turretsLight = 0.1,
		assaults = 1,
		gunships = 1,
	}
}

local staticCamps = {
	{
		pwSupport = 0.1,
		ecoLight = 0.5,
		ecoSupport = 0.1,
		turretsMedium = 1,
		turretsAALight = 0.1,
		turretsLight = 1
	},
	{
		pwGreebles = 1,
		ecoLight = 0.5,
		ecoSupport = 0.1,
		turretsMedium = 1,
		turretsAALight = 1,
		turretsLight = 1
	},
	{
		pwSupport = 0.1,
		pwGreebles = 1,
		ecoSupport = 0.1,
		turretsMedium = 1,
		turretsAALight = 1,
		turretsLight = 1
	},
	{
		factories = 0.1,
		pwGreebles = 1,
		ecoSupport = 0.1,
		turretsMedium = 1,
		turretsAALight = 1,
		turretsLight = 1
	}
}
local largeCamp = {
	pwSupport = 1,
	pwGreebles = 1,
	ecoSupport = 1,
	pwDefence = 1,
	turretsMedium = 1,
	turretsAALight = 1,
	turretsLight = 1,
	artillery = 1,
}

-- TODO remove or keep functions that show off how stuff works?
local function spawningTest()
	
	local spawnList = {}
	
	local riots = GG.UnitSpawnerGetRandomUnitsFromListForCost(1000,allUnitGroups.riots)
	local skirmishers = GG.UnitSpawnerGetRandomUnitsFromListForCost(1000,allUnitGroups.skirmishers)
	
	spawnList = GG.UnitSpawnerAddUnitLists({riots,skirmishers})
	
	GG.UnitSpawnerQueueListSpawn(spawnList,math.random(1,mapSizeX),math.random(1,mapSizeZ),GaiaTeamID,true)
	GG.UnitSpawnerQueueListSpawn(spawnList,math.random(1,mapSizeX),math.random(1,mapSizeZ),GaiaTeamID)
end

local function CompositionBuilderTest()
	local spawnList = GG.UnitSpawnerCompositionBuilder(
	1000,
		{
			--TODO expand so that multirandom and wreck chance is a per thing thing
			assaults = 1,
			skirmishers = 1,
			turretsLight = 1
		}
	)
	GG.UnitSpawnerQueueListSpawn(spawnList,math.random(1,mapSizeX),math.random(1,mapSizeZ),GaiaTeamID)
end

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

local function SpawnNeutralCamps(campCount,campValue,mobileChance)
	local unitIDs
	local unitComposition
	for i = 1, campCount/2, 1 do
		if mobileChance > math.random() then
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,mobileCamps[math.random(1,#mobileCamps)], true)
		else
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,staticCamps[math.random(1,#staticCamps)], true)
		end
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
		end
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID, false,nil,math.random(10,64),noGoZones)
		Spring.MarkerAddPoint(x, 0, z, "Reports of Remnants")
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x2,z2,GaiaTeamID, false,nil,math.random(10,64),noGoZones)
		Spring.MarkerAddPoint(x2, 0, z2, "Reports of Remnants")
	end
	--uneven number results in big map center camp :o 
	if campCount % 2 == 1 then
		unitComposition = GG.UnitSpawnerCompositionBuilder(campValue*CENTER_CAMP_MULT,largeCamp, true)
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID,false,nil,math.random(10,64),noGoZones)
		Spring.MarkerAddPoint(mapSizeX/2, 0, mapSizeZ/2, "Reports of large Remnants")
	end
end

-- duplicate of spawning neutral camps without the startbox check
local function SpawnWreckClump(campCount,campValue)
	local unitIDs
	local unitComposition
	
	for i = 1, campCount/2, 1 do
		if 0.5 > math.random(0,1) then
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,mobileCamps[math.random(1,#mobileCamps)], true)
		else
			unitComposition = GG.UnitSpawnerCompositionBuilder(campValue,staticCamps[math.random(1,#staticCamps)], true)
		end
		--we mirror for an attempt at fairness.
		local x,z = math.random(0,mapSizeX),math.random(mapSizeZ)
		local x2,z2 = mapSizeX-x,mapSizeZ-z
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID, true,nil,math.random(0,128),noGoZones)
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,x2,z2,GaiaTeamID, true,nil,math.random(0,128),noGoZones)
	end
	--uneven number results in big map center field
	if campCount % 2 == 1 then
		unitComposition = GG.UnitSpawnerCompositionBuilder(campValue*CENTER_CAMP_MULT,largeCamp, true)
		unitIDs,noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID, true,nil,math.random(10,64),noGoZones)
	end
end


function gadget:Initialize()

end

function gadget:GameStart()
	maxStartboxcount = Spring.GetGameRulesParam("startbox_max_n")
	Spring.Echo(maxStartboxcount)
	
	if startingNeutralCount and startingNeutralValue and startingNeutralCount >= 0 and startingNeutralValue >= 0 then
		SpawnNeutralCamps(startingNeutralCount,startingNeutralValue,startingNeutralMobileChance)
	end
	if startingWreckCount and startingWreckValue and startingWreckCount >= 0 and startingWreckValue >= 0 then
		SpawnWreckClump(startingWreckCount,startingWreckValue)
	end
	
end