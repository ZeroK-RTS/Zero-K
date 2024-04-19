if gadgetHandler:IsSyncedCode() then
	return false
end

if not VFS.FileExists("mapconfig/texture_generator_config.lua", VFS.MAP) then
	return false
end

if not gl.CreateShader then
	Spring.Log("Map Texture Generator (generic)", LOG.WARNING, "gl.CreateShader unsupported")
	return false
end

function gadget:GetInfo()
	return {
		name      = "Map Texture Generator (generic)",
		desc      = "Applies basic textures on maps based on slopemap",
		author    = "Anarchid",
		date      = "26 September 2021",
		license   = "GNU GPL, v2 or later",
		layer     = 10,
		enabled   = true,
	}
end

-- not actually used yet, any configuration used below is from Random Plateaus v1.1, verbatim
local config = VFS.Include("mapconfig/texture_generator_config.lua", nil, VFS.MAP)

local MAP_X = Game.mapSizeX
local MAP_Z = Game.mapSizeZ

local SQUARE_SIZE = 1024
local SQUARES_X = MAP_X/SQUARE_SIZE
local SQUARES_Z = MAP_Z/SQUARE_SIZE

local VEH_NORMAL      = 0.892
local BOT_NORMAL_PLUS = 0.85
local BOT_NORMAL      = 0.585
local SHALLOW_HEIGHT  = -22

local USE_SHADING_TEXTURE = (Spring.GetConfigInt("AdvMapShading") == 1)

local spSetMapSquareTexture = Spring.SetMapSquareTexture
local spGetMapSquareTexture = Spring.GetMapSquareTexture
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight

local glTexture         = gl.Texture
local glColor           = gl.Color
local glCreateTexture   = gl.CreateTexture
local glTexRect         = gl.TexRect
local glRect            = gl.Rect
local glDeleteTexture   = gl.DeleteTexture
local glDeleteShader    = gl.DeleteShader
local glRenderToTexture = gl.RenderToTexture
local glCreateShader    = gl.CreateShader
local glUseShader       = gl.UseShader
local glGetUniformLocation   = gl.GetUniformLocation
local glUniform              = gl.Uniform

local GL_RGBA = 0x1908

local GL_RGBA16F = 0x881A
local GL_RGBA32F = 0x8814

local floor  = math.floor
local random = math.random

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local initialized, mapfullyprocessed = false, false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local coroutine = coroutine
local Sleep     = coroutine.yield
local activeCoroutine

local function StartScript(fn)
	local co = coroutine.create(fn)
	activeCoroutine = co
end

local function UpdateCoroutines()
	if activeCoroutine then
		if coroutine.status(activeCoroutine) ~= "dead" then
			assert(coroutine.resume(activeCoroutine))
		else
			activeCoroutine = nil
		end
	end
end

local RATE_LIMIT = 12000

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DrawTextureOnSquare(x, z, size, sx, sz, xsize, zsize)
	local x1 = 2*x/SQUARE_SIZE - 1
	local z1 = 2*z/SQUARE_SIZE - 1
	local x2 = 2*(x+size)/SQUARE_SIZE - 1
	local z2 = 2*(z+size)/SQUARE_SIZE - 1
	glTexRect(x1, z1, x2, z2, sx, sz, sx+xsize, sz+zsize)
end

local function LowerHalfRotateSymmetry()
	glTexRect(-1, -1, 1, 1, 0, 0, 1, 1)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function RateCheck(loopCount, texture, color)
	if loopCount > RATE_LIMIT then
		loopCount = 0
		Sleep()
		if texture then
			glTexture(texture)
		elseif color then
			glColor(color)
		end
	end
	return loopCount + 1
end

local function SetMapTexture(texturePool, mapTexX, mapTexZ, topTexX, topTexZ, topTexAlpha, splatTexX, splatTexZ, splatTexCol, mapHeight)
	local DrawStart = Spring.GetTimer()
	local usedsplat
	local usedgrass
	local usedminimap

	local fulltex = gl.CreateTexture(MAP_X, MAP_Z,
		{
			border = false,
			min_filter = GL.LINEAR,
			mag_filter = GL.LINEAR,
			wrap_s = GL.CLAMP_TO_EDGE,
			wrap_t = GL.CLAMP_TO_EDGE,
			fbo = true,
		}
	)

	-- specular probably doesn't need to be entirely full reso tbf
	local spectex = gl.CreateTexture(MAP_X, MAP_Z,
		{
			border = false,
			min_filter = GL.LINEAR,
			mag_filter = GL.LINEAR,
			wrap_s = GL.CLAMP_TO_EDGE,
			wrap_t = GL.CLAMP_TO_EDGE,
			fbo = true,
		}
	)

	Spring.Echo("Generated blank fulltex")
	local topSplattex = USE_SHADING_TEXTURE and gl.CreateTexture(MAP_X, MAP_Z,
		{
			format = GL_RGBA32F,
			border = false,
			min_filter = GL.LINEAR,
			mag_filter = GL.LINEAR,
			wrap_s = GL.CLAMP_TO_EDGE,
			wrap_t = GL.CLAMP_TO_EDGE,
			fbo = true,
		}
	)
	Spring.Echo("Generated blank splattex")

	local vertSrc = [[
		void main(void)
		{
		  gl_TexCoord[0] = gl_MultiTexCoord0;
		  gl_Position    = gl_Vertex;
		}
	  ]]

	local fragSrc = VFS.LoadFile("shaders/map_diffuse_generator.glsl");

	local diffuseShader = glCreateShader({
		vertex = vertSrc,
		fragment = fragSrc,
		uniformInt = {
			tex0 = 0,
			tex1 = 1,
			tex2 = 2,
			tex3 = 3,
			tex4 = 4,
			tex5 = 5,
			tex6 = 6,
			tex7 = 7,
			tex8 = 8,
			tex9 = 9,
			tex10 = 10,
			tex11 = 11,
		},
		uniformFloat = {
			phaseHeights = config.phaseHeights or
				{ 60,  85, -- beach ends at 60, dirt starts at 85 (transition inbetween)
				 110, 145, -- dirt ends at 110, lowland grass starts at 145
				 180, 210, -- lowland, highland grass
				 255, 380, -- highland g., mountains
			},
		},
	})

	Spring.Echo(gl.GetShaderLog())
	if(diffuseShader) then
		Spring.Echo("Diffuse shader created");
	else
		Spring.Echo("SHADER ERROR");
		Spring.Echo(gl.GetShaderLog())

		mapfullyprocessed = true
		return
	end

	local function DrawLoop()
		local loopCount = 0
		glColor(1, 1, 1, 1)
		local ago = Spring.GetTimer()

		Spring.Echo("Begin shader draw")

		local TEXTURES_FOLDER = ":l:bitmaps/map_texture_generator/temperate/"

		glRenderToTexture(fulltex, function ()
			glUseShader(diffuseShader)
			glTexture(0, "$heightmap")
			glTexture(0, false)
			glTexture(1,"$normals")
			glTexture(1, false)
			glTexture(2, TEXTURES_FOLDER .. "diffuse/flats.png");
			glTexture(2, false)
			glTexture(3, TEXTURES_FOLDER .. "diffuse/cliffs.png");
			glTexture(3, false)
			glTexture(4, TEXTURES_FOLDER .. "diffuse/beach.jpg");
			glTexture(4, false)
			glTexture(5, TEXTURES_FOLDER .. "diffuse/midlands.png");
			glTexture(5, false)
			glTexture(6, TEXTURES_FOLDER .. "diffuse/highlands.png");
			glTexture(6, false)
			glTexture(7, TEXTURES_FOLDER .. "diffuse/slopes.png");
			glTexture(7, false)
			glTexture(8, TEXTURES_FOLDER .. "diffuse/ramps.png");
			glTexture(8, false)
			glTexture(9, TEXTURES_FOLDER .. "diffuse/cloudgrass.png");
			glTexture(9, false)
			glTexture(10, TEXTURES_FOLDER .. "diffuse/cloudgrassdark.png");
			glTexture(10, false)
			glTexture(11, TEXTURES_FOLDER .. "diffuse/sand.png");
			glTexture(11, false)
			gl.TexRect(-1,-1,1,1,false,true)
			glUseShader(0)
		end)

		Sleep()
		Spring.ClearWatchDogTimer()

		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/flats.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/cliffs.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/beach.jpg");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/midlands.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/highlands.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/slopes.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/ramps.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/cloudgrass.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/cloudgrassdark.png");
		glDeleteTexture(TEXTURES_FOLDER .. "diffuse/sand.png");
		glTexture(false)

		local cur = Spring.GetTimer()
		Spring.Echo("FullTex rendered in: "..(Spring.DiffTimers(cur, ago, true)))
		local ago2 = Spring.GetTimer()
		gl.Blending(GL.ONE, GL.ZERO)


		Sleep()
		Spring.ClearWatchDogTimer()
		cur = Spring.GetTimer()
		Spring.Echo("Splattex rendered in: "..(Spring.DiffTimers(cur, ago2, true)))
		glColor(1, 1, 1, 1)


		local agoSpec = Spring.GetTimer();
		Spring.Echo("Starting to render specular")
		glRenderToTexture(spectex, function ()
			glUseShader(diffuseShader)
			glTexture(0, "$heightmap")
			glTexture(0, false)
			glTexture(1,"$normals")
			glTexture(1, false)
			glTexture(2, TEXTURES_FOLDER .. "specular/flats.png");
			glTexture(2, false)
			glTexture(3, TEXTURES_FOLDER .. "specular/cliffs.png");
			glTexture(3, false)
			glTexture(4, TEXTURES_FOLDER .. "specular/beach.png");
			glTexture(4, false)
			glTexture(5, TEXTURES_FOLDER .. "specular/cloudgrass.png");
			glTexture(5, false)
			glTexture(6, TEXTURES_FOLDER .. "specular/highlands.png");
			glTexture(6, false)
			glTexture(7, TEXTURES_FOLDER .. "specular/slopes.png");
			glTexture(7, false)
			glTexture(8, TEXTURES_FOLDER .. "specular/ramps.png");
			glTexture(8, false)
			glTexture(9, TEXTURES_FOLDER .. "specular/cloudgrass.png");
			glTexture(9, false)
			glTexture(10, TEXTURES_FOLDER .. "specular/cloudgrassdark.png");
			glTexture(10, false)
			glTexture(11, TEXTURES_FOLDER .. "specular/sand.png");
			glTexture(11, false)
			gl.TexRect(-1,-1,1,1,false,true)
			glUseShader(0)
		end)
		glDeleteTexture(TEXTURES_FOLDER .. "specular/flats.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/cliffs.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/beach.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/cloudgrass.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/highlands.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/slopes.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/ramps.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/cloudgrass.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/cloudgrassdark.png");
		glDeleteTexture(TEXTURES_FOLDER .. "specular/sand.png");
		glTexture(false)
		glDeleteShader(diffuseShader);

		cur = Spring.GetTimer()
		Spring.Echo("Specular rendered in "..(Spring.DiffTimers(cur, ago, true)))

		Spring.Echo("Starting to render SquareTextures")
		local splattex = USE_SHADING_TEXTURE and gl.CreateTexture(MAP_X, MAP_Z,
			{
				format = GL_RGBA32F,
				border = false,
				min_filter = GL.LINEAR,
				mag_filter = GL.LINEAR,
				wrap_s = GL.CLAMP_TO_EDGE,
				wrap_t = GL.CLAMP_TO_EDGE,
				fbo = true,
			}
		)

		gl.Blending(false)

		local texOut = fulltex

		GG.mapgen_squareTexture  = {}
		GG.mapgen_currentTexture = {}
		local ago3 = Spring.GetTimer()
		for x = 0, MAP_X - 1, SQUARE_SIZE do -- Create sqr textures for each sqr
			local sx = floor(x/SQUARE_SIZE)
			GG.mapgen_squareTexture[sx]  = {}
			GG.mapgen_currentTexture[sx] = {}
			for z = 0, MAP_Z - 1, SQUARE_SIZE do
				local sz = floor(z/SQUARE_SIZE)
				local squareTex = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE,
					{
						border = false,
						min_filter = GL.LINEAR,
						mag_filter = GL.LINEAR,
						wrap_s = GL.CLAMP_TO_EDGE,
						wrap_t = GL.CLAMP_TO_EDGE,
						fbo = true,
					}
				)
				local origTex = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE,
					{
						border = false,
						min_filter = GL.LINEAR,
						mag_filter = GL.LINEAR,
						wrap_s = GL.CLAMP_TO_EDGE,
						wrap_t = GL.CLAMP_TO_EDGE,
						fbo = true,
					}
				)
				local curTex = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE,
					{
						border = false,
						min_filter = GL.LINEAR,
						mag_filter = GL.LINEAR,
						wrap_s = GL.CLAMP_TO_EDGE,
						wrap_t = GL.CLAMP_TO_EDGE,
						fbo = true,
					}
				)
				glTexture(texOut)

				glRenderToTexture(squareTex, DrawTextureOnSquare, 0, 0, SQUARE_SIZE, x/MAP_X, z/MAP_Z, SQUARE_SIZE/MAP_X, SQUARE_SIZE/MAP_Z)
				glRenderToTexture(origTex  , DrawTextureOnSquare, 0, 0, SQUARE_SIZE, x/MAP_X, z/MAP_Z, SQUARE_SIZE/MAP_X, SQUARE_SIZE/MAP_Z)
				glRenderToTexture(curTex   , DrawTextureOnSquare, 0, 0, SQUARE_SIZE, x/MAP_X, z/MAP_Z, SQUARE_SIZE/MAP_X, SQUARE_SIZE/MAP_Z)

				GG.mapgen_squareTexture[sx][sz]  = origTex
				GG.mapgen_currentTexture[sx][sz] = curTex
				GG.mapgen_fulltex = fulltex

				glTexture(false)
				gl.GenerateMipmap(squareTex)
				Spring.SetMapSquareTexture(sx, sz, squareTex)
			end
		end
		cur = Spring.GetTimer()
		Spring.Echo("All squaretex rendered and applied in: "..(Spring.DiffTimers(cur, ago3, true)))

		Spring.SetMapShadingTexture("$ssmf_specular", spectex)
		Spring.Echo("specular applied")

		Spring.SetMapShadingTexture("$grass", texOut)

		usedgrass = texOut
		Spring.SetMapShadingTexture("$minimap", texOut)
		usedminimap = texOut
		Spring.Echo("Applied grass and minimap textures")

		gl.DeleteTextureFBO(fulltex)

		if texOut and texOut ~= usedgrass and texOut ~= usedminimap then
			glDeleteTexture(texOut)
			texOut = nil
		end

		if splattex then
			texOut = splattex
			Spring.SetMapShadingTexture("$ssmf_splat_distr", texOut)
			usedsplat = texOut
			Spring.Echo("Applied splat texture")
			gl.DeleteTextureFBO(splattex)
			if texOut and texOut ~= usedsplat then
				glDeleteTexture(texOut)
				if splattex and texOut == splattex then
					splattex = nil
				end
				texOut = nil
			end
			if splattex and splattex ~= usedsplat then
				glDeleteTexture(splattex)
				splattex = nil
			end
		end
		local DrawEnd = Spring.GetTimer()
		Spring.Echo("map fully processed in: "..(Spring.DiffTimers(DrawEnd, DrawStart, true)))

		mapfullyprocessed = true
	end

	StartScript(DrawLoop)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vehTexPool, botTexPool, spiderTexPool, uwTexPool
local mapTexX, mapTexZ, topTexX, topTexZ, topTexAlpha, splatTexX, splatTexZ, splatTexCol, mapHeight

function gadget:DrawGenesis()
	if mapfullyprocessed then
		gadgetHandler:RemoveGadget()
		return
	end

	if activeCoroutine then
		UpdateCoroutines()
	else
		SetMapTexture(texturePool, mapTexX, mapTexZ, topTexX, topTexZ, topTexAlpha, splatTexX, splatTexZ, splatTexCol, mapHeight)
	end
end

function gadget:MousePress(x, y, button)
	return (button == 1) and (not mapfullyprocessed)
end

