--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Map Edge Extension",
    version   = "v0.4+",
    desc      = "Draws a mirrored map next to the edges of the real map",
    author    = "Pako",
    date      = "2010.10.27 - 2011.10.29", --YYYY.MM.DD, created - updated
    license   = "GPL",
    layer     = 0,
    enabled   = true,
    detailsDefault = 2
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
local gridTex = "LuaUI/Images/vr_grid_large.png"
local wallTex = "bitmaps/PD/hexbig.png"
--local wallTex = "bitmaps/PD/shield2.png"
--local wallTex = "LuaUI/Images/vr_grid.png"
local realTex = '$grass'
local tex = realTex

local height = 2048
local minHeight = -height/4
local maxHeight = height*3/4

local texScale = 0.01
local colorFloor = { 0.1, 0.88, 1, 1}
local colorCeiling = { 0.1, 0.88, 1, 0}

local dList
local dListWall
local mirrorShader

local umirrorX
local umirrorZ
local uup
local uleft

local island = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/View/Map/Map Extension Config'
options = {
	--when using shader the map is stored once in a DL and drawn 8 times with vertex mirroring and bending
        --when not, the map is drawn mirrored 8 times into a display list
	drawForIslands = {
		name = "Draw for islands",
		type = 'bool',
		value = false,
		desc = "Draws mirror map when map is an island",		
	},
	drawWall = {
		name = "Draw boundary wall",
		type = 'bool',
		value = true,
		desc = "Draws wall at map boundaries",		
	},        
	useShader = {
		name = "Use shader",
		type = 'bool',
		value = true,
		desc = 'Use a shader when mirroring the map',
		OnChange = function(self)
			gl.DeleteList(dList)
			widget:Initialize()
		end, 		
	},
	gridSize = {
		name = "Tile size (32-512)",
		advanced = true,
		type = 'number',
		min = 32, 
		max = 512, 
		step = 32,
		value = 32,
		desc = 'Sets tile size (smaller = more heightmap detail)',
		OnChange = function(self)
			gl.DeleteList(dList)
			widget:Initialize()
		end, 
	},
	useRealTex = {
		name = "Use realistic texture",
		type = 'bool',
		value = true,
		desc = 'Use a realistic texture instead of a VR grid',
		OnChange = function(self)
			gl.DeleteList(dList)
			if self.value then tex = realTex
			else tex = gridTex end
			widget:Initialize()
		end, 		
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

local shaderTable = {
	uniform = {
      mirrorX = 0,
      mirrorZ = 0,
      up = 0,
      left = 0,
    },
	vertex = [[
      // Application to vertex shader
      uniform float mirrorX;
      uniform float mirrorZ;
      uniform float left;
      uniform float up;

      void main()
      {
      gl_TexCoord[0]= gl_TextureMatrix[0]*gl_MultiTexCoord0;
      gl_Vertex.x = abs(mirrorX-gl_Vertex.x);
      gl_Vertex.z = abs(mirrorZ-gl_Vertex.z);

      float ff = 20000;
      if((mirrorZ && mirrorX))
        ff=ff/(pow(abs(gl_Vertex.z-up*mirrorZ)/150, 2)+pow(abs(gl_Vertex.x-left*mirrorX)/150, 2)+2);
      else if(mirrorX)
        ff=ff/(pow(abs(gl_Vertex.x-left*mirrorX)/150, 2)+2);
      else if(mirrorZ)
        ff=ff/(pow(abs(gl_Vertex.z-up*mirrorZ)/150, 2)+2);

      gl_Position  = gl_ModelViewProjectionMatrix*gl_Vertex;
	  gl_FogFragCoord = //gl_Position.z+ff;
	  length((gl_ModelViewMatrix * gl_Vertex).xyz)+ff; //see how Spring shaders do the fog and copy from there to fix this
      gl_FrontColor = gl_Color;
	  }
    ]],
}
-- place this under gl_Vertex.z = abs(mirrorZ-gl_Vertex.z); in void main() for curvature effect
--if(mirrorX)gl_Vertex.y -= pow(abs(gl_Vertex.x-left*mirrorX)/150, 2);
--if(mirrorZ)gl_Vertex.y -= pow(abs(gl_Vertex.z-up*mirrorZ)/150, 2);

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

local function DrawMapVertices(useMirrorShader)

	local floor = math.floor
	local ceil = math.ceil
	local abs = math.abs

	gl.Color(1,1,1,1)

	local function doMap(dx,dz,sx,sz)
		local Scale = options.gridSize.value
		local sggh = Spring.GetGroundHeight
		local Vertex = gl.Vertex
		local glColor = gl.Color
		local TexCoord = gl.TexCoord
		local Normal = gl.Normal
		local GetGroundNormal = Spring.GetGroundNormal
		local mapSizeX, mapSizeZ = Game.mapSizeX, Game.mapSizeZ
	
		local sten = {0, floor(Game.mapSizeZ/Scale)*Scale, 0}--do every other strip reverse
		local xm0, xm1 = 0, 0
		local xv0, xv1 = 0,math.abs(dx)+sx
		local ind = 0
		local zv
		local h

		if not useMirrorShader then
		gl.TexCoord(0, sten[2]/Game.mapSizeZ)
		Vertex(xv1, sggh(0,sten[2]),abs(dz+sten[2])+sz)--start and end with a double vertex
		end
	
		for x=0,Game.mapSizeX-Scale,Scale do
			xv0, xv1 = xv1, abs(dx+x+Scale)+sx
			xm0, xm1 = xm1, xm1+Scale
			ind = (ind+1)%2
			for z=sten[ind+1], sten[ind+2], (1+(-ind*2))*Scale do
				zv = abs(dz+z)+sz
				TexCoord(xm0/mapSizeX, z/mapSizeZ)
       -- Normal(GetGroundNormal(xm0,z))
        h = sggh(xm0,z)
				Vertex(xv0,h,zv)
				TexCoord(xm1/mapSizeX, z/mapSizeZ)
        --Normal(GetGroundNormal(xm1,z))
				h = sggh(xm1,z)
				Vertex(xv1,h,zv)
			end
		end
		if not useMirrorShader then
			Vertex(xv1,h,zv)
		end
	end

	if useMirrorShader then
		doMap(0,0,0,0)
	else
		doMap(-Game.mapSizeX,-Game.mapSizeZ,-Game.mapSizeX,-Game.mapSizeZ)
		doMap(0,-Game.mapSizeZ,0,-Game.mapSizeZ)
		doMap(-Game.mapSizeX,-Game.mapSizeZ,Game.mapSizeX,-Game.mapSizeZ)
	
		doMap(-Game.mapSizeX,0,-Game.mapSizeX,0)
		doMap(-Game.mapSizeX,0,Game.mapSizeX,0)
	
		doMap(-Game.mapSizeX,-Game.mapSizeZ,-Game.mapSizeX,Game.mapSizeZ)
		doMap(0,-Game.mapSizeZ,0,Game.mapSizeZ)
		doMap(-Game.mapSizeX,-Game.mapSizeZ,Game.mapSizeX,Game.mapSizeZ)
	end
end

local function DrawOMap(useMirrorShader)
	gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(GL.LEQUAL)
	gl.Texture(tex)
	gl.BeginEnd(GL.TRIANGLE_STRIP,DrawMapVertices, useMirrorShader)
	gl.DepthTest(false)
	gl.Color(1,1,1,1)
	gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
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
        Spring.SendCommands("luaui disablewidget External VR Grid")
        island = IsIsland()
	if gl.CreateShader and options.useShader.value then
		mirrorShader = gl.CreateShader(shaderTable)
	end
	if not mirrorShader then
		widget.DrawWorldPreUnit = function()
                        if (not island) or options.drawForIslands.value then
                            gl.DepthMask(true)
                            --gl.Texture(tex)
                            gl.CallList(dList)
                            gl.Texture(false)
                        end
		end
	else
		umirrorX = gl.GetUniformLocation(mirrorShader,"mirrorX")
		umirrorZ = gl.GetUniformLocation(mirrorShader,"mirrorZ")
		uup = gl.GetUniformLocation(mirrorShader,"up")
		uleft = gl.GetUniformLocation(mirrorShader,"left")
	end
	dList = gl.CreateList(DrawOMap, mirrorShader)
	--Spring.SetDrawGround(false)
        dListWall = gl.CreateList(DrawMapWall)
end

function widget:Shutdown()
	--Spring.SetDrawGround(true)
	gl.DeleteList(dList)
	if mirrorShader then
		gl.DeleteShader(mirrorShader)
	end
        gl.DeleteList(dListWall)
end

function widget:DrawWorldPreUnit() --is overwritten when not using the shader
    if (not island) or options.drawForIslands.value then
        local glTranslate = gl.Translate
        local glUniform = gl.Uniform
        local GamemapSizeZ, GamemapSizeX = Game.mapSizeZ,Game.mapSizeX
        
        gl.Fog(true)
        gl.FogCoord(1)
        gl.UseShader(mirrorShader)
        gl.PushMatrix()
        gl.DepthMask(true)
        gl.Texture(tex)
        if wiremap then
            gl.PolygonMode(GL.FRONT_AND_BACK, GL.LINE)
        end
        glUniform(umirrorX, GamemapSizeX)
        glUniform(umirrorZ, GamemapSizeZ)
        glUniform(uleft, 1)
        glUniform(uup, 1)
        glTranslate(-GamemapSizeX,0,-GamemapSizeZ)
        gl.CallList(dList)
        glUniform(uleft , 0)
        glTranslate(GamemapSizeX*2,0,0)
        gl.CallList(dList)
        gl.Uniform(uup, 0)
        glTranslate(0,0,GamemapSizeZ*2)
        gl.CallList(dList)
        glUniform(uleft, 1)
        glTranslate(-GamemapSizeX*2,0,0)
        gl.CallList(dList)
        
        glUniform(umirrorX, 0)
        glTranslate(GamemapSizeX,0,0)
        gl.CallList(dList)
        glUniform(uleft, 0)
        glUniform(uup, 1)
        glTranslate(0,0,-GamemapSizeZ*2)
        gl.CallList(dList)
        
        glUniform(uup, 0)
        glUniform(umirrorZ, 0)
        glUniform(umirrorX, GamemapSizeX)
        glTranslate(GamemapSizeX,0,GamemapSizeZ)
        gl.CallList(dList)
        glUniform(uleft, 1)
        glTranslate(-GamemapSizeX*2,0,0)
        gl.CallList(dList)
        if wiremap then
            gl.PolygonMode(GL.FRONT_AND_BACK, GL.FILL)
        end
        gl.DepthMask(false)
        gl.Texture(false)
        gl.PopMatrix()
        gl.UseShader(0)
        
        gl.Fog(false)
    end
end

function widget:DrawWorld()
    if options.drawWall.value then
        gl.DepthTest(GL.LEQUAL)
        gl.CallList(dListWall)
        gl.DepthTest(false)
    end
end
