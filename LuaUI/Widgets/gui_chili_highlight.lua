--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Chili Highlight",
		desc      = "Draws colored circles around specified Chili elements",
		author    = "KingRaptor",
		date      = "2017.01.15",
		license   = "GNU GPL, v2 or later",
		layer     = -math.huge,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local DEFAULT_COLOR = {.05, .96, .95}
local CIRCLE_SIZE_MULT = 1.05
local PADDING_X = 4
local PADDING_Y = 4

local Chili

local circleDrawList, rectangleDrawList

local controls = {} -- [control name] = {control = control, color = color}
local alpha = 1
local timer = 0

local vsx, vsy, sMidX, sMidY = 0, 0, 0, 0
local uiScale = 1
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- NOTE: drawArrow can be a number to force an angle
local function AddControl(name, color, drawArrow, lineWidth)
	controls[name] = {control = Chili.Screen0:GetObjectByName(name), color = color, drawArrow = drawArrow, lineWidth = lineWidth}
end

local function AddControlFunc(name, func, color, drawArrow, lineWidth)
	controls[name] = {func = func, color = color, drawArrow = drawArrow, lineWidth = lineWidth}
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

local function DrawArrow(x, y, controlWidth, controlHeight, color, angle)
	controlHeight = (controlHeight/2 + vsy * 0.02 * alpha) * uiScale
	local halfWidth = vsx*0.01 * uiScale
	local height = vsy*0.06 * uiScale
	local vertices = {
		{v = {0, controlHeight, 0}},
		{v = {-halfWidth, controlHeight + height, 0}},
		{v = {0, controlHeight + height*0.7, 0}},
		{v = {halfWidth, controlHeight + height, 0}},
	}
	
	if not angle then
		-- nearest diagonal
		angle = GetAngleFromVector(sMidX - x, sMidY - y)
		angle = math.deg(angle) - 90
		angle = math.floor(angle/90) * 90 + 45
	end
	
	gl.PushMatrix()
	gl.Color(color[1], color[2], color[3], 0.8)
	gl.Translate(x, y, 0)
	-- arrow fill
	gl.Rotate(angle, 0, 0, 1)
	gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
	gl.Shape(GL.TRIANGLE_FAN, vertices)
	-- outline
	gl.Color(0, 0, 0, 0.6)
	gl.LineWidth(1.5)
	gl.Shape(GL.LINE_LOOP, vertices)
	gl.PopMatrix()
end

local function DrawCircle(x, y, width, height, color, lineWidth, drawArrow)
	local rectangle = (width/height >= 1.5) or (height/width >= 1.5)
	local sizeMult = rectangle and 1 or CIRCLE_SIZE_MULT
	
	x = x * uiScale
	y = (vsy - y) * uiScale
	width = width * uiScale
	height = height * uiScale
	
	gl.LineWidth(lineWidth)
	gl.PushMatrix()
	gl.Translate(x, y, 0)
	gl.Scale((width*sizeMult + PADDING_X)/2 , (height*sizeMult + PADDING_Y)/2, 1)
	gl.Color(color[1], color[2], color[3], alpha)
	gl.LineStipple('any')
	if rectangle then
		gl.CallList(rectangleDrawList)
	else
		gl.CallList(circleDrawList)
	end
	gl.LineStipple(false)
	gl.PopMatrix()
	
	if drawArrow then
		DrawArrow(x, y, width, height, color, type(drawArrow) == "number" and drawArrow)
	end
end

local function DrawCircleForControl(control, color, lineWidth, drawArrow)
	local x, y = control:LocalToScreen(0, 0)
	y = y + control.height/2
	x = x + control.width/2
	DrawCircle(x, y, control.width, control.height, color, lineWidth, drawArrow)
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
		if data.func then
			local pos = data.func()
			if pos then
				local x, y, w, h = unpack(pos)
				if x and w then
					DrawCircle(x, y, w, h, data.color or DEFAULT_COLOR, data.width or 4, data.drawArrow)
				end
			end
		else
			local control = data.control
			if control and (not control.disposed) then
				if control.visible then
					DrawCircleForControl(control, data.color or DEFAULT_COLOR, data.width or 4, data.drawArrow)
				end
			else
				RemoveControl(name)
			end
		end
	end
	gl.LineWidth(1)
	gl.Color(1,1,1,1)
end

function widget:Update(dt)
	timer = timer + dt * 2
	alpha = 0.75 + 0.25*math.sin(timer)
end

function widget:Initialize()
	Chili = WG.Chili
	
	WG.ChiliHighlight = {
		AddControl = AddControl,
		AddControlFunc = AddControlFunc,
		RemoveControl = RemoveControl,
		ClearControls = ClearControls,
	}
	
	widget:ViewResize(Spring.GetViewGeometry())
	
	circleDrawList = gl.CreateList(gl.BeginEnd, GL.LINE_LOOP, CircleVertices, 18)
	rectangleDrawList = gl.CreateList(gl.BeginEnd, GL.LINE_LOOP, RoundedRectangleVertices, 18)
	--WG.ChiliHighlight.AddControl("Metal", nil, true)
	--WG.ChiliHighlight.AddControl("Energy", nil, 180)
	--WG.ChiliHighlight.AddControlFunc("econTab", function() return {WG.IntegralMenu.GetTabPosition("units_mobile")} end, nil, true)
	--WG.ChiliHighlight.AddControlFunc("attackButton", function() return {WG.IntegralMenu.GetCommandButtonPosition(CMD.ATTACK)} end)
	
	--AddControl("core_backgroundPanel", nil, true)
end

function widget:Shutdown()
	WG.ChiliHighlight = nil
	gl.DeleteList(circleDrawList)
	gl.DeleteList(rectangleDrawList)
end
