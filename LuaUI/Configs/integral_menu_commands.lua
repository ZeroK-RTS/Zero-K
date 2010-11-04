local CMD_BUILD = 10010
local CMD_RAMP = 39734
local CMD_LEVEL = 39736
local CMD_RAISE = 39737
local CMD_SMOOTH = 39738
local CMD_RESTORE = 39739
local CMD_EMBARK = 31800
local CMD_DISEMBARK = 31801
local CMD_RETREAT_ZONE = 10001
local CMD_RETREAT =	10000
local CMD_PRIORITY=34220
local CMD_STEALTH = 32100
local CMD_UNIT_AI = 36214
local CMD_AREA_MEX = 10100
local CMD_CLOAK_SHIELD = 32101
local CMD_JUMP = 38521

local factories = {
	factorycloak = {order = 1},
	factoryshield = {order = 2},
	factoryveh = {order = 3},
	factoryhover = {order = 4},
	factoryspider = {order = 5},
	factoryjump = {order = 6},
	factorytank = {order = 7},
	factoryplane = {order = 8},
	factorygunship = {order = 9},
	corsy = {order = 10},
}

--Integral menu is NON-ROBUST
--all buildings (except facs) need a row or they won't appear!
--also if you put too many things into the same row, the overflow won't be displayed!
local econ = {
	cormex = {order = 1, row = 1},
	armsolar = {order = 2, row = 2},
	armwin = {order = 3, row = 2},
	armfus = {order = 4, row = 2},
	geo = {order = 5, row = 2},
	cafus = {order = 6, row = 2},
	armmstor = {order = 7, row = 3},
	armestor = {order = 8, row = 3},
	armnanotc = {order = 9, row = 3},
	armasp = {order = 10, row = 3},
}

local defense = {
	corrl = {order = 0, row = 1},
	corllt = {order = 1, row = 1},
	armdeva = {order = 2, row = 1},
	armartic = {order = 3, row = 1},
--	corgrav = {order = 4, row = 1},
	armpb = {order = 5, row = 1},
	corhlt = {order = 6, row = 1},
--	armanni = {order = 7, row = 1},

--	corrl = {order = 8, row = 2},
	corrazor = {order = 9, row = 2},
	missiletower = {order = 10, row = 2},
	armcir = {order = 11, row = 2},
	corflak = {order = 12, row = 2},
	screamer = {order = 13, row = 2},

--	armartic = {order = 3, row = 3},
	corgrav = {order = 4, row = 3},
	cortl = {order = 14, row = 3},
	cormine1 = {order = 16, row = 3},
	armanni = {order = 17, row = 3},
}

local aux = {	--merged into special
	corrad = {order = 10, row = 1},
	armjamt = {order = 11, row = 1},
	corjamt = {order = 12, row = 1},
	armsonar = {order = 13, row = 1},
	armarad = {order = 14, row = 1},
	--armasp = {order = 15, row = 1},
}

local super = {	--merged into special
	armamd = {order = 0, row = 2},
	missilesilo = {order = 1, row = 2},
	corbhmth = {order = 2, row = 2},
	armbrtha = {order = 3, row = 2},
	corsilo = {order = 4, row = 2},
	mahlazer = {order = 5, row = 2},
}

--number doesn't mean anything
local common_commands = {
	[CMD.STOP]=1, [CMD.GUARD]=1, [CMD.ATTACK]=1, [CMD.FIGHT]=1,
	[CMD.WAIT]=2, [CMD.PATROL]=2, [CMD.MOVE]=2, 
	[CMD.REPAIR]=1,   [CMD.RECLAIM]=1, [CMD_BUILD] = 1, [CMD.CAPTURE] = 1, [CMD.RESURRECT] = 1, 
--	[CMD_LEVEL] =1, [CMD_RAMP]= 1, [CMD_RAISE] = 2, [CMD_SMOOTH] =2,  [CMD_RESTORE] =2,
	[CMD.SELFD]=1, [CMD.AUTOREPAIRLEVEL]=1,[CMD.DGUN]=1,
	[CMD_RETREAT_ZONE] = 2,
	[CMD_AREA_MEX] = 1,
	[CMD.LOAD_UNITS]=1, [CMD.UNLOAD_UNITS]=1,
}

--not needed; menu has autodetection
local states_commands = {

}

local factory_commands = {}
local econ_commands = {}
local defense_commands = {}
local special_commands = {
	[CMD_RAMP] = {order = 16, row = 3},
	[CMD_LEVEL] = {order = 17, row = 3},
	[CMD_RAISE] = {order = 18, row = 3},
	[CMD_SMOOTH] = {order = 19, row = 3},
	[CMD_RESTORE] = {order = 20, row = 3},
}

local function CopyBuildArray(source, target)
	for name, value in pairs(source) do
		udef = (UnitDefNames[name])
		if udef then
			target[-udef.id] = value
		end
	end
end

CopyBuildArray(factories, factory_commands)
CopyBuildArray(econ, econ_commands)
CopyBuildArray(aux, special_commands)
CopyBuildArray(defense, defense_commands)
CopyBuildArray(super, special_commands)

-- Global commands defined here - they have cmdDesc format + 
local globalCommands = {
--[[	{
		name = "crap",
		texture= 'LuaUi/Images/move_hold.png',
		id = math.huge,
		OnClick = {function() 
			Spring.SendMessage("crap")
		end }
	}
	{
		id      = CMD_RETREAT_ZONE
		type    = CMDTYPE.ICON_MAP,
		tooltip = 'Place a retreat zone. Units will retreat there. Constructors placed in it will repair units.',
		cursor  = 'Repair',
		action  = 'sethaven',
		params  = { }, 
		texture = 'LuaUI/Images/ambulance.png',
	}]]--
}

-- Command overrides. State commands by default expect array of textures, one for each state.
-- You can specify texture, text,tooltip, color
--[[
local overrides = {
	[CMD.ATTACK] = { texture = 'LuaUi/Images/commands/attack.png',  text= '\255\0\255\0A\008ttack'},
	[CMD.STOP] = { texture = 'LuaUi/Images/commands/cancel.png', color={1,0,0,1.2}, text= '\255\0\255\0S\008top'},
	[CMD.FIGHT] = { texture = 'LuaUi/Images/commands/fight.png',text= '\255\0\255\0F\008ight'},
	[CMD.GUARD] = { texture = 'LuaUi/Images/commands/guard.png', text= '\255\0\255\0G\008uard'},
	[CMD.MOVE] = { texture = 'LuaUi/Images/commands/move.png', text= '\255\0\255\0M\008ove'},
	[CMD.PATROL] = { texture = 'LuaUi/Images/commands/patrol.png', text= '\255\0\255\0P\008atrol'},
	[CMD.WAIT] = { texture = 'LuaUi/Images/commands/wait.png', text= '\255\0\255\0W\008ait'},
	
	[CMD.REPAIR] = {text= '\255\0\255\0R\008epair', texture = 'LuaUi/Images/commands/repair.png'},
	[CMD.RECLAIM] = {text= 'R\255\0\255\0e\008claim', texture = 'LuaUi/Images/commands/reclaim.png'},
	[CMD.RESURRECT] = {text= 'Resurrec\255\0\255\0t\008', texture = 'LuaUi/Images/commands/resurrect.png'},
	[CMD_BUILD] = {text = '\255\0\255\0B\008uild'},
	[CMD.DGUN] = { texture = 'LuaUi/Images/commands/dgun.png', text= '\255\0\255\0D\008Gun'},
	
	[CMD_RAMP] = {text = 'Ramp', texture = 'LuaUi/Images/commands/ramp.png'},
	[CMD_LEVEL] = {text = 'Level', texture = 'LuaUi/Images/commands/level.png'},
	[CMD_RAISE] = {text = 'Raise', texture = 'LuaUi/Images/commands/raise.png'},
	[CMD_SMOOTH] = {text = 'Smooth', texture = 'LuaUi/Images/commands/smooth.png'},
	[CMD_RESTORE] = {text = 'Restore', texture = 'LuaUi/Images/commands/restore.png'},
	
	[CMD_AREA_MEX] = {text = 'Mex', texture = 'LuaUi/Images/ibeam.png'},
	[CMD_JUMP] = {text = 'Jump', texture = 'LuaUi/Images/commands/Bold/jump.png'},	
	
	[CMD.ONOFF] = { texture = {'LuaUi/Images/commands/states/off.png', 'LuaUi/Images/commands/states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {'LuaUi/Images/commands/states/bulb_off.png', 'LuaUi/Images/commands/states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {'LuaUi/Images/commands/states/repeat_off.png', 'LuaUi/Images/commands/states/repeat_on.png'}, text=''},
	[CMD.CLOAK] = { texture = {'LuaUi/Images/commands/states/cloak_off.png', 'LuaUI/Images/commands/states/cloak_on.png'}, text ='', tooltip =  'Unit cloaking state - press \255\0\255\0K\008 to toggle'},
	[CMD_CLOAK_SHIELD] = { texture = {'LuaUi/Images/commands/states/areacloak_off.png', 'LuaUI/Images/commands/states/areacloak_on.png'}, text ='',},
	[CMD_STEALTH] = { texture = {'LuaUi/Images/commands/states/stealth_off.png', 'LuaUI/Images/commands/states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {'LuaUi/Images/commands/states/wrench_low.png', 'LuaUi/Images/commands/states/wrench_med.png', 'LuaUi/Images/commands/states/wrench_high.png'}, text='', tooltip = 'Set construction priority (high, normal, low)'},
	[CMD.MOVE_STATE] = { texture = {'LuaUi/Images/commands/states/move_hold.png', 'LuaUi/Images/commands/states/move_engage.png', 'LuaUi/Images/commands/states/move_roam.png'}, text=''},
	[CMD.FIRE_STATE] = { texture = {'LuaUi/Images/commands/states/fire_hold.png', 'LuaUi/Images/commands/states/fire_return.png', 'LuaUi/Images/commands/states/fire_atwill.png'}, text=''},
	[CMD_RETREAT] = { texture = {'LuaUi/Images/commands/states/retreat_off.png', 'LuaUi/Images/commands/states/retreat_30.png', 'LuaUi/Images/commands/states/retreat_60.png', 'LuaUi/Images/commands/states/retreat_90.png'}, text=''},
}]]
local overrides = {
	[CMD.ATTACK] = { texture = 'LuaUi/Images/commands/Bold/attack.png',  text= ' '},
	[CMD.STOP] = { texture = 'LuaUi/Images/commands/Bold/cancel.png', text= ' '},
	[CMD.FIGHT] = { texture = 'LuaUi/Images/commands/Bold/fight.png',text= ' '},
	[CMD.GUARD] = { texture = 'LuaUi/Images/commands/Bold/guard.png', text= ' '},
	[CMD.MOVE] = { texture = 'LuaUi/Images/commands/Bold/move.png', text= ' '},
	[CMD.PATROL] = { texture = 'LuaUi/Images/commands/Bold/patrol.png', text= ' '},
	[CMD.WAIT] = { texture = 'LuaUi/Images/commands/Bold/wait.png', text= ' '},
	
	[CMD.REPAIR] = {text= ' ', texture = 'LuaUi/Images/commands/Bold/repair.png'},
	[CMD.RECLAIM] = {text= ' ', texture = 'LuaUi/Images/commands/Bold/reclaim.png'},
	[CMD.RESURRECT] = {text= ' ', texture = 'LuaUi/Images/commands/Bold/resurrect.png'},
	[CMD_BUILD] = {text = ' ', texture = 'LuaUi/Images/commands/Bold/build.png'},
	[CMD.DGUN] = { texture = 'LuaUi/Images/commands/dgun.png', text= ' '},

	[CMD.LOAD_UNITS] = { texture = 'LuaUi/Images/commands/Bold/load.png', text= ' '},
	[CMD.UNLOAD_UNITS] = { texture = 'LuaUi/Images/commands/Bold/unload.png', text= ' '},	
	
	[CMD_RAMP] = {text = ' ', texture = 'LuaUi/Images/commands/ramp.png'},
	[CMD_LEVEL] = {text = ' ', texture = 'LuaUi/Images/commands/level.png'},
	[CMD_RAISE] = {text = ' ', texture = 'LuaUi/Images/commands/raise.png'},
	[CMD_SMOOTH] = {text = ' ', texture = 'LuaUi/Images/commands/smooth.png'},
	[CMD_RESTORE] = {text = ' ', texture = 'LuaUi/Images/commands/restore.png'},
	
	[CMD_AREA_MEX] = {text = ' ', texture = 'LuaUi/Images/commands/Bold/mex.png'},
	
	[CMD_JUMP] = {text = ' ', texture = 'LuaUi/Images/commands/Bold/jump.png'},	
	
	[CMD.ONOFF] = { texture = {'LuaUi/Images/commands/states/off.png', 'LuaUi/Images/commands/states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {'LuaUi/Images/commands/states/bulb_off.png', 'LuaUi/Images/commands/states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {'LuaUi/Images/commands/states/repeat_off.png', 'LuaUi/Images/commands/states/repeat_on.png'}, text=''},
	[CMD.CLOAK] = { texture = {'LuaUi/Images/commands/states/cloak_off.png', 'LuaUI/Images/commands/states/cloak_on.png'}, text ='', tooltip =  'Unit cloaking state - press \255\0\255\0K\008 to toggle'},
	[CMD_CLOAK_SHIELD] = { texture = {'LuaUi/Images/commands/states/areacloak_off.png', 'LuaUI/Images/commands/states/areacloak_on.png'}, text ='', tooltip = 'Area Cloaker State'},
	[CMD_STEALTH] = { texture = {'LuaUi/Images/commands/states/stealth_off.png', 'LuaUI/Images/commands/states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {'LuaUi/Images/commands/states/wrench_low.png', 'LuaUi/Images/commands/states/wrench_med.png', 'LuaUi/Images/commands/states/wrench_high.png'}, text=""},
	[CMD.MOVE_STATE] = { texture = {'LuaUi/Images/commands/states/move_hold.png', 'LuaUi/Images/commands/states/move_engage.png', 'LuaUi/Images/commands/states/move_roam.png'}, text=''},
	[CMD.FIRE_STATE] = { texture = {'LuaUi/Images/commands/states/fire_hold.png', 'LuaUi/Images/commands/states/fire_return.png', 'LuaUi/Images/commands/states/fire_atwill.png'}, text=''},
	[CMD_RETREAT] = { texture = {'LuaUi/Images/commands/states/retreat_off.png', 'LuaUi/Images/commands/states/retreat_30.png', 'LuaUi/Images/commands/states/retreat_60.png', 'LuaUi/Images/commands/states/retreat_90.png'}, text=''},
}

return common_commands, states_commands, factory_commands, econ_commands, defense_commands, special_commands, globalCommands, overrides