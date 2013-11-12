--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Combo Overhead/Free Camera (experimental)",
    desc      = "v0.128 Camera featuring 6 actions. Type \255\90\90\255/luaui cofc help\255\255\255\255 for help.",
    author    = "CarRepairer, msafwan",
    date      = "2011-03-16", --2013-November-12
    license   = "GNU GPL, v2 or later",
    layer     = 1002,
	handler   = true,
    enabled   = false,
  }
end

include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local init = true
local trackmode = false --before options
local thirdperson_trackunit = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/Camera/Camera Controls'
local cameraFollowPath = 'Settings/Camera/Camera Following'
options_order = { 
	'helpwindow', 
	
	'lblRotate',
	'targetmouse', 
	'rotateonedge', 
	'rotfactor',
    'inverttilt',
    'groundrot',
	
	'lblScroll',
	'edgemove', 
	'smoothscroll',
	'speedFactor', 
	'speedFactor_k', 
	'invertscroll', 
	'smoothmeshscroll', 
	
	'lblZoom',
	'invertzoom', 
	'invertalt', 
	'zoomintocursor', 
	'zoomoutfromcursor', 
	'zoomouttocenter', 
	'zoominfactor', 
	'zoomoutfactor',
	
	'lblMisc',
	'overviewmode', 
	'overviewset',
	'rotatebackfromov',
	'smoothness',
	'fov',
	--'restrictangle',
	--'mingrounddist',
	'freemode',
	'resetcam',
	
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

}

local OverviewAction = function() end
local OverviewSetAction = function() end
local SetFOV = function(fov) end
local SelectNextPlayer = function() end

options = {
	
	lblblank1 = {name='', type='label'},
	lblRotate = {name='Rotation', type='label'},
	lblScroll = {name='Scrolling', type='label'},
	lblZoom = {name='Zooming', type='label'},
	lblMisc = {name='Misc.', type='label'},
	
	lblFollowCursor = {name='Cursor Following', type='label', path=cameraFollowPath},
	lblFollowCursorZoom = {name='Auto-Zooming', type='label', path=cameraFollowPath},
	lblFollowUnit = {name='Unit Following', type='label', path=cameraFollowPath},
	lblMisc2 = {name='Misc.', type='label', path = cameraFollowPath},
	
	
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
		value = true,
	},
	smoothmeshscroll = {
		name = 'Smooth Mesh Scrolling',
		desc = 'A smoother way to scroll. Applies to all types of mouse/keyboard scrolling.',
		type = 'bool',
		value = false,
	},
	
	targetmouse = {
		name = 'Rotate world origin at cursor',
		desc = 'Rotate world using origin at the cursor rather than the center of screen.',
		type = 'bool',
		value = true,
	},
	edgemove = {
		name = 'Scroll camera at edge',
		desc = 'Scroll camera when the cursor is at the edge of the screen.',
		springsetting = 'WindowedEdgeMove',
		type = 'bool',
		value = true,
		
	},
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
		value = 20,
	},
	zoominfactor = {
		name = 'Zoom-in speed',
		type = 'number',
		min = 0.1, max = 0.5, step = 0.05,
		value = 0.2,
	},
	zoomoutfactor = {
		name = 'Zoom-out speed',
		type = 'number',
		min = 0.1, max = 0.5, step = 0.05,
		value = 0.2,
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
    
	zoomoutfromcursor = {
		name = 'Zoom out from cursor',
		desc = 'Zoom out from the cursor rather than center of the screen.',
		type = 'bool',
		value = false,
	},
	zoomintocursor = {
		name = 'Zoom in to cursor',
		desc = 'Zoom in to the cursor rather than the center of the screen.',
		type = 'bool',
		value = true,
	},
	zoomouttocenter = {
		name = 'Zoom out to center',
		desc = 'Center the map as you zoom out.',
		type = 'bool',
		value = false,
	},

	rotfactor = {
		name = 'Rotation speed',
		type = 'number',
		min = 0.001, max = 0.020, step = 0.001,
		value = 0.005,
	},	
	rotateonedge = {
		name = "Rotate camera at edge",
		desc = "Rotate camera when the cursor is at the edge of the screen (edge scroll must be off).",
		type = 'bool',
		value = false,
	},
    
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
		value = false,
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
		value = false,
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
		desc = "If you tap the group numbers (1,2,3..ect) it will focus camera view toward the cluster of unit rather than toward the average position.",
		OnChange = function(self) 
			if self.value==true then
				Spring.SendCommands("luaui enablewidget Receive Units Indicator")
			end
		end,
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vsx, vsy = widgetHandler:GetViewSizes()
local cx,cy = vsx * 0.5,vsy * 0.5
function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	cx = vsx * 0.5
	cy = vsy * 0.5
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


local mwidth, mheight = Game.mapSizeX, Game.mapSizeZ
local averageEdgeHeight = 0
local mcx, mcz 	= mwidth / 2, mheight / 2
local mcy 		= spGetGroundHeight(mcx, mcz)
local maxDistY = max(mheight, mwidth) * 2
do
	local northEdge = spGetGroundHeight(mwidth/2,0)
	local eastEdge = spGetGroundHeight(0,mheight/2)
	local southEdge = spGetGroundHeight(mwidth/2,mheight)
	local westEdge = spGetGroundHeight(mwidth,mheight/2)
	averageEdgeHeight =(northEdge+eastEdge+southEdge+westEdge)/4 --is used for estimating coordinate in null space
	
	local currentFOVhalf_rad = (Spring.GetCameraFOV()/2)*PI/180
	local mapLenght = (max(mheight, mwidth)+4000)/2
	maxDistY =  mapLenght/math.tan(currentFOVhalf_rad) --adjust TAB/Overview distance based on camera FOV
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local rotate_transit --switch for smoothing "rotate at mouse position instead of screen center"
local last_move = spGetTimer() --switch for reseting lockspot for Edgescroll
local thirdPerson_transit = spGetTimer() --switch for smoothing "3rd person trackmode edge screen scroll"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local scrnRay_previousFov=-1
local scrnRay_prevInclination =99
local scrnRay_prevAzimuth = 299
local scrnRay_prevX = 9999
local scrnRay_prevY = 9999
local scrnRay_cachedResult = {0,0,0}
local function OverrideTraceScreenRay(x,y,cs) --this function provide an adjusted TraceScreenRay for null-space outside of the map (by msafwan)
	local halfViewSizeY = vsy/2
	local halfViewSizeX = vsx/2
	y = y- halfViewSizeY --convert screen coordinate to 0,0 at middle
	x = x- halfViewSizeX
	local currentFov = cs.fov/2 --in Spring: 0 degree is directly ahead and +FOV/2 degree to the left and -FOV/2 degree to the right
	--//Speedup//--
	if scrnRay_previousFov==currentFov and scrnRay_prevInclination == cs.rx and scrnRay_prevAzimuth == cs.ry and scrnRay_prevX ==x and scrnRay_prevY == y then --if camera Sphere coordinate & mouse position not change then use cached value
		return scrnRay_cachedResult[1],scrnRay_cachedResult[2],scrnRay_cachedResult[3] 
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
	local sphere_x = 100* sin(azimuth)* cos(inclination) --convert Sphere coordinate back to Cartesian coordinate to prepare for rotation procedure
	local sphere_y = 100* sin(inclination)
	local sphere_z = 100* cos(azimuth)* cos(inclination)
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
	
	--//Sphere-to-groundPosition translation//--
	--(calculate intercept of ray from mouse to a flat ground)
	local tiltSign = abs(cursorTilt)/cursorTilt --Sphere's inclination direction (positive upward or negative downward)
	local cursorTiltComplement = (PI/2-abs(cursorTilt))*tiltSign --return complement angle for cursorTilt. Note: we use 0 degree when look down, and 90 degree when facing the horizon. This simplify the problem conceptually. 
	cursorTiltComplement = min(1.5550425,abs(cursorTiltComplement))*tiltSign --limit to 89 degree to prevent infinity in math.tan() 
	local vertGroundDist = averageEdgeHeight-cs.py --distance to ground
	local groundDistSign = abs(vertGroundDist)/vertGroundDist --negative when ground is below, positive when ground is above
	local cursorxzDist = math.tan(cursorTiltComplement)*(vertGroundDist) --calculate how far does the camera angle look pass the ground beneath
	if groundDistSign + tiltSign == 0 then ---handle a special case when camera is facing away from ground.
		cursorxzDist = cursorxzDist*-1 --Note: Not sure how it manage to work, except it work.
	end
	local cursorxDist = sin(cs.ry+cursorHeading)*cursorxzDist --break down the ground beneath into x and z component.  Note: using Sin() instead of regular Cos() because coordinate & angle is left handed (?)
	local cursorzDist = cos(cs.ry+cursorHeading)*cursorxzDist
	local gx, gy, gz = cs.px+cursorxDist,averageEdgeHeight,cs.pz+cursorzDist --estimated ground position infront of camera 
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
	end
	--//caching for efficiency
	scrnRay_cachedResult[1] = gx
	scrnRay_cachedResult[2] = gy
	scrnRay_cachedResult[3] = gz
	scrnRay_prevInclination =cs.rx
	scrnRay_prevAzimuth = cs.ry
	scrnRay_prevX = x
	scrnRay_prevY = y
	scrnRay_previousFov = currentFov	

	return gx,gy,gz
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
	
	if gx2 > mwidth + extra then
		ddx = mwidth + extra - gx1
	elseif gx2 < 0 - extra then
		ddx = -gx1 - extra
	end
	
	if gz2 > mheight + extra then
		ddz = mheight - gz1 + extra
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
	local _, gpos = spTraceScreenRay(x, y, true)

	if gpos then
		local gx, gy, gz = gpos[1], gpos[2], gpos[3]
		
		--gy = spGetSmoothMeshHeight (gx,gz)
		
		if gx < 0 or gx > mwidth or gz < 0 or gz > mheight then --out of map
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
	local gx,gy,gz = OverrideTraceScreenRay(x,y,cs) --use override if spTraceScreenRay() do not have results
	
	--gy = spGetSmoothMeshHeight (gx,gz)
	return false, gx, gy, gz
end

local function SetLockSpot2(cs, x, y) --set an anchor on the ground for camera rotation 
	if ls_have then --if lockspot is locked
		return
	end
	
	local x, y = x, y
	if not x then
		x, y = cx, cy --center of screen
	end

	--local gpos
	--_, gpos = spTraceScreenRay(x, y, true)
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
		local gndheight = spGetGroundHeight(cs.px, cs.pz)+5
		--gndheight = spGetSmoothMeshHeight(cs.px, cs.pz)+5
		if cs.py < gndheight then
			if options.groundrot.value then
				cs.py = gndheight
			else
				return false
			end
		end
	end
	
	return cs
end

local function SetCameraTarget(gx,gy,gz,smoothness)
	--Note: this is similar to spSetCameraTarget() except we have control of the rules.
	--for example: native spSetCameraTarget() only work when camera is facing south at ~45 degree angle and camera height cannot have negative value (not suitable for underground use)
	if gx and gy and gz and smoothness then --just in case
		local cs = spGetCameraState()
		SetLockSpot2(cs) --get lockspot at mid screen if there's none present
		if not ls_have then
			return
		end
		ls_x = gx --update lockpot to target destination
		ls_y = gy
		ls_z = gz
		local cstemp = UpdateCam(cs)
		if cstemp then cs = cstemp; end
		spSetCameraState(cs, smoothness) --move
	end
end

local function Zoom(zoomin, shift, forceCenter)
	local zoomin = zoomin
	if options.invertzoom.value then
		zoomin = not zoomin
	end

	local cs = spGetCameraState()
	-- [[
	if
	(not forceCenter) and
	((zoomin and options.zoomintocursor.value) or ((not zoomin) and options.zoomoutfromcursor.value)) --zoom to cursor or zoom-out from cursor
	then
		
		local onmap, gx,gy,gz = VirtTraceRay(mx, my, cs)
		
		if gx and not options.freemode.value then
			--out of map. Bound zooming to within map
			if gx < 0 then gx = 0; end
			if gx > mwidth then gx=mwidth; end
			if gz < 0 then gz = 0; end 
			if gz > mheight then gz = mheight; end  
		end
		
		if gx then
			dx = gx - cs.px
			dy = gy - cs.py
			dz = gz - cs.pz
		else
			return false
		end
		
		local sp = (zoomin and options.zoominfactor.value or -options.zoomoutfactor.value) * (shift and 3 or 1)
		
		local new_px = cs.px + dx * sp --a zooming that get slower the closer you are to the target.
		local new_py = cs.py + dy * sp
		local new_pz = cs.pz + dz * sp
		
		if not options.freemode.value then
			if new_py < spGetGroundHeight(cs.px, cs.pz)+5 then --zooming underground?
				sp = (spGetGroundHeight(cs.px, cs.pz)+5 - cs.py) / dy
				new_px = cs.px + dx * sp --a zooming that get slower the closer you are to the ground.
				new_py = cs.py + dy * sp
				new_pz = cs.pz + dz * sp
			elseif (not zoomin) and new_py > maxDistY then --zoom out to space?
				sp = (maxDistY - cs.py) / dy
				new_px = cs.px + dx * sp --a zoom-out that get slower the closer you are to the ceiling?
				new_py = cs.py + dy * sp
				new_pz = cs.pz + dz * sp
			end
			
		end
		
		cs.px = new_px
		cs.py = new_py
		cs.pz = new_pz
		
		spSetCameraState(cs, options.smoothness.value)
		ls_have = false
		return
		
	end
	--]]
	ls_have = false --unlock lockspot 
	SetLockSpot2(cs) --set lockspot
	if not ls_have then
		return
	end
    
	-- if zoomin and not ls_onmap then --prevent zooming into null area (outside map)
		-- return
	-- end
    
	local sp = (zoomin and -options.zoominfactor.value or options.zoomoutfactor.value) * (shift and 3 or 1)
	
	local ls_dist_new = ls_dist + ls_dist*sp -- a zoom in that get faster the further away from target
	ls_dist_new = max(ls_dist_new, 20)
	ls_dist_new = min(ls_dist_new, maxDistY)
	
	ls_dist = ls_dist_new

	local cstemp = UpdateCam(cs)
	if cstemp then cs = cstemp; end
	if (not zoomin and options.zoomouttocenter.value) then
		local dcx = mcx - ls_x -- distance in x-z plane from center of map to center of view (x-axis)
		local dcz = mcz - ls_z -- distance in x-z plane from center of map to center of view (z-axis)
--		Spring.Echo ("maxDistY: " .. maxDistY .. " cs.py: " .. cs.py .. " dcx: " .. dcx .. " dcz: " .. dcz)
		local csp = math.min((cs.py/(maxDistY*2/3)),1) ^ 2
--		Spring.Echo ("csp: " .. csp)
		cs.px = cs.px + dcx * csp
		cs.pz = cs.pz + dcz * csp
	end
	if zoomin or ls_dist < maxDistY then
		spSetCameraState(cs, options.smoothness.value)
	end

	return true
end


local function Altitude(up, s)
	ls_have = false
	
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
	spSetCameraState(cs, options.smoothness.value)
	return true
end
--==End camera utility function^^ (a frequently used function. Function often used for controlling camera).


SetFOV = function(fov)
	local cs = spGetCameraState()
	cs.fov = fov
    spSetCameraState(cs,0)
	Spring.Echo(fov .. " degree")
	
	local currentFOVhalf_rad = (fov/2)*PI/180
	local mapLenght = (max(mheight, mwidth)+4000)/2
	maxDistY =  mapLenght/math.tan(currentFOVhalf_rad) --adjust maximum TAB/Overview distance based on camera FOV
end

local function ResetCam()
	local cs = spGetCameraState()
	cs.px = Game.mapSizeX/2
	cs.py = maxDistY
	cs.pz = Game.mapSizeZ/2
	cs.rx = -HALFPI
	cs.ry = PI
	spSetCameraState(cs, 1)
	ov_cs = nil
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
		spSetCameraState(cs, 1)
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
			spSetCameraState(cs, 1)
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
				spSetCameraState(cs,0)
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
		local cstemp = UpdateCam(cs)
		if cstemp then cs = cstemp; end
		spSetCameraState(cs, smoothness) --track & zoom
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
        if trackmode then --always rotate world instead of camera in trackmode
            lock = true
            ls_have = false
            SetLockSpot2(cs)
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
		spSetCameraState(cs, smooth and options.smoothness.value or 0)
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
	spSetCameraState(cs,0)
	thirdPerson_transit = spGetTimer() --block access to edge scroll until camera focus on unit
end

local function Tilt(s, dir)
	if not tilting then
		ls_have = false	
	end
	tilting = true
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
	scrnRay_prevX=9999 --force reset of offmap traceScreenRay cache. Reason: because offmap traceScreenRay use cursor position for calculation & scrollcam always have cursor at midscreen
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
		ls_x = min(ls_x, mwidth-3) --limit camera movement to map area
		ls_x = max(ls_x, 3)
		
		ls_z = min(ls_z, mheight-3)
		ls_z = max(ls_z, 3)
	end
	
	if options.smoothmeshscroll.value then
		ls_y = spGetSmoothMeshHeight(ls_x, ls_z) or 0
	else
		ls_y = spGetGroundHeight(ls_x, ls_z) or 0
	end
	
	
	local csnew = UpdateCam(cs)
	if csnew then
        spSetCameraState(csnew, smoothlevel)
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
		
		local speed = options.rotfactor.value * (s and 400 or 150)
		if rot.right then
			RotateCamera(vsx * 0.5, vsy * 0.5, speed, 0, true)
		elseif rot.left then
			RotateCamera(vsx * 0.5, vsy * 0.5, -speed, 0, true)
		end
		
		if rot.up then
			RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true)
		elseif rot.down then
			RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true)
		end
		
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
	if options.edgemove.value then
		move2.right = false --reset mouse move state
		move2.left = false
		move2.up = false
		move2.down = false
		
		if mx > vsx-2 then 
			move2.right = true
		elseif mx < 2 then
			move2.left = true
		end
		if my > vsy-2 then
			move2.up = true
		elseif my < 2 then
			move2.down = true
		end
		
	elseif options.rotateonedge.value then
		rot = {}
		if mx > vsx-2 then 
			rot.right = true 
		elseif mx < 2 then
			rot.left = true
		end
		if my > vsy-2 then
			rot.up = true
		elseif my < 2 then
			rot.down = true
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
					spSetCameraState(cs,0)
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
		spSetCameraState(cs,0)
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
	if a then
		spWarpMouse(cx, cy)
		ls_have = false
		rotate = true
		return true
	end
	-- Rotate World --
	if ctrl then
		rotate_transit = nil
		if options.targetmouse.value then --if rotate world at mouse cursor: 
			
			local onmap, gx, gy, gz = VirtTraceRay(x,y, cs)
			if gx then  --Note: we don't block offmap position since VirtTraceRay() now work for offmap position.
				SetLockSpot2(cs,x,y) --set lockspot at cursor position
				SetCameraTarget(gx,gy,gz,1)
				
				--//update "ls_dist" with value from mid-screen's LockSpot because rotation is centered on mid-screen and not at cursor//--
				_,gx,gy,gz = VirtTraceRay(cx,cy,cs) --get ground position traced from mid of screen
				local dx,dy,dz = gx-cs.px, gy-cs.py, gz-cs.pz
				ls_dist = sqrt(dx*dx + dy*dy + dz*dz) --distance to ground 
				
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
			elseif key == key_code.down then 	RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true, not modifier.alt)
			elseif key == key_code.up then 		RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true, not modifier.alt)
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

function widget:DrawScreen()
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
	if smoothscroll or (rotate and ls_have) then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows-dot.png')
	elseif rotate or lockspringscroll or springscroll then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows.png')
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
		
		if not (springscroll and not lockspringscroll) then
		    hideCursor = true
		end
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
			spSetCameraState(cs,0)
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
				return false
			end
			for i=1,#selectedUnit do
				local unitGroup = spGetUnitGroup(selectedUnit[i])
				if unitGroup~=group then
					return false
				end
			end
			if previousKey == key and (spDiffTimers(spGetTimer(),previousTime) > 2) then
				currentIteration = 0 --reset cycle if delay between 2 similar tap took too long.
			end
			previousKey = key
			previousTime = spGetTimer()
			
			if options.enableCycleView.value then 
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
				else
					currentIteration = 1
				end
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
					local x,y,z= slctUnitUnordered[unitID][1],slctUnitUnordered[unitID][2],slctUnitUnordered[unitID][3] --// get stored unit position
					SetCameraTarget(x,y,z,0.5)
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
