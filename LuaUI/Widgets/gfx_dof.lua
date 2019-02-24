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

options_order = {'useDoF'}

options = {
	useDoF = { type='bool', name='Apply Depth of Field Effect', value=false, noHotkey = true, advanced = false}
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

-----------------------------------------------------------------


local function CleanupTextures()
	glDeleteTexture(baseBlurTex or "")
	glDeleteTexture(horizBlurTexR or "")
	glDeleteTexture(horizBlurTexG or "")
	glDeleteTexture(horizBlurTexB or "")
	glDeleteTexture(finalBlurTex or "")
	glDeleteTexture(screenTex or "")
	glDeleteTexture(depthTex or "")
	baseBlurTex, horizBlurTexR, horizBlurTexG, horizBlurTexB, finalBlurTex, screenTex, depthTex = 
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
local horizBlurTexR = nil
local horizBlurTexG = nil
local horizBlurTexB = nil
local finalBlurTex = nil

-- shader uniform handles
local eyePosLoc = nil
local viewProjectionInvLoc = nil
local resolutionLoc = nil
-- local focusDepthLoc = nil
-- local fstopFactorLoc = nil
local passLoc = nil
local channelLoc = nil

-- shader uniform enums
local shaderPasses = 
{
	filterSize = 0,
	horizBlur = 1,
	vertBlur = 2,
	composition = 3,
}
local blurChannels =
{
	red = 0,
	green = 1,
	blue = 2,
}

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
	
	horizBlurTexR = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGBA16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	horizBlurTexG = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGBA16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	horizBlurTexB = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		format = GL_RGBA16F_ARB, wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	finalBlurTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	if not horizBlurTexR or not horizBlurTexG or not horizBlurTexB or 
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
			"#define MAX_FILTER_SIZE 1.0\n",

			"#define FILTER_SIZE_PASS " .. shaderPasses.filterSize .. "\n",
			"#define HORIZ_BLUR_PASS " .. shaderPasses.horizBlur .. "\n",
			"#define VERT_BLUR_PASS " .. shaderPasses.vertBlur .. "\n",
			"#define COMPOSITION_PASS " .. shaderPasses.composition .. "\n",

			"#define BLUR_CHANNEL_RED " .. blurChannels.red .. "\n",
			"#define BLUR_CHANNEL_GREEN " .. blurChannels.green .. "\n",
			"#define BLUR_CHANNEL_BLUE " .. blurChannels.blue .. "\n",
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
	viewProjectionInvLoc = gl.GetUniformLocation(dofShader, "viewProjectionInv")
	resolutionLoc = gl.GetUniformLocation(dofShader, "resolution")
	-- focusDepthLoc = gl.GetUniformLocation(dofShader, "focusDepth")
	-- fstopFactorLoc = gl.GetUniformLocation(dofShader, "fstopFactor")
	passLoc = gl.GetUniformLocation(dofShader, "pass")
	channelLoc = gl.GetUniformLocation(dofShader, "channel")
	
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
	glUniformMatrix(viewProjectionInvLoc, "viewprojectioninverse")
	glUniformInt(passLoc, shaderPasses.filterSize)
	glTexture(0, screenTex)
	glTexture(1, depthTex)

  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
	
	glTexture(0, false)
	glTexture(1, false)
end

local function HorizBlur(channel)
	glUniform(resolutionLoc, vsx/2, vsy/2)
	glUniformInt(channelLoc, channel)
	glUniformInt(passLoc, shaderPasses.horizBlur)
	glTexture(0, baseBlurTex)
  glTexRect(-1-0.5/vsx,1+0.5/vsy,1+0.5/vsx,-1-0.5/vsy)
	glTexture(0, false)
end

local function HorizBlurR()
	HorizBlur(blurChannels.red)
end
local function HorizBlurG()
	HorizBlur(blurChannels.green)
end
local function HorizBlurB()
	HorizBlur(blurChannels.blue)
end

local function VertBlur()
	glUniform(resolutionLoc, vsx/2, vsy/2)
	glUniformInt(passLoc, shaderPasses.vertBlur)
	glTexture(1, horizBlurTexR)
	glTexture(2, horizBlurTexG)
	glTexture(3, horizBlurTexB)
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

-- local function LinearizeDepth(depth)
-- 	Spring.Echo(depth)
--     local n = 0.1; --camera z near
--     local f = 100.0; --camera z far
--     return (2.0 * n) / (f + n - depth* (f - n));
-- end

function widget:DrawScreenEffects()
	if not options.useDoF.value then
		return -- if the option is disabled don't draw anything.
	end

	gl.Blending(false)
	glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
	glCopyToTexture(depthTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image

	-- glTexture(depthTex)
	-- local depth = gl.ReadPixels(vsx/2, vsy/2, 1, 1, GL_DEPTH_COMPONENT24)
	-- Spring.Echo(depth)
	-- glUniform(focusDepthLoc, depth)
	-- glUniform(fstopFactorLoc, math.min(math.max(0.4 / math.max(depth, 0.04) - 1.4, 0), 1))
	
	glUseShader(dofShader)
		
		glRenderToTexture(baseBlurTex, FilterCalculation)
		glRenderToTexture(horizBlurTexR, HorizBlurR)
		glRenderToTexture(horizBlurTexG, HorizBlurG)
		glRenderToTexture(horizBlurTexB, HorizBlurB)
		glRenderToTexture(finalBlurTex, VertBlur)
		Composition()

	glUseShader(0)
end
