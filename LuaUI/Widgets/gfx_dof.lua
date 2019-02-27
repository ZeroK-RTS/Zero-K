function widget:GetInfo()
	return {
		name      = "Depth of Field Shader",
		version	  = 2.0,
		desc      = "Blurs far away objects.",
		author    = "aeonios, Shadowfury333 (with some code from Kleber Garcia)",
		date      = "Feb. 2019",
		license   = "GPL, MIT",
		layer     = -1,
		enabled   = true
	}
end

options_path = 'Settings/Graphics/Effects/Depth of Field'

options_order = {'useDoF', 'autofocus', 'focusDepth', 'fStop'}

options = {
	useDoF = 
	{ 
		type='bool', 
		name='Apply Depth of Field Effect', 
		value=false, 
		noHotkey = true, 
		advanced = false,
	},
	autofocus = 
	{ 
		type='bool',
		name='Automatically Set Focus',
		value=true,
		noHotkey=true,
		advanced=true,
	},
	focusDepth =
	{
		type='number',
		name='Focus Depth (Manual Focus Only)',
		min = 0.0, max = 10000.0, step = 0.1,
		value = 0.3,
		advanced = true,
	},
	fStop =
	{
		type='number',
		name='F-Stop',
		min = 2.4, max = 160.0, step = 0.1,
		value = 16.0,
		advanced = true,
	},
}

local function onChangeFunc()
	if options.useDoF.value then
		widget:Initialize()
	else
		if glDeleteTexture then
			CleanupTextures()
		end
	end
end

options.useDoF.OnChange = onChangeFunc

-----------------------------------------------------------------
-- Engine Functions
-----------------------------------------------------------------

local spGetCameraPosition    = Spring.GetCameraPosition

local glCopyToTexture        = gl.CopyToTexture
local glCreateShader         = gl.CreateShader
local glCreateTexture        = gl.CreateTexture
local glDeleteShader         = gl.DeleteShader
local glDeleteTexture        = gl.DeleteTexture
local glGetShaderLog         = gl.GetShaderLog
local glTexture              = gl.Texture
local glTexRect              = gl.TexRect
local glRenderToTexture		 = gl.RenderToTexture
local glUseShader            = gl.UseShader
local glGetUniformLocation   = gl.GetUniformLocation
local glUniform				 = gl.Uniform
local glUniformInt				 = gl.UniformInt
local glUniformMatrix		 = gl.UniformMatrix

local GL_DEPTH_COMPONENT   = 0x1902
local GL_DEPTH_COMPONENT16 = 0x81A5
local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_DEPTH_COMPONENT32 = 0x81A7

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0
local GL_COLOR_ATTACHMENT1_EXT = 0x8CE1
local GL_COLOR_ATTACHMENT2_EXT = 0x8CE2

-----------------------------------------------------------------


local function CleanupTextures()
	glDeleteTexture(baseBlurTex or "")
	glDeleteTexture(intermediateBlurTexR or "")
	glDeleteTexture(intermediateBlurTexG or "")
	glDeleteTexture(intermediateBlurTexB or "")
	glDeleteTexture(finalBlurTex or "")
	glDeleteTexture(screenTex or "")
	glDeleteTexture(depthTex or "")
	gl.DeleteFBO(intermediateBlurFBO)
	baseBlurTex, intermediateBlurTexR, intermediateBlurTexG, intermediateBlurTexB, finalBlurTex, screenTex, depthTex = 
		nil, nil, nil, nil, nil, nil, nil
end
-----------------------------------------------------------------
-- Global Vars
-----------------------------------------------------------------

local vsx = nil	-- current viewport width
local vsy = nil	-- current viewport height
local dofShader = nil
local screenTex = nil
local depthTex = nil
local baseBlurTex = nil
local intermediateBlurTexR = nil
local intermediateBlurTexG = nil
local intermediateBlurTexB = nil
local intermediateBlurFBO = nil
local finalBlurTex = nil

-- shader uniform handles
local eyePosLoc = nil
local viewProjectionLoc = nil
local resolutionLoc = nil
local autofocusLoc = nil
local focusDepthLoc = nil
local fStopLoc = nil
local passLoc = nil

-- shader uniform enums
local shaderPasses = 
{
	filterSize = 0,
	vertBlur = 1,
	horizBlur = 2,
	composition = 3,
}
-- local blurChannels =
-- {
-- 	red = 0,
-- 	green = 1,
-- 	blue = 2,
-- }

-----------------------------------------------------------------

function widget:ViewResize(x, y)
	vsx, vsy = gl.GetViewSizes()
	CleanupTextures()
	
	screenTex = glCreateTexture(vsx, vsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})

	depthTex = gl.CreateTexture(vsx,vsy, {
		border = false,
		format = GL_DEPTH_COMPONENT24,
		min_filter = GL.NEAREST,
		mag_filter = GL.NEAREST,
	})	

	baseBlurTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	intermediateBlurTexR = glCreateTexture(vsx/2, vsy/2, {
		min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGBA16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	intermediateBlurTexG = glCreateTexture(vsx/2, vsy/2, {
		 min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGBA16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	intermediateBlurTexB = glCreateTexture(vsx/2, vsy/2, {
		 min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGBA16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	finalBlurTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	intermediateBlurFBO = gl.CreateFBO({
		color0 = intermediateBlurTexR,
		color1 = intermediateBlurTexG,
		color2 = intermediateBlurTexB,
     drawbuffers = { 
     	GL_COLOR_ATTACHMENT0_EXT, 
     	GL_COLOR_ATTACHMENT1_EXT, 
     	GL_COLOR_ATTACHMENT2_EXT}
		})

	if not intermediateBlurTexR or not intermediateBlurTexG or not intermediateBlurTexB or 
		not finalBlurTex or not baseBlurTex or not screenTex or not depthTex then
		Spring.Echo("Depth of Field: Failed to create textures!")
		widgetHandler:RemoveWidget()
		return
	end
end

function widget:Initialize()
	if (glCreateShader == nil) then
		Spring.Echo("[Depth of Field::Initialize] removing widget, no shader support")
		widgetHandler:RemoveWidget()
		return
	end
	
	if not options.useDoF.value then
		return
	end

	dofShader = dofShader or glCreateShader({
		defines = {"#version 120\n",
			"#define DEPTH_CLIP01 " .. (Platform.glSupportClipSpaceControl and "1" or "0") .. "\n",
			"#define MAX_FILTER_SIZE 1.0\n",

			"#define FILTER_SIZE_PASS " .. shaderPasses.filterSize .. "\n",
			"#define VERT_BLUR_PASS " .. shaderPasses.vertBlur .. "\n",
			"#define HORIZ_BLUR_PASS " .. shaderPasses.horizBlur .. "\n",
			"#define COMPOSITION_PASS " .. shaderPasses.composition .. "\n",

			-- "#define BLUR_CHANNEL_RED " .. blurChannels.red .. "\n",
			-- "#define BLUR_CHANNEL_GREEN " .. blurChannels.green .. "\n",
			-- "#define BLUR_CHANNEL_BLUE " .. blurChannels.blue .. "\n",
		},
		fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\dof.fs", VFS.ZIP),
		
		uniformInt = {origTex = 0, blurTex0 = 1, blurTex1 = 2, blurTex2 = 3},
	})
	
	if not dofShader then
		Spring.Echo("Depth of Field: Failed to create shader!")
		Spring.Echo(gl.GetShaderLog())
		widgetHandler:RemoveWidget()
		return
	end
	
	eyePosLoc = gl.GetUniformLocation(dofShader, "eyePos")
	viewProjectionLoc = gl.GetUniformLocation(dofShader, "viewProjection")
	resolutionLoc = gl.GetUniformLocation(dofShader, "resolution")
	autofocusLoc = gl.GetUniformLocation(dofShader, "autofocus")
	focusDepthLoc = gl.GetUniformLocation(dofShader, "manualFocusDepth")
	fStopLoc = gl.GetUniformLocation(dofShader, "fStop")
	passLoc = gl.GetUniformLocation(dofShader, "pass")
	-- channelLoc = gl.GetUniformLocation(dofShader, "channel")
	
	widget:ViewResize()
end

function widget:Shutdown()
	if (glDeleteShader and dofShader) then
		glDeleteShader(dofShader)
	end
	
	if glDeleteTexture then
		CleanupTextures()
	end
	dofShader = nil
end

local function FilterCalculation()
	local cpx, cpy, cpz = spGetCameraPosition()
	local gmin, gmax = Spring.GetGroundExtremes()
	local effectiveHeight = cpy - math.max(0, gmin)
	cpy = 3.5 * math.sqrt(effectiveHeight) * math.log(effectiveHeight)
	glUniform(eyePosLoc, cpx, cpy, cpz)
	-- glUniformMatrix(viewProjectionLoc, "projection")
	glUniformInt(passLoc, shaderPasses.filterSize)
	glTexture(0, screenTex)
	glTexture(1, depthTex)

  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
	-- glTexRect(0, 0, vsx, vsy, false, true)
	-- 
	glTexture(0, false)
	glTexture(1, false)
end

local function VertBlur()
	glUniform(resolutionLoc, vsx/2, vsy/2)
	glUniformInt(passLoc, shaderPasses.vertBlur)
	glTexture(0, baseBlurTex)
  -- glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
	glTexRect(0, 0, vsx, vsy, false, true)
	glTexture(0, false)
end

local function HorizBlur()
	glUniform(resolutionLoc, vsx/2, vsy/2)
	glUniformInt(passLoc, shaderPasses.horizBlur)
	glTexture(1, intermediateBlurTexR)
	glTexture(2, intermediateBlurTexG)
	glTexture(3, intermediateBlurTexB)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
	glTexture(1, false)
	glTexture(2, false)
	glTexture(3, false)
end

local function Composition()
	glUniformInt(passLoc, shaderPasses.composition)
	glTexture(0, screenTex)
	glTexture(1, finalBlurTex)
	glTexRect(0, 0, vsx, vsy, false, true)
	glTexture(0, false)
	glTexture(1, false)
end

function widget:DrawWorld()
	gl.ActiveShader(dofShader, function() glUniformMatrix(viewProjectionLoc, "projection") end)
end

function widget:DrawScreenEffects()
	if not options.useDoF.value then
		return -- if the option is disabled don't draw anything.
	end

	gl.Blending(false)
	glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
	glCopyToTexture(depthTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
	
	glUseShader(dofShader)

		glUniformInt(autofocusLoc, options.autofocus.value and 1 or 0)
		glUniform(focusDepthLoc, options.focusDepth.value / 10000)
		glUniform(fStopLoc, options.fStop.value)
		
		glRenderToTexture(baseBlurTex, FilterCalculation)
		gl.ActiveFBO(intermediateBlurFBO, VertBlur)
		glRenderToTexture(finalBlurTex, HorizBlur)
		Composition()

	glUseShader(0)
end
