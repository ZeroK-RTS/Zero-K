function widget:GetInfo()
	return {
		name      = "Chili Redraw Tracker",
		desc      = "Tracks redraws in the chili framework.",
		author    = "GoogleFrog and KingRaptor",
		date      = "8 June 2019",
		license   = "GNU LGPL, v2.1 or later",
		layer     = 0,
		enabled   = false, -- loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local CIRCLE_SIZE_MULT = 0.98

local Chili

local circleDrawList, rectangleDrawList

local controls = {} -- [control name] = {control = control, color = color}

local updateDefs = {
	Draw_tex_all = {
		color = {.05, .96, .95},
		lineWidth = 1,
		padding = -2,
	},
	Draw = {
		color = {.96, .05, .05},
		lineWidth = 4,
		padding = -1,
	},
	DrawForList_tex_all = {
		color = {.95, .96, .95},
		lineWidth = 2,
		padding = 2,
	},
	DrawForList = {
		color = {.96, .05, .95},
		lineWidth = 1,
		padding = 0,
	},
	DrawForList_own_dlist = {
		color = {.05, .05, .05},
		lineWidth = 20,
		padding = 0,
	},
	New = {
		color = {.06, .95, .05},
		lineWidth = 6,
		padding = -4,
	},
	DrawChildrenForList = {
		color = {.96, .95, .05},
		lineWidth = 3,
		padding = -4,
	},
	DrawForList_notVisible = {
		color = {.96, .25, .05},
		lineWidth = 12,
		padding = -4,
	},
}

local vsx, vsy, sMidX, sMidY = 0, 0, 0, 0
local uiScale = 1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- NOTE: drawArrow can be a number to force an angle
local function AddControl(control, drawType)
	local name = control.name .. drawType
	if not controls[name] then
		local params = updateDefs[drawType]
		controls[name] = {
			control = control,
			color = params.color,
			lineWidth = params.lineWidth,
			padding = params.padding,
			life = 0,
		}
	end
	controls[name].life = 1
end

local function RemoveControl(name)
	controls[name] = nil
end

local function ClearControls()
	controls = {}
end

--------------------------------------------------------------------------------
-- drawing functions
--------------------------------------------------------------------------------
local function GetQuadrant(x, y)
	if x > 0 then
		return y > 0 and 1 or 4
	elseif x < 0 then
		return y > 0 and 2 or 3
	else	-- x == 0
		return y > 0 and 1 or 3
	end
end

local function GetAngleFromVector(x, y)
	local quadrant = GetQuadrant(x, y)
	local theta = math.atan(math.abs(y)/math.abs(x))
	if quadrant == 2 then
		theta = math.pi - theta
	elseif quadrant == 3 then
		theta = math.pi + theta
	elseif quadrant == 4 then
		theta = 2*math.pi - theta
	end
	return theta
end

-- from gfx_commands_fx.lua
local function CircleVertices(circleDivs)
	for i = 1, circleDivs do
		local theta = 2 * math.pi * i / circleDivs
		gl.Vertex(math.cos(theta), math.sin(theta), 0)
	end
end

local function RoundedRectangleVertices()
	gl.Vertex(-1, 0.9, 0) -- top left 1
	gl.Vertex(-0.9, 1, 0)	-- top left 2
	gl.Vertex(0.9, 1, 0)	 -- top right 1
	gl.Vertex(1, 0.9, 0)	 -- top right 2
	gl.Vertex(1, -0.9, 0)	-- borrom right 1
	gl.Vertex(0.9, -1, 0)	-- bottom right 2
	gl.Vertex(-0.9, -1, 0) -- bottom left 1
	gl.Vertex(-1, -0.9, 0) -- bottom left 2
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawCircle(x, y, width, height, data, lineWidth)
	local rectangle = true
	local sizeMult = rectangle and 1 or CIRCLE_SIZE_MULT
	
	x = x * uiScale
	y = (vsy - y) * uiScale
	width = width * uiScale
	height = height * uiScale
	
	gl.LineWidth(lineWidth)
	gl.PushMatrix()
	gl.Translate(x, y, 0)
	gl.Scale((width*sizeMult + data.padding)/2 , (height*sizeMult + data.padding)/2, 1)
	gl.Color(data.color[1], data.color[2], data.color[3], data.life)
	gl.LineStipple('any')
	if rectangle then
		gl.CallList(rectangleDrawList)
	else
		gl.CallList(circleDrawList)
	end
	gl.LineStipple(false)
	gl.PopMatrix()
end

local function DrawCircleForControl(control, data, lineWidth)
	local x, y = control:LocalToScreen(0, 0)
	y = y + control.height/2
	x = x + control.width/2
	DrawCircle(x, y, control.width, control.height, data, lineWidth)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	sMidX = viewSizeX * 0.5
	sMidY = viewSizeY * 0.5
	uiScale = WG.uiScale or 1
end

function widget:DrawScreen()
	for name, data in pairs(controls) do
		local control = data.control
		if control and (not control.disposed) then
			if control.visible then
				DrawCircleForControl(control, data, data.lineWidth)
			end
		else
			RemoveControl(name)
		end
	end
	gl.LineWidth(1)
	gl.Color(1,1,1,1)
end

function widget:Update(dt)
	for name, data in pairs(controls) do
		data.life = data.life - dt
		if data.life <= 0 then
			RemoveControl(name)
		end
	end
end

function widget:Initialize()
	Chili = WG.Chili
	
	WG.ChiliRedraw = {
		AddControl = AddControl,
		RemoveControl = RemoveControl,
		ClearControls = ClearControls,
	}
	
	widget:ViewResize(Spring.GetViewGeometry())
	
	circleDrawList = gl.CreateList(gl.BeginEnd, GL.LINE_LOOP, CircleVertices, 18)
	rectangleDrawList = gl.CreateList(gl.BeginEnd, GL.LINE_LOOP, RoundedRectangleVertices, 18)
end

function widget:Shutdown()
	WG.ChiliRedraw = nil
	gl.DeleteList(circleDrawList)
	gl.DeleteList(rectangleDrawList)
end
