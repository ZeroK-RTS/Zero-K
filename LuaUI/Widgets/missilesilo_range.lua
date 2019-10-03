
function widget:GetInfo()
	return {
		name      = "Missile Silo Range",
		desc      = "Displays the ranges of the missiles that the missile silo can produce",
		author    = "Google Frog",
		date      = "Dec 10, 2009", --updated May 3, 2015
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

options_path = 'Settings/Interface/Building Placement'
options_order = { 'missile_silo_advanced'}
options = {
	missile_silo_advanced = {
		name = "Advanced Missile Silo ranges",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'When placing a Missile Silo, show at what range the missiles will fall vertically, ie. are unblockable by terrain geometry and walls. Also, show how far away from the nominal range you can reach through AoE.',
	},
}

local drawRadius = {}

--large textSize & opacity for large radius/tiny text & opacity for small radius, help increase text visibility during zoom-out/zoom-in
drawRadius[1] = {
	range = 3500,
	color = {1,0.2,0.2,1},
	text = "Tacnuke and EMP",
	width = 1,
	miniWidth = 1,
	textSize = 180,
}

drawRadius[2] = {
	range = 6000,
	color = {0.4,1,0.2,1},
	text = "Seismic",
	width = 1,
	miniWidth = 1,
	textSize = 260,
}

drawRadius[3] = {
	range = 3675,
	color = {0.2,0.2,1,1},
	text = "EMP AOE",
	width = 1,
	miniWidth = 1,
	textSize = 180,
}

drawRadius[4] = {
	range = 1500,
	color = {0.2,0.2,1,0.75},
	text = "EMP vertical",
	width = 1,
	miniWidth = 1,
	textSize = 120,
	--stipple = {4,1000},
}

drawRadius[5] = {
	range = 600,
	color = {0.4,1,0.2,0.5},
	text = "Seismic and Tacnuke vertical",
	width = 1,
	miniWidth = 1,
	textSize = 60,
	--stipple = {4,4095},
}

local circleDivs = 64

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedup

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local spGetActiveCommand = Spring.GetActiveCommand
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetMouseState    = Spring.GetMouseState
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetGroundHeight  = Spring.GetGroundHeight
local spGetCameraState   = Spring.GetCameraState

local siloDefID = -UnitDefNames["staticmissilesilo"].id

local floor = math.floor
local cos = math.cos
local sin = math.sin
local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local glColor               = gl.Color
local glLineWidth           = gl.LineWidth
local glDepthTest           = gl.DepthTest
local glTexture             = gl.Texture
local glDrawCircle          = gl.Utilities.DrawCircle
local glDrawGroundCircle    = gl.DrawGroundCircle
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glBillboard           = gl.Billboard
local glText                = gl.Text
local glScale               = gl.Scale
local glRotate              = gl.Rotate
local glLoadIdentity        = gl.LoadIdentity
local glLineStipple         = gl.LineStipple

local mouseX, mouseZ

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawActiveCommandRanges()
	local _, cmd_id = spGetActiveCommand()
	
	if not (cmd_id and cmd_id == siloDefID) then
		return
	end
	
	local mx, my = spGetMouseState()
	local _, mouse = spTraceScreenRay(mx, my, true, true)
	
	if not mouse then
		return
	end
	
	mouseX = floor((mouse[1]+8)/16)*16
	mouseZ = floor((mouse[3]+8)/16)*16
	
	local height = spGetGroundHeight(mouseX, mouseZ)
	
	--handle COFC rotation
	local cs = spGetCameraState()
	local dx,dz = 0, 1
	if cs.ry then
		local rotY = cs.ry - 1.5707
		dx = cos(rotY)
		dz = sin(rotY)
	end
	
	for i = 1, (options.missile_silo_advanced.value and 5 or 2) do
		local radius = drawRadius[i]
		
		glLineWidth(radius.width)
		glColor(radius.color[1], radius.color[2], radius.color[3], radius.color[4] )
		if radius.stipple then
			glLineStipple(radius.stipple[1],radius.stipple[2])
		else
			glLineStipple(false)
		end
		
		glDrawGroundCircle(mouseX, 0, mouseZ, radius.range, circleDivs )
		
		glPushMatrix()
		glTranslate(mouseX + radius.range*dx,  height, mouseZ - (radius.range*dz)-5)
		glBillboard()
		glText( radius.text, 0, 0, radius.textSize, "cn")
		glPopMatrix()
	end
	
	glLineStipple(false)
	glLineWidth(1)
	glColor(1, 1, 1, 1)
end

local function DrawActiveCommandRangesMinimap(minimapX, minimapY)
	local _, cmd_id = spGetActiveCommand()
	
	if not (cmd_id and cmd_id == siloDefID) then
		return
	end
	
	if not mouseX then
		return
	end
	
	local height = spGetGroundHeight(mouseX,mouseZ)
	
	glTranslate(0,minimapY,0)
	glScale(minimapX/mapX, -minimapY/mapZ, 1)
	
	for i = 1, (options.missile_silo_advanced.value and 5 or 2) do
		local radius = drawRadius[i]
		
		glLineWidth(radius.miniWidth)
		glColor(radius.color[1], radius.color[2], radius.color[3], radius.color[4] )
		if radius.stipple then
			glLineStipple(radius.stipple[1],radius.stipple[2])
		else
			glLineStipple(false)
		end
		
		glDrawCircle(mouseX, mouseZ, radius.range)
	end
	
	glScale(1, 1, 1)
	glLineStipple(false)
	glLineWidth(1)
	glColor(1, 1, 1, 1)
end

function widget:DrawInMiniMap(minimapX, minimapY)
	DrawActiveCommandRangesMinimap(minimapX, minimapY)
end

function widget:DrawWorld()
	DrawActiveCommandRanges()
end

local function languageChanged ()
	drawRadius[1].text = WG.Translate("interface", "tacnuke_and_emp")
	drawRadius[2].text = WG.Translate("interface", "seismic")
	drawRadius[3].text = WG.Translate("interface", "emp_aoe")
	drawRadius[4].text = WG.Translate("interface", "emp_vertical")
	drawRadius[5].text = WG.Translate("interface", "tacnuke_vertical")
end

function widget:Initialize()
	WG.InitializeTranslation (languageChanged, GetInfo().name)
end

function widget:Shutdown()
	WG.ShutdownTranslation(GetInfo().name)
end
