function widget:GetInfo()
  return {
    name      = "Chili Minimap",
    desc      = "v0.895 Chili Minimap",
    author    = "Licho, CarRepairer",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = -100000,
    enabled   = true,
  }
end


--// gl const

local GL_DEPTH_BITS = 0x0D56

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0
local GL_COLOR_ATTACHMENT1_EXT = 0x8CE1
local GL_COLOR_ATTACHMENT2_EXT = 0x8CE2
local GL_COLOR_ATTACHMENT3_EXT = 0x8CE3

--// gl vars
 
local fbo
local offscreentex

local fadeShader
local alphaLoc
local boundsLoc

--//

local window
local fakewindow
local map_panel 
local buttons_panel
local Chili
local glDrawMiniMap = gl.DrawMiniMap
local glResetState = gl.ResetState
local glResetMatrices = gl.ResetMatrices
local echo = Spring.Echo

local iconsize = 20
local bgColor_panel = {nil, nil, nil, 1}
local final_opacity = 0
local last_alpha = 1 --Last set alpha value for the actual clickable minimap image

local tabbedMode = false
--local init = true

local function toggleTeamColors()
	if WG.LocalColor and WG.LocalColor.localTeamColorToggle then
		WG.LocalColor.localTeamColorToggle()
	else
		Spring.SendCommands("luaui enablewidget Local Team Colors")
	end
end 

local mapRatio = Game.mapX/Game.mapY
local mapIsWider = mapRatio > 1
local function AdjustToMapAspectRatio(w, h, buttonRight)
	local wPad = 16
	local hPad = 16
	if buttonRight then
		wPad = wPad + iconsize*1.3
	else
		hPad = hPad + iconsize*1.3
	end
	w = w - wPad
	h = h - hPad
	if w/h < mapRatio then
		return w + wPad, w/mapRatio + hPad
	end
	return h*mapRatio + wPad, h + hPad
end

local function AdjustMapAspectRatioToWindow(x,y,w,h)
	local newW, newH = w,h
	local newX, newY = x,y
	if w/h > mapRatio then
		newW = mapRatio*h
		newX = x + (w-newW)/2
	else
		newH = w/mapRatio
		newY = y + (h-newH)/2
	end
	return newX, newY, newW, newH
end

local function MakeMinimapWindow()
end

options_path = 'Settings/Interface/Map'
local minimap_path = 'Settings/HUD Panels/Minimap'
--local radar_path = 'Settings/Interface/Map/Radar View Colors'
local radar_path = 'Settings/Interface/Map'
options_order = { 'use_map_ratio', 'opacity', 'alwaysResizable', 'buttonsOnRight', 'hidebuttons', 'initialSensorState', 'start_with_showeco','lastmsgpos', 'viewstandard', 'clearmapmarks',  'minimizable',
'lblViews', 'viewheightmap', 'viewblockmap', 'lblLos', 'viewfow',
'radar_view_colors_label1', 'radar_view_colors_label2', 'radar_fog_brightness', --'radar_fog_color', 'radar_los_color', 
'radar_radar_color', 'radar_jammer_color', 
'radar_preset_blue_line', 'radar_preset_blue_line_dark_fog', 'radar_preset_green', 'radar_preset_only_los', 'leftClickOnMinimap', 'fadeMinimapOnZoomOut'}
options = {
	start_with_showeco = {
		name = "Initial Showeco state",
		desc = "Game starts with Showeco enabled",
		type = 'bool',
		value = false,
		OnChange = function(self)
			if (self.value) then
				WG.showeco = self.value
			end
		end,
	},
	use_map_ratio = {
		name = 'Keep Aspect Ratio',
		type = 'radioButton',
		value = 'arwindow',
		items = {
			{key = 'arwindow', 	name='Aspect Ratio Window'},
			{key ='armap', 		name='Aspect Ratio Map'},
			{key ='arnone', 		name='Map Fills Window'},
		},
		OnChange = function(self)
			local arwindow = self.value == 'arwindow'
			window.fixedRatio = arwindow
			if arwindow then
				local maxSize = math.max(window.width, window.height)
				local w,h = AdjustToMapAspectRatio(maxSize, maxSize, options.buttonsOnRight.value)
				window:Resize(w,h,false,false)
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
	
	buttonsOnRight = {
		name = 'Map buttons on the right',
		type = 'bool',
		value = false,
		OnChange = function(self) MakeMinimapWindow() end,
		path = minimap_path,
	},
	alwaysResizable = {
		name = 'Resizable',
		type = 'bool',
		value = false,
		OnChange= function(self) MakeMinimapWindow() end,
		path = minimap_path,
	},
	minimizable = {
		name = 'Minimizable',
		type = 'bool',
		value = false,
		OnChange= function(self) MakeMinimapWindow() end,
		path = minimap_path,
	},
	
	-- [[ this option was secretly removed
	viewstandard = {
		name = 'View standard map',
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
	
	radar_fog_brightness = {
		name = "Fog Brightness",
		type = "number",
		value = 0.4, min = 0, max = 1, step = 0.01,
		OnChange =  function() updateRadarColors() end,
		path = radar_path,
	},
	-- radar_los_color = {
	-- 	name = "LOS Color",
	-- 	type = "colors",
	-- 	value = 0.25, min = 0, max = 1,
	-- 	OnChange =  function() updateRadarColors() end,
	-- 	path = radar_path,
	-- },
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
	
	-- NB: The sum of fog color and los color on each channel needs to be 0.5 in order for the area in los to be the same colour as if fog of war was off (i.e. by hitting 'L')
	radar_preset_blue_line = {
		name = 'Blue Outline Radar (default)',
		type = 'button',
		OnChange = function()
			-- options.radar_fog_color.value = { 0.25, 0.25, 0.25, 1}
			-- options.radar_los_color.value = { 0.25, 0.25, 0.25, 1}
			options.radar_fog_brightness.value = 0.5
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
			-- options.radar_fog_color.value = { 0.09, 0.09, 0.09, 1}
			-- options.radar_los_color.value = { 0.41, 0.41, 0.41, 1}
			options.radar_fog_brightness.value = 0.18
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
			-- options.radar_fog_color.value = { 0.25, 0.25, 0.25, 1}
			-- options.radar_los_color.value = { 0.25, 0.25, 0.25, 1}
			options.radar_fog_brightness.value = 0.5
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
			-- options.radar_fog_color.value = { 0.25, 0.25, 0.25, 1}
			-- options.radar_los_color.value = { 0.25, 0.25, 0.25, 1}
			options.radar_fog_brightness.value = 0.5
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
		OnChange= function(self) 
			iconsize = self.value and 0 or 20 
			MakeMinimapWindow() 
		end,
		value = false,
		path = minimap_path,
	},
	opacity = {
		name = "Opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			if self.value == 0 then
				bgColor_panel = {nil, nil, nil, 1}
			else
				bgColor_panel = {nil, nil, nil, 0}
			end
			final_opacity = self.value * last_alpha
			last_alpha = 2 --invalidate last_alpha so it needs to be recomputed
			MakeMinimapWindow()
			window:Invalidate()
		end,
		path = minimap_path,
	},
	leftClickOnMinimap = {
		name = 'Left Click Behaviour',
		type = 'radioButton',
		value = 'unitselection',
		items={
			{key='unitselection', name='Unit Selection'},
			{key='situational', name='Context Dependant'},
			{key='camera', name='Camera Movement'},
		},
		path = minimap_path,
	},	
	fadeMinimapOnZoomOut = {
		name = "Minimap fading when zoomed out",
		type = 'radioButton',
		value = 'none',
		items={
			{key='full', name='Full'},
			{key='partial', name='Semi-transparent'},
			{key='none', name='None'},
		},
		OnChange = function(self)
			last_alpha = 2 --invalidate last_alpha so it needs to be recomputed, for the background opacity
			end,
		path = minimap_path,
	},
}

function WG.Minimap_SetOptions(aspect, opacity, resizable, buttonRight, minimizable)
	if aspect == 'arwindow' or aspect == 'armap' or aspect == 'arnone' then 
		options.use_map_ratio.value = aspect
	end
	options.opacity.value = opacity
	options.alwaysResizable.value = resizable
	options.buttonsOnRight.value = buttonRight
	options.minimizable.value = minimizable
	
	options.opacity.OnChange(options.opacity)
	options.use_map_ratio.OnChange(options.use_map_ratio)
	options.alwaysResizable.OnChange(options.alwaysResizable)
end

function updateRadarColors()
	local losViewOffBrightness = 0.5

	-- local fog = options.radar_fog_color.value
	-- local los = options.radar_los_color.value
	local fog_value = options.radar_fog_brightness.value * losViewOffBrightness
	local los_value = (losViewOffBrightness - fog_value)
	local fog = {fog_value, fog_value, fog_value, 1}
	local los = {los_value, los_value, los_value, 1}
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

local firstUpdate = true
local updateRunOnceRan = false

function widget:Update() --Note: these run-once codes is put here (instead of in Initialize) because we are waiting for epicMenu to initialize the "options" value first.
	if firstUpdate then
		firstUpdate = false
		return
	end
	if not updateRunOnceRan then
		setSensorState(options.initialSensorState.value)
		updateRadarColors()
		options.use_map_ratio.OnChange(options.use_map_ratio) -- Wait for docking to provide saved window size
		updateRunOnceRan = true
	end

	local cs = Spring.GetCameraState()
	if cs.name == "ov" and not tabbedMode then
		Chili.Screen0:RemoveChild(window)
		tabbedMode = true
	end
	if cs.name ~= "ov" and tabbedMode then
		Chili.Screen0:AddChild(window)
		tabbedMode = false
	end
	-- widgetHandler:RemoveCallIn("Update") -- remove update call-in since it only need to run once. ref: gui_ally_cursors.lua by jK
end

local function MakeMinimapButton(file, params)
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
		caption="",
		margin={0,0,0,0},
		padding={2,2,2,2},
		tooltip = (name .. desc .. hotkey ),
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
		  file and
			Chili.Image:New{
				file=file,
				width="100%";
				height="100%";
				x="0%";
				y="0%";
			} or nil
		},
	}
end

MakeMinimapWindow = function()
	if (window) then
		window:Dispose()
	end
	
	-- Set the size for the default settings.
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local width, height = screenWidth/6, screenWidth/6
	
	if options.buttonsOnRight.value then
		width = width + iconsize
	else
		height = height + iconsize
	end
	
	if height > 0 and width > 0 and screenHeight > 0 and screenWidth > 0 then
		if width/height > screenWidth/screenHeight then
			screenHeight = height*screenWidth/width
		else
			screenWidth = width*screenHeight/height
		end
	end
	
	local map_panel_bottom = iconsize*1.3
	local map_panel_right = 0
	
	local buttons_height = iconsize+3
	local buttons_width = iconsize*10
	if options.buttonsOnRight.value then
		map_panel_bottom = 0
		map_panel_right = iconsize*1.3
		buttons_height = iconsize*10
		buttons_width = iconsize+3
	end
	
	map_panel = Chili.Panel:New {
		x = 0,
		y = 0,
		bottom = map_panel_bottom,
		right = map_panel_right,
		
		margin = {0,0,0,0},
		padding = {8,8,8,8},
		backgroundColor = bgColor_panel
		}
	
	buttons_panel = Chili.StackPanel:New{
		orientation = 'horizontal',
		height=buttons_height,
		width=buttons_width,
		bottom = 5,
		right=5,
		
		padding={1,1,1,1},
		--margin={0,0,0,0},
		itemMargin={0,0,0,0},
		
		autosize = false,
		resizeItems = false,
		autoArrangeH = false,
		autoArrangeV = false,
		centerItems = false,
		
		children = {
			Chili.Button:New{ 
				height=iconsize, width=iconsize, 
				caption="",
				margin={0,0,0,0},
				padding={2,2,2,2},
				tooltip = "Toggle simplified teamcolours",
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
			
			MakeMinimapButton( 'LuaUI/images/map/fow.png', {option = 'viewfow'} ),
			
			Chili.Label:New{ width=iconsize/2, height=iconsize/2, caption='', autosize = false,},
			
			MakeMinimapButton( nil, {option = 'viewstandard'} ),
			MakeMinimapButton( 'LuaUI/images/map/heightmap.png', {option = 'viewheightmap'} ),
			MakeMinimapButton( 'LuaUI/images/map/blockmap.png', {option = 'viewblockmap'} ),
			MakeMinimapButton( 'LuaUI/images/map/metalmap.png', {name = "Toggle Eco Display", action = 'showeco', desc = " (show metal, geo spots and pylon fields)"}),	-- handled differently because command is registered in another widget
			
			Chili.Label:New{ width=iconsize/2, height=iconsize/2, caption='', autosize = false,},
			
			MakeMinimapButton( 'LuaUI/images/drawingcursors/eraser.png', {option = 'clearmapmarks'} ),
			MakeMinimapButton( 'LuaUI/images/Crystal_Clear_action_flag.png', {option = 'lastmsgpos'} ),
		},
	}
	
	window = Chili.Window:New{
		parent = Chili.Screen0,
		name   = 'Minimap Window',
		color = {0, 0, 0, 0},
		padding = {0, 0, 0, 0},
		width = (window and window.width) or width,
		height = (window and window.height) or height,
		x = (window and window.x) or 0,
		y = (window and window.y) or 0,
		dockable = true,
		draggable = false,
		resizable = options.alwaysResizable.value,
		minimizable = options.minimizable.value,
		tweakDraggable = true,
		tweakResizable = true,
		dragUseGrip = false,
		minWidth = 100,
		minHeight = 100,
		maxWidth = screenWidth*0.8,
		maxHeight = screenHeight*0.8,
		fixedRatio = options.use_map_ratio.value == 'arwindow',
	}
	
	options.use_map_ratio.OnChange(options.use_map_ratio)
	
	fakewindow = Chili.Panel:New{
		backgroundColor = {1,1,1, final_opacity},
		parent = window,
		x = 0,
		y = 0,
		width = "100%",
		height = "100%",
		dockable = false;
		draggable = false,
		resizable = false,
		padding = {0, 0, 0, 0},
		children = {
			map_panel,
			buttons_panel,
		},
	}

end

local leftClickDraggingCamera = false

function widget:MousePress(x, y, button)
	if last_alpha < 0.01 then
		return false
	end
	if not Spring.IsAboveMiniMap(x, y) then
		return false
	end
	if Spring.GetActiveCommand() == 0 then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		if meta and not shift then --//activate epicMenu when user didn't have active command & Spacebar+click on the minimap
			WG.crude.OpenPath(minimap_path) --click + space will shortcut to option-menu
			WG.crude.ShowMenu() --make epic Chili menu appear.
			return true
		end
		if (options.leftClickOnMinimap.value ~= 'unitselection' and button == 1) or button == 2 then
			local traceType,traceValue = Spring.TraceScreenRay(x,y,false,true)
			local coord 
			if traceType == "ground" then
				coord = traceValue
			end
			if (options.leftClickOnMinimap.value == 'camera' and button == 1) or button == 2 then
				if traceType == "unit" then
					local x,y,z = Spring.GetUnitPosition(traceValue)
					if x and y and z then
						coord = {x,y,z}
					end
				elseif traceType == "feature" then
					local x,y,z = Spring.GetFeaturePosition(traceValue)
					if x and y and z then
						coord = {x,y,z}
					end
				end
			end
			if coord then
				if (WG.COFC_SetCameraTarget) then
					WG.COFC_SetCameraTarget(coord[1],coord[2],coord[3],0)
				else
			 		Spring.SetCameraTarget(coord[1],coord[2],coord[3],0)
				end
				leftClickDraggingCamera = true
				return true
			end
		end
	end
end

function widget:MouseMove(x, y, dx, dy, button)
	if leftClickDraggingCamera and Spring.IsAboveMiniMap(x, y) then
		local traceType,traceValue = Spring.TraceScreenRay(x,y,true,true)
		local coord 
		if traceType == "ground" then
			coord = traceValue
		end
		if coord then
			if (WG.COFC_SetCameraTarget) then
				WG.COFC_SetCameraTarget(coord[1],coord[2],coord[3],0)
			else
		 		Spring.SetCameraTarget(coord[1],coord[2],coord[3],0)
			end
			leftClickDraggingCamera = true
			return true
		end
	end
end

function widget:MouseRelease(x, y, button)
	leftClickDraggingCamera = false
end

 --// similar properties to "widget:Update(dt)" above but update less often.
-- function widget:KeyRelease(key, mods, label, unicode)
-- 	if key == 0x009 then --// "0x009" is equal to "tab". Reference: uikeys.txt

-- 	end
-- end

local function CleanUpFBO()
  if (gl.DeleteFBO) and fbo ~= nil then
    gl.DeleteFBO(fbo or 0)
    fbo = nil
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

	if (gl.CreateFBO) then
	  fbo = gl.CreateFBO()

		fbo.color0 = nil;

	  gl.DeleteTextureFBO(offscreentex or 0)

		local vsx,vsy = gl.GetViewSizes()
	  if vsx > 0 and vsy > 0 then
		  offscreentex = gl.CreateTexture(vsx,vsy, {
		    border = false,
		    min_filter = GL.LINEAR,
		    mag_filter = GL.LINEAR,
		    wrap_s = GL.CLAMP,
		    wrap_t = GL.CLAMP,
		    fbo = true,
		  })

		  fbo.color0 = offscreentex
		  fbo.drawbuffers = GL_COLOR_ATTACHMENT0_EXT
		end

		if (gl.CreateShader) then
		  fadeShader = gl.CreateShader({
		  	vertex = [[
		  		varying vec2 texCoord;

          void main() {
            texCoord = gl_Vertex.xy * 0.5 + 0.5;
            gl_Position = vec4(gl_Vertex.xyz, 1.0);
          }
		  	]],
		    fragment = [[
		      uniform sampler2D tex0;
		      uniform float alpha;
		      uniform vec4 bounds;
		      uniform vec2 screen;

		      varying vec2 texCoord;

		      const float edgeFadePixels = 16.0;

		      void main(void) {
		        vec4 color = texture2D(tex0, texCoord.st);
		       	//float width = bounds.z;
		       	//float height = bounds.w;
		        float edgeFadeScaledPixels = edgeFadePixels/1080.0 * screen.y;
		       	vec2 edgeFadeBase = vec2(edgeFadeScaledPixels / screen.x, edgeFadeScaledPixels / screen.y);
		       	vec2 edgeFade = vec2((2.0 * bounds.z) / edgeFadeBase.x, (2.0 * bounds.w) / edgeFadeBase.y);
		       	vec2 edgeAlpha = vec2(clamp(1.0 - abs((texCoord.x - bounds.x)/bounds.z - 0.5) * 2.0, 0.0, 1.0/edgeFade.x) * edgeFade.x,
		       												clamp(1.0 - abs((texCoord.y - bounds.y)/bounds.w - 0.5) * 2.0, 0.0, 1.0/edgeFade.y) * edgeFade.y);
		       	float final_alpha = edgeAlpha.x * edgeAlpha.y * alpha;
		        gl_FragColor = vec4(color.rgb, final_alpha);
		      }
		    ]],
		    uniformInt = {
		      tex0 = 0,
		    },
		    uniform = {
		    	alpha = 1,
		    	bounds = 2,
		    	screen = 3,
		  	},
		  })

		  if (fadeShader == nil) then
		    Spring.Log(widget:GetInfo().name, LOG.ERROR, "Minimap widget: fade shader error: "..gl.GetShaderLog())
			  CleanUpFBO()
		  else
			  alphaLoc = gl.GetUniformLocation(fadeShader, 'alpha')
				boundsLoc = gl.GetUniformLocation(fadeShader, 'bounds')
				screenLoc = gl.GetUniformLocation(fadeShader, 'screen')
		  end
		else --Shader Generation impossible, clean up FBO
		  CleanUpFBO()
		end
	end

	gl.SlaveMiniMap(true)
end

function widget:Shutdown()
	--// reset engine default minimap rendering
	gl.SlaveMiniMap(false)
	Spring.SendCommands("minimap geo " .. Spring.GetConfigString("MiniMapGeometry"))

  if (gl.DeleteTextureFBO) then
    gl.DeleteTextureFBO(offscreentex)
  end

  CleanUpFBO()

	--// free the chili window
	if (window) then
		window:Dispose()
	end
end 

local lx, ly, lw, lh, last_window_x, last_window_y

local function DrawMiniMap()
  gl.Clear(GL.COLOR_BUFFER_BIT,0,0,0,0)
  glDrawMiniMap()
end

function widget:DrawScreen() 
	local cs = Spring.GetCameraState()
	if (window.hidden or cs.name == "ov") then 
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
	
	local vsx,vsy = gl.GetViewSizes()
	if (lw ~= cw or lh ~= ch or lx ~= cx or ly ~= cy or last_window_x ~= window.x or last_window_y ~= window.y) then
		lx = cx
		ly = cy
		lh = ch
		lw = cw
		last_window_x = window.x
		last_window_y = window.y
		
		cx,cy = map_panel:LocalToScreen(cx,cy)
		gl.ConfigMiniMap(cx,vsy-ch-cy,cw,ch)
	end

	-- Do this even if the fadeShader can't exist, just so that all hiding code still behaves properly
	local alpha = 1
	local alphaMin = options.fadeMinimapOnZoomOut.value == 'full' and 0.0 or 0.3
	if options.fadeMinimapOnZoomOut.value ~= 'none' then
		if WG.COFC_SkyBufferProportion ~= nil then --if nil, COFC is not enabled
			alpha = 1 - (WG.COFC_SkyBufferProportion)
		else
			local height = cs.py
			if cs.height ~= null then height = cs.height end
			--NB: Value based on engine 98.0.1-403 source for OverheadController's maxHeight member variable calculation.
			local maxHeight = 9.5 * math.max(Game.mapSizeX, Game.mapSizeZ)/Game.squareSize
			if options.fadeMinimapOnZoomOut.value == 'full' then
				alpha = 1 - ((height - (maxHeight * 0.7)) / (maxHeight * 0.3)) -- 0 to 1
			else
				alpha = 1 - (height - (maxHeight * 0.7)) -- 0.3 to 1
			end
		end

		--Guarantees a buffer of 0 alpha near full zoom-out, to help account for the camera following the map's elevation
		if alpha < 1 then alpha = math.min(math.max((alpha - 0.2) / 0.8, alphaMin), 1.0) end 
	end

	if math.abs(last_alpha - alpha) > 0.0001 then
		final_opacity = options.fadeMinimapOnZoomOut.value == 'full' and options.opacity.value * alpha or options.opacity.value
		last_alpha = alpha

		fakewindow.backgroundColor = {1,1,1, final_opacity}
		local final_map_bg_color = options.fadeMinimapOnZoomOut.value == 'full' and bgColor_panel[4]*alpha or bgColor_panel[4]
		map_panel.backgroundColor = {1,1,1, final_map_bg_color}
		if alpha < 0.1 then 
			fakewindow.children = {map_panel} 
		else 
			fakewindow.children = {map_panel, buttons_panel} 
		end 
		fakewindow:Invalidate()
		map_panel:Invalidate()
	end

	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.MatrixMode(GL.PROJECTION)
	gl.PushMatrix()
	gl.MatrixMode(GL.MODELVIEW)
	gl.PushMatrix()

	if fbo ~= nil and fadeShader ~= nil then

		gl.ActiveFBO(fbo, DrawMiniMap)

	  gl.Blending(true)

	  -- gl.Color(1,1,1,alpha)
	  gl.Texture(0, offscreentex)
	  gl.UseShader(fadeShader)
	  gl.Uniform(alphaLoc, alpha)
	  local px, py = window.x + lx, vsy - window.y - ly
	  gl.Uniform(boundsLoc, px/vsx, (py - lh)/vsy, lw/vsx, lh/vsy)
	  gl.Uniform(screenLoc, vsx, vsy)
	  -- Spring.Echo("Bounds: "..(window.x + lx)/vsx..", "..(window.y + ly)/vsy..", "..((window.x + lx) + lw)/vsx..", "..((window.y + ly) + lh)/vsy)
	  gl.TexRect(-1-0.25/vsx,1+0.25/vsy,1+0.25/vsx,-1-0.25/vsy)

	  gl.Texture(0, false)
	  gl.Blending(false)
	  gl.UseShader(0)
	elseif (alpha > 0.01) then
		glDrawMiniMap()
	end

	gl.MatrixMode(GL.PROJECTION)
	gl.PopMatrix()
	gl.MatrixMode(GL.MODELVIEW)
	gl.PopMatrix()
	gl.PopAttrib()
end 

