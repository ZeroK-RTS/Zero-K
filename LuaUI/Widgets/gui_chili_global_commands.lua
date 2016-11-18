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

local BUTTON_Y = 5
local BUTTON_SIZE = 40

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
		value = 0.8, min = 0, max = 1, step = 0.01,
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

local function MakeCommandButton(parent, x, file, params)
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
		
	return Chili.Button:New{
		x = x,
		y = BUTTON_Y,
		width = BUTTON_SIZE, 
		height = BUTTON_SIZE,
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

local contentHolder

local function InitializeControls()
	local mainWindow = Window:New{
		name      = 'globalCommandsWindow',
		x         = 0, 
		y         = 0,
		width     = 370,
		height    = 50,
		minHeight = 50,
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
		--classname = "panel2220",
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		backgroundColor = {1, 1, 1, options.background_opacity.value},
		parent = mainWindow,
	}

	MakeCommandButton(contentHolder, 10,
		'LuaUI/images/map/fow.png', 
		{option = 'viewfow'} 
	)
	MakeCommandButton(contentHolder, 50,
		nil,
		{option = 'viewstandard'} 
	)
	MakeCommandButton(contentHolder, 90,
		'LuaUI/images/map/heightmap.png', 
		{option = 'viewheightmap'} 
	)
	MakeCommandButton(contentHolder, 130,
		'LuaUI/images/map/blockmap.png', 
		{option = 'viewblockmap'} 
	)
		
	-- handled differently because command is registered in another widget
	MakeCommandButton(contentHolder, 170,
		'LuaUI/images/map/metalmap.png', 
		{name = "Toggle Eco Display", action = 'showeco', desc = " (show metal, geo spots and pylon fields)"}
	)
	
	MakeCommandButton(contentHolder, 210,
		'LuaUI/images/commands/Bold/retreat.png', 
		{name = "Place Retreat Zone", action = 'sethaven', command = CMD_RETREAT_ZONE, desc = " (Shift to place multiple zones, overlap to remove)"}
	)
	MakeCommandButton(contentHolder, 250,
		'LuaUI/images/commands/Bold/ferry.png', 
		{name = "Place Ferry Route", action = 'setferry', command = CMD_SET_FERRY, desc = " (Shift to queue and edit waypoints, overlap the start to remove)"}
	)
  
	MakeCommandButton(contentHolder, 290,
		'LuaUI/images/drawingcursors/eraser.png', 
		{option = 'clearmapmarks'} 
	)
	MakeCommandButton(contentHolder, 330,
		'LuaUI/images/Crystal_Clear_action_flag.png', 
		{option = 'lastmsgpos'} 
	)
	
end	

function options.background_opacity.OnChange(self)
	contentHolder.backgroundColor[4] = self.value
	contentHolder:Invalidate()
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