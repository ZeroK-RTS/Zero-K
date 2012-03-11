--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Map Edge Barrier",
    version   = "v0.22",
    desc      = "Draws a vertical grid along map edge",
    author    = "Pako",
    date      = "2012.02.19 - 2012.02.21", --YYYY.MM.DD, created - updated
    license   = "GPL",
    layer     = -1,	--higher layer is loaded last
    enabled   = false,
    --detailsDefault = 2    
  }
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if VFS.FileExists("nomapedgewidget.txt") then
	return
end

local spGetGroundHeight = Spring.GetGroundHeight
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local wallTex = "bitmaps/PD/hexbig.png"
--local wallTex = "bitmaps/PD/shield2.png"
--local wallTex = "LuaUI/Images/vr_grid.png"

local height = 2048
local minHeight = -height/4
local maxHeight = height*3/4

local texScale = 0.01
local colorFloor = { 0.1, 0.88, 1, 1}
local colorCeiling = { 0.1, 0.88, 1, 0}

local dListWall

local island = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/View/Map/Edge Barrier Config'
options = {
	drawForIslands = {
		name = "Draw for islands",
		type = 'bool',
		value = true,
		desc = "Draws boundary wall when map is an island",		
	},
	wallFromOutside = {
		name = "Visible walls from outside",
		type = 'bool',
		value = false,
		desc = "Map wall is visible from the outside (e.g. when it's between camera and main map)",
                OnChange = function(self)
                        gl.DeleteList(dListWall)
                        widget:Initialize()
                end
	},        
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetGroundHeight(x, z)
	return spGetGroundHeight(x,z)
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


local function DrawMapWall()
    gl.Texture(wallTex)
    if not options.wallFromOutside.value then
        gl.Culling(GL.FRONT) --'cuts' the outside faces --remove this if you want it to draw over map too
    end
    gl.Shape( GL.TRIANGLE_STRIP,
        {
            { v = { 0, minHeight, 0},      --top left down   
                    texcoord = { 0, 0 },           
                    c = colorFloor
            },
                { v = { 0, maxHeight, 0},          
                    texcoord = { 0, height*texScale },      --top left up     
                    c = colorCeiling
            },    
            { v = { Game.mapSizeX, minHeight, 0},          
                    texcoord = { Game.mapSizeX*texScale, 0 },   --top right        
                    c = colorFloor
            },
                { v = { Game.mapSizeX, maxHeight, 0},          
                    texcoord = { Game.mapSizeX*texScale, height*texScale },           
                    c = colorCeiling
            },
            
                    { v = { Game.mapSizeX, minHeight, Game.mapSizeZ},          -- bottom right  
                    texcoord = { Game.mapSizeX*texScale+Game.mapSizeZ*texScale, 0 },        
                    c = colorFloor
            },
                { v = { Game.mapSizeX, maxHeight, Game.mapSizeZ},          
                    texcoord = { Game.mapSizeX*texScale+Game.mapSizeZ*texScale, height*texScale },           
                    c = colorCeiling
            },
            
                { v = { 0, minHeight, Game.mapSizeZ},  --bottom left        
                    texcoord = { Game.mapSizeZ*texScale, 0 },           
                    c = colorFloor
            },
                { v = { 0, maxHeight, Game.mapSizeZ},          
                    texcoord = { Game.mapSizeZ*texScale, height*texScale },           
                    c = colorCeiling
            },
            
                 { v = { 0, minHeight, 0},        --back to top right  
                    texcoord = { 0, 0 },           
                    c = colorFloor
            },
                { v = { 0, maxHeight, 0},          
                    texcoord = { 0, height*texScale },           
                    c = colorCeiling
            },
        }
    )
    gl.Culling(false)
end

function widget:Initialize()
        island = IsIsland()
        dListWall = gl.CreateList(DrawMapWall)
end

function widget:Shutdown()
        gl.DeleteList(dListWall)
end

function widget:DrawWorldPreUnit()
    if (not island) or options.drawForIslands.value then
        gl.DepthTest(GL.LEQUAL)
        gl.CallList(dListWall)
        gl.DepthTest(false)
    end
end
