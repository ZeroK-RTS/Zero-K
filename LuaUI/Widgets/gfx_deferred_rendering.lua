--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
	name      = "Deferred rendering",
	version   = 3,
	desc      = "Collects and renders point and beam lights using HDR and applies bloom.",
	author    = "beherith, aeonios",
	date      = "2015 Sept.",
	license   = "GPL V2",
	layer     = 99999,
	enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_RGB16F_ARB          = 0x881B
local GL_RGB32F_ARB          = 0x8815
local GL_RGB8				 = 0x8051
local GL_MODELVIEW           = GL.MODELVIEW
local GL_NEAREST             = GL.NEAREST
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_PROJECTION          = GL.PROJECTION
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local glActiveTexture      	 = gl.ActiveTexture
local glBeginEnd             = gl.BeginEnd
local glBillboard            = gl.Billboard
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glClear				 = gl.Clear
local glColor                = gl.Color
local glColorMask            = gl.ColorMask
local glCopyToTexture        = gl.CopyToTexture
local glCreateList           = gl.CreateList
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glGetMatrixData        = gl.GetMatrixData
local glGetShaderLog         = gl.GetShaderLog
local glGetUniformLocation   = gl.GetUniformLocation
local glGetViewSizes         = gl.GetViewSizes
local glLoadIdentity         = gl.LoadIdentity
local glLoadMatrix           = gl.LoadMatrix
local glMatrixMode           = gl.MatrixMode
local glMultiTexCoord        = gl.MultiTexCoord
local glOrtho            	 = gl.Ortho
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glResetMatrices        = gl.ResetMatrices
local glTexCoord             = gl.TexCoord
local glTexture              = gl.Texture
local glTexRect              = gl.TexRect
local glRect                 = gl.Rect
local glRenderToTexture      = gl.RenderToTexture
local glRotate				 = gl.Rotate
local glUniform              = gl.Uniform
local glUniformInt           = gl.UniformInt
local glUniformMatrix        = gl.UniformMatrix
local glUseShader            = gl.UseShader
local glVertex               = gl.Vertex
local glTranslate            = gl.Translate
local spEcho                 = Spring.Echo
local spGetCameraPosition    = Spring.GetCameraPosition
local spGetCameraVectors     = Spring.GetCameraVectors
local spGetDrawFrame         = Spring.GetDrawFrame
local spIsSphereInView       = Spring.IsSphereInView
local spWorldToScreenCoords  = Spring.WorldToScreenCoords
local spTraceScreenRay       = Spring.TraceScreenRay
local spGetSmoothMeshHeight  = Spring.GetSmoothMeshHeight

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Config

local GLSLRenderer = true

options_path = 'Settings/Graphics/HDR (experimental)'
options_order = {'enableHDR'}

options = {
	enableHDR      = {type = 'bool',   name = 'Use High Dynamic Range Color',  value = true}
}

for key,option in pairs(options) do
	option.OnChange = InitialiseShaders
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vsx, vsy
local ivsx = 1.0
local ivsy = 1.0
local screenratio = 1.0
local kernelRadius = 32

-- dynamic light shaders
local depthPointShader = nil
local depthBeamShader = nil

-- HDR shader
local combineShader = nil

-- HDR textures
local screenHDR = nil

-- shader uniforms
local lightposlocPoint = nil
local lightcolorlocPoint = nil
local lightparamslocPoint = nil
local uniformEyePosPoint
local uniformViewPrjInvPoint

local lightposlocBeam  = nil
local lightpos2locBeam  = nil
local lightcolorlocBeam  = nil
local lightparamslocBeam  = nil
local uniformEyePosBeam = nil
local uniformViewPrjInvBeam = nil

local combineShaderTexture0Loc = nil

--------------------------------------------------------------------------------
--Light falloff functions: http://gamedev.stackexchange.com/questions/56897/glsl-light-attenuation-color-and-intensity-formula
--------------------------------------------------------------------------------

local verbose = false
local function VerboseEcho(...)
	if verbose then
		Spring.Echo(...)
	end
end

local collectionFunctions = {}
local collectionFunctionCount = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:ViewResize()
	vsx, vsy = gl.GetViewSizes()
	ivsx = 1.0 / vsx --we can do /n here!
	ivsy = 1.0 / vsy
	if (Spring.GetMiniMapDualScreen() == 'left') then
		vsx = vsx / 2
	end
	if (Spring.GetMiniMapDualScreen() == 'right') then
		vsx = vsx / 2
	end
	screenratio = vsy / vsx --so we dont overdraw and only always draw a square

	glDeleteTexture(screenHDR or "")
	screenHDR = nil

	if options.enableHDR.value then
		screenHDR = glCreateTexture(vsx, vsy, {
			fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
			format = GL_RGB32F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
		})

		if not screenHDR then
			Spring.Echo('Deferred Rendering: Failed to create HDR buffer!')
			options.enableHDR.value = false
		end
	end
end

widget:ViewResize()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local vertSrc = [[
  void main(void)
  {
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_Position    = gl_Vertex;
  }
]]
local fragSrc

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DeferredLighting_RegisterFunction(func)
	collectionFunctionCount = collectionFunctionCount + 1
	collectionFunctions[collectionFunctionCount] = func
end

local function CleanShaders()
	if (glDeleteShader) then
		glDeleteShader(depthPointShader)
		glDeleteShader(depthBeamShader)
		glDeleteShader(combineShader)
	end
	depthPointShader, depthBeamShader, combineShader = nil, nil, nil
end

function InitialiseShaders()

	if ((not forceNonGLSL) and Spring.GetMiniMapDualScreen() ~= 'left') then --FIXME dualscreen
		CleanShaders()
		if (not glCreateShader) then
			spEcho("gfx_deferred_rendering.lua: Shaders not found, removing self.")
			GLSLRenderer = false
			widgetHandler:RemoveWidget()
		else
			fragSrc = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\deferred_lighting.fs", VFS.ZIP)

			--Spring.Echo('gfx_deferred_rendering.lua: Shader code:', fragSrc)

			depthPointShader = glCreateShader({
				defines = {
				    "#version 120\n",
					"#define BEAM_LIGHT 0\n",
					"#define CLIP_CONTROL " .. (Platform.glSupportClipSpaceControl and 1 or 0) .. "\n"
				},
				vertex = vertSrc,
				fragment = fragSrc,
				uniformInt = {
					modelnormals = 0,
					modeldepths = 1,
					mapnormals = 2,
					mapdepths = 3,
					modelExtra = 4,
				},
			})

			if (not depthPointShader) then
				spEcho(glGetShaderLog())
				spEcho("gfx_deferred_rendering.lua: Bad depth point shader, removing self.")
				GLSLRenderer = false
				widgetHandler:RemoveWidget()
			else
				lightposlocPoint       = glGetUniformLocation(depthPointShader, "lightpos")
				lightcolorlocPoint     = glGetUniformLocation(depthPointShader, "lightcolor")
				uniformEyePosPoint     = glGetUniformLocation(depthPointShader, 'eyePos')
				uniformViewPrjInvPoint = glGetUniformLocation(depthPointShader, 'viewProjectionInv')
			end

			depthBeamShader = glCreateShader({
				defines = {
					"#version 120\n",
					"#define BEAM_LIGHT 1\n",
					"#define CLIP_CONTROL " .. (Platform.glSupportClipSpaceControl and 1 or 0) .. "\n"
				},
				vertex = vertSrc,
				fragment = fragSrc,
				uniformInt = {
					modelnormals = 0,
					modeldepths = 1,
					mapnormals = 2,
					mapdepths = 3,
					modelExtra = 4,
				},
			})

			if (not depthBeamShader) then
				spEcho(glGetShaderLog())
				spEcho("gfx_deferred_rendering.lua: Bad depth beam shader, removing self.")
				GLSLRenderer = false
				widgetHandler:RemoveWidget()
			else
				lightposlocBeam       = glGetUniformLocation(depthBeamShader, 'lightpos')
				lightpos2locBeam      = glGetUniformLocation(depthBeamShader, 'lightpos2')
				lightcolorlocBeam     = glGetUniformLocation(depthBeamShader, 'lightcolor')
				uniformEyePosBeam     = glGetUniformLocation(depthBeamShader, 'eyePos')
				uniformViewPrjInvBeam = glGetUniformLocation(depthBeamShader, 'viewProjectionInv')
			end

			if options.enableHDR.value then
				combineShader = glCreateShader({
					defines = {"#version 120\n"},
					fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\hdr.fs", VFS.ZIP),

					uniformInt = { texture0 = 0 }
				})

				if not combineShader then
					Spring.Echo('Deferred Rendering Widget: combineShader failed to compile!')
					options.enableHDR.value = false
					Spring.Echo(gl.GetShaderLog())
				end
			end

			WG.DeferredLighting_RegisterFunction = DeferredLighting_RegisterFunction
		end
		screenratio = vsy / vsx --so we dont overdraw and only always draw a square
	else
		GLSLRenderer = false
	end

	widget:ViewResize()
end

function widget:Initialize()
	if (glCreateShader == nil) then
		Spring.Echo('Deferred Rendering requires shader support!')
		widgetHandler:RemoveWidget()
		return
	end

	if (Spring.GetConfigInt("AllowDeferredMapRendering") ~= 1 or Spring.GetConfigInt("AllowDeferredModelRendering") ~= 1) then
		Spring.Echo('Deferred Rendering (gfx_deferred_rendering.lua) requires  AllowDeferredMapRendering and AllowDeferredModelRendering to be enabled in springsettings.cfg!')
		widgetHandler:RemoveWidget()
		return
	end
	
	InitialiseShaders()
end

function widget:Shutdown()
	if (GLSLRenderer) then
		CleanShaders()
		glDeleteTexture(screenHDR or "")
		screenHDR = nil
	end
end

local function DrawLightType(lights, lightsCount, lighttype) -- point = 0 beam = 1
	--Spring.Echo('Camera FOV = ', Spring.GetCameraFOV()) -- default TA cam fov = 45
	--set uniforms:
	local cpx, cpy, cpz = spGetCameraPosition()
	if lighttype == 0 then --point
		glUseShader(depthPointShader)
		glUniform(uniformEyePosPoint, cpx, cpy, cpz)
		glUniformMatrix(uniformViewPrjInvPoint,  "viewprojectioninverse")
	else --beam
		glUseShader(depthBeamShader)
		glUniform(uniformEyePosBeam, cpx, cpy, cpz)
		glUniformMatrix(uniformViewPrjInvBeam,  "viewprojectioninverse")
	end

	glTexture(0, "$model_gbuffer_normtex")
	glTexture(1, "$model_gbuffer_zvaltex")
	glTexture(2, "$map_gbuffer_normtex")
	glTexture(3, "$map_gbuffer_zvaltex")
	glTexture(4, "$model_gbuffer_spectex")

	local cx, cy, cz = spGetCameraPosition()
	for i = 1, lightsCount do
		local light = lights[i]
		local param = light.param
		if verbose then
			VerboseEcho('gfx_deferred_rendering.lua: Light being drawn:', i)
			Spring.Utilities.TableEcho(light)
		end
		if lighttype == 0 then -- point
			local lightradius = param.radius
			--Spring.Echo("Drawlighttype position = ", light.px, light.py, light.pz)
			local sx, sy, sz = spWorldToScreenCoords(light.px, light.py, light.pz) -- returns x, y, z, where x and y are screen pixels, and z is z buffer depth.

			-- prevent sharp cutoffs when projectile is slightly offscreen
			sx = math.max(0,sx)
			sx = math.min(sx,vsx)

			sx = sx/vsx
			sy = sy/vsy --since FOV is static in the Y direction, the Y ratio is the correct one
			local dist_sq = (light.px-cx)^2 + (light.py-cy)^2 + (light.pz-cz)^2
			local ratio = lightradius / math.sqrt(dist_sq) * 1.5
			glUniform(lightposlocPoint, light.px, light.py, light.pz, param.radius) --in world space
			glUniform(lightcolorlocPoint, param.r * light.colMult, param.g * light.colMult, param.b * light.colMult, 1)
			glTexRect(
				math.max(-1 , (sx-0.5)*2-ratio*screenratio),
				math.max(-1 , (sy-0.5)*2-ratio),
				math.min( 1 , (sx-0.5)*2+ratio*screenratio),
				math.min( 1 , (sy-0.5)*2+ratio),
				math.max( 0 , sx - 0.5*ratio*screenratio),
				math.max( 0 , sy - 0.5*ratio),
				math.min( 1 , sx + 0.5*ratio*screenratio),
				math.min( 1 , sy + 0.5*ratio)
			) -- screen size goes from -1, -1 to 1, 1; uvs go from 0, 0 to 1, 1
		end
		if lighttype == 1 then -- beam
			local lightradius = 0
			local px = light.px+light.dx*0.5
			local py = light.py+light.dy*0.5
			local pz = light.pz+light.dz*0.5
			local lightradius = param.radius + math.sqrt(light.dx^2 + light.dy^2 + light.dz^2)*0.5
			VerboseEcho("Drawlighttype position = ", light.px, light.py, light.pz)
			local sx, sy, sz = spWorldToScreenCoords(px, py, pz) -- returns x, y, z, where x and y are screen pixels, and z is z buffer depth.

			-- prevent sharp cutoffs when beam is slightly offscreen
			sx = math.max(0,sx)
			sx = math.min(sx,vsx)
			
			sx = sx/vsx
			sy = sy/vsy --since FOV is static in the Y direction, the Y ratio is the correct one
			local dist_sq = (px-cx)^2 + (py-cy)^2 + (pz-cz)^2
			local ratio = lightradius / math.sqrt(dist_sq)
			ratio = ratio*2

			glUniform(lightposlocBeam, light.px, light.py, light.pz, param.radius) --in world space
			glUniform(lightpos2locBeam, light.px+light.dx, light.py+light.dy+24, light.pz+light.dz, param.radius) --in world space, the magic constant of +24 in the Y pos is needed because of our beam distance calculator function in GLSL
			glUniform(lightcolorlocBeam, param.r * light.colMult, param.g * light.colMult, param.b * light.colMult, 1)
			--TODO: use gl.Shape instead, to avoid overdraw
			glTexRect(
				math.max(-1 , (sx-0.5)*2-ratio*screenratio),
				math.max(-1 , (sy-0.5)*2-ratio),
				math.min( 1 , (sx-0.5)*2+ratio*screenratio),
				math.min( 1 , (sy-0.5)*2+ratio),
				math.max( 0 , sx - 0.5*ratio*screenratio),
				math.max( 0 , sy - 0.5*ratio),
				math.min( 1 , sx + 0.5*ratio*screenratio),
				math.min( 1 , sy + 0.5*ratio)
			) -- screen size goes from -1, -1 to 1, 1; uvs go from 0, 0 to 1, 1
		end
	end
	glTexture(0, false)
	glTexture(1, false)
	glTexture(2, false)
	glTexture(3, false)
	glTexture(4, false)
	glUseShader(0)
end

local function renderToTextureFunc(tex, s, t)
	glTexture(tex)
	glTexRect(-1 * s, -1 * t,  1 * s, 1 * t)
	glTexture(false)
end

local function mglRenderToTexture(FBOTex, tex, s, t)
	glRenderToTexture(FBOTex, renderToTextureFunc, tex, s, t)
end

local function Bloom()
	gl.Color(1, 1, 1, 1)

	glUseShader(combineShader)
		glTexture(0, screenHDR)
		glTexRect(0, 0, vsx, vsy, false, true)
		glTexture(0, false)
	glUseShader(0)
end

function widget:DrawScreenEffects()
	if not (GLSLRenderer) then
		Spring.Echo('Removing deferred rendering widget: failed to use GLSL shader')
		widgetHandler:RemoveWidget()
		return
	end

	if options.enableHDR.value then
		glCopyToTexture(screenHDR, 0, 0, 0, 0, vsx, vsy) -- copy the screen to an HDR texture
	end

	local beamLights = {}
	local beamLightCount = 0
	local pointLights = {}
	local pointLightCount = 0

	for i = 1, collectionFunctionCount do
		beamLights, beamLightCount, pointLights, pointLightCount = collectionFunctions[i](beamLights, beamLightCount, pointLights, pointLightCount)
	end

	glBlending(GL.DST_COLOR, GL.ONE) -- Set add blending mode

	if beamLightCount > 0 then
		if options.enableHDR.value then
			glRenderToTexture(screenHDR, DrawLightType, beamLights, beamLightCount, 1)
		else
			DrawLightType(beamLights, beamLightCount, 1)
		end
	end
	if pointLightCount > 0 then
		if options.enableHDR.value then
			glRenderToTexture(screenHDR, DrawLightType, pointLights, pointLightCount, 0)
		else
			DrawLightType(pointLights, pointLightCount, 0)
		end
	end

	glBlending(false)

	if options.enableHDR.value then
		Bloom()
	end
end
