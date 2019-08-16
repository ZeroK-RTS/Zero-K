include("LuaRules/Configs/CAI/buildtasks.lua")
include("LuaRules/Configs/CAI/unitarrays.lua")
include("LuaRules/Configs/CAI/brains.lua")
include("LuaRules/Configs/CAI/battlegroupcondition.lua")
include("LuaRules/Configs/CAI/configCoordinator.lua")
include("LuaRules/Configs/CAI/strategies.lua")
include("LuaRules/Configs/CAI/accessory/targetReachableTester.lua")
include("LuaRules/Configs/CAI/accessory/no_stuck_in_factory.lua")

--general constants/vars
SOS_RADIUS = 1200		-- max distance for calls for aid when attacked
PRIORITY_SOS_RADIUS = 3000		-- max distance for calls for aid when attacked
SOS_TIME = 150	-- gameframes before next SOS call is allowed for same unit
HEATSQUARE_MIN_SIZE = 512
--stuckTimerUntilDisband = 1800	-- unused
RADIUS_CHECK_POS_FOR_ENEMY_DEF = 650	-- radius to check for enemy defences in range of a position
CACHE_POS_THREATENED_TTL = 1800	-- how long to keep the cache
MIN_RANGE_TO_THREATEN_SPOT = 250	-- don't let any random flea be considered a threat

waypointTester = UnitDefNames['energysingu'].id


conJobNames = {
	["factory"] = "factory",
	["reclaim"] = "reclaim",
	["mex"] 	= "mex",
	["defence"] = "defence",
	["energy"]	= "energy",
}

factoryJobNames = {
	[1] = "con",
	[2] = "scout",
	[3] = "raider",
	[4] = "arty",
	[5] = "assault",
	[6] = "skirm",
	[7] = "riot",
	[8] = "AA",
}

airFactoryJobNames = {
	[1] = "con",
	[2] = "scout",
	[3] = "fighter",
	[4] = "bomber",
	[5] = "gunship",
}
	
	
