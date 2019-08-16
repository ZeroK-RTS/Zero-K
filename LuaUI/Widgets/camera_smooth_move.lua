
function widget:GetInfo() return {
	name    = "Smooth Scroll",
	desc    = "Alternate view movement for the middle mouse button",
	author  = "trepan",
	date    = "Feb 27, 2007",
	license = "GNU GPL, v2 or later",
	layer   = 1,
	enabled = true
} end

local isEnabled = false

options_path = 'Settings/Camera'
options_order = { 'smooth_mmb_scroll'}
options = {
	smooth_mmb_scroll = {
		name = 'MMB scrolls instead of dragging',
		desc = "When enabled hold middle mouse button to scroll the map in a direction.\n" ..
		       "When disabled click and drag the map with middle mouse button.",
		type = 'bool',
		noHotkey = true,
		value = false,
		OnChange = function(self)
			isEnabled = self.value
		end,
		simpleMode = true,
		everyMode = true,
	},
}

local GL_LINES    = GL.LINES

local glBeginEnd  = gl.BeginEnd
local glColor     = gl.Color
local glLineWidth = gl.LineWidth
local glVertex    = gl.Vertex
local glTexture   = gl.Texture
local glTexRect   = gl.TexRect

local spGetCameraState   = Spring.GetCameraState
local spGetCameraVectors = Spring.GetCameraVectors
local spGetModKeyState   = Spring.GetModKeyState
local spGetMouseState    = Spring.GetMouseState
local spIsAboveMiniMap   = Spring.IsAboveMiniMap
local spSendCommands     = Spring.SendCommands
local spSetCameraState   = Spring.SetCameraState
local spSetMouseCursor   = Spring.SetMouseCursor
local spWarpMouse        = Spring.WarpMouse

local red   = { 1, 0, 0 }
local green = { 0, 1, 0 }

local icon_size = 20
local speedFactor = 25

local mx, my
local active = false

function widget:Update(dt)
	if not active then
		return
	end

	local x, y, lmb, mmb, rmb = spGetMouseState()
	local cs = spGetCameraState()
	local speed = dt * speedFactor

	if (cs.name == 'free') then
		local a,c,m,s = spGetModKeyState()
		if (c) then
			return
		end
		-- clear the velocities
		cs.vx  = 0; cs.vy  = 0; cs.vz  = 0
		cs.avx = 0; cs.avy = 0; cs.avz = 0
	elseif (cs.name == 'ta') then
		local flip = -cs.flipped
		-- simple, forward and right are locked
		cs.px = cs.px + (speed * flip * (x - mx))
		cs.pz = cs.pz + (speed * flip * (my - y))
	else
		-- forward, up, right, top, bottom, left, right
		local camVecs = spGetCameraVectors()
		local cf = camVecs.forward
		local len = math.sqrt((cf[1] * cf[1]) + (cf[3] * cf[3]))
		local dfx = cf[1] / len
		local dfz = cf[3] / len
		local cr = camVecs.right
		local len = math.sqrt((cr[1] * cr[1]) + (cr[3] * cr[3]))
		local drx = cr[1] / len
		local drz = cr[3] / len
		local mxm = (speed * (x - mx))
		local mym = (speed * (y - my))
		cs.px = cs.px + (mxm * drx) + (mym * dfx)
		cs.pz = cs.pz + (mxm * drz) + (mym * dfz)
	end

	spSetCameraState(cs, 0)

	if (mmb) then
		spSetMouseCursor('none')
	end
end

function widget:MousePress(x, y, button)
	if not isEnabled or button ~= 2 or spIsAboveMiniMap(x, y) or WG.COFC_Enabled then
		return false
	end

	active = true

	local vsx, vsy = widgetHandler:GetViewSizes()
	mx = vsx * 0.5
	my = vsy * 0.5
	spWarpMouse(mx, my)
	spSendCommands({'trackoff'})

	return true
end

function widget:MouseRelease(x, y, button)
	active = false
	return -1
end

local function DrawLine(x0, y0, c0, x1, y1, c1)
	glColor(c1)
	glVertex(x1, y1)
	glColor(c0)
	glVertex(x0, y0)
end

function widget:DrawScreen()
	if not active then
		return
	end

	local x, y = spGetMouseState()

	glLineWidth(2)
	glBeginEnd(GL_LINES, DrawLine, x, y, green, mx, my, red)
	glLineWidth(1)

	glTexture(LUAUI_DIRNAME .. 'Images/ccc/arrows-dot.png')
	glTexRect(x-icon_size, y-icon_size, x+icon_size, y+icon_size)
	glTexture(false)
end
