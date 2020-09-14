local buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial, buildCmdUnits, commandDisplayConfig, hiddenCommands = include("Configs/integral_menu_commands.lua", nil, VFS.RAW_FIRST)

local function CommandClickFunction()
	local _,_, meta,_ = Spring.GetModKeyState()
	if not meta then
		return false
	end
	WG.crude.OpenPath("Hotkeys/Commands")
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

local simpleModeCull = {
	[CMD.SELFD] = true,
	[CMD.WAIT] = true,
	--[CMD_EMBARK] = true,
	[CMD_DISEMBARK] = true,
	[CMD.AREA_ATTACK] = true,
	[CMD_AREA_GUARD] = true,
	[CMD_UNIT_SET_TARGET_CIRCLE] = true,
	[CMD_UNIT_CANCEL_TARGET] = true,
	--[CMD_STOP_PRODUCTION] = true,
	
	-- states
	--[CMD_RETREAT] = true,
	--[CMD_WANT_ONOFF] = true,
	--[CMD.REPEAT] = true,
	--[CMD_WANT_CLOAK] = true,
	--[CMD.TRAJECTORY] = true,
	--[CMD_UNIT_FLOAT_STATE] = true,
	--[CMD_PRIORITY] = true,
	--[CMD_MISC_PRIORITY] = true,
	--[CMD_FACTORY_GUARD] = true,
	--[CMD_TOGGLE_DRONES] = true,
	--[CMD_PUSH_PULL] = true,
	--[CMD.IDLEMODE] = true,
	--[CMD_AP_FLY_STATE] = true,
	[CMD_UNIT_AI] = true,
	--[CMD_CLOAK_SHIELD] = true,
	[CMD_AUTO_CALL_TRANSPORT] = true,
	[CMD_GLOBAL_BUILD] = true,
	--[CMD.MOVE_STATE] = true,
	--[CMD.FIRE_STATE] = true,
	[CMD_UNIT_BOMBER_DIVE_STATE] = true,
	[CMD_UNIT_KILL_SUBORDINATES] = true,
	--[CMD_GOO_GATHER] = true,
	[CMD_DISABLE_ATTACK] = true,
	[CMD_DONT_FIRE_AT_RADAR] = true,
	[CMD_PREVENT_OVERKILL] = true,
	[CMD_AIR_STRAFE] = true,
	[CMD_SELECTION_RANK] = true,
}

local cmdPosDef = {
	[CMD.STOP]          = {pos = 1, priority = 1},
	[CMD.FIGHT]         = {pos = 1, priority = 2},
	[CMD_RAW_MOVE]      = {pos = 1, priority = 3},
	[CMD.PATROL]        = {pos = 1, priority = 4},
	[CMD.ATTACK]        = {pos = 1, priority = 5},
	[CMD_JUMP]          = {pos = 1, priority = 6},
	[CMD_AREA_GUARD]    = {pos = 1, priority = 10},
	[CMD.AREA_ATTACK]   = {pos = 1, priority = 11},
	
	[CMD_UPGRADE_UNIT]  = {pos = 7, priority = -8},
	[CMD_UPGRADE_STOP]  = {pos = 7, priority = -7},
	[CMD_MORPH]         = {pos = 7, priority = -6},
	
	[CMD_STOP_NEWTON_FIREZONE] = {pos = 7, priority = -4},
	[CMD_NEWTON_FIREZONE]      = {pos = 7, priority = -3},
	
	[CMD.MANUALFIRE]      = {pos = 7, priority = 0.1},
	[CMD_PLACE_BEACON]    = {pos = 7, priority = 0.2},
	[CMD_ONECLICK_WEAPON] = {pos = 7, priority = 0.24},
	[CMD.STOCKPILE]       = {pos = 7, priority = 0.25},
	[CMD_ABANDON_PW]      = {pos = 7, priority = 0.3},
	[CMD_GBCANCEL]        = {pos = 7, priority = 0.4},
	[CMD_STOP_PRODUCTION] = {pos = 7, priority = 0.7},
	
	[CMD_BUILD]         = {pos = 7, priority = 0.8},
	[CMD_AREA_MEX]      = {pos = 7, priority = 1},
	[CMD.REPAIR]        = {pos = 7, priority = 2},
	[CMD.RECLAIM]       = {pos = 7, priority = 3},
	[CMD.RESURRECT]     = {pos = 7, priority = 4},
	[CMD.WAIT]          = {pos = 7, priority = 5},
	[CMD_FIND_PAD]      = {pos = 7, priority = 6},
	
	[CMD.LOAD_UNITS]    = {pos = 7, priority = 7},
	[CMD.UNLOAD_UNITS]  = {pos = 7, priority = 8},
	[CMD_RECALL_DRONES] = {pos = 7, priority = 10},
	
	[CMD_UNIT_SET_TARGET_CIRCLE] = {pos = 13, priority = 2},
	[CMD_UNIT_CANCEL_TARGET]     = {pos = 13, priority = 2},
	[CMD_EMBARK]        = {pos = 13, priority = 5},
	[CMD_DISEMBARK]     = {pos = 13, priority = 6},

	-- States
	[CMD.REPEAT]           = {pos = 1, priority = 1},
	[CMD_RETREAT]          = {pos = 1, priority = 2},
	
	[CMD.MOVE_STATE]       = {pos = 6, posSimple = 5, priority = 1},
	[CMD.FIRE_STATE]       = {pos = 6, posSimple = 5, priority = 2},
	[CMD_FACTORY_GUARD]    = {pos = 6, posSimple = 5, priority = 3},
	
	[CMD_SELECTION_RANK]   = {pos = 5, priority = 1},
	
	[CMD_PRIORITY]         = {pos = 1, priority = 10},
	[CMD_MISC_PRIORITY]    = {pos = 1, priority = 11},
	[CMD_CLOAK_SHIELD]     = {pos = 1, priority = 11.5},
	[CMD_WANT_CLOAK]       = {pos = 1, priority = 11.6},
	[CMD_WANT_ONOFF]       = {pos = 1, priority = 13},
	[CMD.TRAJECTORY]       = {pos = 1, priority = 14},
	[CMD_UNIT_FLOAT_STATE] = {pos = 1, priority = 15},
	[CMD_TOGGLE_DRONES]    = {pos = 1, priority = 16},
	[CMD_PUSH_PULL]        = {pos = 1, priority = 17},
	[CMD.IDLEMODE]         = {pos = 1, priority = 18},
	[CMD_AP_FLY_STATE]     = {pos = 1, priority = 19},
	[CMD_AUTO_CALL_TRANSPORT] = {pos = 1, priority = 21},

}

return commandPanels, commandPanelMap, commandDisplayConfig, hiddenCommands, textConfig, buttonLayoutConfig, instantCommands, simpleModeCull, cmdPosDef
