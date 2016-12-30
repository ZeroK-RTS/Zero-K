VFS.Include("LuaRules/Configs/customcmds.h.lua")

--FIXME: use this table until state tooltip detection is fixed
--SIDENOTE: using this table is preferable than editing command description directly because this maintain tooltip's compatibility with other build menu too.(eg: color text is not supported by stock gui)
local tooltips = {
	priority = "Priority: Set construction priority (low, normal, high)",
	miscpriority = "Misc Priority: Set priority for non-construction spending (low, normal, high)",
	retreat = "Retreat: Retreat to closest retreat point or airpad at 30/65/99% of health (right-click to disable). Airpad for aircraft only.",
	landat = "Repair level: set the HP % at which this aircraft will go to a repair pad (0, 30, 50, 80)",
	factoryGuard = "Auto Assist: Newly built constructors automatically assist their factory",
	globalBuild = "Global Build Command: toggle using worker AI.",
	diveBomb = "\255\90\255\90Green\255\255\255\255:Dive For Shielded or Mobile Target\n\255\255\255\90Yellow\255\255\255\255:Dive For Mobile Target\n\255\255\90\90Red\255\255\255\255:Always Fly Low\n\255\90\90\90Grey\255\255\255\255:Always Fly High", --override tooltip supplied by unit_bomber_dive.lua gadget.
	floatState = "\255\90\255\90Green\255\255\255\255:Always float \n\255\90\90\90Grey\255\255\255\255:Float to fire\n\255\255\90\90Red\255\255\255\255:Never float",
	fireState = "Fire State: Sets under what conditions a unit will fire without an explicit attack order (never, when attacked, always)",
	moveState = "Move State: Sets how far out of its way a unit will move to attack enemies",
	["repeat"] = "Repeat: if on the unit will continously push finished orders to the end of its order queue",
	dropflag = "Drop flag on the ground.",
}

local CONSTRUCTOR     = {order = 1, row = 1, col = 1}
local RAIDER          = {order = 2, row = 1, col = 2}
local SKIRMISHER      = {order = 3, row = 1, col = 3}
local RIOT            = {order = 4, row = 1, col = 4}
local ASSAULT         = {order = 5, row = 1, col = 5}
local ARTILLERY       = {order = 6, row = 1, col = 6}

local WEIRD_RAIDER    = {order = 7, row = 2, col = 2}
local ANTI_AIR        = {order = 8, row = 2, col = 3}
local HEAVY_SOMETHING = {order = 9, row = 2, col = 4}
local SPECIAL         = {order = 10, row = 2, col = 5}
local UTILITY         = {order = 11, row = 2, col = 6}

local units = {
	factorycloak = {
		armrectr = CONSTRUCTOR,
		armpw = RAIDER,
		spherepole = WEIRD_RAIDER,
		armwar = RIOT,
		armrock = SKIRMISHER,
		armham = ARTILLERY,
		armjeth = ANTI_AIR,
		armzeus = ASSAULT,
		armsnipe = HEAVY_SOMETHING,
		armtick = SPECIAL,
		spherecloaker = UTILITY,
	},
	factoryshield = {
		cornecro = CONSTRUCTOR,
		corclog = WEIRD_RAIDER,
		corak = RAIDER,
		cormak = RIOT,
		corstorm = SKIRMISHER,
		shieldarty = ARTILLERY,
		corcrash = ANTI_AIR,
		corthud = ASSAULT,
		shieldfelon = HEAVY_SOMETHING,
		corroach = SPECIAL,
		core_spectre = UTILITY,	
	},
	factoryveh = {
		corned = CONSTRUCTOR,
		corfav = WEIRD_RAIDER,
		corgator = RAIDER,
		corlevlr = RIOT,
		cormist = SKIRMISHER, -- Not really but nowhere else to go
		corgarp = ARTILLERY,
		vehaa = ANTI_AIR,
		corraid = ASSAULT,
		armmerl = HEAVY_SOMETHING,
		capturecar = SPECIAL,
	},
	factoryhover = {
		corch = CONSTRUCTOR,
		corsh = RAIDER,
		hoverdepthcharge = SPECIAL,
		hoverriot = RIOT,
		nsaclash = SKIRMISHER,
		armmanni = ARTILLERY,
		hoveraa = ANTI_AIR,
		hoverassault = ASSAULT,
	},
	factorygunship = {
		gunshipcon = CONSTRUCTOR,
		bladew = WEIRD_RAIDER,
		armkam = RAIDER,
		armbrawl = ARTILLERY,
		gunshipsupport = SKIRMISHER,
		corvalk = SPECIAL,
		corbtrans = UTILITY,
		gunshipaa = ANTI_AIR,
		blackdawn = ASSAULT,
		corcrw = HEAVY_SOMETHING,
		blastwing = RIOT,
	},
	factoryplane = {
		armca = CONSTRUCTOR,
		fighter = RAIDER,
		corhurc2 = RIOT,
		-- No Plane Artillery
		corvamp = WEIRD_RAIDER,
		corawac = UTILITY,
		corshad = ASSAULT,
		armcybr = HEAVY_SOMETHING,
		armstiletto_laser = SPECIAL,
	},
	factoryspider = {
		arm_spider = CONSTRUCTOR,
		armflea = RAIDER,
		spiderriot = RIOT,
		armsptk = SKIRMISHER,
		-- No Spider Artillery
		spideraa = ANTI_AIR,
		arm_venom = WEIRD_RAIDER,
		spiderassault = ASSAULT,
		armcrabe = HEAVY_SOMETHING,
		armspy = SPECIAL,
	},
	factoryjump = {
		corfast = CONSTRUCTOR,
		puppy = WEIRD_RAIDER,
		corpyro = RAIDER,
		jumpblackhole = RIOT,
		slowmort = SKIRMISHER,
		firewalker = ARTILLERY,
		armaak = ANTI_AIR,
		corcan = ASSAULT,
		corsumo = HEAVY_SOMETHING,
		corsktl = SPECIAL,
	},
	factorytank = {
		coracv =  CONSTRUCTOR,
		logkoda = WEIRD_RAIDER,
		panther = RAIDER,
		tawf114 = RIOT,
		cormart = ARTILLERY,
		trem = UTILITY,
		corsent = ANTI_AIR,
		correap = ASSAULT,
		corgol = HEAVY_SOMETHING,
	},
	factoryamph = {
		amphcon = CONSTRUCTOR,
		amphraider3 = RAIDER,
		amphraider2 = WEIRD_RAIDER,
		amphriot = RIOT,
		amphfloater = SKIRMISHER,
		-- No Amph Artillery
		amphaa = ANTI_AIR,
		amphassault = HEAVY_SOMETHING,
		amphtele = SPECIAL,
	},
	factoryship = {
		shipcon = CONSTRUCTOR,
		shiptorpraider = RAIDER,
		shipriot = RIOT,
		shipskirm = SKIRMISHER,
		shiparty = ARTILLERY,
		shipaa = ANTI_AIR,
		shipscout = WEIRD_RAIDER,
		shipassault = ASSAULT,
		-- No Ship HEAVY_SOMETHING (yet)
		subraider = SPECIAL,
	},



}

local function AddBuildQueue(name)
	units[name] = {}
	local ud = UnitDefNames[name]
	if ud and ud.buildOptions then
		local row = 1
		local col = 1
		local order = 1
		for i = 1, #ud.buildOptions do
			local buildName = UnitDefs[ud.buildOptions[i]].name
			units[name][buildName] = {row = row, col = col, order = order}
			col = col + 1
			if col == 7 then
				col = 1
				row = row + 1
			end
			order = order + 1
		end
	end
end

AddBuildQueue("striderhub")
AddBuildQueue("missilesilo")

local factories = {
	factorycloak =    {order = 1, row = 1, col = 1},
	factoryshield =   {order = 2, row = 1, col = 2},
	factoryveh =      {order = 3, row = 1, col = 3},
	factoryhover =    {order = 4, row = 1, col = 4},
	factorygunship =  {order = 5, row = 1, col = 5},
	factoryplane =    {order = 6, row = 1, col = 6},
	factoryspider =   {order = 7, row = 2, col = 1},
	factoryjump =     {order = 8, row = 2, col = 2},
	factorytank =     {order = 9, row = 2, col = 3},
	factoryamph =    {order = 10, row = 2, col = 4},
	factoryship =    {order = 11, row = 2, col = 5},
	striderhub =     {order = 12, row = 2, col = 6},
}

--Integral menu is NON-ROBUST
--all buildings (except facs) need a row or they won't appear!
--you can put too many things into the same row, but the buttons will be squished
local econ = {
	cormex =     {order = 1, row = 1, col = 1},
	armwin =     {order = 2, row = 2, col = 1},
	armsolar =   {order = 3, row = 2, col = 2},
	geo =        {order = 4, row = 2, col = 3},
	armfus =     {order = 5, row = 2, col = 4},
	cafus =      {order = 6, row = 2, col = 5},
	armmstor =   {order = 7, row = 3, col = 1},
	armestor =   {order = 8, row = 3, col = 2},
	armnanotc =  {order = 9, row = 3, col = 3},
	armasp =    {order = 10, row = 3, col = 4},
}

local defense = {
	corrl =    {order = 0, row = 1, col = 1},
	corllt =   {order = 1, row = 1, col = 2},
	armdeva =  {order = 2, row = 1, col = 3},
	armartic = {order = 3, row = 1, col = 4},
	armpb =    {order = 5, row = 1, col = 5},
	corhlt =   {order = 6, row = 1, col = 6},

	missiletower =  {order = 9, row = 2, col = 1},
	corrazor =     {order = 10, row = 2, col = 2},
	corflak =      {order = 11, row = 2, col = 3},
	armcir =       {order = 12, row = 2, col = 4},
	screamer =     {order = 13, row = 2, col = 5},

--	armartic = {order = 3, row = 3},
	corgrav =    {order = 4, row = 3, col = 1},
	turrettorp = {order = 14, row = 3, col = 2},
	cordoom =    {order = 16, row = 3, col = 3},
	armanni =    {order = 17, row = 3, col = 4},
	corjamt =    {order = 18, row = 3, col = 5},
}

local aux = {	--merged into special
	corrad =   {order = 10, row = 1, col = 1},
	armjamt =  {order = 12, row = 1, col = 2},
	armarad =  {order = 14, row = 1, col = 3},
}

local super = {	--merged into special
	missilesilo = {order = 15, row = 1, col = 4},
	armamd =      {order = 16, row = 1, col = 5},
	corbhmth =     {order = 2, row = 2, col = 1},
	armbrtha =     {order = 3, row = 2, col = 2},
	corsilo =      {order = 4, row = 2, col = 3},
	zenith =       {order = 5, row = 2, col = 4},
	raveparty =    {order = 6, row = 2, col = 5},
	mahlazer =     {order = 7, row = 2, col = 6},
}

--manual entries not needed; menu has autodetection
local common_commands = {}
local states_commands = {}

local factory_commands = {}
local econ_commands = {}
local defense_commands = {}
local special_commands = {
	[CMD_RAMP] =    {order = 16, row = 3, col = 1},
	[CMD_LEVEL] =   {order = 17, row = 3, col = 2},
	[CMD_RAISE] =   {order = 18, row = 3, col = 3},
	[CMD_RESTORE] = {order = 19, row = 3, col = 4},
	[CMD_SMOOTH] =  {order = 20, row = 3, col = 5},
	--[CMD_BUMPY] = {order = 21, row = 3},
}
local units_factory_commands = {}

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

for name, listData in pairs(units) do
	local unitDefID = UnitDefNames[name]
	unitDefID = unitDefID and unitDefID.id
	if unitDefID then
		units_factory_commands[unitDefID] = {}
		CopyBuildArray(listData, units_factory_commands[unitDefID])
	end
end

-- Command overrides. State commands by default expect array of textures, one for each state.
-- You can specify texture, text,tooltip, color
local imageDir = 'LuaUI/Images/commands/'

local overrides = {
	[CMD.ATTACK] = { texture = imageDir .. 'Bold/attack.png', tooltip = "Force Fire: Shoot at a particular target or position."},
	[CMD.STOP] = { texture = imageDir .. 'Bold/cancel.png'},
	[CMD.FIGHT] = { texture = imageDir .. 'Bold/fight.png', tooltip = "Attack Move: Move to a position engaging targets on the way."},
	[CMD.GUARD] = { texture = imageDir .. 'Bold/guard.png'},
	[CMD.MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD.PATROL] = { texture = imageDir .. 'Bold/patrol.png'},
	[CMD.WAIT] = { texture = imageDir .. 'Bold/wait.png'},
	
	[CMD.REPAIR] = {texture = imageDir .. 'Bold/repair.png'},
	[CMD.RECLAIM] = {texture = imageDir .. 'Bold/reclaim.png'},
	[CMD.RESURRECT] = {texture = imageDir .. 'Bold/resurrect.png'},
	[CMD_BUILD] = {texture = imageDir .. 'Bold/build.png'},
	[CMD.MANUALFIRE] = { texture = imageDir .. 'Bold/dgun.png'},

	[CMD.LOAD_UNITS] = { texture = imageDir .. 'Bold/load.png'},
	[CMD.UNLOAD_UNITS] = { texture = imageDir .. 'Bold/unload.png'},
	[CMD.AREA_ATTACK] = { texture = imageDir .. 'Bold/areaattack.png'},
	
	[CMD_RAMP] = {texture = imageDir .. 'ramp.png'},
	[CMD_LEVEL] = {texture = imageDir .. 'level.png'},
	[CMD_RAISE] = {texture = imageDir .. 'raise.png'},
	[CMD_SMOOTH] = {texture = imageDir .. 'smooth.png'},
	[CMD_RESTORE] = {texture = imageDir .. 'restore.png'},
	[CMD_BUMPY] = {texture = imageDir .. 'bumpy.png'},
	
	[CMD_AREA_GUARD] = { texture = imageDir .. 'Bold/guard.png'},
	
	[CMD_AREA_MEX] = {text = ' ', texture = imageDir .. 'Bold/mex.png'},
	
	[CMD_JUMP] = {texture = imageDir .. 'Bold/jump.png'},	
	
	[CMD_FIND_PAD] = {text = ' ', texture = imageDir .. 'Bold/rearm.png'},
	
	[CMD_EMBARK] = {text = ' ', texture = imageDir .. 'Bold/embark.png'},	
	[CMD_DISEMBARK] = {text = ' ', texture = imageDir .. 'Bold/disembark.png'},
	
	[CMD_ONECLICK_WEAPON] = {},--texture = imageDir .. 'Bold/action.png'},
	[CMD_UNIT_SET_TARGET_CIRCLE] = {text='', texture = imageDir .. 'Bold/settarget.png'},
	[CMD_UNIT_CANCEL_TARGET] = {text='', texture = imageDir .. 'Bold/canceltarget.png'},
	
	[CMD_ABANDON_PW] = {text= '', texture = 'LuaUI/Images/Crystal_Clear_action_flag_white.png'},
	
	[CMD_PLACE_BEACON] = {text= '', texture = imageDir .. 'Bold/drop_beacon.png'},
	[CMD_UPGRADE_STOP] = { texture = imageDir .. 'Bold/cancelupgrade.png'},
	[CMD_STOP_PRODUCTION] = { texture = imageDir .. 'Bold/stopbuild.png'},
	[CMD_GBCANCEL] = { texture = imageDir .. 'Bold/stopbuild.png'},
	
	[CMD_RECALL_DRONES] = {texture = imageDir .. 'Bold/recall_drones.png'},
	
	-- states
	[CMD.ONOFF] = { texture = {imageDir .. 'states/off.png', imageDir .. 'states/on.png'}, text=''},
	[CMD_UNIT_AI] = { texture = {imageDir .. 'states/bulb_off.png', imageDir .. 'states/bulb_on.png'}, text=''},
	[CMD.REPEAT] = { texture = {imageDir .. 'states/repeat_off.png', imageDir .. 'states/repeat_on.png'}, text='', tooltip = tooltips["repeat"]},
	[CMD_WANT_CLOAK] = { texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'},
		text ='', tooltip =  'Desired cloak state'},
	[CMD.CLOAK] = { texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'},
		text ='', tooltip =  'Desired cloak state'},
	[CMD_CLOAK_SHIELD] = { texture = {imageDir .. 'states/areacloak_off.png', imageDir .. 'states/areacloak_on.png'}, 
		text ='',	tooltip = 'Area Cloaker State'},
	[CMD_STEALTH] = { texture = {imageDir .. 'states/stealth_off.png', imageDir .. 'states/stealth_on.png'}, text ='', },
	[CMD_PRIORITY] = { texture = {imageDir .. 'states/wrench_low.png', imageDir .. 'states/wrench_med.png', imageDir .. 'states/wrench_high.png'},
		text='', tooltip = tooltips.priority},
	[CMD_MISC_PRIORITY] = { texture = {imageDir .. 'states/wrench_low_other.png', imageDir .. 'states/wrench_med_other.png', imageDir .. 'states/wrench_high_other.png'},
		text='', tooltip = tooltips.miscpriority},
	[CMD_FACTORY_GUARD] = { texture = {imageDir .. 'states/autoassist_off.png', imageDir .. 'states/autoassist_on.png'},
		text='', tooltip = tooltips.factoryGuard,},
	[CMD_GLOBAL_BUILD] = { texture = {imageDir .. 'Bold/buildgrey.png', imageDir .. 'Bold/build_light.png'},
		text='', tooltip = tooltips.globalBuild,},
	[CMD.MOVE_STATE] = { texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'}, text='', tooltip = tooltips.moveState},
	[CMD.FIRE_STATE] = { texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'}, text='', tooltip = tooltips.fireState},
	[CMD_RETREAT] = { texture = {imageDir .. 'states/retreat_off.png', imageDir .. 'states/retreat_30.png', imageDir .. 'states/retreat_60.png', imageDir .. 'states/retreat_90.png'},
		text='', tooltip = tooltips.retreat,},
	[CMD.IDLEMODE] = { texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'}, text=''},	
	[CMD_AP_FLY_STATE] = { texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'}, text=''},
	[CMD.AUTOREPAIRLEVEL] = { texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_30.png', imageDir .. 'states/landat_50.png', imageDir .. 'states/landat_80.png'},
		text = '', tooltip = tooltips.landat,},
	[CMD_AP_AUTOREPAIRLEVEL] = { texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_30.png', imageDir .. 'states/landat_50.png', imageDir .. 'states/landat_80.png'},
		text = ''},
	[CMD_UNIT_BOMBER_DIVE_STATE] = { texture = {imageDir .. 'states/divebomb_off.png', imageDir .. 'states/divebomb_shield.png', imageDir .. 'states/divebomb_attack.png', imageDir .. 'states/divebomb_always.png'},
		text = '', tooltip = tooltips.diveBomb},
	[CMD_UNIT_KILL_SUBORDINATES] = {texture = {imageDir .. 'states/capturekill_off.png', imageDir .. 'states/capturekill_on.png'}, text=''},
	[CMD_DONT_FIRE_AT_RADAR] = {texture = {imageDir .. 'states/stealth_on.png', imageDir .. 'states/stealth_off.png'}, text=''},
	[CMD_PREVENT_OVERKILL] = {texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_80.png'}, text=''},
	[CMD.TRAJECTORY] = { texture = {imageDir .. 'states/traj_low.png', imageDir .. 'states/traj_high.png'}, text=''},
	[CMD_AIR_STRAFE] = { texture = {imageDir .. 'states/strafe_off.png', imageDir .. 'states/strafe_on.png'}, text=''},
	[CMD_UNIT_FLOAT_STATE] = { texture = {imageDir .. 'states/amph_sink.png', imageDir .. 'states/amph_attack.png', imageDir .. 'states/amph_float.png'}, text='', tooltip=tooltips.floatState},
	}

-- Commands that only exist in LuaUI cannot have a hidden param. Therefore those that should be hidden are placed in this table.
local widgetSpaceHidden = {
	[60] = true, -- CMD.PAGES
	[CMD_SETHAVEN] = true,
	[CMD_SET_FERRY] = true,
}

return factory_commands, econ_commands, defense_commands, special_commands, units_factory_commands, overrides, widgetSpaceHidden
