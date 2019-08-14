--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Combo Overhead/Free Camera (experimental)",
    desc      = "v0.138 Camera featuring 6 actions",
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
include("Widgets/COFCtools/TraceScreenRay.lua")

--WG Exports: 	WG.COFC_SetCameraTarget: {number gx, number gy, number gz(, number smoothness(,boolean useSmoothMeshSetting(, number dist)))} -> {}, Set Camera target, ensures COFC options are respected
--						 	WG.COFC_SetCameraTargetBox: {number minX, number minZ, number maxX, number maxZ, number minDist(, number maxY(, number smoothness(,boolean useSmoothMeshSetting)))} -> {}, Set Camera to contain input box. maxY should be the highest point in the box, defaults to ground height of box center
--							WG.COFC_SkyBufferProportion: {} -> number [0..1], proportion of maximum zoom height the camera is currently at. 0 is the ground, 1 is maximum zoom height.

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local init = true
local trackmode = false --before options
local thirdperson_trackunit = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Camera/Camera Controls'
local zoomPath = 'Settings/Camera/Camera Controls/Zoom Behaviour'
local rotatePath = 'Settings/Camera/Camera Controls/Rotation Behaviour'
local scrollPath = 'Settings/Camera/Camera Controls/Scroll Behaviour'
local miscPath = 'Settings/Camera/Camera Controls/Misc'
local cameraFollowPath = 'Settings/Camera/Camera Following'
local minimap_path = 'Settings/HUD Panels/Minimap'
options_order = {
	'helpwindow',
	
	'topBottomEdge',

	'leftRightEdge',

	'middleMouseButton',
	
	'smoothness',
	
	'lblZoom',
	-- 'zoomintocursor',
	-- 'zoomoutfromcursor',
	'zoominfactor',
	'zoomin',
	'zoomoutfactor',
	'zoomout',
	'drifttocenter',
	'invertzoom',
	'invertalt',
	'tiltedzoom',
	'tiltzoomfactor',
	'zoomouttocenter',

	'lblRotate',
	'rotatefactor',
	'rotsmoothness',
	'targetmouse',
	-- 'rotateonedge',
	'inverttilt',
	'tiltfactor',
	'groundrot',
	
	'lblScroll',
	'speedFactor',
	'speedFactor_k',
	-- 'edgemove',
	'invertscroll',
	'smoothscroll',
	'smoothmeshscroll',
	
	'lblMisc',
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
	
	'label_controlgroups',
	'enableCycleView',
	'groupSelectionTapTimeout',

}

local OverviewAction = function() end
local OverviewSetAction = function() end
local GetDistForBounds = function(width, height, maxGroundHeight, edgeBufferProportion) end
local SetFOV = function(fov) end
local SelectNextPlayer = function() end
local ApplyCenterBounds = function(cs) end

options = {
	
	lblblank1 = {name='', type='label'},
	lblRotate = {name='Rotation Behaviour', type='label', path=rotatePath},
	lblScroll = {name='Scroll Behaviour', type='label', path=scrollPath},
	lblZoom = {name='Zoom Behaviour', type='label', path=zoomPath},
	lblMisc = {name='Misc.', type='label', path=miscPath},
	
	lblFollowCursor = {name='Cursor Following', type='label', path=cameraFollowPath},
	lblFollowCursorZoom = {name='Auto-Zooming', type='label', path=cameraFollowPath},
	lblFollowUnit = {name='Unit Following', type='label', path=cameraFollowPath},
	
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
		noHotkey = true,
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
		noHotkey = true,
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
		noHotkey = true,
		advanced = true,
	},
	smoothness = {
		name = 'Smoothness',
		desc = "Controls how smoothly the camera moves.",
		type = 'number',
		min = 0.0, max = 0.8, step = 0.1,
		value = 0.3,
		-- Applies to the following:
		-- 	Zoom()
		--	Altitude()
		--	SetFOV()
		--	edge screen scroll
		--	toggling zoomouttocenter
		--	and calls to SetCameraTarget() without passing in an explicit smoothness parameter
		--
		-- Smoothness for rotation and tilt are handled by the rotsmoothness option instead
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

	zoominfactor = { --should be lower than zoom-out-speed to help user aim tiny units
		name = 'Zoom-in speed',
		type = 'number',
		min = 0.1, max = 1, step = 0.05,
		value = 0.5,
		path = zoomPath,
	},
	zoomoutfactor = { --should be higher than zoom-in-speed to help user escape to bigger picture
		name = 'Zoom-out speed',
		type = 'number',
		min = 0.1, max = 1, step = 0.05,
		value = 0.8,
		path = zoomPath,
	},
	invertzoom = {
		name = 'Invert zoom',
		desc = 'Invert the scroll wheel direction for zooming.',
		type = 'bool',
		value = true,
		noHotkey = true,
		path = zoomPath,
	},
	invertalt = {
		name = 'Invert altitude',
		desc = 'Invert the scroll wheel direction for altitude.',
		type = 'bool',
		value = false,
		noHotkey = true,
		path = zoomPath,
	},
	zoomin = {
		name = 'Zoom In',
		type = 'radioButton',
		value = 'toCursor',
		items = {
			{key = 'toCursor', 		name='To Cursor'},
			{key = 'toCenter', 		name='To Screen Center'},
		},
		noHotkey = true,
		path = zoomPath,
	},
	zoomout = {
		name = 'Zoom Out',
		type = 'radioButton',
		value = 'fromCenter',
		items = {
			{key = 'fromCursor', 		name='From Cursor'},
			{key = 'fromCenter', 		name='From Screen Center'},
		},
		noHotkey = true,
		path = zoomPath,
	},
	zoomouttocenter = {
		name = 'Zoom out to center',
		desc = 'Center the map as you zoom out.',
		type = 'bool',
		value = true,
		OnChange = function(self)
			local cs = Spring.GetCameraState()
			if cs.rx then
				cs = ApplyCenterBounds(cs)
				-- Spring.SetCameraState(cs, options.smoothness.value)
				OverrideSetCameraStateInterpolate(cs,options.smoothness.value)
			end
		end,
		noHotkey = true,
		path = zoomPath,
	},
	drifttocenter = {
		name = 'Drift zoom target to center',
		desc = 'Moves object under cursor to screen center. Only works when zooming to cursor.',
		type = 'bool',
		value = true,
		noHotkey = true,
		path = zoomPath,
	},
	tiltedzoom = {
		name = 'Tilt camera while zooming',
		desc = 'Have the camera tilt while zooming. Camera faces ground when zoomed out, and looks out nearly parallel to ground when fully zoomed in',
		type = 'bool',
		value = true,
		noHotkey = true,
		path = zoomPath,
	},
	tiltzoomfactor = {
		name = 'Tilt amount',
		desc = 'How tilted the camera is when fully zoomed in. 0.1 is fully tilted, 2.0 is not tilted.',
		type = 'number',
		min = 0.1, max = 2, step = 0.1,
		value = 1.0,
		OnChange = function(self) SetFOV(options.fov.value) end,
		path = zoomPath,
	},

	rotatefactor = {
		name = 'Rotation speed',
		type = 'number',
		min = 0.5, max = 10, step = 0.5,
		value = 2,
		path = rotatePath,
	},
	rotsmoothness = {
		name = 'Rotation Smoothness',
		desc = "Controls how smoothly the camera rotates.",
		type = 'number',
		min = 0.0, max = 0.8, step = 0.1,
		value = 0.1,
		path = rotatePath,
	},
	-- rotateonedge = {
	-- 	name = "Rotate camera at edge",
	-- 	desc = "Rotate camera when the cursor is at the edge of the screen (edge scroll must be off).",
	-- 	type = 'bool',
	-- 	value = false,
	-- },
	-- restrictangle = {
	-- 	name = "Restrict Camera Angle",
	-- 	desc = "If disabled you can point the camera upward, but end up with strange camera positioning.",
	-- 	type = 'bool',
	-- 	advanced = true,
	-- 	value = true,
	-- 	OnChange = function(self) init = true; end,
	-- 	noHotkey = true,
	-- },
	targetmouse = {
		name = 'Rotate world origin at cursor',
		desc = 'Rotate world using origin at the cursor rather than the center of screen.',
		type = 'bool',
		value = true,
		noHotkey = true,
		path = rotatePath,
	},
	inverttilt = {
		name = 'Invert tilt',
		desc = 'Invert the tilt direction when using ctrl+mousewheel.',
		type = 'bool',
		value = false,
		noHotkey = true,
		path = rotatePath,
	},
	tiltfactor = {
		name = 'Tilt speed',
		type = 'number',
		min = 2, max = 40, step = 2,
		value = 10,
		path = rotatePath,
	},
	groundrot = {
		name = "Rotate When Camera Hits Ground",
		desc = "If world-rotation motion causes the camera to hit the ground, camera-rotation motion takes over. Doesn't apply in Free Mode.",
		type = 'bool',
		value = true,
		advanced = true,
		noHotkey = true,
		path = rotatePath,
	},

	speedFactor = {
		name = 'Mouse scroll speed',
		desc = 'This speed applies to scrolling with the middle button.',
		type = 'number',
		min = 10, max = 40,
		value = 25,
		path = scrollPath,
	},
	speedFactor_k = {
		name = 'Keyboard/edge scroll speed',
		desc = 'This speed applies to edge scrolling and keyboard keys.',
		type = 'number',
		min = 1, max = 50,
		value = 40,
		path = scrollPath,
	},
	invertscroll = {
		name = "Invert scrolling direction",
		desc = "Invert scrolling direction (doesn't apply to smoothscroll).",
		type = 'bool',
		value = true,
		noHotkey = true,
		path = scrollPath,
	},
	smoothscroll = {
		name = 'Smooth scrolling',
		desc = 'Use smoothscroll method when mouse scrolling.',
		type = 'bool',
		value = false,
		noHotkey = true,
		path = scrollPath,
	},
	smoothmeshscroll = {
		name = 'Smooth Mesh Scrolling',
		desc = 'A smoother way to scroll. Applies to all types of mouse/keyboard scrolling.',
		type = 'bool',
		value = true,
		noHotkey = true,
		path = scrollPath,
	},
    
	-- mingrounddist = {
	-- 	name = 'Minimum Ground Distance',
	-- 	desc = 'Getting too close to the ground allows strange camera positioning.',
	-- 	type = 'number',
	-- 	advanced = true,
	-- 	min = 0, max = 100, step = 1,
	-- 	value = 1,
	-- 	OnChange = function(self) init = true; end,
	-- },
	fov = {
		name = 'Field of View (Degrees)',
		--desc = "FOV (25 deg - 100 deg).",
		type = 'number',
		min = 10, max = 100, step = 5,
		value = Spring.GetCameraFOV(),
		springsetting = 'CamFreeFOV', --save stuff in springsetting. reference: epicmenu_conf.lua
		OnChange = function(self) SetFOV(self.value) end,
		path=miscPath,
	},
	overviewmode = {
		name = "COFC Overview",
		desc = "Go to overview mode, then restore view to cursor position.",
		type = 'button',
		hotkey = {key='tab', mod=''},
		OnChange = function(self) OverviewAction() end,
		path=miscPath,
	},
	overviewset = {
		name = "Set Overview Viewpoint",
		desc = "Save the current view as the new overview mode viewpoint. Use 'Reset Camera' to remove it.",
		type = 'button',
		OnChange = function(self) OverviewSetAction() end,
		path=miscPath,
	},
	rotatebackfromov = {
		name = "Rotate Back From Overview",
		desc = "When returning from overview mode, rotate the camera to its original position (only applies when you have set an overview viewpoint).",
		type = 'bool',
		value = true,
		noHotkey = true,
		path=miscPath,
	},
	resetcam = {
		name = "Reset Camera",
		desc = "Reset the camera position and orientation. Map a hotkey or use <Ctrl> + <Alt> + <Middleclick>",
		type = 'button',
        -- OnChange defined later
		path=miscPath,
	},
	freemode = {
		name = "FreeMode (risky)",
		desc = "Be free. Camera movement not bound to map edge. USE AT YOUR OWN RISK!\nTips: press TAB if you get lost.",
		type = 'bool',
		advanced = true,
		value = false,
		OnChange = function(self) init = true; end,
		noHotkey = true,
		path=miscPath,
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

				-- Spring.SetCameraState(cs,0)
				OverrideSetCameraStateInterpolate(cs,0)
			else
				Spring.SendCommands('trackoff')
				Spring.SendCommands('viewfree')
				thirdperson_trackunit = false
			end
        end,
	},
	
	
	label_controlgroups = {name='Pan To Cluster', type='label', path = 'Settings/Interface/Control Groups'},
	enableCycleView = {
		name = "Pan to cluster",
		type = 'bool',
		value = false,
		path = 'Settings/Interface/Control Groups',
		desc = "If you double-tap the group numbers (1,2,3 etc.) it will move the camera position to different clusters of units within the group rather than to the average position of the entire group.",
	},
	groupSelectionTapTimeout = {
		name = 'Pan to cluster tap timeout',
		desc = "How quickly do you have to double-tap group numbers to move the camera? Smaller timeout means faster tapping.",
		type = 'number',
		min = 0.0, max = 5.0, step = 0.1,
		value = 2.0,
		path = 'Settings/Interface/Control Groups',
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
local centerDriftFactor = 20/1080 * vsy
local horizAspectCorrectionFactor, vertAspectCorrectionFactor = 1, 1
if vsx > vsy then horizAspectCorrectionFactor = vsx/vsy
else vertAspectCorrectionFactor = vsy/vsx end

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	cx = vsx * 0.5
	cy = vsy * 0.5
	centerDriftFactor = 20/1080 * vsy
	horizAspectCorrectionFactor, vertAspectCorrectionFactor = 1, 1
	if vsx > vsy then
		horizAspectCorrectionFactor = vsx/vsy
	else
		vertAspectCorrectionFactor = vsy/vsx
	end
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

-- Mirrored in Interpolate.lua
-- local MWIDTH, MHEIGHT = Game.mapSizeX, Game.mapSizeZ
local minX, minZ, maxX, maxZ = 0, 0, MWIDTH, MHEIGHT
-- local mcx, mcz 	= MWIDTH / 2, MHEIGHT / 2
-- local mcy 		= spGetGroundHeight(mcx, mcz)
-- local maxDistY = max(MHEIGHT, MWIDTH) * 2
-- local mapEdgeBuffer = 1000

--Tilt Zoom constants
local onTiltZoomTrack = true
local lockPoint = {worldBegin = nil, worldEnd = nil, worldCenter = nil, world = nil, screen = nil, mode = nil}
local lastMouseX, lastMouseY
-- local zoomTime = 0
-- local zoomTimer

local groundMin, groundMax = Spring.GetGroundExtremes()
local topDownBufferZonePercent = 0.20
local groundBufferZone = 20
local topDownBufferZone = maxDistY * topDownBufferZonePercent
local minZoomTiltAngle = 35
local angleCorrectionMaximum = 5 * RADperDEGREE
-- local targetCenteringHeight = 1200
local mapEdgeProportion = 1.0/5.9  --map edge buffer is 1/5.9 of the length of the dimension fitted to screen
local currentFOVhalf_rad = 0

GetDistForBounds = function(width, height, maxGroundHeight, edgeBufferProportion, fov)
	if not edgeBufferProportion then edgeBufferProportion = mapEdgeProportion end

	local fittingDistance = height/2
	if vsy/vsx > height/width then fittingDistance = (width * vsy/vsx)/2 end
	local fittingEdge = fittingDistance/(1/(2 * edgeBufferProportion) - 1)
	local edgeBuffer = math.max(maxGroundHeight, fittingEdge)
	local totalFittingLength = fittingDistance + edgeBuffer

	return totalFittingLength/math.tan(currentFOVhalf_rad), edgeBuffer
end

SetFOV = function(fov)
	local cs = spGetCameraState()
	
	currentFOVhalf_rad = (fov/2) * RADperDEGREE
	maxDistY, mapEdgeBuffer = GetDistForBounds(MWIDTH, MHEIGHT, groundMax) --adjust maximum TAB/Overview distance based on camera FOV

	cs.fov = fov
	cs.py = overview_mode and maxDistY or math.min(cs.py, maxDistY)

	--Update Tilt Zoom Constants
	local tiltzoomfactor = options.tiltzoomfactor.value or 1.0
	topDownBufferZone = maxDistY * topDownBufferZonePercent
	minZoomTiltAngle = (30 + 17 * math.tan(currentFOVhalf_rad)) * RADperDEGREE * tiltzoomfactor

	if cs.name == "free" then
	  OverrideSetCameraStateInterpolate(cs,options.smoothness.value)
	else
	  spSetCameraState(cs,0)
	end
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

local function DetermineInitCameraState()
	local csOldpx, csOldpy, csOldpz = Spring.GetCameraPosition()
	local csOlddx, csOlddy, csOlddz = Spring.GetCameraDirection()
	local csOldrx = PI/2 - math.acos(csOlddy)
	local csOldry = math.atan2(csOlddx, -csOlddz) - PI
	spSendCommands("viewfree")
	local cs = spGetCameraState()
	-- if csOldpx == 0.0 * csOldpz == 0.0 then
	-- 	cs.px = MWIDTH/2
	-- 	cs.pz = MHEIGHT/2
	-- else
		cs.px = csOldpx
		cs.pz = csOldpz
	-- end
	cs.py = csOldpy
	cs.rx = csOldrx
	cs.ry = csOldry
	cs.rz = 0
	return cs
end

local function GetPyramidBoundedCoords(x,z) --This is meant for minX,minZ,maxX,maxZ bounds, to get bounds without necessarily changing camera state
	if x < minX then x = minX; end
	if x > maxX then x = maxX; end
	if z < minZ then z = minZ; end
	if z > maxZ then z = maxZ; end
	return x,z
end

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
	local maxZoom = max(abs(zox),abs(zoy),abs(zoz))
	--Limit speed
	maxZoom = min(maxZoom,limit)
	--Normalize
	local total = sqrt(zox^2+zoy^2+zoz^2)
	zox,zoy,zoz = zox/total,zoy/total,zoz/total
	--Reapply speed
	return zox*maxZoom,zoy*maxZoom,zoz*maxZoom
end

local function GetSmoothOrGroundHeight(x,z,checkFreeMode) --only ScrollCam seems to want to ignore this when FreeMode is on
	if options.smoothmeshscroll.value then
		return spGetSmoothMeshHeight(x, z) or 0
	else
		if not (checkFreeMode and options.freemode.value) then
			return spGetGroundHeight(x, z) or 0
		else
			-- in this case `x` and `z` might be off-map due to free mode
			-- however, GetGroundHeight still works fine (returns closest edge point)
			return spGetGroundHeight(x, z) or 0
		end
	end
end

local function GetMapBoundedGroundHeight(x,z)
	--out of map. Bound coordinate to within map
	x,z = GetMapBoundedCoords(x,z)
	return spGetGroundHeight(x,z)
end

local function GetMapBoundedSmoothOrGroundHeight(x,z)
	--out of map. Bound coordinate to within map
	x,z = GetMapBoundedCoords(x,z)
	return GetSmoothOrGroundHeight(x,z)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local scrnRay_cache = {result={0,0,0,0,0,0,0}, previous={fov=1,inclination=99,azimuth=299,x=9999,y=9999,plane=-100,sphere=-100}}
local function OverrideTraceScreenRay(x,y,cs,planeToHit,sphereToHit,returnRayDistance) --this function provide an adjusted TraceScreenRay for null-space outside of the map (by msafwan)
	local viewSizeY = vsy
	local viewSizeX = vsx
	if not vsy or not vsx then
		viewSizeX, viewSizeY = widgetHandler:GetViewSizes()
	end
	--//Speedup//--
	if scrnRay_cache.previous.fov==cs.fov
	and scrnRay_cache.previous.inclination == cs.rx
	and scrnRay_cache.previous.azimuth == cs.ry
	and scrnRay_cache.previous.x ==x
	and scrnRay_cache.previous.y == y
	and scrnRay_cache.previous.plane == planeToHit
	and scrnRay_cache.previous.sphere == sphereToHit
	then --if camera Sphere coordinate & mouse position not change then use cached value
		return scrnRay_cache.result[1],
		scrnRay_cache.result[2],
		scrnRay_cache.result[3],
		scrnRay_cache.result[4],
		scrnRay_cache.result[5],
		scrnRay_cache.result[6],
		scrnRay_cache.result[7]
	end
	local camPos = {px=cs.px,py=cs.py,pz=cs.pz}
	local camRot = {rx=cs.rx,ry=cs.ry,rz=cs.rz}
	local gx,gy,gz,rx,ry,rz,rayDist,cancelCache = TraceCursorToGround(viewSizeX,viewSizeY,{x=x,y=y} ,cs.fov, camPos, camRot,planeToHit,sphereToHit,returnRayDistance)
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
		scrnRay_cache.previous.fov = cs.fov
		scrnRay_cache.previous.plane = planeToHit
		scrnRay_cache.previous.sphere = sphereToHit
	end

	return gx,gy,gz,rx,ry,rz,rayDist
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

local function CorrectTraceTargetToSmoothMesh(cs,x,y,z)
	--We couldn't tell Spring to trace to the smooth mesh point, so compensate with vector multiplication
	local y_smooth = spGetSmoothMeshHeight(x, z) or 0
	local correction_vector_scale = (cs.py - y_smooth)/(cs.py - y)
	local dx, dz = cs.px - x, cs.pz - z
	y = y_smooth
	x, z = cs.px - dx * correction_vector_scale, cs.pz - dz * correction_vector_scale
	return x, y, z
end

--Note: If the x,y is not pointing at an onmap point, this function traces a virtual ray to an
--          offmap position using the camera direction and disregards the x,y parameters.
local function VirtTraceRay(x,y, cs)
	local _, gpos = spTraceScreenRay(x, y, true, false,false, true) --only coordinate, NOT thru minimap, NOT include sky, ignore water surface

	if gpos then
		local gx, gy, gz = gpos[1], gpos[2], gpos[3]
		
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
	local gx,gy,gz = OverrideTraceScreenRay(x,y,cs,nil,nil,nil) --use override if spTraceScreenRay() do not have results
	
	--gy = spGetSmoothMeshHeight (gx,gz)
	return false, gx, gy, gz
end

ApplyCenterBounds = function(cs, ignoreLockSpot)
	local csnew = spGetCameraState()
	CopyState(csnew, cs)
	-- if options.zoomouttocenter then Spring.Echo("zoomouttocenter.value: "..options.zoomouttocenter.value) end
	if options.zoomouttocenter.value --move camera toward center
	and (ls_x or ignoreLockSpot) --lockspot exist
	then

		scrnRay_cache.previous.fov = -999 --force reset cache (somehow cache value is used. Don't make sense at all...)

		local currentFOVhalf_rad = (csnew.fov/2) * RADperDEGREE
		local maxDc = math.max((maxDistY - csnew.py), 0)/(maxDistY - mapEdgeBuffer)-- * math.tan(currentFOVhalf_rad) * 1.5)
		-- Spring.Echo("MaxDC: "..maxDc)
		minX, minZ, maxX, maxZ = math.max(mcx - MWIDTH/2 * maxDc, 0), math.max(mcz - MHEIGHT/2 * maxDc, 0), math.min(mcx + MWIDTH/2 * maxDc, MWIDTH), math.min(mcz + MHEIGHT/2 * maxDc, MHEIGHT)

		local outOfBounds = false;
		if csnew.rx > -HALFPI + 0.002 then --If we are not facing stright down, do a full raycast
			local _,gx,gy,gz = VirtTraceRay(cx, cy, csnew)
			if gx < minX then csnew.px = csnew.px + (minX - gx); if ls_x then ls_x = ls_x + (minX - gx) end; outOfBounds = true end
			if gx > maxX then csnew.px = csnew.px + (maxX - gx); if ls_x then ls_x = ls_x + (maxX - gx) end; outOfBounds = true end
			if gz < minZ then csnew.pz = csnew.pz + (minZ - gz); if ls_z then ls_z = ls_z + (minZ - gz) end; outOfBounds = true end
			if gz > maxZ then csnew.pz = csnew.pz + (maxZ - gz); if ls_z then ls_z = ls_z + (maxZ - gz) end; outOfBounds = true end
		else --We can use camera x & z location in place of a raycast to find center when camera is pointed towards ground, as this is faster and more numerically stable
			if csnew.px < minX then csnew.px = minX; if ls_x then ls_x = minX end; outOfBounds = true end
			if csnew.px > maxX then csnew.px = maxX; if ls_x then ls_x = maxX end; outOfBounds = true end
			if csnew.pz < minZ then csnew.pz = minZ; if ls_z then ls_z = minZ end; outOfBounds = true end
			if csnew.pz > maxZ then csnew.pz = maxZ; if ls_z then ls_z = maxZ end; outOfBounds = true end
		end
		if outOfBounds and (ls_x and ls_y and ls_z) then ls_y = GetMapBoundedGroundHeight(ls_x, ls_z) end
	else
		minX, minZ, maxX, maxZ = 0, 0, MWIDTH, MHEIGHT
	end
	-- Spring.Echo("Bounds: "..minX..", "..minZ..", "..maxX..", "..maxZ)
	return csnew
end

local function ComputeLockSpotParams(cs, gx, gy, gz, onmap) --Only compute from what is sent in, otherwise use pre-existing values
	if gx then
		ls_x,ls_y,ls_z = gx,gy,gz
	end
	if ls_x then
		local px,py,pz = cs.px,cs.py,cs.pz
		local dx,dy,dz = ls_x-px, ls_y-py, ls_z-pz
		if onmap then
			ls_onmap = onmap
		end
		ls_dist = sqrt(dx*dx + dy*dy + dz*dz) --distance to ground coordinate
		ls_have = true
	end
end

local function SetLockSpot2(cs, x, y, useSmoothMeshSetting) --set an anchor on the ground for camera rotation
	if ls_have then --if lockspot is locked
		return
	end
	
	local x, y = x, y
	if not x then
		x, y = cx, cy --center of screen
	end

	local onmap, gx,gy,gz = VirtTraceRay(x, y, cs) --convert screen coordinate to ground coordinate

	if useSmoothMeshSetting then
		gx,gy,gz = CorrectTraceTargetToSmoothMesh(cs, gx,gy,gz)
	end
	ComputeLockSpotParams(cs, gx, gy, gz, onmap)
end


local function UpdateCam(cs)
	local cstemp = spGetCameraState()
	CopyState(cstemp, cs)
	if not (cstemp.rx and cstemp.ry and ls_dist) then
		--return cstemp
		return false
	end
	
	local alt = sin(cstemp.rx) * ls_dist
	local opp = cos(cstemp.rx) * ls_dist --OR same as: sqrt(ls_dist * ls_dist - alt * alt)
	cstemp.px = ls_x - sin(cstemp.ry) * opp
	cstemp.py = ls_y - alt
	cstemp.pz = ls_z - cos(cstemp.ry) * opp
	
	if not options.freemode.value then
		local gndheight = spGetGroundHeight(cstemp.px, cstemp.pz) + 10
		if cstemp.py < gndheight then --prevent camera from going underground
			if options.groundrot.value then
				cstemp.py = gndheight
			else
				return false
			end
		end
	end
	
	return cstemp
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
	local groundHeight = groundMin --GetMapBoundedGroundHeight(gx, gz) + groundBufferZone
	local skyProportion = math.min(math.max((cs.py - groundHeight)/((maxDistY - topDownBufferZone) - groundHeight), 0.0), 1.0)
	local targetRx = sqrt(skyProportion) * (minZoomTiltAngle - HALFPI) - minZoomTiltAngle

	-- Ensure angle correction only happens by parts if the angle doesn't match the target, unless it is within a threshold
	-- If it isn't, make sure the correction only happens in the direction of the curve.
	-- Zooming in shouldn't make the camera face the ground more, and zooming out shouldn't focus more on the horizon
	if zoomin ~= nil and rayDist then
		if onTiltZoomTrack or math.abs(targetRx - cs.rx) < angleCorrectionMaximum then
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

local lastZoomin
local function ZoomTiltCorrection(cs, zoomin, mouseX,mouseY, gx, gy, gz, storeTarget, explicitMouseCoords)
	local cstemp = spGetCameraState()
	CopyState(cstemp, cs)

	local rayDist = nil
	if gx then
		local dx, dy, dz = (cstemp.px - gx), (cstemp.py - gy), (cstemp.pz - gz)
		rayDist = math.sqrt(dx * dx + dy * dy + dz * dz)
	end
	local targetRx = GetZoomTiltAngle(gx, gz, cstemp, zoomin, rayDist)

	cstemp.rx = targetRx

	--
	--Set Interpolation Lock Point
	if (mouseX==nil) then
		mouseX,mouseY = mouseX or vsx/2,mouseY or vsy/2 --if NIL, revert to center of screen
	end

	--We need to get WorldToScreenCoords for computation to avoid the camera popping around, but WorldToScreenCoords drifts north on its own
	--so while WorldToScreenCoords is necessary, it should only happen when the mouse moves or zoom state changes
	local mouseMoved = true
	if lockPoint and lastMouseX and lastMouseY then
		mouseMoved = mouseX ~= lastMouseX and mouseY ~= lastMouseY
	end

	local fltMouseX, fltMouseY = 0, 0

	if storeTarget and (mouseMoved or lastZoomin ~= zoomin or not zoomin) then
		lastZoomin = zoomin
		if gx and not explicitMouseCoords then
			fltMouseX, fltMouseY = Spring.WorldToScreenCoords(gx, gy, gz)
		elseif explicitMouseCoords then
			fltMouseX, fltMouseY = mouseX, mouseY
		end
		lockPoint = {}
		lockPoint.worldBegin = {x = gx, y = gy, z = gz}
		lockPoint.screen = {x = fltMouseX, y = vsy - fltMouseY}
		lockPoint.mode = lockMode.xy
		mouseMoved = false
		lastMouseX = mouseX
		lastMouseY = mouseY
	elseif not storeTarget then
		lockPoint = {}
		lastMouseX = nil
		lastMouseY = nil
	end

	if storeTarget and options.zoomouttocenter.value and not zoomin then
		lockPoint.worldCenter = {x = gx, z = gz}
		if options.zoomout.value == 'fromCenter' then --Special case. For some reason it gets bouncy when done the same way as fromCursor
			lockPoint.mode = lockMode.xycenter
			lockPoint.screen = {x = cx, y = cy}
		end
	end
	--

	return cstemp
end

local function DriftToCenter(cs, gx, gy, gz, mx, my)
	if options.drifttocenter.value then
		mx = mx + (mx - vsx/2)/(vsx/2) * horizAspectCorrectionFactor * centerDriftFactor --Seems to produce the same apparent size on centered object independent of FOV
	 	my = my + (my - vsy/2)/(vsy/2) * vertAspectCorrectionFactor * centerDriftFactor
		local dirx, diry, dirz = Spring.GetPixelDir(mx, vsy - my)
		local distanceFactor = 0
		if diry ~= 0 then
			distanceFactor = (gy - cs.py) / diry
		end
		dirx = dirx * distanceFactor
		diry = diry * distanceFactor
		dirz = dirz * distanceFactor
		local screenTargetInWorld = {x = cs.px + dirx, y = cs.py + diry, z = cs.pz + dirz}
		local dx, dz = gx - screenTargetInWorld.x, gz - screenTargetInWorld.z
		gx = screenTargetInWorld.x
		gz = screenTargetInWorld.z
	end
	return gx, gz
end

local function SetCameraTarget(gx,gy,gz,smoothness,useSmoothMeshSetting,dist)

	--Note: this is similar to spSetCameraTarget() except we have control of the rules.
	--for example: native spSetCameraTarget() only work when camera is facing south at ~45 degree angle and camera height cannot have negative value (not suitable for underground use)
	if gx and gy and gz and not init then --just in case
		if smoothness == nil then smoothness = options.smoothness.value or 0 end
		local cs = GetTargetCameraState()
		SetLockSpot2(cs) --get lockspot at mid screen if there's none present
		if not ls_have then
			return
		end
		if dist then -- if a distance is specified, loosen bounds at first. They will be checked at the end
			ls_dist = dist
			ls_x, ls_y, ls_z = gx, gy, gz
		else -- otherwise, enforce bounds here to avoid the camera jumping around when moved with MMB or minimap over hilly terrain
			ls_x = min(max(gx, minX), maxX) --update lockpot to target destination
			ls_z = min(max(gz, minZ), maxZ)
			if useSmoothMeshSetting then
				ls_y = GetMapBoundedSmoothOrGroundHeight(ls_x, ls_z)
			else
				ls_y = GetMapBoundedGroundHeight(ls_x, ls_z)
			end
		end
		local cstemp = UpdateCam(cs)
		if options.tiltedzoom.value then
			if cstemp then
				if dist then
					lockPoint = {}
					_, x, y, z = VirtTraceRay(cx, cy, cs)
					cs = ZoomTiltCorrection(cstemp, cs.py > cstemp.py, cx, cy, ls_x, ls_y, ls_z, true, true)
					lockPoint.worldEnd = {x = ls_x, y = ls_y, z = ls_z}
					lockPoint.worldBegin = {x = x, y = y, z = z}
				else
					cs.rx = GetZoomTiltAngle(ls_x, ls_z, cstemp)
				end
				cstemp = UpdateCam(cs)
				if cstemp then cs = cstemp end
			end
		else
			if cstemp then cs = cstemp end
		end

		if not options.freemode.value then cs.py = min(cs.py, maxDistY) end --Ensure camera never goes higher than maxY

		-- spSetCameraState(cs, smoothness) --move
		if dist then
			OverrideSetCameraStateInterpolate(cs,smoothness, lockPoint)
		else
			cs = ApplyCenterBounds(cs)
			OverrideSetCameraStateInterpolate(cs,smoothness)
		end
		-- lastMouseX = nil
		lockPoint = {}
	end
end

local function SetCameraTargetBox(minX, minZ, maxX, maxZ, minDist, maxY, smoothness, useSmoothMeshSetting)
	if smoothness == nil then smoothness = options.smoothness.value or 0 end

	local x, z = (minX + maxX) / 2, (minZ + maxZ) / 2
	local y = GetMapBoundedGroundHeight(x, z)
	if not maxY then maxY = y end

	local dist = math.max(GetDistForBounds(math.abs(maxX - minX), math.abs(maxZ - minZ), maxY, mapEdgeProportion * 0.67), minDist)
	SetCameraTarget(x, y, z, smoothness, useSmoothMeshSetting or false, dist)
end

local function Zoom(zoomin, shift, forceCenter)
	local zoomin = zoomin
	if options.invertzoom.value then
		zoomin = not zoomin
	end

	local cs = GetTargetCameraState()

	--//ZOOMOUT FROM CURSOR, ZOOMIN TO CURSOR//--
	if
	(not forceCenter) and
	((zoomin and options.zoomin.value == 'toCursor') or ((not zoomin) and options.zoomout.value == 'fromCursor'))
	then
		local onmap, gx,gy,gz = VirtTraceRay(mx, my, cs)

		if gx then
			gx,gz = DriftToCenter(cs, gx, gy, gz, mx, my)
			if not options.freemode.value then
				gx,gz = GetMapBoundedCoords(gx,gz)
			end
		end

		if gx then
			dx = gx - cs.px
			dy = gy - cs.py
			dz = gz - cs.pz
		else
			return false
		end
		
		local sp = (zoomin and options.zoominfactor.value or -options.zoomoutfactor.value) * (shift and 3 or 1)
		-- Spring.Echo("Zoom Speed: "..sp)
		
		local zox,zoy,zoz = LimitZoom(dx,dy,dz,sp,2000)
		local new_px = cs.px + zox --a zooming that get slower the closer you are to the target.
		local new_py = cs.py + zoy
		local new_pz = cs.pz + zoz
		-- Spring.Echo("Zoom Speed Vector: ("..zox..", "..zoy..", "..zoz..")")

		local groundMinimum = GetMapBoundedGroundHeight(new_px, new_pz) + 20
		
		if not options.freemode.value then
			if new_py < groundMinimum then --zooming underground?
				sp = (groundMinimum - cs.py) / dy
				-- Spring.Echo("Zoom Speed at ground: "..sp)
				
				zox,zoy,zoz = LimitZoom(dx,dy,dz,sp,2000)
				new_px = cs.px + zox --a zooming that get slower the closer you are to the ground.
				new_py = cs.py + zoy
				new_pz = cs.pz + zoz
				-- Spring.Echo("Zoom Speed Vector: ("..zox..", "..zoy..", "..zoz..")")
			elseif (not zoomin) and new_py > maxDistY then --zoom out to space?
				sp = (maxDistY - cs.py) / dy
				-- Spring.Echo("Zoom Speed at sky: "..sp)

				zox,zoy,zoz = LimitZoom(dx,dy,dz,sp,2000)
				new_px = cs.px + zox --a zoom-out that get slower the closer you are to the ceiling?
				new_py = cs.py + zoy
				new_pz = cs.pz + zoz
				-- Spring.Echo("Zoom Speed Vector: ("..zox..", "..zoy..", "..zoz..")")
			end
			
		end

		if new_py == new_py then
			local boundedPy = (options.freemode.value and new_py) or min(max(new_py, groundMinimum), maxDistY - 10)
			cs.px = new_px-- * (boundedPy/math.max(new_py, 0.0001))
			cs.py = boundedPy
			cs.pz = new_pz-- * (boundedPy/math.max(new_py, 0.0001))

			--//SUPCOM camera zoom by Shadowfury333(Dominic Renaud):
			if options.tiltedzoom.value then
				cs = ZoomTiltCorrection(cs, zoomin, mx,my, gx, gy, gz, true)
			else
				lockPoint = {}
			end
		end
		--//

		ls_have = false
		
	else

		--//ZOOMOUT FROM CENTER-SCREEN, ZOOMIN TO CENTER-SCREEN//--
		local onmap, gx,gy,gz = VirtTraceRay(cx, cy, cs) --This doesn't seem to provide the exact center, thus later bounding
		
		if gx and not options.freemode.value then
			--out of map. Bound zooming to within map
			gx,gz = GetMapBoundedCoords(gx,gz)
			-- if not zoomin then gx, gz = GetPyramidBoundedCoords(gx, gz) end
		end

		ls_have = false --unlock lockspot
		ComputeLockSpotParams(cs, gx, gy, gz, onmap)

		if not ls_have then
			return
		end

		-- if not options.freemode.value and ls_dist >= maxDistY then
			-- return
		-- end
	    
		local sp = (zoomin and -options.zoominfactor.value or options.zoomoutfactor.value) * (shift and 3 or 1)
		
		local ls_dist_new = ls_dist + max(min(ls_dist*sp,2000),-2000) -- a zoom in that get faster the further away from target (limited to -+2000)
		ls_dist_new = max(ls_dist_new, 20)
		
		if not options.freemode.value and ls_dist_new > maxDistY - gy then --limit camera distance to maximum distance
			-- return
			ls_dist_new = maxDistY - gy
		end
		ls_dist = ls_dist_new

		local cstemp = UpdateCam(cs)

		if cstemp and options.tiltedzoom.value then
			cstemp = ZoomTiltCorrection(cstemp, zoomin, mx,my, gx, gy, gz, true)
			cstemp = UpdateCam(cstemp)
		else
			lockPoint = {}
		end
		
		if cstemp then cs = cstemp; end
	end

	local csbounded = ApplyCenterBounds(cs, not zoomin)
	if not zoomin then
		cs = csbounded
	end

	OverrideSetCameraStateInterpolate(cs,options.smoothness.value, lockPoint)

	return true
end


local function Altitude(up, s)
	ls_have = false
	onTiltZoomTrack = false
	
	local up = up
	if options.invertalt.value then
		up = not up
	end
	
	local cs = GetTargetCameraState()
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

	cs = ApplyCenterBounds(cs)

	lastMouseX = nil

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
	cs = ApplyCenterBounds(cs)
	-- spSetCameraState(cs, 0)
	OverrideSetCameraStateInterpolate(cs,0)
	ov_cs = nil

	lastMouseX = nil
	onTiltZoomTrack = true
end
options.resetcam.OnChange = ResetCam

OverviewSetAction = function()
	local cs = GetTargetCameraState()
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
		
		local cs = GetTargetCameraState()
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
		cs = ApplyCenterBounds(cs)

		local onmap, gx, gy, gz = VirtTraceRay(cx,cy,cs)
		lockPoint = {}
		lockPoint.worldBegin = {x = gx, y = gy, z = gz}
		lockPoint.worldEnd = {x = Game.mapSizeX/2, y = GetMapBoundedGroundHeight(Game.mapSizeX/2, Game.mapSizeZ/2), z = Game.mapSizeZ/2}
		lockPoint.screen = {x = cx, y = cy}
		lockPoint.mode = lockMode.xy
		lastMouseX = nil
		-- spSetCameraState(cs, 1)
		OverrideSetCameraStateInterpolate(cs,1,lockPoint)
	else --if in overview mode
		local cs = GetTargetCameraState()
		mx, my = spGetMouseState()
		local onmap, gx, gy, gz = VirtTraceRay(mx,my,cs) --create a lockstop point.
		if gx then --Note:  Now VirtTraceRay can extrapolate coordinate in null space (no need to check for onmap)
			local cs = GetTargetCameraState()
			cs.rx = last_rx
			if ov_cs and last_ry and options.rotatebackfromov.value then cs.ry = last_ry end
			ls_dist = last_ls_dist
			ls_x = gx
			ls_z = gz
			ls_y = gy
			ls_have = true
			local cstemp = UpdateCam(cs) --set camera position & orientation based on lockstop point
			if cstemp then cs = cstemp; end
			cs = ApplyCenterBounds(cs)

			lockPoint = {}
			lockPoint.worldBegin = {x = Game.mapSizeX/2, y = GetMapBoundedGroundHeight(Game.mapSizeX/2, Game.mapSizeZ/2), z = Game.mapSizeZ/2}
			lockPoint.worldEnd = {x = gx, y = gy, z = gz}
			lockPoint.screen = {x = cx, y = cy}
			lockPoint.mode = lockMode.xy
			lastMouseX = nil
			-- spSetCameraState(cs, 1)
			OverrideSetCameraStateInterpolate(cs,1,lockPoint)
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
				local cs = GetTargetCameraState()
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
		local cs = GetTargetCameraState()
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
		OverrideSetCameraStateInterpolate(cs,0, lockPoint)
		lastMouseX = nil
	end
	local teamID = Spring.GetLocalTeamID()
	local _, playerID = Spring.GetTeamInfo(teamID, false)
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

local function RotateCamera(x, y, dx, dy, smooth, lock, tilt)
	local cs = GetTargetCameraState()
	local cs1 = cs
	lastMouseX = nil
	if cs.rx then
		
		local trfactor = (tilt and options.tiltfactor.value or options.rotatefactor.value) / 2000
		cs.rx = cs.rx + dy * trfactor
		cs.ry = cs.ry - dx * trfactor
		
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
		OverrideSetCameraStateInterpolate(cs,smooth and options.rotsmoothness.value or 0)
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
				if UnitDefs[defID] and not UnitDefs[defID].isImmobile then
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
	lastMouseX = nil
	onTiltZoomTrack = false

	local cs = GetTargetCameraState()
	SetLockSpot2(cs)
	if not ls_have then
		return
	end
    local dir = dir * (options.inverttilt.value and -1 or 1)
    

	local speed = dir * (s and 30 or 10)
	RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, true, true) --smooth, lock, tilt

	return true
end

local function ScrollCam(cs, mxm, mym, smoothlevel)
	scrnRay_cache.previous.fov = -999 --force reset of offmap traceScreenRay cache. Reason: because offmap traceScreenRay use cursor position for calculation but scrollcam always have cursor at midscreen
	lastMouseX = nil
	SetLockSpot2(cs, nil, nil, true)
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

	-- The following code should be here and not in SetLockSpot2,
	-- but MouseMove springscroll (MMB scrolling, not smoothscroll)
	-- starts translating on all axes, rather than just x and z

	-- corrected, ls_x, ls_y, ls_z = CorrectTraceTargetToSmoothMesh(cs, ls_x, ls_y, ls_z)
	-- if corrected then ComputeLockSpotParams(cs) end

	local vecDist = (- cs.py) / cs.dy
	
	local ddx = (mxm * drx) + (mym * dfx)
	local ddz = (mxm * drz) + (mym * dfz)
	
	ls_x = ls_x + ddx
	ls_z = ls_z + ddz
	
	if not options.freemode.value then
		ls_x = min(ls_x, maxX-3) --limit camera movement, either to map area or (if options.zoomouttocenter.value is true) to a set distance from map center
		ls_x = max(ls_x, minX+3) --Do not replace with GetMapBoundedCoords or GetMapBoundedGroundHeight, those functions only (and should only) respect map area.
		
		ls_z = min(ls_z, maxZ-3)
		ls_z = max(ls_z, minZ+3)
	end
	
	ls_y = GetSmoothOrGroundHeight(ls_x, ls_z, true)

	local csnew = UpdateCam(cs)
	if csnew and options.tiltedzoom.value then
	  csnew.rx = GetZoomTiltAngle(ls_x, ls_z, csnew)
		csnew = UpdateCam(csnew)
	end
	if csnew then
		if not options.freemode.value then csnew.py = min(csnew.py, maxDistY) end --Ensure camera never goes higher than maxY
		csnew = ApplyCenterBounds(csnew) --Should be done since cs.py changes, but stops camera movement southwards. TODO: Investigate this.
    -- spSetCameraState(csnew, smoothlevel)
	OverrideSetCameraStateInterpolate(csnew,smoothlevel)
  end
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local missedMouseRelease = false
function widget:Update(dt)
	local framePassed = math.ceil(dt/0.0333) --estimate how many gameframe would've passes based on difference in time??
	
	if hideCursor then
		spSetMouseCursor('%none%')
	end

	local cs = spGetCameraState() --GetTargetCameraState()
	--//MISC
	fpsmode = cs.name == "fps"
	if init or ((cs.name ~= "free") and (cs.name ~= "ov") and not fpsmode) then
		-- spSendCommands("viewfree")
		cs = DetermineInitCameraState()

		init = false
		cs.tiltSpeed = 0
		cs.scrollSpeed = 0
		--cs.gndOffset = options.mingrounddist.value
		cs.gndOffset = options.freemode.value and 0 or 1 --this tell engine to block underground motion, ref: Spring\rts\Game\Camera\FreeController.cpp
		-- spSetCameraState(cs,0)
		if not initialBoundsSet then cs.py = maxDistY end

		OverrideSetCameraStateInterpolate(cs,0)

		if not initialBoundsSet then
			local oldzoomouttocenterValue = options.zoomouttocenter.value
			options.zoomouttocenter.value = false
			SetCameraTarget(MWIDTH/2, 10, MHEIGHT/2, 0)
			options.zoomouttocenter.value = oldzoomouttocenterValue
			if options.tiltedzoom.value then ResetCam() end
			initialBoundsSet = true
		end
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

	cs = GetTargetCameraState()
	
	local use_lockspringscroll = lockspringscroll and not springscroll

	local a,c,m,s = spGetModKeyState()

	local fpsCompensationFactor = (60 * dt) --Normalize to 60fps
    
	--//HANDLE ROTATE CAMERA
	if 	(not thirdperson_trackunit and  --block 3rd Person
	(rot.right or rot.left or rot.up or rot.down))
	then
		
		cs = GetTargetCameraState()

		local speed = (options.rotatefactor.value / 2000) * (s and 500 or 250) * fpsCompensationFactor

		if (rot.right or rot.left) and options.leftRightEdge.value == 'orbit' then
			SetLockSpot2(cs, vsx * 0.5, vsy * 0.5)
		end
		if rot.right then
			RotateCamera(vsx * 0.5, vsy * 0.5, speed, 0, true, ls_have, false)
		elseif rot.left then
			RotateCamera(vsx * 0.5, vsy * 0.5, -speed, 0, true, ls_have, false)
		end
		
		if (rot.up or rot.down) and options.topBottomEdge.value == 'orbit' then
			SetLockSpot2(cs, vsx * 0.5, vsy * 0.5)
		elseif options.topBottomEdge.value == 'rotate' then
			ls_have = false
		end
		if rot.up then
			RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, ls_have, false)
		elseif rot.down then
			RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true, ls_have, false)
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
		cs = GetTargetCameraState()
		
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
			local speed = math.max( options.speedFactor_k.value * (s and 3 or 1) * heightFactor * fpsCompensationFactor, 1 )
			
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
		
		cs = GetTargetCameraState()

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
					Spring.Echo("track retarget")
					OverrideSetCameraStateInterpolate(cs,0)
				end
			else --no unit selected: return to freeStyle camera
				spSendCommands('trackoff')
				spSendCommands('viewfree')
				thirdperson_trackunit = false
			end
		end
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
end

function widget:MouseMove(x, y, dx, dy, button)
	lastMouseX = nil
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
			RotateCamera(x, y, dx, dy, true, ls_have, false)
		end
		
		spWarpMouse(msx, msy)
		
		follow_timer = 0.6 --disable tracking for 1 second when middle mouse is pressed or when scroll is used for zoom
	elseif springscroll then

		-- if abs(dx) > 0 or abs(dy) > 0 then
		-- 	lockspringscroll = false
		-- end
		local dir = options.invertscroll.value and -1 or 1

		local cs = GetTargetCameraState()
		
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
	
	local cs = GetTargetCameraState()
	
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
		-- lockspringscroll = not lockspringscroll
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
		
			local cs = GetTargetCameraState()
			SetLockSpot2(cs)
			if not ls_have then
				return
			end
			

		
			local speed = (modifier.shift and 30 or 10)

			if key == key_code.right then 		RotateCamera(vsx * 0.5, vsy * 0.5, speed, 0, true, not modifier.alt, false)
			elseif key == key_code.left then 	RotateCamera(vsx * 0.5, vsy * 0.5, -speed, 0, true, not modifier.alt, false)
			elseif key == key_code.down then 	onTiltZoomTrack = false; RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true, not modifier.alt, false)
			elseif key == key_code.up then 		onTiltZoomTrack = false; RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, not modifier.alt, false)
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

function widget:DrawScreenEffects(vsx, vsy)
	--placed here so that its always called even when GUI is hidden
	Interpolate()
end

local screenFrame = 0
function widget:DrawScreen()
	SetSkyBufferProportion()

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

	if WG.crude then
		if WG.crude.GetHotkey then
			epicmenuHkeyComp[1] = WG.crude.GetHotkey("toggleoverview")
			epicmenuHkeyComp[2] = WG.crude.GetHotkey("trackmode")
			epicmenuHkeyComp[3] = WG.crude.GetHotkey("track")
			epicmenuHkeyComp[4] = WG.crude.GetHotkey("mousestate")
		end
		if WG.crude.SetHotkey then
			WG.crude.SetHotkey("toggleoverview",nil)
			WG.crude.SetHotkey("trackmode",nil)
			WG.crude.SetHotkey("track",nil)
			WG.crude.SetHotkey("mousestate",nil)
		end
	end

	WG.COFC_Enabled = true
	WG.COFC_SetCameraTarget = SetCameraTarget
	WG.COFC_SetCameraTargetBox = SetCameraTargetBox

	--for external use, so that minimap can scale when zoomed out
	WG.COFC_SkyBufferProportion = 0
	
	if WG.SetWidgetOption then
		WG.SetWidgetOption("Settings/Camera","Settings/Camera","Camera Type","COFC") --tell epicmenu.lua that we select COFC as our default camera (since we enabled it!)
	end

end

function widget:Shutdown()
	spSendCommands{"viewta"}

	if WG.crude and WG.crude.SetHotkey then
		WG.crude.SetHotkey("toggleoverview",epicmenuHkeyComp[1])
		WG.crude.SetHotkey("trackmode",epicmenuHkeyComp[2])
		WG.crude.SetHotkey("track",epicmenuHkeyComp[3])
		WG.crude.SetHotkey("mousestate",epicmenuHkeyComp[4])
	end

	WG.COFC_SetCameraTarget = nil
	WG.COFC_SkyBufferProportion = nil
	WG.COFC_Enabled = nil
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
			local cs = GetTargetCameraState()
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
	[KEYSYMS.N_0] = 0,
}

function WG.COFC_UpdateGroupNumbers(newNumber)
	groupNumber = newNumber
end

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
					SetCameraTarget(meanX, meanY, meanZ,0.5,true)
				else
					local unitID = lonely[currentIteration-#cluster]
					local slctUnit = slctUnitUnordered[unitID]
					if slctUnit ~= nil then --nil check. There seems to be a race condition or something which causes this unit to be nil sometimes
						local x,y,z= slctUnit[1],slctUnit[2],slctUnit[3] --// get stored unit position
						SetCameraTarget(x,y,z,0.5,true)
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
				SetCameraTarget(meanX, meanY, meanZ,0.5,true) --is overriden by Spring.SetCameraTarget() at cache.lua.
			end
			previousGroup= group
			return true
		end
	end
end
