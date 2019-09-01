VFS.Include("LuaRules/Configs/customcmds.h.lua")

--FIXME: use this table until state tooltip detection is fixed
local tooltips = {
	priority = "Priority: Set construction priority (low, normal, high)",
	retreat = "Retreat: Retreat to closest retreat point at 30/65/99% of health (right-click to disable)",
	landat = "Repair level: set the HP % at which this aircraft will go to a repair pad (0, 30, 50, 80)",
	factoryGuard = "Auto Assist: Newly built constructors automatically assist their factory",
	diveBomb = "Dive bomb (never; target under shield; any target; always (including moving))",

	fireState = "Fire State: Sets under what conditions a unit will fire without an explicit attack order (never, when attacked, always)",
	moveState = "Move State: Sets how far out of its way a unit will move to attack enemies",
	["repeat"] = "Repeat: if on the unit will continously push finished orders to the end of its order queue",
	autoCallTransport = "Automatically call transports between constructor tasks."
}


--you can put too many things into the same row, but the buttons will be squished
local buildoptions = {

	{-- factories
		-- basic
		{ "factorycloak", notSea=true },
		{ "factoryveh", notSea=true },
		{ "factoryspider",  notSea=true },

		{ "factoryship",  sea=true },

		-- support both
		{ "factoryamph" },
		{ "factoryhover" },
		{ "factorygunship" },
		{ "factoryplane" },

		-- support land-only
		{ "factoryshield",  notSea=true },
		{ "factoryjump",  notSea=true },
		{ "factorytank",  notSea=true },

		{ "striderhub" },
	},

	{-- economy
		-- common
		{ "staticmex" },
		{ "energywind" },-- wind
		{ "energysolar",  notSea=true },
		{ "staticcon" },-- caretaker
		{ "energygeo",  notSea=true },
		{ "staticrearm" },-- repair pad

		-- adv
		{ "energypylon",  tech=2 },-- pylon
		{ "staticstorage",  tech=2 },-- storage
		{ "energyfusion",  tech=2 },
		{ "energysingu",  tech=2 },-- singularity
	},


	{-- point_defense
		{ "turretlaser",  notSea=true },
		{ "turretemp",  notSea=true },-- Faraday
		{ "turrettorp",  notLand=true },-- you can build it on land, but torpedoes are only useful around water.
		{ "turretriot" },-- Stardust
		{ "turretimpulse",  notSea=true },-- newton
		{ "turretgauss",  notSea=true },-- Popup gauss
		{ "turretheavylaser",  tech=2 },-- peoples should prefer Stardust, Faraday, Newton, Urchin more.
		{ "turretheavy",  tech=2, notSea=true },
		{ "turretantiheavy",  tech=3, notSea=true },
		{ "staticarty",  tech=3, notSea=true },
		{ "staticantinuke",  tech=3, notSea=true },-- Antinuke
	},

	{-- air_defense
		{ "corr" },-- mt
		{ "turretaalaser" },
		{ "turretaaclose" },-- hacksaw
		{ "turretaaflak" },

		{ "turretaafar",  tech=2 },-- chainsaw
		{ "turretaaheavy",  tech=3 },
	},

	{-- special
		{ "staticradar" },
		{ "staticheavyradar",  tech=2 },
		{ "staticshield",  tech=2 },-- Aegis
		{ "staticjammer",  tech=2 },-- Cornea
		{ "staticmissilesilo",  tech=2 },
		{ CMD_RAMP,  tech=3 },
		{ CMD_LEVEL,  tech=3 },
		{ CMD_RAISE,  tech=3 },
		{ CMD_SMOOTH,  tech=3 },
		{ CMD_RESTORE,  tech=3 },
		{ CMD_BUMPY,  tech=3 },
		{ "staticheavyarty",  tech=3, notSea=true },
		{ "staticnuke",  tech=3, notSea=true },-- Nuke
	},

	{-- super
		{ "zenith",  tech=4, notSea=true },
		{ "raveparty",  tech=4, notSea=true },
		{ "mahlazer",  tech=4, notSea=true },
	},
}

--manual entries not needed; menu has autodetection
local common_commands = {}
local states_commands = {}

local land_commands = {}
local sea_commands = {}
local advland_commands = {}
local advsea_commands = {}
local special_commands = {}

if true then
	local i = 1
	local land = 0
	local sea = 0
	local advland = 0
	local advsea = 0
	local special = 0
	for _, group in pairs(buildoptions) do
		for _, unit in pairs(group) do
			local udef = (UnitDefNames[unit[1]])
			if udef then
				if not unit.tech or unit.tech == 1 then
					if not unit.notLand then
						land=land+1
						land_commands[-udef.id] = { order=land }
					end
					if not unit.notSea then
						sea=sea+1
						sea_commands[-udef.id] = { order=sea }
					end
				elseif unit.tech == 2 then
					if not unit.notLand then
						advland=advland+1
						advland_commands[-udef.id] = { order=advland }
					end
					if not unit.notSea then
						advsea=advsea+1
						advsea_commands[-udef.id] = { order=advsea }
					end
				elseif unit.tech == 3 or unit.tech == 4 then-- in the same list, because we have only a few special units.
						special=special+1
					special_commands[-udef.id] = { order=special }
				end
			end
		end
--		land=land+1 sea=sea+1 advland=advland+1 advsea=advsea+1 special=special+1
--		land_commands['spacer_' .. i] = { order=land, spacer=true }
--		sea_commands['spacer_' .. i] = { order=sea, spacer=true }
--		advland_commands['spacer_' .. i] = { order=advland, spacer=true }
--		advsea_commands['spacer_' .. i] = { order=advsea, spacer=true }
--		special_commands['spacer_' .. i] = { order=special, spacer=true }
--		i = i + 1
	end
end

-- Global commands defined here - they have cmdDesc format +
local globalCommands = {
	--[[{
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
-- You can specify texture, caption,tooltip, color
local imageDir = 'LuaUI/Images/commands/'

local overrides = {
	[CMD.ATTACK] = { texture = imageDir .. 'Bold/attack.png'},
	[CMD.STOP] = { texture = imageDir .. 'Bold/cancel.png'},
	[CMD.FIGHT] = { texture = imageDir .. 'Bold/fight.png'},
	[CMD.GUARD] = { texture = imageDir .. 'Bold/guard.png'},
	[CMD.MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD_RAW_MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD.PATROL] = { texture = imageDir .. 'Bold/patrol.png'},
	[CMD.WAIT] = { texture = imageDir .. 'Bold/wait.png'},

	[CMD.REPAIR] = {texture = imageDir .. 'Bold/repair.png'},
	[CMD.RECLAIM] = {texture = imageDir .. 'Bold/reclaim.png'},
	[CMD.RESURRECT] = {texture = imageDir .. 'Bold/resurrect.png'},
	[CMD_BUILD] = {caption = '\255\0\255\0B', texture = imageDir .. 'Bold/build.png'},
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

	[CMD_AREA_MEX] = {caption = '', texture = imageDir .. 'Bold/mex.png'},

	[CMD_JUMP] = {texture = imageDir .. 'Bold/jump.png'},

	[CMD_FIND_PAD] = {caption = '', texture = imageDir .. 'Bold/rearm.png'},

	[CMD_EMBARK] = {caption = '', texture = imageDir .. 'Bold/embark.png'},
	[CMD_DISEMBARK] = {caption = ' ', texture = imageDir .. 'Bold/disembark.png'},

	[CMD_ONECLICK_WEAPON] = {},--texture = imageDir .. 'Bold/action.png'},
	[CMD_UNIT_SET_TARGET] = {texture = imageDir .. 'Bold/action.png'},

	[CMD_ABANDON_PW] = {caption= '', texture = 'LuaUI/Images/Crystal_Clear_action_flag_white.png'},

	[CMD_PLACE_BEACON] = {caption= '', texture = imageDir .. 'Bold/drop_beacon.png'},

	[CMD_RECALL_DRONES] = {caption= '', texture = imageDir .. 'Bold/recall_drones.png'},

	-- states
	[CMD_WANT_ONOFF] = { texture = {imageDir .. 'states/off.png', imageDir .. 'states/on.png'}, caption=''},
	[CMD_UNIT_AI] = { texture = {imageDir .. 'states/bulb_off.png', imageDir .. 'states/bulb_on.png'}, caption=''},
	[CMD.REPEAT] = { texture = {imageDir .. 'states/repeat_off.png', imageDir .. 'states/repeat_on.png'}, caption='', tooltip = tooltips["repeat"]},
	[CMD.CLOAK] = { texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'},
		caption ='', tooltip =  'Desired cloak state'},
	[CMD_CLOAK_SHIELD] = { texture = {imageDir .. 'states/areacloak_off.png', imageDir .. 'states/areacloak_on.png'},
		caption ='',	tooltip = 'Area Cloaker State'},
	[CMD_STEALTH] = { texture = {imageDir .. 'states/stealth_off.png', imageDir .. 'states/stealth_on.png'}, caption ='' },
	[CMD_PRIORITY] = { texture = {imageDir .. 'states/wrench_low.png', imageDir .. 'states/wrench_med.png', imageDir .. 'states/wrench_high.png'},
		caption='', tooltip = tooltips.priority},
	[CMD_FACTORY_GUARD] = { texture = {imageDir .. 'states/autoassist_off.png', imageDir .. 'states/autoassist_on.png'},
		caption='', tooltip = tooltips.factoryGuard,},
	[CMD_AUTO_CALL_TRANSPORT] = { texture = {imageDir .. 'states/auto_call_off.png', imageDir .. 'states/auto_call_on.png'},
		text='', tooltip = tooltips.autoCallTransport,},
	[CMD.MOVE_STATE] = { texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'}, caption='', tooltip = tooltips.moveState},
	[CMD.FIRE_STATE] = { texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'}, caption='', tooltip = tooltips.fireState},
	[CMD_RETREAT] = { texture = {imageDir .. 'states/retreat_off.png', imageDir .. 'states/retreat_30.png', imageDir .. 'states/retreat_60.png', imageDir .. 'states/retreat_90.png'},
		caption='', tooltip = tooltips.retreat,},
	[CMD.IDLEMODE] = { texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'}, caption=''},
	[CMD_AP_FLY_STATE] = { texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'}, caption=''},
	[CMD.AUTOREPAIRLEVEL] = { texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_30.png', imageDir .. 'states/landat_50.png', imageDir .. 'states/landat_80.png'},
		caption = '', tooltip = tooltips.landat,},
	[CMD_AP_AUTOREPAIRLEVEL] = { texture = {imageDir .. 'states/landat_off.png', imageDir .. 'states/landat_30.png', imageDir .. 'states/landat_50.png', imageDir .. 'states/landat_80.png'},
		caption = ''},
	[CMD_UNIT_BOMBER_DIVE_STATE] = { texture = {imageDir .. 'states/divebomb_off.png', imageDir .. 'states/divebomb_shield.png', imageDir .. 'states/divebomb_attack.png', imageDir .. 'states/divebomb_always.png'},
		caption = '', tooltip = tooltips.diveBomb,},
	[CMD_UNIT_KILL_SUBORDINATES] = {texture = {imageDir .. 'states/capturekill_off.png', imageDir .. 'states/capturekill_on.png'}, caption=''},
	[CMD_DISABLE_ATTACK] = {texture = {imageDir .. 'states/disableattack_off.png', imageDir .. 'states/disableattack_on.png'}, caption=''},
	[CMD_PUSH_PULL] = {texture = {imageDir .. 'states/pull_alt.png', imageDir .. 'states/push_alt.png'}, caption=''},
	[CMD_DONT_FIRE_AT_RADAR] = {texture = {imageDir .. 'states/stealth_on.png', imageDir .. 'states/stealth_off.png'}, caption=''},
	[CMD.TRAJECTORY] = { texture = {imageDir .. 'states/traj_low.png', imageDir .. 'states/traj_high.png'}, caption=''},
	[CMD_AIR_STRAFE] = { texture = {imageDir .. 'states/strafe_off.png', imageDir .. 'states/strafe_on.png'}, caption=''},
	[CMD_UNIT_FLOAT_STATE] = { texture = {imageDir .. 'states/amph_sink.png', imageDir .. 'states/amph_attack.png', imageDir .. 'states/amph_float.png'}, caption=''},
	[CMD_SELECTION_RANK] = { texture = {imageDir .. 'states/selection_rank_0.png', imageDir .. 'states/selection_rank_1.png', imageDir .. 'states/selection_rank_2.png', imageDir .. 'states/selection_rank_3.png'}, text=''},
	}

-- noone really knows what this table does but it's needed for epic menu to get the hotkey
local custom_cmd_actions = {	-- states are 2, not states are 1

	--SPRING COMMANDS

	selfd=1,
	attack=1,
	stop=1,
	fight=1,
	guard=1,
	move=1,
	patrol=1,
	wait=1,
	repair=1,
	reclaim=1,
	resurrect=1,
	manualfire=1,
	loadunits=1,
	unloadunits=1,
	areaattack=1,

	rawmove=1,

	-- states
	wantonoff=2,
	['repeat']=2,
	cloak=2,
	movestate=2,
	firestate=2,
	idlemode=2,
	autorepairlevel=2,


	--CUSTOM COMMANDS

	sethaven=1,
	--build=1,
	areamex=1,
	disembark=1,
	mine=1,
	build=1,
	jump=1,
	find_pad=1,
	embark=1,
	disembark=1,
	oneclickwep=1,
	settarget=1,
	canceltarget=1,
	setferry=1,
	radialmenu=1,
	placebeacon=1,
	evacuate=1,

	-- terraform
	rampground=1,
	levelground=1,
	raiseground=1,
	smoothground=1,
	restoreground=1,
	--terraform_internal=1,

	resetfire=1,
	resetmove=1,

	--states
--	stealth=2, --no longer applicable
	cloak_shield=2,
	retreat=2,
	['luaui noretreat']=2,
	priority=2,
	ap_fly_state=2,
	ap_autorepairlevel=2,
	floatstate=2,
	dontfireatradar=2,
	antinukezone=2,
	unitai=2,
	unit_kill_subordinates=2,
	disableattack=2,
	pushpull=2,
	autoassist=2,
	autocalltransport=2,
	airstrafe=2,
	divestate=2,
	selection_rank = 2,
}


return common_commands, states_commands, land_commands, sea_commands, advland_commands, advsea_commands, special_commands, globalCommands, overrides, custom_cmd_actions
