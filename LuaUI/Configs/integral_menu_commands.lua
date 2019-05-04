VFS.Include("LuaRules/Configs/customcmds.h.lua")

--FIXME: use this table until state tooltip detection is fixed
--SIDENOTE: using this table is preferable than editing command description directly because this maintain tooltip's compatibility with other build menu too.(eg: color text is not supported by stock gui)

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
		cloakcon = CONSTRUCTOR,
		cloakraid = RAIDER,
		cloakheavyraid = WEIRD_RAIDER,
		cloakriot = RIOT,
		cloakskirm = SKIRMISHER,
		cloakarty = ARTILLERY,
		cloakaa = ANTI_AIR,
		cloakassault = ASSAULT,
		cloaksnipe = HEAVY_SOMETHING,
		cloakbomb = SPECIAL,
		cloakjammer = UTILITY,
	},
	factoryshield = {
		shieldcon = CONSTRUCTOR,
		shieldscout = WEIRD_RAIDER,
		shieldraid = RAIDER,
		shieldriot = RIOT,
		shieldskirm = SKIRMISHER,
		shieldarty = ARTILLERY,
		shieldaa = ANTI_AIR,
		shieldassault = ASSAULT,
		shieldfelon = HEAVY_SOMETHING,
		shieldbomb = SPECIAL,
		shieldshield = UTILITY,
	},
	factoryveh = {
		vehcon = CONSTRUCTOR,
		vehscout = WEIRD_RAIDER,
		vehraid = RAIDER,
		vehriot = RIOT,
		vehsupport = SKIRMISHER, -- Not really but nowhere else to go
		veharty = ARTILLERY,
		vehaa = ANTI_AIR,
		vehassault = ASSAULT,
		vehheavyarty = HEAVY_SOMETHING,
		vehcapture = SPECIAL,
	},
	factoryhover = {
		hovercon = CONSTRUCTOR,
		hoverraid = RAIDER,
		hoverdepthcharge = SPECIAL,
		hoverriot = RIOT,
		hoverskirm = SKIRMISHER,
		hoverarty = ARTILLERY,
		hoveraa = ANTI_AIR,
		hoverassault = ASSAULT,
	},
	factorygunship = {
		gunshipcon = CONSTRUCTOR,
		gunshipemp = WEIRD_RAIDER,
		gunshipraid = RAIDER,
		gunshipheavyskirm = ARTILLERY,
		gunshipskirm = SKIRMISHER,
		gunshiptrans = SPECIAL,
		gunshipheavytrans = UTILITY,
		gunshipaa = ANTI_AIR,
		gunshipassault = ASSAULT,
		gunshipkrow = HEAVY_SOMETHING,
		gunshipbomb = RIOT,
	},
	factoryplane = {
		planecon = CONSTRUCTOR,
		planefighter = RAIDER,
		bomberriot = RIOT,
		-- No Plane Artillery
		planeheavyfighter = WEIRD_RAIDER,
		planescout = UTILITY,
		planelightscout = ARTILLERY,
		bomberprec = ASSAULT,
		bomberheavy = HEAVY_SOMETHING,
		bomberdisarm = SPECIAL,
	},
	factoryspider = {
		spidercon = CONSTRUCTOR,
		spiderscout = RAIDER,
		spiderriot = RIOT,
		spiderskirm = SKIRMISHER,
		-- No Spider Artillery
		spideraa = ANTI_AIR,
		spideremp = WEIRD_RAIDER,
		spiderassault = ASSAULT,
		spidercrabe = HEAVY_SOMETHING,
		spiderantiheavy = SPECIAL,
	},
	factoryjump = {
		jumpcon = CONSTRUCTOR,
		jumpscout = WEIRD_RAIDER,
		jumpraid = RAIDER,
		jumpblackhole = RIOT,
		jumpskirm = SKIRMISHER,
		jumparty = ARTILLERY,
		jumpaa = ANTI_AIR,
		jumpassault = ASSAULT,
		jumpsumo = HEAVY_SOMETHING,
		jumpbomb = SPECIAL,
	},
	factorytank = {
		tankcon =  CONSTRUCTOR,
		tankraid = WEIRD_RAIDER,
		tankheavyraid = RAIDER,
		tankriot = RIOT,
		tankarty = ARTILLERY,
		tankheavyarty = UTILITY,
		tankaa = ANTI_AIR,
		tankassault = ASSAULT,
		tankheavyassault = HEAVY_SOMETHING,
	},
	factoryamph = {
		amphcon = CONSTRUCTOR,
		amphraid = RAIDER,
		amphimpulse = WEIRD_RAIDER,
		amphriot = RIOT,
		amphfloater = SKIRMISHER,
		-- No Amph Artillery
		amphaa = ANTI_AIR,
		amphassault = HEAVY_SOMETHING,
		amphlaunch = ARTILLERY,
		amphbomb = SPECIAL,
		amphtele = UTILITY,
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
	pw_bomberfac = {
		bomberriot = RIOT,
		bomberprec = ASSAULT,
		bomberheavy = HEAVY_SOMETHING,
		bomberdisarm = SPECIAL,
	},
	pw_dropfac = {
		gunshiptrans = SPECIAL,
		gunshipheavytrans = UTILITY,
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
AddBuildQueue("staticmissilesilo")

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
	staticmex =     {order = 1, row = 1, col = 1},
	energywind =     {order = 2, row = 2, col = 1},
	energysolar =   {order = 3, row = 2, col = 2},
	energygeo =        {order = 4, row = 2, col = 3},
	energyfusion =     {order = 5, row = 2, col = 4},
	energysingu =      {order = 6, row = 2, col = 5},
	staticstorage =   {order = 7, row = 3, col = 1},
	energypylon =   {order = 8, row = 3, col = 2},
	staticcon =  {order = 9, row = 3, col = 3},
	staticrearm =    {order = 10, row = 3, col = 4},
}

local defense = {
	turretlaser =   {order = 2, row = 1, col = 1},
	turretmissile =    {order = 1, row = 1, col = 2},
	turretriot =  {order = 2, row = 1, col = 3},
	turretemp = {order = 3, row = 1, col = 4},
	turretgauss =    {order = 5, row = 1, col = 5},
	turretheavylaser =   {order = 6, row = 1, col = 6},

	turretaaclose =  {order = 9, row = 2, col = 1},
	turretaalaser =     {order = 10, row = 2, col = 2},
	turretaaflak =      {order = 11, row = 2, col = 3},
	turretaafar =       {order = 12, row = 2, col = 4},
	turretaaheavy =     {order = 13, row = 2, col = 5},

--	turretemp = {order = 3, row = 3},
	turretimpulse =    {order = 4, row = 3, col = 1},
	turrettorp = {order = 14, row = 3, col = 2},
	turretheavy =    {order = 16, row = 3, col = 3},
	turretantiheavy =    {order = 17, row = 3, col = 4},
	staticshield =    {order = 18, row = 3, col = 5},
}

local aux = {	--merged into special
	staticradar =   {order = 10, row = 1, col = 1},
	staticjammer =  {order = 12, row = 1, col = 2},
	staticheavyradar =  {order = 14, row = 1, col = 3},
}

local super = {	--merged into special
	staticmissilesilo = {order = 15, row = 1, col = 4},
	staticantinuke =      {order = 16, row = 1, col = 5},
	staticarty =     {order = 2, row = 2, col = 1},
	staticheavyarty =     {order = 3, row = 2, col = 2},
	staticnuke =      {order = 4, row = 2, col = 3},
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

-- Old tooltips
--priority = ,
--miscpriority = "Misc Priority: Set priority for non-construction spending (low, normal, high)",
--retreat = "Retreat: Retreat to closest retreat point or airpad at 30/65/99% of health (right-click to disable). Airpad for aircraft only.",
--landat = "Repair level: set the HP % at which this aircraft will go to a repair pad (0, 30, 50, 80)",
--factoryGuard = "Auto Assist: Newly built constructors automatically assist their factory",
--globalBuild =
--diveBomb = "\255\90\255\90Green\255\255\255\255:Dive For Shielded or Mobile Target\n\255\255\255\90Yellow\255\255\255\255:Dive For Mobile Target\n\255\255\90\90Red\255\255\255\255:Always Fly Low\n\255\90\90\90Grey\255\255\255\255:Always Fly High", --override tooltip supplied by unit_bomber_dive.lua gadget.
--floatState = "\255\90\255\90Green\255\255\255\255:Always float \n\255\90\90\90Grey\255\255\255\255:Float to fire\n\255\255\90\90Red\255\255\255\255:Never float",
--fireState = "Fire State: Sets under what conditions a unit will fire without an explicit attack order (never, when attacked, always)",
--moveState = "Move State: Sets how far out of its way a unit will move to attack enemies",
--["repeat"] = "Repeat: if on the unit will continously push finished orders to the end of its order queue",
--dropflag = "Drop flag on the ground.",
--autoCallTransport =

local tooltips = {
	ONOFF = "Activation (_STATE_)\n  Toggles some unit abilities.",
	UNIT_AI = "Unit AI (_STATE_)\n  Move intelligently in combat.",
	REPEAT = "Repeat (_STATE_)\n  Loop command queue. Construction queue for factories.",
	WANT_CLOAK = "Cloak (_STATE_)\n  Makes the unit invisible, unless it fires, takes damage, or is too close to an enemy unit.",
	CLOAK_SHIELD = "Area Cloaker (_STATE_)\n  Cloaks all friendly units in an area.",
	PRIORITY = "Construction Priority (_STATE_)\n  Higher priority constructors receive resources before those of lower priority.",
	MISC_PRIORITY = "Misc. Priority (_STATE_)\n  Priority for non-constructor resource usage (morph, stockpile, and energy upkeep).",
	FACTORY_GUARD = "Auto Assist (_STATE_)\n  Newly built constructors automatically assist their factory.",
	AUTO_CALL_TRANSPORT = "Call Transports (_STATE_)\n  Automatically call transports between constructor tasks.",
	GLOBAL_BUILD = "Global Build Command (_STATE_)\n  Sets constructors to execute global build orders.",
	MOVE_STATE = "Move State (_STATE_)\n  Sets how far out of its way a unit will move to attack enemies.",
	FIRE_STATE = "Fire State (_STATE_)\n  Sets when a unit will automatically shoot.",
	RETREAT = "Retreat (_STATE_)\n  Automatically retreat to closest retreat point or airpad when damaged. Right click to disable.",
	IDLEMODE = "Idle State (_STATE_)\n  Set whether aircraft lands when idle.",
	AP_FLY_STATE = "Idle State (_STATE_)\n  Set whether aircraft lands when idle.",
	UNIT_BOMBER_DIVE_STATE = "Dive State (_STATE_)\n  Set when Ravens dive.",
	UNIT_KILL_SUBORDINATES = "Kill Captured (_STATE_)\n  Set whether to kill captured units.",
	PUSH_PULL = "Impulse Mode (_STATE_)\n  Set whether gravity guns push or pull.",
	DONT_FIRE_AT_RADAR = "Fire At Radar State (_STATE_)\n  Set whether precise units with high reload time fire at radar dots.",
	PREVENT_OVERKILL = "Overkill Prevention (_STATE_)\n  Prevents units from shooting at already doomed enemies.",
	TRAJECTORY = "Trajectory (_STATE_)\n  Set whether units fire at a high or low arc.",
	AIR_STRAFE = "Gunship Strafe (_STATE_)\n  Set whether gunships strafe when fighting.",
	UNIT_FLOAT_STATE = "Float State (_STATE_)\n  Set the conditions which cause certain amphibious units to float to the surface.",
	SELECTION_RANK = "Selection Rank (_STATE_)\n  Priority for selection filtering.",
	TOGGLE_DRONES = "Drone Construction (_STATE_)\n  Toggle drone creation."
}

local overrides = {
	[CMD.ATTACK] = { texture = imageDir .. 'Bold/attack.png', tooltip = "Force Fire: Shoot at a particular target or position."},
	[CMD.STOP] = { texture = imageDir .. 'Bold/cancel.png'},
	[CMD.FIGHT] = { texture = imageDir .. 'Bold/fight.png', tooltip = "Attack Move: Move to a position engaging targets on the way."},
	[CMD.GUARD] = { texture = imageDir .. 'Bold/guard.png'},
	[CMD.MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD_RAW_MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD.PATROL] = { texture = imageDir .. 'Bold/patrol.png'},
	[CMD.WAIT] = { texture = imageDir .. 'Bold/wait.png', tooltip = "Wait: Pause the units command queue and have it hold its current position."},

	[CMD.REPAIR] = {texture = imageDir .. 'Bold/repair.png'},
	[CMD.RECLAIM] = {texture = imageDir .. 'Bold/reclaim.png'},
	[CMD.RESURRECT] = {texture = imageDir .. 'Bold/resurrect.png'},
	[CMD_BUILD] = {texture = imageDir .. 'Bold/build.png'},
	[CMD.MANUALFIRE] = { texture = imageDir .. 'Bold/dgun.png', tooltip = "Fire Special Weapon: Fire the unit's special weapon."},

	[CMD.LOAD_UNITS] = { texture = imageDir .. 'Bold/load.png'},
	[CMD.UNLOAD_UNITS] = { texture = imageDir .. 'Bold/unload.png'},
	[CMD.AREA_ATTACK] = { texture = imageDir .. 'Bold/areaattack.png'},

	[CMD_RAMP] = {texture = imageDir .. 'ramp.png'},
	[CMD_LEVEL] = {texture = imageDir .. 'level.png'},
	[CMD_RAISE] = {texture = imageDir .. 'raise.png'},
	[CMD_SMOOTH] = {texture = imageDir .. 'smooth.png'},
	[CMD_RESTORE] = {texture = imageDir .. 'restore.png'},
	[CMD_BUMPY] = {texture = imageDir .. 'bumpy.png'},

	[CMD_AREA_GUARD] = { texture = imageDir .. 'Bold/guard.png', tooltip = "Guard: Protect the target and assist its production."},

	[CMD_AREA_MEX] = {texture = imageDir .. 'Bold/mex.png'},

	[CMD_JUMP] = {texture = imageDir .. 'Bold/jump.png'},

	[CMD_FIND_PAD] = {texture = imageDir .. 'Bold/rearm.png', tooltip = "Resupply: Return to nearest repair pad for health and ammo."},

	[CMD_EMBARK] = {texture = imageDir .. 'Bold/embark.png'},
	[CMD_DISEMBARK] = {texture = imageDir .. 'Bold/disembark.png'},

	[CMD_ONECLICK_WEAPON] = {},--texture = imageDir .. 'Bold/action.png'},
	[CMD_UNIT_SET_TARGET_CIRCLE] = {texture = imageDir .. 'Bold/settarget.png'},
	[CMD_UNIT_CANCEL_TARGET] = {texture = imageDir .. 'Bold/canceltarget.png'},

	[CMD_ABANDON_PW] = {texture = imageDir .. 'Bold/drop_beacon.png'},

	[CMD_PLACE_BEACON] = {texture = imageDir .. 'Bold/drop_beacon.png'},
	[CMD_UPGRADE_STOP] = { texture = imageDir .. 'Bold/cancelupgrade.png'},
	[CMD_STOP_PRODUCTION] = { texture = imageDir .. 'Bold/stopbuild.png'},
	[CMD_GBCANCEL] = { texture = imageDir .. 'Bold/stopbuild.png'},

	[CMD_RECALL_DRONES] = {texture = imageDir .. 'Bold/recall_drones.png'},

	-- states
	[CMD.ONOFF] = {
		texture = {imageDir .. 'states/off.png', imageDir .. 'states/on.png'},
		stateTooltip = {tooltips.ONOFF:gsub("_STATE_", "Off"), tooltips.ONOFF:gsub("_STATE_", "On")}
	},
	[CMD_UNIT_AI] = {
		texture = {imageDir .. 'states/bulb_off.png', imageDir .. 'states/bulb_on.png'},
		stateTooltip = {tooltips.UNIT_AI:gsub("_STATE_", "Disabled"), tooltips.UNIT_AI:gsub("_STATE_", "Enabled")},
	},
	[CMD.REPEAT] = {
		texture = {imageDir .. 'states/repeat_off.png', imageDir .. 'states/repeat_on.png'},
		stateTooltip = {tooltips.REPEAT:gsub("_STATE_", "Disabled"), tooltips.REPEAT:gsub("_STATE_", "Enabled")}
	},
	[CMD_WANT_CLOAK] = {
		texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'},
		stateTooltip = {tooltips.WANT_CLOAK:gsub("_STATE_", "Disabled"), tooltips.WANT_CLOAK:gsub("_STATE_", "Enabled")}
	},
	[CMD_CLOAK_SHIELD] = {
		texture = {imageDir .. 'states/areacloak_off.png', imageDir .. 'states/areacloak_on.png'},
		stateTooltip = {tooltips.CLOAK_SHIELD:gsub("_STATE_", "Disabled"), tooltips.CLOAK_SHIELD:gsub("_STATE_", "Enabled")}
	},
	[CMD_PRIORITY] = {
		texture = {imageDir .. 'states/wrench_low.png', imageDir .. 'states/wrench_med.png', imageDir .. 'states/wrench_high.png'},
		stateTooltip = {
			tooltips.PRIORITY:gsub("_STATE_", "Low"),
			tooltips.PRIORITY:gsub("_STATE_", "Normal"),
			tooltips.PRIORITY:gsub("_STATE_", "High")
		}
	},
	[CMD_MISC_PRIORITY] = {
		texture = {imageDir .. 'states/wrench_low_other.png', imageDir .. 'states/wrench_med_other.png', imageDir .. 'states/wrench_high_other.png'},
		stateTooltip = {
			tooltips.MISC_PRIORITY:gsub("_STATE_", "Low"),
			tooltips.MISC_PRIORITY:gsub("_STATE_", "Normal"),
			tooltips.MISC_PRIORITY:gsub("_STATE_", "High")
		}
	},
	[CMD_FACTORY_GUARD] = {
		texture = {imageDir .. 'states/autoassist_off.png',
		imageDir .. 'states/autoassist_on.png'},
		stateTooltip = {tooltips.FACTORY_GUARD:gsub("_STATE_", "Disabled"), tooltips.FACTORY_GUARD:gsub("_STATE_", "Enabled")}
	},
	[CMD_AUTO_CALL_TRANSPORT] = {
		texture = {imageDir .. 'states/auto_call_off.png', imageDir .. 'states/auto_call_on.png'},
		stateTooltip = {tooltips.AUTO_CALL_TRANSPORT:gsub("_STATE_", "Disabled"), tooltips.AUTO_CALL_TRANSPORT:gsub("_STATE_", "Enabled")}
	},
	[CMD_GLOBAL_BUILD] = {
		texture = {imageDir .. 'Bold/buildgrey.png', imageDir .. 'Bold/build_light.png'},
		stateTooltip = {tooltips.GLOBAL_BUILD:gsub("_STATE_", "Disabled"), tooltips.GLOBAL_BUILD:gsub("_STATE_", "Enabled")}
	},
	[CMD.MOVE_STATE] = {
		texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'},
		stateTooltip = {
			tooltips.MOVE_STATE:gsub("_STATE_", "Hold Position"),
			tooltips.MOVE_STATE:gsub("_STATE_", "Maneuver"),
			tooltips.MOVE_STATE:gsub("_STATE_", "Roam")
		}
	},
	[CMD.FIRE_STATE] = {
		texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'},
		stateTooltip = {
			tooltips.FIRE_STATE:gsub("_STATE_", "Hold Fire"),
			tooltips.FIRE_STATE:gsub("_STATE_", "Return Fire"),
			tooltips.FIRE_STATE:gsub("_STATE_", "Fire At Will")
		}
	},
	[CMD_RETREAT] = {
		texture = {imageDir .. 'states/retreat_off.png', imageDir .. 'states/retreat_30.png', imageDir .. 'states/retreat_60.png', imageDir .. 'states/retreat_90.png'},
		stateTooltip = {
			tooltips.RETREAT:gsub("_STATE_", "Disabled"),
			tooltips.RETREAT:gsub("_STATE_", "30%% Health"),
			tooltips.RETREAT:gsub("_STATE_", "65%% Health"),
			tooltips.RETREAT:gsub("_STATE_", "99%% Health")
		}
	},
	[CMD.IDLEMODE] = {
		texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'},
		stateTooltip = {tooltips.IDLEMODE:gsub("_STATE_", "Fly"), tooltips.IDLEMODE:gsub("_STATE_", "Land")}
	},
	[CMD_AP_FLY_STATE] = {
		texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'},
		stateTooltip = {tooltips.AP_FLY_STATE:gsub("_STATE_", "Fly"), tooltips.AP_FLY_STATE:gsub("_STATE_", "Land")}
	},
	[CMD_UNIT_BOMBER_DIVE_STATE] = {
		texture = {imageDir .. 'states/divebomb_off.png', imageDir .. 'states/divebomb_shield.png', imageDir .. 'states/divebomb_attack.png', imageDir .. 'states/divebomb_always.png'},
		stateTooltip = {
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", "Always Fly High"),
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", "Against Shields and Units"),
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", "Against Units"),
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", "Always Fly Low")
		}
	},
	[CMD_UNIT_KILL_SUBORDINATES] = {
		texture = {imageDir .. 'states/capturekill_off.png', imageDir .. 'states/capturekill_on.png'},
		stateTooltip = {tooltips.UNIT_KILL_SUBORDINATES:gsub("_STATE_", "Keep"), tooltips.UNIT_KILL_SUBORDINATES:gsub("_STATE_", "Kill")}
	},
	[CMD_PUSH_PULL] = {
		texture = {imageDir .. 'states/pull_alt.png', imageDir .. 'states/push_alt.png'},
		stateTooltip = {tooltips.PUSH_PULL:gsub("_STATE_", "Pull"), tooltips.PUSH_PULL:gsub("_STATE_", "Push")}
	},
	[CMD_DONT_FIRE_AT_RADAR] = {
		texture = {imageDir .. 'states/stealth_on.png', imageDir .. 'states/stealth_off.png'},
		stateTooltip = {tooltips.DONT_FIRE_AT_RADAR:gsub("_STATE_", "Fire"), tooltips.DONT_FIRE_AT_RADAR:gsub("_STATE_", "Hold Fire")}
	},
	[CMD_PREVENT_OVERKILL] = {
		texture = {imageDir .. 'states/overkill_off.png', imageDir .. 'states/overkill_on.png'},
		stateTooltip = {tooltips.PREVENT_OVERKILL:gsub("_STATE_", "Disabled"), tooltips.PREVENT_OVERKILL:gsub("_STATE_", "Enabled")}
	},
	[CMD.TRAJECTORY] = {
		texture = {imageDir .. 'states/traj_low.png', imageDir .. 'states/traj_high.png'},
		stateTooltip = {tooltips.TRAJECTORY:gsub("_STATE_", "Low"), tooltips.TRAJECTORY:gsub("_STATE_", "High")}
	},
	[CMD_AIR_STRAFE] = {
		texture = {imageDir .. 'states/strafe_off.png', imageDir .. 'states/strafe_on.png'},
		stateTooltip = {tooltips.AIR_STRAFE:gsub("_STATE_", "No Strafe"), tooltips.AIR_STRAFE:gsub("_STATE_", "Strafe")}
	},
	[CMD_UNIT_FLOAT_STATE] = {
		texture = {imageDir .. 'states/amph_sink.png', imageDir .. 'states/amph_attack.png', imageDir .. 'states/amph_float.png'},
		stateTooltip = {
			tooltips.UNIT_FLOAT_STATE:gsub("_STATE_", "Never Float"),
			tooltips.UNIT_FLOAT_STATE:gsub("_STATE_", "Float To Fire"),
			tooltips.UNIT_FLOAT_STATE:gsub("_STATE_", "Always Float")
		}
	},
	[CMD_SELECTION_RANK] = {
		texture = {imageDir .. 'states/selection_rank_0.png', imageDir .. 'states/selection_rank_1.png', imageDir .. 'states/selection_rank_2.png', imageDir .. 'states/selection_rank_3.png'},
		stateTooltip = {
			tooltips.SELECTION_RANK:gsub("_STATE_", "0"),
			tooltips.SELECTION_RANK:gsub("_STATE_", "1"),
			tooltips.SELECTION_RANK:gsub("_STATE_", "2"),
			tooltips.SELECTION_RANK:gsub("_STATE_", "3")
		}
	},
	[CMD_TOGGLE_DRONES] = {
		texture = {imageDir .. 'states/drones_off.png', imageDir .. 'states/drones_on.png'},
		stateTooltip = {
			tooltips.TOGGLE_DRONES:gsub("_STATE_", "Disabled"),
			tooltips.TOGGLE_DRONES:gsub("_STATE_", "Enabled"),
		}
	},
}

-- Commands that only exist in LuaUI cannot have a hidden param. Therefore those that should be hidden are placed in this table.
local widgetSpaceHidden = {
	[60] = true, -- CMD.PAGES
	[CMD_SETHAVEN] = true,
	[CMD_SET_AI_START] = true,
	[CMD_CHEAT_GIVE] = true,
	[CMD_SET_FERRY] = true,
	[CMD.MOVE] = true,
}

return factory_commands, econ_commands, defense_commands, special_commands, units_factory_commands, overrides, widgetSpaceHidden
