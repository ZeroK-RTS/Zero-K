
function widget:GetInfo()
  return {
    name      = "Metal Spot Placer",
    desc      = "Click to make a mex table. Alt+M to toggle. Check infolog.txt for the output.",
    author    = "Google Frog",
    date      = "April 25, 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false --  loaded by default?
  }
end

include("keysym.h.lua")

------------------------------------------------
-- Speedups
------------------------------------------------
local GetActiveCommand = Spring.GetActiveCommand
local GetMouseState = Spring.GetMouseState
local TraceScreenRay = Spring.TraceScreenRay
local GetGroundInfo = Spring.GetGroundInfo
local GetGameFrame = Spring.GetGameFrame
local GetMapDrawMode = Spring.GetMapDrawMode

local glLineWidth = gl.LineWidth
local glColor = gl.Color
local glRect = gl.Rect
local glText = gl.Text
local glGetTextWidth = gl.GetTextWidth
local glPolygonMode = gl.PolygonMode
local glDrawGroundCircle = gl.DrawGroundCircle
local glUnitShape = gl.UnitShape

local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local glTranslate = gl.Translate

local GL_FRONT_AND_BACK = GL.FRONT_AND_BACK
local GL_FILL = GL.FILL

local floor = math.floor
local min, max = math.min, math.max
local sqrt = math.sqrt
local strFind = string.find
local strFormat = string.format

local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

local myTeamID = Spring.GetMyTeamID()

local mexDefID = UnitDefNames["staticmex"].id
local mexUnitDef = UnitDefNames["staticmex"]
local mexDefInfo = {
	extraction = 0.001,
	oddX = mexUnitDef.xsize % 4 == 2,
	oddZ = mexUnitDef.zsize % 4 == 2,
}

local TEXT_SIZE = 16

local TEXT_CORRECT_Y = 1.25

------------------------------------------------
-- Variables
------------------------------------------------

local centerX, centerZ

local enabled = false
local spots = {}
local extraction = 0

------------------------------------------------
-- Press Handling
------------------------------------------------

function widget:KeyPress(key, modifier, isRepeat)
	if modifier.alt then
		if key == KEYSYMS.M then
			if enabled then
				for i = 1, #spots do
					local spot = spots[i]
					Spring.Echo("{x = " .. floor(spot.x+0.5) .. ", z = " .. floor(spot.z+0.5) .. ", metal = " .. spot.metal .. "},")
				end
				spots = {}
			end
			enabled = not enabled
		end
	end
end

local function legalPos(pos)
	return pos and pos[1] > 0 and pos[3] > 0 and pos[1] < Game.mapSizeX and pos[3] < Game.mapSizeZ
end

function widget:MousePress(mx, my, button)
	if enabled and (not Spring.IsAboveMiniMap(mx, my)) then
		local _, pos = Spring.TraceScreenRay(mx, my, true)
		if legalPos(pos) then
			spots[#spots+1] = {
				x = pos[1],
				z = pos[3],
				metal = extraction,
			}
			Spring.MarkerAddPoint(pos[1],0,pos[3],#spots .. ": " ..extraction)
		end
	end
end


------------------------------------------------------------
-- Draw Metal Map Value
------------------------------------------------------------

local function DrawTextWithBackground(text, x, y, size, opt)
	local width = glGetTextWidth(text) * size
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
	
	glColor(0.25, 0.25, 0.25, 0.75)
	if (opt) then
		if (strFind(opt, "r")) then
			glRect(x, y, x - width, y + size * TEXT_CORRECT_Y)
		elseif (strFind(opt, "c")) then
			glRect(x + width * 0.5, y, x - width * 0.5, y + size * TEXT_CORRECT_Y)
		else
			glRect(x, y, x + width, y + size * TEXT_CORRECT_Y)
		end
	else
		glRect(x, y, x + width, y + size * TEXT_CORRECT_Y)
	end
	glColor(0.75, 0.75, 0.75, 1)
	glText(text, x, y, size, opt)
	
end

local function IntegrateMetal(x, z, forceUpdate)
	local newCenterX, newCenterZ
	
	if (mexDefInfo.oddX) then
		newCenterX = (floor( x / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		newCenterX = floor( x / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end
	
	if (mexDefInfo.oddZ) then
		newCenterZ = (floor( z / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		newCenterZ = floor( z / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end
	
	if (centerX == newCenterX and centerZ == newCenterZ and not forceUpdate) then
		return
	end
	
	centerX = newCenterX
	centerZ = newCenterZ
	
	local startX = floor((centerX - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local startZ = floor((centerZ - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endX = floor((centerX + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endZ = floor((centerZ + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	startX, startZ = max(startX, 0), max(startZ, 0)
	endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)
	
	local mult = mexDefInfo.extraction
	local result = 0

	for i = startX, endX do
		for j = startZ, endZ do
			local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
			local dx, dz = cx - centerX, cz - centerZ
			local dist = sqrt(dx * dx + dz * dz)

			if (dist < MEX_RADIUS) then
				local _, metal = Spring.GetGroundInfo(cx, cz)
				result = result + metal
			end
		end
	end

	extraction = result * mult
end

function widget:DrawWorld()
	if enabled then
		local mx, my = GetMouseState()
		local _, coords = TraceScreenRay(mx, my, true, true)
		
		if not coords then return end
		
		IntegrateMetal(coords[1], coords[3], false)
		
		glLineWidth(1)
		glColor(1, 0, 0, 0.5)
		glDrawGroundCircle(centerX, 0, centerZ, MEX_RADIUS, 32)
		glPushMatrix()
			glColor(1, 1, 1, 0.25)
			glTranslate(centerX, coords[2], centerZ)
			glUnitShape(mexDefID, myTeamID)
		glPopMatrix()
		glColor(1, 1, 1, 1)
	end
end

function widget:DrawScreen()
	if enabled then
		local mx, my = GetMouseState()
		local _, coords = TraceScreenRay(mx, my, true, true)
		
		if (not coords) then return end
		
		IntegrateMetal(coords[1], coords[3], forceUpdate)
		DrawTextWithBackground("\255\255\255\255Metal extraction: " .. strFormat("%.2f", extraction), mx, my, TEXT_SIZE, "d")
		glColor(1, 1, 1, 1)
	end
end
