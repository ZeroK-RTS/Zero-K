local buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial, buildCmdUnits, cmdPosDef, factoryUnitPosDef = include("Configs/integral_menu_commands_processed.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tooltips

local imageDir = 'LuaUI/Images/commands/'

local tooltips = {
	WANT_ONOFF = WG.Translate("interface", "states_activation")..' (_STATE_)\n  '..WG.Translate("interface", "states_activation_tooltip"),
	UNIT_AI = WG.Translate("interface", "states_unitai")..' (_STATE_)\n  '..WG.Translate("interface", "states_unitai_tooltip"),
	REPEAT = WG.Translate("interface", "states_repeat")..' (_STATE_)\n  '..WG.Translate("interface", "states_repeat_tooltip"),
	WANT_CLOAK = WG.Translate("interface", "states_perscloak")..' (_STATE_)\n  '..WG.Translate("interface", "states_perscloak_tooltip"),
	CLOAK_SHIELD = WG.Translate("interface", "states_areacloak")..' (_STATE_)\n  '..WG.Translate("interface", "states_areacloak_tooltip"),
	PRIORITY = WG.Translate("interface", "states_priority")..' (_STATE_)\n  '..WG.Translate("interface", "states_priority_tooltip"),
	MISC_PRIORITY = WG.Translate("interface", "states_miscpriority")..' (_STATE_)\n  '..WG.Translate("interface", "states_miscpriority_tooltip"),
	FACTORY_GUARD = WG.Translate("interface", "states_autoassist")..' (_STATE_)\n  '..WG.Translate("interface", "states_autoassist_tooltip"),
	AUTO_CALL_TRANSPORT = WG.Translate("interface", "states_calltransport")..' (_STATE_)\n  '..WG.Translate("interface", "states_calltransport_tooltip"),
	GLOBAL_BUILD = WG.Translate("interface", "states_glbuild")..' (_STATE_)\n  '..WG.Translate("interface", "states_glbuild_tooltip"),
	MOVE_STATE = WG.Translate("interface", "states_holdposition")..' (_STATE_)\n  '..WG.Translate("interface", "states_holdposition_tooltip"),
	FIRE_STATE = WG.Translate("interface", "states_holdfire")..' (_STATE_)\n  '..WG.Translate("interface", "states_holdfire_tooltip"),
	RETREAT = WG.Translate("interface", "states_retreat")..' (_STATE_)\n  '..WG.Translate("interface", "states_retreat_tooltip"),
	IDLEMODE = WG.Translate("interface", "states_airidle")..' (_STATE_)\n  '..WG.Translate("interface", "states_airidle_tooltip"),
	AP_FLY_STATE = WG.Translate("interface", "states_factoryairidle")..' (_STATE_)\n  '..WG.Translate("interface", "states_factoryairidle_tooltip"),
	UNIT_BOMBER_DIVE_STATE = WG.Translate("interface", "states_divebombing")..' (_STATE_)\n  '..WG.Translate("interface", "states_divebombing_tooltip"),
	UNIT_KILL_SUBORDINATES = WG.Translate("interface", "states_killcap")..' (_STATE_)\n  '..WG.Translate("interface", "states_killcap_tooltip"),
	GOO_GATHER = WG.Translate("interface", "states_puppygoo")..' (_STATE_)\n  '..WG.Translate("interface", "states_puppygoo_tooltip"),
	DISABLE_ATTACK = WG.Translate("interface", "states_attackcom")..' (_STATE_)\n  '..WG.Translate("interface", "states_attackcom_tooltip"),
	PUSH_PULL = WG.Translate("interface", "states_pushpull")..' (_STATE_)\n  '..WG.Translate("interface", "states_pushpull_tooltip"),
	DONT_FIRE_AT_RADAR = WG.Translate("interface", "states_radartargeting")..' (_STATE_)\n  '..WG.Translate("interface", "states_radartargeting_tooltip"),
	PREVENT_OVERKILL = WG.Translate("interface", "states_overkill")..' (_STATE_)\n  '..WG.Translate("interface", "states_overkill_tooltip"),
	TRAJECTORY = WG.Translate("interface", "states_firearc")..' (_STATE_)\n  '..WG.Translate("interface", "states_firearc_tooltip"),
	AIR_STRAFE = WG.Translate("interface", "states_gsstrafe")..' (_STATE_)\n  '..WG.Translate("interface", "states_gsstrafe_tooltip"),
	UNIT_FLOAT_STATE = WG.Translate("interface", "states_waterfloat")..' (_STATE_)\n  '..WG.Translate("interface", "states_waterfloat_tooltip"),
	SELECTION_RANK = WG.Translate("interface", "states_selectionrank")..' (_STATE_)\n  '..WG.Translate("interface", "states_selectionrank_tooltip"),
	TOGGLE_DRONES = WG.Translate("interface", "states_drones")..' (_STATE_)\n  '..WG.Translate("interface", "states_drones_tooltip")
}

local tooltipsAlternate = {
	MOVE_STATE = WG.Translate("interface", "states_movestate")..' (_STATE_)\n  '..WG.Translate("interface", "states_movestate_tooltip"),
	FIRE_STATE = WG.Translate("interface", "states_firestate")..' (_STATE_)\n  '..WG.Translate("interface", "states_firestate_tooltip"),
}

local commandDisplayConfig = {
	[CMD.ATTACK] = { texture = imageDir .. 'Bold/attack.png', tooltip = WG.Translate("interface", "commands_forcefire")},
	[CMD.STOP] = { texture = imageDir .. 'Bold/cancel.png', tooltip = WG.Translate("interface", "commands_stop")},
	[CMD.FIGHT] = { texture = imageDir .. 'Bold/fight.png', tooltip = WG.Translate("interface", "commands_attackmove")},
	[CMD.GUARD] = { texture = imageDir .. 'Bold/guard.png'},
	[CMD.MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD_RAW_MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD.PATROL] = { texture = imageDir .. 'Bold/patrol.png', tooltip = WG.Translate("interface", "commands_patrol")},
	[CMD.WAIT] = { texture = imageDir .. 'Bold/wait.png', tooltip = WG.Translate("interface", "commands_wait")},

	[CMD.REPAIR] = {texture = imageDir .. 'Bold/repair.png', tooltip = WG.Translate("interface", "commands_repair")},
	[CMD.RECLAIM] = {texture = imageDir .. 'Bold/reclaim.png', tooltip = WG.Translate("interface", "commands_reclaim")},
	[CMD.RESURRECT] = {texture = imageDir .. 'Bold/resurrect.png', tooltip = WG.Translate("interface", "commands_res")},
	[CMD_BUILD] = {texture = imageDir .. 'Bold/build.png'},
	[CMD.MANUALFIRE] = { texture = imageDir .. 'Bold/dgun.png', tooltip = WG.Translate("interface", "commands_dgun")},
	[CMD.STOCKPILE] = {tooltip = WG.Translate("interface", "commands_stockpile")},

	[CMD.LOAD_UNITS] = { texture = imageDir .. 'Bold/load.png', tooltip = WG.Translate("interface", "commands_load")},
	[CMD.UNLOAD_UNITS] = { texture = imageDir .. 'Bold/unload.png', tooltip = WG.Translate("interface", "commands_unload")},
	[CMD.AREA_ATTACK] = { texture = imageDir .. 'Bold/areaattack.png', tooltip = WG.Translate("interface", "commands_areaattack")},

	[CMD_RAMP] = {texture = imageDir .. 'ramp.png'},
	[CMD_LEVEL] = {texture = imageDir .. 'level.png'},
	[CMD_RAISE] = {texture = imageDir .. 'raise.png'},
	[CMD_SMOOTH] = {texture = imageDir .. 'smooth.png'},
	[CMD_RESTORE] = {texture = imageDir .. 'restore.png'},
	[CMD_BUMPY] = {texture = imageDir .. 'bumpy.png'},

	[CMD_AREA_GUARD] = { texture = imageDir .. 'Bold/guard.png', tooltip = WG.Translate("interface", "commands_guard")},

	[CMD_AREA_MEX] = {texture = imageDir .. 'Bold/mex.png'},

	[CMD_JUMP] = {texture = imageDir .. 'Bold/jump.png'},

	[CMD_FIND_PAD] = {texture = imageDir .. 'Bold/rearm.png', tooltip = WG.Translate("interface", "commands_resupply")},

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
	[CMD_WANT_ONOFF] = {
		texture = {imageDir .. 'states/off.png', imageDir .. 'states/on.png'},
		stateTooltip = {tooltips.WANT_ONOFF:gsub("_STATE_", WG.Translate("interface", "states_smthng_off")), tooltips.WANT_ONOFF:gsub("_STATE_", WG.Translate("interface", "states_smthng_on"))}
	},
	[CMD_UNIT_AI] = {
		texture = {imageDir .. 'states/bulb_off.png', imageDir .. 'states/bulb_on.png'},
		stateTooltip = {tooltips.UNIT_AI:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.UNIT_AI:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))},
	},
	[CMD.REPEAT] = {
		texture = {imageDir .. 'states/repeat_off.png', imageDir .. 'states/repeat_on.png'},
		stateTooltip = {tooltips.REPEAT:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.REPEAT:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD_WANT_CLOAK] = {
		texture = {imageDir .. 'states/cloak_off.png', imageDir .. 'states/cloak_on.png'},
		stateTooltip = {tooltips.WANT_CLOAK:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.WANT_CLOAK:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD_CLOAK_SHIELD] = {
		texture = {imageDir .. 'states/areacloak_off.png', imageDir .. 'states/areacloak_on.png'},
		stateTooltip = {tooltips.CLOAK_SHIELD:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.CLOAK_SHIELD:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD_PRIORITY] = {
		texture = {imageDir .. 'states/wrench_low.png', imageDir .. 'states/wrench_med.png', imageDir .. 'states/wrench_high.png'},
		stateTooltip = {
			tooltips.PRIORITY:gsub("_STATE_", WG.Translate("interface", "states_smthng_low")),
			tooltips.PRIORITY:gsub("_STATE_", WG.Translate("interface", "states_smthng_normal")),
			tooltips.PRIORITY:gsub("_STATE_", WG.Translate("interface", "states_smthng_high"))
		}
	},
	[CMD_MISC_PRIORITY] = {
		texture = {imageDir .. 'states/wrench_low_other.png', imageDir .. 'states/wrench_med_other.png', imageDir .. 'states/wrench_high_other.png'},
		stateTooltip = {
			tooltips.MISC_PRIORITY:gsub("_STATE_", WG.Translate("interface", "states_smthng_low")),
			tooltips.MISC_PRIORITY:gsub("_STATE_", WG.Translate("interface", "states_smthng_normal")),
			tooltips.MISC_PRIORITY:gsub("_STATE_", WG.Translate("interface", "states_smthng_high"))
		}
	},
	[CMD_FACTORY_GUARD] = {
		texture = {imageDir .. 'states/autoassist_off.png',
		imageDir .. 'states/autoassist_on.png'},
		stateTooltip = {tooltips.FACTORY_GUARD:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.FACTORY_GUARD:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD_AUTO_CALL_TRANSPORT] = {
		texture = {imageDir .. 'states/auto_call_off.png', imageDir .. 'states/auto_call_on.png'},
		stateTooltip = {tooltips.AUTO_CALL_TRANSPORT:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.AUTO_CALL_TRANSPORT:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD_GLOBAL_BUILD] = {
		texture = {imageDir .. 'Bold/buildgrey.png', imageDir .. 'Bold/build_light.png'},
		stateTooltip = {tooltips.GLOBAL_BUILD:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.GLOBAL_BUILD:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD.MOVE_STATE] = {
		texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'},
		stateTooltip = {
			tooltips.MOVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled")),
			tooltips.MOVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")),
			tooltips.MOVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_movestate_roam"))
		},
		stateNameOverride = {WG.Translate("interface", "states_smthng_enabled"), WG.Translate("interface", "states_smthng_disabled"), WG.Translate("interface", "states_holdposition_roam")},
		altConfig = {
			texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'},
			stateTooltip = {
				tooltips.MOVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_movestate_hold")),
				tooltips.MOVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_movestate_manuever")),
				tooltips.MOVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_movestate_roam"))
			},
		}
	},
	[CMD.FIRE_STATE] = {
		texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'},
		stateTooltip = {
			tooltips.FIRE_STATE:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled")),
			tooltips.FIRE_STATE:gsub("_STATE_", WG.Translate("interface", "states_firestate_return")),
			tooltips.FIRE_STATE:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled"))
		},
		stateNameOverride = {WG.Translate("interface", "states_smthng_enabled"), WG.Translate("interface", "states_holdfire_return"), WG.Translate("interface", "states_smthng_disabled")},
		altConfig = {
			texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'},
			stateTooltip = {
				tooltips.FIRE_STATE:gsub("_STATE_", WG.Translate("interface", "states_firestate_hold")),
				tooltips.FIRE_STATE:gsub("_STATE_", WG.Translate("interface", "states_firestate_return")),
				tooltips.FIRE_STATE:gsub("_STATE_", WG.Translate("interface", "states_firestate_weaponsfree"))
			},
		}
	},
	[CMD_RETREAT] = {
		texture = {imageDir .. 'states/retreat_off.png', imageDir .. 'states/retreat_30.png', imageDir .. 'states/retreat_60.png', imageDir .. 'states/retreat_90.png'},
		stateTooltip = {
			tooltips.RETREAT:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")),
			tooltips.RETREAT:gsub("_STATE_", "30%% "..WG.Translate("interface", "health_absent")),
			tooltips.RETREAT:gsub("_STATE_", "65%% "..WG.Translate("interface", "health_absent")),
			tooltips.RETREAT:gsub("_STATE_", "99%% "..WG.Translate("interface", "health_absent"))
		}
	},
	[CMD.IDLEMODE] = {
		texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'},
		stateTooltip = {tooltips.IDLEMODE:gsub("_STATE_", WG.Translate("interface", "states_planeland_no")), tooltips.IDLEMODE:gsub("_STATE_", WG.Translate("interface", "states_planeland_yes"))}
	},
	[CMD_AP_FLY_STATE] = {
		texture = {imageDir .. 'states/fly_on.png', imageDir .. 'states/fly_off.png'},
		stateTooltip = {tooltips.AP_FLY_STATE:gsub("_STATE_", WG.Translate("interface", "states_planeland_no")), tooltips.AP_FLY_STATE:gsub("_STATE_", WG.Translate("interface", "states_planeland_yes"))}
	},
	[CMD_UNIT_BOMBER_DIVE_STATE] = {
		texture = {imageDir .. 'states/divebomb_off.png', imageDir .. 'states/divebomb_shield.png', imageDir .. 'states/divebomb_attack.png', imageDir .. 'states/divebomb_always.png'},
		stateTooltip = {
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_divebombing_flyhigh")),
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_divebombing_shieldandunits")),
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_divebombing_units")),
			tooltips.UNIT_BOMBER_DIVE_STATE:gsub("_STATE_", WG.Translate("interface", "states_divebombing_golow"))
		}
	},
	[CMD_UNIT_KILL_SUBORDINATES] = {
		texture = {imageDir .. 'states/capturekill_off.png', imageDir .. 'states/capturekill_on.png'},
		stateTooltip = {tooltips.UNIT_KILL_SUBORDINATES:gsub("_STATE_", WG.Translate("interface", "states_killcap_keep")), tooltips.UNIT_KILL_SUBORDINATES:gsub("_STATE_", WG.Translate("interface", "states_killcap_kill"))}
	},
	[CMD_GOO_GATHER] = {
		texture = {imageDir .. 'states/goo_off.png', imageDir .. 'states/goo_on.png', imageDir .. 'states/goo_cloak.png'},
		stateTooltip = {
			tooltips.GOO_GATHER:gsub("_STATE_", WG.Translate("interface", "states_smthng_off")),
			tooltips.GOO_GATHER:gsub("_STATE_", WG.Translate("interface", "states_puppygoo_onbutcloaked")),
			tooltips.GOO_GATHER:gsub("_STATE_", WG.Translate("interface", "states_puppygoo_onalways"))
		}
	},
	[CMD_DISABLE_ATTACK] = {
		texture = {imageDir .. 'states/disableattack_off.png', imageDir .. 'states/disableattack_on.png'},
		stateTooltip = {tooltips.DISABLE_ATTACK:gsub("_STATE_", WG.Translate("interface", "states_attackcom_allowed")), tooltips.DISABLE_ATTACK:gsub("_STATE_", WG.Translate("interface", "states_attackcom_blocked"))}
	},
	[CMD_PUSH_PULL] = {
		texture = {imageDir .. 'states/pull_alt.png', imageDir .. 'states/push_alt.png'},
		stateTooltip = {tooltips.PUSH_PULL:gsub("_STATE_", WG.Translate("interface", "states_pushpull_pull")), tooltips.PUSH_PULL:gsub("_STATE_", WG.Translate("interface", "states_pushpull_push"))}
	},
	[CMD_DONT_FIRE_AT_RADAR] = {
		texture = {imageDir .. 'states/stealth_on.png', imageDir .. 'states/stealth_off.png'},
		stateTooltip = {tooltips.DONT_FIRE_AT_RADAR:gsub("_STATE_", WG.Translate("interface", "states_radartargeting_fire")), tooltips.DONT_FIRE_AT_RADAR:gsub("_STATE_", WG.Translate("interface", "states_radartargeting_hold"))}
	},
	[CMD_PREVENT_OVERKILL] = {
		texture = {imageDir .. 'states/overkill_off.png', imageDir .. 'states/overkill_on.png'},
		stateTooltip = {tooltips.PREVENT_OVERKILL:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")), tooltips.PREVENT_OVERKILL:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled"))}
	},
	[CMD.TRAJECTORY] = {
		texture = {imageDir .. 'states/traj_low.png', imageDir .. 'states/traj_high.png'},
		stateTooltip = {tooltips.TRAJECTORY:gsub("_STATE_", WG.Translate("interface", "states_firearc_low")), tooltips.TRAJECTORY:gsub("_STATE_", WG.Translate("interface", "states_firearc_high"))}
	},
	[CMD_AIR_STRAFE] = {
		texture = {imageDir .. 'states/strafe_off.png', imageDir .. 'states/strafe_on.png'},
		stateTooltip = {tooltips.AIR_STRAFE:gsub("_STATE_", WG.Translate("interface", "states_gsstrafe_no")), tooltips.AIR_STRAFE:gsub("_STATE_", WG.Translate("interface", "states_gsstrafe_yes"))}
	},
	[CMD_UNIT_FLOAT_STATE] = {
		texture = {imageDir .. 'states/amph_sink.png', imageDir .. 'states/amph_attack.png', imageDir .. 'states/amph_float.png'},
		stateTooltip = {
			tooltips.UNIT_FLOAT_STATE:gsub("_STATE_", WG.Translate("interface", "states_waterfloat_never")),
			tooltips.UNIT_FLOAT_STATE:gsub("_STATE_", WG.Translate("interface", "states_waterfloat_tofire")),
			tooltips.UNIT_FLOAT_STATE:gsub("_STATE_", WG.Translate("interface", "states_waterfloat_always"))
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
			tooltips.TOGGLE_DRONES:gsub("_STATE_", WG.Translate("interface", "states_smthng_disabled")),
			tooltips.TOGGLE_DRONES:gsub("_STATE_", WG.Translate("interface", "states_smthng_enabled")),
		}
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Panel Configuration and Layout

local function CommandClickFunction(isInstantCommand, isStateCommand)
	local _,_, meta,_ = Spring.GetModKeyState()
	if not meta then
		return false
	end
	
	if isStateCommand then
		WG.crude.OpenPath("Hotkeys/Commands/State")
	elseif isInstantCommand then
		WG.crude.OpenPath("Hotkeys/Commands/Instant")
	else
		WG.crude.OpenPath("Hotkeys/Commands/Targeted")
	end
	WG.crude.ShowMenu() --make epic Chili menu appear.
	return true
end

local textConfig = {
	bottomLeft = {
		name = "bottomLeft",
		x = "15%",
		right = 0,
		bottom = 2,
		height = 12,
		fontsize = 12,
	},
	topLeft = {
		name = "topLeft",
		x = "12%",
		y = "11%",
		fontsize = 12,
	},
	bottomRightLarge = {
		name = "bottomRightLarge",
		right = "14%",
		bottom = "16%",
		fontsize = 14,
	},
	queue = {
		name = "queue",
		right = "18%",
		bottom = "14%",
		align = "right",
		fontsize = 16,
		height = 16,
	},
}

local buttonLayoutConfig = {
	command = {
		image = {
			x = "7%",
			y = "7%",
			right = "7%",
			bottom = "7%",
			keepAspect = true,
		},
		ClickFunction = CommandClickFunction,
	},
	build = {
		image = {
			x = "5%",
			y = "4%",
			right = "5%",
			bottom = 12,
			keepAspect = false,
		},
		tooltipPrefix = "Build",
		showCost = true
	},
	buildunit = {
		image = {
			x = "5%",
			y = "4%",
			right = "5%",
			bottom = 12,
			keepAspect = false,
		},
		tooltipPrefix = "BuildUnit",
		showCost = true
	},
	queue = {
		image = {
			x = "5%",
			y = "5%",
			right = "5%",
			height = "90%",
			keepAspect = false,
		},
		showCost = false,
		queueButton = true,
		tooltipOverride = "\255\1\255\1"..WG.Translate("interface", "leftrightmb").." \255\255\255\255: "..WG.Translate("interface", "facqueue_tooltip_1").."\n\255\1\255\1"..WG.Translate("interface", "hold").." "..WG.Translate("interface", "lmb_1").." \255\255\255\255: "..WG.Translate("interface", "facqueue_tooltip_2"),
		dragAndDrop = true,
	},
	queueWithDots = {
		image = {
			x = "5%",
			y = "5%",
			right = "5%",
			height = "90%",
			keepAspect = false,
		},
		caption = "...",
		showCost = false,
		queueButton = true,
		-- "\255\1\255\1Hold Left mouse \255\255\255\255: drag drop to different factory or position in queue\n"
		tooltipOverride = "\255\1\255\1"..WG.Translate("interface", "leftrightmb").." \255\255\255\255: "..WG.Translate("interface", "facqueue_tooltip_1").."\n\255\1\255\1"..WG.Translate("interface", "hold").." "..WG.Translate("interface", "lmb_1").." \255\255\255\255: "..WG.Translate("interface", "facqueue_tooltip_2"),
		dragAndDrop = true,
		dotDotOnOverflow = true,
	}
}

local specialButtonLayoutOverride = {}
for i = 1, 5 do
	specialButtonLayoutOverride[i] = {
		[3] = {
			buttonLayoutConfig = buttonLayoutConfig.command,
			isStructure = false,
		}
	}
end

local commandPanels = {
	{
		humanName = WG.Translate("interface", "commandpanel_orders"),
		name = "orders",
		inclusionFunction = function(cmdID)
			return cmdID >= 0 and not buildCmdSpecial[cmdID] -- Terraform
		end,
		loiterable = true,
		buttonLayoutConfig = buttonLayoutConfig.command,
	},
	{
		humanName = WG.Translate("interface", "commandpanel_econ"),
		name = "economy",
		inclusionFunction = function(cmdID)
			local position = buildCmdEconomy[cmdID]
			return position and true or false, position
		end,
		isBuild = true,
		isStructure = true,
		gridHotkeys = true,
		returnOnClick = "orders",
		optionName = "tab_economy",
		buttonLayoutConfig = buttonLayoutConfig.build,
	},
	{
		humanName = WG.Translate("interface", "commandpanel_defence"),
		name = "defence",
		inclusionFunction = function(cmdID)
			local position = buildCmdDefence[cmdID]
			return position and true or false, position
		end,
		isBuild = true,
		isStructure = true,
		gridHotkeys = true,
		returnOnClick = "orders",
		optionName = "tab_defence",
		buttonLayoutConfig = buttonLayoutConfig.build,
	},
	{
		humanName = WG.Translate("interface", "commandpanel_special"),
		name = "special",
		inclusionFunction = function(cmdID)
			local position = buildCmdSpecial[cmdID]
			return position and true or false, position
		end,
		isBuild = true,
		isStructure = true,
		notBuildRow = 3,
		gridHotkeys = true,
		returnOnClick = "orders",
		optionName = "tab_special",
		buttonLayoutConfig = buttonLayoutConfig.build,
		buttonLayoutOverride = specialButtonLayoutOverride,
	},
	{
		humanName = WG.Translate("interface", "commandpanel_factory"),
		name = "factory",
		inclusionFunction = function(cmdID)
			local position = buildCmdFactory[cmdID]
			return position and true or false, position
		end,
		isBuild = true,
		isStructure = true,
		gridHotkeys = true,
		returnOnClick = "orders",
		optionName = "tab_factory",
		buttonLayoutConfig = buttonLayoutConfig.build,
	},
	{
		humanName = WG.Translate("interface", "commandpanel_units"),
		name = "units_mobile",
		inclusionFunction = function(cmdID, factoryUnitDefID)
			return not factoryUnitDefID -- Only called if previous funcs don't
		end,
		isBuild = true,
		gridHotkeys = true,
		returnOnClick = "orders",
		optionName = "tab_units",
		buttonLayoutConfig = buttonLayoutConfig.build,
	},
	{
		humanName = WG.Translate("interface", "commandpanel_units"),
		name = "units_factory",
		inclusionFunction = function(cmdID, factoryUnitDefID)
			if not (factoryUnitDefID and buildCmdUnits[factoryUnitDefID]) then
				return false
			end
			local buildOptions = UnitDefs[factoryUnitDefID].buildOptions
			for i = 1, #buildOptions do
				if buildOptions[i] == -cmdID then
					local position = buildCmdUnits[factoryUnitDefID][cmdID]
					return position and true or false, position
				end
			end
			return false
		end,
		loiterable = true,
		factoryQueue = true,
		isBuild = true,
		hotkeyReplacement = "Orders",
		gridHotkeys = true,
		disableableKeys = true,
		buttonLayoutConfig = buttonLayoutConfig.buildunit,
	},
}

local commandPanelMap = {}
for i = 1, #commandPanels do
	commandPanelMap[commandPanels[i].name] = commandPanels[i]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Hidden Commands

local instantCommands = {
	[CMD.SELFD] = true,
	[CMD.STOP] = true,
	[CMD.WAIT] = true,
	[CMD_FIND_PAD] = true,
	[CMD_EMBARK] = true,
	[CMD_DISEMBARK] = true,
	[CMD_LOADUNITS_SELECTED] = true,
	[CMD_ONECLICK_WEAPON] = true,
	[CMD_UNIT_CANCEL_TARGET] = true,
	[CMD_STOP_NEWTON_FIREZONE] = true,
	[CMD_RECALL_DRONES] = true,
	[CMD_MORPH_UPGRADE_INTERNAL] = true,
	[CMD_UPGRADE_STOP] = true,
	[CMD_STOP_PRODUCTION] = true,
	[CMD_RESETFIRE] = true,
	[CMD_RESETMOVE] = true,
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

local factoryPlates = {
	"platecloak",
	"plateshield",
	"plateveh",
	"platehover",
	"plategunship",
	"plateplane",
	"platespider",
	"platejump",
	"platetank",
	"plateamph",
	"plateship",
}

-- Hide factory plates
for i = 1, #factoryPlates do
	local plateDefID = UnitDefNames[factoryPlates[i]].id
	widgetSpaceHidden[-plateDefID] = true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return commandPanels, commandPanelMap, commandDisplayConfig, widgetSpaceHidden, textConfig, buttonLayoutConfig, instantCommands, cmdPosDef

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

