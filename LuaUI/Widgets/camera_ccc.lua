--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Complete Control Camera",
    desc      = "v0.25 Camera featuring 6 actions. Type \255\90\90\255/luaui ccc help\255\255\255\255 for help.",
    author    = "CarRepairer (smoothscroll code by trepan)",
    date      = "2009-12-15",
    license   = "GNU GPL, v2 or later",
    layer     = 1002,
	handler   = true,
    enabled   = true,
  }
end

include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local init = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/View/Complete Control Camera'
options_order = { 
	'helpwindow', 
	
	'lblRotate',
	'targetmouse', 
	'rotateonedge', 
	'rotfactor', 
	
	'lblScroll',
	'edgemove', 
	'smoothscroll',
	'speedFactor', 
	'speedFactor_k', 
	'invertscroll', 
	
	'lblZoom',
	'invertzoom', 
	'zoomintocursor', 
	'zoomoutfromcursor', 
	'zoominfactor', 
	'zoomoutfactor', 
	
	'lblMisc',
	'follow', 
	'smoothness',
	'fov',
	'restrictangle',
	'mingrounddist',

}
options = {
	
	lblblank1 = {name='', type='label'},
	lblRotate = {name='Rotation', type='label'},
	lblScroll = {name='Scrolling', type='label'},
	lblZoom = {name='Zooming', type='label'},
	lblMisc = {name='Misc.', type='label'},
	
	helpwindow = {
		name = 'CC Cam Help',
		type = 'text',
		value = [[
			Complete Control Camera has six main actions...
			
			Zoom..... <Mousewheel>
			Tilt World..... <Ctrl> + <Mousewheel>
			Altitude..... <Alt> + <Mousewheel>
			Mouse Scroll..... <Middlebutton-drag>
			Rotate World..... <Ctrl> + <Middlebutton-drag>
			Rotate Camera..... <Alt> + <Middlebutton-drag>
			
			Additional actions:
			Keyboard: <arrow keys> replicate middlebutton drag while <pgup/pgdn> replicate mousewheel. You can use these with ctrl, alt & shift to replicate mouse camera actions.
			Use <Shift> to speed up camera movements.
			Reset Camera..... <Ctrl> + <Alt> + <Shift> + <Middleclick> or /luaui ccc reset
		]],
	},
	smoothscroll = {
		name = 'Smooth scrolling',
		desc = 'Use smoothscroll method when mouse scrolling.',
		type = 'bool',
		value = true,
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
		desc = 'Invert the scroll wheel direction for zooming and altitude.',
		type = 'bool',
		value = true,
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
		desc = "Follow the cursor of the player you're spectating (needs Ally Cursor widget to be on).",
		type = 'bool',
		value = false,
		path = 'Settings/View',
	},	
	rotfactor = {
		name = 'Rotation speed',
		type = 'number',
		min = 0.001, max = 0.010, step = 0.001,
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
		name = 'Field of View',
		desc = "FOV (35 deg - 100 deg). Requires restart to take effect.",
		springsetting = 'CamFreeFOV',
		type = 'number',
		min = 35, max = 100, step = 5,
		value = 45,
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
	},
	mingrounddist = {
		name = 'Minimum Ground Distance',
		desc = 'Getting too close to the ground allows strange camera positioning.',
		type = 'number',
		advanced = true,
		min = 0, max = 10, step = 1,
		value = 5,
		OnChange = function(self) init = true; end
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
local spGetModKeyState		= Spring.GetModKeyState
local spGetMouseState		= Spring.GetMouseState
local spIsAboveMiniMap		= Spring.IsAboveMiniMap
local spSendCommands		= Spring.SendCommands
local spSetCameraState		= Spring.SetCameraState
local spSetMouseCursor		= Spring.SetMouseCursor
local spTraceScreenRay		= Spring.TraceScreenRay
local spWarpMouse			= Spring.WarpMouse
local spGetCameraDirection	= Spring.GetCameraDirection
local spSetCameraTarget		= Spring.SetCameraTarget

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
local cx, cy
local smoothscroll = false
local springscroll = false
local lockspringscroll = false
local rotate, lockSpot, gx, gy, gz, gdist, movekey
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


local mwidth, mheight = Game.mapSizeX, Game.mapSizeZ
local mcx, mcz 	= mwidth / 2, mheight / 2
local mcy 		= Spring.GetGroundHeight(mcx, mcz)
local maxDistY = max(mheight, mwidth) * 2


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
	
	local gx1, gz1 = cs.px + vecDist*cs.dx,			cs.pz + vecDist*cs.dz
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

local function Zoom(up, s)

	local cs = spGetCameraState()

	local gpos
	local gx, gy, gz
	local dx, dy, dz
	
	if (up and options.zoomoutfromcursor.value)
		or 
		(not up and options.zoomintocursor.value)
		then
		_,gpos = spTraceScreenRay(mx, my, true)
	else
		_,gpos = spTraceScreenRay(vsx/2, vsy/2, true)
	end
		
		
	if gpos then
		gx, gy, gz = gpos[1], gpos[2], gpos[3]
	else
		local vecDist = (- cs.py) / cs.dy
		gx, gy, gz = cs.px + vecDist*cs.dx, 	cs.py + vecDist*cs.dy, cs.pz + vecDist*cs.dz
	end
	
	if gx then
		dx = gx - cs.px
		dy = gy - cs.py
		dz = gz - cs.pz
	else
		return false
	end
	
	local sp = (up and -options.zoomoutfactor.value or options.zoominfactor.value) * (s and 4 or 1)
	
	MoveRotatedCam(cs, 0, 0)

	cs.px = cs.px + dx * sp
	cs.py = cs.py + dy * sp
	cs.pz = cs.pz + dz * sp
	
	local newDist = GetDist( cs.px,  cs.py,  cs.pz, mcx, mcy, mcz)
	
	if not up or newDist < maxDistY then
		spSetCameraState(cs, options.smoothness.value)
	end

	return true
end

local function Altitude(up, s)
	local cs = spGetCameraState()
	local py = max(1, abs(cs.py) )
	local dy = py * (up and 1 or -1) * (s and 0.3 or 0.1)
	spSetCameraState({ py = py + dy, }, options.smoothness.value)
	return true
end


local function SetLockSpot(cs, x,y)
	local gpos
	if options.targetmouse.value then
		_, gpos = spTraceScreenRay(x, y, true)
	else
		_, gpos = spTraceScreenRay(vsx/2, vsy/2, true)
	end
	if gpos then
		gx,gy,gz = gpos[1], gpos[2], gpos[3]
		
		spSetCameraTarget(gx,gy,gz, 1)
		local px,py,pz = cs.px,cs.py,cs.pz
		local dx,dy,dz = gx-px, gy-py, gz-pz
		gdist = sqrt(dx*dx + dy*dy + dz*dz)
	end
	
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




local function RotateCamera(x, y, dx, dy, smooth)
	local cs = spGetCameraState()
	if cs.rx then
		
		cs.rx = cs.rx + dy * options.rotfactor.value
		cs.ry = cs.ry - dx * options.rotfactor.value
		
		local max_rx = options.restrictangle.value and -0.1 or HALFPIMINUS
		
		if cs.rx < -HALFPIMINUS then
			cs.rx = -HALFPIMINUS
		elseif cs.rx > max_rx then
			cs.rx = max_rx 
		end
		
		
		if lockSpot then
			if not gdist then
				SetLockSpot(cs, x,y)
			else
				local opp = sin(cs.rx) * gdist
				local alt = sqrt(gdist * gdist - opp * opp)
				cs.px = gx - sin(cs.ry) * alt
				cs.py = gy - opp
				cs.pz = gz - cos(cs.ry) * alt
				spWarpMouse(cx, cy)
			end
		end
		spSetCameraState(cs, smooth and options.smoothness.value or 0)
	end
end

local function tilt(s, dir)
	lockSpot = true
	local cs = spGetCameraState()
	msx = mx
	msy = my
	SetLockSpot(cs, vsx * 0.5, vsy * 0.5)
	local speed = dir * (s and 30 or 10)
	RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true)
	lockSpot = nil
	gdist = nil
	spWarpMouse(msx,msy)
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Update(dt)
	if options.follow.value then
		camcycle = camcycle %(32*6) + 1
		if camcycle == 1 then
			if WG.alliedCursorsPos then 
				local teamID = Spring.GetLocalTeamID()
				local _, playerID = Spring.GetTeamInfo(teamID)
				local pp = WG.alliedCursorsPos[ playerID ]
				if pp then 
					Spring.SetCameraTarget(pp[1], 0, pp[2], 5)
				end 
			end 
		end
	end
	cycle = cycle %(32*15) + 1
	-- Periodic warning
	if cycle == 1 then
		local c_widgets, c_widgets_list = '', {}
		for name,data in pairs(widgetHandler.knownWidgets) do
			if data.active and ( name:find('SmoothScroll') or name:find('Hybrid Overhead') )then
				c_widgets_list[#c_widgets_list+1] = name
			end
		end
		for _,wname in ipairs(c_widgets_list) do
			c_widgets = c_widgets .. wname .. ', '
		end
		if c_widgets ~= '' then
			echo('<CC Cam> *Periodic warning* Please disable other camera widgets: ' .. c_widgets)
		end
	end

	local cs = spGetCameraState()
	
	local use_lockspringscroll = lockspringscroll and not springscroll

	local a,c,m,s = spGetModKeyState()
	
	if rot.right or rot.left or rot.up or rot.down then
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
	
	if smoothscroll
		or move.right or move.left or move.up or move.down
		or use_lockspringscroll
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
			local speed = dt * options.speedFactor.value * heightFactor 
			mxm = speed * (x - cx)
			mym = speed * (y - cy)
		elseif use_lockspringscroll then
			local speed = options.speedFactor.value * heightFactor / 10
			local dir = options.invertscroll.value and -1 or 1
			mxm = speed * (x - mx) * dir
			mym = speed * (y - my) * dir
			--spWarpMouse(msx, msy)
			spWarpMouse(cx, cy)
		else
			local speed = options.speedFactor_k.value * (s and 3 or 1) * heightFactor
			
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
		end
		
		cs = MoveRotatedCam(cs, mxm, mym)
		
		spSetCameraState(cs, smoothlevel)
	end
	mx, my = spGetMouseState()
	
	if options.edgemove.value then
		if not movekey then
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

	fpsmode = cs.name == "fps"
	if init or ((cs.name ~= "free") and (cs.name ~= "ov") and not fpsmode) then 
		init = false
		spSendCommands("viewfree") 
		local cs = spGetCameraState()
		cs.tiltSpeed = 0
		cs.scrollSpeed = 0
		cs.gndOffset = options.mingrounddist.value
		spSetCameraState(cs,0)
	end
	
end

function widget:MouseMove(x, y, dx, dy, button)
	if rotate then
		if abs(dx) > 0 or abs(dy) > 0 then
			RotateCamera(x, y, dx, dy, false)
		end
		if not (lockSpot) then
			spWarpMouse(msx, msy)
		end
		
	elseif springscroll then
		if abs(dx) > 0 or abs(dy) > 0 then
			lockspringscroll = false
		end
		local dir = options.invertscroll.value and -1 or 1
					
		local cs = spGetCameraState()
		
		local speed = options.speedFactor.value * cs.py/1000 / 10
		local mxm = speed * dx * dir
		local mym = speed * dy * dir
	
		cs = MoveRotatedCam(cs, mxm, mym)
				
		spSetCameraState(cs, 0)
		if not (lockSpot) then
			spWarpMouse(msx, msy)
		end
		
	end
end


function widget:MousePress(x, y, button)
	if lockspringscroll then
		spWarpMouse(msx, msy)
		lockspringscroll = false
		return true
	end
	
	-- Not Middle Click --
	if (button ~= 2) then
		return false
	end
	
	local a,c,m,s = spGetModKeyState()
	
	-- Reset --
	if a and c and s then
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
	spWarpMouse(cx, cy)
	spSendCommands({'trackoff'})
	
	rotate, lockSpot = false, false
	-- Rotate --
	if a then
		rotate = true
		return true
	end
	-- Rotate World --
	if c then
		rotate = true
		SetLockSpot(cs, x,y)
		msx = cx
		msy = cy
		lockSpot = true
		return true
	end
	
	-- Scrolling --
	if options.smoothscroll.value then
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
		if not (lockSpot or lockspringscroll) then
			spWarpMouse(msx, msy)
		end
		lockSpot = nil
		smoothscroll = false
		springscroll = false
		gdist = nil
		return -1
	end
end

function widget:MouseWheel(up, value)
	local a,c,m,s = spGetModKeyState()
	
	if options.invertzoom.value then
		up = not up
	end
	
	-- Altitude --
	if c then
		return tilt(s, up and 1 or -1)
	elseif a then
		return Altitude(up, s)
	end
	
	-- Zoom --	
	return Zoom(up, s)
end

function widget:KeyPress(key, modifier, isRepeat)
	if fpsmode then return end
	if keys[key] then
		if modifier.ctrl or modifier.alt then
			local speed = modifier.shift and 30 or 10 
			if not modifier.alt then
				lockSpot = true
				local cs = spGetCameraState()
				SetLockSpot(cs, vsx * 0.5, vsy * 0.5)
			end
			if key == key_code.right then 		RotateCamera(vsx * 0.5, vsy * 0.5, speed, 0, true)
			elseif key == key_code.left then 	RotateCamera(vsx * 0.5, vsy * 0.5, -speed, 0, true)
			elseif key == key_code.down then 	RotateCamera(vsx * 0.5, vsy * 0.5, 0, -speed, true)
			elseif key == key_code.up then 		RotateCamera(vsx * 0.5, vsy * 0.5, 0, speed, true)
			end
			lockSpot = false
		else
			movekey = true
			move[keys[key]] = true
		end
	elseif key == key_code.pageup then
		if modifier.ctrl then
			tilt(modifier.shift, 1)
		elseif modifier.alt then
			Altitude(true, modifier.shift)
		else
			Zoom(true, modifier.shift)
		end
	elseif key == key_code.pagedown then
		if modifier.ctrl then
			tilt(modifier.shift, -1)
		elseif modifier.alt then
			Altitude(false, modifier.shift)
		else
			Zoom(false, modifier.shift)
		end
	end
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
	if smoothscroll or (rotate and lockSpot) then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows-dot.png')
	elseif rotate or lockspringscroll or springscroll then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows.png')
	end
	
	if filefound then
	
		if smoothscroll then
			glColor(0,1,0,1)
		elseif (rotate and lockSpot) then
			glColor(1,0.6,0,1)
		elseif rotate then
			glColor(1,1,0,1)
		elseif lockspringscroll then
			glColor(1,0,0,1)
		elseif springscroll then
			glColor(0,1,1,1)
		end
		
		glAlphaTest(GL_GREATER, 0)
		
		spSetMouseCursor('none')
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
end

function widget:Shutdown()
	spSendCommands{"viewta"}
end

function widget:TextCommand(command)
	
	if command == "ccc help" then
		for i, text in ipairs(helpText) do
			echo('<CC Cam['.. i ..']> '.. text)
		end
		return true
	elseif command == "ccc reset" then
		ResetCam()
		return true
	end
	return false
end   

--------------------------------------------------------------------------------
