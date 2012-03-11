--related thread: http://springrts.com/phpbb/viewtopic.php?f=13&t=26732&start=22
function widget:GetInfo()
  return {
    name      = "External VR Grid",
    desc      = "VR grid around map",
    author    = "knorke, tweaked by KR",
    date      = "Sep 2011",
    license   = "PD",
    layer     = -3,
    enabled   = true,
    detailsDefault = 3,
  }
end

if VFS.FileExists("nomapedgewidget.txt") then
	return
end

local DspLst = nil
--local updateFrequency = 120	-- unused
local gridTex = "LuaUI/Images/vr_grid.png"
--local height = 0	-- how far above ground to draw

---magical speedups---
local math = math
local random = math.random
local spGetGroundHeight = Spring.GetGroundHeight
local glVertex = gl.Vertex
local glTexCoord = gl.TexCoord
local glColor = gl.Color
local glCreateList = gl.CreateList
local glTexRect = gl.TexRect
----------------------

local heights = {}
local island = false

--[[
local maxHillSize = 800/res
local maxPlateauSize = math.floor(maxHillSize*0.6)
local maxHeight = 300
local featureChance = 0.01
local noFeatureRange = 0
]]--

options_path = 'Settings/View/Map/Configure VR Grid'
options_order = {"mirrorHeightMap","drawForIslands","res","range"}
options = {
	mirrorHeightMap = {
		name = "Mirror heightmap",
		type = 'bool',
		value = true,
		desc = 'Mirrors heightmap on the grid',
		OnChange = function(self)
			gl.DeleteList(DspLst)
			widget:Initialize()
		end, 		
	},
	drawForIslands = {
		name = "Draw for islands",
		type = 'bool',
		value = Spring.GetConfigInt("ReflectiveWater", 0) ~= 4,
		desc = "Draws mirror grid when map is an island",		
	},	
	res = {
		name = "Tile size (64-512)",
		advanced = true,
		type = 'number',
		min = 64, 
		max = 512, 
		step = 64,
		value = 512,
		desc = 'Sets tile size (lower = more detail)\nStepsize is 64; recommend powers of 2',
		OnChange = function(self)
			gl.DeleteList(DspLst)
			widget:Initialize()
		end, 
	},
	range = {
		name = "Range (1024-8192)",
		advanced = true,
		type = 'number',
		min = 1024, 
		max = 8192, 
		step = 256,
		value = 3072,
		desc = 'How far outside the map to draw',
		OnChange = function(self)
			gl.DeleteList(DspLst)
			widget:Initialize()
		end, 
	},		
}

-- for terrain randomization - kind of primitive
--[[
local terrainFuncs = {
	ridge = function(x, z, args)
			if args.height == 0 then return end
			for a=x-args.sizeX*res, x+args.sizeX*res,res do
				for b=z-args.sizeZ*res, z+args.sizeZ*res,res do
					local distFromCenterX = math.abs(a - x)/res
					local distFromCenterZ = math.abs(b - z)/res
					local heightMod = 0
					local excessDistX, excessDistZ = 0, 0
					if distFromCenterX > args.plateauSizeX then
						excessDistX = distFromCenterX - args.plateauSizeX
					end
					if distFromCenterZ > args.plateauSizeZ then
						excessDistZ = distFromCenterZ - args.plateauSizeZ
					end
					if excessDistX == 0 and excessDistZ == 0 then
						-- do nothing
					elseif excessDistX >= excessDistZ then
						heightMod = excessDistX/(args.sizeX - args.plateauSizeX)
					elseif excessDistX < excessDistZ then
						heightMod = excessDistZ/(args.sizeZ - args.plateauSizeZ)
					end
					
					if heights[a] and heights[a][b] then
						heights[a][b] = heights[a][b] + args.height * (1-heightMod)
					end
				end
			end
			--Spring.Echo(count)
		end,
	diamondHill = function(x, z, args) end,
	mesa = function(x, z, args) end,
}
]]--
local function GetGroundHeight(x, z)
	return heights[x] and heights[x][z] or spGetGroundHeight(x,z)
end

local function IsIsland()
	local sampleDist = 512
	for i=1,Game.mapSizeX,sampleDist do
		-- top edge
		if GetGroundHeight(i, 0) > 0 then
			return false
		end
		-- bottom edge
		if GetGroundHeight(i, Game.mapSizeZ) > 0 then
			return false
		end
	end
	for i=1,Game.mapSizeZ,sampleDist do
		-- left edge
		if GetGroundHeight(0, i) > 0 then
			return false
		end
		-- right edge
		if GetGroundHeight(Game.mapSizeX, i) > 0 then
			return false
		end	
	end
	return true
end

local function InitGroundHeights()
	local res = options.res.value or 128
	local range = (options.range.value or 8192)/res
	local TileMaxX = Game.mapSizeX/res +1
	local TileMaxZ = Game.mapSizeZ/res +1
	
	for x = (-range)*res,Game.mapSizeX+range*res, res do
		heights[x] = {}
		for z = (-range)*res,Game.mapSizeZ+range*res, res do
			local px, pz
			if options.mirrorHeightMap.value then
				if (x < 0 or x > Game.mapSizeX) then	-- outside X map bounds; mirror true heightmap
					local xAbs = math.abs(x)
					local xFrac = (Game.mapSizeX ~= xAbs) and x%(Game.mapSizeX) or Game.mapSizeX
					local xFlip = -1^math.floor(x/Game.mapSizeX)
					if xFlip == -1 then
						px = Game.mapSizeX - xFrac
					else
						px = xFrac
					end
				end
				if (z < 0 or z > Game.mapSizeZ) then	-- outside Z map bounds; mirror true heightmap
					local zAbs = math.abs(z)
					local zFrac = (Game.mapSizeZ ~= zAbs) and z%(Game.mapSizeZ) or Game.mapSizeZ
					local zFlip = -1^math.floor(z/Game.mapSizeZ)
					if zFlip == -1 then
						pz = Game.mapSizeZ - zFrac
					else
						pz = zFrac
					end				
				end
			end
			heights[x][z] = GetGroundHeight(px or x, pz or z)	-- 20, 0
		end
	end
	
	--apply noise
	--[[
	for x=-range*res, (TileMaxX+range)*res,res do
		for z=-range*res, (TileMaxZ+range)*res,res do
			if (x > 0 and z > 0) then Spring.Echo(x, z) end
			if not (x + noFeatureRange > 0 and z + noFeatureRange > 0 and x - noFeatureRange < TileMaxX and z - noFeatureRange < TileMaxZ) and featureChance>math.random() then
				local args = {
					sizeX = math.random(1, maxHillSize),
					sizeZ = math.random(1, maxHillSize),
					plateauSizeX = math.random(1, maxPlateauSize),
					plateauSizeZ = math.random(1, maxPlateauSize),
					height = math.random(-maxHeight, maxHeight),
				}
				terrainFuncs.ridge(x,z,args)
			end
		end
	end	
	
	-- for testing
	local args = {
		sizeX = maxHillSize,
		sizeZ = maxHillSize,
		plateauSizeX = maxPlateauSize,
		plateauSizeZ = maxPlateauSize,
		height = maxHeight,
	}
	terrainFuncs.ridge(-600,-600,args)	
	]]--
end

--[[
function widget:GameFrame(n)
	if n % updateFrequency == 0 then
		Spring.Echo("ping")
		DspList = nil
	end
end
]]--

local function TilesVerticesOutside()
	local res = options.res.value or 128
	local range = (options.range.value or 8192)/res
	local TileMaxX = Game.mapSizeX/res +1
	local TileMaxZ = Game.mapSizeZ/res +1	
	for x=-range,TileMaxX+range,1 do
		for z=-range,TileMaxZ+range,1 do
			if (x > 0 and z > 0 and x < TileMaxX and z < TileMaxZ) then 
			else
				glTexCoord(0,0)
				glVertex(res*(x-1), GetGroundHeight(res*(x-1),res*z), res*z)
				glTexCoord(0,1)
				glVertex(res*x, GetGroundHeight(res*x,res*z), res*z)
				glTexCoord(1,1)				
				glVertex(res*x, GetGroundHeight(res*x,res*(z-1)), res*(z-1))
				glTexCoord(1,0)
				glVertex(res*(x-1), GetGroundHeight(res*(x-1),res*(z-1)), res*(z-1))
			end
		end
	end
end

local function DrawTiles()
	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.DepthTest(true)
	gl.DepthMask(true)
	gl.Texture(gridTex)
	gl.BeginEnd(GL.QUADS,TilesVerticesOutside)
	gl.Texture(false)
	gl.DepthMask(false)
	gl.DepthTest(false)
	glColor(1,1,1,1)
	gl.PopAttrib()
end

function widget:DrawWorldPreUnit()
	if (not island) or options.drawForIslands.value then
		gl.CallList(DspLst)-- Or maybe you want to keep it cached but not draw it everytime.
		-- Maybe you want Spring.SetDrawGround(false) somewhere
	end	
end

function widget:Initialize()
	Spring.SendCommands("luaui disablewidget Map Edge Extension")
	island = IsIsland()
	InitGroundHeights()
	DspLst = glCreateList(DrawTiles)
end

function widget:Shutdown()
	gl.DeleteList(DspList)
end