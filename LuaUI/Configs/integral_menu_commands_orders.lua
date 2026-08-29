VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Order and State Panel Positions

-- Commands are placed in their position, with conflicts resolved by pushng those
-- with less priority (higher number = less priority) along the positions if
-- two or more commands want the same position.
-- The command panel is propagated left to right, top to bottom.
-- The state panel is propagate top to bottom, right to left.
-- * States can use posSimple to set a different position when the panel is in
--   four-row mode.
-- * Missing commands have {pos = 1, priority = 100}

local cmdPosDef = {
	-- Commands
	[CMD.STOP]          = {pos = 1, priority = 1},
	[CMD.FIGHT]         = {pos = 1, priority = 2},
	[CMD_RAW_MOVE]      = {pos = 1, priority = 3},
	[CMD.PATROL]        = {pos = 1, priority = 4},
	[CMD.ATTACK]        = {pos = 1, priority = 5},
	[CMD_JUMP]          = {pos = 1, priority = 6},
	[CMD_AREA_GUARD]    = {pos = 1, priority = 10},
	[CMD.AREA_ATTACK]   = {pos = 1, priority = 11},
	
	[CMD_UPGRADE_UNIT]  = {pos = 7, priority = -8},
	[CMD_UPGRADE_STOP]  = {pos = 7, priority = -7},
	[CMD_MORPH]         = {pos = 7, priority = -6},
	
	[CMD_STOP_NEWTON_FIREZONE] = {pos = 7, priority = -4},
	[CMD_NEWTON_FIREZONE]      = {pos = 7, priority = -3},
	
	[CMD.MANUALFIRE]      = {pos = 7, priority = 0.1},
	[CMD_AIR_MANUALFIRE]  = {pos = 7, priority = 0.12},
	[CMD_PLACE_BEACON]    = {pos = 7, priority = 0.2},
	[CMD_ONECLICK_WEAPON] = {pos = 7, priority = 0.24},
	[CMD.STOCKPILE]       = {pos = 7, priority = 0.25},
	[CMD_ABANDON_PW]      = {pos = 7, priority = 0.3},
	[CMD_GBCANCEL]        = {pos = 7, priority = 0.4},
	[CMD_STOP_PRODUCTION] = {pos = 7, priority = 0.7},
	
	[CMD_BUILD]         = {pos = 7, priority = 0.8},
	[CMD_AREA_MEX]      = {pos = 7, priority = 1},
	[CMD.REPAIR]        = {pos = 7, priority = 2},
	[CMD.RECLAIM]       = {pos = 7, priority = 3},
	[CMD.RESURRECT]     = {pos = 7, priority = 4},
	[CMD.WAIT]          = {pos = 7, priority = 5},
	[CMD_FIND_PAD]      = {pos = 7, priority = 6},
	
	[CMD.LOAD_UNITS]    = {pos = 7, priority = 7},
	[CMD.UNLOAD_UNITS]  = {pos = 7, priority = 8},
	[CMD_RECALL_DRONES] = {pos = 7, priority = 10},
	
	[CMD_FIELD_FAC_SELECT]       = {pos = 13, priority = 0.6},
	[CMD_MISC_BUILD]             = {pos = 13, priority = 0.7},
	[CMD_AREA_TERRA_MEX]         = {pos = 13, priority = 1},
	[CMD_UNIT_SET_TARGET_CIRCLE] = {pos = 13, priority = 2},
	[CMD_UNIT_CANCEL_TARGET]     = {pos = 13, priority = 3},
	[CMD_EMBARK]                 = {pos = 13, priority = 5},
	[CMD_DISEMBARK]              = {pos = 13, priority = 6},
	[CMD_EXCLUDE_PAD]            = {pos = 13, priority = 7},
	[CMD_IMMEDIATETAKEOFF]       = {pos = 13, priority = 8},

	-- States
	[CMD.REPEAT]              = {pos = 1, priority = 1},
	[CMD_RETREAT]             = {pos = 1, priority = 2},
	
	[CMD.MOVE_STATE]          = {pos = 6, posSimple = 5, priority = 1},
	[CMD.FIRE_STATE]          = {pos = 6, posSimple = 5, priority = 2},
	[CMD_FACTORY_GUARD]       = {pos = 6, posSimple = 5, priority = 3},
	
	[CMD_SELECTION_RANK]      = {pos = 6, posSimple = 1, priority = 1.5},
	
	[CMD_PRIORITY]            = {pos = 1, priority = 10},
	[CMD_MISC_PRIORITY]       = {pos = 1, priority = 11},
	[CMD_CLOAK_SHIELD]        = {pos = 1, priority = 11.5},
	[CMD_WANT_CLOAK]          = {pos = 1, priority = 11.6},
	[CMD_WANT_ONOFF]          = {pos = 1, priority = 13},
	[CMD_PREVENT_BAIT]        = {pos = 1, priority = 13.1},
	[CMD_PREVENT_OVERKILL]    = {pos = 1, priority = 13.2},
	[CMD_FIRE_TOWARDS_ENEMY]  = {pos = 1, priority = 13.25},
	[CMD_FIRE_AT_SHIELD]      = {pos = 1, priority = 13.3},
	[CMD.TRAJECTORY]          = {pos = 1, priority = 14},
	[CMD_UNIT_FLOAT_STATE]    = {pos = 1, priority = 15},
	[CMD_TOGGLE_DRONES]       = {pos = 1, priority = 16},
	[CMD_PUSH_PULL]           = {pos = 1, priority = 17},
	[CMD.IDLEMODE]            = {pos = 1, priority = 18},
	[CMD_AP_FLY_STATE]        = {pos = 1, priority = 19},
	[CMD_AUTO_CALL_TRANSPORT] = {pos = 1, priority = 21},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local modCommands = VFS.Include("LuaRules/Configs/modCommandsDefs.lua")
if modCommands then
	for i = 1, #modCommands do
		local cmd = modCommands[i]
		cmdPosDef[cmd.cmdID] = cmd.position
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return cmdPosDef

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
