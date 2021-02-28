VFS.Include("LuaRules/Configs/customcmds.h.lua")

local stateData = {
	[CMD_WANT_ONOFF] = 2,
	[CMD.IDLEMODE] = 2,
	[CMD_AP_FLY_STATE] = 2,
	[CMD_CLOAK_SHIELD] = 2,
	[CMD_DONT_FIRE_AT_RADAR] = 2,
	[CMD_FACTORY_GUARD] = 2,
	[CMD_WANT_CLOAK] = 2,
	[CMD_PRIORITY] = 3,
	[CMD_TOGGLE_DRONES] = 2,
	[CMD_UNIT_FLOAT_STATE] = 3,
	[CMD_AIR_STRAFE] = 2,
	[CMD.FIRE_STATE] = 3,
	[CMD.MOVE_STATE] = 3,
	[CMD_PUSH_PULL] = 2,
	[CMD_MISC_PRIORITY] = 3,
	[CMD_GOO_GATHER] = 3,
	[CMD.REPEAT] = 2,
	[CMD_RETREAT] = 4,
	[CMD.TRAJECTORY] = 2,
	[CMD_DISABLE_ATTACK] = 2,
	[CMD_UNIT_BOMBER_DIVE_STATE] = 4,
	--[CMD_AUTO_CALL_TRANSPORT] = 2, -- Handled entirely in luaUI so not included here.
	--[CMD_GLOBAL_BUILD] = 2, -- Handled entirely in luaUI so not included here.
	[CMD_UNIT_KILL_SUBORDINATES] = 2,
	[CMD_PREVENT_OVERKILL] = 2,
	[CMD_PREVENT_BAIT] = 5,
	[CMD_WARD_FIRE] = 2,
	--[CMD_SELECTION_RANK] = 2, -- Handled entirely in luaUI so not included here.
	[CMD_UNIT_AI] = 2,
}

local specialHandling = {
	[CMD_RETREAT] = function (state, options)
		if options.right then
			state = 0
		elseif state == 0 then --note: this means that to set "Retreat Off" (state = 0) you need to use the "right" modifier, whether the command is given by the player using an ui button or by Lua
			state = 1
		end
		return state
	end,
}

local gadgetReverse = {
	[CMD_PRIORITY] = true,
	[CMD_UNIT_FLOAT_STATE] = true,
	[CMD_MISC_PRIORITY] = true,
	[CMD_UNIT_BOMBER_DIVE_STATE] = true,
	[CMD_PREVENT_BAIT] = true,
	[CMD_GOO_GATHER] = true,
}

return stateData, gadgetReverse, specialHandling
