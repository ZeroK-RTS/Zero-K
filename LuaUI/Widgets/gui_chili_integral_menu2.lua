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

local function ClickFunc(mouse, cmdID, isStructure)
	local left, right = mouse == 1, mouse == 3
	local alt,ctrl,meta,shift = Spring.GetModKeyState()
	local mb = (left and 1) or (right and 3)
	if mb then
		local index = Spring.GetCmdDescIndex(cmdID)
		if index then
			Spring.SetActiveCommand(index,mb,left,right,alt,ctrl,meta,shift)
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
-- Queue Panel

local function GetQueuePanel(parent, rows, columns)
	local externalFunctions = {}

	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Button Panel

local function GetButton(parent, x, y, xStr, yStr, width, height, isBuild, isStructure, onClick)
	local cmdID
	local usingGrid

	local button = Button:New {
		x = xStr,
		y = yStr,
		width = width,
		height = height,
		caption = "",
		padding = {0, 0, 0, 0},
		parent = parent,
		OnClick = {
			function(self, x, y, mouse) 
				ClickFunc(mouse, cmdID, isStructure)
				if onClick then
					onClick()
				end
			end
		}
	}
	
	if not BUTTON_COLOR then
		BUTTON_COLOR = button.backgroundColor
	end
	if not BUTTON_FOCUS_COLOR then
		BUTTON_FOCUS_COLOR = button.focusColor
	end
	
	local image
	local lowerText
	local upperText
	
	local function SetImage(texture1, texture2)
		if not image then
			image = Image:New {
				x = "9%",
				y = "9%",
				right = "9%",
				height = (not isBuild) and nil or "82%",
				bottom = (isBuild) and 16 or nil,
				keepAspect = not isBuild,
				file = texture1,
				file2 = texture2,
				parent = button,
			}
			if upperText then
				upperText:BringToFront()
			end
			return
		end
		
		image.file = texture1
		image.file2 = texture2
		image:Invalidate()
	end
	
	local function SetLowerText(text)
		if not lowerText then
			lowerText = TextBox:New {
				x = "15%",
				right = 0,
				bottom = 2,
				height = 12,
				fontsize = 14,
				text = text,
				parent = button,
			}
			return
		end
	
		lowerText:SetText(text)
		lowerText:Invalidate()
	end
	
	local function SetUpperText(text)
		if not upperText then
			if not text then
				return
			end
			upperText = TextBox:New {
				x = "14%",
				y = "14%",
				fontsize = 11,
				text = text,
				parent = button,
			}
			upperText:BringToFront()
			return
		end
		
		upperText:SetText(text or NO_TEXT)
		upperText:Invalidate()
	end
	
	local externalFunctionsAndData = {
		button = button
	}
	
	function externalFunctionsAndData.DoClick()
		ClickFunc(1, cmdID, isStructure)
		if onClick then
			onClick()
		end
	end
	
	function externalFunctionsAndData.UpdateGridHotkey(gridMap)
		local key = gridMap[y] and gridMap[y][x]
		if not key then
			return
		end
		usingGrid = true
		SetUpperText('\255\0\255\0' .. key)
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
	
	function externalFunctionsAndData.SetCommand(command)
		cmdID = command.id
		buttonsByCommand[cmdID] = externalFunctionsAndData
		externalFunctionsAndData.SetSelection(false)
		if cmdID < 0 then
			local ud = UnitDefs[-cmdID]
			local tooltip = "Build Unit: " .. ud.humanName .. " - " .. ud.tooltip .. "\n"
			button.tooltip = tooltip	
			SetImage("#" .. -cmdID, WG.GetBuildIconFrame(UnitDefs[-cmdID]))
			SetLowerText(UnitDefs[-cmdID].metalCost)
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
				SetUpperText(hotkey)
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

local function GetButtonPanel(parent, rows, columns, vertical, isBuild, isStructure, notBuildRow, onClick)
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
		
		newButton = GetButton(parent, x, y, xStr, yStr, width, height, notBuildRow ~= y and isBuild, notBuildRow ~= y and isStructure, onClick)
		
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
-- Tab Panel

local function GetTabButton(panel, contentControl, name, humanName, hotkey, loiterable)
	local button = Button:New {
		caption = humanName,
		padding = {0, 0, 0, 0},
		OnClick = {
			function ()
				panel.SwitchToTab(name)
				panel.SetHotkeysActive(loiterable)
			end
		}
	}
	
	local hideHotkey = loiterable
	
	if hotkey and not hideHotkey then
		button:SetCaption(humanName .. "(\255\0\255\0" .. hotkey .. "\008)")
		button:Invalidate()
	end
	
	local externalFunctionsAndData = {
		button = button,
		name = name
	}
	
	function externalFunctionsAndData.DoClick()
		panel.SwitchToTab(name)
		panel.SetHotkeysActive(loiterable)
	end
		
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

local function GetSelectedFactoryUnitDefID()	
	local selection = Spring.GetSelectedUnits()
	for i = 1, #selection do
		local unitID = selection[i]
		local defID = Spring.GetUnitDefID(unitID)
		if defID and UnitDefs[defID].isFactory then
			return defID
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
	local factoryUnitDefID = GetSelectedFactoryUnitDefID()

	for i = 1, #commandPanels do
		local data = commandPanels[i]
		data.buttons.ClearButtons()
		data.commandCount = 0
	end
		
	statePanel.commandCount = 0
	statePanel.buttons.ClearButtons()
	
	for i = 1, #commands do
		ProcessCommand(commands[i], factoryUnitDefID)
	end
	
	for i = 1, #customCommands do
		ProcessCommand(customCommands[i], factoryUnitDefID)
	end
	
	local tabsToShow = {}
	local lastTabSelected = tabPanel.GetCurrentTab()
	local tabToSelect
	
	if factoryUnitDefID then
		tabToSelect = "units_factory"
	end
	
	for i = 1, #commandPanels do
		if commandPanels[i].commandCount ~= 0 then
			tabsToShow[#tabsToShow + 1] = commandPanels[i].tabButton
			if (not factoryUnitDefID) and commandPanels[i].tabButton.name == lastTabSelected then
				tabToSelect = lastTabSelected
			end
		end
	end
	
	tabPanel.SetTabs(tabsToShow, #tabsToShow > 1, not factoryUnitDefID)
	
	if not tabToSelect then
		tabToSelect = "orders"
	end
	
	tabPanel.SwitchToTab(tabToSelect)
	lastTabSelected = tabToSelect
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
		
		data.tabButton = GetTabButton(tabPanel, commandHolder, data.name, data.humanName, hotkey, data.loiterable)

		if data.returnOnClick then
			data.onClick = ReturnToOrders
		end
		
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
			data.buttons = GetButtonPanel(buttonHolder, 2, 6,  false, data.isBuild, data.isStructure, data.notBuildRow, data.onClick)
			
			local queueHolder = Control:New{
				x = "0%",
				y = "66.666%",
				width = "100%",
				height = "33.3333%",
				padding = {0, 0, 0, 0},
				parent = commandHolder,
			}
			data.queue = GetQueuePanel(queueHolder, 1, 6)
		else
			data.buttons = GetButtonPanel(commandHolder, 3, 6, false, data.isBuild, data.isStructure, data.notBuildRow, data.onClick)
		end
	
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
	
	statePanel.buttons = GetButtonPanel(statePanel.holder, 5, 3, true)
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
