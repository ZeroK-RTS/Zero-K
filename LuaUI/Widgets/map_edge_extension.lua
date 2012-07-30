--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Map Edge Extension",
    version   = "v0.4",
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
local spTraceScreenRay = Spring.TraceScreenRay
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local gridTex = "LuaUI/Images/vr_grid_large.dds"
--local gridTex = "bitmaps/PD/shield3hex.png"
local realTex = '$grass'

local dList
local mirrorShader

local umirrorX
local umirrorZ
local uup
local uleft

local island = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Graphics/Map/Map Extension Config'
options = {
	--when using shader the map is stored once in a DL and drawn 8 times with vertex mirroring and bending
        --when not, the map is drawn mirrored 8 times into a display list
	drawForIslands = {
		name = "Draw for islands",
		type = 'bool',
		value = false,
		desc = "Draws mirror map when map is an island",		
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
		desc = 'Sets tile size (smaller = more heightmap detail)\nStepsize is 32; recommend powers of 2',
		OnChange = function(self)
			gl.DeleteList(dList)
			widget:Initialize()
		end, 
	},
	useRealTex = {
		name = "Use realistic texture",
		type = 'bool',
		value = false,
		desc = 'Use a realistic texture instead of a VR grid',
		OnChange = function(self)
			gl.DeleteList(dList)
			widget:Initialize()
		end, 		
	},	
	northSouthText = {
		name = "North, East, South, & West text",
		type = 'bool',
		value = false,
		desc = 'Help you identify map direction under rotation by placing a "North/South/East/West" text on the map edges',
		OnChange = function(self)
			gl.DeleteList(dList)
			widget:Initialize()
		end, 		
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

local function TextOutside()
	if (options.northSouthText.value) then
		local mapSizeX = Game.mapSizeX
		local mapSizeZ = Game.mapSizeZ
		local average = (GetGroundHeight(mapSizeX/2,0) + GetGroundHeight(0,mapSizeZ/2) + GetGroundHeight(mapSizeX/2,mapSizeZ) +GetGroundHeight(mapSizeX,mapSizeZ/2))/4

		gl.Rotate(-90,1,0,0)
		gl.Translate (0,0,average)		
		gl.Text("North", mapSizeX/2, 200, 200, "co")
		
		gl.Rotate(-90,0,0,1)
		gl.Text("East", mapSizeZ/2, mapSizeX+200, 200, "co")
		
		gl.Rotate(-90,0,0,1)	
		gl.Text("South", -mapSizeX/2, mapSizeZ +200, 200, "co")
		
		gl.Rotate(-90,0,0,1)
		gl.Text("West", -mapSizeZ/2,200, 200, "co")
		
		-- gl.Text("North", mapSizeX/2, 100, 200, "on")
		-- gl.Text("South", mapSizeX/2,-mapSizeZ, 200, "on")
		-- gl.Text("East", mapSizeX,-(mapSizeZ/2), 200, "on")
		-- gl.Text("West", 0,-(mapSizeZ/2), 200, "on")
	end
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
        if options.useRealTex.value then gl.Texture(realTex)
	else gl.Texture(gridTex) end
	gl.BeginEnd(GL.TRIANGLE_STRIP,DrawMapVertices, useMirrorShader)
	gl.DepthTest(false)
	gl.Color(1,1,1,1)
	gl.Blending(GL.SRC_ALPHA,GL.ONE_MINUS_SRC_ALPHA)
	
	----draw map compass text
	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.Texture(false)
	gl.DepthMask(false)
	gl.DepthTest(false)
	gl.Color(1,1,1,1)
	TextOutside()
	gl.PopAttrib()
	----	
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
end

function widget:Shutdown()
	--Spring.SetDrawGround(true)
	gl.DeleteList(dList)
	if mirrorShader then
		gl.DeleteShader(mirrorShader)
	end
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
        if options.useRealTex.value then gl.Texture(realTex)
	else gl.Texture(gridTex) end
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

function widget:MousePress(x, y, button)
	local _, mpos = spTraceScreenRay(x, y, true) --//convert UI coordinate into ground coordinate.
	if mpos==nil then --//activate epic menu if mouse position is outside the map
		local _, _, meta, _ = Spring.GetModKeyState()
		if meta then  --//show epicMenu when user also press the Spacebar
			WG.crude.OpenPath(options_path) --click + space will shortcut to option-menu
			WG.crude.ShowMenu() --make epic Chili menu appear.
			return false
		end
	end
end