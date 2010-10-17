include("LuaRules/Configs/CAI/buildtasks.lua")
include("LuaRules/Configs/CAI/unitarrays.lua")
include("LuaRules/Configs/CAI/brains.lua")
include("LuaRules/Configs/CAI/battlegroupcondition.lua")
include("LuaRules/Configs/CAI/configCoordinator.lua")
include("LuaRules/Configs/CAI/strategies.lua")

--general vars
sosRadius = 1200		-- max distance for calls for aid when attacked
prioritySosRadius = 3000		-- max distance for calls for aid when attacked
sosTime = 150	--gameframes before next SOS call is allowed for same unit
heatSquareMinSize = 512
stuckTimerUntilDisband = 1800

waypointTester = UnitDefNames['cafus'].id


conJobNames = {
	["factory"] = "factory ",
	["reclaim"] = "reclaim ",
	["mex"] 	= "mex    ",
	["defence"] = "defence  ",
	["energy"]	= "energy  ",
}

factoryJobNames = {
	[1] = "con    ",
	[2] = "scout  ",
	[3] = "raider ",
	[4] = "arty   ",
	[5] = "assault",
	[6] = "skirm  ",
	[7] = "riot   ",
	[8] = "AA     ",
}

airFactoryJobNames = {
	[1] = "con    ",
	[2] = "scout  ",
	[3] = "fighter",
	[4] = "bomber ",
	[5] = "gunship",
}
	
	