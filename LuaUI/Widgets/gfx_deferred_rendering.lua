--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
	name      = "Deferred rendering",
	version   = 3,
	desc      = "Collects and renders point and beam lights.",
	author    = "beherith",
	date      = "2015 Sept.",
	license   = "GPL V2",
	layer     = -1000000000,
	enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GL_RGB16F_ARB          = 0x881B
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
local glDepthMask            = gl.DepthMask
local glDepthTest            = gl.DepthTest
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

options_path = 'Settings/Graphics/HDR'
options_order = {'useHDR', 'useBloom', 'illumThreshold', 'maxBrightness'}

options = {
	useHDR	 		= { type='bool', 	name='Use High Dynamic Range Color', 	value=true,	noHotkey = true,advanced = false,	},
	useBloom 		= { type='bool', 	name='Apply Bloom Effect', 	value=true,	noHotkey = true,advanced = false,	},
	illumThreshold 	= { type='number', 		name='Illumination Threshold', 	value=0.65, 		min=0, max=1,step=0.05, 	},
	maxBrightness 	= { type='number', 		name='Maximum Highlight Brightness', 			value=0.5,		min=0.05, max=1.0,step=0.05,},
}

-- config params
local useBloom = 1					-- apply the bloom effect? [0 | 1]
local useHDR = 1					-- use high dynamic range color? [0 | 1]
local maxBrightness = 0.5			-- maximum brightness of bloom additions [1, n]
local illumThreshold = 0.65			-- how bright does a fragment need to be before being considered a glow source? [0, 1]

local function OnchangeFunc()
	useBloom 		= options.useBloom.value and 1 or 0
	useHDR	 		= options.useHDR.value and 1 or 0
	maxBrightness 	= options.maxBrightness.value
	illumThreshold 	= options.illumThreshold.value
end
for key,option in pairs(options) do
	option.OnChange = OnchangeFunc
end
OnchangeFunc()

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
local depthPointShader
local depthBeamShader

-- bloom shaders
local brightShader
local blurShaderH71
local blurShaderV71
local combineShader

-- HDR textures
local screenHDR
local brightTexture1
local brightTexture2

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
local uniformEyePosBeam 
local uniformViewPrjInvBeam 

-- bloom shader uniform locations
local brightShaderText0Loc = nil
local brightShaderInvRXLoc = nil
local brightShaderInvRYLoc = nil
local brightShaderIllumLoc = nil

local blurShaderH51Text0Loc = nil
local blurShaderH51InvRXLoc = nil
local blurShaderH51FragLoc = nil
local blurShaderV51Text0Loc = nil
local blurShaderV51InvRYLoc = nil
local blurShaderV51FragLoc = nil

local blurShaderH71Text0Loc = nil
local blurShaderH71InvRXLoc = nil
local blurShaderH71FragLoc = nil
local blurShaderV71Text0Loc = nil
local blurShaderV71InvRYLoc = nil
local blurShaderV71FragLoc = nil

local combineShaderUseBloomLoc = nil
local combineShaderUseHDRLoc = nil
local combineShaderTexture0Loc = nil
local combineShaderTexture1Loc = nil
local combineShaderIllumLoc = nil
local combineShaderFragLoc = nil

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
	
	glDeleteTexture(brightTexture1 or "")
	glDeleteTexture(brightTexture2 or "")
	glDeleteTexture(screenHDR or "")
	screenHDR = glCreateTexture(vsx, vsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGB16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	brightTexture1 = glCreateTexture(vsx/4, vsy/4, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGB16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	brightTexture2 = glCreateTexture(vsx/4, vsy/4, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGB16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	kernelRadius = vsx / 36.0
	
	if not brightTexture1 or not brightTexture2 or not screenHDR then
		Spring.Echo('Deferred Rendering: Failed to create offscreen buffers!') 
		widgetHandler:RemoveWidget()
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

function widget:Initialize()
	if (glCreateShader == nil) then
		Spring.Echo('Deferred Rendering requires shader support!') 
		widgetHandler:RemoveWidget()
		return
	end
	
	Spring.SetConfigInt("AllowDeferredMapRendering", 1)
	Spring.SetConfigInt("AllowDeferredModelRendering", 1)

	if (Spring.GetConfigString("AllowDeferredMapRendering") == '0' or Spring.GetConfigString("AllowDeferredModelRendering") == '0') then
		Spring.Echo('Deferred Rendering (gfx_deferred_rendering.lua) requires  AllowDeferredMapRendering and AllowDeferredModelRendering to be enabled in springsettings.cfg!') 
		widgetHandler:RemoveWidget()
		return
	end
	if ((not forceNonGLSL) and Spring.GetMiniMapDualScreen() ~= 'left') then --FIXME dualscreen
		if (not glCreateShader) then
			spEcho("gfx_deferred_rendering.lua: Shaders not found, removing self.")
			GLSLRenderer = false
			widgetHandler:RemoveWidget()
		else
			fragSrc = VFS.LoadFile("shaders\\deferred_lighting.glsl", VFS.ZIP)
			--Spring.Echo('gfx_deferred_rendering.lua: Shader code:', fragSrc)
			depthPointShader = glCreateShader({
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
			fragSrc = "#define BEAM_LIGHT \n" .. fragSrc
			depthBeamShader = glCreateShader({
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
			
			brightShader = glCreateShader({
				fragment = [[
					uniform sampler2D texture0;
					uniform float illuminationThreshold;
					uniform float inverseRX;
					uniform float inverseRY;

					void main(void) {
						vec2 C0 = vec2(gl_TexCoord[0]);
						vec3 color = vec3(texture2D(texture0, C0));
						float illum = dot(color, vec3(0.2990, 0.5870, 0.1140));

						if (illum > illuminationThreshold) {
							// Apply tone mapping when adding to the bloom texture, because otherwise the bloom intensity setting has no effect.
							// white point correction
							const float whiteStart = 2.0; // the minimum color intensity for starting white point transition
							const float whiteMax = 0.35; // the maximum amount of white shifting applied
							const float whiteScale = 0.1; // the rate at which to transition to white 
							
							float mx = max(color.r, max(color.g, color.b));
							if (mx > whiteStart) {
								color.rgb += min(vec3((mx - whiteStart) * whiteScale), vec3(whiteMax));
							}
							
							// tone mapping
							// I'm using exponential exposure for tone mapping here, because reinhard is suseptible
							// to precision overflows which propogate to the blur shaders, causing artifacts.
							color = vec3(1.0) - exp(-color);
							gl_FragColor = vec4(color.rgb, 1.0);
						} else {
							gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
						}
					}
				]],

				uniformInt = {texture0 = 0},
				uniformFloat = {illuminationThreshold, inverseRX, inverseRY}
			})
		
			blurShaderH71 = glCreateShader({
				fragment = [[
					uniform sampler2D texture0;
					uniform float inverseRX;
					uniform float fragKernelRadius;
					float bloomSigma = fragKernelRadius / 2.0;

					void main(void) {
						vec2 C0 = vec2(gl_TexCoord[0]);

						vec4 S = texture2D(texture0, C0);
						float weight = 1.0 / (2.50663 * bloomSigma);
						float total_weight = weight;
						S *= weight;
						for (float r = 1.5; r < fragKernelRadius; r += 2.0)
						{
							weight = exp(-((r*r)/(2.0 * bloomSigma * bloomSigma)))/(2.50663 * bloomSigma);
							S += texture2D(texture0, C0 - vec2(r * inverseRX, 0.0)) * weight;
							S += texture2D(texture0, C0 + vec2(r * inverseRX, 0.0)) * weight;

							total_weight += 2*weight;
						}

						gl_FragColor = vec4(S.rgb/total_weight, 1.0);
					}
				]],

				uniformInt = {texture0 = 0},
				uniformFloat = {inverseRX, fragKernelRadius, exposure}
			})
		
			blurShaderV71 = glCreateShader({
				fragment = [[
					uniform sampler2D texture0;
					uniform float inverseRY;
					uniform float fragKernelRadius;
					float bloomSigma = fragKernelRadius / 2.0;

					void main(void) {
						vec2 C0 = vec2(gl_TexCoord[0]);

						vec4 S = texture2D(texture0, C0);
						float weight = 1.0 / (2.50663 * bloomSigma);
						float total_weight = weight;
						S *= weight;
						for (float r = 1.5; r < fragKernelRadius; r += 2.0)
						{
							weight = exp(-((r*r)/(2.0 * bloomSigma * bloomSigma)))/(2.50663 * bloomSigma);
							S += texture2D(texture0, C0 - vec2(0.0, r * inverseRY)) * weight;
							S += texture2D(texture0, C0 + vec2(0.0, r * inverseRY)) * weight;

							total_weight += 2*weight;
						}

						gl_FragColor = vec4(S.rgb/total_weight, 1.0);
					}
				]],

				uniformInt = {texture0 = 0},
				uniformFloat = {inverseRY, fragKernelRadius}
			})
		
			combineShader = glCreateShader({
				fragment = [[
					uniform sampler2D texture0;
					uniform sampler2D texture1;
					uniform float illuminationThreshold;
					uniform float fragMaxBrightness;
					uniform int useBloom;
					uniform int useHDR;
					
					vec3 toneMapReinhard(vec3 color){
						const float whitePoint = 1.0;
						
						float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
						float lumLDR =  ((lum * (1.0 + (lum/(whitePoint * whitePoint)))))/(lum + 1.0);
						return color * (lumLDR/lum);
					}

					void main(void) {
						vec2 C0 = vec2(gl_TexCoord[0]);
						vec4 S0 = texture2D(texture0, C0);
						vec4 S1 = texture2D(texture1, C0);
					
						S1 = S1 * fragMaxBrightness;
						vec4 hdr = bool(useBloom) ? S1 + S0 : S0;
						
						if (bool(useHDR)){
							// white point correction
							// give super bright lights a white shift
							const float whiteStart = 1.5; // the minimum color intensity for starting white point transition
							const float whiteMax = 0.75; // the maximum amount of white shifting applied
							const float whiteScale = 0.2; // the rate at which to transition to white 
							
							float mx = max(hdr.r, max(hdr.g, hdr.b));
							if (mx > whiteStart) {
								hdr.rgb += vec3(min((mx - whiteStart) * whiteScale,  whiteMax));
							}
						
							// tone mapping
							hdr.rgb = toneMapReinhard(hdr.rgb);
						}
						
						vec4 map = vec4(hdr.rgb, 1.0);
											
						gl_FragColor = map;
					}
				]],

				uniformInt = { texture0 = 0, texture1 = 1, useBloom = 1, useHDR = 1},
				uniformFloat = {illuminationThreshold, fragMaxBrightness}
			})
		
			if not brightShader or not blurShaderH71 or not blurShaderV71 or not combineShader then
				Spring.Echo('Deferred Rendering Widget: Failed to create shaders!')
				Spring.Echo(gl.GetShaderLog())
				widgetHandler:RemoveWidget()
				return
			end
		
			brightShaderText0Loc = glGetUniformLocation(brightShader, "texture0")
			brightShaderInvRXLoc = glGetUniformLocation(brightShader, "inverseRX")
			brightShaderInvRYLoc = glGetUniformLocation(brightShader, "inverseRY")
			brightShaderIllumLoc = glGetUniformLocation(brightShader, "illuminationThreshold")

			blurShaderH71Text0Loc = glGetUniformLocation(blurShaderH71, "texture0")
			blurShaderH71InvRXLoc = glGetUniformLocation(blurShaderH71, "inverseRX")
			blurShaderH71FragLoc = glGetUniformLocation(blurShaderH71, "fragKernelRadius")
			blurShaderV71Text0Loc = glGetUniformLocation(blurShaderV71, "texture0")
			blurShaderV71InvRYLoc = glGetUniformLocation(blurShaderV71, "inverseRY")
			blurShaderV71FragLoc = glGetUniformLocation(blurShaderV71, "fragKernelRadius")

			combineShaderUseBloomLoc = glGetUniformLocation(combineShader, "useBloom")
			combineShaderUseHDRLoc = glGetUniformLocation(combineShader, "useHDR")
			combineShaderTexture0Loc = glGetUniformLocation(combineShader, "texture0")
			combineShaderTexture1Loc = glGetUniformLocation(combineShader, "texture1")
			combineShaderIllumLoc = glGetUniformLocation(combineShader, "illuminationThreshold")
			combineShaderFragLoc = glGetUniformLocation(combineShader, "fragMaxBrightness")
			
			WG.DeferredLighting_RegisterFunction = DeferredLighting_RegisterFunction
		end
		screenratio = vsy / vsx --so we dont overdraw and only always draw a square
	else
		GLSLRenderer = false
	end
end

function widget:Shutdown()
	if (GLSLRenderer) then
		if (glDeleteShader) then
			glDeleteShader(depthPointShader)
			glDeleteShader(depthBeamShader)
			glDeleteShader(brightShader)
			glDeleteShader(blurShaderH71)
			glDeleteShader(blurShaderV71)
			glDeleteShader(combineShader)
		end
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
	
	if useBloom then
		glUseShader(brightShader)
			glUniformInt(brightShaderText0Loc, 0)
			glUniform(   brightShaderInvRXLoc, ivsx)
			glUniform(   brightShaderInvRYLoc, ivsy)
			glUniform(   brightShaderIllumLoc, illumThreshold)
			mglRenderToTexture(brightTexture1, screenHDR, 1, -1)
		glUseShader(0)

		for i=1, 2 do
			glUseShader(blurShaderH71)
				glUniformInt(blurShaderH71Text0Loc, 0)
				glUniform(   blurShaderH71InvRXLoc, ivsx)
				glUniform(	 blurShaderH71FragLoc, kernelRadius)
				mglRenderToTexture(brightTexture2, brightTexture1, 1, -1)
			glUseShader(0)
	
			glUseShader(blurShaderV71)
				glUniformInt(blurShaderV71Text0Loc, 0)
				glUniform(   blurShaderV71InvRYLoc, ivsy)
				glUniform(	 blurShaderV71FragLoc, kernelRadius)
				mglRenderToTexture(brightTexture1, brightTexture2, 1, -1)
			glUseShader(0)
		end
	end

	glUseShader(combineShader)
		glUniformInt(combineShaderUseBloomLoc, useBloom)
		glUniformInt(combineShaderUseHDRLoc, useHDR)
		glUniformInt(combineShaderTexture0Loc, 0)
		glUniformInt(combineShaderTexture1Loc, 1)
		glUniform(   combineShaderIllumLoc, illumThreshold)
		glUniform(   combineShaderFragLoc, maxBrightness)
		local _, ocoords = spTraceScreenRay(0, 0, true, false, true, false)
		local _, dcoords = spTraceScreenRay(vsx-1, vsy-1, true, false, true, false)
		local ox, oy, oz = ocoords[4], ocoords[5], ocoords[6]
		local dx, dy, dz = ocoords[4], ocoords[5], ocoords[6]
		glDepthTest(false)
		glTexture(0, screenHDR)
		glTexture(1, brightTexture1)
		glTexRect(0, 0, vsx, vsy, false, true)
		glTexture(0, false)
		glTexture(1, false)
	glUseShader(0)
end

function widget:DrawScreenEffects()
	if not (GLSLRenderer) then
		Spring.Echo('Removing deferred rendering widget: failed to use GLSL shader')
		widgetHandler:RemoveWidget()
		return
	end
	
	glCopyToTexture(screenHDR, 0, 0, 0, 0, vsx, vsy) -- copy the screen to an HDR texture
	
	local beamLights = {}
	local beamLightCount = 0
	local pointLights = {}
	local pointLightCount = 0
	
	for i = 1, collectionFunctionCount do
		beamLights, beamLightCount, pointLights, pointLightCount = collectionFunctions[i](beamLights, beamLightCount, pointLights, pointLightCount)
	end
	
	glBlending(GL.DST_COLOR, GL.ONE) -- Set add blending mode
	
	if beamLightCount > 0 then
		glRenderToTexture(screenHDR, DrawLightType, beamLights, beamLightCount, 1)
	end
	if pointLightCount > 0 then
		glRenderToTexture(screenHDR, DrawLightType, pointLights, pointLightCount, 0)
	end
	glBlending(false)
	
	Bloom()
end