--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Chili Integral Menu 2",
		desc      = "Integral Command Menu Improved",
		author    = "GoogleFrog",
		date      = "8 Novemember 2016",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge-10,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Configuration

include("keysym.h.lua")

-- Chili classes
local Chili
local Button
local Label
local Colorbars
local Checkbox
local Window
local Panel
local StackPanel
local TextBox
local Image
local Progressbar
local Control

-- Chili instances
local screen0

local emptyTable = {}

local MIN_HEIGHT = 80
local MIN_WIDTH = 200
local COMMAND_SECTION_WIDTH = 74 -- percent
local STATE_SECTION_WIDTH = 24 -- percent

local SELECT_BUTTON_COLOR = {0.8, 0, 0, 1}
local SELECT_BUTTON_FOCUS_COLOR = {0.8, 0, 0, 1}

-- Defined upon learning the appropriate colors
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR

local NO_TEXT = ""

local EPIC_NAME = "epic_chili_integral_menu_2_"
local EPIC_NAME_UNITS = "epic_chili_integral_menu_2_tab_units"

local _, _, buildCmdFactory, buildCmdEconomy, buildCmdDefence, buildCmdSpecial,_ , commandDisplayConfig, _, hiddenCommands = include("Configs/integral_menu_commands.lua")

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
		}
	},
	build = {
		image = {
			x = "5%",
			y = "3%",
			right = "5%",
			bottom = 13,
			keepAspect = false,
		},
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
		-- "\255\1\255\1Hold Left mouse \255\255\255\255: drag drop to different factory or position in queue\n"
		tooltipOverride = "\255\1\255\1Left/Right click \255\255\255\255: Add to/subtract from queue",
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Options

options_path = 'Settings/HUD Panels/Command Panel2'
options_order = { 
	'tab_economy', 'tab_defence', 'tab_special','tab_factory','tab_units'
}
options = {
	tab_economy = {
		name = "Economy Tab",
		desc = "Switches to economy tab.",
		type = 'button',
	},
	tab_defence = {
		name = "Defence Tab",
		desc = "Switches to defence tab.",
		type = 'button',
	},
	tab_special = {
		name = "Special Tab",
		desc = "Switches to special tab.",
		type = 'button',
	},
	tab_factory = {
		name = "Factory Tab",
		desc = "Switches to factory tab.",
		type = 'button',
	},
	tab_units = {
		name = "Units Tab",
		desc = "Switches to units tab.",
		type = 'button',
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Very Global Globals

local buttonsByCommand = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility

local function GenerateGridKeyMap(name)
	local gridMap = include("Configs/keyboard_layout.lua")[name]
	local ret = {}
	for i = 1, 3 do
		for j = 1, 6 do
			ret[KEYSYMS[gridMap[i][j]]] = {i, j}
		end
	end
	return ret, gridMap
end

local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
end

local function DeleteCommandsFromPosition(cmdID, factoryUnitID, queuePosition, inputMult, reinsertPosition)
	local alreadyRemovedTag = {}
	local commands = Spring.GetFactoryCommands(factoryUnitID)
	
	if not commands then
		return
	end
	-- The start of the queue can have a stop command?
	if commands[1] and commands[1].id > 0 then
		queuePosition = queuePosition + 1
	end
	
	if reinsertPosition == 0 and commands[1] then
		local startCommandID = (commands[1].id > 0 and commands[2] and commands[2].id) or commands[1].id
		if startCommandID == cmdID then
			reinsertPosition = 1
		end
	end
	Spring.Echo("reinsertPosition", reinsertPosition)

	-- delete from back so that the order is not canceled while under construction
	local i = queuePosition
	local j = 0
	while commands[i] and commands[i].id == cmdID and ((not inputMult) or j < inputMult) do
		Spring.GiveOrderToUnit(factoryUnitID, CMD.REMOVE, {commands[i].tag}, {"ctrl"})
		if reinsertPosition then
			Spring.GiveOrderToUnit(factoryUnitID, CMD.INSERT, {reinsertPosition, cmdID, 0}, {"alt", "ctrl"})
		end
		alreadyRemovedTag[commands[i].tag] = true
		j = j + 1
		i = i - 1
	end
end

local function QueueClickFunc(eft, right, alt, ctrl, meta, shift, cmdID, factoryUnitID, queuePosition)
	if alt then
		DeleteCommandsFromPosition(cmdID, factoryUnitID, queuePosition, false, 0)
		return
	end

	local inputMult = 1*(shift and 5 or 1)*(ctrl and 20 or 1)
	if not right then
		for i = 1, inputMult do
			Spring.GiveOrderToUnit(factoryUnitID, CMD.INSERT, {queuePosition, cmdID, 0 }, {"alt", "ctrl"})
		end
		return
	end
	
	DeleteCommandsFromPosition(cmdID, factoryUnitID, queuePosition, inputMult)
end

local function ClickFunc(mouse, cmdID, isStructure, factoryUnitID, queuePosition)
	local left, right = mouse == 1, mouse == 3
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if factoryUnitID then
		QueueClickFunc(left, right, alt, ctrl, meta, shift, cmdID, factoryUnitID, queuePosition)
		return
	end
	
	local mb = (left and 1) or (right and 3)
	if mb then
		local index = Spring.GetCmdDescIndex(cmdID)
		if index then
			Spring.SetActiveCommand(index, mb, left, right, alt, ctrl, meta, shift)
			if alt and isStructure and WG.Terraform_SetPlacingRectangle then
				WG.Terraform_SetPlacingRectangle(-cmdID)
			end
		end
	end
end

local function GetHotkeyText(actionName)
	local hotkey = WG.crude.GetHotkey(actionName)
	if hotkey ~= '' then
		return '\255\0\255\0' .. hotkey
	end
	return nil
end

local function GetActionHotkey(actionName)
	return WG.crude.GetHotkey(actionName)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Button Panel

local function GetButton(parent, x, y, xStr, yStr, width, height, buttonLayout, isStructure, onClick)
	local cmdID
	local usingGrid
	local factoryUnitID, queuePosition

	local function DoClick(_, _, _, mouse)
		ClickFunc(mouse or 1, cmdID, isStructure, factoryUnitID, queuePosition)
		if onClick then
			onClick()
		end
	end
	
	local button = Button:New {
		x = xStr,
		y = yStr,
		width = width,
		height = height,
		caption = "",
		padding = {0, 0, 0, 0},
		parent = parent,
		OnClick = {DoClick}
	}
	
	if not BUTTON_COLOR then
		BUTTON_COLOR = button.backgroundColor
	end
	if not BUTTON_FOCUS_COLOR then
		BUTTON_FOCUS_COLOR = button.focusColor
	end
	
	local image
	local buildProgress
	local textBoxes = {}
	
	local function SetImage(texture1, texture2)
		if not image then
			image = Image:New {
				x = buttonLayout.image.x,
				y = buttonLayout.image.y,
				right = buttonLayout.image.right,
				bottom = buttonLayout.image.bottom,
				height = buttonLayout.image.height,
				keepAspect = buttonLayout.image.keepAspect,
				file = texture1,
				file2 = texture2,
				parent = button,
			}
			image:SendToBack()
			return
		end
		
		image.file = texture1
		image.file2 = texture2
		image:Invalidate()
	end
	
	local function SetText(textPosition, text)
		if not textBoxes[textPosition] then
			if not text then
				return
			end
			local config = textConfig[textPosition]
			textBoxes[textPosition] = Label:New {
				x = config.x,
				y = config.y,
				right = config.right,
				bottom = config.bottom,
				height = config.height,
				align = config.align,
				fontsize = config.fontsize,
				caption = text,
				parent = button,
			}
			textBoxes[textPosition]:BringToFront()
			return
		end
	
		textBoxes[textPosition]:SetCaption(text or NO_TEXT)
		textBoxes[textPosition]:Invalidate()
	end
	
	
	local externalFunctionsAndData = {
		button = button,
		DoClick = DoClick
	}

	function externalFunctionsAndData.SetProgressBar(proportion)
		if buildProgress then
			buildProgress:SetValue(proportion or 0)
			return
		end
		
		if not image then
			SetImage("")
		end
		
		buildProgress = Progressbar:New{
			x = "5%",
			y = "5%",
			right = "5%",
			bottom = "5%",
			value = proportion,
			max = 1,
			color   		= {0.7, 0.7, 0.4, 0.6},
			backgroundColor = {1, 1, 1, 0.01},
			parent = image,
			skin = nil,
			skinName = 'default',
		}
	end
	
	function externalFunctionsAndData.UpdateGridHotkey(gridMap)
		local key = gridMap[y] and gridMap[y][x]
		if not key then
			return
		end
		usingGrid = true
		SetText(textConfig.topLeft.name, '\255\0\255\0' .. key)
	end
	
	function externalFunctionsAndData.SetQueueCommandParameter(newFactoryUnitID, newQueuePosition)
		factoryUnitID = newFactoryUnitID
		queuePosition = newQueuePosition
	end
	
	function externalFunctionsAndData.SetSelection(isSelected)
		if isSelected then
			button.backgroundColor = SELECT_BUTTON_COLOR
			button.focusColor = SELECT_BUTTON_FOCUS_COLOR
			button:Invalidate()
			return
		end
		
		button.backgroundColor = BUTTON_COLOR
		button.focusColor = BUTTON_FOCUS_COLOR
		button:Invalidate()
	end
	
	function externalFunctionsAndData.GetCommandID()
		return cmdID
	end
	
	function externalFunctionsAndData.SetBuildQueueCount(count)
		SetText(textConfig.queue.name, count)
	end
	
	function externalFunctionsAndData.SetCommand(command, overrideCmdID, notGlobal)
		-- If overrideCmdID is negative then command can be nil.
		cmdID = overrideCmdID or command.id
		if not notGlobal then
			buttonsByCommand[cmdID] = externalFunctionsAndData
		end
		if buildProgress then
			externalFunctionsAndData.SetProgressBar(0)
		end
		externalFunctionsAndData.SetSelection(false)
		externalFunctionsAndData.SetBuildQueueCount(nil)
		
		if cmdID < 0 then
			local ud = UnitDefs[-cmdID]
			if buttonLayout.tooltipOverride then
				button.tooltip = buttonLayout.tooltipOverride
			else
				local tooltip = "Build Unit: " .. ud.humanName .. " - " .. ud.tooltip .. "\n"
				button.tooltip = tooltip
			end
			SetImage("#" .. -cmdID, WG.GetBuildIconFrame(UnitDefs[-cmdID]))
			if buttonLayout.showCost then
				SetText(textConfig.bottomLeft.name, UnitDefs[-cmdID].metalCost)
			end
			return
		end
		
		local displayConfig = commandDisplayConfig[cmdID]
		local tooltip = (displayConfig and displayConfig.tooltip) or command.tooltip
		
		local isStateCommand = (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
		
		if command.action then
			local hotkey = GetHotkeyText(command.action)
			if tooltip and hotkey then
				tooltip = tooltip .. " (\255\0\255\0" .. hotkey .. "\008)"
			end
			if not (isStateCommand or usingGrid) then 
				SetText(textConfig.topLeft.name, hotkey)
			end
		end
		
		button.tooltip = tooltip
		
		if isStateCommand then
			local state = command.params[1] + 1
			local texture = displayConfig.texture[state]
			SetImage(texture)
		else
			local texture = (displayConfig and displayConfig.texture) or command.texture
			SetImage(texture)
		end
	end

	return externalFunctionsAndData
end

local function GetButtonPanel(parent, rows, columns, vertical, generalButtonLayout, generalIsStructure, onClick, rowOverride)
	local buttons = {}
	local buttonList = {}
	
	local width = tostring(100/columns) .. "%"
	local height = tostring(100/rows) .. "%"
	
	local gridMap
	
	local externalFunctions = {}
	
	function externalFunctions.ClearButtons()
		parent:ClearChildren()
	end
	
	function externalFunctions.GetButton(x, y, onlyExisting)
		if buttons[x] and buttons[x][y] then
			if not buttons[x][y].button.parent then
				if onlyExisting then
					return false
				end
				parent:AddChild(buttons[x][y].button)
			end
			return buttons[x][y]
		end
		
		if onlyExisting then
			return false
		end
		
		buttons[x] = buttons[x] or {}
		
		local xStr = tostring((x - 1)*100/columns) .. "%"
		local yStr = tostring((y - 1)*100/rows) .. "%"
		
		local buttonLayout, isStructure = generalButtonLayout, generalIsStructure
		if rowOverride and rowOverride[y] then
			buttonLayout = rowOverride[y].buttonLayoutConfig
			isStructure = rowOverride[y].isStructure
		end
		
		newButton = GetButton(parent, x, y, xStr, yStr, width, height, buttonLayout, isStructure, onClick)
		
		buttonList[#buttonList + 1] = newButton
		if gridMap then
			newButton.UpdateGridHotkey(gridMap)
		end
		
		buttons[x][y] = newButton
		
		return newButton
	end
	
	function externalFunctions.IndexToPosition(index)
		if vertical then
			local y = (index - 1)%rows + 1
			local x = columns - (index - y)/rows
			return x, y
		else
			local x = (index - 1)%columns + 1
			local y = (index - x)/columns + 1
			return x, y
		end
	end
	
	function externalFunctions.ApplyGridHotkeys(newGridMap)
		gridMap = newGridMap
		for i = 1, #buttonList do
			buttonList[i].UpdateGridHotkey(gridMap)
		end
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Queue Panel

local function GetQueuePanel(parent, rows, columns)
	local externalFunctions = {}
	
	local factoryUnitID
	local factoryUnitDefID
	local buttonCount = 0
	local buttonColumns = columns - 1
	local buttons = GetButtonPanel(parent, rows, columns, false, buttonLayoutConfig.queue, false, onClick)

	function externalFunctions.ClearButtons()
		factoryUnitID = false
		factoryUnitDefID = false
		buttons.ClearButtons()
		buttonCount = 0
	end
	
	function externalFunctions.UpdateBuildProgress()
		if not factoryUnitID then
			return
		end
		local button = buttons.GetButton(1, 1, true)
		if not button then
			return
		end
		local unitBuildID = Spring.GetUnitIsBuilding(factoryUnitID)
		if not unitBuildID then 
			return
		end
		local progress = select(5, Spring.GetUnitHealth(unitBuildID))
		button.SetProgressBar(progress)
	end
	
	function externalFunctions.UpdateFactory(newFactoryUnitID, newFactoryUnitDefID)
		
		factoryUnitID = newFactoryUnitID 
		factoryUnitDefID = newFactoryUnitDefID
		local uncondensedCommandTotal = 0
	
		local buildQueue = Spring.GetRealBuildQueue(factoryUnitID)
		local buildDefIDCounts = {}
		if buildQueue then
			for i = 1, #buildQueue do
				for udid, count in pairs(buildQueue[i]) do
					if buttonCount < buttonColumns then
						buttonCount = buttonCount + 1
						uncondensedCommandTotal = uncondensedCommandTotal + count
						local x, y = buttons.IndexToPosition(buttonCount)
						local button = buttons.GetButton(x,y)
						button.SetCommand(nil, -udid, true)
						button.SetQueueCommandParameter(newFactoryUnitID, uncondensedCommandTotal)
						button.SetBuildQueueCount(count)
					else
					
					end
					
					buildDefIDCounts[udid] = (buildDefIDCounts[udid] or 0) + count
				end
			end
		end
		
		externalFunctions.UpdateBuildProgress()
		
		for udid, count in pairs(buildDefIDCounts) do
			local button = buttonsByCommand[-udid]
			if button then
				button.SetBuildQueueCount(count)
			end
		end
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tab Panel

local function GetTabButton(panel, contentControl, name, humanName, hotkey, loiterable, OnSelect)
	
	local function DoClick()
		panel.SwitchToTab(name)
		panel.SetHotkeysActive(loiterable)
		if OnSelect then
			OnSelect()
		end
	end
	
	local button = Button:New {
		caption = humanName,
		padding = {0, 0, 0, 0},
		OnClick = {DoClick}
	}
	
	local hideHotkey = loiterable
	
	if hotkey and not hideHotkey then
		button:SetCaption(humanName .. "(\255\0\255\0" .. hotkey .. "\008)")
		button:Invalidate()
	end
	
	local externalFunctionsAndData = {
		button = button,
		name = name,
		DoClick = DoClick,
	}
		
	function externalFunctionsAndData.IsTabSelected()
		return contentControl.visible
	end
	
	function externalFunctionsAndData.IsTabPresent()
		return button.parent and true or false
	end
	
	function externalFunctionsAndData.SetHotkeyActive(isActive)
		if (not hotkey) or hideHotkey then
			return
		end
		if loiterable then
			isActive = isActive and (not contentControl.visible)
		end
		
		if isActive then
			button:SetCaption(humanName .. "(\255\0\255\0" .. hotkey .. "\008)")
		else
			button:SetCaption(humanName .. "(" .. hotkey .. ")")
		end
		button:Invalidate()
	end
	
	function externalFunctionsAndData.SetHideHotkey(newHidden)
		if not loiterable then
			return
		end
		hideHotkey = newHidden
		if hideHotkey then
			button:SetCaption(humanName)
			button:Invalidate()
		end
	end
	
	function externalFunctionsAndData.SetSelected(isSelected)
		contentControl:SetVisibility(isSelected)
		if loiterable and not hideHotkey then
			externalFunctionsAndData.SetHotkeyActive(not isSelected)
		end
		button.backgroundColor[4] = isSelected and 1 or 0.4
		button:Invalidate()
	end
	
	return externalFunctionsAndData
end

local function GetTabPanel(parent, rows, columns)
	local tabHolder = StackPanel:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {0, 0, 0, 0},
		itemMargin  = {1, 1, 1, -1},	
		parent = parent,
		preserveChildrenOrder = true,
		resizeItems = true,
		orientation = "horizontal",
	}
	
	local hotkeysActive = true
	local currentTab
	local tabList = {}
	
	local externalFunctions = {}
	
	function externalFunctions.SetTabs(newTabList, showTabs, variableHide)
		tabList = newTabList
		tabHolder:ClearChildren()
		if showTabs then
			for i = 1, #tabList do
				tabHolder:AddChild(tabList[i].button)
				tabList[i].SetHideHotkey(variableHide)
				tabList[i].SetHotkeyActive(hotkeysActive)
			end
		end
	end
	
	function externalFunctions.SwitchToTab(name)
		currentTab = name
		for i = 1, #tabList do
			local data = tabList[i]
			data.SetSelected(data.name == name)
		end
	end
	
	function externalFunctions.SetHotkeysActive(newActive)
		hotkeysActive = newActive
		for i = 1, #tabList do
			local data = tabList[i]
			data.SetHotkeyActive(hotkeysActive)
		end
	end
	
	function externalFunctions.GetCurrentTab()
		return currentTab
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Global Variables

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
		humanName = "Economy",
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
		rowOverride = {
			[3] = {
				buttonLayoutConfig = buttonLayoutConfig.command,
				isStructure = false,
			}
		}
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
			if not factoryUnitDefID then
				return false
			end
			local buildOptions = UnitDefs[factoryUnitDefID].buildOptions
			for i = 1, #buildOptions do
				if buildOptions[i] == -cmdID then
					return true
				end
			end
			return false
		end,
		loiterable = true,
		factoryQueue = true,
		isBuild = true,
		hotkeyReplacement = "Orders",
		gridHotkeys = true,
		buttonLayoutConfig = buttonLayoutConfig.build,
	},
}

local commandPanelMap = {}
for i = 1, #commandPanels do
	commandPanelMap[commandPanels[i].name] = commandPanels[i]
end

local statePanel = {}
local tabPanel

local gridKeyMap, gridMap = GenerateGridKeyMap("qwerty")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling

local function GetSelectedFactory()	
	local selection = Spring.GetSelectedUnits()
	for i = 1, #selection do
		local unitID = selection[i]
		local defID = Spring.GetUnitDefID(unitID)
		if defID and UnitDefs[defID].isFactory then
			return unitID, defID
		end
	end
	return false
end

local function ProcessCommand(command, factorySelected)
	if hiddenCommands[command.id] or command.hidden then
		return
	end

	local isStateCommand = (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
	if isStateCommand then
		statePanel.commandCount = statePanel.commandCount + 1
		
		local x, y = statePanel.buttons.IndexToPosition(statePanel.commandCount)
		local button = statePanel.buttons.GetButton(x, y)
		button.SetCommand(command)
		return
	end
	
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		local found, position = data.inclusionFunction(command.id, factorySelected)
		if found then
			data.commandCount = data.commandCount + 1
			
			local x, y
			if position then
				x, y = position.col, position.row
			else
				x, y = data.buttons.IndexToPosition(data.commandCount)
			end
			
			local button = data.buttons.GetButton(x, y)
			
			button.SetCommand(command)
			return
		end
	end
end

local function ProcessAllCommands(commands, customCommands)
	local factoryUnitID, factoryUnitDefID  = GetSelectedFactory()

	for i = 1, #commandPanels do
		local data = commandPanels[i]
		data.buttons.ClearButtons()
		data.commandCount = 0
		if data.queue then
			data.queue.ClearButtons()
		end
	end
		
	statePanel.commandCount = 0
	statePanel.buttons.ClearButtons()
	
	for i = 1, #commands do
		ProcessCommand(commands[i], factoryUnitDefID)
	end
	
	for i = 1, #customCommands do
		ProcessCommand(customCommands[i], factoryUnitDefID)
	end
	
	-- Call factory queue update here because the update will globally
	-- set queue count for the top two rows of the factory tab. Therefore
	-- the factory tab must have updated its commands.
	if factoryUnitDefID then
		for i = 1, #commandPanels do
			local data = commandPanels[i]
			if data.queue then
				data.queue.UpdateFactory(factoryUnitID, factoryUnitDefID)
			end
		end
	end
	
	local tabsToShow = {}
	local lastTabSelected = tabPanel.GetCurrentTab()
	local tabToSelect
	
	-- Switch to factory tab is a factory is newly selected.
	if factoryUnitDefID then
		local unitsFactoryTab = commandPanelMap.units_factory.tabButton
		if not unitsFactoryTab.IsTabPresent() then
			tabToSelect = "units_factory"
		end
	end
	
	-- Determine which tabs to display and which to select
	for i = 1, #commandPanels do
		if commandPanels[i].commandCount ~= 0 then
			tabsToShow[#tabsToShow + 1] = commandPanels[i].tabButton
			if (not tabToSelect) and commandPanels[i].tabButton.name == lastTabSelected then
				tabToSelect = lastTabSelected
			end
		end
	end
	
	tabPanel.SetTabs(tabsToShow, #tabsToShow > 1, not factoryUnitDefID)
	
	if not tabToSelect then
		tabToSelect = "orders"
	end
	
	if #tabsToShow == 0 then
		tabPanel.SwitchToTab(nil)
		lastTabSelected = false
	else
		tabPanel.SwitchToTab(tabToSelect)
		lastTabSelected = tabToSelect
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function InitializeControls()
	-- Set the size for the default settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local width = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local height = math.min(screenHeight/4.5, 200*width/450)

	local mainWindow = Window:New{
		name      = 'integralwindow2',
		x         = 0, 
		bottom    = 0,
		width     = width,
		height    = height,
		minWidth  = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		dockable  = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		padding = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent    = screen0,
	}
		
	local tabHolder = Control:New{
		x = "0%",
		y = "0%",
		width = "100%",
		height = "15%",
		padding = {2, 2, 2, 0},
		parent = mainWindow,
	}
	
	tabPanel = GetTabPanel(tabHolder)
	
	local contentHolder = Panel:New{
		x = 0,
		y = "15%",
		width = "100%",
		height = "85%",
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, 0.8},
		parent = mainWindow,
	}
	
	local function ReturnToOrders()
		commandPanelMap.orders.tabButton.DoClick()
	end
	
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		local commandHolder = Control:New{
			x = "0%",
			y = "0%",
			width = COMMAND_SECTION_WIDTH .. "%",
			height = "100%",
			padding = {4, 4, 0, 4},
			parent = contentHolder,
		}
		
		local hotkey
		if data.optionName then
			hotkey = GetActionHotkey(EPIC_NAME .. data.optionName)
		else
			hotkey = GetActionHotkey(EPIC_NAME_UNITS)
		end

		if data.returnOnClick then
			data.onClick = ReturnToOrders
		end
		
		local OnTabSelect
		
		data.holder = commandHolder
		if data.factoryQueue then
			local buttonHolder = Control:New{
				x = "0%",
				y = "0%",
				width = "100%",
				height = "66.666%",
				padding = {0, 0, 0, 0},
				parent = commandHolder,
			}
			data.buttons = GetButtonPanel(buttonHolder, 2, 6,  false, data.buttonLayoutConfig, data.isStructure, data.onClick, data.rowOverride)
			
			local queueHolder = Control:New{
				x = "0%",
				y = "66.666%",
				width = "100%",
				height = "33.3333%",
				padding = {0, 0, 0, 0},
				parent = commandHolder,
			}
			data.queue = GetQueuePanel(queueHolder, 1, 6)
			
			-- If many things need doing they must be put in a function
			-- but this works for now.
			OnTabSelect = data.queue.UpdateBuildProgress
		else
			data.buttons = GetButtonPanel(commandHolder, 3, 6, false, data.buttonLayoutConfig, data.isStructure, data.onClick, data.rowOverride)
		end
		
		data.tabButton = GetTabButton(tabPanel, commandHolder, data.name, data.humanName, hotkey, data.loiterable, OnTabSelect)
	
		if data.gridHotkeys then
			data.buttons.ApplyGridHotkeys(gridMap)
		end
	end
	
	statePanel.holder = Control:New{
		x = (100 - STATE_SECTION_WIDTH) .. "%",
		y = "0%",
		width = STATE_SECTION_WIDTH .. "%",
		height = "100%",
		padding = {0, 4, 3, 4},
		parent = contentHolder,
	}
	
	statePanel.buttons = GetButtonPanel(statePanel.holder, 5, 3, true, buttonLayoutConfig.command)
end

local function HotkeyTabEconomy()
	local tab = commandPanelMap.economy.tabButton
	if tab.IsTabPresent() then
		tab.DoClick()
	end
end

local function HotkeyTabDefence()
	local tab = commandPanelMap.defence.tabButton
	if tab.IsTabPresent() then
		tab.DoClick()
	end
end

local function HotkeyTabSpecial()
	local tab = commandPanelMap.special.tabButton
	if tab.IsTabPresent() then
		tab.DoClick()
	end
end

local function HotkeyTabFactory()
	local tab = commandPanelMap.factory.tabButton
	if tab.IsTabPresent() then
		tab.DoClick()
	end
end

local function HotkeyTabUnits()
	local tab = commandPanelMap.units_mobile.tabButton
	if tab.IsTabPresent() then
		tab.DoClick()
		return
	end
	local unitsFactoryTab = commandPanelMap.units_factory.tabButton
	if not unitsFactoryTab.IsTabPresent() then
		return
	end
	if unitsFactoryTab.IsTabSelected() then
		commandPanelMap.orders.tabButton.DoClick()
	else
		unitsFactoryTab.DoClick()
	end
end

options.tab_economy.OnChange = HotkeyTabEconomy
options.tab_defence.OnChange = HotkeyTabDefence
options.tab_special.OnChange = HotkeyTabSpecial
options.tab_factory.OnChange = HotkeyTabFactory
options.tab_units.OnChange   = HotkeyTabUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local initialized = false

local lastCmdID
function widget:Update()
	local _,cmdID = Spring.GetActiveCommand()
	if cmdID ~= lastCmdID then
		if lastCmdID and buttonsByCommand[lastCmdID] then
			buttonsByCommand[lastCmdID].SetSelection(false)
		end
		if buttonsByCommand[cmdID] then
			buttonsByCommand[cmdID].SetSelection(true)
		end
		
		lastCmdID = cmdID
	end
end

function widget:KeyPress(key, modifier, isRepeat)
	if isRepeat then
		return false
	end
	
	local currentTab = tabPanel.GetCurrentTab()
	local commandPanel = currentTab and commandPanelMap[currentTab]
	if (not commandPanel) or (not commandPanel.gridHotkeys) then
		return false
	end
	
	local pos = gridKeyMap[key]
	if pos then
		local x, y = pos[2], pos[1]
		local button = commandPanel.buttons.GetButton(x, y, true)
		if button then
			button.DoClick()
			return true
		end
	end

	if commandPanel.onClick then
		commandPanel.onClick()
		return true
	end
	return false
end

function widget:CommandsChanged()
	if not initialized then
		return
	end

	local commands = widgetHandler.commands
	local customCommands = widgetHandler.customCommands
	ProcessAllCommands(commands, customCommands)
end

function widget:GameFrame(n)
	if n%6 == 0 then
		local unitsFactoryPanel = commandPanelMap.units_factory
		if unitsFactoryPanel.tabButton.IsTabSelected() then
			unitsFactoryPanel.queue.UpdateBuildProgress()
		end
	end
end

function widget:Initialize()
	RemoveAction("nextmenu")
	RemoveAction("prevmenu")
	initialized = true
	
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Colorbars = Chili.Colorbars
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	Control = Chili.Control
	screen0 = Chili.Screen0
	
	InitializeControls()
end
