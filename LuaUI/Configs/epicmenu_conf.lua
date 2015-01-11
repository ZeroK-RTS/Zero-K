local confdata = {}
confdata.title = 'Z.K.'
confdata.title_image = LUAUI_DIRNAME .. 'Images/ZK_logo.png'
confdata.default_source_file = 'zk_keys.lua' --the file in ZIP archive where default key is stored.
confdata.mission_keybinds_file = 'zk_keys.lua' --the filename to be used for Mission mod. set this to NIL if want to use mission's name as filename.
-- confdata.regular_keybind_file = LUAUI_DIRNAME .. 'Configs/zk_keys.lua' --for Multiplayer this is automatically set according to modName in epicmenu.lua
--FIXME: find modname instead of using hardcoded mission_keybinds_file name
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
	
	null = {nil, nil, nil, 1},
	transnull = {nil, nil, nil, 0.3},
	transnull2 = {nil, nil, nil, 0.5},
	transnull3 = {nil, nil, nil, 0.8},
}

color.tooltip_bg = color.transnull3
color.tooltip_fg = color.null
color.tooltip_info = color.cyan
color.tooltip_help = color.green

color.main_bg = color.transnull2
color.main_fg = color.null

color.menu_bg = color.null
color.menu_fg = color.null

color.game_bg = color.null
color.game_fg = color.null

color.sub_bg	= color.transnull
color.sub_fg 	= color.null
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

local function AddOption(path, option)
	option.path = path or "Settings\Broken Paths"
	if not option.key then
		option.key = option.name
	end
	table.insert(confdata.eopt, option)
end

--ShortHand for adding a button
local function ShButton(path, caption, action2, tooltip, advanced, icon, DisableFunc)
	AddOption(path,
	{
		type='button',
		name=caption,
		desc = tooltip or '',
		action = (type(action2) == 'string' and action2 or nil),
		OnChange = (type(action2) ~= 'string' and action2 or nil),
		key=caption,
		advanced = advanced,
		icon = icon,
		DisableFunc = DisableFunc or nil, --function that trigger grey colour on buttons (not actually disable their functions, only coloured them grey)
	})
end


--ShortHand for adding radiobuttons
local function ShRadio(path, caption, items,defValue, action2, advanced) 
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
	['Game'] = imgPath..'epicmenu/game.png',
	['Settings'] = imgPath..'epicmenu/settings.png',
	['Help'] = imgPath..'epicmenu/questionmark.png',
	
	['Game/Game Speed'] = imgPath..'epicmenu/speed-test-icon.png',
	['Game/New Unit States'] = imgPath..'epicmenu/robot2.png',
	['Settings/Reset Settings'] = imgPath..'epicmenu/undo.png',
	['Settings/Audio'] = imgPath..'epicmenu/vol.png',
	['Settings/Camera'] = imgPath..'epicmenu/video_camera.png',
	['Settings/Graphics'] = imgPath..'epicmenu/graphics.png',
	['Settings/HUD Panels'] = imgPath..'epicmenu/control_panel.png',
	['Settings/Interface'] = imgPath..'epicmenu/robotarm.png',
	['Settings/Misc'] = imgPath..'epicmenu/misc.png',
	
	['Settings/Interface/Mouse Cursor'] = imgPath..'epicmenu/input_mouse.png',
	['Settings/Interface/Map'] = imgPath..'epicmenu/map.png',
	['Settings/Interface/Healthbars'] = imgPath..'commands/Bold/health.png',
	['Settings/Interface/Retreat Zones'] = imgPath..'commands/Bold/retreat.png',
	['Settings/Interface/Spectating'] = imgPath..'epicmenu/find.png',
}

-- SETUP MENU HERE

--- GENERAL SETTINGS --- settings about settings
local generalPath = 'Settings/Reset Settings'
	ShLabel(generalPath, 'Reset graphic settings to minimum.')
	ShButton(generalPath, 'Reset graphic settings',function()
					spSendCommands{"water 0",
						"Shadows 0",
						"maxparticles 100",
						"advmodelshading 0",
						"grounddecals 0",
						'luaui disablewidget LupsManager',
						"luaui disablewidget Lups",
						"luaui disablewidget Display DPS",
						"luaui disablewidget Map Edge Extension",
						"luaui disablewidget SelectionHalo",
						"luaui disablewidget SelectionCircle",
						"luaui disablewidget UnitShapes",
					}
				end,
				'Use this if your performance is poor'
			)
	ShLabel(generalPath, 'Reset custom settings to default.')
	ShButton(generalPath, 'Reset custom settings', function() WG.crude.ResetSettings() end)
	ShLabel(generalPath, 'Reset hotkeys.')
	ShButton(generalPath, 'Reset hotkeys',function() WG.crude.ResetKeys() end)


local settingsPath = 'Settings'
	--[[
	AddOption(settingsPath,
	{
		name = 'Show Advanced Settings',
		type = 'bool',
		value = false,
	})
	--]]


--- GAME --- Stuff for gameplay only. Spectator would never need to open this
local gamePath = 'Game' 
local gameSpeedPath = 'Game/Game Speed'

	ShButton(gamePath, 'Pause/Unpause', 'pause', nil, nil, imgPath .. 'epicmenu/media_playback_pause.png')
		ShButton(gameSpeedPath, 'Increase Speed', 'speedup')
		ShButton(gameSpeedPath, 'Decrease Speed', 'slowdown')
		
	ShLabel(gamePath, '')
	ShButton(gamePath, 'Choose Commander Type', (function() spSendCommands{"luaui showstartupinfoselector"} end)) 
--	ShButton(gamePath, 'Constructor Auto Assist', function() spSendCommands{"luaui togglewidget Constructor Auto Assist"} end)


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
			{name = 'Total Annihilation',key='Total Annihilation', desc='TA camera', hotkey=nil},
			{name = 'FPS',key='FPS', desc='FPS camera', hotkey=nil},
			{name = 'Free',key='Free', desc='Freestyle camera', hotkey=nil},
			{name = 'Rotatable Overhead',key='Rotatable Overhead', desc='Rotatable Overhead camera', hotkey=nil},
			{name = 'Total War',key='Total War', desc='TW camera', hotkey=nil},
			{name = 'COFC',key='COFC', desc='Combo Overhead/Free Camera', hotkey=nil},
		},'Total Annihilation',
		function(self)
			local key = self.value
			if key == 'Total Annihilation' then
				spSendCommands{cofcDisable ,"viewta"}
			elseif key == 'FPS' then
				spSendCommands{cofcDisable ,"viewfps"}
			elseif key == 'Free' then
				spSendCommands{cofcDisable ,"viewfree"}
			elseif key == 'Rotatable Overhead' then
				spSendCommands{cofcDisable ,"viewrot"}
			elseif key == 'Total War' then
				spSendCommands{cofcDisable ,"viewtw"}
			elseif key == 'COFC' then
				spSendCommands{"luaui enablewidget Combo Overhead/Free Camera (experimental)",}
			end
		end
		)
	
	ShButton(cameraPath, 'Flip the TA Camera', 'viewtaflip')
	ShButton(cameraPath, 'Toggle Camera Shake', 'luaui togglewidget CameraShake')
	ShButton(cameraPath, 'Toggle SmooothScroll', 'luaui togglewidget SmoothScroll')
	ShButton(cameraPath, 'Toggle Smooth Camera', 'luaui togglewidget SmoothCam')
	--ShButton(cameraPath, 'Toggle advanced COFC camera', 'luaui togglewidget Combo Overhead/Free Camera (experimental)' )

local oldCameraPath = 'Settings/Camera/Old Camera Shortcuts'	
	ShButton(oldCameraPath, 'Total Annihilation', 'viewta')
	ShButton(oldCameraPath, 'FPS', 'viewfps')
	ShButton(oldCameraPath, 'Free', 'viewfree')
	ShButton(oldCameraPath, 'Rotatable Overhead', 'viewrot')
	ShButton(oldCameraPath, 'Total War', 'viewtw')
	ShLabel(oldCameraPath, '')
	ShButton(oldCameraPath, 'Move Forward', 'moveforward')	
	ShButton(oldCameraPath, 'Move Back', 'moveback')	
	ShButton(oldCameraPath, 'Move Left', 'moveleft')	
	ShButton(oldCameraPath, 'Move Right', 'moveright')
	ShLabel(oldCameraPath, ' ')
	ShButton(oldCameraPath, 'TA camera track unit', 'track')
	ShButton(oldCameraPath, 'Overview mode', 'toggleoverview')
	ShButton(oldCameraPath, 'Panning mode','mousestate', 'Note: must be bound to a key for use')
	
	
--- HUD Panels --- Only settings that pertain to windows/icons at the drawscreen level should go here.
local HUDPath = 'Settings/HUD Panels'
	ShButton(HUDPath, 'Tweak Mode (Esc to exit)', 'luaui tweakgui', 'Tweak Mode. Move and resize parts of the user interface. (Hit Esc to exit)')

local HUDSkinPath = 'Settings/HUD Panels/HUD Skin'
	AddOption(HUDSkinPath,
	{
		name = 'Skin Sets (Requires LuaUI Reload)',
		type = 'list',
		OnChange = function (self)
			WG.crude.SetSkin( self.value );
		end,
		items = {
			{ key = 'Carbon', name = 'Carbon', },
			{ key = 'Robocracy', name = 'Robocracy', },
			{ key = 'DarkHive', name = 'DarkHive', },
			{ key = 'DarkHiveSquare', name = 'DarkHive (square)', },
			{ key = 'Twilight', name = 'Twilight', },
		},
	})
	ShButton(HUDSkinPath, 'Reload LuaUI', 'luaui reload', 'Reloads the entire UI. NOTE: This button will not work. You must bind a hotkey to this command and use the hotkey.')


--- Interface --- anything that's an interface but not a HUD Panel
local pathInterface = 'Settings/Interface'
local pathMap = 'Settings/Interface/Map'
local pathMouse = 'Settings/Interface/Mouse Cursor'
	ShButton(pathInterface, 'Toggle DPS Display', function() spSendCommands{"luaui togglewidget Display DPS"} end, 'Shows RPG-style damage')
	ShButton(pathMap, 'Map Draw Key', "drawinmap", nil, true)
	ShButton(pathMouse, 'Toggle Grab Input', function() spSendCommands{"grabinput"} end, 'Mouse cursor won\'t be able to leave the window.')
	AddOption(pathMouse,
	{ 	
		name = 'Hardware Cursor',
		type = 'bool',
		springsetting = 'HardwareCursor',
		OnChange=function(self) spSendCommands{"hardwarecursor " .. (self.value and 1 or 0) } end, 
	})	
	
local pathSelectionShapes = 'Settings/Interface/Selection/Selection Shapes'
local pathSelectionXrayHalo = 'Settings/Interface/Selection/Selection XRay&Halo'
local pathSelectionPlatters = 'Settings/Interface/Selection/Blurry Halo Selections'
local pathSelectionBluryHalo = 'Settings/Interface/Selection/Blurry Halo Selections'
	ShButton(pathSelectionShapes, 'Toggle Selection Shapes', function() spSendCommands{"luaui togglewidget UnitShapes"} end, "Draws coloured shapes under selected units")
	ShButton(pathSelectionXrayHalo, 'Toggle Selection XRay&Halo', function() spSendCommands{"luaui togglewidget XrayHaloSelections"} end, "Highlights bodies of selected units")	
	ShButton(pathSelectionPlatters, 'Toggle Team Platters', function() Spring.SendCommands{"luaui togglewidget TeamPlatter"} end, "Puts team-coloured disk below units")
	ShButton(pathSelectionBluryHalo, 'Toggle Blurry Halo Selections', function() Spring.SendCommands{"luaui togglewidget Selection BlurryHalo"} end, "Places blurry halo around selected units")

  
--- MISC --- Ungrouped. If some of the settings here can be grouped together, make a new subsection or its own section.
local pathMisc = 'Settings/Misc'
	ShButton(pathMisc, 'Local Widget Config', function() spSendCommands{"luaui localwidgetsconfig"} end, '', true)
	ShButton(pathMisc, 'Game Info', "gameinfo", '', true)
	ShButton(pathMisc, 'Share Dialog...', 'sharedialog', '', true)
	ShButton(pathMisc, 'FPS Control', "controlunit", 'Control a unit directly in FPS mode.', true)
	--ShButton( 'Exit Game...', "exitwindow", '', false ) --this breaks the exitwindow, fixme
	AddOption(pathMisc,
	{
		name = 'Menu pauses in SP',
		desc = 'Does opening the menu pause the game (and closing unpause it) in single player?',
		type = 'bool',
		value = true,
	})
	AddOption(pathMisc,
	{
		name = 'Use uikeys.txt',
		desc = 'NOT RECOMMENDED! Enable this to use the engine\'s keybind file. This can break existing functionality. Requires restart.',
		type = 'bool',
		advanced = true,
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


local pathMiscScreenshots = 'Settings/Misc/Screenshots'	
	ShButton(pathMiscScreenshots, 'Save Screenshot (PNG)', 'screenshot', 'Find your screenshots under Spring/screenshots') 
	ShButton(pathMiscScreenshots, 'Save Screenshot (JPG)', 'screenshot jpg', 'Find your screenshots under Spring/screenshots')
	ShButton(pathMiscScreenshots, 
			'Create Video (risky)', 'createvideo', 'Capture video directly from Spring without sound. Gets saved in the Spring folder. '
			..'Creates a smooth video framerate without ingame stutter. '
			..'Caution: It\'s safer to use this in windowed mode because the encoder pop-up menu appears in the foreground window, and could crash the game with a "Fatal Error" after a long recording. '
			..'\n\nRecommendation (especially for low-end PCs): After activating the video recording select the fastest encoder such as Microsoft Video and record the video in segments. '
			..' You can then use VirtualDub (opensource software) to do futher compression and editing. Note: there is other opensource video capture software like Taksi that you could try.') 
	
--- GRAPHICS --- We might define section as containing anything graphical that has a significant impact on performance and isn't necessary for gameplay
local pathGraphics = 'Settings/Graphics'
	ShLabel(pathGraphics, 'View Radius')
	
	ShButton(pathGraphics, 'Increase Radius', "increaseviewradius")
	ShButton(pathGraphics, 'Decrease Radius', "decreaseviewradius")


	ShLabel(pathGraphics, 'Trees')
	ShButton(pathGraphics, 'Toggle View', 'drawtrees', nil, nil, imgPath..'epicmenu/tree_1.png')
	ShButton(pathGraphics, 'See More Trees', 'moretrees', nil, nil, imgPath..'epicmenu/tree_1.png')
	ShButton(pathGraphics, 'See Less Trees', 'lesstrees', nil, nil, imgPath..'epicmenu/tree_1.png')
	--{'Toggle Dynamic Sky', function(self) spSendCommands{'dynamicsky'} end },
	
	ShLabel(pathGraphics, 'Water Settings')
	ShButton(pathGraphics, 'Basic', function() spSendCommands{"water 0"} end, nil, nil, imgPath..'epicmenu/water.png')
	ShButton(pathGraphics, 'Reflective', function() spSendCommands{"water 1"} end, nil, nil, imgPath..'epicmenu/water.png')
	ShButton(pathGraphics, 'Reflective and Refractive', function() spSendCommands{"water 3"} end, nil, nil, imgPath..'epicmenu/water.png')
	ShButton(pathGraphics, 'Dynamic', function() spSendCommands{"water 2"} end, nil, nil, imgPath..'epicmenu/water.png')
	ShButton(pathGraphics, 'Bumpmapped', function() spSendCommands{"water 4"} end, nil, nil, imgPath..'epicmenu/water.png')

	ShLabel(pathGraphics, 'Shadow Settings')
	
	AddOption(pathGraphics, 
	{
		name = 'Shadow Detail (Slide left for off)',
		type = 'number',
		valuelist = {512, 1024, 2048, 4096},
		springsetting = 'ShadowMapSize',
		OnChange=function(self)
			local curShadow = Spring.GetConfigInt("Shadows") or 0
			if curShadow == 0 then
				return
			end
			curShadow=math.max(1,curShadow)
			spSendCommands{"Shadows " .. curShadow .. ' ' .. self.value}
		end, 
	})
	
	ShButton(pathGraphics, 
	'Toggle Shadows',
		function()
			local curShadow = Spring.GetConfigInt("Shadows") or 0
			if curShadow == 0 then
				spSendCommands{"Shadows 1"}
			elseif curShadow > 0 then
				spSendCommands{"Shadows 0"}
			elseif curShadow == -1 then
				Spring.Echo("Shadows cannot be toggled ingame with Shadows = -1 in springsettings")
			end
		end
	)

	ShButton(pathGraphics, 'Toggle Terrain Shadows',
		function()
			local curShadow=Spring.GetConfigInt("Shadows") or 0
			if curShadow == 0 then
				Spring.Echo 'Shadows are turned off, you must first enable them.'
				return
			end
			if (curShadow<2) then 
				curShadow=2 
			else 
				curShadow=1 
			end
			spSendCommands{"Shadows "..curShadow}
		end
	)
	
	ShLabel(pathGraphics, 'Various')
	AddOption(pathGraphics, 
	{
		name = 'Brightness',
		type = 'number',
		min = 0, 
		max = 1, 
		step = 0.01,
		value = 1,
		icon = imgPath..'epicmenu/stock_brightness.png',
		OnChange = function(self) Spring.SendCommands{"luaui enablewidget Darkening", "luaui darkening " .. 1-self.value} end, 
	} )
	
	
	AddOption(pathGraphics, 
	{ 	
		name = 'Ground Decals',
		type = 'bool',
		springsetting = 'GroundDecals',
		OnChange=function(self) spSendCommands{"grounddecals " .. (self.value and 1 or 0) } end, 
	} )

	AddOption(pathGraphics, 
	{
		name = 'Maximum Particles (100 - 20,000)',
		type = 'number',
		valuelist = {100,500,1000,2000,5000,10000,20000},
		springsetting = 'MaxParticles',
		OnChange=function(self) Spring.SendCommands{"maxparticles " .. self.value } end, 
	} )
	ShButton(pathGraphics, 'Toggle Lups (Lua Particle System)', function() spSendCommands{'luaui togglewidget LupsManager','luaui togglewidget Lups'} end )
	ShButton(pathGraphics, 'Toggle ROAM Rendering', function() spSendCommands{"roam"} end, "Toggle between legacy map rendering and (the new) ROAM map rendering." )
	
local pathGraphicsExtras = 'Settings/Graphics/Effects'
	ShButton(pathGraphicsExtras, 'Toggle Nightvision', function() spSendCommands{'luaui togglewidget Nightvision Shader'} end, 'Applies a nightvision filter to screen')
	ShButton(pathGraphicsExtras, 'Smoke Signal Markers', function() spSendCommands{'luaui togglewidget Smoke Signal'} end, 'Creates a smoke signal effect at map points' )
local pathGraphicsExtrasNight = 'Settings/Graphics/Effects/Night View'
	ShButton(pathGraphicsExtrasNight, 'Toggle Night View', function() spSendCommands{'luaui togglewidget Night'} end, 'Adds a day/night cycle effect' )
	


local pathVR = 'Settings/Graphics/Map/VR Grid'
	ShButton(pathVR, 'Toggle VR Grid', function() spSendCommands{'luaui togglewidget External VR Grid'} end, 'Draws a grid around the map' )
local pathMapExtension = 'Settings/Graphics/Map/Map Extension'
	ShButton(pathMapExtension, 'Toggle Map Extension', function() spSendCommands{'luaui togglewidget Map Edge Extension'} end ,'Alternate map grid')
local pathEdgeBarrier = 'Settings/Graphics/Map/Edge Barrier'
	ShButton(pathEdgeBarrier, 'Toggle Edge Barrier', function() spSendCommands{'luaui togglewidget Map Edge Barrier'} end, 'Draws a boundary wall at map edges')
	
local pathUnitVisiblity = 'Settings/Graphics/Unit Visibility'
	ShLabel(pathUnitVisiblity, 'Unit Visibility Options')
	AddOption(pathUnitVisiblity,
	{
		name = 'Draw Distance',
		type = 'number',
		min = 1, 
		max = 10000,
		springsetting = 'UnitLodDist',
		OnChange = function(self) Spring.SendCommands{"distdraw " .. self.value} end 
	} )
	AddOption(pathUnitVisiblity,
	{
	  name = 'Icon Distance',
	  type = 'number',
	  min = 1, 
	  max = 1000,
	  springsetting = 'UnitIconDist',
	  OnChange = function(self) Spring.SendCommands{"disticon " .. self.value} end 
	  } )
	AddOption(pathUnitVisiblity,
	{
		name = 'Shiny Units',
		type = 'bool',
		springsetting = 'AdvUnitShading',
		OnChange=function(self) spSendCommands{"advmodelshading " .. (self.value and 1 or 0) } end, --needed as setconfigint doesn't apply change right away
	} )
	ShLabel(pathUnitVisiblity, 'Unit Visibility Widgets')
	ShButton(pathUnitVisiblity,'Toggle Unit Halos', function() spSendCommands{"luaui togglewidget Halo"} end, "Shows halo around units")
	
	local pathSpotter = 'Settings/Graphics/Unit Visibility/Spotter'
		ShButton(pathSpotter, 'Toggle Unit Spotter', function() Spring.SendCommands{"luaui togglewidget Spotter"} end, "Puts team-coloured blob below units")
	local pathXrayShader = 'Settings/Graphics/Unit Visibility/XRay Shader'
		ShButton(pathXrayShader, 'Toggle XRay Shader', function() spSendCommands{"luaui togglewidget XrayShader"} end, "Highlights edges of units")
	local pathUnitOutline = 'Settings/Graphics/Unit Visibility/Outline'
		ShButton(pathUnitOutline, 'Toggle Unit Outline', function() spSendCommands{"luaui togglewidget Outline"} end, "Highlights edges of units")

--[[
path='Settings/Audio'
	AddOption({
		name = 'Sound Volume',
		type = 'number',
		min = 0, 
		max = 100,
		springsetting = 'snd_volmaster',
		OnChange = function(self) spSendCommands{"set snd_volmaster " .. self.value} end
	} )
	AddOption({
		name = 'Music Volume',
		type = 'number',
		min = 0, 
		max = 1,
		step = 0.01,
		value = WG.music_volume or 0.5,
		OnChange = function(self)	
				if (WG.music_start_volume or 0 > 0) then 
					Spring.SetSoundStreamVolume(self.value / WG.music_start_volume) 
				else 
					Spring.SetSoundStreamVolume(self.value) 
				end
				local prevValue = WG.music_volume
				--settings.music_volume = self.value
				WG.music_volume = self.value
				if (prevValue > 0 and self.value <=0) then widgetHandler:DisableWidget("Music Player") end 
				if (prevValue <=0 and self.value > 0) then widgetHandler:EnableWidget("Music Player") end 
			end,
	} )
]]
		
--- HELP ---
local pathHelp = 'Help'
	AddOption(pathHelp,
	{
		type='text',
		name='Tips',
		value=[[Hold your meta-key (spacebar by default) while clicking on a unit or corpse for more info and options. 
			You can also space-click on menu elements to see context settings. 
			]]
	})
	ShButton(pathHelp,'Tutorial', function() spSendCommands{"luaui togglewidget Nubtron"} end )
	ShButton(pathHelp,'Tip Dispenser', function() spSendCommands{"luaui togglewidget Automatic Tip Dispenser"} end, 'An advisor which gives you tips as you play' )
local pathClippy = 'Help/Clippy Comments'
	ShButton(pathClippy, 'Toggle Clippy Comments', function() spSendCommands{"luaui togglewidget Clippy Comments"} end, "Units speak up if they see you're not playing optimally" )

--- MISC
--

return confdata