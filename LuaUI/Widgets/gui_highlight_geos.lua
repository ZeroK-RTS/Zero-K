
function widget:GetInfo()
	return {
		name      = 'Highlight Geos',
		desc      = 'Highlights geothermal spots when in metal map view',
		author    = 'Niobium, modified by GoogleFrog',
		version   = '1.0',
		date      = 'Mar, 2011',
		license   = 'GNU GPL, v2 or later',
		layer     = 0,
		enabled   = true,  --  loaded by default?
	}
end

----------------------------------------------------------------
-- Globals
----------------------------------------------------------------
local geoDisplayList

----------------------------------------------------------------
-- Speedups
----------------------------------------------------------------
local glLineWidth = gl.LineWidth
local glDepthTest = gl.DepthTest
local glCallList = gl.CallList
local spGetMapDrawMode = Spring.GetMapDrawMode
local spGetActiveCommand = Spring.GetActiveCommand
local spGetGameFrame        = Spring.GetGameFrame


local geoDefID = UnitDefNames["geo"].id

local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ
local mapXinv = 1/mapX
local mapZinv = 1/mapZ

local size = math.max(mapX,mapZ) * 60/4096

----------------------------------------------------------------
-- Functions
----------------------------------------------------------------
local function PillarVerts(x, y, z)
	gl.Color(1, 1, 0, 1)
	gl.Vertex(x, y, z)
	gl.Color(1, 1, 0, 0)
	gl.Vertex(x, y + 1000, z)
end

local geos = {}

local function HighlightGeos()
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local fID = features[i]
		if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
			local fx, fy, fz = Spring.GetFeaturePosition(fID)
			gl.BeginEnd(GL.LINE_STRIP, PillarVerts, fx, fy, fz)
			geos[#geos+1] = {x = fx, z = fz}
		end
	end
end

----------------------------------------------------------------
-- Callins
----------------------------------------------------------------
local drawGeos = false

function widget:Shutdown()
	if geoDisplayList then
		gl.DeleteList(geoDisplayList)
	end
end

function widget:DrawWorld()
	
	local _, cmdID = spGetActiveCommand()
	drawGeos = spGetMapDrawMode() == 'metal' or -geoDefID == cmdID or spGetGameFrame() < 1 or (WG.GetWidgetOption and WG.GetWidgetOption('Chili Minimap','Settings/Interface/Map','alwaysDisplayMexes').value)
	
	if drawGeos then
		
		if not geoDisplayList then
			geoDisplayList = gl.CreateList(HighlightGeos)
		end
		
		glLineWidth(20)
		glDepthTest(true)
		glCallList(geoDisplayList)
		glLineWidth(1)
	end
end

local function drawMinimapGeos(x,z)
	gl.Vertex(x - size,0,z - size)
	gl.Vertex(x + size,0,z + size)
	gl.Vertex(x + size,0,z - size)
	gl.Vertex(x - size,0,z + size)
end

function widget:DrawInMiniMap()

	if drawGeos then
	
		gl.LoadIdentity()
		gl.Translate(0,1,0)
		gl.Scale(mapXinv , -mapZinv, 1)
		gl.Rotate(270,1,0,0)
		gl.LineWidth(2)
		gl.Lighting(false)
		gl.Color(1,1,0,0.7)
		for i = 1, #geos do
			local geo = geos[i]
			gl.BeginEnd(GL.LINES,drawMinimapGeos,geo.x,geo.z)
		end
		
		gl.LineWidth(0)
		gl.Color(1,1,1,1)
	end
end