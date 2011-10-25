--related thread: http://springrts.com/phpbb/viewtopic.php?f=13&t=26732&start=22
function widget:GetInfo()
  return {
    name      = "Map External Grid",
    desc      = "VR grid around map",
    author    = "knorke, tweaked by KR",
    date      = "Sep 2011",
    license   = "PD",
    layer     = -3,
    enabled   = false
  }
end

-- TODO: make res and range settable in options

local DspLst=nil
local res = 200		-- smaller = higher resolution (decreases performance)
local TileMaxX = Game.mapSizeX/res +1
local TileMaxZ = Game.mapSizeZ/res +1
local localAllyID = Spring.GetLocalAllyTeamID ()
local updateFrequency = 120
local gridTex = "LuaUI/Images/vr_grid.png"
local range = 72	-- how far out of the map to draw (decreases performance)
local height = 0	-- how far above ground to draw

---magical speedups---
local random = math.random
local spGetGroundHeight = Spring.GetGroundHeight
local glVertex = gl.Vertex
local glTexCoord = gl.TexCoord
local glColor = gl.Color
local glCreateList = gl.CreateList
local glTexRect = gl.TexRect
----------------------

--[[
function widget:GameFrame(n)
	if n % updateFrequency == 0 then
		Spring.Echo("ping")
		DspList = nil
	end
end
]]--

function widget:Initialize()
end

local function TilesVerticesOutside()
	for x=-range,TileMaxX+range,1 do
		for z=-range,TileMaxZ+range,1 do
			if (x > 0 and z > 0 and x < TileMaxX and z < TileMaxZ) then 
			else
				--height = random(-20,20)
				glTexCoord(0,0)
				glVertex(res*(x-1), spGetGroundHeight(res*(x-1),res*z), res*z)
				glTexCoord(0,1)
				glVertex(res*x, spGetGroundHeight(res*x,res*z), res*z)
				glTexCoord(1,1)				
				glVertex(res*x, spGetGroundHeight(res*x,res*(z-1)), res*(z-1))
				glTexCoord(1,0)
				glVertex(res*(x-1), spGetGroundHeight(res*(x-1),res*(z-1)), res*(z-1))
			end
		end
	end
end

local function DrawTiles()
	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.DepthTest(true)
	gl.DepthMask(true)
	gl.Texture(gridTex)
	--gl.TexGen(GL.TEXTURE_GEN_MODE, true)
	--glColor(1,1,1,1)
	gl.BeginEnd(GL.QUADS,TilesVerticesOutside)
	--TilesVerticesOutside()
	--DrawSquares()
	--gl.TexGen(GL.TEXTURE_GEN_MODE, false)
	gl.Texture(false)
	gl.DepthMask(false)
	gl.DepthTest(false)
	glColor(1,1,1,1)
	gl.PopAttrib()
end

function widget:DrawWorld()
	if not DspLst then
		DspLst=glCreateList(DrawTiles)
	end
	gl.CallList(DspLst)-- Or maybe you want to keep it cached but not draw it everytime.
	-- Maybe you want Spring.SetDrawGround(false) somewhere
end