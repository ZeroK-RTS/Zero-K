--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Combo Overhead/Free Camera (experimental)",
    desc      = "v0.138 Camera featuring 6 actions. Type \255\90\90\255/luaui cofc help\255\255\255\255 for help.",
    author    = "CarRepairer, msafwan",
    date      = "2011-03-16", --2014-Sept-25
    license   = "GNU GPL, v2 or later",
    layer     = 1002,
	handler   = true,
    enabled   = false,
  }
end

include("keysym.h.lua")
include("Widgets/COFCtools/Interpolate.lua")
--Noticeable bugs that is clearly attributable to introduction of Interpolate():
--Transition issues: 
--1) "TAB" Overview have slight jump at finish, reason unknown!
--2) holding "CTRL+Arrow" to rotate have jump when first initiated, reason is because of delay in "repeat" status for KeyPress() (and probably because added drift :))

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local init = true
local trackmode = false --before options
local thirdperson_trackunit = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Camera/Camera Controls'
local cameraFollowPath = 'Settings/Camera/Camera Following'
local minimap_path = 'Settings/HUD Panels/Minimap'
options_order = { 
	'helpwindow', 
	
	'topBottomEdge',

	'leftRightEdge',

	'middleMouseButton',
	
	'lblZoom',
	-- 'zoomintocursor', 
	-- 'zoomoutfromcursor', 
	'zoominfactor', 
	'zoomin',
	'zoomoutfactor',
	'zoomout',
	'invertzoom', 
	'invertalt', 
	'tiltedzoom',
	'zoomouttocenter', 

	'lblRotate',
	'rotfactor',
	'targetmouse', 
	-- 'rotateonedge', 
  'inverttilt',
  'groundrot',
	
	'lblScroll',
	'speedFactor', 
	'speedFactor_k', 
	-- 'edgemove', 
	'invertscroll', 
	'smoothscroll',
	'smoothmeshscroll', 
	
	'lblMisc',
	'smoothness',
	'fov',
	'overviewmode', 
	'overviewset',
	'rotatebackfromov',
	--'restrictangle',
	--'mingrounddist',
	'resetcam',
	'freemode',
	
	--following:
	
	'lblFollowCursor',
	'follow',
	
	'lblFollowUnit',
	'trackmode',
	'persistenttrackmode',
	'thirdpersontrack',

	'lblFollowCursorZoom',
	'followautozoom',
	'followinscrollspeed',
	'followoutscrollspeed',
	'followzoominspeed',
	'followzoomoutspeed',
	'followzoommindist',
	'followzoommaxdist',
	
	'lblMisc2',
	'enableCycleView',
	'groupSelectionTapTimeout',

}

local OverviewAction = function() end
local OverviewSetAction = function() end
local SetFOV = function(fov) end
local SelectNextPlayer = function() end
local SetCenterBounds = function(cs) end

options = {
	
	lblblank1 = {name='', type='label'},
	lblRotate = {name='Rotation Behaviour', type='label'},
	lblScroll = {name='Scroll Behaviour', type='label'},
	lblZoom = {name='Zoom Behaviour', type='label'},
	lblMisc = {name='Misc.', type='label'},
	
	lblFollowCursor = {name='Cursor Following', type='label', path=cameraFollowPath},
	lblFollowCursorZoom = {name='Auto-Zooming', type='label', path=cameraFollowPath},
	lblFollowUnit = {name='Unit Following', type='label', path=cameraFollowPath},
	lblMisc2 = {name='Misc.', type='label', path = cameraFollowPath},

	topBottomEdge = {
		name = 'Top/Bottom Edge Behaviour',
		type = 'radioButton',
		value = 'pan',
		items = {
			{key = 'pan', 			name='Pan'},
			{key = 'orbit', 		name='Rotate World'},
			{key = 'rotate', 		name='Rotate Camera'},
			{key = 'off', 			name='Off'},
		},
	},

	leftRightEdge = {
		name = 'Left/Right Edge Behaviour',
		type = 'radioButton',
		value = 'pan',
		items = {
			{key = 'pan', 			name='Pan'},
			{key = 'orbit', 		name='Rotate World'},
			{key = 'rotate', 		name='Rotate Camera'},
			{key = 'off', 			name='Off'},
		},
	},

	middleMouseButton = {
		name = 'Middle Mouse Button Behaviour',
		type = 'radioButton',
		value = 'pan',
		items = {
			{key = 'pan', 			name='Pan'},
			{key = 'orbit', 		name='Rotate World'},
			{key = 'rotate', 		name='Rotate Camera'},
			{key = 'off', 			name='Off'},
		},
		advanced = true,
	},
	
	
	helpwindow = {
		name = 'COFCam Help',
		type = 'text',
		value = [[
			Complete Overhead/Free Camera has six main actions...
			
			Zoom..... <Mousewheel>
			Tilt World..... <Ctrl> + <Mousewheel>
			Altitude..... <Alt> + <Mousewheel>
			Mouse Scroll..... <Middlebutton-drag>
			Rotate World..... <Ctrl> + <Middlebutton-drag>
			Rotate Camera..... <Alt> + <Middlebutton-drag>
			
			Additional actions:
			Keyboard: <arrow keys> replicate middlebutton drag while <pgup/pgdn> replicate mousewheel. You can use these with ctrl, alt & shift to replicate mouse camera actions.
			Use <Shift> to speed up camera movements.
			Reset Camera..... <Ctrl> + <Alt> + <Middleclick>
		]],
	},
	smoothscroll = {
		name = 'Smooth scrolling',
		desc = 'Use smoothscroll method when mouse scrolling.',
		type = 'bool',
		value = false,
	},
	smoothmeshscroll = {
		name = 'Smooth Mesh Scrolling',
		desc = 'A smoother way to scroll. Applies to all types of mouse/keyboard scrolling.',
		type = 'bool',
		value = true,
	},
	
	targetmouse = {
		name = 'Rotate world origin at cursor',
		desc = 'Rotate world using origin at the cursor rather than the center of screen.',
		type = 'bool',
		value = true,
	},
	-- edgemove = {
	-- 	name = 'Scroll camera at edge',
	-- 	desc = 'Scroll camera when the cursor is at the edge of the screen.',
	-- 	springsetting = 'WindowedEdgeMove',
	-- 	type = 'bool',
	-- 	value = true,
		
	-- },
	speedFactor = {
		name = 'Mouse scroll speed',
		desc = 'This speed applies to scrolling with the middle button.',
		type = 'number',
		min = 10, max = 40,
		value = 25,
	},
	speedFactor_k = {
		name = 'Keyboard/edge scroll speed',
		desc = 'This speed applies to edge scrolling and keyboard keys.',
		type = 'number',
		min = 1, max = 50,
		value = 40,
	},
	zoominfactor = { --should be lower than zoom-out-speed to help user aim tiny units
		name = 'Zoom-in speed',
		type = 'number',
		min = 0.1, max = 1, step = 0.05,
		value = 0.5,
	},
	zoomoutfactor = { --should be higher than zoom-in-speed to help user escape to bigger picture
		name = 'Zoom-out speed',
		type = 'number',
		min = 0.3, max = 1.3, step = 0.05,
		value = 0.8,
	},
	invertzoom = {
		name = 'Invert zoom',
		desc = 'Invert the scroll wheel direction for zooming.',
		type = 'bool',
		value = true,
	},
	invertalt = {
		name = 'Invert altitude',
		desc = 'Invert the scroll wheel direction for altitude.',
		type = 'bool',
		value = false,
	},
  inverttilt = {
		name = 'Invert tilt',
		desc = 'Invert the tilt direction when using ctrl+mousewheel.',
		type = 'bool',
		value = false,
	},
    
	-- zoomoutfromcursor = {
	-- 	name = 'Zoom out from cursor',
	-- 	desc = 'Zoom out from the cursor rather than center of the screen.',
	-- 	type = 'bool',
	-- 	value = false,
	-- },
	-- zoomintocursor = {
	-- 	name = 'Zoom in to cursor',
	-- 	desc = 'Zoom in to the cursor rather than the center of the screen.',
	-- 	type = 'bool',
	-- 	value = true,
	-- },

	zoomin = {
		name = 'Zoom In',
		type = 'radioButton',
		value = 'toCursor',
		items = {
			{key = 'toCursor', 		name='To Cursor'},
			{key = 'toCenter', 		name='To Screen Center'},
		},
	},

	zoomout = {
		name = 'Zoom Out',
		type = 'radioButton',
		value = 'fromCenter',
		items = {
			{key = 'fromCursor', 		name='From Cursor'},
			{key = 'fromCenter', 		name='From Screen Center'},
		},
	},

	zoomouttocenter = {
		name = 'Zoom out to center',
		desc = 'Center the map as you zoom out.',
		type = 'bool',
		value = true,
		OnChange = function(self) 
			local cs = Spring.GetCameraState()
			if cs.rx then
				SetCenterBounds(cs) 
				Spring.SetCameraState(cs, options.smoothness.value) 
			end
		end,
	},
	tiltedzoom = {
		name = 'Tilt camera while zooming',
		desc = 'Have the camera tilt while zooming. Camera faces ground when zoomed out, and looks out nearly parallel to ground when fully zoomed in',
		type = 'bool',
		value = true,
	},

	rotfactor = {
		name = 'Rotation speed',
		type = 'number',
		min = 0.001, max = 0.020, step = 0.001,
		value = 0.005,
	},	
	-- rotateonedge = {
	-- 	name = "Rotate camera at edge",
	-- 	desc = "Rotate camera when the cursor is at the edge of the screen (edge scroll must be off).",
	-- 	type = 'bool',
	-- 	value = false,
	-- },
    
	smoothness = {
		name = 'Smoothness',
		desc = "Controls how smooth the camera moves.",
		type = 'number',
		min = 0.0, max = 0.8, step = 0.1,
		value = 0.2,
	},
	fov = {
		name = 'Field of View (Degrees)',
		--desc = "FOV (25 deg - 100 deg).",
		type = 'number',
		min = 10, max = 100, step = 5,
		value = Spring.GetCameraFOV(),
		springsetting = 'CamFreeFOV', --save stuff in springsetting. reference: epicmenu_conf.lua
		OnChange = function(self) SetFOV(self.value) end
	},
	invertscroll = {
		name = "Invert scrolling direction",
		desc = "Invert scrolling direction (doesn't apply to smoothscroll).",
		type = 'bool',
		value = true,
	},
	restrictangle = {
		name = "Restrict Camera Angle",
		desc = "If disabled you can point the camera upward, but end up with strange camera positioning.",
		type = 'bool',
		advanced = true,
		value = true,
		OnChange = function(self) init = true; end
	},
	freemode = {
		name = "FreeMode (risky)",
		desc = "Be free. Camera movement not bound to map edge. USE AT YOUR OWN RISK!\nTips: press TAB if you get lost.",
		type = 'bool',
		advanced = true,
		value = false,
		OnChange = function(self) init = true; end,
	},
	mingrounddist = {
		name = 'Minimum Ground Distance',
		desc = 'Getting too close to the ground allows strange camera positioning.',
		type = 'number',
		advanced = true,
		min = 0, max = 100, step = 1,
		value = 1,
		OnChange = function(self) init = true; end,
	},
	
	overviewmode = {
		name = "COFC Overview",
		desc = "Go to overview mode, then restore view to cursor position.",
		type = 'button',
		hotkey = {key='tab', mod=''},
		OnChange = function(self) OverviewAction() end,
	},
	overviewset = {
		name = "Set Overview Viewpoint",
		desc = "Save the current view as the new overview mode viewpoint. Use 'Reset Camera' to remove it.",
		type = 'button',
		OnChange = function(self) OverviewSetAction() end,
	},
	rotatebackfromov = {
		name = "Rotate Back From Overview",
		desc = "When returning from overview mode, rotate the camera to its original position (only applies when you have set an overview viewpoint).",
		type = 'bool',
		value = true,
	},
	resetcam = {
		name = "Reset Camera",
		desc = "Reset the camera position and orientation. Map a hotkey or use <Ctrl> + <Alt> + <Middleclick>",
		type = 'button',
        -- OnChange defined later
	},
	groundrot = {
		name = "Rotate When Camera Hits Ground",
		desc = "If world-rotation motion causes the camera to hit the ground, camera-rotation motion takes over. Doesn't apply in Free Mode.",
		type = 'bool',
		value = false,
		advanced = true,
	},
	
	
	
	-- follow cursor
	follow = {
		name = "Follow player's cursor",
		desc = "Follow the cursor of the player you're spectating (needs Ally Cursor widget to be on). Mouse midclick to pause tracking for 4 second.",
		type = 'bool',
		value = false,
		hotkey = {key='l', mod='alt+'},
		path = cameraFollowPath,
		OnChange = function(self) Spring.Echo("COFC: follow cursor " .. (self.value and "active" or "inactive")) end,		
	},
	followautozoom = {
		name = "Auto zoom",
		desc = "Auto zoom in and out while following player's cursor (zoom level will represent player's focus). \n\nDO NOT enable this if you want to control the zoom level yourself.",
		type = 'bool',
		value = false,
		path = cameraFollowPath,
	},
	followinscrollspeed = {
		name = "On Screen Tracking Speed",
		desc = "Tracking speed while cursor is on-screen. \n\nRecommend: Lowest (prevent jerky movement)",
		type = 'number',
		min = 1, max = 14, step = 1,
		mid = (14+1)/2,
		value = 1,
		OnChange = function(self) Spring.Echo("COFC: " ..self.mid*2 - self.value .. " second") end,
		path = cameraFollowPath,
	},	
	followoutscrollspeed = {
		name = "Off Screen Tracking Speed",
		desc = "Tracking speed while cursor is off-screen. \n\nRecommend: Highest (prevent missed action)",
		type = 'number',
		min = 2, max = 15, step = 1,
		mid = (15+2)/2,
		value = 15,
		OnChange = function(self) Spring.Echo("COFC: " ..self.mid*2 - self.value  .. " second") end,
		path = cameraFollowPath,
	},
	followzoommindist = {
		name = "Closest Zoom",
		desc = "The closest zoom. Default: 500",
		type = 'number',
		min = 200, max = 10000, step = 100,
		value = 500,
		OnChange = function(self) Spring.Echo("COFC: " ..self.value .. " elmo") end,
		path = cameraFollowPath,
	},
	followzoommaxdist = {
		name = "Farthest Zoom",
		desc = "The furthest zoom. Default: 2000",
		type = 'number',
		min = 200, max = 10000, step = 100,
		value = 2000,
		OnChange = function(self) Spring.Echo("COFC: " .. self.value .. " elmo") end,
		path = cameraFollowPath,
	},	
	followzoominspeed = {
		name = "Zoom-in Speed",
		desc = "Zoom-in speed when cursor is on-screen. Default: 50%",
		type = 'number',
		min = 0.1, max = 1, step = 0.05,
		value = 0.5,
		OnChange = function(self) Spring.Echo("COFC: " .. self.value*100 .. " percent") end,
		path = cameraFollowPath,
	},
	followzoomoutspeed = {
		name = "Zoom-out Speed",
		desc = "Zoom-out speed when cursor is at screen edge and off-screen. Default: 50%",
		type = 'number',
		min = 0.1, max = 1, step = 0.05,
		value = 0.5,
		OnChange = function(self)Spring.Echo("COFC: " .. self.value*100 .. " percent") end,
		path = cameraFollowPath,
	},
	-- end follow cursor
	
	-- follow unit
	trackmode = {
		name = "Activate Trackmode",
		desc = "Track the selected unit (mouse midclick to exit mode)",
		type = 'button',
        hotkey = {key='t', mod='alt+'},
		path = cameraFollowPath,
		OnChange = function(self) 
			if thirdperson_trackunit then --turn off 3rd person tracking if it is.
				Spring.SendCommands('trackoff')
				Spring.SendCommands('viewfree')
				thirdperson_trackunit = false
			end
			trackmode = true;
			Spring.Echo("COFC: Unit tracking ON")
		end,
	},
	
	persistenttrackmode = {
		name = "Persistent trackmode state",
		desc = "Trackmode will not cancel when deselecting unit. Trackmode will always attempt to track newly selected unit. Press mouse midclick to cancel this mode.",
		type = 'bool',
		value = false,
		path = cameraFollowPath,
	},
    
    thirdpersontrack = {
		name = "Enter 3rd Person Trackmode",
		desc = "3rd Person track the selected unit (mouse midclick to exit mode). Press arrow key to jump to nearby units, or move mouse to edge of screen to jump to current unit selection (will exit mode if no selection).",
		type = 'button',
		hotkey = {key='k', mod='alt+'},
		path = cameraFollowPath,
		OnChange = function(self)
			local selUnits = Spring.GetSelectedUnits()
			if selUnits and selUnits[1] and thirdperson_trackunit ~= selUnits[1] then --check if 3rd Person into same unit or if there's any unit at all
				Spring.SendCommands('viewfps')
				Spring.SendCommands('track')
				thirdperson_trackunit = selUnits[1]
				local cs = Spring.GetCameraState()
				cs.px,cs.py,cs.pz =Spring.GetUnitPosition(selUnits[1]) --place FPS camera on the ground (prevent out of LOD case)
				cs.py = cs.py + 25
				Spring.SetCameraState(cs,0)
			else
				Spring.SendCommands('trackoff')
				Spring.SendCommands('viewfree')
				thirdperson_trackunit = false
			end
        end,
	},
	
	enableCycleView = {
		name = "Group recall cycle within group",
		type = 'bool',
		value = false,
		path = cameraFollowPath,
		desc = "If you tap the group numbers (1,2,3 etc.) it will move the camera position to different clusters of units within the group rather than to the average position of the entire group.",
	},
	groupSelectionTapTimeout = {
		name = 'Group selection tap timeout',
		desc = "How quickly do you have to tap group numbers to move the camera? Smaller timeout means faster tapping.",
		type = 'number',
		min = 0.0, max = 5.0, step = 0.1,
		value = 2.0,
		path = cameraFollowPath,
	},
	-- end follow unit

}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_LINES		= GL.LINES
local GL_GREATER	= GL.GREATER
local GL_POINTS		= GL.POINTS

local glBeginEnd	= gl.BeginEnd
local glColor		= gl.Color
local glLineWidth	= gl.LineWidth
local glVertex		= gl.Vertex
local glAlphaTest	= gl.AlphaTest
local glPointSize 	= gl.PointSize
local glTexture 	= gl.Texture
local glTexRect 	= gl.TexRect

local red   = { 1, 0, 0 }
local green = { 0, 1, 0 }
local black = { 0, 0, 0 }
local white = { 1, 1, 1 }


local spGetCameraState		= Spring.GetCameraState
local spGetCameraVectors	= Spring.GetCameraVectors
local spGetGroundHeight		= Spring.GetGroundHeight
local spGetSmoothMeshHeight	= Spring.GetSmoothMeshHeight
local spGetModKeyState		= Spring.GetModKeyState
local spGetMouseState		= Spring.GetMouseState
local spGetSelectedUnits	= Spring.GetSelectedUnits
local spGetUnitPosition		= Spring.GetUnitPosition
local spIsAboveMiniMap		= Spring.IsAboveMiniMap
local spSendCommands		= Spring.SendCommands
local spSetCameraState		= Spring.SetCameraState
local spSetMouseCursor		= Spring.SetMouseCursor
local spTraceScreenRay		= Spring.TraceScreenRay
local spWarpMouse			= Spring.WarpMouse
local spGetCameraDirection	= Spring.GetCameraDirection
local spGetTimer 			= Spring.GetTimer
local spDiffTimers 			= Spring.DiffTimers
local spGetUnitDefID 		= Spring.GetUnitDefID
local spGetUnitSeparation	= Spring.GetUnitSeparation

local abs	= math.abs
local min 	= math.min
local max	= math.max
local sqrt	= math.sqrt
local sin	= math.sin
local cos	= math.cos

local echo = Spring.Echo

local helpText = {}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local ls_x, ls_y, ls_z --lockspot position
local ls_dist, ls_have, ls_onmap --lockspot flag
local tilting
local overview_mode, last_rx, last_ry, last_ls_dist, ov_cs --overview_mode's variable
local follow_timer = 0
local epicmenuHkeyComp = {} --for saving & reapply hotkey system handled by epicmenu.lua
local initialBoundsSet = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vsx, vsy = widgetHandler:GetViewSizes()
local cx,cy = vsx * 0.5,vsy * 0.5
function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	cx = vsx * 0.5
	cy = vsy * 0.5
	SetFOV(Spring.GetCameraFOV())
end

local PI 			= 3.1415
--local TWOPI			= PI*2	
local HALFPI		= PI/2
--local HALFPIPLUS	= HALFPI+0.01
local HALFPIMINUS	= HALFPI-0.01
local RADperDEGREE = PI/180


local fpsmode = false
local mx, my = 0,0
local msx, msy = 0,0
local smoothscroll = false
local springscroll = false
local lockspringscroll = false
local rotate, movekey
local move, rot, move2 = {}, {}, {}
local key_code = {
	left 		= 276,
	right 		= 275,
	up 			= 273,
	down 		= 274,
	pageup 		= 280,
	pagedown 	= 281,
}
local keys = {
	[276] = 'left',
	[275] = 'right',
	[273] = 'up',
	[274] = 'down',
}
local icon_size = 20
local cycle = 1
local camcycle = 1
local trackcycle = 1
local hideCursor = false


local MWIDTH, MHEIGHT = Game.mapSizeX, Game.mapSizeZ
local minX, minZ, maxX, maxZ = 0, 0, MWIDTH, MHEIGHT
local mcx, mcz 	= MWIDTH / 2, MHEIGHT / 2
local mcy 		= spGetGroundHeight(mcx, mcz)
local maxDistY = max(MHEIGHT, MWIDTH) * 2
local mapEdgeBuffer = 1000

--Tilt Zoom constants
local onTiltZoomTrack = true

local groundMin, groundMax = Spring.GetGroundExtremes()
local topDownBufferZonePercent = 0.20
local groundBufferZone = 20
local topDownBufferZone = maxDistY * topDownBufferZonePercent
local minZoomTiltAngle = 35
local angleCorrectionMaximum = 5 * RADperDEGREE
local targetCenteringHeight = 1200

SetFOV = function(fov)
	local cs = spGetCameraState()
	-- Spring.Echo(fov .. " degree")
	
	local currentFOVhalf_rad = (fov/2) * RADperDEGREE
	mapEdgeBuffer = groundMax
	local mapFittingDistance = MHEIGHT/2
	if vsy/vsx > MHEIGHT/MWIDTH then mapFittingDistance = (MWIDTH * vsy/vsx)/2 end
	mapEdgeBuffer = math.max(mapEdgeBuffer, mapFittingDistance/1.7) -- map edge buffer should be 1/6th of the length of the dimension fitted to screen

	local mapLength = mapFittingDistance + mapEdgeBuffer
	maxDistY = mapLength/math.tan(currentFOVhalf_rad) --adjust maximum TAB/Overview distance based on camera FOV

	cs.fov = fov
	cs.py = overview_mode and maxDistY or math.min(cs.py, maxDistY)

	--Update Tilt Zoom Constants
	topDownBufferZone = maxDistY * topDownBufferZonePercent
	minZoomTiltAngle = (30 + 25 * math.tan(cs.fov/2 * RADperDEGREE)) * RADperDEGREE

  spSetCameraState(cs,0)
  -- OverrideSetCameraStateInterpolate(cs,smoothness.value)
end

local function SetSkyBufferProportion(cs)
	local _,cs_py,_ = Spring.GetCameraPosition()
	local topDownBufferZoneBottom = maxDistY - topDownBufferZone
	WG.COFC_SkyBufferProportion = min(max((cs_py - topDownBufferZoneBottom)/topDownBufferZone + 0.2, 0.0), 1.0) --add 0.2 to start fading little before the straight-down zoomout
end

do SetFOV(Spring.GetCameraFOV()) end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local rotate_transit --switch for smoothing "rotate at mouse position instead of screen center"
local last_move = spGetTimer() --switch for reseting lockspot for Edgescroll
local thirdPerson_transit = spGetTimer() --switch for smoothing "3rd person trackmode edge screen scroll"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetMapBoundedCoords(x,z) --This should not use minX,minZ,maxX,maxZ bounds, as this is used specifically to keep things on the map
	if x < 0 then x = 0; end
	if x > MWIDTH then x=MWIDTH; end
	if z < 0 then z = 0; end 
	if z > MHEIGHT then z = MHEIGHT; end 
	return x,z
end

local function GetDist(x1,y1,z1, x2,y2,z2)
	local d1 = x2-x1
	local d2 = y2-y1
	local d3 = z2-z1
	
	return sqrt(d1*d1 + d2*d2 + d3*d3)
end

local function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end

local function LimitZoom(a,b,c,sp,limit)
	--Check if anyone reach max speed
	local zox,zoy,zoz = a*sp,b*sp,c*sp
	local maxZoom = math.max(math.abs(zox),math.abs(zoy),math.abs(zoz))
	--Limit speed
	maxZoom = math.min(maxZoom,limit)
	--Normalize
	local total = math.sqrt(zox^2+zoy^2+zoz^2)
	zox,zoy,zoz = zox/total,zoy/total,zoz/total
	--Reapply speed
	return zox*maxZoom,zoy*maxZoom,zoz*maxZoom
end

local function ExtendedGetGroundHeight(x,z)
	--out of map. Bound coordinate to within map
	x,z = GetMapBoundedCoords(x,z)
	return spGetGroundHeight(x,z)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local scrnRay_cache = {result={0,0,0,0,0,0,0}, previous={fov=1,inclination=99,azimuth=299,x=9999,y=9999}}
local function OverrideTraceScreenRay(x,y,cs,groundHeight,sphereRadius,planeIntercept,hitScanMethod,planeToHit,returnRayDistance) --this function provide an adjusted TraceScreenRay for null-space outside of the map (by msafwan)
	local viewSizeY = vsy
	local viewSizeX = vsx
	if not vsy or not vsx then
		viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	end
	local halfViewSizeY = viewSizeY/2
	local halfViewSizeX = viewSizeX/2
	y = y- halfViewSizeY --convert screen coordinate to 0,0 at middle
	x = x- halfViewSizeX
	local currentFov = cs.fov/2 --in Spring: 0 degree is directly ahead and +FOV/2 degree to the left and -FOV/2 degree to the right
	--//Speedup//--
	if scrnRay_cache.previous.fov==currentFov and scrnRay_cache.previous.inclination == cs.rx and scrnRay_cache.previous.azimuth == cs.ry and scrnRay_cache.previous.x ==x and scrnRay_cache.previous.y == y then --if camera Sphere coordinate & mouse position not change then use cached value
		return scrnRay_cache.result[1],scrnRay_cache.result[2],scrnRay_cache.result[3],scrnRay_cache.result[4],scrnRay_cache.result[5],scrnRay_cache.result[6],scrnRay_cache.result[7] 
	end
	--[[
	--Opengl screen FOV scaling logic:
	                                  >     
	                              >    | 
	                          >        |  
	                      >            | 
	                  >  |             |  Notice! : 90 FOV screen size == 2 times 45 FOV screen size
	              >      | <-45 FOV    |
	          >          |   reference | 
	      >              |   screen    | 
	      > --- FOV=45   |             | 
	          >          |             |  <-- 90 FOV
	              >      |             |      new screen size
	                  >  |             |      
	                      >            |
	                          >        |
	                              >    |
	                                  > <--ray cone
	--]]
	--//Opengl FOV scaling logic//--
	local referenceScreenSize = halfViewSizeY --because Opengl Glut use vertical screen size for FOV setting
	local referencePlaneDistance = referenceScreenSize -- because Opengl use 45 degree as default FOV, in which case tan(45)=1= referenceScreenSize/referencePlaneDistance
	local currentScreenSize = math.tan(currentFov*RADperDEGREE)*referencePlaneDistance --calculate screen size for current FOV if the distance to perspective projection plane is the default for 45 degree
	local resizeFactor = referenceScreenSize/currentScreenSize --the ratio of the default screen size to new FOV's screen size
	local perspectivePlaneDistance = resizeFactor*referencePlaneDistance --move perspective projection plane (closer or further away) so that the size appears to be as the default size for 45 degree
	--Note: second method is "perspectivePlaneDistance=halfViewSizeY/math.tan(currentFov*RADperDEGREE)" which yield the same result with 1 line.
	--[[
	--mouse-to-Sphere illustration:
	          ______                            ______
	          \     -----------_______----------      /
	            \    .      .     |     .     .     /
	             \   .     .    ..|.. $<cursor.    /
	              \   .   .   /   |   \   .  .    /
	              | --.---.--.----|----.--.--.----|    <--(bottom of) sphere surface flatten on 2d screen
	              /   .   .   \   |   /   .  .    \       so, cursor distance from center assume role of Inclination
	             /   .     .    ..|..    .    .    \      and, cursor position (left, right, or bottom) assume role of Azimuth
	            /    .      .     |     .     .     \
	          /    ____________-------__________      \
	          -----                             ------
	--]]
	--//mouse-to-Sphere projection//--
	local distanceFromCenter = sqrt(x*x+y*y) --mouse cursor distance from center screen. We going to simulate a Sphere dome which we will position the mouse cursor.
	local inclination = math.atan(distanceFromCenter/perspectivePlaneDistance) --translate distance in 2d plane to angle projected from the Sphere
	inclination = inclination -PI/2 --offset 90 degree because we want to place the south hemisphere (bottom) of the dome on the screen
	local azimuth = math.atan2(-x,y) --convert x,y to angle, so that left is +degree and right is -degree. Note: negative x flip left-right or right-left (flip the direction of angle)
	--//Sphere-to-coordinate conversion//-- 
	--(x,y,z floating in space)
	sphereRadius = sphereRadius or 100
	local sphere_x = sphereRadius* sin(azimuth)* cos(inclination) --convert Sphere coordinate back to Cartesian coordinate to prepare for rotation procedure
	local sphere_y = sphereRadius* sin(inclination)
	local sphere_z = sphereRadius* cos(azimuth)* cos(inclination)
	--//coordinate rotation 90+x degree//--
	--(x,y,z rotated in space)
	local rotateToInclination = PI/2+cs.rx --rotate to +90 degree facing the horizon then rotate to camera's current facing.
	local new_x = sphere_x --rotation on x-axis
	local new_y = sphere_y* cos (rotateToInclination) + sphere_z* sin (rotateToInclination) --move points of Sphere to new location 
	local new_z = sphere_z* cos (rotateToInclination) - sphere_y* sin (rotateToInclination)
	--//coordinate-to-Sphere conversion//--
	--(Inclination and Azimuth for x,y,z)
	local cursorTilt = math.atan2(new_y,sqrt(new_z*new_z+new_x*new_x)) --convert back to Sphere coordinate. See: http://en.wikipedia.org/wiki/Spherical_coordinate_system for conversion formula.
	local cursorHeading = math.atan2(new_x,new_z) --Sphere's azimuth
	
	local gx, gy, gz,rx,ry,rz,rayDist = -1,-1,-1,-1,-1,-1,-1
	local cancelCache = false
	if planeIntercept then
		groundHeight = groundHeight or 0
		if hitScanMethod then
			groundHeight = 0 --we going to find it ourselves using Hit Scan method!
		end
		--//Sphere-to-groundPosition translation (part1)//--
		--(calculate intercept of ray from mouse to a flat ground)
		local tiltSign = abs(cursorTilt)/cursorTilt --Sphere's inclination direction (positive upward or negative downward)
		local cursorTiltComplement = (PI/2-abs(cursorTilt))*tiltSign --return complement angle for cursorTilt. Note: we use 0 degree when look down, and 90 degree when facing the horizon. This simplify the problem conceptually. (actual case is 0 degree horizon and +-90 degree up/down)
		cursorTiltComplement = min(1.5550425,abs(cursorTiltComplement))*tiltSign --limit to 89 degree to prevent infinity in math.tan() 
		local vertGroundDist = groundHeight-cs.py --distance to ground
		local groundDistSign = abs(vertGroundDist)/vertGroundDist --negative when ground is below, positive when ground is above
		local xz_GrndDistRatio = math.tan(cursorTiltComplement)
		local cursorxzDist = xz_GrndDistRatio*(vertGroundDist) --calculate how far does the camera angle look pass the ground beneath
		local effectiveHeading = cs.ry+cursorHeading
		if groundDistSign + tiltSign == 0 then ---handle a special case when camera/cursor is facing away from ground (ground & camera sign is different).
			--//Sphere-to-3d-coordinate translation//--
			--(calculate intercept of ray from mouse to sphere edge)
			local xzDist = sqrt(new_x*new_x + new_z*new_z)
			local xDist = sin(effectiveHeading)*xzDist --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed
			local zDist = cos(effectiveHeading)*xzDist
			rayDist = sphereRadius
			rx,ry,rz = xDist,new_y,zDist --relative 3d coordinate with respect to screen (sphere's edge)
			gx, gy, gz = cs.px+xDist,cs.py+new_y,cs.pz+zDist --estimated ground position infront of camera (sphere's edge)
			cancelCache = true --force cache update next run (because zooming the sky will end when cam reach the edge of the sphere, so we must always calculate next sphere)
		else --when normal case (camera facing the ground)
			--//Sphere-to-groundPosition translation (part2)//--
			--[[
			--illustration of conventional coordinate and Spring's coordinate:
			--Convention coordinate:
			         * +Z-axis
			         |
			         |
			         |
			         O - - - - -> +X-axis
			--Spring coordinate: (conventional trigonometry must be tweaked to be consistent with this coordinate system. High chance of bug!)
			         O - - - - -> +X-axis
			         |
			         |
			         |
			         v +Z-axis
			--]]
			local cursorxDist = sin(effectiveHeading)*cursorxzDist --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed
			local cursorzDist = cos(effectiveHeading)*cursorxzDist
			rx,ry,rz = cursorxDist,groundHeight-cs.py,cursorzDist --relative 3d coordinate with respect to screen
			gx, gy, gz = cs.px+cursorxDist,groundHeight,cs.pz+cursorzDist --estimated ground position infront of camera
			if returnRayDistance then
				rayDist = math.sqrt(cursorxzDist^2+ry^2)
			end
			
			if hitScanMethod then
				local searchDirection = 100
				local SearchCriteria = function(grndHeight,currHeight)
										return grndHeight >= currHeight
									end

				local safetyCounter = 0
				local tx,tz,ty,cxzd  = 0,0,0,10
				while(safetyCounter<1000 and cxzd>0 and cxzd<100000) do
					cxzd = cxzd + searchDirection
					safetyCounter = safetyCounter + 1
					cursorxDist = sin(effectiveHeading)*cxzd --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed
					cursorzDist = cos(effectiveHeading)*cxzd
					tx, tz = cs.px+cursorxDist,cs.pz+cursorzDist --estimated ground position infront of camera
					ty = (cxzd/xz_GrndDistRatio) - vertGroundDist 
					currentGrndH = planeToHit or ExtendedGetGroundHeight(tx,tz)
					if SearchCriteria(currentGrndH,ty) then
						if searchDirection >1 then --condition meet but search is too coarse
							cxzd = cursorxzDist --go back
							searchDirection = searchDirection/10 --increase search accuracy
						else
							gx,gy,gz,cursorxzDist = tx,ty,tz,cxzd
							break --finish!
						end
					end
					gx,gy,gz,cursorxzDist = tx,ty,tz,cxzd
				end
				rx,ry,rz = cursorxDist,currentGrndH-cs.py,cursorzDist --relative to camera
				if returnRayDistance then
					rayDist = math.sqrt(cursorxzDist^2+ry^2)
				end
			end
		end
	else
		--//Sphere-to-worldSphere translation//--
		--(calculate intercept of ray from mouse to a bigger sphere)
		local xzDist = sqrt(new_x*new_x + new_z*new_z)
		local xDist = sin(cs.ry+cursorHeading)*xzDist --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed (?)
		local zDist = cos(cs.ry+cursorHeading)*xzDist
		rayDist = sphereRadius
		rx,ry,rz = xDist,new_y,zDist --(sphere's edge)
		gx, gy, gz = cs.px+xDist,cs.py+new_y,cs.pz+zDist --estimated ground position infront of camera (sphere's edge))
	end
		
	--Finish
	if false then
		-- Spring.Echo("MouseCoordinate")
		-- Spring.Echo(y .. " y")
		-- Spring.Echo(x .. " x")
		-- Spring.Echo("Before_Angle")
		-- Spring.Echo(inclination*(180/PI) .. " inclination")
		-- Spring.Echo(azimuth*(180/PI).. " azimuth")
		-- Spring.Echo(distanceFromCenter.. " distanceFromCenter")
		-- Spring.Echo(perspectivePlaneDistance.. " perspectivePlaneDistance")
		-- Spring.Echo( halfViewSizeY/math.tan(currentFov*RADperDEGREE) .. " perspectivePlaneDistance(2ndMethod)")
		-- Spring.Echo("CameraAngle")
		-- Spring.Echo(cs.rx*(180/PI))
		-- Spring.Echo(cs.ry*(180/PI))
		-- Spring.Echo("After_Angle")
		-- Spring.Echo(cursorTilt*(180/PI))
		-- Spring.Echo((cs.ry+cursorHeading)*(180/PI) .. " cursorComponent: " .. cursorHeading*(180/PI))
		Spring.MarkerAddPoint(gx, gy, gz, "here")
		Spring.Echo(gx..",".. gy..",".. gz)
	end
	--//caching for efficiency
	if not cancelCache then
		scrnRay_cache.result[1] = gx
		scrnRay_cache.result[2] = gy
		scrnRay_cache.result[3] = gz
		scrnRay_cache.result[4] = rx
		scrnRay_cache.result[5] = ry
		scrnRay_cache.result[6] = rz
		scrnRay_cache.result[7] = rayDist
		scrnRay_cache.previous.inclination =cs.rx
		scrnRay_cache.previous.azimuth = cs.ry
		scrnRay_cache.previous.x = x
		scrnRay_cache.previous.y = y
		scrnRay_cache.previous.fov = currentFov
	end

	return gx,gy,gz,rx,ry,rz,rayDist
	--Most important credit to!:
	--0: Google search service
	--1: "Perspective Projection: The Wrong Imaging Model" by Margaret M. Fleck (http://www.cs.illinois.edu/~mfleck/my-papers/stereographic-TR.pdf)
	--2: http://www.scratchapixel.com/lessons/3d-advanced-lessons/perspective-and-orthographic-projection-matrix/perspective-projection-matrix/
	--3: http://stackoverflow.com/questions/5278417/rotating-body-from-spherical-coordinates
	--4: http://en.wikipedia.org/wiki/Spherical_coordinate_system
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[ --NOTE: is not yet used for the moment
local function MoveRotatedCam(cs, mxm, mym)
	if not cs.dy then
		return cs
	end
	
	-- forward, up, right, top, bottom, left, right
	local camVecs = spGetCameraVectors()
	local cf = camVecs.forward
	local len = sqrt((cf[1] * cf[1]) + (cf[3] * cf[3]))
	local dfx = cf[1] / len
	local dfz = cf[3] / len
	local cr = camVecs.right
	local len = sqrt((cr[1] * cr[1]) + (cr[3] * cr[3]))
	local drx = cr[1] / len
	local drz = cr[3] / len
	
	local vecDist = (- cs.py) / cs.dy
	
	local ddx = (mxm * drx) + (mym * dfx)
	local ddz = (mxm * drz) + (mym * dfz)
	
	local gx1, gz1 = cs.px + vecDist*cs.dx,			cs.pz + vecDist*cs.dz --note me: what does cs.dx mean?
	local gx2, gz2 = cs.px + vecDist*cs.dx + ddx,	cs.pz + vecDist*cs.dz + ddz 
	
	local extra = 500
	
	if gx2 > MWIDTH + extra then
		ddx = MWIDTH + extra - gx1
	elseif gx2 < 0 - extra then
		ddx = -gx1 - extra
	end
	
	if gz2 > MHEIGHT + extra then
		ddz = MHEIGHT - gz1 + extra
	elseif gz2 < 0 - extra then
		ddz = -gz1 - extra
	end
	
	cs.px = cs.px + ddx
	cs.pz = cs.pz + ddz
	return cs
end
--]]

--Note: If the x,y is not pointing at an onmap point, this function traces a virtual ray to an
--          offmap position using the camera direction and disregards the x,y parameters.
local function VirtTraceRay(x,y, cs)
	local _, gpos = spTraceScreenRay(x, y, true, false,false, true) --only coordinate, NOT thru minimap, NOT include sky, ignore water surface

	if gpos then
		local gx, gy, gz = gpos[1], gpos[2], gpos[3]
		
		--gy = spGetSmoothMeshHeight (gx,gz)
		
		if gx < 0 or gx > MWIDTH or gz < 0 or gz > MHEIGHT then --out of map
			return false, gx, gy, gz	
		else
			return true, gx, gy, gz
		end
	end
	
	if not cs or not cs.dy or cs.dy == 0 then
		return false, false
	end
	--[[ 
	local vecDist = (- cs.py) / cs.dy
	local gx, gy, gz = cs.px + vecDist*cs.dx, 	cs.py + vecDist*cs.dy, 	cs.pz + vecDist*cs.dz  --note me: what does cs.dx mean?
	--]]
	local gx,gy,gz = OverrideTraceScreenRay(x,y,cs,ExtendedGetGroundHeight(cs.px, cs.pz),2000,true) --use override if spTraceScreenRay() do not have results
	
	--gy = spGetSmoothMeshHeight (gx,gz)
	return false, gx, gy, gz
end

SetCenterBounds = function(cs)
	-- if options.zoomouttocenter then Spring.Echo("zoomouttocenter.value: "..options.zoomouttocenter.value) end
	if options.zoomouttocenter.value then --move camera toward center

		scrnRay_cache.previous.fov = -999 --force reset cache (somehow cache value is used. Don't make sense at all...)

		local currentFOVhalf_rad = (cs.fov/2) * RADperDEGREE
		local maxDc = math.max((maxDistY - cs.py), 0)/(maxDistY - mapEdgeBuffer)-- * math.tan(currentFOVhalf_rad) * 1.5)
		-- Spring.Echo("MaxDC: "..maxDc)
		minX, minZ, maxX, maxZ = math.max(mcx - MWIDTH/2 * maxDc, 0), math.max(mcz - MHEIGHT/2 * maxDc, 0), math.min(mcx + MWIDTH/2 * maxDc, MWIDTH), math.min(mcz + MHEIGHT/2 * maxDc, MHEIGHT)

		local outOfBounds = false;
		if cs.rx > -HALFPI + 0.002 then --If we are not facing stright down, do a full raycast
			local _,gx,gy,gz = VirtTraceRay(cx, cy, cs)
			if gx < minX then cs.px = cs.px + (minX - gx); ls_x = ls_x + (minX - gx); outOfBounds = true end
			if gx > maxX then cs.px = cs.px + (maxX - gx); ls_x = ls_x + (maxX - gx); outOfBounds = true end
			if gz < minZ then cs.pz = cs.pz + (minZ - gz); ls_z = ls_z + (minZ - gz); outOfBounds = true end
			if gz > maxZ then cs.pz = cs.pz + (maxZ - gz); ls_z = ls_z + (maxZ - gz); outOfBounds = true end
		else --We can use camera x & z location in place of a raycast to find center when camera is pointed towards ground, as this is faster and more numerically stable
			if cs.px < minX then cs.px = minX; ls_x = minX; outOfBounds = true end
			if cs.px > maxX then cs.px = maxX; ls_x = maxX; outOfBounds = true end
			if cs.pz < minZ then cs.pz = minZ; ls_z = minZ; outOfBounds = true end
			if cs.pz > maxZ then cs.pz = maxZ; ls_z = maxZ; outOfBounds = true end
		end
		if outOfBounds then ls_y = ExtendedGetGroundHeight(ls_x, ls_z) end
	else
		minX, minZ, maxX, maxZ = 0, 0, MWIDTH, MHEIGHT
	end
	-- Spring.Echo("Bounds: "..minX..", "..minZ..", "..maxX..", "..maxZ)
end

local function SetLockSpot2(cs, x, y) --set an anchor on the ground for camera rotation 
	if ls_have then --if lockspot is locked
		return
	end
	
	local x, y = x, y
	if not x then
		x, y = cx, cy --center of screen
	end

	local onmap, gx,gy,gz = VirtTraceRay(x, y, cs) --convert screen coordinate to ground coordinate
	
	if gx then
		ls_x,ls_y,ls_z = gx,gy,gz
		local px,py,pz = cs.px,cs.py,cs.pz
		local dx,dy,dz = ls_x-px, ls_y-py, ls_z-pz
		ls_onmap = onmap
		ls_dist = sqrt(dx*dx + dy*dy + dz*dz) --distance to ground coordinate
		ls_have = true
	end
end


local function UpdateCam(cs)
	local cs = cs
	if not (cs.rx and cs.ry and ls_dist) then
		--return cs 
		return false
	end
	
	local alt = sin(cs.rx) * ls_dist
	local opp = cos(cs.rx) * ls_dist --OR same as: sqrt(ls_dist * ls_dist - alt * alt)
	cs.px = ls_x - sin(cs.ry) * opp
	cs.py = ls_y - alt
	cs.pz = ls_z - cos(cs.ry) * opp
	
	if not options.freemode.value then
		local gndheight = spGetGroundHeight(cs.px, cs.pz) + 10
		if cs.py < gndheight then --prevent camera from going underground
			if options.groundrot.value then
				cs.py = gndheight
			else
				return false
			end
		end
	end
	
	return cs
end

local function GetZoomTiltAngle(gx, gz, cs, zoomin, rayDist)
		--[[
		--FOR REFERENCE
		--plot of "sqrt(skyProportion) * (-2 * HALFPI / 3) - HALFPI / 3"
		         O - - - - - - - - - - - - - - - - ->1 +skyProportion
		     -18 |
		         |x
		     -36 | x
		         |    x
		     -54 |        x
		         |            x
		     -72 |                  x
		         |                         x
		     -90 v -cam angle                       x
		--]]
	local groundHeight = groundMin --ExtendedGetGroundHeight(gx, gz) + groundBufferZone
	local skyProportion = math.min(math.max((cs.py - groundHeight)/((maxDistY - topDownBufferZone) - groundHeight), 0.0), 1.0)
	local targetRx = sqrt(skyProportion) * (minZoomTiltAngle - HALFPI) - minZoomTiltAngle

	-- Ensure angle correction only happens by parts if the angle doesn't match the target, unless it is within a threshold
	-- If it isn't, make sure the correction only happens in the direction of the curve. 
	-- Zooming in shouldn't make the camera face the ground more, and zooming out shouldn't focus more on the horizon
	if zoomin ~= nil and rayDist then
		if math.abs(targetRx - cs.rx) < angleCorrectionMaximum then
			-- Spring.Echo("Within Bounds")
			onTiltZoomTrack = true
			return targetRx
		elseif targetRx > cs.rx and zoomin then 
			-- Spring.Echo("Pulling on track for Zoomin")
			-- onTiltZoomTrack = true
			return cs.rx + angleCorrectionMaximum
		elseif targetRx < cs.rx and not zoomin then 
			-- Spring.Echo("Pulling on track for Zoomout")
			-- onTiltZoomTrack = true
			if skyProportion < 1.0 and rayDist < (maxDistY - topDownBufferZone) then return cs.rx - angleCorrectionMaximum
			else return targetRx
			end
		end
	end

	-- Spring.Echo((onTiltZoomTrack and "On" or "Off").." tiltzoom track")

	if onTiltZoomTrack then
		return targetRx
	else
		return cs.rx
	end
end

local function ZoomTiltCorrection(cs, zoomin, mouseX,mouseY)

	if (mouseX==nil) then
		mouseX,mouseY = mouseX or vsx/2,mouseY or vsy/2 --if NIL, revert to center of screen
	end
	scrnRay_cache.previous.fov = -999 --force reset cache (somehow cache value is used. Don't make sense at all...)

	--fixme: proper handling of nil ls_dist.
	--How to replicate: position camera to outside the map (looking at null space)
	--do /luaui reload, then attempt zoom. "ls_dist" will be nil here (currently not using "ls_dist" but using "rayDist")
	--(unexpected nil might indicate some COFC's flaw somewhere else). a todo..
	--
	-- 2014-11-08: This may have been fixed by checking that the result from UpdateCam exists before calling this from Zoom. Not entirely sure on that
	local gx,gy,gz,_,_,_,rayDist = OverrideTraceScreenRay(mouseX,mouseY, cs, nil,2000,true,true,nil,true)
	if gy == -math.huge then return cs end -- Avoids any possible issues when fully zooming out
	
	-- if gx and not options.freemode.value then
		-- out of map. Bound zooming to within map
		-- gx,gz = GetMapBoundedCoords(gx,gz)  
	-- end

	local targetRx = GetZoomTiltAngle(gx, gz, cs, zoomin, rayDist)
	cs.rx = targetRx

	local testgx,testgy,testgz = OverrideTraceScreenRay(mouseX, mouseY, cs, nil,2000,true,true,gy)
	if testgy == -math.huge then return cs end -- Avoids any possible issues when fully zooming out

	-- if testgx and not options.freemode.value then
		-- out of map. Bound zooming to within map
		-- testgx,testgz = GetMapBoundedCoords(testgx, testgz)
	-- end

	-- Correct so that mouse cursor is hovering over the same point. 

	-- Slight intentional overcorrection, helps the rotating camera keep the target in view
	-- Get proportion needed so that target location is centered in the view around when cs.py is targetCenteringHeight elmos above target, when zoomed from overview
	local centerwardDriftBase = (maxDistY - groundMin)/((maxDistY - groundMin) - (gy + targetCenteringHeight)) - 1
	-- Spring.Echo(centerwardDriftBase)
	local centerwardVDriftFactor = ((mouseY - vsy/2)/(vsy/2) - 0.3) * centerwardDriftBase --Shift vertical overcorrection down, to compensate for camera tilt
	local centerwardHDriftFactor = (mouseX - vsx/2)/(vsx/2) * centerwardDriftBase * (vsx/vsy) --Adjust horizontal overcorrection for aspect ratio

	-- Ensure that both points are on the same plane by testing them from camera. This way the y value will always be positive, making div/0 checks possible
	local dgx, dgz, dtestx, dtestz = gx - cs.px, gz - cs.pz, testgx - cs.px, testgz - cs.pz
	local dyCorrection = 1
	if cs.py > 0 then
		dyCorrection = (cs.py - gy)/math.max(cs.py - testgy, 0.001)
	end
	dtestx, dtestz = dtestx * dyCorrection, dtestz * dyCorrection 
	local dx, dz = (dgx - dtestx), (dgz - dtestz)
	if zoomin or cs.py < topDownBufferZone then
		cs.px = cs.px + dx - math.abs(math.sin(cs.ry)) * centerwardVDriftFactor * dx + math.abs(math.cos(cs.ry)) * centerwardHDriftFactor * dz
		cs.pz = cs.pz + dz - math.abs(math.cos(cs.ry)) * centerwardVDriftFactor * dz - math.abs(math.sin(cs.ry)) * centerwardHDriftFactor * dx
	else
		cs.px = cs.px + dx 
		cs.pz = cs.pz + dz 
	end
	-- Spring.Echo("Cos(RY): "..math.cos(cs.ry)..", Sin(RY): "..math.sin(cs.ry))

	return cs
end

local function SetCameraTarget(gx,gy,gz,smoothness,dist)
	--Note: this is similar to spSetCameraTarget() except we have control of the rules.
	--for example: native spSetCameraTarget() only work when camera is facing south at ~45 degree angle and camera height cannot have negative value (not suitable for underground use)
	if gx and gy and gz then --just in case
		if smoothness == nil then smoothness = options.smoothness.value or 0 end
		local cs = spGetCameraState()
		SetLockSpot2(cs) --get lockspot at mid screen if there's none present
		if not ls_have then
			return
		end
		if dist then -- if a distance is specified, loosen bounds at first. They will be checked at the end
			ls_dist = dist 
			ls_x, ls_y, ls_z = gx, gy, gz
		else -- otherwise, enforce bounds here to avoid the camera jumping around when moved with MMB or minimap over hilly terrain
			ls_x = math.min(math.max(gx, minX), maxX) --update lockpot to target destination
			ls_z = math.min(math.max(gz, minZ), maxZ)
			ls_y = ExtendedGetGroundHeight(ls_x, ls_z)
		end
		if options.tiltedzoom.value then
			local cstemp = UpdateCam(cs)
			if cstemp then cs.rx = GetZoomTiltAngle(ls_x, ls_z, cstemp) end
		end

		local oldPy = cs.py

		local cstemp = UpdateCam(cs)
		if cstemp then cs = cstemp end

		if not options.freemode.value then cs.py = min(cs.py, maxDistY) end --Ensure camera never goes higher than maxY

		SetCenterBounds(cs) 

		-- spSetCameraState(cs, smoothness) --move
		OverrideSetCameraStateInterpolate(cs,smoothness)
	end
end

local function Zoom(zoomin, shift, forceCenter)
	local zoomin = zoomin
	if options.invertzoom.value then
		zoomin = not zoomin
	end

	local cs = spGetCameraState()
	
	--//ZOOMOUT FROM CURSOR, ZOOMIN TO CURSOR//--
	if
	(not forceCenter) and
	((zoomin and options.zoomin.value == 'toCursor') or ((not zoomin) and options.zoomout.value == 'fromCursor'))
	then
		local onmap, gx,gy,gz = VirtTraceRay(mx, my, cs)
	
		if gx and not options.freemode.value then
			--out of map. Bound zooming to within map
			gx,gz = GetMapBoundedCoords(gx,gz)  
		end
		
		if gx then
			dx = gx - cs.px
			dy = gy - cs.py
			dz = gz - cs.pz
		else
			return false
		end
		
		local sp = (zoomin and options.zoominfactor.value or -options.zoomoutfactor.value) * (shift and 3 or 1)
		
		local zox,zoy,zoz = LimitZoom(dx,dy,dz,sp,2000)
		local new_px = cs.px + zox --a zooming that get slower the closer you are to the target.
		local new_py = cs.py + zoy
		local new_pz = cs.pz + zoz

		local groundMinimum = ExtendedGetGroundHeight(new_px, new_pz) + 20
		
		if not options.freemode.value then
			if new_py < groundMinimum then --zooming underground?
				sp = (groundMinimum - cs.py) / dy
				
				zox,zoy,zoz = LimitZoom(dx,dy,dz,sp,2000)
				new_px = cs.px + zox --a zooming that get slower the closer you are to the ground.
				new_py = cs.py + zoy
				new_pz = cs.pz + zoz
			elseif (not zoomin) and new_py > maxDistY then --zoom out to space?
				sp = (maxDistY - cs.py) / dy

				zox,zoy,zoz = LimitZoom(dx,dy,dz,sp,2000)
				new_px = cs.px + zox --a zoom-out that get slower the closer you are to the ceiling?
				new_py = cs.py + zoy
				new_pz = cs.pz + zoz
			end
			
		end


		if new_py == new_py then
			local boundedPy = math.min(math.max(new_py, groundMinimum), maxDistY - 10)
			cs.px = new_px-- * (boundedPy/math.max(new_py, 0.0001))
			cs.py = boundedPy
			cs.pz = new_pz-- * (boundedPy/math.max(new_py, 0.0001))

			--//SUPCOM camera zoom by Shadowfury333(Dominic Renaud):
			if options.tiltedzoom.value then
				cs = ZoomTiltCorrection(cs, zoomin, mx,my)
			end
		end
		--//

		-- ls_dist = cs.py

		-- spSetCameraState(cs, options.smoothness.value)

		ls_have = false
		-- return
		
	else

		--//ZOOMOUT FROM CENTER-SCREEN, ZOOMIN TO CENTER-SCREEN//--
		local onmap, gx,gy,gz = VirtTraceRay(cx, cy, cs)
		
		if gx and not options.freemode.value then
			--out of map. Bound zooming to within map
			gx,gz = GetMapBoundedCoords(gx,gz)   
		end
		
		ls_have = false --unlock lockspot 
		-- SetLockSpot2(cs) --set lockspot
		if gx then --set lockspot
			ls_x,ls_y,ls_z = gx,gy,gz
			local px,py,pz = cs.px,cs.py,cs.pz
			local dx,dy,dz = ls_x-px, ls_y-py, ls_z-pz
			ls_onmap = onmap
			ls_dist = sqrt(dx*dx + dy*dy + dz*dz) --distance to ground coordinate
			ls_have = true
		end

		if not ls_have then
			return
		end
	    
		-- if zoomin and not ls_onmap then --prevent zooming into null area (outside map)
			-- return
		-- end

		-- if not options.freemode.value and ls_dist >= maxDistY then 
			-- return 
		-- end
	    
		local sp = (zoomin and -options.zoominfactor.value or options.zoomoutfactor.value) * (shift and 3 or 1)
		
		local ls_dist_new = ls_dist + math.max(math.min(ls_dist*sp,2000),-2000) -- a zoom in that get faster the further away from target (limited to -+2000)
		ls_dist_new = max(ls_dist_new, 20)
		
		if not options.freemode.value and ls_dist_new > maxDistY - gy then --limit camera distance to maximum distance
			-- return
			ls_dist_new = maxDistY - gy
		end
		ls_dist = ls_dist_new

		local cstemp = UpdateCam(cs)

		if cstemp and options.tiltedzoom.value then
			cstemp = ZoomTiltCorrection(cstemp, zoomin, nil)
			cstemp = UpdateCam(cstemp)
		end
		
		if cstemp then cs = cstemp; end
	end

	SetCenterBounds(cs)

	-- spSetCameraState(cs, options.smoothness.value)
	OverrideSetCameraStateInterpolate(cs,options.smoothness.value)

	return true
end


local function Altitude(up, s)
	ls_have = false
	onTiltZoomTrack = false
	
	local up = up
	if options.invertalt.value then
		up = not up
	end
	
	local cs = spGetCameraState()
	local py = max(1, abs(cs.py) )
	local dy = py * (up and 1 or -1) * (s and 0.3 or 0.1)
	local new_py = py + dy
	if not options.freemode.value then
        if new_py < spGetGroundHeight(cs.px, cs.pz)+5  then
            new_py = spGetGroundHeight(cs.px, cs.pz)+5  
        elseif new_py > maxDistY then
            new_py = maxDistY 
        end
	end
    cs.py = new_py

	SetCenterBounds(cs)

	-- spSetCameraState(cs, options.smoothness.value)
	OverrideSetCameraStateInterpolate(cs, options.smoothness.value)
	return true
end
--==End camera utility function^^ (a frequently used function. Function often used for controlling camera).


local function ResetCam()
	local cs = spGetCameraState()
	cs.px = Game.mapSizeX/2
	cs.py = maxDistY - 5 --Avoids flying off into nothingness when zooming out from cursor
	cs.pz = Game.mapSizeZ/2
	cs.rx = -HALFPI
	cs.ry = PI
	SetCenterBounds(cs)
	-- spSetCameraState(cs, 0)
	OverrideSetCameraStateInterpolate(cs,0)
	ov_cs = nil
	onTiltZoomTrack = true
end
options.resetcam.OnChange = ResetCam

OverviewSetAction = function()
	local cs = spGetCameraState()
	ov_cs = {}
	ov_cs.px = cs.px
	ov_cs.py = cs.py
	ov_cs.pz = cs.pz
	ov_cs.rx = cs.rx
	ov_cs.ry = cs.ry
end

OverviewAction = function()
	if not overview_mode then
		if thirdperson_trackunit then --exit 3rd person to show map overview
			spSendCommands('trackoff')
			spSendCommands('viewfree')
		end
		
		local cs = spGetCameraState()
		SetLockSpot2(cs)
		last_ls_dist = ls_dist
		last_rx = cs.rx
		last_ry = cs.ry
		if ov_cs then
			cs.px = ov_cs.px
			cs.py = ov_cs.py
			cs.pz = ov_cs.pz
			cs.rx = ov_cs.rx
			cs.ry = ov_cs.ry
		else
			cs.px = Game.mapSizeX/2
			cs.py = maxDistY
			cs.pz = Game.mapSizeZ/2
			cs.rx = -HALFPI
		end
		SetCenterBounds(cs)
		-- spSetCameraState(cs, 1)
		OverrideSetCameraStateInterpolate(cs,1)
	else --if in overview mode
		local cs = spGetCameraState()
		mx, my = spGetMouseState()
		local onmap, gx, gy, gz = VirtTraceRay(mx,my,cs) --create a lockstop point.
		if gx then --Note:  Now VirtTraceRay can extrapolate coordinate in null space (no need to check for onmap)
			local cs = spGetCameraState()			
			cs.rx = last_rx
			if ov_cs and last_ry and options.rotatebackfromov.value then cs.ry = last_ry end
			ls_dist = last_ls_dist 
			ls_x = gx
			ls_z = gz
			ls_y = gy
			ls_have = true
			local cstemp = UpdateCam(cs) --set camera position & orientation based on lockstop point
			if cstemp then cs = cstemp; end
			SetCenterBounds(cs)
			-- spSetCameraState(cs, 1)
			OverrideSetCameraStateInterpolate(cs,1)
		end
		
		if thirdperson_trackunit then
			local selUnits = spGetSelectedUnits() --player's new unit to track
			if not (selUnits and selUnits[1]) then --if player has no new unit to track
				Spring.SelectUnitArray({thirdperson_trackunit}) --select the original unit
				selUnits = spGetSelectedUnits()
			end
			thirdperson_trackunit = false
			if selUnits and selUnits[1] then 
				spSendCommands('viewfps')
				spSendCommands('track') -- re-issue 3rd person for selected unit
				thirdperson_trackunit = selUnits[1]
				local cs = spGetCameraState()	
				cs.px,cs.py,cs.pz=spGetUnitPosition(selUnits[1]) --move camera to unit position so no "out of LOD" case
				cs.py= cs.py+25 --move up 25-elmo incase FPS camera stuck to unit's feet instead of tracking it (aesthetic)
				-- spSetCameraState(cs,0)
				OverrideSetCameraStateInterpolate(cs,0)
			end
		end
	end
	
	overview_mode = not overview_mode
end
--==End option menu function (function that is attached to epic menu button)^^

local offscreenTracking = false --state variable
local function AutoZoomInOutToCursor() --options.followautozoom (auto zoom camera while in follow cursor mode)
	if smoothscroll or springscroll or rotate then
		return
	end
	local lclZoom = function(zoomin, smoothness,x,y,z)
		if not options.followautozoom.value then
			SetCameraTarget(x,y,z, smoothness) --track only
			return
		end
		local cs = spGetCameraState()
		ls_have = false --unlock lockspot 
        SetLockSpot2(cs) --set lockspot
        if not ls_have then
            return
        end 
		local sp = (zoomin and -1*options.followzoominspeed.value or options.followzoomoutspeed.value)
		local deltaDist = max(abs(ls_dist - abs(options.followzoommaxdist.value+options.followzoommindist.value)/2),10) --distance to midpoint
		local ls_dist_new = ls_dist + deltaDist*sp --zoom step: distance-to-midpoint multiplied by a zooming-multiplier
		ls_dist_new = max(ls_dist_new, options.followzoommindist.value)
		ls_dist_new = min(ls_dist_new, maxDistY,options.followzoommaxdist.value)
		ls_dist = ls_dist_new
		ls_x = x --update lockpot to target destination
		ls_y = y
		ls_z = z
		ls_have = true --lock lockspot

		if options.tiltedzoom.value and cs.name == "free" then 
			--fixme: proper handling of a case where cam is not "free cam". 
			--How to replicate: join a running game with autozoom & autotilt on, but DO NOT OPEN THE SPRING WINDOW,
			--allow for some catchup then open the Spring window to look at the game, the camera definitely already crashed.
			cs = ZoomTiltCorrection(cs, zoomin, nil)
		end

		local cstemp = UpdateCam(cs)
		if cstemp then cs = cstemp; end
		-- spSetCameraState(cs, smoothness) --track & zoom
		OverrideSetCameraStateInterpolate(cs,0)
	end
	local teamID = Spring.GetLocalTeamID()
	local _, playerID = Spring.GetTeamInfo(teamID)
	local pp = WG.alliedCursorsPos[ playerID ]
	if pp then
		local groundY = max(0,spGetGroundHeight(pp[1],pp[2]))
		local scrn_x,scrn_y = Spring.WorldToScreenCoords(pp[1],groundY,pp[2]) --get cursor's position on screen
		local scrnsize_X,scrnsize_Y = Spring.GetViewGeometry() --get current screen size
		if (scrn_x<scrnsize_X*4/6 and scrn_x>scrnsize_X*2/6) and (scrn_y<scrnsize_Y*4/6 and scrn_y>scrnsize_Y*2/6) then --if cursor near center:
			-- Spring.Echo("CENTER")
			local onscreenspeed = options.followinscrollspeed.mid*2 - options.followinscrollspeed.value --reverse value (ie: if 15 return 1, if 1 return 15, ect)
			lclZoom(true, onscreenspeed,pp[1], groundY, pp[2]) --zoom in & track
			offscreenTracking = nil
		elseif (scrn_x<scrnsize_X*5/6 and scrn_x>scrnsize_X*1/6) and (scrn_y<scrnsize_Y*5/6 and scrn_y>scrnsize_Y*1/6) then --if cursor between center & edge: do nothing 
			-- Spring.Echo("MID")
			if not offscreenTracking then
				local onscreenspeed = options.followinscrollspeed.mid*2 - options.followinscrollspeed.value --reverse value (ie: if 15 return 1, if 1 return 15, ect)
				SetCameraTarget(pp[1], groundY, pp[2], onscreenspeed) --track
			else --continue off-screen tracking, but at fastest speed (bring cursor to center ASAP)
				local maxspeed = math.min(options.followoutscrollspeed.mid*2 - options.followoutscrollspeed.value,options.followinscrollspeed.mid*2 - options.followinscrollspeed.value) --the fastest speed available 
				SetCameraTarget(pp[1], groundY, pp[2], maxspeed) --track
			end
		elseif (scrn_x<scrnsize_X*6/6 and scrn_x>scrnsize_X*0/6) and (scrn_y<scrnsize_Y*6/6 and scrn_y>scrnsize_Y*0/6) then --if cursor near edge: do
			-- Spring.Echo("EDGE")
			if not offscreenTracking then
				local onscreenspeed = options.followinscrollspeed.mid*2 - options.followinscrollspeed.value --reverse value (ie: if 15 return 1, if 1 return 15, ect)
				lclZoom(false, onscreenspeed,pp[1], groundY, pp[2]) --zoom out & track
			else --continue off-screen tracking, but at fastest speed (bring cursor to center ASAP)
				local maxspeed = math.min(options.followoutscrollspeed.mid*2 - options.followoutscrollspeed.value,options.followinscrollspeed.mid*2 - options.followinscrollspeed.value) --the fastest speed available 
				lclZoom(false, maxspeed,pp[1], groundY, pp[2]) --zoom out & track
			end
		else --outside screen
			-- Spring.Echo("OUT")
			local offscreenspeed = options.followoutscrollspeed.mid*2 - options.followoutscrollspeed.value --reverse value (ie: if 15 return 1, if 1 return 15, ect)
			lclZoom(false, offscreenspeed,pp[1], groundY, pp[2]) --zoom out & track
			offscreenTracking = true
		end
	end
end

local function RotateCamera(x, y, dx, dy, smooth, lock)
	local cs = spGetCameraState()
	local cs1 = cs
	if cs.rx then
		
		cs.rx = cs.rx + dy * options.rotfactor.value
		cs.ry = cs.ry - dx * options.rotfactor.value
		
		--local max_rx = options.restrictangle.value and -0.1 or HALFPIMINUS
		local max_rx = HALFPIMINUS
		
		if cs.rx < -HALFPIMINUS then
			cs.rx = -HALFPIMINUS
		elseif cs.rx > max_rx then
			cs.rx = max_rx 
		end
		
        -- [[
        if trackmode then --rotate world instead of camera during trackmode (during tracking unit)
            lock = true --lock camera to lockspot while rotating
            ls_have = false
			-- SetLockSpot2(cs) --set lockspot to middle of screen
			local selUnits = spGetSelectedUnits()
			if selUnits and selUnits[1] then
				local x,y,z = spGetUnitPosition( selUnits[1] )
				if x then --set lockspot to the unit
					ls_x,ls_y,ls_z = x,y,z
					local px,py,pz = cs.px,cs.py,cs.pz
					local dx,dy,dz = ls_x-px, ls_y-py, ls_z-pz
					ls_onmap = true
					ls_dist = sqrt(dx*dx + dy*dy + dz*dz) --distance to unit
					ls_have = true
				end
			end
        end
		--]]
		if lock and (ls_onmap or options.freemode.value) then --if have lock (ls_have ==true) and is either onmap or freemode (offmap) then update camera properties.
			local cstemp = UpdateCam(cs)
			if cstemp then
				cs = cstemp;
			else
				return
			end
		else
			ls_have = false
		end
		-- spSetCameraState(cs, smooth and options.smoothness.value or 0)
		OverrideSetCameraStateInterpolate(cs,smooth and options.smoothness.value or 0)
	end
end

local function ThirdPersonScrollCam(cs) --3rd person mode that allow you to jump between unit by edge scrolling (by msafwan)
	local detectionSphereRadiusAndPosition = {
		--This big spheres will fill a 90-degree cone and is used to represent a detection cone facing forward/left/right/backward. It's size will never exceed the 90-degree cone, but bigger sphere will always overlap halfway into smaller sphere and some empty space still exist on the side.
		--the first 25-elmo from unit is an empty space (which is really close to unit and thus needed no detection sphere)
		[1]={60,85}, --smaller sphere
		[2]={206,291}, --bigger sphere
		[3]={704,995},
		[4]={2402,3397},
		[5]={8201,11598},
		[6]={28001,39599},
		--90-degree cone
	}
	--local camVecs = spGetCameraVectors()
	local isSpec = Spring.GetSpectatingState()
	local teamID = (not isSpec and Spring.GetMyTeamID()) --get teamID ONLY IF not spec
	local foundUnit, foundUnitStructure
	local forwardOffset,backwardOffset,leftOffset,rightOffset
	if move.right then --content of move table is set in KeyPress(). Is global. Is used to start scrolling & rotation (initiated in Update()) 
		rightOffset =true
	elseif move.up then
		forwardOffset = true
	elseif move.left then
		leftOffset =true
	elseif move.down then
		backwardOffset = true
	end
	local front, top, right = Spring.GetUnitVectors(thirdperson_trackunit) --get vector of current tracked unit
	local x,y,z = spGetUnitPosition(thirdperson_trackunit) 
	y = y+25
	for i=1, 3 do --create a (detection) sphere of increasing size to ~1600-elmo range in scroll direction
		local sphereCenterOffset = detectionSphereRadiusAndPosition[i][2]
		local sphereRadius = detectionSphereRadiusAndPosition[i][1]
		local offX_temp = (forwardOffset and sphereCenterOffset) or (backwardOffset and -sphereCenterOffset) or 0 --set direction where sphere must grow in x,y,z (global) direction.
		local offY_temp = 0
		local offZ_temp = (rightOffset and sphereCenterOffset) or (leftOffset and -sphereCenterOffset) or 0
		local offX = front[1]*offX_temp + top[1]*offY_temp + right[1]*offZ_temp --rotate (translate) the global right/left/forward/backward into a direction relative to current unit
		local offY = front[2]*offX_temp + top[2]*offY_temp + right[2]*offZ_temp
		local offZ = front[3]*offX_temp + top[3]*offY_temp + right[3]*offZ_temp
		local sphUnits = Spring.GetUnitsInSphere(x+offX,y+offY,z+offZ, sphereRadius,teamID) --create sphere that detect unit in area of this direction
		local lowestUnitSeparation = 9999
		local lowestStructureSeparation = 9999
		for i=1, #sphUnits do
			local unitID = sphUnits[i]
			Spring.SelectUnitArray({unitID}) --test select unit (in case its not selectable)
			local selUnits = spGetSelectedUnits()
			if selUnits and selUnits[1] then --find unit in that area
				local defID = spGetUnitDefID(unitID)
				local unitSeparation = spGetUnitSeparation (unitID, thirdperson_trackunit, true)
				if UnitDefs[defID] and UnitDefs[defID].speed >0 then
					if lowestUnitSeparation > unitSeparation then
						foundUnit = selUnits[1]
						lowestUnitSeparation = unitSeparation
					end
				elseif not foundUnitStructure then
					if lowestStructureSeparation > unitSeparation then
						foundUnitStructure = selUnits[1]
						lowestStructureSeparation = unitSeparation
					end
				end
			end
		end
		if foundUnit then break end
		-- i++ (increase size of detection sphere) & (increase distance of detection sphere away into selected direction)
	end
	if not foundUnit then --if no mobile unit in the area: use closest structure (as target)
		foundUnit = foundUnitStructure
	end
	if not foundUnit then --if no unit in the area: use current unit (as target)
		foundUnit = thirdperson_trackunit
		Spring.Echo("COFC: no unit in that direction to jump to!")
	end
	Spring.SelectUnitArray({foundUnit}) --give selection order to player
	spSendCommands('viewfps')
	spSendCommands('track')
	thirdperson_trackunit = foundUnit --remember current unitID
	cs.px,cs.py,cs.pz=spGetUnitPosition(foundUnit) --move FPS camera to ground level (prevent out of LOD problem where unit turn into icons)
	cs.py = cs.py+25
	-- spSetCameraState(cs,0)
	OverrideSetCameraStateInterpolate(cs,0)
	thirdPerson_transit = spGetTimer() --block access to edge scroll until camera focus on unit
end

local function Tilt(s, dir)
	if not tilting then
		ls_have = false	
	end
	tilting = true
	onTiltZoomTrack = false

	local cs = spGetCameraState()
	SetLockSpot2(cs)
	if not ls_have then
		return
	end
    local dir = dir * (options.inverttilt.value and -1 or 1)
    

	local speed = dir * (s and 30 or 10)
	RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, true) --smooth, lock

	return true
end

local function ScrollCam(cs, mxm, mym, smoothlevel)
	scrnRay_cache.previous.fov = -999 --force reset of offmap traceScreenRay cache. Reason: because offmap traceScreenRay use cursor position for calculation but scrollcam always have cursor at midscreen
	SetLockSpot2(cs)
	if not cs.dy or not ls_have then
		--echo "<COFC> scrollcam fcn fail"
		return
	end
	if not ls_onmap then
		smoothlevel = 0.5
	end
	
	-- forward, up, right, top, bottom, left, right
	local camVecs = spGetCameraVectors()
	local cf = camVecs.forward
	local len = sqrt((cf[1] * cf[1]) + (cf[3] * cf[3])) --get hypotenus of x & z vector only
	local dfx = cf[1] / len
	local dfz = cf[3] / len
	local cr = camVecs.right
	local len = sqrt((cr[1] * cr[1]) + (cr[3] * cr[3]))
	local drx = cr[1] / len
	local drz = cr[3] / len
	
	local vecDist = (- cs.py) / cs.dy
	
	local ddx = (mxm * drx) + (mym * dfx)
	local ddz = (mxm * drz) + (mym * dfz)
	
	ls_x = ls_x + ddx
	ls_z = ls_z + ddz
	
	if not options.freemode.value then
		ls_x = min(ls_x, maxX-3) --limit camera movement to map area
		ls_x = max(ls_x, minX+3)
		
		ls_z = min(ls_z, maxZ-3)
		ls_z = max(ls_z, minZ+3)
	end
	
	if options.smoothmeshscroll.value then
		ls_y = spGetSmoothMeshHeight(ls_x, ls_z) or 0
	else
		if not options.freemode.value then
			ls_y = spGetGroundHeight(ls_x, ls_z) or 0 --bind lockspot to groundheight if not free
		end
	end
	
	local csnew = UpdateCam(cs)
	if csnew and options.tiltedzoom.value then
	  csnew.rx = GetZoomTiltAngle(ls_x, ls_z, csnew)
		csnew = UpdateCam(csnew)
	end
	if csnew then
		if not options.freemode.value then csnew.py = min(csnew.py, maxDistY) end --Ensure camera never goes higher than maxY
		-- SetCenterBounds(csnew) --Should be done since cs.py changes, but stops camera movement southwards. TODO: Investigate this.
    -- spSetCameraState(csnew, smoothlevel)
	OverrideSetCameraStateInterpolate(cs,smoothlevel)
  end
	
end

local function PeriodicWarning()
	local c_widgets, c_widgets_list = '', {}
	for name,data in pairs(widgetHandler.knownWidgets) do
		if data.active and
			(
			name:find('SmoothScroll')
			or name:find('Hybrid Overhead')
			or name:find('Complete Control Camera')
			)
			then
			c_widgets_list[#c_widgets_list+1] = name
		end
	end
	for i=1, #c_widgets_list do
		c_widgets = c_widgets .. c_widgets_list[i] .. ', '
	end
	if c_widgets ~= '' then
		echo('<COFCam> *Periodic warning* Please disable other camera widgets: ' .. c_widgets)
	end
end
--==End camera control function^^ (functions that actually do camera control)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local missedMouseRelease = false
function widget:Update(dt)
	local framePassed = math.ceil(dt/0.0333) --estimate how many gameframe would've passes based on difference in time??
    
	if hideCursor then
		spSetMouseCursor('%none%')
	end
	
	--//HANDLE TIMER FOR VARIOUS SECTION
	--timer to block tracking when using mouse
	if follow_timer > 0  then 
		follow_timer = follow_timer - dt
	end
	--timer to block unit tracking
	trackcycle = trackcycle + framePassed 
	if trackcycle >=6 then 
		trackcycle = 0 --reset value to Zero (0) every 6th frame. Extra note: dt*trackcycle would be the estimated number of second elapsed since last reset.
	end
	--timer to block cursor tracking
	camcycle = camcycle + framePassed 
	if camcycle >=12 then
		camcycle = 0 --reset value to Zero (0) every 12th frame. NOTE: a reset value a multiple of trackcycle's reset is needed to prevent conflict 
	end
	--timer to block periodic warning
	cycle = cycle + framePassed
	if cycle >=32*15 then
		cycle = 0 --reset value to Zero (0) every 32*15th frame.
	end	

	--//HANDLE TRACK UNIT
	--trackcycle = trackcycle%(6) + 1 --automatically reset "trackcycle" value to Zero (0) every 6th iteration.
	if (trackcycle == 0 and
	trackmode and
	not overview_mode and
	(follow_timer <= 0) and --disable tracking temporarily when middle mouse is pressed or when scroll is used for zoom
	not thirdperson_trackunit and
	not (rot.right or rot.left or rot.up or rot.down) and --cam rotation conflict with tracking, causing zoom-out bug. Rotation while tracking is handled in RotateCamera() but with less smoothing.
	(not rotate)) --update trackmode during non-rotating state (doing both will cause a zoomed-out bug)
	then 
		local selUnits = spGetSelectedUnits()
		if selUnits and selUnits[1] then
			local vx,vy,vz = Spring.GetUnitVelocity(selUnits[1])
			local x,y,z = spGetUnitPosition( selUnits[1] )
			--MAINTENANCE NOTE: the following smooth value is obtained from trial-n-error. There's no formula to calculate and it could change depending on engine (currently Spring 91). 
			--The following instruction explain how to get this smooth value:
			--1) reset Spring.SetCameraTarget to: (x+vx,y+vy,z+vz, 0.0333)
			--2) increase value A until camera motion is not jittery, then stop: (x+vx,y+vy,z+vz, 0.0333*A)
			--3) increase value B until unit center on screen, then stop: (x+vx*B,y+vy*B,z+vz*B, 0.0333*A)
			SetCameraTarget(x+vx*40,y+vy*40,z+vz*40, 0.0333*137)
		elseif (not options.persistenttrackmode.value) then --cancel trackmode when no more units is present in non-persistent trackmode.
			trackmode=false --exit trackmode
			Spring.Echo("COFC: Unit tracking OFF")
		end
	end
	
	--//HANDLE TRACK CURSOR
	--camcycle = camcycle%(12) + 1  --automatically reset "camcycle" value to Zero (0) every 12th iteration.
	if (camcycle == 0 and
	not trackmode and
	not overview_mode and
	(follow_timer <= 0) and --disable tracking temporarily when middle mouse is pressed or when scroll is used for zoom
	not thirdperson_trackunit and
	options.follow.value)  --if follow selected player's cursor:
	then 
		if WG.alliedCursorsPos then 
			AutoZoomInOutToCursor()
		end
	end
	
	
	-- Periodic warning
	--cycle = cycle%(32*15) + framePassed --automatically reset "cycle" value to Zero (0) every 32*15th iteration.
	if cycle == 0 then
		PeriodicWarning()
	end

	local cs = spGetCameraState()
	
	local use_lockspringscroll = lockspringscroll and not springscroll

	local a,c,m,s = spGetModKeyState()
	
	--//HANDLE ROTATE CAMERA
	if 	(not thirdperson_trackunit and  --block 3rd Person 
	(rot.right or rot.left or rot.up or rot.down))
	then
		
		local speed = options.rotfactor.value * (s and 500 or 250)

		if (rot.right or rot.left) and options.leftRightEdge.value == 'orbit' then
			SetLockSpot2(cs, vsx * 0.5, vsy * 0.5)
		end
		if rot.right then
			RotateCamera(vsx * 0.5, vsy * 0.5, speed, 0, true, ls_have)
		elseif rot.left then
			RotateCamera(vsx * 0.5, vsy * 0.5, -speed, 0, true, ls_have)
		end
		
		if (rot.up or rot.down) and options.topBottomEdge.value == 'orbit' then
			SetLockSpot2(cs, vsx * 0.5, vsy * 0.5)
		elseif options.topBottomEdge.value == 'rotate' then
			ls_have = false
		end
		if rot.up then
			RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, ls_have)
		elseif rot.down then
			RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true, ls_have)
		end
		ls_have = false
		
	end
	
	--//HANDLE MOVE CAMERA
	if (not thirdperson_trackunit and  --block 3rd Person 
	(smoothscroll or
	move.right or move.left or move.up or move.down or
	move2.right or move2.left or move2.up or move2.down or
	use_lockspringscroll))
	then
		
		local x, y, lmb, mmb, rmb = spGetMouseState()
		
		if (c) then
			return
		end
		
		local smoothlevel = 0
		
		-- clear the velocities
		cs.vx  = 0; cs.vy  = 0; cs.vz  = 0
		cs.avx = 0; cs.avy = 0; cs.avz = 0
				
		local mxm, mym = 0,0
		
		local heightFactor = (cs.py/1000)
		if smoothscroll then
			--local speed = dt * options.speedFactor.value * heightFactor 
			local speed = math.max( dt * options.speedFactor.value * heightFactor, 0.005 )
			mxm = speed * (x - cx)
			mym = speed * (y - cy)
		elseif use_lockspringscroll then
			--local speed = options.speedFactor.value * heightFactor / 10
			local speed = math.max( options.speedFactor.value * heightFactor / 10, 0.05 )
			local dir = options.invertscroll.value and -1 or 1
			mxm = speed * (x - mx) * dir
			mym = speed * (y - my) * dir
			
			spWarpMouse(cx, cy)		
		else --edge screen scroll
			--local speed = options.speedFactor_k.value * (s and 3 or 1) * heightFactor
			local speed = math.max( options.speedFactor_k.value * (s and 3 or 1) * heightFactor, 1 )
			
			if move.right or move2.right then
				mxm = speed
			elseif move.left or move2.left then
				mxm = -speed
			end
			
			if move.up or move2.up then
				mym = speed
			elseif move.down or move2.down then
				mym = -speed
			end
			smoothlevel = options.smoothness.value
			
			if spDiffTimers(spGetTimer(),last_move)>1 then --if edge scroll is 'first time': unlock lockspot once 
				ls_have = false
			end			
			last_move = spGetTimer()
		end
		
		ScrollCam(cs, mxm, mym, smoothlevel)
		
	end
	
	mx, my = spGetMouseState()
	
	--//HANDLE MOUSE'S SCREEN-EDGE SCROLL/ROTATION
	if not (WG.IsGUIHidden and WG.IsGUIHidden()) then --not in mission or (in mission but) not GuiHidden()
		if options.leftRightEdge.value == 'pan' then
			move2.right = false --reset mouse move state
			move2.left = false
			if mx > vsx-2 then 
				move2.right = true
			elseif mx < 2 then
				move2.left = true
			end
			
		elseif options.leftRightEdge.value == 'rotate' or options.leftRightEdge.value == 'orbit' then
			rot.right = false 
			rot.left = false
			if mx > vsx-2 then 
				rot.right = true 
			elseif mx < 2 then
				rot.left = true
			end
		end

		if options.topBottomEdge.value == 'pan' then
			move2.up = false
			move2.down = false
			if my > vsy-2 then
				move2.up = true
			elseif my < 2 then
				move2.down = true
			end

		elseif options.topBottomEdge.value == 'rotate' or options.topBottomEdge.value == 'orbit' then
			rot.up = false
			rot.down = false
			if my > vsy-2 then
				rot.up = true
			elseif my < 2 then
				rot.down = true
			end
		end
	end
	
	--//HANDLE MOUSE/KEYBOARD'S 3RD-PERSON (TRACK UNIT) RETARGET
	if 	(thirdperson_trackunit and 
	not overview_mode and --block 3rd person scroll when in overview mode
	(move.right or move.left or move.up or move.down or
	move2.right or move2.left or move2.up or move2.down or
	rot.right or rot.left or rot.up or rot.down)) --NOTE: engine exit 3rd-person trackmode if it detect edge-screen scroll, so we handle 3rd person trackmode scrolling here.
	then
		
		if movekey and spDiffTimers(spGetTimer(),thirdPerson_transit)>=1 then --wait at least 1 second before 3rd Person to nearby unit, and only allow edge scroll for keyboard press
			ThirdPersonScrollCam(cs) --edge scroll to nearby unit
		else --not using movekey for 3rdPerson-edge-Scroll (ie:is using mouse, "move2" and "rot"): re-issue 3rd person
			local selUnits = spGetSelectedUnits()
			if selUnits and selUnits[1] then -- re-issue 3rd person for selected unit (we need to reissue this because in normal case mouse edge scroll will exit trackmode)
				spSendCommands('viewfps')
				spSendCommands('track')
				thirdperson_trackunit = selUnits[1]
				local x,y,z = spGetUnitPosition(selUnits[1])
				if x and y and z then --unit position can be NIL if spectating with limited LOS
					cs.px,cs.py,cs.pz=x,y,z
					cs.py= cs.py+25 --move up 25-elmo incase FPS camera stuck to unit's feet instead of tracking it (aesthetic)
					-- spSetCameraState(cs,0)
					OverrideSetCameraStateInterpolate(cs,0)
				end
			else --no unit selected: return to freeStyle camera
				spSendCommands('trackoff')
				spSendCommands('viewfree')
				thirdperson_trackunit = false
			end
		end
	end
	
	--//MISC
	fpsmode = cs.name == "fps"
	if init or ((cs.name ~= "free") and (cs.name ~= "ov") and not fpsmode) then 
		init = false
		spSendCommands("viewfree") 
		local cs = spGetCameraState()
		cs.tiltSpeed = 0
		cs.scrollSpeed = 0
		--cs.gndOffset = options.mingrounddist.value
		cs.gndOffset = options.freemode.value and 0 or 1
		-- spSetCameraState(cs,0)
		OverrideSetCameraStateInterpolate(cs,0)
	end
	
	if missedMouseRelease and camcycle==0 then 
		--Workaround/Fix for middle-mouse button release event not detected:
		--We request MouseRelease event for middle-mouse release in MousePress by returning "true",
		--but when 2 key is pressed at same time, the MouseRelease is called for the first key which is released (not necessarily middle-mouse button).
		--If that happen, we will loop here every half-second until the middle-mouse button is really released.
		local _,_, _, mmb = spGetMouseState()
		if (not mmb) then
			rotate = nil
			smoothscroll = false
			springscroll = false
			missedMouseRelease = false
		end
	end

	if not initialBoundsSet then
		initialBoundsSet = true
		if options.tiltedzoom.value then ResetCam() end
	end
end

function widget:GamePreload()
	if not initialBoundsSet then --Tilt zoom initial overhead view (Engine 91)
		initialBoundsSet = true
		if options.tiltedzoom.value then ResetCam() end
	end
end

function widget:MouseMove(x, y, dx, dy, button)
	if rotate then
		local smoothed
		if rotate_transit then --if "rotateAtCursor" flag is True, then this will run 'once' to smoothen camera motion
			if spDiffTimers(spGetTimer(),rotate_transit)<1 then --smooth camera for in-transit effect
				smoothed = true
			else
				rotate_transit = nil --cancel in-transit flag
			end
		end
		if abs(dx) > 0 or abs(dy) > 0 then
			RotateCamera(x, y, dx, dy, smoothed, ls_have)
		end
		
		spWarpMouse(msx, msy)
		
		follow_timer = 0.6 --disable tracking for 1 second when middle mouse is pressed or when scroll is used for zoom
	elseif springscroll then
		
		if abs(dx) > 0 or abs(dy) > 0 then
			lockspringscroll = false
		end
		local dir = options.invertscroll.value and -1 or 1
					
		local cs = spGetCameraState()
		
		local speed = options.speedFactor.value * cs.py/1000 / 10
		local mxm = speed * dx * dir
		local mym = speed * dy * dir
		ScrollCam(cs, mxm, mym, 0)
		
		follow_timer = 0.6 --disable tracking for 1 second when middle mouse is pressed or when scroll is used for zoom
	end
end


function widget:MousePress(x, y, button) --called once when pressed, not repeated
	ls_have = false
	if (button == 2 and options.middleMouseButton.value == 'off') then 
		return true 
	end
	--overview_mode = false
    --if fpsmode then return end
	if lockspringscroll then
		lockspringscroll = false
		return true
	end
	
	-- Not Middle Click --
	if (button ~= 2) then
		return false
	end
	
	follow_timer = 4 --disable tracking for 4 second when middle mouse is pressed or when scroll is used for zoom
	
	local a,ctrl,m,s = spGetModKeyState()
	
	spSendCommands('trackoff')
    spSendCommands('viewfree')
	if not (options.persistenttrackmode.value and (ctrl or a)) then --Note: wont escape trackmode if pressing Ctrl or Alt in persistent trackmode, else: always escape.
		if trackmode then
			Spring.Echo("COFC: Unit tracking OFF")
		end
		trackmode = false
	end
	thirdperson_trackunit = false
	
	
	-- Reset --
	if a and ctrl then
		ResetCam()
		return true
	end
	
	-- Above Minimap --
	if (spIsAboveMiniMap(x, y)) then
		return false
	end
	
	local cs = spGetCameraState()
	
	msx = x
	msy = y
	
	spSendCommands({'trackoff'})
	
	rotate = false
	-- Rotate --
	if a or options.middleMouseButton.value == 'rotate' then
		spWarpMouse(cx, cy)
		ls_have = false
		onTiltZoomTrack = false
		rotate = true
		return true
	end
	-- Rotate World --
	if ctrl or options.middleMouseButton.value == 'orbit' then
		rotate_transit = nil
		onTiltZoomTrack = false
		if options.targetmouse.value then --if rotate world at mouse cursor: 
			
			local onmap, gx, gy, gz = VirtTraceRay(x,y, cs)
			if gx and (options.freemode.value or onmap) then  --Note: we don't block offmap position since VirtTraceRay() now work for offmap position.
				SetLockSpot2(cs,x,y) --set lockspot at cursor position
				
				--//update "ls_dist" with value from mid-screen's LockSpot because rotation is centered on mid-screen and not at cursor (cursor's "ls_dist" has bigger value than midscreen "ls_dist")//--
				local _,cgx,cgy,cgz = VirtTraceRay(cx,cy,cs) --get ground position traced from mid of screen
				local dx,dy,dz = cgx-cs.px, cgy-cs.py, cgz-cs.pz
				ls_dist = sqrt(dx*dx + dy*dy + dz*dz) --distance to ground 
				
				SetCameraTarget(gx,gy,gz,1) --transit to cursor position
				rotate_transit = spGetTimer() --trigger smooth in-transit effect in widget:MouseMove()
			end
			
		else
			SetLockSpot2(cs) --lockspot at center of screen
		end
		
		spWarpMouse(cx, cy) --move cursor to center of screen
		rotate = true
		msx = cx
		msy = cy
		return true
	end
	
	-- Scrolling --
	if options.smoothscroll.value then
		spWarpMouse(cx, cy)
		smoothscroll = true
	else
		springscroll = true
		lockspringscroll = not lockspringscroll
	end
	
	return true
	
end

function widget:MouseRelease(x, y, button)
	if (button == 2) then
		rotate = nil
		smoothscroll = false
		springscroll = false
		return -1
	else
		missedMouseRelease = true
	end
end

function widget:MouseWheel(wheelUp, value)
    if fpsmode then return end
	local alt,ctrl,m,shift = spGetModKeyState()
	
	if ctrl then
		return Tilt(shift, wheelUp and 1 or -1)
	elseif alt then
		if overview_mode then --cancel overview_mode if Overview_mode + descending 
			local zoomin = not wheelUp
			if options.invertalt.value then
				zoomin = not zoomin
			end
			if zoomin then 
				overview_mode = false
			else return; end-- skip wheel if Overview_mode + ascending
		end
		return Altitude(wheelUp, shift)
	end
	
	if overview_mode then --cancel overview_mode if Overview_mode + ZOOM-in
		local zoomin = not wheelUp
		if options.invertzoom.value then
			zoomin = not zoomin
		end
		if zoomin then
			overview_mode = false
		else return; end --skip wheel if Overview_mode + ZOOM-out
	end
	
	follow_timer = 0.6 --disable tracking for 1 second when middle mouse is pressed or when scroll is used for zoom
	return Zoom(not wheelUp, shift)
end

function widget:KeyPress(key, modifier, isRepeat)
	local intercept = GroupRecallFix(key, modifier, isRepeat)
	if intercept then
		return true
	end

	--ls_have = false
	tilting = false
	
	if thirdperson_trackunit then  --move key for edge Scroll in 3rd person trackmode
		if keys[key] and not (modifier.ctrl or modifier.alt) then
			movekey = true
			move[keys[key]] = true
		end
	end
	if fpsmode then return end
	if keys[key] then
		if modifier.ctrl or modifier.alt then
		
			local cs = spGetCameraState()
			SetLockSpot2(cs)
			if not ls_have then
				return
			end
			

		
			local speed = modifier.shift and 30 or 10 
			
			if key == key_code.right then 		RotateCamera(vsx * 0.5, vsy * 0.5, speed, 0, true, not modifier.alt)
			elseif key == key_code.left then 	RotateCamera(vsx * 0.5, vsy * 0.5, -speed, 0, true, not modifier.alt)
			elseif key == key_code.down then 	onTiltZoomTrack = false; RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true, not modifier.alt)
			elseif key == key_code.up then 		onTiltZoomTrack = false; RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, not modifier.alt)
			end
			return
		else
			movekey = true
			move[keys[key]] = true
		end
	elseif key == key_code.pageup then
		if modifier.ctrl then
			Tilt(modifier.shift, 1)
			return
		elseif modifier.alt then
			Altitude(true, modifier.shift)
			return
		else
			Zoom(true, modifier.shift, true)
			return
		end
	elseif key == key_code.pagedown then
		if modifier.ctrl then
			Tilt(modifier.shift, -1)
			return
		elseif modifier.alt then
			Altitude(false, modifier.shift)
			return
		else
			Zoom(false, modifier.shift, true)
			return
		end
	end
	tilting = false
end
function widget:KeyRelease(key)
	if keys[key] then
		move[keys[key]] = nil
	end
	if not (move.up or move.down or move.left or move.right) then
		movekey = nil
	end
end

local function DrawLine(x0, y0, c0, x1, y1, c1)
  glColor(c0); glVertex(x0, y0)
  glColor(c1); glVertex(x1, y1)
end

local function DrawPoint(x, y, c, s)
  --FIXME reenable later - ATIBUG glPointSize(s)
  glColor(c)
  glBeginEnd(GL_POINTS, glVertex, x, y)
end

local screenFrame = 0
function widget:DrawScreen()
	SetSkyBufferProportion()
	Interpolate()

	--Reset Camera for tiltzoom at game start (Engine 92+)
	if screenFrame == 3 then --detect frame no.2
		if options.tiltedzoom.value then ResetCam() end
		initialBoundsSet = true
	end
	screenFrame = screenFrame+1

  hideCursor = false
	if not cx then return end
    
	local x, y
	if smoothscroll then
		x, y = spGetMouseState()
		glLineWidth(2)
		glBeginEnd(GL_LINES, DrawLine, x, y, green, cx, cy, red)
		glLineWidth(1)
		
		DrawPoint(cx, cy, black, 14)
		DrawPoint(cx, cy, white, 11)
		DrawPoint(cx, cy, black,  8)
		DrawPoint(cx, cy, red,    5)
	
		DrawPoint(x, y, { 0, 1, 0 },  5)
	end
	
	local filefound	
	if smoothscroll then --or (rotate and ls_have) then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows.png')
		hideCursor = true
	--elseif rotate or lockspringscroll or springscroll then
		--filefound = glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows.png')
	end
	
	if filefound then
	
		if smoothscroll then
			glColor(0,1,0,1)
		elseif (rotate and ls_have) then
			glColor(1,0.6,0,1)
		elseif rotate then
			glColor(1,1,0,1)
		elseif lockspringscroll then
			glColor(1,0,0,1)
		elseif springscroll then
			if options.invertscroll.value then
				glColor(1,0,1,1)
			else
				glColor(0,1,1,1)
			end
		end
		
		glAlphaTest(GL_GREATER, 0)
		
		-- if not (springscroll and not lockspringscroll) then
		    -- hideCursor = true
		-- end
		if smoothscroll then
			local icon_size2 = icon_size
			glTexRect(x-icon_size, y-icon_size2, x+icon_size, y+icon_size2)
		else
			glTexRect(cx-icon_size, cy-icon_size, cx+icon_size, cy+icon_size)
		end
		glTexture(false)

		glColor(1,1,1,1)
		glAlphaTest(false)		
	end
end

function widget:Initialize()
	helpText = explode( '\n', options.helpwindow.value )
	cx = vsx * 0.5
	cy = vsy * 0.5
	
	spSendCommands( 'unbindaction toggleoverview' )
	spSendCommands( 'unbindaction trackmode' )
	spSendCommands( 'unbindaction track' )
	spSendCommands( 'unbindaction mousestate' ) --//disable screen-panning-mode toggled by 'backspace' key
	
	--Note: the following is for compatibility with epicmenu.lua's zkkey framework
	if WG.crude then
		if WG.crude.GetHotkey then
			epicmenuHkeyComp[1] = WG.crude.GetHotkey("toggleoverview") --get hotkey
			epicmenuHkeyComp[2] = WG.crude.GetHotkey("trackmode")
			epicmenuHkeyComp[3] = WG.crude.GetHotkey("track")
			epicmenuHkeyComp[4] = WG.crude.GetHotkey("mousestate")
		end
		if 	WG.crude.SetHotkey then
			WG.crude.SetHotkey("toggleoverview",nil) --unbind hotkey
			WG.crude.SetHotkey("trackmode",nil)
			WG.crude.SetHotkey("track",nil)
			WG.crude.SetHotkey("mousestate",nil)
		end
	end

	WG.COFC_SetCameraTarget = SetCameraTarget --for external use, so that minimap click works with COFC

	--for external use, so that minimap can scale when zoomed out
	WG.COFC_SkyBufferProportion = 0 
	
	spSendCommands("luaui disablewidget SmoothScroll")
	if WG.SetWidgetOption then
		WG.SetWidgetOption("Settings/Camera","Settings/Camera","Camera Type","COFC") --tell epicmenu.lua that we select COFC as our default camera (since we enabled it!)
	end

end

function widget:Shutdown()
	spSendCommands{"viewta"}
	spSendCommands( 'bind any+tab toggleoverview' )
	spSendCommands( 'bind any+t track' )
	spSendCommands( 'bind ctrl+t trackmode' )
	spSendCommands( 'bind backspace mousestate' ) --//re-enable screen-panning-mode toggled by 'backspace' key
	
	--Note: the following is for compatibility with epicmenu.lua's zkkey framework
	if WG.crude and WG.crude.SetHotkey then
		WG.crude.SetHotkey("toggleoverview",epicmenuHkeyComp[1]) --rebind hotkey
		WG.crude.SetHotkey("trackmode",epicmenuHkeyComp[2])
		WG.crude.SetHotkey("track",epicmenuHkeyComp[3])
		WG.crude.SetHotkey("mousestate",epicmenuHkeyComp[4])
	end

	WG.COFC_SetCameraTarget = nil
	WG.COFC_SkyBufferProportion = nil
end

function widget:TextCommand(command)
	
	if command == "cofc help" then
		for i, text in ipairs(helpText) do
			echo('<COFCam['.. i ..']> '.. text)
		end
		return true
	elseif command == "cofc reset" then
		ResetCam()
		return true
	end
	return false
end   

function widget:UnitDestroyed(unitID) --transfer 3rd person trackmode to other unit or exit to freeStyle view
	if thirdperson_trackunit and thirdperson_trackunit == unitID then --return user to normal view if tracked unit is destroyed
		local isSpec = Spring.GetSpectatingState()
		local attackerID= Spring.GetUnitLastAttacker(unitID)
		if not isSpec then
			spSendCommands('trackoff')
			spSendCommands('viewfree')
			thirdperson_trackunit = false
			return
		end
		if Spring.ValidUnitID(attackerID) then --shift tracking toward attacker if it is alive (cinematic).
			Spring.SelectUnitArray({attackerID})
		end
		local selUnits = spGetSelectedUnits()--test select unit
		if not (selUnits and selUnits[1]) then --if can't select, then, check any unit in vicinity
			local x,_,z = spGetUnitPosition(unitID)
			local units = Spring.GetUnitsInCylinder(x,z, 100)
			if units and units[1] then
				Spring.SelectUnitArray({units[1]})
			end
		end
		selUnits = spGetSelectedUnits()--test select unit
		if selUnits and selUnits[1] and (not Spring.GetUnitIsDead(selUnits[1]) ) then --if we can select unit, and those unit is not dead in this frame, then: track them
			spSendCommands('viewfps')
			spSendCommands('track')
			thirdperson_trackunit = selUnits[1]
			local cs = spGetCameraState()
			cs.px,cs.py,cs.pz=spGetUnitPosition(selUnits[1])
			cs.py= cs.py+25 --move up 25-elmo incase FPS camera stuck to unit's feet instead of tracking it (aesthetic)
			-- spSetCameraState(cs,0)
			OverrideSetCameraStateInterpolate(cs,0)
		else
			spSendCommands('trackoff')
			spSendCommands('viewfree')
			thirdperson_trackunit = false
		end
	end
end

--------------------------------------------------------------------------------
--Group Recall Fix--- (by msafwan, 9 Jan 2013)
--Remake Spring's group recall to trigger ZK's custom Spring.SetCameraTarget (which work for freestyle camera mode).
--------------------------------------------------------------------------------
local spGetUnitGroup = Spring.GetUnitGroup
local spGetGroupList  = Spring.GetGroupList 


--include("keysym.h.lua")
local previousGroup =99
local currentIteration = 1
local currentIterations = {}
local previousKey = 99
local previousTime = spGetTimer()
local groupNumber = {
	[KEYSYMS.N_1] = 1,
	[KEYSYMS.N_2] = 2,
	[KEYSYMS.N_3] = 3,
	[KEYSYMS.N_4] = 4,
	[KEYSYMS.N_5] = 5,
	[KEYSYMS.N_6] = 6,
	[KEYSYMS.N_7] = 7,
	[KEYSYMS.N_8] = 8,
	[KEYSYMS.N_9] = 9,
}

function GroupRecallFix(key, modifier, isRepeat)
	if ( not modifier.ctrl and not modifier.alt and not modifier.meta) then --check key for group. Reference: unit_auto_group.lua by Licho
		local group
		if (key ~= nil and groupNumber[key]) then 
			group = groupNumber[key]	
		end
		if (group ~= nil) then
			local selectedUnit = spGetSelectedUnits()
			local groupCount = spGetGroupList() --get list of group with number of units in them
			if groupCount[group] ~= #selectedUnit then
				previousKey = key
				previousTime = spGetTimer()
				return false
			end
			for i=1,#selectedUnit do
				local unitGroup = spGetUnitGroup(selectedUnit[i])
				if unitGroup~=group then
					previousKey = key
					previousTime = spGetTimer()
					return false
				end
			end
			if previousKey == key and (spDiffTimers(spGetTimer(),previousTime) > options.groupSelectionTapTimeout.value) then
				previousKey = key
				previousTime = spGetTimer()
				return true --but don't do anything. Only move camera after a double-tap (or more).
			end
			previousKey = key
			previousTime = spGetTimer()
			
			if options.enableCycleView.value then 
				if (currentIterations[group]) then
					currentIteration = currentIterations[group]
				else
					currentIteration = 1
				end
				local slctUnitUnordered = {}
				for i=1 , #selectedUnit do
					local unitID = selectedUnit[i]
					local x,y,z = spGetUnitPosition(unitID)
					slctUnitUnordered[unitID] = {x,y,z}
				end
				selectedUnit = nil
				local cluster, lonely = WG.OPTICS_cluster(slctUnitUnordered, 600,2, Spring.GetMyTeamID(),300) --//find clusters with atleast 2 unit per cluster and with at least within 300-elmo from each other with 600-elmo detection range
				if previousGroup == group then
					currentIteration = currentIteration +1
					if currentIteration > (#cluster + #lonely) then
						currentIteration = 1
					end
				-- else
				--	currentIteration = 1
				end
				currentIterations[group] = currentIteration
				if currentIteration <= #cluster then
					local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
					for unitIndex=1, #cluster[currentIteration] do
						local unitID = cluster[currentIteration][unitIndex]
						local x,y,z= slctUnitUnordered[unitID][1],slctUnitUnordered[unitID][2],slctUnitUnordered[unitID][3] --// get stored unit position
						sumX= sumX+x
						sumY = sumY+y
						sumZ = sumZ+z
						unitCount=unitCount+1
					end
					meanX = sumX/unitCount --//calculate center of cluster
					meanY = sumY/unitCount
					meanZ = sumZ/unitCount
					SetCameraTarget(meanX, meanY, meanZ,0.5)
				else
					local unitID = lonely[currentIteration-#cluster]
					local slctUnit = slctUnitUnordered[unitID]
					if slctUnit ~= nil then --nil check. There seems to be a race condition or something which causes this unit to be nil sometimes
						local x,y,z= slctUnit[1],slctUnit[2],slctUnit[3] --// get stored unit position
						SetCameraTarget(x,y,z,0.5)
					end
				end
				cluster=nil
				slctUnitUnordered = nil
			else --conventional method:
				local sumX, sumY,sumZ, unitCount,meanX, meanY, meanZ = 0,0 ,0 ,0 ,0,0,0
				for i=1, #selectedUnit do
					local unitID = selectedUnit[i]
					local x,y,z= spGetUnitPosition(unitID)
					sumX= sumX+x
					sumY = sumY+y
					sumZ = sumZ+z
					unitCount=unitCount+1
				end
				meanX = sumX/unitCount --//calculate center
				meanY = sumY/unitCount
				meanZ = sumZ/unitCount
				SetCameraTarget(meanX, meanY, meanZ,0.5) --is overriden by Spring.SetCameraTarget() at cache.lua.
			end
			previousGroup= group
			return true
		end
	end
end
