function widget:GetInfo()
	return {
		name      = "Chili Global Commands",
		desc      = "Holds global commands, map overlays, playerlist display and other stuff.",
		author    = "GoogleFrog",
		date      = "16 November 2016",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local BUTTON_Y = 0
local BUTTON_SIZE = 25
local BUTTON_PLACE_SPACE = 27

local contentHolder

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

local function toggleTeamColors()
	if WG.LocalColor and WG.LocalColor.localTeamColorToggle then
		WG.LocalColor.localTeamColorToggle()
	else
		Spring.SendCommands("luaui enablewidget Local Team Colors")
	end
end

local globalCommands = {
	
}

options_path = 'Settings/HUD Panels/Global Commands'
options = {
	background_opacity = {
		name = "Opacity",
		type = "number",
		value = 1, min = 0, max = 1, step = 0.01,
	},
	clearmapmarks = {
		name = 'Erase Map Drawing',
		desc = 'Erases all map drawing and markers (for you, not for others on your team).',
		type = 'button',
		action = 'clearmapmarks',
	},	
	lastmsgpos = {
		name = 'Zoom To Last Message',
		desc = 'Moves the camera to the most recently placed map marker or message.',
		type = 'button',
		action = 'lastmsgpos',
	},
	viewstandard = {
		name = 'Clear Overlays',
		desc = 'Disables Heightmap, Pathing and Line of Sight overlays.',
		type = 'button',
		action = 'showstandard',
	},
	viewheightmap = {
		name = 'Toggle Height Map',
		desc = 'Shows contours of terrain elevation.',
		type = 'button',
		action = 'showelevation',
	},
	viewblockmap = {
		name = 'Toggle Pathing Map',
		desc = 'Select a unit to see where it can go. Select a building blueprint to see where it can be placed.',
		type = 'button',
		action = 'showpathtraversability',
	},
	viewfow = {
		name = 'Toggle Line of Sight',
		desc = 'Shows sight distance and radar coverage.',
		type = 'button',
		action = 'togglelos',
	},
	viewfow = {
		name = 'Toggle Line of Sight',
		desc = 'Shows sight distance and radar coverage.',
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
		advanced = true,
		noHotkey = true,
	},
}

local commandButtonMouseDown = { 
	function(self)
		local _,_, meta,_ = Spring.GetModKeyState()
		if not meta then 
			return false
		end
		WG.crude.OpenPath("Game/Command Hotkeys")
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
		name = options[option].name
		desc = options[option].desc and (' (' .. options[option].desc .. ')') or ''
		action = WG.crude.GetActionName(options_path, options[option])
	end
	name = name or params.name or ""
	desc = desc or params.desc or ""
	action = action or params.action
	hotkey = WG.crude.GetHotkey(action)
	command = params.command
	
	if hotkey ~= '' then
		hotkey = ' (\255\0\255\0' .. hotkey:upper() .. '\008)'
	end
		
	Chili.Button:New{
		x = (vertical and 0) or ((position - 1)*BUTTON_PLACE_SPACE + BUTTON_Y),
		y = (vertical and ((position - 1)*BUTTON_PLACE_SPACE + BUTTON_Y)) or BUTTON_Y,
		width = BUTTON_SIZE, 
		height = BUTTON_SIZE,
		classname = "button_tiny",
		caption = "",
		margin = {0,0,0,0},
		padding = {2,2,2,2},
		tooltip = (name .. desc .. hotkey), 
		parent = parent,
		OnMouseDown = (command and commandButtonMouseDown) or globalMouseDown,
		OnClick = {
			function(self)
				if command then
					local left, right = true, false
					local alt, ctrl, meta, shift = Spring.GetModKeyState()
					local index = Spring.GetCmdDescIndex(command)
					Spring.SetActiveCommand(index, 1, left, right, alt, ctrl, meta, shift)
				else
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
		MakeCommandButton(overlayPanel, i, overlays[i][1], {option = overlays[i][2]}, true, HideSelector)
		
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
		tooltip = "Set map overlay", 
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
	
	return externalFunctions
end

local function InitializeControls()
	local mainWindow = Window:New{
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
		padding = {0, 0, 0, 0},
		color = {0, 0, 0, 0},
		parent = screen0,
	}
	
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
	
	mapOverlay = MakeDropdownButtons(contentHolder, 1, overlayConfig)
	mapOverlay.UpdateOverlayImage()
	
	-- handled differently because command is registered in another widget
	MakeCommandButton(contentHolder, 2,
		'LuaUI/images/map/metalmap.png', 
		{name = "Toggle Eco Display", action = 'showeco', desc = " (show metal, geo spots and pylon fields)"}
	)
	MakeCommandButton(contentHolder, 3,
		'LuaUI/images/drawingcursors/eraser.png', 
		{option = 'clearmapmarks'} 
	)
	MakeCommandButton(contentHolder, 4,
		'LuaUI/images/Crystal_Clear_action_flag.png', 
		{option = 'lastmsgpos'} 
	)
	
	MakeCommandButton(contentHolder, 5.5,
		'LuaUI/images/commands/Bold/retreat.png', 
		{name = "Place Retreat Zone", action = 'sethaven', command = CMD_RETREAT_ZONE, desc = " (Shift to place multiple zones, overlap to remove)"}
	)
	MakeCommandButton(contentHolder, 6.5,
		'LuaUI/images/commands/Bold/ferry.png', 
		{name = "Place Ferry Route", action = 'setferry', command = CMD_SET_FERRY, desc = " (Shift to queue and edit waypoints, overlap the start to remove)"}
	)
	
end	

function options.background_opacity.OnChange(self)
	contentHolder.backgroundColor[4] = self.value
	contentHolder:Invalidate()
end

function widget:Update()
	mapOverlay.UpdateOverlayImage()
end
			
function widget:Initialize()
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
