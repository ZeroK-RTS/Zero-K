local buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial, buildCmdUnits, commandDisplayConfig, hiddenCommands = include("Configs/integral_menu_commands_old.lua")

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
			x = "9%",
			y = "9%",
			right = "9%",
			height = "82%",
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

return commandPanels, commandPanelMap, commandDisplayConfig, hiddenCommands, textConfig, buttonLayoutConfig, instantCommands
