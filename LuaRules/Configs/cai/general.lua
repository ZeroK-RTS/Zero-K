include("LuaRules/Configs/CAI/buildtasks.lua")
include("LuaRules/Configs/CAI/unitarrays.lua")
include("LuaRules/Configs/CAI/brains.lua")
include("LuaRules/Configs/CAI/battlegroupcondition.lua")
include("LuaRules/Configs/CAI/configCoordinator.lua")
include("LuaRules/Configs/CAI/strategies.lua")

--general vars
sosRadius = 1200		-- max distance for calls for aid when attacked
sosTime = 150	--gameframes before next SOS call is allowed for same unit
heatSquareMinSize = 512
stuckTimerUntilDisband = 1800

waypointTester = UnitDefNames['cafus'].id
