function widget:GetInfo()
  return {
    name      = "Chili Minimap",
    desc      = "v0.862 Chili Minimap",
    author    = "Licho, tweaked by CarRepairer",
    date      = "@2010",
    license   = "GNU GPL, v2 or later",
    layer     = -100000,
    experimental = false,
    enabled   = true --  loaded by default?
  }
end


local window_minimap
local Chili
local glDrawMiniMap = gl.DrawMiniMap
local glResetState = gl.ResetState
local glResetMatrices = gl.ResetMatrices

local iconsize = 20

local tabbedMode = false

local function AdjustToMapAspectRatio(w,h)
	if (Game.mapX > Game.mapY) then
		return w, w*Game.mapY/Game.mapX+iconsize
	end
	return h*Game.mapX/Game.mapY, h+iconsize
end

local function MakeMinimapWindow()
end

options_path = 'Game'
options_order = { 'use_map_ratio', 'hidebuttons', 'simplecolors', 'lblViews', 'viewstandard', 'viewheightmap', 'viewblockmap', 'viewmetalmap', 'lblLos', 'viewfow', 'viewradar', }
options = {
	
	use_map_ratio = {
		name = 'Minimap Keeps Aspect Ratio',
		type = 'bool',
		value = true,
		path = 'Settings/Interface',
		advanced = true,
		OnChange = function(self)
			if (self.value) then 
				local w,h = AdjustToMapAspectRatio(300, 200)
				window_minimap:Resize(w,h,false,false)
			end 
			window_minimap.fixedRatio = self.value;			
		end,
	},
	simplecolors = {
		name = 'Simple Radar Blip Colors',
		type = 'bool',
		desc = 'Show radar blips as green for yours, teal for allies and red for enemies.', 
		springsetting = 'SimpleMiniMapColors',
		OnChange = function(self) Spring.SendCommands{"minimap simplecolors " .. (self.value and 1 or 0) } end,
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
		action = 'showpathmap',
	},
	viewmetalmap = {
		name = 'Toggle Metal Map',
		desc = 'Shows concentration of metal',
		type = 'button',
		action = 'showmetalmap',
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
	
	hidebuttons = {
		name = 'Hide Minimap Buttons',
		type = 'bool',
		advanced = true,
		path = 'Settings/Interface',
		OnChange= function(self) iconsize = self.value and 0 or 20; MakeMinimapWindow() end
	},
	
}
			
local function MakeMinimapButton(file, pos, option )
	return Chili.Button:New{ 
		height=iconsize, width=iconsize, 
--		file=file,
		caption="",
		margin={0,0,0,0},
		padding={4,3,2,2},
		bottom=0, 
		right=iconsize*pos+5, 
		
		tooltip = (
			options[option].name
				.. ( options[option].desc 
					and (' (' .. options[option].desc .. ')') 
					or '' )
				.. ' (\255\0\255\0' .. WG.crude.GetHotkey(options[option].action) .. '\008)' 
			),
		
		
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
	
	local w,h = screenWidth*0.32,screenHeight*0.4+iconsize
	if (options.use_map_ratio.value) then
		w,h = AdjustToMapAspectRatio(w,h)
	end
	
	window_minimap = Chili.Window:New{  
		dockable = true,
		name = "minimap",
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
		fixedRatio = options.use_map_ratio.value,
		dragUseGrip = false,
		minimumSize = {iconsize*9,50},
		children = {
			
--			Chili.Panel:New {bottom = (iconsize), x = 0, y = 0, right = 0, margin={0,0,0,0}, padding = {0,0,0,0}, skinName="DarkGlass"},			
			Chili.Panel:New {bottom = (iconsize), x = 0, y = 0, right = 0, margin={0,0,0,0}, padding = {0,0,0,0}},
			
			MakeMinimapButton( 'LuaUI/images/map/standard.png', 1, 'viewstandard' ),
			MakeMinimapButton( 'LuaUI/images/map/heightmap.png', 2, 'viewheightmap' ),
			MakeMinimapButton( 'LuaUI/images/map/blockmap.png', 3, 'viewblockmap' ),
			MakeMinimapButton( 'LuaUI/images/map/metalmap.png', 4, 'viewmetalmap' ),
			MakeMinimapButton( 'LuaUI/images/map/radar.png', 6, 'viewradar' ),
			MakeMinimapButton( 'LuaUI/images/map/fow.png', 7, 'viewfow' ),
			
			
		},
	}
end

function widget:Update(dt)
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
