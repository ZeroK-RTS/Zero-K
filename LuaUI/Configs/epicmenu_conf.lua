local confdata = {}
confdata.title = 'Z.K.'
confdata.title_image = LUAUI_DIRNAME .. 'Images/ZK_logo.png'
confdata.default_source_file = 'zk_keys.lua' --the file in ZIP archive where default key is stored.
confdata.mission_keybinds_file = 'zk_keys.lua' --the filename to be used for Mission mod. set this to NIL if want to use mission's name as filename.
-- confdata.regular_keybind_file = LUAUI_DIRNAME .. 'Configs/zk_keys.lua' --for Multiplayer this is automatically set according to modName in epicmenu.lua
--FIXME: find modname instead of using hardcoded mission_keybinds_file name
confdata.description = 'Zero-K is a free real time strategy (RTS), that aims to be the best open source multi-platform strategy game available :-) \n\n www.zero-k.info'
local color = {
	white = {1,1,1,1},
	yellow = {1,1,0,1},
	gray = {0.5,.5,.5,1},
	darkgray = {0.3,.3,.3,1},
	cyan = {0,1,1,1},
	red = {1,0,0,1},
	darkred = {0.5,0,0,1},
	blue = {0,0,1,1},
	black = {0,0,0,1},
	darkgreen = {0,0.5,0,1},
	green = {0,1,0,1},
	postit = {1,0.9,0.5,1},
	
	grayred = {0.5,0.4,0.4,1},
	grayblue = {0.4,0.4,0.45,1},
	transblack = {0,0,0,0.3},
	transblack2 = {0,0,0,0.7},
	transGray = {0.1,0.1,0.1,0.8},
	
	empty = {0,0,0,0},
	null = {nil, nil, nil, 1},
	transnull = {nil, nil, nil, 0.3},
	transnull2 = {nil, nil, nil, 0.5},
	transnull3 = {nil, nil, nil, 0.8},
}

color.tooltip_bg = color.transnull3
color.tooltip_fg = color.null
color.tooltip_info = color.cyan
color.tooltip_help = color.green

color.main_bg = color.transnull3
color.main_fg = color.null

color.menu_bg = color.null
color.menu_fg = color.null

color.game_bg = color.null
color.game_fg = color.null

color.sub_bg    = color.transnull
color.sub_fg     = color.null
color.sub_header = color.yellow

color.sub_button_bg = color.null
color.sub_button_fg = color.null

color.sub_back_bg = color.null
color.sub_back_fg = color.null

color.sub_close_bg = color.null
color.sub_close_fg = color.null

color.stats_bg = color.sub_bg
color.stats_fg = color.sub_fg
color.stats_header = color.sub_header

color.context_bg = color.transnull
color.context_fg = color.null
color.context_header = color.yellow

color.disabled_bg = color.transGray
color.disabled_fg = color.darkgray

confdata.color = color

local spSendCommands = Spring.SendCommands

confdata.eopt = {}

local function nullFunc()
end

local function SetWidgetEnableState(widget, state)
	if state then
		spSendCommands{"luaui enablewidget " .. widget}
	else
		spSendCommands{"luaui disablewidget " .. widget}
	end
end

local function AddOption(path, option)
	option.path = path or "Settings/Broken Paths"
	if not option.key then
		option.key = option.name
	end
	table.insert(confdata.eopt, option)
end

--ShortHand for adding a button
local function ShButton(path, caption, action2, tooltip, advanced, icon, DisableFunc, bindMod)
	AddOption(path,
	{
		type='button',
		name=caption,
		desc = tooltip or '',
		action = (type(action2) == 'string' and action2 or nil),
		OnChange = (type(action2) ~= 'string' and action2 or nil),
		key=caption,
		bindMod = bindMod,
		advanced = advanced,
		icon = icon,
		DisableFunc = DisableFunc or nil, --function that trigger grey colour on buttons (not actually disable their functions, only coloured them grey)
	})
end


--ShortHand for adding radiobuttons
local function ShRadio(path, caption, items,defValue, action2, advanced, nhk)
	AddOption(path,
	{
		type='radioButton',
		name=caption,
		key=caption,
		items = items or {},
		value = defValue or '',
		action = (type(action2) == 'string' and action2 or nil),
		OnChange = (type(action2) ~= 'string' and action2 or nil),
		advanced = advanced,
		noHotkey = nhk,
	})
end

--ShortHand for adding a label
local function ShLabel(path, caption)
	AddOption(path,
	{
		type='label',
		name=caption,
		value = caption,
		key=caption,
	})
end


local imgPath = LUAUI_DIRNAME  .. 'images/'
confdata.subMenuIcons = {
	['Settings'] = imgPath..'epicmenu/settings.png',
	['Help'] = imgPath..'epicmenu/questionmark.png',
	
	['Settings/Unit Behaviour/Worker AI'] = imgPath..'commands/Bold/build_light.png',
	['Settings/Interface/Unit Marker']     = imgPath..'epicmenu/marker.png',
	['Settings/Unit Behaviour']  = imgPath..'epicmenu/robot2.png',
	['Hotkeys']         = imgPath..'epicmenu/keyboard.png',
	
	['Hotkeys/Misc']                = imgPath..'epicmenu/misc.png',
	['Hotkeys/Camera']              = imgPath..'epicmenu/video_camera.png',
	['Hotkeys/Construction']        = imgPath..'factory.png',
	['Hotkeys/Selection']           = imgPath..'epicmenu/selection.png',
	['Hotkeys/Commands']            = imgPath..'commands/Bold/move.png',
	['Hotkeys/Grid Hotkeys']       = imgPath..'epicmenu/grid.png',
	
	['Hotkeys/Commands/Targeted']   = imgPath..'commands/Bold/attack.png',
	['Hotkeys/Commands/Instant']    = imgPath..'commands/Bold/action.png',
	['Hotkeys/Commands/State']      = imgPath..'commands/states/move_engage.png',
	
	['Hotkeys/Camera/Camera Position Hotkeys']     = imgPath..'epicmenu/marker.png',
	['Hotkeys/Camera/Camera Mode Hotkeys']         = imgPath..'epicmenu/move.png',
	
	['Settings/Reset Settings']     = imgPath..'epicmenu/undo.png',
	['Settings/Audio']              = imgPath..'epicmenu/vol.png',
	['Settings/Camera']             = imgPath..'epicmenu/video_camera.png',
	['Settings/Graphics']           = imgPath..'epicmenu/graphics.png',
	['Settings/Accessibility']      = imgPath..'map/minimap_colors_simple.png',
	['Settings/HUD Panels']         = imgPath..'epicmenu/control_panel.png',
	['Settings/HUD Presets']        = imgPath..'epicmenu/speed-test-icon.png',
	['Settings/Interface']          = imgPath..'epicmenu/robotarm.png',
	['Settings/Misc']               = imgPath..'epicmenu/misc.png',
	['Settings/Tips']               = imgPath..'epicmenu/questionmark.png',
	['Settings/Spectating']         = imgPath..'epicmenu/popcorn.png',
	['Settings/Toolbox']            = imgPath..'commands/states/autoassist_on.png',
	['Settings/Autosave']            = imgPath..'epicmenu/save_small.png',
	
	['Settings/Interface/Mouse Cursor']             = imgPath..'epicmenu/input_mouse.png',
	['Settings/Interface/Map']                      = imgPath..'epicmenu/map.png',
	['Settings/Interface/Healthbars']               = imgPath..'commands/Bold/health.png',
	['Settings/Interface/Retreat Zones']            = imgPath..'commands/Bold/retreat.png',
	['Settings/Interface/Reclaim Highlight']        = imgPath..'epicmenu/reclaimfield.png',
	['Settings/Interface/Building Placement']       = imgPath..'factory.png',
	['Settings/Interface/Team Colors']              = imgPath..'map/minimap_colors_simple.png',
	['Settings/Interface/Common Team Colors']       = imgPath..'map/minimap_colors_simple.png',
	['Settings/Interface/Build ETA']                = imgPath..'epicmenu/stop_watch_icon.png',
	['Settings/Interface/Defence and Cloak Ranges'] = imgPath..'epicmenu/target.png',
	['Settings/Interface/Command Visibility']       = imgPath..'epicmenu/fingertap.png',
	['Settings/Interface/Line Formations']          = imgPath..'commands/bold/move.png',
	['Settings/Interface/Hovering Icons']           = imgPath..'epicmenu/halo.png',
	['Settings/Interface/Selection']                = imgPath..'epicmenu/selection.png',
	['Settings/Interface/Selection Filtering']      = imgPath..'epicmenu/selection_rank.png',
	['Settings/Interface/Control Groups']           = imgPath..'epicmenu/addusergroup.png',
	['Settings/Interface/Gesture Menu']             = imgPath..'epicmenu/stock_brightness.png',
	['Settings/Interface/Economy Overlay']          = imgPath..'energy.png',
	['Settings/Interface/Falling Units']            = imgPath..'advplayerslist/point2.png',
	['Settings/Interface/Commands']                 = imgPath..'commands/bold/attack.png',
	['Settings/Interface/Missile Warnings']         = imgPath..'nuke_button_48.png',
	['Settings/Interface/Player Name Tags']         = imgPath..'hellomynameis.png',
	['Settings/Interface/Battle Value Tracker']     = imgPath..'costIcon.png',
	
	['Settings/HUD Panels/Minimap']                 = imgPath..'epicmenu/map.png',
	['Settings/HUD Panels/Economy Panel']           = imgPath..'ibeam.png',
	['Settings/HUD Panels/Commander Selector']      = imgPath..'epicmenu/corcommander.png',
	['Settings/HUD Panels/Tooltip']                 = imgPath..'epicmenu/lightbulb.png',
	['Settings/HUD Panels/Chat']                    = imgPath..'advplayerslist/chat.png',
	['Settings/HUD Panels/FactoryPanel']            = imgPath..'factory.png',
	['Settings/HUD Panels/Pause Screen']            = imgPath..'epicmenu/media_playback_pause.png',
	['Settings/HUD Panels/Replay Controls']         = imgPath..'epicmenu/key_play_pause.png',
	['Settings/HUD Panels/Unit Stats Help Window']  = imgPath..'advplayerslist/random.png',
	['Settings/HUD Panels/Player List']             = imgPath..'epicmenu/people.png',
	['Settings/HUD Panels/Extras/Docking']          = imgPath..'epicmenu/anchor.png',
	['Settings/HUD Panels/Selected Units Panel']    = imgPath..'epicmenu/grid.png',
	['Settings/HUD Panels/Command Panel']           = imgPath..'epicmenu/control_panel.png',
	['Settings/HUD Panels/Quick Selection Bar']     = imgPath..'idlecon.png',
	['Settings/HUD Panels/Stats Graph']             = imgPath..'graphs_icon.png',
	['Settings/HUD Panels/Global Commands']         = imgPath..'planetQuestion.png',
	['Settings/HUD Panels/Nuke Warning']            = imgPath..'nuke_button_48.png',
	['Settings/HUD Panels/Extras']                  = imgPath..'plus_green.png',
	
	['Settings/Spectating/Action Tracking Camera']  = imgPath..'epicmenu/video_camera.png',
	['Settings/Spectating/Team Information Panels'] = imgPath..'epicmenu/corcommander.png',
	['Settings/Spectating/Player View']             = imgPath..'advplayerslist/spec.png',
}

confdata.simpleModeDirectory = {
	['Reset Settings'] = true,
	['Interface'] = true,
	['Commands'] = true,
	['Presets'] = true,
	['Audio'] = true,
	['Graphics'] = true,
	['Camera'] = true,
	['Unit Behaviour'] = true,
	['Accessibility'] = true,
	['Autosave'] = true,
}
confdata.simpleModeFullDirectory = {
	'Reset Settings',
	'Hotkeys',
	'Unit Behaviour',
	'Help',
}

-- SETUP MENU HERE
-- moved to epicmenu itself
--ShButton('', 'Save Game', (function() if WG.SaveGame then WG.SaveGame.CreateSaveWindow() end end), nil, nil, imgPath .. 'commands/Bold/unload.png', CanSaveGame)
--ShButton('', 'Load Game', (function() if WG.SaveGame then WG.SaveGame.CreateLoadWindow() end end), nil, nil, imgPath .. 'commands/Bold/load.png')

--- GENERAL SETTINGS --- settings about settings
local generalPath = 'Settings/Reset Settings'
	ShLabel(generalPath, 'Minimal Graphics - Requires restart.')
	ShButton(generalPath, 'Minimal graphic settings',function()
					spSendCommands{"water 0",
						"Shadows 0",
						"maxparticles 100",
						"advmodelshading 0",
						"grounddecals 0",
						'luaui disablewidget LupsManager',
						"luaui disablewidget Lups",
						"luaui disablewidget Display DPS",
						"luaui disablewidget Map Edge Extension",
						'mapborder 1',
						"luaui disablewidget SelectionHalo",
						"luaui disablewidget SelectionCircle",
					}
				end,
				'Test minimal graphics. Use the main settings menu to make a permanent if necessary.'
			)
	ShLabel(generalPath, 'Reset settings - Requires restart.')
	ShButton(generalPath, 'Reset settings', function() WG.crude.ResetSettings() end, 'Reset all interface settings to the default. Restart the battle to apply.')
	ShLabel(generalPath, 'Reset hotkeys - Requires restart.')
	ShButton(generalPath, 'Reset hotkeys',function() WG.crude.ResetKeys() end, 'Reset all hotkeys to the default. Restart the battle to apply.')


local settingsPath = 'Settings'
	--[[
	AddOption(settingsPath,
	{
		name = 'Show Advanced Settings',
		type = 'bool',
		value = false,
	})
	--]]


--- Hotkeys ---
local hotkeysMiscPath = 'Hotkeys/Misc'

	ShButton(hotkeysMiscPath, 'Pause/Unpause', 'pause', nil, nil, imgPath .. 'epicmenu/media_playback_pause.png')
		ShButton(hotkeysMiscPath, 'Increase Speed', 'speedup')
		ShButton(hotkeysMiscPath, 'Decrease Speed', 'slowdown')
		
	--ShLabel(hotkeysMiscPath, '')
	ShButton(hotkeysMiscPath, 'Choose Commander Type', (function() spSendCommands{"luaui showstartupinfoselector"} end), nil, nil, imgPath..'epicmenu/corcommander.png' )
	ShButton(hotkeysMiscPath, 'Save Screenshot (PNG)', 'screenshot png', 'Find your screenshots under Spring/screenshots')
	ShButton(hotkeysMiscPath, 'Save Screenshot (JPG)', 'screenshot jpg', 'Find your screenshots under Spring/screenshots')
	ShButton(hotkeysMiscPath, 'Zoom In', 'movedown', 'Key to zoom the camera out.')
	ShButton(hotkeysMiscPath, 'Zoom Out', 'moveup', 'Key to zoom the camera in.')
	ShButton(hotkeysMiscPath,
	     'Create Video (risky)', 'createvideo', 'Capture video directly from Spring without sound. Gets saved in the Spring folder. '
	     ..'Creates a smooth video framerate without ingame stutter. '
	     ..'Caution: It\'s safer to use this in windowed mode because the encoder pop-up menu appears in the foreground window, and could crash the game with a "Fatal Error" after a long recording. '
	     ..'\n\nRecommendation (especially for low-end PCs): After activating the video recording select the fastest encoder such as Microsoft Video and record the video in segments. '
	     ..' You can then use VirtualDub (opensource software) to do futher compression and editing. Note: there is other opensource video capture software like Taksi that you could try.')
	ShButton(hotkeysMiscPath, 'Game Info', "gameinfo", '', true)
	--ShButton(hotkeysMiscPath, 'Share Dialog...', 'sharedialog', '', true)
	--ShButton(hotkeysMiscPath, 'FPS Control', "controlunit", 'Control a unit directly in FPS mode.', true)
	
	--ShButton(hotkeysMiscPath, 'Constructor Auto Assist', function() spSendCommands{"luaui togglewidget Constructor Auto Assist"} end)

--- CAMERA ---
local cameraPath = 'Settings/Camera'
	--[[
		the problem is "radioButton" is not fully implemented to recognize the item "viewta" as an existing action,
		so the hotkey Ctrl+F2 doesn't show in the menu, and thus cannot be unbound. A proposed solution is to enable both "radioButton"
		& old camera button, but put the later in saperate category.
	--]]

	local cofcDisable = "luaui disablewidget Combo Overhead/Free Camera (experimental)"
	ShRadio( cameraPath,
		'Camera Type', {
			{name = 'Default camera', key='Default', desc='Default camera', hotkey=nil},
			{name = 'Rotatable Overhead',key='Rotatable Overhead', hotkey=nil},
			{name = 'COFC (highly configurable)',key='COFC', desc='Combo Overhead/Free Camera', hotkey=nil},
			{name = 'FPS (experimental)',key='FPS', hotkey=nil},
			{name = 'Free (experimental)',key='Free', hotkey=nil},
			{name = 'Spring (experimental)',key='Spring',  hotkey=nil},
		},'Default',
		function(self)
			local key = self.value
			if key == 'Default' then
				spSendCommands{cofcDisable ,"viewta"}
			elseif key == 'FPS' then
				spSendCommands{cofcDisable ,"viewfps"}
			elseif key == 'Free' then
				spSendCommands{cofcDisable ,"viewfree"}
			elseif key == 'Rotatable Overhead' then
				spSendCommands{cofcDisable ,"viewrot"}
			elseif key == 'Spring' then
				spSendCommands{cofcDisable ,"viewspring"}
			elseif key == 'COFC' then
				spSendCommands{"luaui enablewidget Combo Overhead/Free Camera (experimental)",}
			else
				spSendCommands{cofcDisable ,"viewta"} -- Fallback for any issue with settings.
			end
		end
		)

local camerHotkeys = 'Hotkeys/Camera'
	ShButton(camerHotkeys, 'Move Forward', 'moveforward')
	ShButton(camerHotkeys, 'Move Back', 'moveback')
	ShButton(camerHotkeys, 'Move Left', 'moveleft')
	ShButton(camerHotkeys, 'Move Right', 'moveright')
	ShLabel(camerHotkeys, '')
	ShButton(camerHotkeys, 'Overview Mode', 'toggleoverview')
	ShButton(camerHotkeys, 'Track unit', 'track')
	ShButton(camerHotkeys, 'Flip the Camera', 'viewtaflip')
	ShButton(camerHotkeys, 'Panning mode','mousestate', 'Note: must be bound to a key for use', true)
	ShButton(camerHotkeys, 'Tilt Camera', 'movetilt', "Tilt the camera with mouse wheel while this key is held.", nil, nil, nil, true)
	ShButton(camerHotkeys, 'Overview Zoom', 'movereset', "Mousewheel down with this key held to zoom all the way out. Mousewheel up to return to previous zoom level.", nil, nil, nil, true)
	ShButton(camerHotkeys, 'Fast Camera Movement', 'movefast', "Increased camera speed while this key is held.", nil, nil, nil, true)
	ShButton(camerHotkeys, 'Slow Camera Movement', 'moveslow', "Decreased camera speed while this key is held.", nil, nil, nil, true)
	-- Requires Spring Camera to be default.
	--ShButton(camerHotkeys, 'Rotate Camera', 'moverotate', "Decreased camera speed while this key is held.", nil, nil, nil, true)
	
	ShLabel(camerHotkeys, 'Saving Position and Switching Camera')

local camerTypeZoom = 'Hotkeys/Camera/Camera Position Hotkeys'
	ShButton(camerTypeZoom, 'Cycle through alerts', 'lastmsgpos') -- Does not allow camtime override

--local camerTypeHotkeys = 'Hotkeys/Camera/Camera Mode Hotkeys'
--	AddOption(camerTypeHotkeys,
--	{
--		type='text',
--		name='Camera Modes',
--		value = [[For more camera configuration navigate to Settings/Camera and untick 'Simple Settings'.]]
--	})
--	ShButton(camerTypeHotkeys, 'Switch to Default', 'viewta')
--	--ShButton(camerTypeHotkeys, 'Switch FPS', 'viewfps', nil, true)
--	--ShButton(camerTypeHotkeys, 'Switch Free', 'viewfree', nil, true)
--	ShButton(camerTypeHotkeys, 'Switch to Rotatable', 'viewrot')
--	--ShButton(camerTypeHotkeys, 'Switch Total War', 'viewtw', nil, true)

-- Control menu order
ShLabel('Hotkeys/Commands', 'Command Categories')

--- HUD Panels --- Only settings that pertain to windows/icons at the drawscreen level should go here.
local HUDPath = 'Settings/HUD Panels/Extras'
	ShButton(HUDPath, 'Tweak Mode (Esc to exit)', 'luaui tweakgui', 'Tweak Mode. Move and resize parts of the user interface. (Hit Esc to exit)')
	ShButton(HUDPath, 'Toggle Attrition Counter', function() spSendCommands{"luaui togglewidget Attrition Counter"} end, "Tracks killed and lost units (only in line of sight while playing)")
	ShButton(HUDPath, 'Toggle RoI Tracker', function() spSendCommands{"luaui togglewidget RoI Tracker"} end, "Tracks ")

local HUDSkinPath = 'Settings/HUD Panels/Extras/HUD Skin'
	AddOption(HUDSkinPath,
	{
		name = 'Skin Sets (Requires LuaUI Reload)',
		type = 'list',
		advanced = true,
		OnChange = function (self)
			WG.crude.SetSkin( self.value );
		end,
		items = {
			{ key = 'Blueprint', name = 'Blueprint', },
			{ key = 'Carbon', name = 'Carbon', },
			{ key = 'Robocracy', name = 'Robocracy', },
			--{ key = 'DarkGlass', name = 'DarkGlass', }, -- Broken
			{ key = 'DarkHive', name = 'DarkHive', },
			{ key = 'DarkHiveSquare', name = 'DarkHive (square)', },
			{ key = 'Evolved', name = 'Evolved', },
			--{ key = 'Glass', name = 'Glass', }, -- Broken
			{ key = 'Twilight', name = 'Twilight', },
		},
	})
	ShButton(HUDSkinPath, 'Reload LuaUI', 'luaui reload', 'Reloads the entire UI. NOTE: This button will not work. You must bind a hotkey to this command and use the hotkey.', true)

--- Spectating --- anything that's an interface but not a HUD Panel
local pathSpectating = 'Settings/Spectating'
	ShButton(pathSpectating .. "/Action Tracking Camera", 'Toggle Action Camera', function() spSendCommands{"luaui togglewidget Action Tracking Camera"} end, "Toggles an automatic action tracking camera. Only activates for non-players.")

--- Interface --- anything that's an interface but not a HUD Panel
local pathInterface = 'Settings/Interface'



local pathMouse = 'Settings/Interface/Mouse Cursor'
	AddOption(pathMouse,
	{
		name = 'Hardware Cursor',
		type = 'bool',
		desc = 'Temporary toggle. For a permanent toggle change go to Settings in the non-game main menu.',
		--advanced = true, -- The temp toggle is somewhat useful.
		springsetting = 'HardwareCursor',
		OnChange=function(self) spSendCommands{"hardwarecursor " .. (self.value and 1 or 0) } end,
	})

ShLabel('Settings/Interface/Selection', 'Selection Display Options')

local pathSelectionGL4 = 'Settings/Interface/Selection/Default Selections'
local pathSelectionShapes = 'Settings/Interface/Selection/Selection Shapes'
local pathSelectionXrayHalo = 'Settings/Interface/Selection/Selection XRay&Halo'
local pathSelectionPlatters = 'Settings/Interface/Selection/Team Platters'
local pathSelectionBluryHalo = 'Settings/Interface/Selection/Blurry Halo Selections'
	ShButton(pathSelectionGL4, 'Toggle Default Selections', function() spSendCommands{"luaui togglewidget Selected Units GL4 2"} end, "Draws a configurable box and platter underneath units. This is the default, but required a graphics card capable of using shaders.")
	ShButton(pathSelectionShapes, 'Toggle Selection Shapes', function() spSendCommands{"luaui togglewidget UnitShapes 3"} end, "Draws coloured shapes under selected units")
	ShButton(pathSelectionXrayHalo, 'Toggle Selection XRay&Halo', function() spSendCommands{"luaui togglewidget XrayHaloSelections"} end, "Highlights bodies of selected units")
	ShButton(pathSelectionPlatters, 'Toggle Team Platters', function() spSendCommands{"luaui togglewidget TeamPlatter"} end, "Puts team-coloured disk below units")
	ShButton(pathSelectionBluryHalo, 'Toggle Blurry Halo Selections', function() spSendCommands{"luaui togglewidget Selection BlurryHalo 2"} end, "Places blurry halo around selected units")

ShLabel('Settings/Interface/Selection', 'General Settings')

local pathReclaimHighlight = "Settings/Interface/Reclaim Highlight"
	ShButton(pathReclaimHighlight, 'Toggle Field Summary', function() spSendCommands{"luaui togglewidget Reclaim Field Highlight"} end, "Draws shapes around fields of reclaim, and shows their equivalent metal value")

ShButton('Settings/Interface/Player Name Tags', 'Toggle Player Name Tags', function() spSendCommands{"luaui togglewidget Player Name Tags"} end, "Draws player names near visible units.")
ShButton('Settings/Interface/Battle Value Tracker', 'Toggle Battle Value Tracker', function() spSendCommands{"luaui togglewidget Battle Resource Tracker"} end, "Draws value killed and lost during a shortly after each battle. This toggle enables tracking, so battles that happen prior to the toggle are not shown.")


local pathGesture = 'Settings/Interface/Gesture Menu'
	ShButton(pathGesture, 'Toggle gesture menu', function() spSendCommands{"luaui togglewidget Chili Gesture Menu"} end, "Enable/disable gesture build menu.")

local pathToolbox = 'Settings/Toolbox'
	ShButton(pathToolbox, 'Toggle Start Zone Editor', function() spSendCommands{"luaui togglewidget Startbox Editor"} end, [[Map creation gui for drawing polygons and saving their coordinates]], true)

	
	ShButton(pathToolbox, 'Toggle Economy Announcer', function() spSendCommands{"luaui togglewidget Economic Victory Announcer v2"} end, "Toggles a widget that tracks team economies and announces 'victory' in chat, for certain manually run tournament games.")

--- MISC --- Ungrouped. If some of the settings here can be grouped together, make a new subsection or its own section.
local pathMisc = 'Settings/Misc'
	--ShButton( 'Exit Game...', "exitwindow", '', false ) --this breaks the exitwindow, fixme
	AddOption(pathMisc,
	{
		name = 'Show Advanced Settings',
		desc = 'Show developer tools and settings that should essentially never be disabled, except for testing.',
		type = 'bool',
		value = false,
		OnChange = function (self)
			WG.Epic_SetShowAdvancedSettings(self.value)
		end,
	})
	ShButton(pathMisc, 'Local Widget Config', function() spSendCommands{"luaui localwidgetsconfig"} end, '', true)
	AddOption(pathMisc,
	{
		name = 'Use uikeys.txt',
		desc = 'NOT RECOMMENDED! Enable this to use the engine\'s keybind file. This can break existing functionality. Requires restart.',
		type = 'bool',
		advanced = true,
		noHotkey = true,
		value = false,
	})
	AddOption(pathMisc,
	{
		name = 'Use Old Chili',
		desc = 'Enable this if menu element is missing or does not render properly in Spring 96+. '..
		       'Do NOT enable if you see nothing wrong with the menu (it is slower).'..
		       '\n(type "/luaui reload" to apply settings)',
		type = 'bool',
		value = false,
		noHotkey = true,
		advanced = true,
		OnChange = function (self)
			local value = (self.value and 1) or 0 --true = 1, false = 0
			if self.value then
				Spring.Echo("Will use old Chili")
			else
				Spring.Echo("Will use new Chili")
			end
			Spring.SetConfigInt("ZKuseOldChili", value); --store in Springsettings.txt because api_chili.lua must read it independent of gui_epicmenu.lua
		end,
	})
	ShButton(pathMisc, 'Toggle Redraw Tracker', function() spSendCommands{"luaui togglewidget Chili Redraw Tracker"} end, '', true)
	ShButton(pathMisc, 'Toggle Widget Profiler', function() spSendCommands{"luaui togglewidget WidgetProfiler"} end, '', true)
	ShButton(pathMisc, 'Toggle New Widget Profiler', function() spSendCommands{"luaui togglewidget Widget Profiler New"} end, '', true)

--- GRAPHICS --- We might define section as containing anything graphical that has a significant impact on performance and isn't necessary for gameplay
local pathGraphicsMap = 'Settings/Graphics/Map Detail'
	
	--ShRadio( pathGraphicsMap,
	--	'Water rendering', {
	--		{name = 'Basic',key='0', desc='A simple plane.', icon=imgPath..'epicmenu/water.png'},
	--		{name = 'Reflective',key='1', desc='Reflects the world.', icon=imgPath..'epicmenu/water.png'},
	--		-- crashy, see https://github.com/ZeroK-RTS/Zero-K/issues/3396
	--		--{name = 'Dynamic',key='2', desc='Has waves and wakes when units move and projectiles explode.', icon=imgPath..'epicmenu/water.png'},
	--		{name = 'Reflective / Refractive',key='3', desc='Reflects the world and has distortions.', icon=imgPath..'epicmenu/water.png'},
	--		{name = 'Bumpmapped',key='4', desc='Fast and good-looking.', icon=imgPath..'epicmenu/water.png'},
	--	},'4',
	--	function(self)
	--		spSendCommands{"water " .. self.value}
	--	end,
	--	true,
	--	true
	--)
	--
	--ShRadio( pathGraphicsMap,
	--	'Shadows cast by', {
	--		{name = 'Nothing',key='0', desc='Shadows disabled.'},
	--		{name = 'Units',key='2', desc='Only units cast shadows.'},
	--		{name = 'Units and terrain',key='1', desc='Terrain can cast shadows onto lower terrain. Units also cast shadows.'},
	--	},'1',
	--	function(self)
	--		spSendCommands{"Shadows " .. self.value}
	--	end,
	--	true,
	--	true
	--)
	--AddOption(pathGraphicsMap,
	--{
	--	name = 'Shadow detail level',
	--	desc = 'Temporary toggle. For a permanent toggle change go to Settings in the non-game main menu.',
	--	advanced = true,
	--	type = 'number',
	--	valuelist = {512, 1024, 2048, 4096, 8192, 16384},
	--	springsetting = 'ShadowMapSize',
	--	OnChange=function(self)
	--		local curShadow = Spring.GetConfigInt("Shadows") or 0
	--		spSendCommands{"Shadows " .. curShadow .. ' ' .. self.value}
	--	end,
	--})

	ShLabel(pathGraphicsMap, 'Miscellaneous')
	AddOption(pathGraphicsMap,
	{
		name = 'Map Brightness',
		desc = 'How bright the terrain appears.',
		type = 'number',
		min = 0,
		max = 1,
		step = 0.01,
		value = 1,
		icon = imgPath..'epicmenu/stock_brightness.png',
		OnChange = function(self) spSendCommands{"luaui enablewidget Darkening", "luaui darkening " .. 1-self.value} end,
	} )

	--AddOption(pathGraphicsMap,
	--{
	--	name = 'Terrain detail',
	--	desc = 'Control the accuracy of the terrain.',
	--	type = 'number',
	--	min = 30,
	--	max = 250,
	--	step = 5,
	--	value = 90,
	--	OnChange = function(self) spSendCommands{"GroundDetail " .. self.value} end,
	--} )

	AddOption(pathGraphicsMap,
	{
		name = 'Ground Decals',
		desc = 'Whether explosions leave scars on the ground.',
		type = 'bool',
		springsetting = 'GroundDecals',
		OnChange=function(self) spSendCommands{"grounddecals " .. (self.value and 1 or 0) } end,
		noHotkey = true,
	} )
	
	--ShButton(pathGraphicsMap, 'Toggle ROAM Rendering', function() spSendCommands{"roam"} end, "Toggle between legacy map rendering and (the new) ROAM map rendering." )

local pathGraphicsExtras = 'Settings/Graphics/Effects'
	AddOption(pathGraphicsExtras,
	{
		name = 'Particle density',
		desc = 'Temporary toggle. For a permanent toggle change go to Settings in the non-game main menu.',
		advanced = true,
		type = 'number',
		min = 250,
		max = 20000,
		step = 250,
		value = 10000,
		springsetting = 'MaxParticles',
		OnChange=function(self) spSendCommands{"maxparticles " .. self.value } end,
	} )
	ShButton(pathGraphicsExtras, 'Toggle Lups (Lua Particle System)', function() spSendCommands{'luaui togglewidget LupsManager','luaui togglewidget Lups'} end )
	ShButton(pathGraphicsExtras, 'Toggle Nightvision', function() spSendCommands{'luaui togglewidget Nightvision Shader'} end, 'Applies a nightvision filter to screen')
	ShButton(pathGraphicsExtras, 'Toggle Night View', function() spSendCommands{'luaui togglewidget Night'} end, 'Adds a day/night cycle effect' )


local pathUnitVisiblity = 'Settings/Graphics/Unit Visibility'
	ShLabel(pathUnitVisiblity, 'Unit Visibility Options')
	AddOption(pathUnitVisiblity,
	{
		name = 'Draw Distance',
		type = 'number',
		min = 1,
		max = 10000,
		springsetting = 'UnitLodDist',
		OnChange = function(self) spSendCommands{"distdraw " .. self.value} end,
		advanced = true,
	} )
	AddOption(pathUnitVisiblity,
	{
		name = 'Icon Distance',
		type = 'number',
		min = 1,
		max = 1000,
		springsetting = 'UnitIconDist',
		OnChange = function(self)
			spSendCommands{"disticon " .. self.value}
			WG.resetIconDist = self.value
		end
	} )
	AddOption(pathUnitVisiblity,
	{
		name = 'Shiny Units',
		type = 'bool',
		advanced = true,
		springsetting = 'AdvUnitShading',
		OnChange=function(self) spSendCommands{"advmodelshading " .. (self.value and 1 or 0) } end, --needed as setconfigint doesn't apply change right away
	} )
	ShLabel(pathUnitVisiblity, 'Unit Highlight Options')
	
	-- Why are selections here? They are in Settings/Interface/Selection
	--AddOption(pathUnitVisiblity,
	--{
	--	name = 'Selections GL4 (default)',
	--	desc = "Shows shape and base platter around units. This is the default option.",
	--	type = 'bool',
	--	value = true,
	--	OnChange = function(self)
	--		SetWidgetEnableState("Selected Units GL4 2", self.value)
	--	end,
	--} )
	--AddOption(pathUnitVisiblity,
	--{
	--	name = 'Selection Shapes (old)',
	--	desc = "Show appropriate shapes around the base of selected and hovered units.",
	--	type = 'bool',
	--	value = false,
	--	OnChange = function(self)
	--		SetWidgetEnableState("UnitShapes 3", self.value)
	--	end,
	--} )
	--AddOption(pathUnitVisiblity,
	--{
	--	name = 'Teamcolour Halos',
	--	desc = "Shows a thin halo of team colour around units.",
	--	type = 'bool',
	--	value = false,
	--	OnChange = function(self)
	--		SetWidgetEnableState("Halo", self.value)
	--	end,
	--} )
	--AddOption(pathUnitVisiblity,
	--{
	--	name = 'Teamcolour Baseplatter',
	--	desc = "Highlight the base of units with a disk of their team colour.",
	--	type = 'bool',
	--	value = false,
	--	OnChange = function(self)
	--		SetWidgetEnableState("Fancy Teamplatter", self.value)
	--	end,
	--} )
	--AddOption(pathUnitVisiblity,
	--{
	--	name = 'Selection Halo',
	--	desc = "Add a large halo around selected and hovered units.",
	--	type = 'bool',
	--	value = false,
	--	OnChange = function(self)
	--		SetWidgetEnableState("Selection BlurryHalo 2", self.value)
	--	end,
	--} )
	
	--local pathSpotter = 'Settings/Graphics/Unit Visibility/Spotter'
	--	ShButton(pathSpotter, 'Toggle Unit Spotter', function() spSendCommands{"luaui togglewidget Spotter"} end, "Puts team-coloured blob below units")
	--local pathPlatter = 'Settings/Graphics/Unit Visibility/Platter'
	--	ShButton(pathPlatter, 'Toggle Unit Platter', function() spSendCommands{"luaui togglewidget Fancy Teamplatter"} end, "Puts a team-coloured platter-halo below units.")
	local pathXrayShader = 'Settings/Graphics/Unit Visibility/XRay Shader'
		ShButton(pathXrayShader, 'Toggle XRay Shader', function() spSendCommands{"luaui togglewidget XrayShader"} end, "Highlights edges of units")
	local pathIconZoomTransition = 'Settings/Graphics/Unit Visibility/Icon Zoom Transition'
		ShButton(pathIconZoomTransition, 'Toggle Smooth Icon Zoom', function() spSendCommands{"luaui togglewidget Icon Zoom Transition"} end, "Draw both icons and models at medium zoom distance.")
	local pathUnitOutline = 'Settings/Graphics/Unit Visibility/Outline'
		ShButton(pathUnitOutline, 'Toggle Unit Outline', function()
				spSendCommands{"luaui disablewidget Outline No Shader"}
				spSendCommands{"luaui togglewidget Outline Shader GL4"}
			end, "Highlights edges of units")



local pathSSAO = 'Settings/Graphics/Ambient Occlusion'
	WG.SSAO_RequireDeferredRendering = true
	ShButton(
		pathSSAO, 'Toggle SSAO',
		function()
			spSendCommands{"luaui togglewidget ssao 3"}
		end, "Toggle Screen Space Ambient Occlusion. It essentially adds a bit of shading to everything.")
	AddOption(pathSSAO,
		{
			name = 'Require deferred rendering',
			desc = 'SSAO can cause visual issues if enabled without deferred rendering. This option force-disables SSAO if deferred rendering is not found.',
			type = 'bool',
			value = true,
			OnChange = function(self)
				WG.SSAO_RequireDeferredRendering = self.value
				if WG.WidgetEnabledAndActive then
					if self.value and not WG.WidgetEnabledAndActive("Deferred rendering") then
						spSendCommands{"luaui disablewidget ssao 3"}
					else
						spSendCommands{"luaui enablewidget ssao 3"}
					end
				end
			end,
		})

local pathAudio = 'Settings/Audio'
	AddOption(pathAudio,{
		name = 'Master Volume',
		desc = 'Overall volume level, acts on top of the specific levels below.',
		type = 'number',
		min = 0,
		max = 100,
		springsetting = 'snd_volmaster',
		OnChange = function(self)
			if WG.crude and WG.crude.SetMasterVolume then
				WG.crude.SetMasterVolume(self.value)
			end
		end,
		simpleMode = true,
		everyMode = true,
	})
	AddOption(pathAudio,{
		name = 'Battle Volume',
		desc = 'Combat effects such as weapon fire and explosions.',
		type = 'number',
		min = 0,
		max = 100,
		springsetting = 'snd_volbattle',
		OnChange = function(self) spSendCommands{"set snd_volbattle " .. self.value} end,
		simpleMode = true,
		everyMode = true,
	})
	AddOption(pathAudio,{
		name = 'UI Volume',
		desc = 'Interface notifications such as chat. Also applies to unit replies.',
		type = 'number',
		min = 0,
		max = 100,
		springsetting = 'snd_volui',
		OnChange = function(self) spSendCommands{"set snd_volui " .. self.value} end,
		simpleMode = true,
		everyMode = true,
	})
	AddOption(pathAudio,{
		name = 'Unit Reply Volume',
		desc = 'Noises that units make when being selected or given orders.',
		type = 'number',
		key = "unit_reply_volume",
		value = 50,
		min = 0,
		max = 100,
		OnChange = function(self) WG.unitReplyVolumeMult =  self.value / 50 end, -- pay attention, the scaled value is 0-2!
		simpleMode = true,
		everyMode = true,
	})
	AddOption(pathAudio,{
		name = 'Ambient Volume',
		desc = 'Miscellaneous sounds such as the environment or a busy base.',
		type = 'number',
		min = 0,
		max = 100,
		springsetting = 'snd_volgeneral',
		OnChange = function(self) spSendCommands{"set snd_volgeneral " .. self.value} end,
		simpleMode = true,
		everyMode = true,
	})
	AddOption(pathAudio,{
		name = 'Music Volume',
		type = 'number',
		min = 0,
		max = 1,
		step = 0.01,
		-- springsetting = 'snd_volmusic', -- TODO: we should probably switch from WG to this at some point
		value = WG.music_volume or 0.5,
		OnChange = function(self)
			if WG.crude and WG.crude.SetMusicVolume then
				WG.crude.SetMusicVolume(self.value)
			end
		end,
		simpleMode = true,
		everyMode = true,
	})


--- HUD ETC ---
AddOption("Settings/HUD Panels/Pause Screen",
	{
		name = 'Menu pauses in SP',
		desc = 'Does opening the menu pause the game in single player?',
		type = 'bool',
		value = true,
		noHotkey = true,
	})
AddOption("Settings/HUD Panels/Pause Screen",
	{
		name = 'Menu unpauses in SP',
		desc = 'Does closing the menu unpause the game in single player?',
		type = 'bool',
		value = true,
		noHotkey = true,
	})

--- HELP ---
local pathHelp = 'Help'
	AddOption(pathHelp,
	{
		type='text',
		name='Space + Click Tips',
		value = [[Hold Space and click on a unit or wreck to display detailed information.
        You can also space-click on commands and other interface elements to open their hotkey settings. ]]
	})
	AddOption(pathHelp,
	{
		type='text',
		name='Ingame Tutorial',
		value = [[The button below guides you through the whys and hows of setting up a base and advancing with an army. It can be disabled at any time.
        This tutorial is not availible in the campaign or when spectating.]]
	})
	ShButton(pathHelp,'Toggle Ingame Tutorial', function() spSendCommands{"luaui togglewidget Nubtron 2.0"} end )
	AddOption(pathHelp,
	{
		type='label',
		name='Unit Lists and Concepts',
	})
	
--- TIPS ---
local pathTips = 'Settings/Tips'
	ShButton(pathHelp,'Tip Dispenser', function() spSendCommands{"luaui togglewidget Automatic Tip Dispenser"} end, 'An advisor which gives you tips as you play' )
local pathClippy = 'Settings/Tips/Clippy Comments'
	ShButton(pathClippy, 'Toggle Clippy Comments', function() spSendCommands{"luaui togglewidget Clippy Comments"} end, "Units speak up if they see you're not playing optimally" )


--- MISC
--

return confdata
