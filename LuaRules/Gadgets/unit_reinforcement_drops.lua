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
		layer     = math.huge, -- (I dont know when would be appropriate)
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
local modOptions = Spring.GetModOptions()
local GaiaTeamID     = Spring.GetGaiaTeamID()
local GaiaAllyTeamID = select(6, Spring.GetTeamInfo(GaiaTeamID, false))
local allUnitGroups = VFS.Include("LuaRules/Configs/unit_class_groupings.lua")
local teamSpawnPosition = {}
    
local reinforceInput = tonumber(modOptions.reinforce_drop) or 0
local gaiaReinforcements = tonumber(modOptions.reinforce_drop_gaia) or 0
local reinforceBudget =  tonumber(modOptions.reinforce_drop_base) or 0
local reinforceBudgetGrowth = tonumber(modOptions.reinforce_drop_growth) or 300
local reinforceGaiaMult = tonumber(modOptions.reinforce_drop_gaia_mult) or 1

local tinyUnitComps = {
    {
		scouts = 1,
	},
    {
		raiders = 1,
	},
	{
		riots = 1,
	},
	{
        bombs = 1
	},
    {
        assaults = 1
    },
    {
        raiders = 1,
        drones = 0.3
    }
}

local smallUnitComps = {
    {
        raiders = 1,
        skirmishers = 1
	},
    {
        riots = 1,
        skirmishers = 1
	},
    {
        riots = 1,
        skirmishers = 1
	},
    {
        assaults = 1,
        bombs = 0.2,
	},
    {
        assaults = 1
    },
    {
        assaults = 1,
        skirmishers = 1,
    },
    {
        drones = 0.3,
        riots = 1,
    },
}

local mediumUnitComps = {
    {
        constructors = 0.1,
        assaults = 1,
        skirmishers = 1,
    },
    {
        assaults = 1,
        riots = 1,
    },
    {
        assaults = 1,
        artillery = 1,
        scouts = 0.1,
    },
    {
        raiders = 1,
        artillery = 1,
    },
    {
        antiSub = 1,
        artillery = 1,
    },
    {
        gunships = 1,
    },
    {
        stridersDemi = 1,
        antiAir = 0.01
    },
    {
        riots = 1,
        transports = 0.5,
    },
}
local largeUnitComps = {
    {
        assaults = 1,
        artillery = 1,
        raiders = 0.5,
    },
    {
        stridersDemi = 1,
        raiders = 0.5,
    },
    {
        stridersDemi = 1,
        antiSub = 1,
    },
    {
        aerialAA = 1,
        bombers = 1
    },
    {
        stridersMedium = 1,
        support = 0.0001,
    },
    {
        stridersDemi = 1,
        assaults = 1
    },
    {
        antiHeavy = 1
    }
}
local hugeUnitComps = {
    {
        stridersDemi = 1,
        bombers = 1
    },
    {
        stridersMedium = 1,
        assaults = 1
    },
    {
        stridersMedium = 1,
        support = 0.001,
    },
    {
        stridersDemi = 1,
        aerialAA = 1,
    },
    {
        stridersHeavy = 1,
    }
}


local function GetUnitTypeAndRatiosForBudget(budget)
    if not budget then
        budget = 300
    end
    if not (budget > 700) then
        Spring.Echo("tinyComp")
        return tinyUnitComps[math.random(#tinyUnitComps)]
    end
    if not (budget > 1500) then
        Spring.Echo("smallComp")
        return smallUnitComps[math.random(#smallUnitComps)]
    end
    if not (budget > 3500) then
        Spring.Echo("mediumComp")
        return mediumUnitComps[math.random(#mediumUnitComps)]
    end
    if not (budget > 7500) then
         Spring.Echo("largeComp")
        return largeUnitComps[math.random(#largeUnitComps)]
    end
    if not (budget > 13000) then
         Spring.Echo("hugeComp")
        return hugeUnitComps[math.random(#hugeUnitComps)]
    end
    return {assaults = 1}
end


local function TeamReinforcements(budget)
    local UnitTypeAndRatios = GetUnitTypeAndRatiosForBudget(budget)
    --[[for key, value in pairs(UnitTypeAndRatios) do
        Spring.Echo(key)
        Spring.Echo(value)
    end --]]
    local unitComposition = GG.UnitSpawnerCompositionBuilder(budget,UnitTypeAndRatios, false)
    --[[for key, value in pairs(unitComposition) do
        Spring.Echo(key)
        Spring.Echo(value)
    end --]]
    for teamID, position in pairs(teamSpawnPosition) do
        Spring.Echo(teamID)
        local x,z = position[1],position[2]
        GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,teamID)
    end
end

--TODO improve the spawning to prefer buildings, then mid
local function GaiaReinforcements(budget)
    local unitComposition = GG.UnitSpawnerCompositionBuilder(budget,GetUnitTypeAndRatiosForBudget(budget), true)
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
        end
        local x,y,z = Spring.GetUnitBasePosition(unitToSpawnOn)
        -- Sit and wait when spawned on allies
        GG.UnitSpawnerQueueListSpawn(unitComposition,x,z,GaiaTeamID)
    else
        -- move on your own
        local unitIDs, noGoZones = GG.UnitSpawnerQueueListSpawn(unitComposition,mapSizeX/2,mapSizeZ/2,GaiaTeamID)
        for unitID, _ in pairs(unitIDs) do
            GG.Zombies.SetZombieBehavior(unitID)
        end
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