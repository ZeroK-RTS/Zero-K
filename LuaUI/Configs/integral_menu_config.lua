local buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial, buildCmdUnits, cmdPosDef, factoryUnitPosDef = include("Configs/integral_menu_commands_processed.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tooltips

local imageDir = 'LuaUI/Images/commands/'

local tooltips = {
	WANT_ONOFF = "Activation (_STATE_)\n  Toggles unit abilities such as radar, shield charge, and radar jamming.",
	UNIT_AI = "Unit AI (_STATE_)\n  Move intelligently in combat.",
	REPEAT = "Repeat (_STATE_)\n  Loop factory construction, or the command queue for units.",
	WANT_CLOAK = "Cloak (_STATE_)\n  Turn invisible. Disrupted by damage, firing, abilities, and nearby enemies.",
	CLOAK_SHIELD = "Area Cloaker (_STATE_)\n  Cloak all friendly units in the area. Does not apply to structures or shield bearers.",
	PRIORITY = "Construction Priority (_STATE_)\n  Higher priority construction takes resources before lower priorities.",
	MISC_PRIORITY = "Misc. Priority (_STATE_)\n  Priority for other resource use, such as morph, stockpile and radar.",
	FACTORY_GUARD = "Auto Assist (_STATE_)\n  Newly built constructors stay to assist and boost production.",
	AUTO_CALL_TRANSPORT = "Call Transports (_STATE_)\n  Automatically call transports between constructor tasks.",
	GLOBAL_BUILD = "Global Build Command (_STATE_)\n  Sets constructors to execute global build orders.",
	MOVE_STATE = "Hold Position (_STATE_)\n  Prevent units from moving when idle. States are persistent and togglable.",
	FIRE_STATE = "Hold Fire (_STATE_)\n  Prevent units from firing unless a direct command or target is set.",
	RETREAT = "Retreat (_STATE_)\n  Retreat to the closest Airpad or Retreat Zone (placed via the top left of the screen). Right click to disable.",
	IDLEMODE = "Air Idle State (_STATE_)\n  Set whether aircraft land when idle.",
	AP_FLY_STATE = "Air Factory Idle State (_STATE_)\n  Set whether produced aircraft land when idle.",
	UNIT_BOMBER_DIVE_STATE = "Bomber Dive State (_STATE_)\n  Set when Ravens dive.",
	UNIT_KILL_SUBORDINATES = "Kill Captured (_STATE_)\n  Set whether to kill captured units.",
	GOO_GATHER = "Puppy Replication (_STATE_)\n  Set whether Puppies use nearby wrecks to make more Puppies.",
	DISABLE_ATTACK = "Allow Attack Commands (_STATE_)\n  Set whether the unit responds to attack commands.",
	PUSH_PULL = "Impulse Mode (_STATE_)\n  Set whether gravity guns push or pull.",
	DONT_FIRE_AT_RADAR = "Fire At Radar State (_STATE_)\n  Set whether precise units with high reload time fire at radar dots.",
	PREVENT_OVERKILL = "Overkill Prevention (_STATE_)\n  Prevents units from shooting at already doomed enemies.",
	TRAJECTORY = "Trajectory (_STATE_)\n  Set whether units fire at a high or low arc.",
	AIR_STRAFE = "Gunship Strafe (_STATE_)\n  Set whether gunships strafe when fighting.",
	UNIT_FLOAT_STATE = "Float State (_STATE_)\n  Set when certain amphibious units float to the surface.",
	SELECTION_RANK = "Selection Rank (_STATE_)\n  Priority for selection filtering.",
	TOGGLE_DRONES = "Drone Construction (_STATE_)\n  Toggle drone creation."
}

local tooltipsAlternate = {
	MOVE_STATE = "Move State (_STATE_)\n  Sets how far out of its way a unit will move to attack enemies.",
	FIRE_STATE = "Fire State (_STATE_)\n  Sets when a unit will automatically shoot.",
}

local commandDisplayConfig = {
	[CMD.ATTACK] = { texture = imageDir .. 'Bold/attack.png', tooltip = "Force Fire: Shoot at a particular target. Units will move to find a clear shot."},
	[CMD.STOP] = { texture = imageDir .. 'Bold/cancel.png', tooltip = "Stop: Halt the unit and clear its command queue."},
	[CMD.FIGHT] = { texture = imageDir .. 'Bold/fight.png', tooltip = "Attack Move: Move to a position engaging targets along the way."},
	[CMD.GUARD] = { texture = imageDir .. 'Bold/guard.png'},
	[CMD.MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD_RAW_MOVE] = { texture = imageDir .. 'Bold/move.png'},
	[CMD.PATROL] = { texture = imageDir .. 'Bold/patrol.png', tooltip = "Patrol: Attack Move back and forth between one or more waypoints."},
	[CMD.WAIT] = { texture = imageDir .. 'Bold/wait.png', tooltip = "Wait: Pause the units command queue and have it hold its current position."},

	[CMD.REPAIR] = {texture = imageDir .. 'Bold/repair.png', tooltip = "Repair: Assist construction or repair a unit. Click and drag for area repair."},
	[CMD.RECLAIM] = {texture = imageDir .. 'Bold/reclaim.png', tooltip = "Reclaim: Take resources from a wreck. Click and drag for area reclaim."},
	[CMD.RESURRECT] = {texture = imageDir .. 'Bold/resurrect.png', tooltip = "Resurrect: Spend energy to turn a wreck into a unit."},
	[CMD_BUILD] = {texture = imageDir .. 'Bold/build.png'},
	[CMD.MANUALFIRE] = { texture = imageDir .. 'Bold/dgun.png', tooltip = "Fire Special Weapon: Fire the unit's special weapon."},
	[CMD.STOCKPILE] = {tooltip = "Stockpile: Queue missile production. Right click to reduce the queue."},

	[CMD.LOAD_UNITS] = { texture = imageDir .. 'Bold/load.png', tooltip = "Load: Pick up a unit. Click and drag to load unit in an area."},
	[CMD.UNLOAD_UNITS] = { texture = imageDir .. 'Bold/unload.png', tooltip = "Unload: Set down a carried unit. Click and drag to unload in an area."},
	[CMD.AREA_ATTACK] = { texture = imageDir .. 'Bold/areaattack.png', tooltip = "Area Attack: Indiscriminately bomb the terrain in an area."},

	[CMD_RAMP] = {texture = imageDir .. 'ramp.png'},
	[CMD_LEVEL] = {texture = imageDir .. 'level.png'},
	[CMD_RAISE] = {texture = imageDir .. 'raise.png'},
	[CMD_SMOOTH] = {texture = imageDir .. 'smooth.png'},
	[CMD_RESTORE] = {texture = imageDir .. 'restore.png'},
	[CMD_BUMPY] = {texture = imageDir .. 'bumpy.png'},

	[CMD_AREA_GUARD] = { texture = imageDir .. 'Bold/guard.png', tooltip = "Guard: Protect the target and assist its production."},

	[CMD_AREA_MEX] = {texture = imageDir .. 'Bold/mex.png'},

	[CMD_JUMP] = {texture = imageDir .. 'Bold/jump.png'},

	[CMD_FIND_PAD] = {texture = imageDir .. 'Bold/rearm.png', tooltip = "Resupply: Return to nearest Airpad for repairs and, for bombers, ammo."},

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
		stateTooltip = {tooltips.WANT_ONOFF:gsub("_STATE_", "Off"), tooltips.WANT_ONOFF:gsub("_STATE_", "On")}
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
			tooltips.MOVE_STATE:gsub("_STATE_", "Enabled"),
			tooltips.MOVE_STATE:gsub("_STATE_", "Disabled"),
			tooltips.MOVE_STATE:gsub("_STATE_", "Roam")
		},
		stateNameOverride = {"Enabled", "Disabled", "Roam (not in toggle)"},
		altConfig = {
			texture = {imageDir .. 'states/move_hold.png', imageDir .. 'states/move_engage.png', imageDir .. 'states/move_roam.png'},
			stateTooltip = {
				tooltipsAlternate.MOVE_STATE:gsub("_STATE_", "Hold Position"),
				tooltipsAlternate.MOVE_STATE:gsub("_STATE_", "Maneuver"),
				tooltipsAlternate.MOVE_STATE:gsub("_STATE_", "Roam")
			},
		}
	},
	[CMD.FIRE_STATE] = {
		texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'},
		stateTooltip = {
			tooltips.FIRE_STATE:gsub("_STATE_", "Enabled"),
			tooltips.FIRE_STATE:gsub("_STATE_", "Return Fire"),
			tooltips.FIRE_STATE:gsub("_STATE_", "Disabled")
		},
		stateNameOverride = {"Enabled", "Return Fire (not in toggle)", "Disabled"},
		altConfig = {
			texture = {imageDir .. 'states/fire_hold.png', imageDir .. 'states/fire_return.png', imageDir .. 'states/fire_atwill.png'},
			stateTooltip = {
				tooltipsAlternate.FIRE_STATE:gsub("_STATE_", "Hold Fire"),
				tooltipsAlternate.FIRE_STATE:gsub("_STATE_", "Return Fire"),
				tooltipsAlternate.FIRE_STATE:gsub("_STATE_", "Fire At Will")
			},
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
	[CMD_GOO_GATHER] = {
		texture = {imageDir .. 'states/goo_off.png', imageDir .. 'states/goo_on.png', imageDir .. 'states/goo_cloak.png'},
		stateTooltip = {
			tooltips.GOO_GATHER:gsub("_STATE_", "Off"),
			tooltips.GOO_GATHER:gsub("_STATE_", "On except when cloaked"),
			tooltips.GOO_GATHER:gsub("_STATE_", "On always")
		}
	},
	[CMD_DISABLE_ATTACK] = {
		texture = {imageDir .. 'states/disableattack_off.png', imageDir .. 'states/disableattack_on.png'},
		stateTooltip = {tooltips.DISABLE_ATTACK:gsub("_STATE_", "Allowed"), tooltips.DISABLE_ATTACK:gsub("_STATE_", "Blocked")}
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
		tooltipOverride = "\255\1\255\1Left/Right click \255\255\255\255: Add to/subtract from queue\n\255\1\255\1Hold Left mouse \255\255\255\255: Drag to a different position in queue",
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
		tooltipOverride = "\255\1\255\1Left/Right click \255\255\255\255: Add to/subtract from queue\n\255\1\255\1Hold Left mouse \255\255\255\255: Drag to a different position in queue",
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
		humanName = "Orders",
		name = "orders",
		inclusionFunction = function(cmdID)
			return cmdID >= 0 and not buildCmdSpecial[cmdID] -- Terraform
		end,
		loiterable = true,
		buttonLayoutConfig = buttonLayoutConfig.command,
	},
	{
		humanName = "Econ",
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
		humanName = "Defence",
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
		humanName = "Special",
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
		humanName = "Factory",
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
		humanName = "Units",
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
		humanName = "Units",
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

