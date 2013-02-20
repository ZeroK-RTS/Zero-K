--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Combo Overhead/Free Camera (experimental)",
    desc      = "v0.109 Camera featuring 6 actions. Type \255\90\90\255/luaui cofc help\255\255\255\255 for help.",
    author    = "CarRepairer",
    date      = "2011-03-16", --2013-02-13 (msafwan)
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

options_path = 'Settings/Camera/Advanced Camera Config'
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
	'zoominfactor', 
	'zoomoutfactor',
	'followautozoom',	
	
	'lblMisc',
	'overviewmode', 
	'follow',
	'smoothness',
	'fov',
	--'restrictangle',
	--'mingrounddist',
	'freemode',
	
	'trackmode',
	'persistenttrackmode',
	'thirdpersontrack',
	'thirdpersonedgescroll',

	'resetcam',
	
	'enableCycleView',

}

local OverviewAction = function() end
local SetFOV = function(fov) end

options = {
	
	lblblank1 = {name='', type='label'},
	lblRotate = {name='Rotation', type='label'},
	lblScroll = {name='Scrolling', type='label'},
	lblZoom = {name='Zooming', type='label'},
	lblMisc = {name='Misc.', type='label'},
	
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
		value = false,
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
	follow = {
		name = "Follow player's cursor",
		desc = "Follow the cursor of the player you're spectating (needs Ally Cursor widget to be on). \n\nSee \"Advanced Camera Config\" (under Zoom subsection) to enable automatic Zoom option. ",
		type = 'bool',
		value = false,
		hotkey = {key='l', mod='alt+'},
		path = 'Settings/Camera',
	},
	followautozoom = {
		name = "Auto zoom while follow cursor",
		desc = "COFC will auto zoom in & out while in follow cursor mode (zoom level will represent player's focus). Work best using low to moderate zoom speed.",
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
		desc = "Be free. Camera movement not bound to map edge. USE AT YOUR OWN RISK!",
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
		name = "Overview",
		desc = "Go to overview mode, then restore view to cursor position.",
		type = 'button',
		hotkey = {key='tab', mod=''},
		OnChange = function(self) OverviewAction() end,
	},
	
	trackmode = {
		name = "Enter Trackmode",
		desc = "Track the selected unit (midclick to cancel)",
		type = 'button',
        hotkey = {key='t', mod='alt+'},
		OnChange = function(self) trackmode = true; end,
	},
	
	persistenttrackmode = {
		name = "Persistent trackmode state",
		desc = "Trackmode will not cancel unless user press midclick",
		type = 'bool',
		value = false,
	},
    
    thirdpersontrack = {
		name = "Enter 3rd Person Trackmode",
		desc = "Track the selected unit (midclick to cancel)",
		type = 'button',
		hotkey = {key='k', mod='alt+'},
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
    
 	thirdpersonedgescroll = {
		name = "3rd Person Trackmode Retarget",
		desc = "When in 3rd Person Trackmode, use the arrow keys to follow a nearby unit.",
		type = 'bool',
		value = true,
	},
	resetcam = {
		name = "Reset Camera",
		desc = "Reset the camera position and orientation. Map a hotkey or use <Ctrl> + <Alt> + <Shift> + <Middleclick>",
		type = 'button',
        -- OnChange defined later
	},
	
	groundrot = {
		name = "Rotate When Camera Hits Ground",
		desc = "If world-rotation motion causes the camera to hit the ground, camera-rotation motion takes over. Doesn't apply in Free Mode.",
		type = 'bool',
		value = false,
	},
	
	enableCycleView = {
		name = "Group recall cycle within group",
		type = 'bool',
		value = false,
		path='Settings/Camera',
		desc = "Cycle camera focus among group units when same number is pressed more than once. Note: This option will automatically enable \'Receive Indicator\' widget (for its cluster detection feature).",
		OnChange = function(self) 
			if self.value==true then
				Spring.SendCommands("luaui enablewidget Receive Units Indicator")
			end
		end,
	},
	
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
local spSetCameraTarget		= Spring.SetCameraTarget
local spGetTimer 			= Spring.GetTimer
local spDiffTimers 			= Spring.DiffTimers

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
local overview_mode, last_rx, last_ls_dist --overview_mode's variable
local follow_timer = 0

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


local fpsmode = false
local mx, my = 0,0
local msx, msy = 0,0
local smoothscroll = false
local springscroll = false
local lockspringscroll = false
local rotate, movekey
local move, rot = {}, {}
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
local last_move = spGetTimer() --switch for reset lockspot for edgescroll
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
	---===Convert camera angle into estimated ground position (by Msafwan)===
	local camTilt = math.min(1.5550425, PI/2 + cs.rx)
	local xzDist = math.tan(camTilt)*(cs.py-averageEdgeHeight) --the ground distance (at xz-plane) between FreeStyle camera and the target.
	local xDist = sin(cs.ry)*xzDist ----break down "xzDist" into x and z component.
	local zDist = cos(cs.ry)*xzDist
	gx, gy, gz = cs.px+xDist,averageEdgeHeight,cs.pz+zDist --estimated ground position infront of camera (if outside map)
	---===
	
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

local function Zoom(zoomin, shift, forceCenter)
	local zoomin = zoomin
	if options.invertzoom.value then
		zoomin = not zoomin
	end

	local cs = spGetCameraState()
	-- [[
	if
		(not forceCenter) and
		(
			(zoomin and options.zoomintocursor.value)
			or ((not zoomin) and options.zoomoutfromcursor.value)
		)
		then
		
		local onmap, gx,gy,gz = VirtTraceRay(mx, my, cs)
		
		if onmap then
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

SetFOV = function(fov)
	local cs = spGetCameraState()
	cs.fov = fov
    spSetCameraState(cs,0)
	Spring.Echo(fov .. " degree")
	
	local currentFOVhalf_rad = (fov/2)*PI/180
	local mapLenght = (max(mheight, mwidth)+4000)/2
	maxDistY =  mapLenght/math.tan(currentFOVhalf_rad) --adjust TAB/Overview distance based on camera FOV
end

local function ResetCam()
	local cs = spGetCameraState()
	cs.px = Game.mapSizeX/2
	cs.py = maxDistY
	cs.pz = Game.mapSizeZ/2
	cs.rx = -HALFPI
	cs.ry = PI
	spSetCameraState(cs, 1)
end
options.resetcam.OnChange = ResetCam

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
		
		cs.px = Game.mapSizeX/2
		cs.py = maxDistY
		cs.pz = Game.mapSizeZ/2
		cs.rx = -HALFPI
		spSetCameraState(cs, 1)
	else --if in overview mode
		local cs = spGetCameraState()
		mx, my = spGetMouseState()
		local onmap, gx, gy, gz = VirtTraceRay(mx,my,cs) --create a lockstop point.
		if gx then --Note:  Now VirtTraceRay can extrapolate coordinate in null space (no need to check for onmap)
			local cs = spGetCameraState()			
			cs.rx = last_rx
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



local function AutoZoomInOutToCursor() --options.followautozoom (auto zoom camera while in follow cursor mode)
	if follow_timer > 0 or smoothscroll or springscroll or rotate then
		return
	end
	local teamID = Spring.GetLocalTeamID()
	local _, playerID = Spring.GetTeamInfo(teamID)
	local pp = WG.alliedCursorsPos[ playerID ]
	if pp then
		local groundY = max(0,spGetGroundHeight(pp[1],pp[2]))
		local scrnsize_X,scrnsize_Y = Spring.GetViewGeometry() --get current screen size
		local scrn_x,scrn_y = Spring.WorldToScreenCoords(pp[1],groundY,pp[2]) --get cursor's position on screen
		local camHeight = spGetCameraState().py - groundY --get camera height with respect to ground
		local zoomin = true
		if options.invertzoom.value then --if invert zoom:
			zoomin = not zoomin
		end
		if (scrn_x<scrnsize_X*5/8 and scrn_x>scrnsize_X*3/8) and (scrn_y<scrnsize_Y*5/8 and scrn_y>scrnsize_Y*3/8) then --if cursor near center:
			if camHeight >1000 then --if cam height from ground greater than 1000elmo: do
				Zoom(zoomin, false, true) --slow zoom in
			end
		elseif (scrn_x>scrnsize_X*6/8 or scrn_x<scrnsize_X*2/8) or (scrn_y>scrnsize_Y*6/8 or scrn_y<scrnsize_Y*2/8) then --if cursor near edge: do
			Zoom(not zoomin, false, true) --slow zoom out
		end				
		if (scrn_x>scrnsize_X or scrn_x<0) or (scrn_y>scrnsize_Y or scrn_y<0) then --if cursor outside screen: do
			Zoom(not zoomin, false, true) --slow zoom out 3 times! ~ equal to fast zoom out using SHIFT
			Zoom(not zoomin, false, true)
			spSetCameraTarget(pp[1], groundY, pp[2], 1) --fast go-to speed
		else --if cursor within screen: do
			spSetCameraTarget(pp[1], groundY, pp[2], 15) --slow go-to speed
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
		if lock and ls_onmap then
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
	local initRadius = 50
	--local camVecs = spGetCameraVectors()
	local isSpec = Spring.GetSpectatingState()
	local teamID = (not isSpec and Spring.GetMyTeamID()) --get teamID if not spec
	local foundUnit
	local forwardOffset,backwardOffset,leftOffset,rightOffset
	if move.right or rot.right then --content of move & rot table is set in Update() and in KeyPress(). Is global. Is used to start scrolling & rotation (initiated in Update()) 
		rightOffset =initRadius
	elseif move.up or rot.up then
		forwardOffset = initRadius
	elseif move.left or rot.left then
		leftOffset =initRadius
	elseif move.down or rot.down then
		backwardOffset = initRadius
	end
	for i=1, 5 do --create a (detection) sphere of increasing size (x5) in scroll direction
		local front, top, right = Spring.GetUnitVectors(thirdperson_trackunit) --get vector of current tracked unit
		local x,y,z = spGetUnitPosition(thirdperson_trackunit) 
		y = y+25
		local offX_temp = (forwardOffset and forwardOffset+25) or (backwardOffset and -backwardOffset-25) or 0 --set direction where sphere must grow in x,y,z (global) direction.
		local offY_temp = 0
		local offZ_temp = (rightOffset and rightOffset+25) or (leftOffset and -leftOffset-25) or 0
		local offX = front[1]*offX_temp + top[1]*offY_temp + right[1]*offZ_temp --rotate (translate) the global right/left/forward/backward into a direction relative to current unit
		local offY = front[2]*offX_temp + top[2]*offY_temp + right[2]*offZ_temp
		local offZ = front[3]*offX_temp + top[3]*offY_temp + right[3]*offZ_temp
		local selUnits = Spring.GetUnitsInSphere(x+offX,y+offY,z+offZ, initRadius,teamID) --create sphere that detect unit in area of this direction
		Spring.SelectUnitArray({selUnits[1]}) --test select unit (in case its not selectable)
		selUnits = spGetSelectedUnits()
		if selUnits and selUnits[1] then --find unit in that area
			foundUnit = selUnits[1]
			break
		end
		if forwardOffset then --increase distance of detection sphere away into selected direction
			forwardOffset =forwardOffset*2
		elseif backwardOffset then
			backwardOffset =backwardOffset*2
		elseif leftOffset then
			leftOffset =leftOffset*2
		elseif rightOffset then
			rightOffset =rightOffset*2
		end
		initRadius =initRadius*2 --increase size of detection sphere
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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(dt)

    if hideCursor then
        spSetMouseCursor('%none%')
    end
	
	if follow_timer > 0  then 
		follow_timer = follow_timer - dt
	end

	if options.follow.value then --if follow selected player's cursor: do
		camcycle = camcycle %(8) + 1
		if camcycle == 1 then
			if WG.alliedCursorsPos then 
				if options.followautozoom.value then
					AutoZoomInOutToCursor()
				else
					local teamID = Spring.GetLocalTeamID()
					local _, playerID = Spring.GetTeamInfo(teamID)
					local pp = WG.alliedCursorsPos[ playerID ]
					if pp then
						local groundY = max(0,spGetGroundHeight(pp[1],pp[2]))
						local scrnsize_X,scrnsize_Y = Spring.GetViewGeometry() --get current screen size
						local scrn_x,scrn_y = Spring.WorldToScreenCoords(pp[1],groundY,pp[2]) --get cursor's position on screen
						if (scrn_x>scrnsize_X or scrn_x<0) or (scrn_y>scrnsize_Y or scrn_y<0) then --if cursor outside screen: do
							spSetCameraTarget(pp[1], groundY, pp[2], 1) --fast go-to speed
						else --if cursor within screen: do
							spSetCameraTarget(pp[1], groundY, pp[2], 15) --slow go-to speed
						end
					end
				end
			end 
		end
	end
	
	cycle = cycle %(32*15) + 1
	-- Periodic warning
	if cycle == 1 then
		PeriodicWarning()
	end
	
	trackcycle = trackcycle %(4) + 1
	if trackcycle == 1 and trackmode and (not rotate) then --update trackmode during normal/non-rotating state (doing both will cause a zoomed-out bug)
		local selUnits = spGetSelectedUnits()
		if selUnits and selUnits[1] then
			local x,y,z = spGetUnitPosition( selUnits[1] )
			spSetCameraTarget(x,y,z, 0.2)
		elseif (not options.persistenttrackmode.value) then --cancel trackmode when no more units is present in non-persistent trackmode.
			trackmode=false --exit trackmode
		end
	end
	

	local cs = spGetCameraState()
	
	local use_lockspringscroll = lockspringscroll and not springscroll

	local a,c,m,s = spGetModKeyState()
	
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
	
	if (not thirdperson_trackunit and  --block 3rd Person 
		(smoothscroll or
		move.right or move.left or move.up or move.down or
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
			
			if move.right then
				mxm = speed
			elseif move.left then
				mxm = -speed
			end
			
			if move.up then
				mym = speed
			elseif move.down then
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
	
	if options.edgemove.value then
		if not movekey then --if not doing arrow key on keyboard: reset
			move = {}
		end
		
		if mx > vsx-2 then 
			move.right = true
		elseif mx < 2 then
			move.left = true
		end
		if my > vsy-2 then
			move.up = true
		elseif my < 2 then
			move.down = true
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
	
	if 	(thirdperson_trackunit and 
		not overview_mode and --block 3rd person scroll when in overview mode
		(move.right or move.left or move.up or move.down or
		rot.right or rot.left or rot.up or rot.down)) --NOTE: engine exit 3rd-person trackmode if it detect edge-screen scroll, so we handle 3rd person trackmode scrolling here.
		then
		
		if options.thirdpersonedgescroll.value and spDiffTimers(spGetTimer(),thirdPerson_transit)>=1 then --edge scroll will 3rd Person nearby unit
			ThirdPersonScrollCam(cs) --edge scroll to nearby unit
		else --not 3rdPerson-edge-Scroll: edge scroll won't effect tracking
			local selUnits = spGetSelectedUnits()
			if selUnits and selUnits[1] then -- re-issue 3rd person for selected unit
				spSendCommands('viewfps')
				spSendCommands('track')
				thirdperson_trackunit = selUnits[1]
				cs.px,cs.py,cs.pz=spGetUnitPosition(selUnits[1])
				cs.py= cs.py+25 --move up 25-elmo incase FPS camera stuck to unit's feet instead of tracking it (aesthetic)
				spSetCameraState(cs,0)
			else --no unit selected: return to freeStyle camera
				spSendCommands('trackoff')
				spSendCommands('viewfree')
				thirdperson_trackunit = false
			end
		end
	end
	
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
			end
		end
		if abs(dx) > 0 or abs(dy) > 0 then
			RotateCamera(x, y, dx, dy, smoothed, ls_have)
		end
		
		spWarpMouse(msx, msy)
		
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
	
	follow_timer = 4
	
	local a,c,m,s = spGetModKeyState()
	
	spSendCommands('trackoff')
    spSendCommands('viewfree')
	if not (options.persistenttrackmode.value and (c or a)) then --Note: wont escape trackmode if pressing Ctrl or Alt in persistent trackmode, else: always escape.
		trackmode = false
	end
	thirdperson_trackunit = false
	
	
	-- Reset --
	if a and c then
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
	if c then
		rotate_transit = nil
		if options.targetmouse.value then --if "rotateAtCursor": trigger smoot in-transit effect
			
			local onmap, gx, gy, gz = VirtTraceRay(x,y, cs)
			if gx and onmap then
				SetLockSpot2(cs,x,y)
				
				spSetCameraTarget(gx,gy,gz, 1)
				rotate_transit = spGetTimer()
			end
		end
		spWarpMouse(cx, cy)
		SetLockSpot2(cs)
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
		follow_timer = 4
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
	
	spSendCommands("luaui disablewidget SmoothScroll")
end

function widget:Shutdown()
	spSendCommands{"viewta"}
	spSendCommands( 'bind any+tab toggleoverview' )
	spSendCommands( 'bind any+t track' )
	spSendCommands( 'bind ctrl+t trackmode' )
	spSendCommands( 'bind backspace mousestate' ) --//re-enable screen-panning-mode toggled by 'backspace' key
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
		if selUnits and selUnits[1] then
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

function GroupRecallFix(key, modifier, isRepeat)
	if ( not modifier.alt and not modifier.meta) then --check key for group. Reference: unit_auto_group.lua by Licho
		local gr
		if (key == KEYSYMS.N_0) then gr = 0 
		elseif (key == KEYSYMS.N_1) then gr = 1
		elseif (key == KEYSYMS.N_2) then gr = 2 
		elseif (key == KEYSYMS.N_3) then gr = 3
		elseif (key == KEYSYMS.N_4) then gr = 4
		elseif (key == KEYSYMS.N_5) then gr = 5
		elseif (key == KEYSYMS.N_6) then gr = 6
		elseif (key == KEYSYMS.N_7) then gr = 7
		elseif (key == KEYSYMS.N_8) then gr = 8
		elseif (key == KEYSYMS.N_9) then gr = 9
		end
		if (gr ~= nil) then
			local selectedUnit = spGetSelectedUnits()
			local groupCount = spGetGroupList()
			if groupCount[gr] ~= #selectedUnit then
				return false
			end
			for i=1,#selectedUnit do
				local unitGroup = spGetUnitGroup(selectedUnit[i])
				if unitGroup~=gr then
					return false
				end
			end
			if previousKey == key and (spDiffTimers(spGetTimer(),previousTime) > 2) then
				currentIteration = 0 --reset cycle if delay between 2 similar tap took too long.
			end
			previousKey = key
			previousTime = spGetTimer()
			
			if options.enableCycleView.value and WG.recvIndicator then 
				local slctUnitUnordered = {}
				for i=1 , #selectedUnit do
					local unitID = selectedUnit[i]
					local x,y,z = spGetUnitPosition(unitID)
					slctUnitUnordered[unitID] = {x,y,z}
				end
				selectedUnit = nil
				local cluster, lonely = WG.recvIndicator.OPTICS_cluster(slctUnitUnordered, 600,2, Spring.GetMyTeamID(),300) --//find clusters with atleast 2 unit per cluster and with at least within 300-elmo from each other with 600-elmo detection range
				if previousGroup == gr then
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
					Spring.SetCameraTarget(meanX, meanY, meanZ,0.5)
				else
					local unitID = lonely[currentIteration-#cluster]
					local x,y,z= slctUnitUnordered[unitID][1],slctUnitUnordered[unitID][2],slctUnitUnordered[unitID][3] --// get stored unit position
					Spring.SetCameraTarget(x,y,z,0.5)
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
				Spring.SetCameraTarget(meanX, meanY, meanZ,0.5) --is overriden by Spring.SetCameraTarget() at cache.lua.
			end
			previousGroup= gr
			return true
		end
	end
end
