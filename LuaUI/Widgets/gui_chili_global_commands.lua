function widget:GetInfo()
	return {
		name      = "Chili Global Commands",
		desc      = "Holds global commands, map overlays, playerlist display and other stuff.",
		author    = "GoogleFrog",
		date      = "16 November 2016",
		license   = "GNU GPL, v2 or later",
		layer     = -11,
		enabled   = false,
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local BUTTON_Y = 0
local BUTTON_SIZE = 25
local BUTTON_PLACE_SPACE = 27

local mainWindow
local contentHolder
local commandButtonOffset

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

local function toggleTeamColors()
	if WG.LocalColor and WG.LocalColor.localTeamColorToggle then
		WG.LocalColor.localTeamColorToggle()
	else
		Spring.SendCommands("luaui enablewidget Local Team Colors")
	end
end

local globalCommands = {
	
}

local teamcolor_selector, mapOverlay

local buttons = {}
local strings = {
	toggle_eco_display = {"", ""},
	place_retreat_zone = {"", ""},
	place_ferry_route = {"", ""},
	viewstandard = {"", ""},
	viewheightmap = {"", ""},
	viewblockmap = {"", ""},
	viewfow = {"", ""},
	clearmapmarks = {"", ""},
	lastmsgpos = {"", ""},
}

options_path = 'Settings/HUD Panels/Global Commands'
options = {
	background_opacity = {
		type = "number",
		value = 1, min = 0, max = 1, step = 0.01,
	},
	clearmapmarks = {
		type = 'button',
		action = 'clearmapmarks',
	},	
	lastmsgpos = {
		type = 'button',
		action = 'lastmsgpos',
	},
	viewstandard = {
		type = 'button',
		action = 'showstandard',
	},
	viewheightmap = {
		type = 'button',
		action = 'showelevation',
	},
	viewblockmap = {
		type = 'button',
		action = 'showpathtraversability',
	},
	viewfow = {
		type = 'button',
		action = 'togglelos',
	},
	simplifiedteamcolor = {
		name = 'Simplified Team Colors',
		desc = 'Toggles simplified team colors.',
		type = 'button',
		OnChange = toggleTeamColors,
	},
	showeco = {
		name = 'Toggle Economy Overlay',
		desc = 'Show metal, geo spots and energy grid',
		hotkey = {key='f4', mod=''},
		type ='button',
		action='showeco',
		noAutoControlFunc = true,
		OnChange = function(self)
			if (WG.ToggleShoweco) then
				WG.ToggleShoweco()
			end
		end,
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'radioButton',
		value = 'panel',
		items = {
			{key = 'panel', name = 'None'},
			--{key = 'panel_0001', name = 'Flush',},
			{key = 'panel_0001_small', name = 'Flush Small',},
			{key = 'panel_1001_small', name = 'Top Left',},
		},
		OnChange = function (self)
			local currentSkin = Chili.theme.skin.general.skinName
			local skin = Chili.SkinHandler.GetSkin(currentSkin)
			
			local className = self.value
			local newClass = skin.panel
			if skin[className] then
				newClass = skin[className]
			end
			
			contentHolder.tiles = newClass.tiles
			contentHolder.TileImageFG = newClass.TileImageFG
			--contentHolder.backgroundColor = newClass.backgroundColor
			contentHolder.TileImageBK = newClass.TileImageBK
			if newClass.padding then
				contentHolder.padding = className.padding
				contentHolder:UpdateClientArea()
			end
			contentHolder:Invalidate()
		end,
		hidden = true,
		noHotkey = true,
	},
	hide = {
		name = 'Hide GBC',
		desc = 'Hides the Global Bar of Commands.',
		type = 'bool',
		value = false,
		hidden = true, -- hidden on purpose
		noHotkey = true,
		OnChange = function (self)
			if not mainWindow then
				return
			end
			if self.value then
				mainWindow:Hide()
			else
				mainWindow:Show()
			end
		end,
	},
}

local function languageChanged ()
	for k, str in pairs(strings) do
		str[1] = WG.Translate ("interface", k .. "_name")
		str[2] = WG.Translate ("interface", k .. "_desc")
	end

	options.background_opacity.name = WG.Translate ("interface", "opacity")

	local bulk_translate_options = {"viewstandard", "viewheightmap", "viewfow", "viewblockmap", "clearmapmarks", "lastmsgpos"}
	for i = 1, #bulk_translate_options do
		local opt = bulk_translate_options[i]
		options[opt].name = strings[opt][1]
		options[opt].desc = strings[opt][2]
	end

	teamcolor_selector.tooltip = WG.Translate("interface", "teamcolor_selector")
	teamcolor_selector:Invalidate()
	mapOverlay.UpdateTooltip(WG.Translate("interface", "overlay_selector"))

	for k, button in pairs(buttons) do

		local name, desc
		local option = button.crude_option
		local hotkey = ''
		if option then
			name = options[option].name
			desc = options[option].desc
			local action = WG.crude.GetActionName(options_path, options[option])
			if action then
				hotkey = WG.crude.GetHotkey(action)
				if hotkey ~= '' then
					hotkey = ' (\255\0\255\0' .. hotkey:upper() .. '\008)'
				end
			end
		else
			local str = strings[k]
			name = str[1]
			desc = str[2]
		end

		if desc then
			desc = "\n\n" .. desc
		else
			desc = ''
		end
		button.tooltip = name .. hotkey .. desc
		button:Invalidate()
	end
end

local commandButtonMouseDown = { 
	function(self)
		local _,_, meta,_ = Spring.GetModKeyState()
		if not meta then 
			return false
		end
		WG.crude.OpenPath("Hotkeys/Commands")
		WG.crude.ShowMenu() --make epic Chili menu appear.
		return true
	end 
}

local globalMouseDown = { 
	function(self)
		local _,_, meta,_ = Spring.GetModKeyState()
		if not meta then 
			return false
		end
		WG.crude.OpenPath(options_path)
		WG.crude.ShowMenu() --make epic Chili menu appear.
		return true
	end 
}

local function MakeCommandButton(parent, position, file, params, vertical, onClick)
	local option = params.option
	local name, desc, action, hotkey, command
	if option then
		action = WG.crude.GetActionName(options_path, options[option])
	end
	name = params.name or ""
	desc = params.desc or ""
	action = action or params.action
	command = params.command
	
	local btn = Chili.Button:New{
		x = (vertical and 0) or ((position - 1)*BUTTON_PLACE_SPACE + BUTTON_Y),
		y = (vertical and ((position - 1)*BUTTON_PLACE_SPACE + BUTTON_Y)) or BUTTON_Y,
		width = BUTTON_SIZE, 
		height = BUTTON_SIZE,
		classname = "button_tiny",
		caption = "",
		margin = {0,0,0,0},
		padding = {2,2,2,2},
		tooltip = name .. desc,
		parent = parent,
		crude_option = option,
		OnMouseDown = (command and commandButtonMouseDown) or globalMouseDown,
		OnClick = {
			function(self)
				if command then
					local left, right = true, false
					local alt, ctrl, meta, shift = Spring.GetModKeyState()
					local index = Spring.GetCmdDescIndex(command)
					Spring.SetActiveCommand(index, 1, left, right, alt, ctrl, meta, shift)
				elseif action then
					Spring.SendCommands(action)
				end
				if onClick then
					onClick()
				end
			end 
		},
		children = {
		  file and
			Chili.Image:New{
				file = file,
				x = 0,
				y = 0,
				right = 0,
				bottom = 0,
			} or nil
		},
	}
	return btn
end

local function MakeDropdownButtonsFromWidget(parent, position, tooltip, width, titleImage, widgetName, widgetPath, settingName)
	
	local option = WG.GetWidgetOption(widgetName, widgetPath, settingName)
	if not (option and option.items) then
		return
	end
	local items = {}
	local keys = {}
	for i = 1, #option.items do
		items[i] = option.items[i].name
		keys[i] = option.items[i].key
	end
	
	local freeze = true
	
	local overlaySelector = Chili.ComboBox:New{
		x = (position - 1)*BUTTON_PLACE_SPACE + BUTTON_Y,
		y = BUTTON_Y,
		width = BUTTON_SIZE,
		height = BUTTON_SIZE,
		selectionOffsetX = -40,
		selectionOffsetY = 7,
		itemFontSize = 18,
		itemHeight = 26,
		topHeight = 10,
		minDropDownWidth = width,
		ignoreItemCaption = true,
		classname = "button_tiny",
		caption = "",
		margin = {0,0,0,0},
		padding = {2,2,2,2},
		tooltip = tooltip,
		items = items,
		parent = parent,
		OnMouseDown = globalMouseDown,
		OnSelect = {
			function(obj, index)
				if not freeze then
					WG.SetWidgetOption(widgetName, widgetPath, settingName, keys[index])
				end
			end 
		},
	}
	
	freeze = false
	
	local currentOverlayImage = Chili.Image:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		parent = overlaySelector,
		file = titleImage,
	}

	return overlaySelector
end

local function MakeDropdownButtons(parent, position, overlays)
	
	local overlayPanel = Panel:New{
		x = 0,
		y = 38,
		width = 36,
		height = (#overlays)*BUTTON_PLACE_SPACE + 8,
		classname = "overlay_panel",
		parent = screen0,
		padding = {6,4,0,0}
	}
		
	local function HideSelector()
		overlayPanel:SetVisibility(false)
	end
	HideSelector()
	
	local overlayImageMap = {}
	for i = 1, #overlays do
		buttons["overlay_" .. overlays[i][2]] = MakeCommandButton(overlayPanel, i, overlays[i][1], {option = overlays[i][2]}, true, HideSelector)
		
		overlayImageMap[overlays[i][3]] = overlays[i][1]
	end
	
	local overlaySelector = Chili.Button:New{
		x = (position - 1)*BUTTON_PLACE_SPACE + BUTTON_Y,
		y = BUTTON_Y,
		width = BUTTON_SIZE, 
		height = BUTTON_SIZE,
		classname = "button_tiny",
		caption = "",
		margin = {0,0,0,0},
		padding = {2,2,2,2},
		tooltip = "", 
		parent = parent,
		OnMouseDown = globalMouseDown,
		OnClick = {
			function(self)
				overlayPanel:SetVisibility(not overlayPanel.visible)
			end 
		},
	}
		
	local currentOverlayImage = Chili.Image:New{
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		parent = overlaySelector,
	}
	
	local externalFunctions = {}
	
	local oldDrawMode
	function externalFunctions.UpdateOverlayImage()
		local newDrawMode = Spring.GetMapDrawMode()
		if newDrawMode == oldDrawMode then
			return
		end
		oldDrawMode = newDrawMode
		
		currentOverlayImage.file = overlayImageMap[newDrawMode]
		currentOverlayImage:Invalidate()
	end

	function externalFunctions.UpdateTooltip(newTooltip)
		overlaySelector.tooltip = newTooltip
		overlaySelector:Invalidate()
	end
	
	return externalFunctions
end

local function AddCommand(imageFile, tooltip, onClick)
	local button = MakeCommandButton(contentHolder, commandButtonOffset, imageFile, {desc = tooltip}, nil, onClick)
	commandButtonOffset = commandButtonOffset + 1
	return button
end

local function InitializeControls()
	mainWindow = Window:New{
		name      = 'globalCommandsWindow',
		x         = 0, 
		y         = 0,
		width     = 370,
		height    = 50,
		minWidth  = 200,
		minHeight = 32,
		dockable  = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		padding = {0, -1, 0, 0},
		color = {0, 0, 0, 0},
		parent = screen0,
	}
	if options.hide.value then
		mainWindow:Hide()
	end

	contentHolder = Panel:New{
		classname = options.fancySkinning.value,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0,0,0,0},
		backgroundColor = {1, 1, 1, options.background_opacity.value},
		parent = mainWindow,
	}

	local overlayConfig = {
		{nil, 'viewstandard', "normal"},
		{'LuaUI/images/map/fow.png', 'viewfow', "los"},
		{'LuaUI/images/map/heightmap.png', 'viewheightmap', "height"},
		{'LuaUI/images/map/blockmap.png', 'viewblockmap', "pathTraversability"}, 
	}
	
	-- Overlay related buttons
	local offset = 1
	
	mapOverlay = MakeDropdownButtons(contentHolder, offset, overlayConfig)
	mapOverlay.UpdateOverlayImage()
	offset = offset + 1
	
	-- handled differently because command is registered in another widget
	buttons.toggle_eco_display = MakeCommandButton(contentHolder, offset,
		'LuaUI/images/map/metalmap.png', 
		{action = 'showeco'}
	)
	offset = offset + 1
	
	teamcolor_selector = MakeDropdownButtonsFromWidget(contentHolder, offset, "", 180, 'LuaUI/images/map/minimap_colors_simple.png', "Local Team Colors", "Settings/Interface/Team Colors", "colorSetting")
	offset = offset + 1
	
	buttons.clearmapmarks = MakeCommandButton(contentHolder, offset,
		'LuaUI/images/drawingcursors/eraser.png', 
		{option = 'clearmapmarks'} 
	)
	offset = offset + 1
	
	buttons.lastmsgpos = MakeCommandButton(contentHolder, offset,
		'LuaUI/images/Crystal_Clear_action_flag.png', 
		{option = 'lastmsgpos'} 
	)
	offset = offset + 1
	
	-- Global commands
	offset = offset + 0.5
	
	buttons.place_retreat_zone = MakeCommandButton(contentHolder, offset,
		'LuaUI/images/commands/Bold/retreat.png',
		{action = 'sethaven', command = CMD_RETREAT_ZONE}
	)
	offset = offset + 1
	
	buttons.place_ferry_route = MakeCommandButton(contentHolder, offset,
		'LuaUI/images/commands/Bold/ferry.png', 
		{action = 'setferry', command = CMD_SET_FERRY}
	)
	offset = offset + 1
	
	commandButtonOffset = offset + 0.5
end

function options.background_opacity.OnChange(self)
	contentHolder.backgroundColor[4] = self.value
	contentHolder:Invalidate()
end

function widget:Update()
	mapOverlay.UpdateOverlayImage()
end

local GlobalCommandBar = {}

function GlobalCommandBar.AddCommand(imageFile, tooltip, onClick)
	return AddCommand(imageFile, tooltip, onClick)
end

function widget:Initialize()
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
	WG.InitializeTranslation (languageChanged, GetInfo().name)
	WG.GlobalCommandBar = GlobalCommandBar
end
