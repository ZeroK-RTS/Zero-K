--this crap should be autodetected tbfh, I don't even know why I'm putting it here

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

CMD_PAGES = 60

local factories = {
	factorycloak = 1,
	factoryshield = 1,
	factoryspider = 1,
	factoryjump = 1,
	factoryveh = 1,
	factorytank = 1,
	factoryhover = 1,
	factoryplane = 1,
	factorygunship = 1,
	corsy = 1,
	armcsa = 1,
}

local econ = {
	cormex = 1,
	armsolar = 1,
	armwin = 1,
	armfus = 1,
	geo = 1,
	cafus = 2,
	armmstor = 2,
	armestor = 2,
	armnanotc = 1,
}

local aux = {	--merged into econ
	corrad = 1,
	armarad = 2,
	corjamt = 1,
	armsonar = 1,
	armasp = 1,
}

local defense = {
	corllt = 1,
	armdeva = 1,
	corhlt = 1,
	armartic = 2,
	corgrav = 2,
	armpb = 2,
	armanni = 3,
	corrl = 1,
	corrazor = 1,
	missiletower = 1,
	armcir = 2,
	corflak = 2,
	screamer = 3,
}

common_commands = {
	[CMD.STOP]=1, [CMD.GUARD]=1, [CMD.ATTACK]=1, [CMD.FIGHT]=1,
	[CMD.WAIT]=2, [CMD.PATROL]=2, [CMD.MOVE]=2, 
	[CMD.REPAIR]=1,   [CMD.RECLAIM]=1, [CMD_BUILD] = 1, [CMD.CAPTURE] = 1, [CMD.RESURRECT] = 1, [CMD_LEVEL] =1,  [CMD_RAMP]= 1, 
	[CMD_RAISE] = 2, [CMD_SMOOTH] =2,  [CMD_RESTORE] =2,
	[CMD.SELFD]=1, [CMD.AUTOREPAIRLEVEL]=1,[CMD.DGUN]=1,
	[CMD_RETREAT_ZONE] = 2,
	[CMD_AREA_MEX] = 1,
}

states_commands = {
	[CMD_CLOAK_SHIELD] = 1,
	[CMD_RETREAT] = 2, [CMD.MOVE_STATE] = 2, [CMD.FIRE_STATE] = 2, [CMD_UNIT_AI] = 2,
	[CMD_STEALTH] = 2,
	[CMD.AISELECT] = 3, 
}

factory_commands = {
}

econaux_commands = {

}

defense_commands = {

}

local function CopyBuildArray(source, target)
	for name, value in pairs(source) do
		cmdid = UnitDefNames[name].id
		if cmdid then target[-cmdid] = value end
		Spring.Echo("Adding command "..-cmdid.." unit "..UnitDefs[cmdid].name.." to menu")
	end
end

CopyBuildArray(factories, factory_commands)
CopyBuildArray(econ, econaux_commands)
CopyBuildArray(aux, econaux_commands)
CopyBuildArray(defense, defense_commands)

-- Command overrides. State commands by default expect array of textures, one for each state. States are drawn without button borders and keep aspect ratio. 
-- You can specify texture, text,tooltip, color
overrides = {
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
	
	[CMD.ONOFF] = { texture = {'LuaUi/Images/commands/states/off.png', 'LuaUi/Images/commands/states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {'LuaUi/Images/commands/states/bulb_off.png', 'LuaUi/Images/commands/states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {'LuaUi/Images/commands/states/repeat_off.png', 'LuaUi/Images/commands/states/repeat_on.png'}, text=''},
	[CMD.CLOAK] = { texture = {'LuaUi/Images/commands/states/cloak_off.png', 'LuaUI/Images/commands/states/cloak_on.png'}, text ='', tooltip =  'Unit cloaking state - press \255\0\255\0K\008 to toggle'},
	[CMD_CLOAK_SHIELD] = { texture = {'LuaUi/Images/commands/states/areacloak_off.png', 'LuaUI/Images/commands/states/areacloak_on.png'}, text ='', tooltip = 'Area Cloaker State'},
	[CMD_STEALTH] = { texture = {'LuaUi/Images/commands/states/stealth_off.png', 'LuaUI/Images/commands/states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {'LuaUi/Images/commands/states/wrench_low.png', 'LuaUi/Images/commands/states/wrench_med.png', 'LuaUi/Images/commands/states/wrench_high.png'}, text=''},
	[CMD.MOVE_STATE] = { texture = {'LuaUi/Images/commands/states/move_hold.png', 'LuaUi/Images/commands/states/move_engage.png', 'LuaUi/Images/commands/states/move_roam.png'}, text=''},
	[CMD.FIRE_STATE] = { texture = {'LuaUi/Images/commands/states/fire_hold.png', 'LuaUi/Images/commands/states/fire_return.png', 'LuaUi/Images/commands/states/fire_atwill.png'}, text=''},
	[CMD_RETREAT] = { texture = {'LuaUi/Images/commands/states/retreat_off.png', 'LuaUi/Images/commands/states/retreat_30.png', 'LuaUi/Images/commands/states/retreat_60.png', 'LuaUi/Images/commands/states/retreat_90.png'}, text=''},
}