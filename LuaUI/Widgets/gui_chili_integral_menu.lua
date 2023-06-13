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
-- Spring localizations
local spEcho = Spring.Echo
local spGetActiveCommand = Spring.GetActiveCommand
local spGetCmdDescIndex = Spring.GetCmdDescIndex
local spGetFactoryCommands = Spring.GetFactoryCommands
local spGetModKeyState = Spring.GetModKeyState
local spGetMouseState = Spring.GetMouseState
local spGetRealBuildQueue = Spring.GetRealBuildQueue
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetSelectedUnitsCount = Spring.GetSelectedUnitsCount
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitIsBuilding = Spring.GetUnitIsBuilding
local spGetUnitRepeat = Spring.Utilities.GetUnitRepeat
local spGetViewGeometry = Spring.GetViewGeometry
local spGiveOrderToUnit = Spring.GiveOrderToUnit
local spSetActiveCommand = Spring.SetActiveCommand

-- Configuration
include("colors.lua")
include("keysym.lua")
local specialKeyCodes = include("Configs/integral_menu_special_keys.lua")
local custom_cmd_actions = include("Configs/customCmdTypes.lua")
local cullingSettingsList, commandCulling =  include("Configs/integral_menu_culling.lua")
local transkey = include("Configs/transkey.lua")

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
local commandSectionWidth = 74 -- percent
local stateSectionWidth = 26 -- percent

local bigStateWidth, bigStateHeight = 4, 3
local smallStateWidth, smallStateHeight = 5, 3.4

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_DISABLE_COLOR = {0.1, 0.1, 0.1, 0.85}
local BUTTON_DISABLE_FOCUS_COLOR = {0.1, 0.1, 0.1, 0.85}

local DRAW_NAME_COMMANDS = {
	[CMD.STOCKPILE] = true, -- draws stockpile progress (command handler sends correct string).
}

local DYNAMIC_COMMANDS = {
	[CMD_ONECLICK_WEAPON] = true,
	[CMD.MANUALFIRE] = true,
}

local REMOVE_TAG_FRAMES = 180 -- Game frames between reseting the tag removal table.

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

if modOptions.campaign_debug_units ~= "1" then
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

local commandPanels, commandPanelMap, commandDisplayConfig, hiddenCommands, textConfig, buttonLayoutConfig, instantCommands, cmdPosDef = include("Configs/integral_menu_config.lua")

local statePanel = {}
local tabPanel
local selectionIndex = 0
local background
local returnToOrdersCommand = false
local simpleModeEnabled = true

local buildTabHolder, buttonsHolder -- Required for padding update setting
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Options

options_path = 'Settings/HUD Panels/Command Panel'
options_order = {
	'simple_mode', 'enable_return_fire', 'enable_roam',
	'background_opacity', 'keyboardType2',  'selectionClosesTab', 'selectionClosesTabOnSelect', 'altInsertBehind',
	'unitsHotkeys2', 'ctrlDisableGrid', 'hide_when_spectating', 'applyCustomGrid', 'label_apply',
	'label_tab', 'tab_economy', 'tab_defence', 'tab_special', 'tab_factory', 'tab_units',
	'tabFontSize', 'leftPadding', 'rightPadding', 'flushLeft', 'fancySkinning',
	'helpwindow', 'commands_reset_default', 'commands_enable_all', 'commands_disable_all', 'states_enable_all', 'states_disable_all',
}

local commandPanelPath = 'Hotkeys/Grid Hotkeys'
local customGridPath = 'Hotkeys/Grid Hotkeys/Custom'
local commandOptPath = 'Settings/Interface/Commands'

local function UpdateHolderSizes()
	if statePanel.buttons then
		if simpleModeEnabled then
			statePanel.buttons.SetDimensions(bigStateWidth, bigStateHeight, true)
		else
			statePanel.buttons.SetDimensions(smallStateWidth, smallStateHeight, true)
		end
	end
end

WG.RemoveReturnFireState = true -- matches default
WG.RemoveRoamState = true -- matches default

options = {
	simple_mode = {
		name = "Large State Icons",
		desc = "Large state icons are arranged in four rows and display their hotkey (if the hotkey is short). When disabled, the icons are arranged in five rows and do not display hotkeys. Individual states can be added or removed under Settings -> Interface -> Commands.",
		type = 'bool',
		value = true,
		OnChange = function(self)
			simpleModeEnabled = self.value
			UpdateHolderSizes()
		end,
	},
	enable_return_fire = {
		name = "Enable return fire state",
		desc = "When enabled, the Hold Fire state is extended to a three-option toggle with Return Fire as an additional option.",
		type = 'bool',
		value = false,
		OnChange = function(self)
			WG.RemoveReturnFireState = not self.value
			if commandDisplayConfig then
				commandDisplayConfig[CMD.FIRE_STATE].useAltConfig = self.value
			end
			UpdateHolderSizes() -- Need to delete buttons to change tooltips
		end,
		path = commandOptPath,
		simpleMode = true,
		everyMode = true,
	},
	enable_roam = {
		name = "Enable roam move state",
		desc = "When enabled, the Hold Position state is extended to a three-option toggle with Roam as an additional option.",
		type = 'bool',
		value = false,
		OnChange = function(self)
			WG.RemoveRoamState = not self.value
			if commandDisplayConfig then
				commandDisplayConfig[CMD.MOVE_STATE].useAltConfig = self.value
			end
			UpdateHolderSizes() -- Need to delete buttons to change tooltips
		end,
		path = commandOptPath,
		simpleMode = true,
		everyMode = true,
	},
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
			{name = 'Dvorak (standard)', key = 'dvorak', hotkey = nil},
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
	},
	label_apply = {
		type = 'text',
		name = 'Note: Click above to refresh',
		value = 'Update modified custom grid hotkeys by clicking the button above. Reselecting any selected units may also be required. Note that "Apply Changes" can be bound to a key for convinence.',
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
	
	helpwindow = {
		name = 'Command Visibility',
		type = 'text',
		value = "Each command can be hidden from the command panel, with some advanced ones hidden by default. Hotkeys can be used to issue commands or toggle states even when hidden.",
		path = commandOptPath,
		simpleMode = true,
		everyMode = true,
	},
	commands_reset_default = {
		type = 'button',
		name = "Reset to default",
		desc = "Show the basic commands and hide the advanced ones",
		OnChange = function ()
			for i = 1, #cullingSettingsList do
				local data = cullingSettingsList[i]
				if data.cmdID then
					local name = "cmd_" .. data.cmdID
					options[name].value = data.default
					commandCulling[data.cmdID] = not data.default
				end
			end
		end,
		path = commandOptPath .. '/Presets',
		simpleMode = true,
		everyMode = true,
	},
	commands_enable_all = {
		type = 'button',
		name = "Show all commands",
		OnChange = function ()
			for i = 1, #cullingSettingsList do
				local data = cullingSettingsList[i]
				if data.cmdID and not data.state then
					local name = "cmd_" .. data.cmdID
					options[name].value = true
					commandCulling[data.cmdID] = false
				end
			end
		end,
		path = commandOptPath .. '/Presets',
		simpleMode = true,
		everyMode = true,
	},
	commands_disable_all = {
		type = 'button',
		name = "Hide all commands",
		OnChange = function ()
			for i = 1, #cullingSettingsList do
				local data = cullingSettingsList[i]
				if data.cmdID and not data.state then
					local name = "cmd_" .. data.cmdID
					options[name].value = false
					commandCulling[data.cmdID] = true
				end
			end
		end,
		path = commandOptPath .. '/Presets',
		simpleMode = true,
		everyMode = true,
	},
	states_enable_all = {
		type = 'button',
		name = "Show all states",
		OnChange = function ()
			for i = 1, #cullingSettingsList do
				local data = cullingSettingsList[i]
				if data.cmdID and data.state then
					local name = "cmd_" .. data.cmdID
					options[name].value = true
					commandCulling[data.cmdID] = false
				end
			end
		end,
		path = commandOptPath .. '/Presets',
		simpleMode = true,
		everyMode = true,
	},
	states_disable_all = {
		type = 'button',
		name = "Hide all states",
		OnChange = function ()
			for i = 1, #cullingSettingsList do
				local data = cullingSettingsList[i]
				if data.cmdID and data.state then
					local name = "cmd_" .. data.cmdID
					options[name].value = false
					commandCulling[data.cmdID] = true
				end
			end
		end,
		path = commandOptPath .. '/Presets',
		simpleMode = true,
		everyMode = true,
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
	local _,_, meta,_ = spGetModKeyState()
	if not meta then
		return false
	end
	WG.crude.OpenPath(options_path) --// click+ space on integral-menu tab will open a integral options.
	WG.crude.ShowMenu() --make epic Chili menu appear.
	return true
end

local function AddCommandCullOptions()
	for i = 1, #cullingSettingsList do
		local data = cullingSettingsList[i]
		if data.label then
			local name = "integralCommands" .. data.label
			options[name] = {
				type = 'label',
				name = data.label,
				path = commandOptPath,
				simpleMode = true,
				everyMode = true,
			}
			options_order[#options_order + 1] = name
		else
			local name = "cmd_" .. data.cmdID
			options[name] = {
				name = data.name,
				desc = "Show the " .. data.name .. (data.state and " state" or " command") ..  " on the command panel.",
				type = 'bool',
				value = not commandCulling[data.cmdID],
				noHotkey = true,
				OnChange = function(self)
					commandCulling[data.cmdID] = not self.value
				end,
				path = commandOptPath,
				simpleMode = true,
				everyMode = true,
			}
			options_order[#options_order + 1] = name
		end
	end
end

AddCommandCullOptions()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Very Global Globals

local buttonsByCommand = {}
local alreadyRemovedTag = {}
local lastRemovedTagResetFrame = false

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
		local alt, ctrl, meta, shift = spGetModKeyState()
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
				spEcho("LUA_ERRRUN", "Integral menu missing key for", i, j, name)
			end
		end
	end
	return ret, gridMap
end

local function RemoveAction(cmd, types)
	return widgetHandler.actionHandler:RemoveAction(widget, cmd, types)
end

--- Returns:
--- - hotkey: string - nil if hotkey is not set
local function GetHotkeyText(actionName)
	local hotkey = WG.crude.GetHotkey(actionName)
	if hotkey ~= '' then
		return GetGreenStr(hotkey)
	end
	return nil
end

--- Returns:
--- - states: Table - See customCmdTypes.lua
--- - hotkeys: Table[state_idx, value_text], nil if action cannot be found or action has no states; value_text is
---   "(none)" if a hotkey is not set
--- - n: Integer - number of hotkeys that are set, nil under same conditions as for hotkeys
local function GetHotkeysForStatesText(action_name)
	local action = custom_cmd_actions[action_name]
	if not action then return nil end
	local states = action.states
	if not states then return nil end
	local hotkeys = {}
	local n = 0
	for state_idx = 1, #states do
		local hotkey = WG.crude.GetHotkey(action_name .. " " .. (state_idx - 1))
		if not hotkey or hotkey == '' then
			hotkey = "(none)"
		else
			n = n + 1
		end
		hotkeys[state_idx] = hotkey
	end
	return action.states, hotkeys, n
end

local function GetActionHotkey(actionName)
	return WG.crude.GetHotkey(actionName)
end

--- Combines the information about the command, its state and hotkeys
local function GetButtonTooltip(displayConfig, command, state)
	local PARAGRAPH = "\n  "

	local tooltip = state and displayConfig and displayConfig.stateTooltip and displayConfig.stateTooltip[state]
	if not tooltip then
		tooltip = (displayConfig and displayConfig.tooltip) or (command and command.tooltip)
	end
	if not tooltip then
		return nil
	end

	local action_name = command.action
	if not action_name then
		return nil
	end

	-- Append Toggle hotkey
	local hotkey_for_toggle = GetHotkeyText(action_name)
	if hotkey_for_toggle then
		tooltip = tooltip .. " (" .. GetGreenStr(hotkey_for_toggle) .. ")"
	end

	-- Append State hotkeys if any are set
	local states, hotkeys_for_states, number_of_set_hotkeys = GetHotkeysForStatesText(action_name)
	if displayConfig and displayConfig.stateNameOverride then
		states = displayConfig.stateNameOverride
	end
	
	if hotkeys_for_states and number_of_set_hotkeys > 0 then
		tooltip = tooltip .. PARAGRAPH .. "State Hotkeys:"
		for i = 1, #states do
			local state_name = states[i]
			local hotkey = hotkeys_for_states[i]
			tooltip = tooltip .. PARAGRAPH .. GetGreenStr(state_name .. ": " .. hotkey)
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
		local selectedCount = spGetSelectedUnitsCount()
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

local function GetCmdPosParameters(cmdID)
	local def =  cmdPosDef[cmdID]
	if (not def) and cmdID >= CMD_MORPH and cmdID < CMD_MORPH + 2000 then -- Includes CMD_MORPH and CMD_MORPH_STOP
		def = cmdPosDef[CMD_MORPH]
	end
	
	if def then
		if simpleModeEnabled and def.posSimple then
			return def.posSimple, def.priority
		end
		return def.pos, def.priority
	end
	--spEcho("Unknown GetCmdPosParameters", cmdID)
	return 1, 100
end

local function GetDisplayConfig(cmdID)
	local displayConfig = commandDisplayConfig[cmdID]
	if not displayConfig then
		return
	end
	if displayConfig.useAltConfig then
		return displayConfig.altConfig
	end
	return displayConfig
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Command Queue Editing Implementation

local function MoveOrRemoveCommands(cmdID, factoryUnitID, commands, queuePosition, inputMult, reinsertPosition)
	if not commands then
		return
	end
	
	if (not lastRemovedTagResetFrame) or lastRemovedTagResetFrame + REMOVE_TAG_FRAMES < Spring.GetGameFrame() then
		alreadyRemovedTag = {}
		lastRemovedTagResetFrame = Spring.GetGameFrame()
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
			spGiveOrderToUnit(factoryUnitID, CMD.REMOVE, {cmdTag}, CMD.OPT_CTRL)
			if reinsertPosition then
				local opts = thisCmd.options
				local coded = opts.coded
				spGiveOrderToUnit(factoryUnitID, CMD.INSERT, {reinsertPosition, cmdID, coded}, CMD.OPT_CTRL + CMD.OPT_ALT)
			end
			j = j + 1
		end
		i = i - 1
	end
end

local function MoveCommandBlock(factoryUnitID, queueCmdID, moveBlock, insertBlock)
	local commands = spGetFactoryCommands(factoryUnitID, -1)
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
	local commands = spGetFactoryCommands(factoryUnitID, -1)
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
		spGiveOrderToUnit(factoryUnitID, CMD.INSERT, {queuePosition, queueCmdID, 0 }, CMD.OPT_ALT + CMD.OPT_CTRL)
	end
	return true
end

local function ClickFunc(mouse, cmdID, isStructure, factoryUnitID, fakeFactory, isQueueButton, queueBlock)
	local left, right = mouse == 1, mouse == 3
	local alt, ctrl, meta, shift = spGetModKeyState()
	
	-- RMB beats Alt since Alt is opposed to the concept of removing orders.
	if right then
		alt = false
	end
	
	if factoryUnitID and isQueueButton then
		if meta and cmdID then
			local bq = Spring.GetUnitCmdDescs(factoryUnitID)
			local bqidx = Spring.FindUnitCmdDesc(factoryUnitID, cmdID)
			if bqidx then
				local cmddsc = bq[bqidx]
				if cmddsc then
					local udid = UnitDefNames[cmddsc.name]
					if udid then
						local x, y = spGetMouseState()
						WG.MakeStatsWindow(udid, x, y, factoryUnitID)
					end
				end
			end
		else
			QueueClickFunc(mouse, right, alt, ctrl, meta, shift, cmdID, factoryUnitID, queueBlock)
		end
		return true
	end

	if alt and factoryUnitID and options.altInsertBehind.value and (not fakeFactory) then
		-- Repeat alt has to be handled by engine so that the command is removed after completion.
		if not spGetUnitRepeat(factoryUnitID) then
			local inputMult = 1*(shift and 5 or 1)*(ctrl and 20 or 1)
			for i = 1, inputMult do
				spGiveOrderToUnit(factoryUnitID, CMD.INSERT, {1, cmdID, 0 }, CMD.OPT_ALT + CMD.OPT_CTRL)
			end
			if WG.noises then
				WG.noises.PlayResponse(factoryUnitID, cmdID)
			end
			return true
		end
	end
	
	local index = spGetCmdDescIndex(cmdID)
	if index then
		spSetActiveCommand(index, mouse or 1, left, right, alt, ctrl, meta, shift)
		if not instantCommands[cmdID] then
			UpdateButtonSelection(cmdID)
		end
		if alt and isStructure and WG.Terraform_SetPlacingRectangleCheck and WG.Terraform_SetPlacingRectangleCheck() then
			WG.Terraform_SetPlacingRectangle(-cmdID)
		end
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Button Panel

local function GetButton(parent, name, selectionIndex, x, y, xStr, yStr, width, height, buttonLayout, isStructure, onClick)
	local cmdID
	local isStateCommand
	local usingGrid
	local factoryUnitID
	local fakeFactory
	local queueCount
	local isDisabled = false
	local isSelected = false
	local isQueueButton = buttonLayout.queueButton
	local hotkeyText
	local keyToShowWhenVisible
	
	local function DoClick(_, _, _, mouse)
		if buttonLayout.ClickFunction and buttonLayout.ClickFunction(cmdID and instantCommands[cmdID], isStateCommand) then
			return false
		end
		if isDisabled then
			return false
		end
		local success = ClickFunc(mouse, cmdID, isStructure, factoryUnitID, fakeFactory, isQueueButton, x)
		if success and onClick then
			-- Don't do the onClick if the command was not eaten by the menu.
			onClick(cmdID)
		end
		return success
	end
	
	local button = Button:New {
		name = name,
		x = xStr,
		y = yStr,
		width = width,
		height = height,
		caption = buttonLayout.caption or false,
		noFont = not buttonLayout.caption,
		objectOverrideFont = WG.GetFont(14),
		padding = {0, 0, 0, 0},
		parent = parent,
		preserveChildrenOrder = true,
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
				name = name .. "_image",
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
				name = name .. "_text_" .. config.name,
				x = config.x,
				y = config.y,
				right = config.right,
				bottom = config.bottom,
				height = config.height,
				align = config.align,
				fontsize = config.fontsize,
				objectOverrideFont = WG.GetFont(config.fontsize),
				caption = text,
				parent = button,
			}
			textBoxes[textPosition]:BringToFront()
			return
		end
		
		local newVisible = ((text and true) or false)
		
		if (not newVisible) and (not textBoxes[textPosition].visible) then
			return
		end
		textBoxes[textPosition]:SetVisibility(newVisible)
		
		if (not newVisible) or (text == textBoxes[textPosition].caption) then
			return
		end
		textBoxes[textPosition]:SetCaption(text)
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
			caption = false,
			noFont = true,
			color           = {0.7, 0.7, 0.4, 0.6},
			backgroundColor = {1, 1, 1, 0.01},
			parent = image,
			skin = nil,
			skinName = 'default',
		}
	end
	
	local function IsVisible()
		return button.parent and button.parent.visible
	end
	
	function externalFunctionsAndData.RemoveGridHotkey(onlyWhenVisible)
		if onlyWhenVisible and not IsVisible() then
			keyToShowWhenVisible = -1
			return
		end
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
	
	local function SetGridKey(key)
		usingGrid = true
		hotkeyText = GetGreenStr(transkey[string.lower(key)] or key)
		SetText(textConfig.topLeft.name, hotkeyText)
	end
	
	function externalFunctionsAndData.UpdateGridHotkey(myGridMap, myOverride, onlyWhenVisible)
		local key
		if myOverride then
			key = myOverride[y] and myOverride[y][x]
		else
			key = myGridMap[y] and myGridMap[y][x]
		end

		if onlyWhenVisible and not IsVisible() then
			keyToShowWhenVisible = key or -1
			return
		end

		if not key then
			externalFunctionsAndData.RemoveGridHotkey()
			return
		end
		SetGridKey(key)
	end
	
	function externalFunctionsAndData.OnVisibleGridKeyUpdate()
		if not keyToShowWhenVisible then
			return
		end
		if keyToShowWhenVisible == -1 then
			externalFunctionsAndData.RemoveGridHotkey()
			keyToShowWhenVisible = false
			return
		end
		SetGridKey(keyToShowWhenVisible)
		keyToShowWhenVisible = false
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
						local buildQueue = spGetRealBuildQueue(factoryUnitID)
						
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
		
		isStateCommand = command and (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
		local state = isStateCommand and (((WG.GetOverriddenState and WG.GetOverriddenState(newCmdID)) or command.params[1]) + 1)
		if cmdID == newCmdID then
			if isStateCommand then
				local displayConfig = GetDisplayConfig(cmdID)
				if displayConfig then
					local texture = displayConfig.texture[state]
					if displayConfig.stateTooltip then
						button.tooltip = GetButtonTooltip(displayConfig, command, state)
					end
					SetImage(texture)
				end
			elseif newCmdID and DYNAMIC_COMMANDS[newCmdID] then
				-- Reset potentially stale special weapon iamge and tooltip.
				-- Action is the same so hotkey does not require a reset.
				local displayConfig = GetDisplayConfig(cmdID)
				button.tooltip = GetButtonTooltip(displayConfig, command, state)
				local texture = (displayConfig and displayConfig.texture) or command.texture
				SetImage(texture)
			end
			if not notGlobal then
				buttonsByCommand[cmdID] = externalFunctionsAndData
			end
			if buildProgress then
				externalFunctionsAndData.SetProgressBar(0)
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
		
		local displayConfig = GetDisplayConfig(cmdID)
		button.tooltip = GetButtonTooltip(displayConfig, command, state)
		
		if command.action then
			local hotkey = GetHotkeyText(command.action)
			if not (isStateCommand or usingGrid) then
				hotkeyText = hotkey
				SetText(textConfig.topLeft.name, hotkey)
			end
			if simpleModeEnabled and isStateCommand then
				hotkey = hotkey and not string.find(hotkey, "+") and hotkey -- Only show short hotkeys.
				hotkeyText = hotkey
				SetText(textConfig.topLeft.name, hotkey)
			end
		end
		
		if isStateCommand then
			if displayConfig then
				local texture = displayConfig.texture[state]
				SetImage(texture)
			else
				spEcho("Error, missing command config", cmdID)
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
	
	function externalFunctionsAndData.Delete()
		button:Dispose()
	end

	return externalFunctionsAndData
end

local function GetButtonPanel(parent, name, rows, columns, vertical, generalButtonLayout, generalIsStructure, onClick, buttonLayoutOverride)
	local buttons = {}
	local buttonList = {}
	
	local cmdPosition = {}
	local positionCmd = {}
	
	local width = tostring(100/columns) .. "%"
	local height = tostring(100/rows) .. "%"
	local buttonSpace = math.floor(rows)*math.floor(columns)
	
	local gridMap, override
	local gridEnabled = true
	local gridUpdatedSinceVisible = false
	
	local externalFunctions = {}
	
	function externalFunctions.ClearOldButtons(selectionIndex)
		for i = 1, #buttonList do
			local button = buttonList[i]
			if button.selectionIndex ~= selectionIndex then
				parent:RemoveChild(button.button)
			end
		end
	end
	
	function externalFunctions.DeleteButtons()
		for i = 1, #buttonList do
			buttonList[i].Delete()
		end
		buttons = {}
		buttonList = {}
	end
	
	function externalFunctions.GetButton(x, y, selectionIndex)
		if buttons[x] and buttons[x][y] then
			if not buttons[x][y].button.parent then
				if not selectionIndex then
					return false
				end
				buttons[x][y].OnVisibleGridKeyUpdate()
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
		
		newButton = GetButton(parent, name .. "_".. x .. "_" .. y, selectionIndex, x, y, xStr, yStr, width, height, buttonLayout, isStructure, onClick)
		
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
	
	function externalFunctions.CommandToPosition(cmdID, count)
		local index = cmdPosition[cmdID] or count or 1
		local x, y = externalFunctions.IndexToPosition(index)
		return x, y, index <= buttonSpace
	end
	
	function externalFunctions.ResetCommandPositions(cmdID)
		cmdPosition = {}
		positionCmd = {}
	end
	
	function externalFunctions.AddCommandPosition(cmdID)
		local pos, priority = GetCmdPosParameters(cmdID)
		while positionCmd[pos] do
			local otherCmdID = positionCmd[pos]
			local _, otherPriority = GetCmdPosParameters(otherCmdID)
			if (priority < otherPriority) then
				-- Displace old command. Priority 1 displaces priority 2.
				cmdPosition[cmdID] = pos
				positionCmd[pos] = cmdID
				cmdID = otherCmdID
				priority = otherPriority
			end
			pos = pos + 1
		end
		cmdPosition[cmdID] = pos
		positionCmd[pos] = cmdID
		return
	end
	
	function externalFunctions.ApplyGridHotkeys(newGridMap, newOverride, updateNonVisible)
		gridMap = newGridMap or gridMap
		override = newOverride or override
		gridEnabled = true
		for i = 1, #buttonList do
			buttonList[i].UpdateGridHotkey(gridMap, override and override.gridMap, not updateNonVisible)
		end
		if (not parent.visible) and (not updateNonVisible) then
			gridUpdatedSinceVisible = true
		end
	end
	
	function externalFunctions.RemoveGridHotkeys()
		gridEnabled = false
		for i = 1, #buttonList do
			buttonList[i].RemoveGridHotkey(true)
		end
		if not parent.visible then
			gridUpdatedSinceVisible = true
		end
	end
	
	function externalFunctions.OnSelect()
		if not gridUpdatedSinceVisible then
			return
		end
		for i = 1, #buttonList do
			buttonList[i].OnVisibleGridKeyUpdate()
		end
		gridUpdatedSinceVisible = false
	end
	
	function externalFunctions.SetDimensions(newRows, newColumns, newVertical)
		rows, columns, vertical = newRows, newColumns, newVertical
		width = tostring(100/columns) .. "%"
		height = tostring(100/rows) .. "%"
		buttonSpace = math.floor(rows)*math.floor(columns)
		externalFunctions.DeleteButtons()
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
	
	local buttons = GetButtonPanel(parent, "queuePanel", 1, columns, false, buttonLayoutConfig.queue, false, nil, buttonLayoutOverride)

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
		local unitBuildID = spGetUnitIsBuilding(factoryUnitID)
		if not unitBuildID then
			button.SetProgressBar(0)
			return
		end
		local progress = select(5, spGetUnitHealth(unitBuildID))
		button.SetProgressBar(progress)
	end
	
	function externalFunctions.ClearFactory()
		factoryUnitID = false
		factoryUnitDefID = false
	end
	
	function externalFunctions.UpdateFactory(newFactoryUnitID, newFactoryUnitDefID, selectionIndex)
		local buttonCount = 0
		factoryUnitID = newFactoryUnitID
		factoryUnitDefID = newFactoryUnitDefID
	
		local buildQueue = spGetRealBuildQueue(factoryUnitID)
	
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
		objectOverrideFont = WG.GetFont(14),
		OnClick = {
			function()
				DoClick(true)
			end
		},
	}
	button.backgroundColor[4] = 0.4
	
	if disabled then
		button.font = WG.GetSpecialFont(14, "integral_grey", {outlineColor = {0, 0, 0, 1}, color = {0.6, 0.6, 0.6, 1}})
		button.supressButtonReaction = true
	end
	
	local hideHotkey = loiterable
	
	if hotkey and (not hideHotkey) and (not disabled) then
		button:SetCaption(humanName .. " (" .. GetGreenStr(hotkey) .. ")")
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
			button:SetCaption(humanName .. " (" .. GetGreenStr(hotkey) .. ")")
		else
			button:SetCaption(humanName .. " (" .. hotkey .. ")")
		end
	end
	
	function externalFunctionsAndData.SetHideHotkey(newHidden)
		if (not loiterable) or disabled then
			return
		end
		hideHotkey = newHidden
		if hideHotkey then
			button:SetCaption(humanName)
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
	local selection = spGetSelectedUnits()
	for i = 1, #selection do
		local unitID = selection[i]
		local defID = spGetUnitDefID(unitID)
		if defID and (UnitDefs[defID].isFactory or UnitDefs[defID].customParams.isfakefactory) and (not UnitDefs[defID].customParams.notreallyafactory) then
			return unitID, defID, UnitDefs[defID].customParams.isfakefactory, #selection
		end
	end
	return false, nil, nil, #selection
end

local function HiddenCommand(command)
	return hiddenCommands[command.id] or command.hidden or (commandCulling and commandCulling[command.id])
end

local function ProcessCommandPosition(command)
	if HiddenCommand(command) then
		return
	end

	local isStateCommand = (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
	if isStateCommand then
		statePanel.buttons.AddCommandPosition(command.id)
		return
	end
	
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		if not data.isBuild then
			local found, position = data.inclusionFunction(command.id, factoryUnitDefID)
			if found then
				data.buttons.AddCommandPosition(command.id)
			end
		end
	end
end

local function ProcessCommand(command, factoryUnitID, factoryUnitDefID, fakeFactory, selectionIndex)
	if HiddenCommand(command) then
		return
	end

	local isStateCommand = (command.type == CMDTYPE.ICON_MODE and #command.params > 1)
	if isStateCommand then
		statePanel.commandCount = statePanel.commandCount + 1
		
		local x, y, spaceAvailible = statePanel.buttons.CommandToPosition(command.id, statePanel.commandCount)
		if not spaceAvailible then
			statePanel.commandCount = statePanel.commandCount - 1
			return
		end
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
				x, y = data.buttons.CommandToPosition(command.id, data.commandCount)
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
		if not data.isBuild then
			data.buttons.ResetCommandPositions()
		end
	end
	
	statePanel.commandCount = 0
	statePanel.buttons.ResetCommandPositions()
	
	for i = 1, #commands do
		ProcessCommandPosition(commands[i])
	end
	
	for i = 1, #customCommands do
		ProcessCommandPosition(customCommands[i])
	end
	
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
	local screenWidth, screenHeight = spGetViewGeometry()
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
		noFont = true,
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
		noFont = true,
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
			width = commandSectionWidth .. "%",
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
		
		
		data.holder = commandHolder
		data.buttons = GetButtonPanel(commandHolder, data.name, 3, 6,  false, data.buttonLayoutConfig, data.isStructure, data.onClick, data.buttonLayoutOverride)
		local OnTabSelect = data.buttons.OnSelect
		
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
			OnTabSelect = function ()
				data.queue.UpdateBuildProgress()
				data.buttons.OnSelect()
			end
		end
		
		data.tabButton = GetTabButton(tabPanel, commandHolder, data.name, data.humanName, hotkey, data.loiterable, OnTabSelect)
	
		if data.gridHotkeys and ((not data.disableableKeys) or options.unitsHotkeys2.value) then
			data.buttons.ApplyGridHotkeys(gridMap, (gridCustomOverrides and gridCustomOverrides[data.name]) or {})
		end
	end
	
	statePanel.holder = Control:New{
		x = (100 - stateSectionWidth) .. "%",
		y = "0%",
		width = stateSectionWidth .. "%",
		height = "100%",
		padding = {0, 6, 3, 4},
		parent = buttonsHolder,
	}
	statePanel.holder:SetVisibility(false)
	
	statePanel.buttons = GetButtonPanel(statePanel.holder, "statePanel",
		simpleModeEnabled and bigStateWidth or smallStateWidth,
		simpleModeEnabled and bigStateHeight or smallStateHeight,
		true,
		buttonLayoutConfig.command
	)
	
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
			data.buttons.ApplyGridHotkeys(gridMap, (gridCustomOverrides and gridCustomOverrides[data.name]) or {}, true)
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
	local isSpec = spGetSpectatingState()
	background:SetVisibility(WG.IntegralVisible and not (self.value and isSpec))
end

function options.unitsHotkeys2.OnChange(self)
	for i = 1, #commandPanels do
		local data = commandPanels[i]
		if data.disableableKeys then
			if not options.unitsHotkeys2.value then
				data.buttons.RemoveGridHotkeys()
			else
				data.buttons.ApplyGridHotkeys(gridMap, (gridCustomOverrides and gridCustomOverrides[data.name]) or {}, true)
			end
		end
	end
end

local function CheckTabHotkeyAllowed()
	local alt, ctrl = spGetModKeyState()
	if alt then
		return false
	end
	if options.ctrlDisableGrid.value then
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
local initialized = false

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

function externalFunctions.UpdateCommands()
	if not initialized then
		return
	end

	local commands = widgetHandler.commands
	local customCommands = widgetHandler.customCommands
	ProcessAllCommands(commands, customCommands)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Update()
	local _,cmdID = spGetActiveCommand()
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
		local isSpec = spGetSpectatingState()
		background:SetVisibility(WG.IntegralVisible and not isSpec)
	end
end

function widget:CommandsChanged()
	externalFunctions.UpdateCommands()
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
