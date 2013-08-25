function widget:GetInfo()
  return {
    name      = "Chili Minimap",
    desc      = "v0.890 Chili Minimap",
    author    = "Licho, CarRepairer",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = -100000,
    experimental = false,
    enabled   = true, --  loaded by default?
	detailsDefault = 1
  }
end

local window_minimap
local map_panel 
local Chili
local glDrawMiniMap = gl.DrawMiniMap
local glResetState = gl.ResetState
local glResetMatrices = gl.ResetMatrices
local echo = Spring.Echo

local iconsize = 20
local bgColor_panel = {nil,nil,nil,1}

local tabbedMode = false
--local init = true

local function toggleTeamColors()
	if WG.LocalColor and WG.LocalColor.localTeamColorToggle then
		WG.LocalColor.localTeamColorToggle()
	else
		Spring.SendCommands("luaui enablewidget Local Team Colors")
	end
end 

local ar = Game.mapX/Game.mapY
local mapIsWider = Game.mapX > Game.mapY
local function AdjustToMapAspectRatio(w,h)
	if mapIsWider then
		return w, w/ar +iconsize
	end
	return h*ar, h+iconsize
end

local function AdjustMapAspectRatioToWindow(x,y,w,h)
	local newW, newH = w,h
	local newX, newY = x,y
	if w/h > ar then
		newW = ar*h
		newX = (w-newW)/2
	else
		newH = w/ar
		newY = (h-newH)/2
	end
	return newX, newY, newW, newH
end

local function MakeMinimapWindow()
end

options_path = 'Settings/Interface/Map'
local minimap_path = 'Settings/HUD Panels/Minimap'
--local radar_path = 'Settings/Interface/Map/Radar View Colors'
local radar_path = 'Settings/Interface/Map'
options_order = { 'use_map_ratio', 'hidebuttons', 'initialSensorState', 'lastmsgpos', 'clearmapmarks', 'opacity',
'lblViews', 'viewheightmap', 'viewblockmap', 'lblLos', 'viewfow',
'radar_view_colors_label1', 'radar_view_colors_label2', 'radar_fog_color', 'radar_los_color', 'radar_radar_color', 'radar_jammer_color', 
'radar_preset_blue_line', 'radar_preset_blue_line_dark_fog', 'radar_preset_green', 'radar_preset_only_los'}
options = {
	use_map_ratio = {
		name = 'Keep Aspect Ratio',
		type = 'radioButton',
		value = 'arwindow',
		items={
			{key='arwindow', 	name='Aspect Ratio Window'},
			{key='armap', 		name='Aspect Ratio Map'},
			{key='arnone', 		name='Map Fills Window'},
		},
		OnChange = function(self)
			local arwindow = self.value == 'arwindow'
			window_minimap.fixedRatio = arwindow
			if arwindow then 
				local w,h = AdjustToMapAspectRatio(328,308+iconsize)
				window_minimap:Resize(w,h,false,false)
			end 
			
		end,
		path = minimap_path,
	},
	--[[
	simpleMinimapColors = {
		name = 'Simplified Minimap Colors',
		type = 'bool',
		desc = 'Show minimap blips as green for you, teal for allies and red for enemies (only minimap will use this simple color scheme).', 
		springsetting = 'SimpleMiniMapColors',
		OnChange = function(self) Spring.SendCommands{"minimap simplecolors " .. (self.value and 1 or 0) } end,
	},
	--]]
	
	initialSensorState = {
		name = "Initial LOS state",
		desc = "Game starts with LOS enabled",
		type = 'bool',
		value = true,
	},
	
	lblViews = { type = 'label', name = 'Views', },
	
	--[[ this option was secretly removed
	viewstandard = {
		name = 'Clear map drawings',
		type = 'button',
		action = 'showstandard',
	},
	--]]
	clearmapmarks = {
		name = 'Clear map drawings',
		type = 'button',
		action = 'clearmapmarks',
	},
	viewheightmap = {
		name = 'Toggle Height Map',
		type = 'button',
		action = 'showelevation',
	},
	viewblockmap = {
		name = 'Toggle Pathing Map',
		desc = 'Select unit then click this to see where it can go.',
		type = 'button',
		action = 'showpathtraversability',
	},
	
	lastmsgpos = {
		name = 'Last Message Position',
		type = 'button',
		action = 'lastmsgpos',
	},
	
	lblLos = { type = 'label', name = 'Line of Sight', },
	
	viewfow = {
		name = 'Toggle Fog of War View',
		type = 'button',
		action = 'togglelos',
	},
	
	radar_view_colors_label1 = { type = 'label', name = 'Radar View Colors', path = radar_path,},
	radar_view_colors_label2 = { type = 'label', name = '* Note: These colors are additive.', path = radar_path,},
	
	radar_fog_color = {
		name = "Fog Color",
		type = "colors",
		value = { 0.4, 0.4, 0.4, 1},
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	radar_los_color = {
		name = "LOS Color",
		type = "colors",
		value = { 0.15, 0.15, 0.15, 1},
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	radar_radar_color = {
		name = "Radar Color",
		type = "colors",
		value = { 0, 0, 1, 1},
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	radar_jammer_color = {
		name = "Jammer Color",
		type = "colors",
		value = { 0.1, 0, 0, 1},
		OnChange = function() updateRadarColors() end,
		path = radar_path,
	},
	
	radar_preset_blue_line = {
		name = 'Blue Outline Radar (default)',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.4, 0.4, 0.4, 1}
			options.radar_los_color.value = { 0.15, 0.15, 0.15, 1}
			options.radar_radar_color.value = { 0, 0, 1, 1}
			options.radar_jammer_color.value = { 0.1, 0, 0, 1}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	radar_preset_blue_line_dark_fog = {
		name = 'Blue Outline Radar with dark fog',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.05, 0.05, 0.05, 1}
			options.radar_los_color.value = { 0.5, 0.5, 0.5, 1}
			options.radar_radar_color.value = { 0, 0, 1, 1}
			options.radar_jammer_color.value = { 0.1, 0, 0, 1}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	radar_preset_green = {
		name = 'Green Area Radar',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.25, 0.2, 0.25, 0}
			options.radar_los_color.value = { 0.2, 0.13, 0.2, 0}
			options.radar_radar_color.value = { 0, 0.17, 0, 0}
			options.radar_jammer_color.value = { 0.18, 0, 0, 0}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	radar_preset_only_los = {
		name = 'Only LOS',
		type = 'button',
		OnChange = function()
			options.radar_fog_color.value = { 0.40, 0.40, 0.40, 0}
			options.radar_los_color.value = { 0.15, 0.15, 0.15, 0}
			options.radar_radar_color.value = { 0, 0, 0, 0}
			options.radar_jammer_color.value = { 0, 0, 0, 0}
			updateRadarColors()
		end,
		path = radar_path,
	},
	
	hidebuttons = {
		name = 'Hide Minimap Buttons',
		type = 'bool',
		advanced = true,
		OnChange= function(self) iconsize = self.value and 0 or 20; MakeMinimapWindow() end,
		value = false,
		path = minimap_path,
	},
	opacity = {
		name = "Opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			if self.value == 0 then
				bgColor_panel = {nil,nil,nil,1}
			else
				bgColor_panel = {nil,nil,nil,0}
			end
			MakeMinimapWindow()
			
			window_minimap:Invalidate()
		end,
		path = minimap_path,
	},

}

function updateRadarColors()
	local fog = options.radar_fog_color.value
	local los = options.radar_los_color.value
	local radar = options.radar_radar_color.value
	local jam = options.radar_jammer_color.value
	Spring.SetLosViewColors(
		{ fog[1], los[1], radar[1], jam[1]},
		{ fog[2], los[2], radar[2], jam[2]}, 
		{ fog[3], los[3], radar[3], jam[3]} 
	)
end

function setSensorState(newState)
	local losEnabled = Spring.GetMapDrawMode() == "los"
	if losEnabled ~= newState then
		Spring.SendCommands('togglelos')
	end
end

function widget:Update() --Note: these run-once codes is put here (instead of in Initialize) because we are waiting for epicMenu to initialize the "options" value first.
	setSensorState(options.initialSensorState.value)
	updateRadarColors()
	widgetHandler:RemoveCallIn("Update") -- remove update call-in since it only need to run once. ref: gui_ally_cursors.lua by jK
end

local function MakeMinimapButton(file, pos, params)
	local option = params.option
	local name, desc, action, hotkey
	if option then
		name = options[option].name
		desc = options[option].desc and (' (' .. options[option].desc .. ')') or ''
		action = WG.crude.GetActionName(options_path, options[option])
	end
	name = name or params.name or ""
	desc = desc or params.desc or ""
	action = action or params.action
	hotkey = WG.crude.GetHotkey(action)
	
	if hotkey ~= '' then
		hotkey = ' (\255\0\255\0' .. hotkey:upper() .. '\008)'
	end
		
	return Chili.Button:New{ 
		height=iconsize, width=iconsize, 
--		file=file,
		caption="",
		margin={0,0,0,0},
		padding={4,3,2,2},
		bottom=iconsize*0.3, 
		right=iconsize*pos+5, 
		
		tooltip = (name .. desc .. hotkey ),
		
		--OnClick={ function(self) options[option].OnChange() end }, 
		OnClick={ function(self)
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if meta then
				WG.crude.OpenPath(options_path) --click + space will shortcut to option-menu
				WG.crude.ShowMenu() --make epic Chili menu appear.
				return true
			end
			Spring.SendCommands( action )
		end },
		children={
			Chili.Image:New{
				file=file,
				width="100%";
				height="100%";
				x="0%";
				y="0%";
			}
		},
	}
end

MakeMinimapWindow = function()
	if (window_minimap) then
		window_minimap:Dispose()
	end
	
	--init = true
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	--local w,h = screenWidth*0.32,screenHeight*0.4+iconsize
	local w,h = 328,308+iconsize
	if (options.use_map_ratio.value == 'arwindow') then
		w,h = AdjustToMapAspectRatio(w,h)
	end
	
	if h > 0 and w > 0 and screenHeight > 0 and screenWidth > 0 then
		if w/h > screenWidth/screenHeight then
			screenHeight = h*screenWidth/w
		else
			screenWidth = w*screenHeight/h
		end
	end
	
	map_panel = Chili.Panel:New {bottom = (iconsize*1.3), x = 0, y = 0, right = 0,
		margin={0,0,0,0},
		padding = {8,5,8,8},
		backgroundColor = bgColor_panel
		}
	window_minimap = Chili.Window:New{  
		dockable = true,
		name = "Minimap",
		x = 0,  
		y = 0,
		color = {nil, nil, nil, options.opacity.value},
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		width  = w,
		height = h,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		resizable = true,
	    tweakResizable   = true,
		minimizable = true,
		fixedRatio = options.use_map_ratio.value == 'arwindow',
		dragUseGrip = false,
		minWidth = iconsize*10,
		maxWidth = screenWidth*0.8,
		maxHeight = screenHeight*0.8,
		children = {
			
--			Chili.Panel:New {bottom = (iconsize), x = 0, y = 0, right = 0, margin={0,0,0,0}, padding = {0,0,0,0}, skinName="DarkGlass"},			
			map_panel,
			
			MakeMinimapButton( 'LuaUI/images/Crystal_Clear_action_flag.png', 1, {option = 'lastmsgpos'} ),
			--MakeMinimapButton( 'LuaUI/images/map/standard.png', 2.5, option = {'viewstandard'} ),
			MakeMinimapButton( 'LuaUI/images/drawingcursors/eraser.png', 2.5, {option = 'clearmapmarks'} ),
			MakeMinimapButton( 'LuaUI/images/map/heightmap.png', 3.5, {option = 'viewheightmap'} ),
			MakeMinimapButton( 'LuaUI/images/map/blockmap.png', 4.5, {option = 'viewblockmap'} ),
			MakeMinimapButton( 'LuaUI/images/map/metalmap.png', 5.5, {name = "Toggle Eco Display", action = 'showeco', desc = " (show metal, geo spots and pylon fields)"}),	-- handled differently because command is registered in another widget
			MakeMinimapButton( 'LuaUI/images/map/fow.png', 7, {option = 'viewfow'} ),
			
			Chili.Button:New{ 
				height=iconsize, width=iconsize, 
				caption="",
				margin={0,0,0,0},
				padding={4,3,2,2},
				bottom=iconsize*0.3, 
				right=iconsize*8.5, 
				
				tooltip = "Toggle simplified teamcolours",
				
				--OnClick={ function(self) options[option].OnChange() end }, 
				OnClick = {toggleTeamColors},
				children={
					Chili.Image:New{
						file='LuaUI/images/map/minimap_colors_simple.png',
						width="100%";
						height="100%";
						x="0%";
						y="0%";
					}
				},
			},
		},
	}
end
function widget:MousePress(x, y, button)
	if not Spring.IsAboveMiniMap(x, y) then
		return false
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if not meta then  --//skip epicMenu when user didn't press the Spacebar
		return false 
	end
	if Spring.GetActiveCommand() == 0 then --//activate epicMenu when user didn't have active command & Spacebar+click on the minimap
		WG.crude.OpenPath(minimap_path) --click + space will shortcut to option-menu
		WG.crude.ShowMenu() --make epic Chili menu appear.
		return true
	else --//skip epicMenu when user have active command. User might be trying to queue/insert command using the minimap.
		return false
	end
end

--[[function widget:Update(dt) 
	local mode = Spring.GetCameraState()["mode"]
	if mode == 7 and not tabbedMode then
		tabbedMode = true
		Chili.Screen0:RemoveChild(window_minimap)
	end
	if mode ~= 7 and tabbedMode then
		Chili.Screen0:AddChild(window_minimap)
		tabbedMode = false
	end
end
--]]

 --// similar properties to "widget:Update(dt)" above but update less often.
function widget:KeyRelease(key, mods, label, unicode)
	if key == 0x009 then --// "0x009" is equal to "tab". Reference: uikeys.txt
		local mode = Spring.GetCameraState()["mode"]
		if mode == 7 and not tabbedMode then
			Chili.Screen0:RemoveChild(window_minimap)
			tabbedMode = true
		end
		if mode ~= 7 and tabbedMode then
			Chili.Screen0:AddChild(window_minimap)
			tabbedMode = false
		end
	end
end

function widget:Initialize()
	if (Spring.GetMiniMapDualScreen()) then
		Spring.Echo("ChiliMinimap: auto disabled (DualScreen is enabled).")
		widgetHandler:RemoveWidget()
		return
	end

	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	
	Chili = WG.Chili
	
	MakeMinimapWindow()
	
	gl.SlaveMiniMap(true)
end

function widget:Shutdown()
	--// reset engine default minimap rendering
	gl.SlaveMiniMap(false)
	Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))

	--// free the chili window
	if (window_minimap) then
		window_minimap:Dispose()
	end
end 


local lx, ly, lw, lh

function widget:DrawScreen() 
	if (window_minimap.hidden) then 
		gl.ConfigMiniMap(0,0,0,0) --// a phantom map still clickable if this is not present.
		lx = 0
		ly = 0
		lh = 0
		lw = 0
		return 
	end
	local cx,cy,cw,ch = Chili.unpack4(map_panel.clientArea)
	
	if (options.use_map_ratio.value == 'armap') then
		cx,cy,cw,ch = AdjustMapAspectRatioToWindow(cx,cy,cw,ch)
	end
	
	--if (lw ~= window_minimap.width or lh ~= window_minimap.height or lx ~= window_minimap.x or ly ~= window_minimap.y) or init then
	if (lw ~= cx or lh ~= ch or lx ~= cx or ly ~= cy) then
		--[[
		if init then
			window_minimap:Update() --required otherwise size stackpanel is calculated wrong when first loaded
			init = false
		end
		--]]
			
		lx = cx
		ly = cy
		lh = ch
		lw = cw
		
		cx,cy = window_minimap:LocalToScreen(cx,cy)
		local vsx,vsy = gl.GetViewSizes()
		gl.ConfigMiniMap(cx,vsy-ch-cy,cw,ch)

		
	end

	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.MatrixMode(GL.PROJECTION)
	gl.PushMatrix()
	gl.MatrixMode(GL.MODELVIEW)
	gl.PushMatrix()

	glDrawMiniMap()

	gl.MatrixMode(GL.PROJECTION)
	gl.PopMatrix()
	gl.MatrixMode(GL.MODELVIEW)
	gl.PopMatrix()
	gl.PopAttrib()
end 

