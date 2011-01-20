VFS.Include("LuaRules/Configs/customcmds.h.lua")

--FIXME: use this table until state tooltip detection is fixed
local tooltips = {
	priority = "Priority: Set construction priority (low, normal, high)",
	retreat = "Retreat: Retreat to closest retreat point at 30/60/90% of health (right-click to disable)",
	landat = "Repair level: set the HP % at which this aircraft will go to a repair pad (0, 30, 50, 80)",
}

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
	cordoom = {order = 18, row = 3},
	corjamt = {order = 19, row = 1},
}

local aux = {	--merged into special
	corrad = {order = 10, row = 1},
	armjamt = {order = 11, row = 1},
--	corjamt = {order = 12, row = 1},
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

--manual entries not needed; menu has autodetection
local common_commands = {}
local states_commands = {}

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
local imageDir = 'LuaUI/Images/commands/'

--[[
local overrides = {
	[CMD.ATTACK] = { texture = imageDir .. 'attack.png',  text= '\255\0\255\0A\008ttack'},
	[CMD.STOP] = { texture = imageDir .. 'cancel.png', color={1,0,0,1.2}, text= '\255\0\255\0S\008top'},
	[CMD.FIGHT] = { texture = imageDir .. 'fight.png',text= '\255\0\255\0F\008ight'},
	[CMD.GUARD] = { texture = imageDir .. 'guard.png', text= '\255\0\255\0G\008uard'},
	[CMD.MOVE] = { texture = imageDir .. 'move.png', text= '\255\0\255\0M\008ove'},
	[CMD.PATROL] = { texture = imageDir .. 'patrol.png', text= '\255\0\255\0P\008atrol'},
	[CMD.WAIT] = { texture = imageDir .. 'wait.png', text= '\255\0\255\0W\008ait'},
	
	[CMD.REPAIR] = {text= '\255\0\255\0R\008epair', texture = imageDir .. 'repair.png'},
	[CMD.RECLAIM] = {text= 'R\255\0\255\0e\008claim', texture = imageDir .. 'reclaim.png'},
	[CMD.RESURRECT] = {text= 'Resurrec\255\0\255\0t\008', texture = imageDir .. 'resurrect.png'},
	[CMD_BUILD] = {text = '\255\0\255\0B\008uild'},
	[CMD.DGUN] = { texture = imageDir .. 'dgun.png', text= '\255\0\255\0D\008Gun'},
	
	[CMD_RAMP] = {text = 'Ramp', texture = imageDir .. 'ramp.png'},
	[CMD_LEVEL] = {text = 'Level', texture = imageDir .. 'level.png'},
	[CMD_RAISE] = {text = 'Raise', texture = imageDir .. 'raise.png'},
	[CMD_SMOOTH] = {text = 'Smooth', texture = imageDir .. 'smooth.png'},
	[CMD_RESTORE] = {text = 'Restore', texture = imageDir .. 'restore.png'},
	
	[CMD_AREA_MEX] = {text = 'Mex', texture = 'LuaUi/Images/ibeam.png'},
	[CMD_JUMP] = {text = 'Jump', texture = imageDir .. 'Bold/jump.png'},	
	
	[CMD.ONOFF] = { texture = {imageDir .. 'states/off.png', imageDir .. 'states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {imageDir .. 'states/bulb_off.png', imageDir .. 'states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {imageDir .. 'states/repeat_off.png', imageDir .. 'states/repeat_on.png'}, text=''},
	[CMD.CLOAK] = { texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'}, text ='', tooltip =  'Unit cloaking state - press \255\0\255\0K\008 to toggle'},
	[CMD_CLOAK_SHIELD] = { texture = {imageDir .. 'states/areacloak_off.png', imageDir .. 'states/areacloak_on.png'}, text ='',},
	[CMD_STEALTH] = { texture = {imageDir .. 'states/stealth_off.png', imageDir .. 'states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {imageDir .. 'states/wrench_low.png', imageDir .. 'states/wrench_med.png', imageDir .. 'states/wrench_high.png'}, text='', tooltip = tooltips.priority},
	[CMD.MOVE_STATE] = { texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'}, text=''},
	[CMD.FIRE_STATE] = { texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'}, text=''},
	[CMD_RETREAT] = { texture = {imageDir .. 'states/retreat_off.png', imageDir .. 'states/retreat_30.png', imageDir .. 'states/retreat_60.png', imageDir .. 'states/retreat_90.png'}, text=''},
}]]

local overrides = {
	[CMD.ATTACK] = { texture = imageDir .. 'Bold/attack.png',  text= '\255\0\255\0A'},
	[CMD.STOP] = { texture = imageDir .. 'Bold/cancel.png', text= '\255\0\255\0S'},
	[CMD.FIGHT] = { texture = imageDir .. 'Bold/fight.png',text= '\255\0\255\0F'},
	[CMD.GUARD] = { texture = imageDir .. 'Bold/guard.png', text= '\255\0\255\0G'},
	[CMD.MOVE] = { texture = imageDir .. 'Bold/move.png', text= '\255\0\255\0M'},
	[CMD.PATROL] = { texture = imageDir .. 'Bold/patrol.png', text= '\255\0\255\0P'},
	[CMD.WAIT] = { texture = imageDir .. 'Bold/wait.png', text= '\255\0\255\0W'},
	
	[CMD.REPAIR] = {text= '\255\0\255\0R', texture = imageDir .. 'Bold/repair.png'},
	[CMD.RECLAIM] = {text= '\255\0\255\0E', texture = imageDir .. 'Bold/reclaim.png'},
	[CMD.RESURRECT] = {text= '\255\0\255\0S', texture = imageDir .. 'Bold/resurrect.png'},
	[CMD_BUILD] = {text = '\255\0\255\0B', texture = imageDir .. 'Bold/build.png'},
	[CMD.DGUN] = { texture = imageDir .. 'dgun.png', text= '\255\0\255\0D'},

	[CMD.LOAD_UNITS] = { texture = imageDir .. 'Bold/load.png', text= '\255\0\255\0L'},
	[CMD.UNLOAD_UNITS] = { texture = imageDir .. 'Bold/unload.png', text= '\255\0\255\0U'},
	[CMD.AREA_ATTACK] = { texture = imageDir .. 'Bold/areaattack.png', text='\255\0\255\0Alt+A'},
	
	[CMD_RAMP] = {text = ' ', texture = imageDir .. 'ramp.png'},
	[CMD_LEVEL] = {text = ' ', texture = imageDir .. 'level.png'},
	[CMD_RAISE] = {text = ' ', texture = imageDir .. 'raise.png'},
	[CMD_SMOOTH] = {text = ' ', texture = imageDir .. 'smooth.png'},
	[CMD_RESTORE] = {text = ' ', texture = imageDir .. 'restore.png'},
	
	[CMD_AREA_MEX] = {text = ' ', texture = imageDir .. 'Bold/mex.png'},
	
	[CMD_JUMP] = {text = ' ', texture = imageDir .. 'Bold/jump.png'},	
	
	-- states
	[CMD.ONOFF] = { texture = {imageDir .. 'states/off.png', imageDir .. 'states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {imageDir .. 'states/bulb_off.png', imageDir .. 'states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {imageDir .. 'states/repeat_off.png', imageDir .. 'states/repeat_on.png'}, text=''},
	[CMD.CLOAK] = { texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'}, text ='', tooltip =  'Unit cloaking state - press \255\0\255\0K\008 to toggle'},
	[CMD_CLOAK_SHIELD] = { texture = {imageDir .. 'states/areacloak_off.png', imageDir .. 'states/areacloak_on.png'}, text ='', tooltip = 'Area Cloaker State'},
	[CMD_STEALTH] = { texture = {imageDir .. 'states/stealth_off.png', imageDir .. 'states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {imageDir .. 'states/wrench_low.png', imageDir .. 'states/wrench_med.png', imageDir .. 'states/wrench_high.png'}, text='', tooltip = tooltips.priority},
	[CMD.MOVE_STATE] = { texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'}, text=''},
	[CMD.FIRE_STATE] = { texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'}, text=''},
	[CMD_RETREAT] = { texture = {imageDir .. 'states/retreat_off.png', imageDir .. 'states/retreat_30.png', imageDir .. 'states/retreat_60.png', imageDir .. 'states/retreat_90.png'}, text='', tooltip = tooltips.retreat,},
	[CMD.IDLEMODE] = { texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'}, text=''},	
	[CMD_AP_FLY_STATE] = { texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'}, text=''},
	[CMD.AUTOREPAIRLEVEL] = { texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_30.png', imageDir .. 'states/landat_50.png', imageDir .. 'states/landat_80.png'}, text = '', tooltip = tooltips.landat,},
	[CMD_AP_AUTOREPAIRLEVEL] = { texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_30.png', imageDir .. 'states/landat_50.png', imageDir .. 'states/landat_80.png'}, text = ''},
	[CMD_UNIT_KILL_SUBORDINATES] = {texture = {imageDir .. 'states/capturekill_off.png', imageDir .. 'states/capturekill_on.png'}, text=''},
}

local custom_cmd_actions = {
	retreat=1,
	--retreat_zone=1,
	sethaven=1,
	['luaui noretreat']=1,

	build=1,
	area_mex=1,

	embark=1,
	disembark=1,
	stealth=1,
	cloak_shield=1,
	mine=1,
	priority=1,
	ap_fly_state=1,
	ap_autorepairlevel=1,
	antinukezone=1,
	unit_ai=1,
	unit_kill_subordinates=1,
	jump=1,

	-- terraform
	ramp=1,
	level=1,
	raise=1,
	smooth=1,
	restore=1,
	--terraform_internal=1,
}


return common_commands, states_commands, factory_commands, econ_commands, defense_commands, special_commands, globalCommands, overrides, custom_cmd_actions