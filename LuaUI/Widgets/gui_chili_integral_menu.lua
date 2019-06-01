--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Chili Integral Menu",
		desc      = "Integral Command Menu",
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
local specialKeyCodes = include("Configs/integral_menu_special_keys.lua")

-- Chili classes
local Chili
local Button
local Label
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

local MIN_HEIGHT = 80
local MIN_WIDTH = 200
local COMMAND_SECTION_WIDTH = 74 -- percent
local STATE_SECTION_WIDTH = 24 -- percent

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_DISABLE_COLOR = {0.1, 0.1, 0.1, 0.85}
local BUTTON_DISABLE_FOCUS_COLOR = {0.1, 0.1, 0.1, 0.85}

local DRAW_NAME_COMMANDS = {
	[CMD.STOCKPILE] = true, -- draws stockpile progress (command handler sends correct string).
}

-- Defined upon learning the appropriate colors
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR
local BUTTON_BORDER_COLOR

local NO_TEXT = ""
local NO_TOOLTIP = "NONE"

EPIC_NAME = "epic_chili_integral_menu_"
EPIC_NAME_UNITS = "epic_chili_integral_menu_tab_units"

local modOptions = Spring.GetModOptions()
local disabledTabs = {}

if Spring.GetModOptions().campaign_debug_units ~= "1" then
	if modOptions.integral_disable_economy == "1" then
		disabledTabs.economy = true
	end
	if modOptions.integral_disable_defence == "1" then
		disabledTabs.defence = true
	end
	if modOptions.integral_disable_special == "1" then
		disabledTabs.special = true
	end
	if modOptions.integral_disable_factory == "1" then
		disabledTabs.factory = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Handling and lower variables

configurationName = "Configs/integral_menu_config.lua"
local commandPanels, commandPanelMap, commandDisplayConfig, hiddenCommands, textConfig, buttonLayoutConfig, instantCommands -- In Initialize = include("Configs/integral_menu_config.lua")

local statePanel = {}
local tabPanel
local selectionIndex = 0
local background
local returnToOrdersCommand = false

local buildTabHolder, buttonsHolder -- Required for padding update setting
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Options

options_path = 'Settings/HUD Panels/Command Panel'
options_order = { 
	'background_opacity', 'keyboardType2',  'selectionClosesTab', 'selectionClosesTabOnSelect', 'altInsertBehind',
	'unitsHotkeys2', 'ctrlDisableGrid', 'hide_when_spectating', 'applyCustomGrid', 'label_apply',
	'label_tab', 'tab_economy', 'tab_defence', 'tab_special', 'tab_factory', 'tab_units',
	'tabFontSize', 'leftPadding', 'rightPadding', 'flushLeft', 'fancySkinning', 
}

local commandPanelPath = 'Hotkeys/Command Panel'
local customGridPath = 'Hotkeys/Command Panel/Custom'

options = {
	background_opacity = {
		name = "Opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			background.backgroundColor = {1,1,1,self.value}
			background:Invalidate()
		end,
	},
	keyboardType2 = {
		type='radioButton', 
		name='Grid Keyboard Layout',
		items = {
			{name = 'QWERTY (standard)',key = 'qwerty', hotkey = nil},
			{name = 'QWERTZ (central Europe)', key = 'qwertz', hotkey = nil},
			{name = 'AZERTY (France)', key = 'azerty', hotkey = nil},
			{name = 'Configure in "Custom" (below)', key = 'custom', hotkey = nil},
			{name = 'Disable Grid Keys', key = 'none', hotkey = nil},
		},
		value = 'qwerty',  --default at start of widget
		noHotkey = true,
		path = commandPanelPath,
	},
	selectionClosesTab = {
		name = 'Construction Closes Tab',
		desc = "When enabled, issuing or cancelling a construction command will switch back to the Orders tab (except for build options in the factory queue tab).",
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	selectionClosesTabOnSelect = {
		name = 'Selection Closes Tab',
		desc = "When enabled, selecting a construction command will switch back to the Orders tab (except for build options in the factory queue tab).",
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	altInsertBehind = {
		name = 'Alt Inserts Behind',
		desc = "When enabled, the Alt modifier will insert construction behind the current item in the queue. When disabled, and if the factory is not set to repeat, Alt will insert the command in front of the current construction (destroying its progress).",
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	unitsHotkeys2 = {
		name = 'Factories use grid',
		desc = "When enabled, factory unit production uses grid hotkeys.",
		type = 'bool',
		value = true,
		noHotkey = true,
		path = commandPanelPath,
	},
	ctrlDisableGrid = {
		name = 'Ctrl Disables Hotkeys',
		desc = "When enabled, grid and tab hotkeys will deactivate while Ctrl is held. This allows for Ctrl+key hotkeys to be used while a construtor or factory is selected.",
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	hide_when_spectating = {
		name = 'Hide when Spectating',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	applyCustomGrid = {
		name = "Apply Changes",
		type = 'button',
		path = customGridPath,
		noHotkey = true,
	},
	label_apply = {
		type = 'label',
		name = 'Changes require application or restart',
		path = customGridPath
	},
	label_tab = {
		type = 'label',
		name = 'Tab Hotkeys',
		path = commandPanelPath
	},
	tab_economy = {
		name = "Economy Tab",
		desc = "Switches to economy tab.",
		type = 'button',
		path = commandPanelPath,
	},
	tab_defence = {
		name = "Defence Tab",
		desc = "Switches to defence tab.",
		type = 'button',
		path = commandPanelPath,
	},
	tab_special = {
		name = "Special Tab",
		desc = "Switches to special tab.",
		type = 'button',
		path = commandPanelPath,
	},
	tab_factory = {
		name = "Factory Tab",
		desc = "Switches to factory tab.",
		type = 'button',
		path = commandPanelPath,
	},
	tab_units = {
		name = "Units Tab",
		desc = "Switches to units tab.",
		type = 'button',
		path = commandPanelPath,
	},
	leftPadding = {
		name = 'Left Padding',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 500, step=1,
		OnChange = function() 
			ClearData(true)
		end,	
	},
	tabFontSize = {
		name = "Tab Font Size",
		type = "number",
		value = 14, min = 8, max = 30, step = 1,
	},
	rightPadding = {
		name = 'Right Padding',
		type = 'number',
		value = 0,
		advanced = true,
		min = 0, max = 500, step=1,
		OnChange = function() 
			ClearData(true)
		end,
	},
	flushLeft = {
		name = 'Flush Left',
		type = 'bool',
		value = false,
		hidden = true,
		noHotkey = true,
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'bool',
		value = false,
		hidden = true,
		noHotkey = true,
	},
	label_super_grid_config = {
		type = 'label',
		name = 'Tab specific overrides',
		path = customGridPath
	},
}

local function AddCustomGridOptions()
	for i = 1, 3 do
		for j = 1, 6 do
			local optName = "customgrid" .. i .. j
			options[optName] = {
				name = "Column " .. j .. ", row " .. i,
				type = 'button',
				path = customGridPath,
				dontRegisterAction = true,
				bindWithoutMod = true,
			}
			options_order[#options_order + 1] = optName
		end
	end

	options_order[#options_order + 1] = "label_super_grid_config"

	-- Needed now for epicmenu loading
	local hotkeyTabNames = {
		{"economy", "Economy"},
		{"defence", "Defence"},
		{"special", "Special"},
		{"factory", "Factory"},
		{"economy", "Economy"},
		{"units_factory", "Units"},
	}

	for name = 1, #hotkeyTabNames do
		local optPrefix = "customgrid_override_" .. hotkeyTabNames[name][1]
		local pathName = customGridPath .. "/" .. hotkeyTabNames[name][2]
		for i = 1, 3 do
			for j = 1, 6 do
				local optName = optPrefix .. i .. j
				options[optName] = {
					name = "Column " .. j .. ", row " .. i,
					type = 'button',
					path = pathName,
					dontRegisterAction = true,
					bindWithoutMod = true,
				}
				options_order[#options_order + 1] = optName
			end
		end
	end
end
AddCustomGridOptions()

local function TabClickFunction(mouse)
	if not mouse then
		return false
	end
	local _,_, meta,_ = Spring.GetModKeyState()
	if not meta then 
		return false
	end
	WG.crude.OpenPath(options_path) --// click+ space on integral-menu tab will open a integral options.
	WG.crude.ShowMenu() --make epic Chili menu appear.
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Very Global Globals

local buttonsByCommand = {}
local alreadyRemovedTag = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utility

local lastCmdID
local function UpdateButtonSelection(cmdID)
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

local gridKeysEnabled = true
local function SetGridHotkeysEnabled(newEnabled)
	if newEnabled == gridKeysEnabled then
		return
	end
	gridKeysEnabled = newEnabled
	
	if gridKeysEnabled then
		for i = 1, #commandPanels do
			local data = commandPanels[i]
			if data.gridHotkeys and ((not data.disableableKeys) or options.unitsHotkeys2.value) then
				data.buttons.ApplyGridHotkeys()
			end
		end
	else
		for i = 1, #commandPanels do
			local data = commandPanels[i]
			if data.gridHotkeys and ((not data.disableableKeys) or options.unitsHotkeys2.value) then
				data.buttons.RemoveGridHotkeys()
			end
		end
	end
end

local function UpdateReturnToOrders(cmdID)
	if returnToOrdersCommand and returnToOrdersCommand ~= cmdID then
		commandPanelMap.orders.tabButton.DoClick()
		returnToOrdersCommand = false
	end
	
	if (not returnToOrdersCommand) and options.ctrlDisableGrid.value then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		SetGridHotkeysEnabled(not ctrl)
	else
		SetGridHotkeysEnabled(not returnToOrdersCommand)
	end
end

local function ToKeysyms(key)
	if not key then
		return
	end
	if tonumber(key) then
		return KEYSYMS["N_" .. key], key
	end
	local keyCode = KEYSYMS[string.upper(key)]
	if keyCode == nil then
		keyCode = specialKeyCodes[key]
	end
	key = string.upper(key) or key
	key = string.gsub(key, "NUMPAD", "NP") or key
	key = string.gsub(key, "KP", "NP") or key
	return keyCode, key
end

local function GenerateCustomKeyMap()
	local ret = {}
	local gridMap = {}
	local keyAlreadyUsed = {}
	for i = 1, 3 do
		gridMap[i] = {}
		for j = 1, 6 do
			local key = WG.crude.GetHotkeyRaw("epic_chili_integral_menu_customgrid" .. i .. j)
			local code, humanName = ToKeysyms(key and key[1])
			if code and not keyAlreadyUsed[code] then
				gridMap[i][j] = humanName
				ret[code] = {i, j}
				keyAlreadyUsed[code] = true
			end
		end
	end
	
	local overrides = {}
	if commandPanels then
		for panel = 1, #commandPanels do
			local name = commandPanels[panel].name
			if options["customgrid_override_" .. name .. "11"] then
				local actionName = "epic_chili_integral_menu_customgrid_override_" .. name
				keyAlreadyUsed = {}
				for i = 1, 3 do
					for j = 1, 6 do
						local key = WG.crude.GetHotkeyRaw(actionName .. i .. j)
						local code, humanName = ToKeysyms(key and key[1])
						if code and not keyAlreadyUsed[code] then
							overrides[name] = overrides[name] or {keyMap = {}, gridMap = {}}
							overrides[name].gridMap[i] = overrides[name].gridMap[i] or {}
							overrides[name].gridMap[i][j] = humanName
							overrides[name].keyMap[code] = {i, j}
							keyAlreadyUsed[code] = true
						end
					end
				end
			end
		end
	end
	
	return ret, gridMap, overrides
end

local function GenerateGridKeyMap(name)
	if name == "custom" then
		local ret, gridMap, overrides = GenerateCustomKeyMap()
		return ret, gridMap, overrides
	end
	
	local keyboardLayouts = include("Configs/keyboard_layout.lua")
	local gridMap = (name and keyboardLayouts[name]) or {}
	local ret = {}
	for i = 1, #gridMap do
		for j = 1, #gridMap[i] do
			local key = KEYSYMS[gridMap[i][j]]
			if key then
				ret[key] = {i, j}
			else
				Spring.Echo("LUA_ERRRUN", "Integral menu missing key for", i, j, name)
			end
		end
	end
	return ret, gridMap
end

local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
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

local function GetButtonTooltip(displayConfig, command, state)
	local tooltip = displayConfig and displayConfig.stateTooltip and displayConfig.stateTooltip[state]
	if not tooltip then
		tooltip = (displayConfig and displayConfig.tooltip) or (command and command.tooltip)
	end
	if command and command.action then
		local hotkey = GetHotkeyText(command.action)
		if tooltip and hotkey then
			tooltip = tooltip .. " (\255\0\255\0" .. hotkey .. "\008)"
		end
	end
	return tooltip
end

local function TabListsAreIdentical(newTabList, tabList)
	if (not tabList) or (not newTabList) then
		return false
	end
	if #newTabList ~= #tabList then
		return false
	end
	for i = 1, #newTabList do
		if newTabList[i].name ~= tabList[i].name then
			return false
		end
	end
	return true
end

local prevClass

local function UpdateBackgroundSkin()
	local currentSkin = Chili.theme.skin.general.skinName
	local skin = Chili.SkinHandler.GetSkin(currentSkin)
	
	local newClass
	
	if options.fancySkinning.value then
		local selectedCount = Spring.GetSelectedUnitsCount()
		if selectedCount and selectedCount > 0 then
			if options.flushLeft.value then
				newClass = skin.panel_0120_small
			else
				newClass = skin.panel_2100_small
			end
		else
			if options.flushLeft.value then
				newClass = skin.panel_0110
			else
				newClass = skin.panel_1100
			end
		end
	end
	
	newClass = newClass or skin.panel
	
	if prevClass == newClass then
		return
	end
	prevClass = newClass
	
	background.tiles = newClass.tiles
	background.TileImageFG = newClass.TileImageFG
	background.TileImageBK = newClass.TileImageBK
	background:Invalidate()
	
	-- Update buttons holder padding, not background.
	if newClass.padding then
		buttonsHolder.padding = newClass.padding
		buttonsHolder:UpdateClientArea()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Queue Editing Implementation

local function MoveOrRemoveCommands(cmdID, factoryUnitID, commands, queuePosition, inputMult, reinsertPosition)
	if not commands then
		return
	end
	
	-- delete from back so that the order is not canceled while under construction
	local i = queuePosition
	local j = 0
	while commands[i] and ((not inputMult) or j < inputMult) do
		local thisCmd = commands[i]
		local thisCmdID = thisCmd.id
		local cmdTag = thisCmd.tag
		if thisCmdID < 0 and not alreadyRemovedTag[cmdTag] then
			if thisCmdID ~= cmdID then
				break
			end
	
			alreadyRemovedTag[cmdTag] = true
			Spring.GiveOrderToUnit(factoryUnitID, CMD.REMOVE, {cmdTag}, CMD.OPT_CTRL)
			if reinsertPosition then
				local opts = thisCmd.options
				local coded = opts.coded
				Spring.GiveOrderToUnit(factoryUnitID, CMD.INSERT, {reinsertPosition, cmdID, coded}, CMD.OPT_CTRL + CMD.OPT_ALT)
			end
			j = j + 1
		end
		i = i - 1
	end
end

local function MoveCommandBlock(factoryUnitID, queueCmdID, moveBlock, insertBlock)
	local commands = Spring.GetFactoryCommands(factoryUnitID, -1)
	if not commands then
		return
	end
	
	-- Insert at the end of blocks which are after the move block
	if insertBlock > moveBlock then
		insertBlock = insertBlock + 1
	end
	
	-- Delete moved commands from the end of the block so look for the start of the next block.
	moveBlock = moveBlock + 1
	
	local movePos, insertPos
	local lastBlockCmdID
	local blockCount = 0
	local lastPosition = 0
	local i = 1
	local iterationEnd = #commands + 1
	while i <= iterationEnd and ((not movePos) or (not insertPos)) do
		local command = commands[i]
		local cmdID = command and command.id
		if (not cmdID) or cmdID < 0 then
			if cmdID ~= lastBlockCmdID then
				blockCount = blockCount + 1
				if blockCount == moveBlock then
					movePos = lastPosition
				elseif blockCount == insertBlock then
					insertPos = lastPosition
					-- Prevent canceling construction of identical units
					if cmdID == queueCmdID then
						insertPos = insertPos + 1
					elseif insertBlock > moveBlock then
						insertPos = insertPos - 1
					end
				end
				lastBlockCmdID = cmdID
			end
			lastPosition = i
		end
		i = i + 1
	end
	
	if not insertPos then
		insertPos = #commands 
	end
	
	if not (movePos and insertPos) then
		return
	end
	
	MoveOrRemoveCommands(queueCmdID, factoryUnitID, commands, movePos, nil, insertPos)
end

local function QueueClickFunc(mouse, right, alt, ctrl, meta, shift, queueCmdID, factoryUnitID, queueBlock)
	local commands = Spring.GetFactoryCommands(factoryUnitID, -1)
	if not commands then
		return true
	end
	
	-- Find the end of the block
	queueBlock = queueBlock + 1
	
	local queuePosition
	local lastBlockCmdID
	local blockCount = 0
	local lastPosition = 0
	local i = 1
	local iterationEnd = #commands + 1
	for i = 1, iterationEnd  do
		local command = commands[i]
		local cmdID = command and command.id
		if (not cmdID) or cmdID < 0 then
			if cmdID ~= lastBlockCmdID then
				blockCount = blockCount + 1
				if blockCount == queueBlock then
					queuePosition = lastPosition
					break
				end
				lastBlockCmdID = cmdID
			end
			lastPosition = i
		end
	end
	
	if not queuePosition then
		return true
	end
	
	if WG.noises then
		WG.noises.PlayResponse(factoryUnitID, cmdID)
	end
	
	if alt then
		MoveOrRemoveCommands(queueCmdID, factoryUnitID, commands, queuePosition, false, 0)
		return true
	end

	local inputMult = 1*(shift and 5 or 1)*(ctrl and 20 or 1)
	if right then
		MoveOrRemoveCommands(queueCmdID, factoryUnitID, commands, queuePosition, inputMult)
		return true
	end
	
	for i = 1, inputMult do
		Spring.GiveOrderToUnit(factoryUnitID, CMD.INSERT, {queuePosition, queueCmdID, 0 }, CMD.OPT_ALT + CMD.OPT_CTRL)
	end
	return true
end

local function ClickFunc(mouse, cmdID, isStructure, factoryUnitID, fakeFactory, isQueueButton, queueBlock)
	local left, right = mouse == 1, mouse == 3
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if factoryUnitID and isQueueButton then
		QueueClickFunc(mouse, right, alt, ctrl, meta, shift, cmdID, factoryUnitID, queueBlock)
		return true
	end

	if alt and factoryUnitID and options.altInsertBehind.value and (not fakeFactory) then
		-- Repeat alt has to be handled by engine so that the command is removed after completion.
		if not Spring.Utilities.GetUnitRepeat(factoryUnitID) then
			local inputMult = 1*(shift and 5 or 1)*(ctrl and 20 or 1)
			for i = 1, inputMult do
				Spring.GiveOrderToUnit(factoryUnitID, CMD.INSERT, {1, cmdID, 0 }, CMD.OPT_ALT + CMD.OPT_CTRL)
			end
			if WG.noises then
				WG.noises.PlayResponse(factoryUnitID, cmdID)
			end
			return true
		end
	end
	
	local index = Spring.GetCmdDescIndex(cmdID)
	if index then
		Spring.SetActiveCommand(index, mouse or 1, left, right, alt, ctrl, meta, shift)
		if not instantCommands[cmdID] then
			UpdateButtonSelection(cmdID)
		end
		if alt and isStructure and WG.Terraform_SetPlacingRectangle then
			WG.Terraform_SetPlacingRectangle(-cmdID)
		end
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Button Panel

local function GetButton(parent, selectionIndex, x, y, xStr, yStr, width, height, buttonLayout, isStructure, onClick)
	local cmdID
	local usingGrid
	local factoryUnitID
	local fakeFactory
	local queueCount
	local isDisabled = false
	local isSelected = false
	local isQueueButton = buttonLayout.queueButton
	local hotkeyText
	
	local function DoClick(_, _, _, mouse)
		if buttonLayout.ClickFunction and buttonLayout.ClickFunction() then
			return false
		end
		if isDisabled then
			return false
		end
		local sucess = ClickFunc(mouse, cmdID, isStructure, factoryUnitID, fakeFactory, isQueueButton, x)
		if sucess and onClick then
			-- Don't do the onClick if the command was not eaten by the menu.
			onClick(cmdID)
		end
		return sucess
	end
	
	local button = Button:New {
		x = xStr,
		y = yStr,
		width = width,
		height = height,
		caption = buttonLayout.caption or "",
		padding = {0, 0, 0, 0},
		parent = parent,
		OnClick = {DoClick},
	}
	
	if buttonLayout.dragAndDrop then
		button.OnMouseDown = button.OnMouseDown or {}
		button.OnMouseDown[#button.OnMouseDown + 1] = function(obj,_,_,mouse) --for drag_drop feature
			if mouse == 1 then
				local badX, badY = obj:CorrectlyImplementedLocalToScreen(obj.x, obj.y, true)
				WG.DrawMouseBuild.SetMouseIcon(-cmdID, obj.width/2, queueCount - 1, badX, badY, obj.width, obj.height)
			end
		end

		-- MouseRelease event, for drag_drop feature --note: x & y is coordinate with respect to obj
		button.OnMouseUp = button.OnMouseUp or {}
		button.OnMouseUp[#button.OnMouseUp + 1] = function(obj, clickX, clickY, mouse) 
			WG.DrawMouseBuild.ClearMouseIcon()
			if not factoryUnitID then
				return
			end
			if clickY < 0 or clickY > button.height or button.width == 0 then
				return
			end
			local clickPosition = math.floor(clickX/button.width) + x
			if clickPosition < 1 then
				return
			end
			if factoryUnitID and x ~= clickPosition then
				MoveCommandBlock(factoryUnitID, cmdID, x, clickPosition)
			end
		end
	end
	
	if not BUTTON_COLOR then
		BUTTON_COLOR = button.backgroundColor
	end
	if not BUTTON_FOCUS_COLOR then
		BUTTON_FOCUS_COLOR = button.focusColor
	end
	if not BUTTON_BORDER_COLOR then
		BUTTON_BORDER_COLOR = button.borderColor
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
		
		if image.file == texture1 and image.file2 == texture2 then
			return
		end
		
		if image.file == texture1 and image.file2 == texture2 then
			return
		end
		image.file = texture1
		image.file2 = texture2
		image:Invalidate()
	end
	
	local function SetText(textPosition, text)
		if isDisabled then
			text = false
		end
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
		
		if text == textBoxes[textPosition].caption then
			return
		end
		
		textBoxes[textPosition]:SetCaption(text or NO_TEXT)
		textBoxes[textPosition]:Invalidate()
	end
		
	local externalFunctionsAndData = {
		button = button,
		DoClick = DoClick,
		selectionIndex = selectionIndex,
	}
	
	local function SetDisabled(newDisabled)
		if newDisabled == isDisabled then
			return
		end
		isDisabled = newDisabled
		
		if not image then
			SetImage("")
		end
		if isDisabled then
			button.backgroundColor = BUTTON_DISABLE_COLOR
			button.focusColor = BUTTON_DISABLE_FOCUS_COLOR
			button.borderColor = BUTTON_DISABLE_FOCUS_COLOR
			image.color = {0.3, 0.3, 0.3, 1}
			externalFunctionsAndData.ClearGridHotkey()
		else
			button.backgroundColor = BUTTON_COLOR
			button.focusColor = BUTTON_FOCUS_COLOR
			button.borderColor = BUTTON_BORDER_COLOR
			image.color = {1, 1, 1, 1}
			if hotkeyText then
				SetText(textConfig.topLeft.name, hotkeyText)
			end
		end
			
		button:Invalidate()
		image:Invalidate()
	end
	
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
		
	function externalFunctionsAndData.RemoveGridHotkey()
		if not usingGrid then
			return
		end
		usingGrid = false
		if command and command.action then
			local hotkey = GetHotkeyText(command.action)
			hotkeyText = hotkey
			SetText(textConfig.topLeft.name, hotkey)
		else
			SetText(textConfig.topLeft.name, nil)
		end
	end
	
	function externalFunctionsAndData.UpdateGridHotkey(myGridMap, myOverride)
		local key
		if myOverride then
			key = myOverride[y] and myOverride[y][x]
		else
			key = myGridMap[y] and myGridMap[y][x]
		end
		if not key then
			externalFunctionsAndData.RemoveGridHotkey()
			return
		end
		usingGrid = true
		hotkeyText = '\255\0\255\0' .. key
		SetText(textConfig.topLeft.name, hotkeyText)
	end
	
	function externalFunctionsAndData.ClearGridHotkey()
		SetText(textConfig.topLeft.name)
	end
	
	local currentOverflow, onMouseOverFun
	function externalFunctionsAndData.SetQueueCommandParameter(newFactoryUnitID, overflow, newFakeFactory)
		factoryUnitID = newFactoryUnitID
		fakeFactory = newFakeFactory
		if buttonLayout.dotDotOnOverflow then
			currentOverflow = overflow 
			if overflow then
				button.tooltip = ""
				for _,textBox in pairs(textBoxes) do
					textBox:SetCaption(NO_TEXT)
				end
				SetImage()
				
				if not onMouseOverFun then
					onMouseOverFun = function ()
						if not currentOverflow then
							return
						end
						local buildQueue = Spring.GetRealBuildQueue(factoryUnitID)
						
						local overflowString = ""
						for i = x, #buildQueue do
							for udid, count in pairs(buildQueue[i]) do
								local name = UnitDefs[udid].humanName
								overflowString = overflowString .. name .. " x" .. count .. ((i < #buildQueue and "\n") or "")
							end
						end
						button.tooltip = overflowString
					end
					button.OnMouseOver[#button.OnMouseOver + 1] = onMouseOverFun
				end
			end
		end
	end
	
	function externalFunctionsAndData.SetSelection(newIsSelected)
		if isSelected == newIsSelected then
			return
		end
		isSelected = newIsSelected
	
		if isSelected then
			button.backgroundColor = SELECT_BUTTON_COLOR
			button.focusColor = SELECT_BUTTON_FOCUS_COLOR
		else
			button.backgroundColor = BUTTON_COLOR
			button.focusColor = BUTTON_FOCUS_COLOR
		end
		button:Invalidate()
	end
	
	function externalFunctionsAndData.GetCommandID()
		return cmdID
	end
	
	function externalFunctionsAndData.SetBuildQueueCount(count)
		if not (count or queueCount) then
			return
		end
		queueCount = count
		SetText(textConfig.queue.name, count)
	end
	
	function externalFunctionsAndData.SetCommand(command, overrideCmdID, notGlobal)
		-- If overrideCmdID is negative then command can be nil.
		local newCmdID = overrideCmdID or command.id
		
		externalFunctionsAndData.SetSelection(false)
		externalFunctionsAndData.SetBuildQueueCount(nil)
		
		-- Update stockpile progress
		if command and DRAW_NAME_COMMANDS[command.id] and command.name then
			SetText(textConfig.bottomRightLarge.name, command.name)
		end
		
		if cmdID == newCmdID then
			local isStateCommand = command and (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
			if isStateCommand then
				local state = command.params[1] + 1
				local displayConfig = commandDisplayConfig[cmdID]
				if displayConfig then
					local texture = displayConfig.texture[state]
					if displayConfig.stateTooltip then
						button.tooltip = GetButtonTooltip(displayConfig, command, isStateCommand and (command.params[1] + 1))
					end
					SetImage(texture)
				end
			end
			if command then
				SetDisabled(command.disabled)
			end
			return
		end
		cmdID = newCmdID
		if not notGlobal then
			buttonsByCommand[cmdID] = externalFunctionsAndData
		end
		if buildProgress then
			externalFunctionsAndData.SetProgressBar(0)
		end
		if command then
			SetDisabled(command.disabled)
		end
		if cmdID < 0 then
			local ud = UnitDefs[-cmdID]
			if buttonLayout.tooltipOverride then
				button.tooltip = buttonLayout.tooltipOverride
			else
				local tooltip = (buttonLayout.tooltipPrefix or "") .. ud.name
				button.tooltip = tooltip
			end
			SetImage("#" .. -cmdID, WG.GetBuildIconFrame(UnitDefs[-cmdID]))
			if buttonLayout.showCost then
				SetText(textConfig.bottomLeft.name, UnitDefs[-cmdID].metalCost)
			end
			return
		end
		
		local isStateCommand = (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
		local displayConfig = commandDisplayConfig[cmdID]
		button.tooltip = GetButtonTooltip(displayConfig, command, isStateCommand and (command.params[1] + 1))
		
		if command.action then
			local hotkey = GetHotkeyText(command.action)
			if not (isStateCommand or usingGrid) then
				hotkeyText = hotkey
				SetText(textConfig.topLeft.name, hotkey)
			end
		end
		
		if isStateCommand then
			if displayConfig then
				local state = command.params[1] + 1
				local texture = displayConfig.texture[state]
				SetImage(texture)
			else
				Spring.Echo("Error, missing command config", cmdID)
			end
		else
			local texture = (displayConfig and displayConfig.texture) or command.texture
			SetImage(texture)
			
			-- Remove stockpile progress
			if not (command and DRAW_NAME_COMMANDS[command.id] and command.name) then
				SetText(textConfig.bottomRightLarge.name, nil)
			end
		end
	end
	
	function externalFunctionsAndData.GetScreenPosition()
		if not button:IsVisibleOnScreen() then
			return false
		end
		local x, y = button:LocalToScreen(0, 0)
		if not x then
			return false
		end
		x = x + button.width/2
		y = y + button.height/2
		return x, y, button.width, button.height
	end

	return externalFunctionsAndData
end

local function GetButtonPanel(parent, rows, columns, vertical, generalButtonLayout, generalIsStructure, onClick, buttonLayoutOverride)
	local buttons = {}
	local buttonList = {}
	
	local width = tostring(100/columns) .. "%"
	local height = tostring(100/rows) .. "%"
	
	local gridMap, override
	local gridEnabled = true
	
	local externalFunctions = {}
	
	function externalFunctions.ClearOldButtons(selectionIndex)
		for i = 1, #buttonList do
			local button = buttonList[i]
			if button.selectionIndex ~= selectionIndex then
				parent:RemoveChild(button.button)
			end
		end
	end
	
	function externalFunctions.GetButton(x, y, selectionIndex)
		if buttons[x] and buttons[x][y] then
			if not buttons[x][y].button.parent then
				if not selectionIndex then
					return false
				end
				parent:AddChild(buttons[x][y].button)
			end
			if selectionIndex then
				buttons[x][y].selectionIndex = selectionIndex
			end
			return buttons[x][y]
		end
		
		if not selectionIndex then
			return false
		end
		
		buttons[x] = buttons[x] or {}
		
		local xStr = tostring((x - 1)*100/columns) .. "%"
		local yStr = tostring((y - 1)*100/rows) .. "%"
		
		local buttonLayout, isStructure = generalButtonLayout, generalIsStructure
		if buttonLayoutOverride and buttonLayoutOverride[x] and buttonLayoutOverride[x][y] then
			buttonLayout = buttonLayoutOverride[x][y].buttonLayoutConfig
			isStructure = buttonLayoutOverride[x][y].isStructure
		end
		
		newButton = GetButton(parent, selectionIndex, x, y, xStr, yStr, width, height, buttonLayout, isStructure, onClick)
		
		buttonList[#buttonList + 1] = newButton
		if gridMap and gridEnabled then
			newButton.UpdateGridHotkey(gridMap, override and override.gridMap)
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
	
	function externalFunctions.ApplyGridHotkeys(newGridMap, newOverride)
		gridMap = newGridMap or gridMap
		override = newOverride or override
		gridEnabled = true
		for i = 1, #buttonList do
			buttonList[i].UpdateGridHotkey(gridMap, override and override.gridMap)
		end
	end
	
	function externalFunctions.RemoveGridHotkeys()
		gridEnabled = false
		for i = 1, #buttonList do
			buttonList[i].RemoveGridHotkey()
		end
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Queue Panel

local function GetQueuePanel(parent, columns)
	local externalFunctions = {}
	
	local factoryUnitID
	local factoryUnitDefID
	
	local buttonLayoutOverride = {
		[columns] = {
			[1] = {
				buttonLayoutConfig = buttonLayoutConfig.queueWithDots,
				isStructure = false,
			}
		}
	}
	
	local buttons = GetButtonPanel(parent, 1, columns, false, buttonLayoutConfig.queue, false, nil, buttonLayoutOverride)

	function externalFunctions.ClearOldButtons(selectionIndex)
		buttons.ClearOldButtons(selectionIndex)
	end
	
	function externalFunctions.UpdateBuildProgress()
		if not factoryUnitID then
			return
		end
		local button = buttons.GetButton(1, 1)
		if not button then
			return
		end
		local unitBuildID = Spring.GetUnitIsBuilding(factoryUnitID)
		if not unitBuildID then 
			button.SetProgressBar(0)
			return
		end
		local progress = select(5, Spring.GetUnitHealth(unitBuildID))
		button.SetProgressBar(progress)
	end
	
	function externalFunctions.ClearFactory()
		factoryUnitID = false
		factoryUnitDefID = false
	end
	
	function externalFunctions.UpdateFactory(newFactoryUnitID, newFactoryUnitDefID, selectionIndex)
		local buttonCount = 0
		
		alreadyRemovedTag = {}
		
		factoryUnitID = newFactoryUnitID 
		factoryUnitDefID = newFactoryUnitDefID
	
		local buildQueue = Spring.GetRealBuildQueue(factoryUnitID)
	
		local buildDefIDCounts = {}
		if buildQueue then
			for i = 1, #buildQueue do
				for udid, count in pairs(buildQueue[i]) do
					if buttonCount <= columns then
						buttonCount = buttonCount + 1
						local x, y = buttons.IndexToPosition(buttonCount)
						local button = buttons.GetButton(x, y, selectionIndex)
						button.SetCommand(nil, -udid, true)
						button.SetBuildQueueCount(count)
						button.SetQueueCommandParameter(newFactoryUnitID, #buildQueue > columns)
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
	local disabled = disabledTabs[name]
	
	local function DoClick(mouse)
		if disabled or TabClickFunction(mouse) then
			return
		end
		panel.SwitchToTab(name)
		panel.SetHotkeysActive(loiterable)
		if OnSelect then
			OnSelect()
		end
	end
	
	local button = Button:New {
		classname = "button_tab",
		caption = humanName,
		padding = {0, 0, 0, 1},
		tooltip = NO_TOOLTIP,
		OnClick = {
			function()
				DoClick(true)
			end
		},
	}
	button.backgroundColor[4] = 0.4
	
	if disabled then
		button.font.outlineColor = {0, 0, 0, 1}
		button.font.color = {0.6, 0.6, 0.6, 1}
		button.supressButtonReaction = true
	end
	
	local hideHotkey = loiterable
	
	if hotkey and (not hideHotkey) and (not disabled) then
		button:SetCaption(humanName .. " (\255\0\255\0" .. hotkey .. "\008)")
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
		if (not hotkey) or hideHotkey or disabled then
			return
		end
		if loiterable then
			isActive = isActive and (not contentControl.visible)
		end
		
		if isActive then
			button:SetCaption(humanName .. " (\255\0\255\0" .. hotkey .. "\008)")
		else
			button:SetCaption(humanName .. " (" .. hotkey .. ")")
		end
		button:Invalidate()
	end
	
	function externalFunctionsAndData.SetHideHotkey(newHidden)
		if (not loiterable) or disabled then
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
		button.backgroundColor[4] = isSelected and 0.8 or 0.4
		button:Invalidate()
	end
	
	function externalFunctionsAndData.SetFontSize(newSize)
		button.font.size = newSize
		button:Invalidate()
	end
	
	function externalFunctionsAndData.GetScreenPosition()
		if not button:IsVisibleOnScreen() then
			return false
		end
		local x, y = button:LocalToScreen(0, 0)
		if not x then
			return false
		end
		x = x + button.width/2
		y = y + button.height/2
		return x, y, button.width, button.height
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
		itemMargin  = {0, 1, 0, -1},
		parent = parent,
		preserveChildrenOrder = true,
		resizeItems = true,
		orientation = "horizontal",
	}
	
	local currentSelectedIndex
	local hotkeysActive = true
	local currentTab
	local tabList = false
	
	local externalFunctions = {}
	
	function externalFunctions.SwitchToTab(name)
		if not tabList then
			return
		end
		currentTab = name
		for i = 1, #tabList do
			local data = tabList[i]
			data.SetSelected(data.name == name)
			if data.name == name then
				currentSelectedIndex = i
			end
		end
	end
		
	function externalFunctions.SetTabs(newTabList, showTabs, variableHide, tabToSelect)
		if TabListsAreIdentical(newTabList, tabList) then
			return
		end
		if currentSelectedIndex and tabList[currentSelectedIndex] then
			tabList[currentSelectedIndex].SetSelected(false)
		end
		tabList = newTabList
		tabHolder:ClearChildren()
		for i = 1, #tabList do
			if showTabs then
				tabHolder:AddChild(tabList[i].button)
				tabList[i].SetHideHotkey(variableHide)
				tabList[i].SetHotkeyActive(hotkeysActive)
			end
			if tabList[i].name == tabToSelect then
				tabList[i].DoClick()
			end
		end
	end
	
	function externalFunctions.ClearTabs()
		if tabList then
			externalFunctions.SwitchToTab()
			tabList = false
			currentSelectedIndex = false
			tabHolder:ClearChildren()
		end
	end
	
	function externalFunctions.SetHotkeysActive(newActive)
		hotkeysActive = newActive
		if not tabList then
			return
		end
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
-- Command Handling

local function GetSelectionValues()	
	local selection = Spring.GetSelectedUnits()
	for i = 1, #selection do
		local unitID = selection[i]
		local defID = Spring.GetUnitDefID(unitID)
		if defID and (UnitDefs[defID].isFactory or UnitDefs[defID].customParams.isfakefactory) and (not UnitDefs[defID].customParams.notreallyafactory) then
			return unitID, defID, UnitDefs[defID].customParams.isfakefactory, #selection
		end
	end
	return false, nil, nil, #selection
end

local function ProcessCommand(command, factoryUnitID, factoryUnitDefID, fakeFactory, selectionIndex)
	if hiddenCommands[command.id] or command.hidden then
		return
	end

	local isStateCommand = (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
	if isStateCommand then
		statePanel.commandCount = statePanel.commandCount + 1
		
		local x, y = statePanel.buttons.IndexToPosition(statePanel.commandCount)
		local button = statePanel.buttons.GetButton(x, y, selectionIndex)
		button.SetCommand(command)
		return
	end
	
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		local found, position = data.inclusionFunction(command.id, factoryUnitDefID)
		if found then
			data.commandCount = data.commandCount + 1
			
			local x, y
			if position then
				x, y = position.col, position.row
			else
				x, y = data.buttons.IndexToPosition(data.commandCount)
			end
			
			local button = data.buttons.GetButton(x, y, selectionIndex)
			
			button.SetCommand(command)
			if data.factoryQueue then
				button.SetQueueCommandParameter(factoryUnitID, nil, fakeFactory)
			end
			return
		end
	end
end

local function SetIntegralVisibility(visible)
	background:SetVisibility(visible)
	UpdateBackgroundSkin()
	
	WG.IntegralVisible = visible
	if WG.CoreSelector then
		WG.CoreSelector.SetSpecSpaceVisible(visible)
	end
end

local function ProcessAllCommands(commands, customCommands)
	local factoryUnitID, factoryUnitDefID, fakeFactory, selectedUnitCount = GetSelectionValues()

	selectionIndex = selectionIndex + 1
	
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		data.commandCount = 0
	end
	
	statePanel.commandCount = 0
	
	for i = 1, #commands do
		ProcessCommand(commands[i], factoryUnitID, factoryUnitDefID, fakeFactory, selectionIndex)
	end
	
	for i = 1, #customCommands do
		ProcessCommand(customCommands[i], factoryUnitID, factoryUnitDefID, fakeFactory, selectionIndex)
	end
	
	-- Call factory queue update here because the update will globally
	-- set queue count for the top two rows of the factory tab. Therefore
	-- the factory tab must have updated its commands.
	if factoryUnitDefID then
		for i = 1, #commandPanels do
			local data = commandPanels[i]
			if data.queue then
				if fakeFactory then
					data.queue.ClearFactory()
				else
					data.queue.UpdateFactory(factoryUnitID, factoryUnitID, selectionIndex)
					if WG.CoreSelector then
						WG.CoreSelector.ForceUpdate()
					end
				end
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
		local data = commandPanels[i]
		if data.commandCount ~= 0 then
			tabsToShow[#tabsToShow + 1] = data.tabButton
			data.buttons.ClearOldButtons(selectionIndex)
			if data.queue then
				data.queue.ClearOldButtons(selectionIndex)
			end
			if (not tabToSelect) and data.tabButton.name == lastTabSelected then
				tabToSelect = lastTabSelected
			end
		end
	end
	
	statePanel.holder:SetVisibility(statePanel.commandCount ~= 0)
	if statePanel.commandCount ~= 0 then
		statePanel.buttons.ClearOldButtons(selectionIndex)
	end
	
	if not tabToSelect then
		tabToSelect = "orders"
	end
	
	if #tabsToShow == 0 then
		tabPanel.ClearTabs()
		lastTabSelected = false
	else
		tabPanel.SetTabs(tabsToShow, #tabsToShow > 1, not factoryUnitDefID, tabToSelect)
		lastTabSelected = tabToSelect
	end
	
	-- Keeps main window for tweak mode.SetIntegralVisibility(visible)
	SetIntegralVisibility(not (#tabsToShow == 0 and selectedUnitCount == 0))
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local gridKeyMap, gridMap, gridCustomOverrides -- Configuration requires this

local function InitializeControls()
	-- Set the size for the default settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local width = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local height = math.min(screenHeight/4.5, 200*width/450)  + 8

	gridKeyMap, gridMap, gridCustomOverrides = GenerateGridKeyMap(options.keyboardType2.value)
	
	local mainWindow = Window:New{
		name      = 'integralwindow',
		x         = 0, 
		bottom    = 0,
		width     = width,
		height    = height,
		minWidth  = MIN_WIDTH,
		minHeight = MIN_HEIGHT,
		bringToFrontOnClick = false,
		dockable  = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		padding = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = screen0,
	}
	mainWindow:SendToBack()
	
	buildTabHolder = Control:New{
		x = options.leftPadding.value,
		y = "0%",
		right = options.rightPadding.value,
		height = "15%",
		padding = {2, 2, 2, -1},
		parent = mainWindow,
	}
	
	tabPanel = GetTabPanel(buildTabHolder)
	
	buttonsHolder = Control:New{
		x = options.leftPadding.value,
		y = (100/7) .. "%",
		right = options.rightPadding.value,
		bottom = 0,
		padding = {0, 0, 0, 0},
		parent = mainWindow,
	}
	
	background = Panel:New{
		x = 0,
		y = "15%",
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, options.background_opacity.value},
		noClickThrough = true,
		parent = mainWindow,
	}
	
	buildTabHolder:SendToBack() -- behind background
	
	local function ReturnToOrders(cmdID)
		if options.selectionClosesTabOnSelect.value then
			if commandPanelMap.orders then
				commandPanelMap.orders.tabButton.DoClick()
			end
		elseif options.selectionClosesTab.value and cmdID then
			returnToOrdersCommand = cmdID
		end
	end
	
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		local commandHolder = Control:New{
			x = "0%",
			y = "0%",
			width = COMMAND_SECTION_WIDTH .. "%",
			height = "100%",
			padding = {4, 6, 0, 4},
			parent = buttonsHolder,
		}
		commandHolder:SetVisibility(false)
		
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
		data.buttons = GetButtonPanel(commandHolder, 3, 6,  false, data.buttonLayoutConfig, data.isStructure, data.onClick, data.buttonLayoutOverride)
		
		if data.factoryQueue then
			local queueHolder = Control:New{
				x = "0%",
				y = "66.666%",
				width = "100%",
				height = "33.3333%",
				padding = {0, 0, 0, 0},
				parent = commandHolder,
			}
			data.queue = GetQueuePanel(queueHolder, 6)
			
			-- If many things need doing they must be put in a function
			-- but this works for now.
			OnTabSelect = data.queue.UpdateBuildProgress
		end
		
		data.tabButton = GetTabButton(tabPanel, commandHolder, data.name, data.humanName, hotkey, data.loiterable, OnTabSelect)
	
		if data.gridHotkeys and ((not data.disableableKeys) or options.unitsHotkeys2.value) then
			data.buttons.ApplyGridHotkeys(gridMap, (gridCustomOverrides and gridCustomOverrides[data.name]) or {})
		end
	end
	
	statePanel.holder = Control:New{
		x = (100 - STATE_SECTION_WIDTH) .. "%",
		y = "0%",
		width = STATE_SECTION_WIDTH .. "%",
		height = "100%",
		padding = {0, 6, 3, 4},
		parent = buttonsHolder,
	}
	statePanel.holder:SetVisibility(false)
	
	statePanel.buttons = GetButtonPanel(statePanel.holder, 5, 3, true, buttonLayoutConfig.command)
	
	SetIntegralVisibility(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Epic Menu Configuration and Hotkey Functions

local function UpdateGrid(name)
	gridKeyMap, gridMap, gridCustomOverrides = GenerateGridKeyMap(name)
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		if data.gridHotkeys and ((not data.disableableKeys) or options.unitsHotkeys2.value) then
			data.buttons.ApplyGridHotkeys(gridMap, (gridCustomOverrides and gridCustomOverrides[data.name]) or {})
		end
	end

end

function options.keyboardType2.OnChange(self)
	UpdateGrid(self.value)
end

function options.applyCustomGrid.OnChange()
	UpdateGrid(options.keyboardType2.value)
end

function options.hide_when_spectating.OnChange(self)
	local isSpec = Spring.GetSpectatingState()
	background:SetVisibility(WG.IntegralVisible and not (self.value and isSpec))
end

function options.unitsHotkeys2.OnChange(self)
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		if data.disableableKeys then
			if not options.unitsHotkeys2.value then
				data.buttons.RemoveGridHotkeys()
			else
				data.buttons.ApplyGridHotkeys(gridMap, (gridCustomOverrides and gridCustomOverrides[data.name]) or {})
			end
		end
	end
end

local function CheckTabHotkeyAllowed()
	if options.ctrlDisableGrid.value then
		local _, ctrl = Spring.GetModKeyState()
		if ctrl then
			return false
		end
	end
	return true
end

function options.tab_economy.OnChange()
	local tab = commandPanelMap.economy.tabButton
	if tab.IsTabPresent() and CheckTabHotkeyAllowed() then
		tab.DoClick()
	end
end

local function HotkeyTabDefence()
	local tab = commandPanelMap.defence.tabButton
	if tab.IsTabPresent() and CheckTabHotkeyAllowed() then
		tab.DoClick()
	end
end

local function HotkeyTabSpecial()
	local tab = commandPanelMap.special.tabButton
	if tab.IsTabPresent() and CheckTabHotkeyAllowed() then
		tab.DoClick()
	end
end

local function HotkeyTabFactory()
	local tab = commandPanelMap.factory.tabButton
	if tab.IsTabPresent() and CheckTabHotkeyAllowed() then
		tab.DoClick()
	end
end

local function HotkeyTabUnits()
	local tab = commandPanelMap.units_mobile.tabButton
	if not CheckTabHotkeyAllowed() then
		return
	end
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

options.tab_defence.OnChange = HotkeyTabDefence
options.tab_special.OnChange = HotkeyTabSpecial
options.tab_factory.OnChange = HotkeyTabFactory
options.tab_units.OnChange   = HotkeyTabUnits

function options.tabFontSize.OnChange(self)
	if commandPanels then
		for i = 1, #commandPanels do
			local data = commandPanels[i]
			data.tabButton.SetFontSize(self.value)
		end
	end
end

local function PaddingUpdate()
	buttonsHolder._relativeBounds.left = options.leftPadding.value
	buttonsHolder._relativeBounds.right = options.rightPadding.value
	buttonsHolder:UpdateClientArea()

	buildTabHolder._relativeBounds.left = options.leftPadding.value
	buildTabHolder._relativeBounds.right = options.rightPadding.value
	buildTabHolder:UpdateClientArea()
end

options.leftPadding.OnChange  = PaddingUpdate
options.rightPadding.OnChange = PaddingUpdate
options.flushLeft.OnChange = UpdateBackgroundSkin
options.fancySkinning.OnChange = UpdateBackgroundSkin

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- External functions

local externalFunctions = {} -- Appear unused in repo but are used by missions.

function externalFunctions.GetCommandButtonPosition(cmdID)
	if not buttonsByCommand[cmdID] then
		return
	end
	local button = buttonsByCommand[cmdID]
	if button and button.GetCommandID() == cmdID then
		local x, y, w, h = button.GetScreenPosition()
		return x, y, w, h
	end
end

function externalFunctions.GetTabPosition(tabName)
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		if data.name == tabName then
			local tab = data.tabButton
			local x, y, w, h = tab.GetScreenPosition()
			return x, y, w, h
		end
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local initialized = false

function widget:Update()
	local _,cmdID = Spring.GetActiveCommand()
	UpdateButtonSelection(cmdID)
	UpdateReturnToOrders(cmdID)
end

function widget:KeyPress(key, modifier, isRepeat)
	if isRepeat then
		return false
	end
	
	if returnToOrdersCommand or (modifier.ctrl and options.ctrlDisableGrid.value) then
		return false
	end
	
	local currentTab = tabPanel.GetCurrentTab()
	local commandPanel = currentTab and commandPanelMap[currentTab]
	if (not commandPanel) or (not (commandPanel.gridHotkeys and ((not commandPanel.disableableKeys) or options.unitsHotkeys2.value))) then
		return false
	end
	
	local currentKeyMap = gridKeyMap
	if gridCustomOverrides and gridCustomOverrides[currentTab] then
		currentKeyMap = gridCustomOverrides[currentTab].keyMap
	end
	
	local pos = currentKeyMap[key]
	if pos then
		local x, y = pos[2], pos[1]
		local button = commandPanel.buttons.GetButton(x, y)
		if button then
			return button.DoClick()
		end
	end

	if (key == KEYSYMS.ESCAPE or currentKeyMap[key]) and commandPanel.onClick then
		if commandPanelMap.orders then
			commandPanelMap.orders.tabButton.DoClick()
		end
		return true
	end
	return false
end

function widget:PlayerChanged(playerID)
	if options.hide_when_spectating.value then
		local isSpec = Spring.GetSpectatingState()
		background:SetVisibility(WG.IntegralVisible and not isSpec)
	end
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
		if unitsFactoryPanel and unitsFactoryPanel.tabButton.IsTabSelected() then
			unitsFactoryPanel.queue.UpdateBuildProgress()
			if WG.CoreSelector then
				WG.CoreSelector.ForceUpdate()
			end
		end
	end
end

function widget:Initialize()
	commandPanels, commandPanelMap, commandDisplayConfig, hiddenCommands, textConfig, buttonLayoutConfig, instantCommands = include(configurationName)
	
	RemoveAction("nextmenu")
	RemoveAction("prevmenu")
	initialized = true
	
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
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
	
	WG.IntegralMenu = externalFunctions
end
