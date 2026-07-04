local CMD = CMD
local SUC = Spring.Utilities.CMD

local stateData = {
	[SUC.WANT_ONOFF] = 2,
	[CMD.IDLEMODE] = 2,
	[SUC.AP_FLY_STATE] = 2,
	[SUC.CLOAK_SHIELD] = 2,
	[SUC.DONT_FIRE_AT_RADAR] = 2,
	[SUC.FACTORY_GUARD] = 2,
	[SUC.WANT_CLOAK] = 2,
	[SUC.PRIORITY] = 3,
	[SUC.TOGGLE_DRONES] = 2,
	[SUC.UNIT_FLOAT_STATE] = 3,
	[SUC.AIR_STRAFE] = 2,
	[CMD.FIRE_STATE] = 3,
	[CMD.MOVE_STATE] = 3,
	[SUC.PUSH_PULL] = 2,
	[SUC.MISC_PRIORITY] = 3,
	[SUC.GOO_GATHER] = 3,
	[CMD.REPEAT] = 2,
	[SUC.RETREAT] = 4,
	[CMD.TRAJECTORY] = 2,
	[SUC.DISABLE_ATTACK] = 2,
	[SUC.UNIT_BOMBER_DIVE_STATE] = 4,
	--[SUC.AUTO_CALL_TRANSPORT] = 2, -- Handled entirely in luaUI so not included here.
	--[SUC.GLOBAL_BUILD] = 2, -- Handled entirely in luaUI so not included here.
	[SUC.UNIT_KILL_SUBORDINATES] = 2,
	[SUC.PREVENT_OVERKILL] = 5,
	[SUC.PREVENT_BAIT] = 5,
	[SUC.FIRE_AT_SHIELD] = 2,
	[SUC.FIRE_TOWARDS_ENEMY] = 2,
	--[SUC.SELECTION_RANK] = 2, -- Handled entirely in luaUI so not included here.
	[SUC.UNIT_AI] = 2,
}

local specialHandling = {
	[SUC.RETREAT] = function (state, options)
		if options.right then
			state = 0
		elseif state == 0 then --note: this means that to set "Retreat Off" (state = 0) you need to use the "right" modifier, whether the command is given by the player using an ui button or by Lua
			state = 1
		end
		return state
	end,
}

local gadgetReverse = {
	[SUC.PRIORITY] = true,
	[SUC.UNIT_FLOAT_STATE] = true,
	[SUC.MISC_PRIORITY] = true,
	[SUC.UNIT_BOMBER_DIVE_STATE] = true,
	[SUC.PREVENT_BAIT] = true,
	[SUC.PREVENT_OVERKILL] = true,
	[SUC.GOO_GATHER] = true,
}

return stateData, gadgetReverse, specialHandling
