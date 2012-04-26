function widget:GetInfo()
  return {
    name      = "Chili Minimap",
    desc      = "v0.883 Chili Minimap",
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
local Chili
local glDrawMiniMap = gl.DrawMiniMap
local glResetState = gl.ResetState
local glResetMatrices = gl.ResetMatrices

local iconsize = 20

local recentlyInitialized = false
local tabbedMode = false

local function toggleTeamColors() 
	if WG.localTeamColorToggle then
		WG.localTeamColorToggle() 
	end
end 


local function AdjustToMapAspectRatio(w,h)
	if (Game.mapX > Game.mapY) then
		return w, w*Game.mapY/Game.mapX+iconsize
	end
	return h*Game.mapX/Game.mapY, h+iconsize
end

local function MakeMinimapWindow()
end

options_path = 'Settings/View/Minimap'
options_order = { 'use_map_ratio', 'hidebuttons', 'simpleMinimapColors', 'simpleteamcolors', 'startwithlos', 'startwithradar', 'lblViews', 'viewstandard', 'viewheightmap', 'viewblockmap', 'viewmetalmap', 'lblLos', 'viewfow', 'viewradar', 'simplecolors' }
options = {
	
	use_map_ratio = {
		name = 'Minimap Keeps Aspect Ratio',
		type = 'bool',
		value = true,
		advanced = true,
		OnChange = function(self)
			if (self.value) then 
				local w,h = AdjustToMapAspectRatio(300, 200)
				window_minimap:Resize(w,h,false,false)
			end 
			window_minimap.fixedRatio = self.value;			
		end,
	},
	simpleMinimapColors = {
		name = 'Simplified Minimap Colors',
		type = 'bool',
		desc = 'Show units in minimap as green for you, teal for allies and red for enemies (will use this color scheme only for units shown in minimap).', 
		springsetting = 'SimpleMiniMapColors',
		OnChange = function(self) Spring.SendCommands{"minimap simplecolors " .. (self.value and 1 or 0) } end,
	},
	simpleteamcolors = {
		name = 'Simplified Team Colors',
		type = 'bool',
		desc = 'Use teal as your color, blue for allies and red for enemies for all view-mode (will use this color scheme for icons in zoom-out mode, player name in player list, and units shown in minimap).', 
		value = false,
		OnChange = function()
			if (options.simpleteamcolors.value and not WG.usingSimpleTeamColors) or (not options.simpleteamcolors.value and WG.usingSimpleTeamColors) then --//change the team color scheme when the saved scheme didn't match the current scheme.
				toggleTeamColors()
			end
		end,
	},
	
	startwithlos = {
		name = 'Start with LOS view',
		type = 'bool',
		desc = 'Enables LOS view at game start.', 
		value = false,
	},
	
	startwithradar = {
		name = 'Start with Radar view',
		type = 'bool',
		desc = 'Enables Radar view at game start.', 
		value = false,
	},
	
	lblViews = { type = 'label', name = 'Views', },
	
	viewstandard = {
		name = 'Normal View',
		type = 'button',
		action = 'showstandard',
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
	viewmetalmap = {
		name = 'Toggle Metal Map',
		desc = 'Shows concentration of metal',
		type = 'button',
		action = 'showmetalmap',
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
	viewradar = {
		name = 'Toggle Radar & Jammer View',
		desc = 'Only shows when Fog of War is enabled',
		type = 'button',
		action = 'toggleradarandjammer',
	},
	
	simplecolors = {
		name = 'Toggle Simple Teamcolors',
		desc = 'Toggle simples teamcolors, allies blue, enemies red and self teal.',
		type = 'button',
		OnChange = toggleTeamColors,
	},
	
	hidebuttons = {
		name = 'Hide Minimap Buttons',
		type = 'bool',
		advanced = true,
		OnChange= function(self) iconsize = self.value and 0 or 20; MakeMinimapWindow() end,
		value = false,
	},
	
}

local function MakeMinimapButton(file, pos, option )
	local desc = options[option].desc and (' (' .. options[option].desc .. ')') or ''
	local hotkey = WG.crude.GetHotkey(options[option].action)
	if hotkey ~= '' then
		hotkey = ' (\255\0\255\0' .. hotkey:upper() .. '\008)'
	end
		
	return Chili.Button:New{ 
		height=iconsize, width=iconsize, 
--		file=file,
		caption="",
		margin={0,0,0,0},
		padding={4,3,2,2},
		bottom=0, 
		right=iconsize*pos+5, 
		
		tooltip = ( options[option].name .. desc .. hotkey ),
		
		--OnClick={ function(self) options[option].OnChange() end }, 
		OnClick={ function(self) Spring.SendCommands( options[option].action ); end },
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
	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	--local w,h = screenWidth*0.32,screenHeight*0.4+iconsize
	local w,h = 328,308+iconsize
	if (options.use_map_ratio.value) then
		w,h = AdjustToMapAspectRatio(w,h)
	end
	
	window_minimap = Chili.Window:New{  
		dockable = true,
		name = "Minimap",
		x = 0,  
		y = 0,
		color = {0,0,0,0},
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		width  = w,
		height = h,
		parent = Chili.Screen0,
		draggable = false,
		tweakDraggable = true,
		resizable = true,
		minimizable = true,
		fixedRatio = options.use_map_ratio.value,
		dragUseGrip = false,
		minWidth = iconsize*10,
		children = {
			
--			Chili.Panel:New {bottom = (iconsize), x = 0, y = 0, right = 0, margin={0,0,0,0}, padding = {0,0,0,0}, skinName="DarkGlass"},			
			Chili.Panel:New {bottom = (iconsize), x = 0, y = 0, right = 0, margin={0,0,0,0}, padding = {0,0,0,0}},
			
			MakeMinimapButton( 'LuaUI/images/Crystal_Clear_action_flag.png', 1, 'lastmsgpos' ),
			MakeMinimapButton( 'LuaUI/images/map/standard.png', 2.5, 'viewstandard' ),
			MakeMinimapButton( 'LuaUI/images/map/heightmap.png', 3.5, 'viewheightmap' ),
			MakeMinimapButton( 'LuaUI/images/map/blockmap.png', 4.5, 'viewblockmap' ),
			MakeMinimapButton( 'LuaUI/images/map/metalmap.png', 5.5, 'viewmetalmap' ),
			MakeMinimapButton( 'LuaUI/images/map/radar.png', 7, 'viewradar' ),
			MakeMinimapButton( 'LuaUI/images/map/fow.png', 8, 'viewfow' ),
			
			Chili.Button:New{ 
				height=iconsize, width=iconsize, 
				caption="",
				margin={0,0,0,0},
				padding={4,3,2,2},
				bottom=0, 
				right=iconsize*9+5, 
				
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
		WG.crude.OpenPath(options_path) --click + space will shortcut to option-menu
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

	recentlyInitialized = true
	
	Chili = WG.Chili
	
	MakeMinimapWindow()
	
	gl.SlaveMiniMap(true)
end

function widget:Update()
	if recentlyInitialized then
		options.simpleteamcolors.OnChange(options.simpleteamcolors)
		if options.startwithlos.value then
			Spring.SendCommands('togglelos')
		end
		if options.startwithradar.value then
			Spring.SendCommands('toggleradarandjammer')
		end
		recentlyInitialized = false
		widgetHandler:RemoveCallIn("Update") --ref: gui_ally_cursors.lua by jK
	end
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
	if (lw ~= window_minimap.width or lh ~= window_minimap.height or lx ~= window_minimap.x or ly ~= window_minimap.y) then 
		local cx,cy,cw,ch = Chili.unpack4(window_minimap.clientArea)
		ch = ch-iconsize	
		cx = cx + 8
		cy = cy + 4
		cw = cw - 16 
		ch = ch - 12
		--window_minimap.x, window_minimap.y, window_minimap.width, window_minimap.height
		--Chili.unpack4(window_minimap.clientArea)
		cx,cy = window_minimap:LocalToScreen(cx,cy)
		local vsx,vsy = gl.GetViewSizes()
		gl.ConfigMiniMap(cx,vsy-ch-cy,cw,ch)
		lx = window_minimap.x
		ly = window_minimap.y
		lh = window_minimap.height
		lw = window_minimap.width
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

