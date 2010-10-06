
function widget:GetInfo()
	return {
		name      = "Missile Silo Range",
		desc      = "Displays the ranges of the missiles that the missile silo can produce",
		author    = "Google Frog",
		date      = "Dec 10, 2009",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

----------------------------
-- Config

local radiusCount = 5

local drawRadius = {}

drawRadius[1] = {
	range = 3500,
	color = {1,0.2,0.2,1},
	text = "Tacnuke and EMP",
	width = 1,
	miniWidth = 1,
	textSize = 90,
	}

drawRadius[2] = {
	range = 3675,
	color = {0.2,0.2,1,1},
	text = "EMP AOE",
	width = 1,
	miniWidth = 1,
	textSize = 90,
	}	
	
drawRadius[3] = {
	range = 6000,
	color = {0.4,1,0.2,1},
	text = "Seismic",
	width = 1,
	miniWidth = 1,
	textSize = 90,
	}
	
drawRadius[4] = {
	range = 1500,
	color = {0.2,0.2,1,1},
	text = "EMP vertical",
	width = 1,
	miniWidth = 1,
	textSize = 60,
	stipple = {4,1000},
	}
	
drawRadius[5] = {
	range = 600,
	color = {0.4,1,0.2,1},
	text = "Seismic and Tacnuke vertical",
	width = 1,
	miniWidth = 1,
	textSize = 60,
	stipple = {4,4095},
	}
	
local circleDivs = 64
	
----------------------------
-- Speedup
local spGetActiveCommand 	= Spring.GetActiveCommand
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetMouseState		= Spring.GetMouseState
local spTraceScreenRay		= Spring.TraceScreenRay
local spGetGroundHeight		= Spring.GetGroundHeight
	
local siloDefID = -UnitDefNames["missilesilo"].id

local floor = math.floor
local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local glColor               = gl.Color
local glLineWidth           = gl.LineWidth
local glDepthTest           = gl.DepthTest
local glTexture             = gl.Texture
local glDrawGroundCircle    = gl.DrawGroundCircle
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glBillboard           = gl.Billboard
local glText                = gl.Text
local glScale				= gl.Scale
local glRotate				= gl.Rotate
local glLoadIdentity		= gl.LoadIdentity
local glLineStipple			= gl.LineStipple

----------------------------

local function DrawActiveCommandRanges()

	local idx, cmd_id, cmd_type, cmd_name = spGetActiveCommand()
	
	if not (cmd_id and cmd_id == siloDefID) then
		return
	end
	
	local mx, my = spGetMouseState()
	local _, mouse = spTraceScreenRay(mx, my, true, true)
			
	if not mouse then
		return
	end
	
	mouse[1] = floor((mouse[1]+8)/16)*16
	mouse[3] = floor((mouse[3]+8)/16)*16
	
	local height = spGetGroundHeight(mouse[1],mouse[3])
	
	for i = 1, radiusCount do
		local radius = drawRadius[i]
		
		glLineWidth(radius.width)
		glColor(radius.color[1], radius.color[2], radius.color[3], radius.color[4] )
		if radius.stipple then
			glLineStipple(radius.stipple[1],radius.stipple[2])
		else
			glLineStipple(false)
		end
		
		glDrawGroundCircle(mouse[1], 0, mouse[3], radius.range, circleDivs )
		
		glPushMatrix()
		glTranslate(mouse[1] ,  height ,mouse[3]-radius.range-10)
		glBillboard()
		glText( radius.text, 0, 0, radius.textSize, "cn")
		glPopMatrix()  
			
	end
	
	glLineStipple(false)
	glLineWidth(1)
	glColor(1, 1, 1, 1)
	
end

local function DrawActiveCommandRangesMinimap()

	local idx, cmd_id, cmd_type, cmd_name = spGetActiveCommand()
	
	if not (cmd_id and cmd_id == siloDefID) then
		return
	end
	
	local mx, my = spGetMouseState()
	local _, mouse = spTraceScreenRay(mx, my, true, true)
			
	if not mouse then
		return
	end
	
	mouse[1] = floor((mouse[1]+8)/16)*16
	mouse[3] = floor((mouse[3]+8)/16)*16
	
	local height = spGetGroundHeight(mouse[1],mouse[3])
	
	glPushMatrix()
	glLoadIdentity()
	glTranslate(0,1,0)
	glScale(1/mapX , -1/mapZ, 1)
	glRotate(90,1,0,0)
	glTranslate(0,0,-mouse[3])
	
	for i = 1, radiusCount do
		local radius = drawRadius[i]
		
		glLineWidth(radius.miniWidth)
		glColor(radius.color[1], radius.color[2], radius.color[3], radius.color[4] )
		if radius.stipple then
			glLineStipple(radius.stipple[1],radius.stipple[2])
		else
			glLineStipple(false)
		end
		
		glDrawGroundCircle(mouse[1], mouse[3], 0, radius.range, circleDivs )
			
	end
	
	glLineStipple(false)
	glLineWidth(1)
	glColor(1, 1, 1, 1)
	
end



function widget:DrawInMiniMap()

	DrawActiveCommandRangesMinimap()

end

	
function widget:DrawWorld()
	
	DrawActiveCommandRanges()
	
end