--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function gadget:GetInfo()
	return {
		name      = "Reinforcement Drops",
		desc      = "Implements Periodic Reinforcement Drops",
		author    = "Stiofan",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local modOptions = Spring.GetModOptions()
local GaiaTeamID     = Spring.GetGaiaTeamID()
local GaiaAllyTeamID = select(6, Spring.GetTeamInfo(GaiaTeamID, false))
local allCompositions = VFS.Include("LuaRules/Configs/unit_compositions.lua")
local staticCompositions = allCompositions.staticCompositions
local mobileCompositions = allCompositions.mobileCompositions
local teamSpawnPosition = {}
    
local reinforceInput = tonumber(modOptions.reinforce_drop) or 0
local gaiaReinforcements = tonumber(modOptions.reinforce_drop_gaia) or 0
local reinforceBudget =  tonumber(modOptions.reinforce_drop_base) or 0
local reinforceBudgetGrowth = tonumber(modOptions.reinforce_drop_growth) or 300
local reinforceGaiaMult = tonumber(modOptions.reinforce_drop_gaia_mult) or 1

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
    return {assaults = 1}
end

local function TeamReinforcements(budget)
    local UnitTypeAndRatios = GetGroupCompositionByBudgetAndType(budget)
    local unitComposition = GG.UnitSpawnerCompositionBuilder(budget,UnitTypeAndRatios)
    --[[
    Spring.Echo("ReinforceCompUnits")
    for key, value in pairs(unitComposition) do
        Spring.Echo(value.unitDefName .." = "..value.unitCount)
    end
    ]]
    for teamID, position in pairs(teamSpawnPosition) do
        --Spring.Echo(teamID)
        local x,z = position[1],position[2]
        GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,teamID)
    end
end

--TODO improve the spawning to prefer buildings, then mid
local function GaiaReinforcements(budget)
    local unitComposition = GG.UnitSpawnerCompositionBuilder(budget,GetGroupCompositionByBudgetAndType(budget))
    --[[
    Spring.Echo("GaiaCompUnits")
    for key, value in pairs(unitComposition) do
        Spring.Echo(value.unitDefName .." = "..value.unitCount)
    end
    ]]
    local gaiaUnits = Spring.GetTeamUnits(GaiaTeamID)
    local gaiaBuildings = {}
    if gaiaUnits and #gaiaUnits > 0 then
        for index, unitID in ipairs(gaiaUnits) do
            local unitSpeed = UnitDefs[Spring.GetUnitDefID(unitID)].speed
            if unitSpeed or unitSpeed == 0 then
                gaiaBuildings[unitID] = true
            end
        end
        local unitToSpawnOn = gaiaUnits[math.random(1,#gaiaUnits)]
        if gaiaBuildings and #gaiaBuildings > 0 then -- we prefer buildings to spawn on
            unitToSpawnOn = gaiaUnits[math.random(1,#gaiaBuildings)]
            local x,y,z = Spring.GetUnitBasePosition(unitToSpawnOn)
            -- Sit and wait when spawned on allies
            GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID)
            return
        end
        -- Lets not spawn on moving units
        --local x,y,z = Spring.GetUnitBasePosition(unitToSpawnOn)
        -- Sit and wait when spawned on allies
        --GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID)
        -- return
    end
    -- move on your own
    local unitIDs, noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID)
    for unitID, _ in pairs(unitIDs) do
        GG.Zombies.SetZombieBehavior(unitID)
    end
end

function gadget:GameFrame(f)
    
    if f == 1 then
        for _, unitID in ipairs(Spring.GetAllUnits()) do
            local teamID = Spring.GetUnitTeam(unitID)
            if teamID ~= GaiaTeamID then
                local x,y,z = Spring.GetUnitBasePosition(unitID)
                teamSpawnPosition[teamID] = {x,z}
            end
        end
	end
    
	if f%1800 == 1 and f ~= 1 then
        if reinforceBudget > 0 then
            if reinforceInput ~= 0 then
                TeamReinforcements(reinforceBudget)
            end
            if gaiaReinforcements ~= 0 then
                GaiaReinforcements(reinforceBudget*reinforceGaiaMult)
            end
        end
        reinforceBudget = reinforceBudget + reinforceBudgetGrowth
	end
end