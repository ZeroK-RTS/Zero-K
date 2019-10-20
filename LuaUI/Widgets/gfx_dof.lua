function widget:GetInfo()
	return {
		name      = "DoF/Bloom Shader",
		version	  = 1.0,
		desc      = "Blurs far away objects.",
		author    = "aeonios, Shadowfury333",
		date      = "Oct. 2019",
		license   = "GPL, MIT",
		layer     = -9999999, -- To run after literally everything else.
		enabled   = true
	}
end

options_path = 'Settings/Graphics/Effects/DoF & Bloom'

options_order = {'useDoF', 'useBloom', 'bloomIntensity'}

options = {
	useDoF = { type='bool', name='Apply Depth of Field Effect', value=false, noHotkey = true, advanced = false},
	useBloom = { type='bool', name='Apply Bloom Effect', value=false, noHotkey = true, advanced = false},
	bloomIntensity  = {type = 'number', name = 'Bloom Intensity', value = 0.5, min = 0.05, max = 1, step = 0.05,}
}

local function onChangeFunc()
	widget:Initialize()
end

options.useDoF.OnChange = onChangeFunc
options.useBloom.OnChange = onChangeFunc

-----------------------------------------------------------------
-- Engine Functions
-----------------------------------------------------------------

local spGetCameraPosition    = Spring.GetCameraPosition

local glResetMatrices        = gl.ResetMatrices
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
local glUniformInt			 = gl.UniformInt
local glUniformMatrix		 = gl.UniformMatrix

local GL_DEPTH_COMPONENT24 = 0x81A6

-----------------------------------------------------------------


-----------------------------------------------------------------
-- Global Vars
-----------------------------------------------------------------

local vsx = nil	-- current viewport width
local vsy = nil	-- current viewport height
local blurShaderH = nil
local blurShaderV = nil
local dofShader = nil
local screenTex = nil
local downscaleTex = nil
local blurTex = nil
local pongTex = nil
local smallPongTex = nil
local bloomTex = nil
local depthTex = nil

-- combine shader uniform handles
local projectionLoc = nil
local bloomFactorLoc = nil

-- blur shader uniform handles
local inverseRXloc = nil
local inverseRYloc = nil
local bigBlurHloc = nil
local bigBlurVloc = nil

-----------------------------------------------------------------
local function CleanTextures()
	if glDeleteTexture then
		glDeleteTexture(downscaleTex or "")
		glDeleteTexture(screenTex or "")
		glDeleteTexture(blurTex or "")
		glDeleteTexture(pongTex or "")
		glDeleteTexture(smallPongTex or "")
		glDeleteTexture(bloomTex or "")
		glDeleteTexture(depthTex or "")
	end
	screenTex = nil
	downscaleTex = nil
	blurTex = nil
	pongTex = nil
	smallPongTex = nil
	bloomTex = nil
	depthTex = nil
end

function widget:ViewResize(x, y)
	vsx, vsy = gl.GetViewSizes()
	CleanTextures()
	
	if blurShaderH and blurShaderV then
		gl.ActiveShader(blurShaderH, function() glUniform(inverseRXloc, 2.0/vsx) end)
		gl.ActiveShader(blurShaderV, function() glUniform(inverseRYloc, 2.0/vsy) end)
	end
	
	screenTex = glCreateTexture(vsx, vsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	downscaleTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	blurTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	
	pongTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
		
	if options.useDoF.value then
		depthTex = gl.CreateTexture(vsx,vsy, {
			border = false,
			format = GL_DEPTH_COMPONENT24,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
		})
	end
	
	if options.useBloom.value then
		bloomTex = glCreateTexture(vsx/4, vsy/4, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP})
		
		smallPongTex = glCreateTexture(vsx/4, vsy/4, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP, wrap_t = GL.CLAMP,
	})
	end
	
	if not downscaleTex or not screenTex or not blurTex or not pongTex or (options.useDoF.value and not depthTex) or (options.useBloom.value and not bloomTex) then
		Spring.Echo("DoF/Bloom: Failed to create textures!")
		widget:Shutdown()
		widgetHandler:RemoveWidget()
		return
	end
end

local function CleanShaders()
	if (glDeleteShader) then
		glDeleteShader(dofShader)
		glDeleteShader(blurShaderH)
		glDeleteShader(blurShaderV)
	end
	blurShaderH = nil
	blurShaderV = nil
	dofShader = nil
end

local function InitShaders()
	CleanShaders()
	
	dofShader = glCreateShader({
		defines = {
			"#version 120\n",
			"#define USE_DOF " .. (options.useDoF.value and "1" or "0") .. "\n",
			"#define USE_BLOOM " .. (options.useBloom.value and "1" or "0") .. "\n"
		},
		fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\dof.fs", VFS.ZIP),
		
		uniformInt = {origTex = 0, downscaleTex = 1, blurTex = 2, bloomTex = 3, depthTex = 4},
	})
	
	if not dofShader then
		Spring.Echo("DOF/Bloom Widget: Failed to create DoF shader!")
		Spring.Echo(gl.GetShaderLog())
		widget:Shutdown()
		widgetHandler:RemoveWidget()
		return
	end
	
	projectionLoc = gl.GetUniformLocation(dofShader, "projection")
	bloomFactorLoc = gl.GetUniformLocation(dofShader, "bloomFactor")
	
	blurShaderH = glCreateShader({
		fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\bloom_blurH.fs", VFS.ZIP),

		uniformInt = {texture0 = 0}
	})

	if not blurShaderH then
		Spring.Echo('DOF/Bloom Widget: blurshaderH failed to compile!')
		Spring.Echo(gl.GetShaderLog())
		widget:Shutdown()
		widgetHandler:RemoveWidget()
	end
	
	inverseRXloc = gl.GetUniformLocation(blurShaderH, "inverseRX")
	bigBlurHloc = gl.GetUniformLocation(blurShaderH, "bigBlur")
	
	blurShaderV = glCreateShader({
		fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\bloom_blurV.fs", VFS.ZIP),

		uniformInt = {texture0 = 0}
	})

	if not blurShaderV then
		Spring.Echo('DOF/Bloom Widget: blurshaderV failed to compile!')
		Spring.Echo(gl.GetShaderLog())
		widget:Shutdown()
		widgetHandler:RemoveWidget()
	end
	
	inverseRYloc = gl.GetUniformLocation(blurShaderV, "inverseRY")
	bigBlurVloc = gl.GetUniformLocation(blurShaderV, "bigBlur")
end

function widget:Initialize()
	if (glCreateShader == nil) then
		Spring.Echo("[DoF/Bloom::Initialize] removing widget, no shader support")
		widgetHandler:RemoveWidget()
		return
	end
	
	if options.useDoF.value or options.useBloom.value then
		InitShaders()
		widget:ViewResize()
	else
		widget:Shutdown()
	end
end

function widget:Shutdown()
	CleanShaders()
	CleanTextures()
end

function widget:DrawWorld()
	--gl.ActiveShader(dofShader, function() glUniformMatrix(projectionLoc, "projection") end)
end

local function renderToTextureFunc(tex, s, t)
	glTexture(tex)
	glTexRect(-1 * s, -1 * t,  1 * s, 1 * t)
	glTexture(false)
end

local function mglRenderToTexture(FBOTex, tex, s, t)
	glRenderToTexture(FBOTex, renderToTextureFunc, tex, s, t)
end

local function ApplyBlurs()
	-- first copy and then downscale the screen textures.
	glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
	if options.useDoF.value then
		glCopyToTexture(depthTex, 0, 0, 0, 0, vsx, vsy)
	end
	
	-- then downscale it 2x2
	mglRenderToTexture(downscaleTex, screenTex, 1, -1)
	
	--apply a small gaussian blur to the downscaled image for DoF
	glUseShader(blurShaderH)
		glUniform(inverseRXloc, 2.0/vsx)
		glUniformInt(bigBlurHloc, 0)
		mglRenderToTexture(pongTex, downscaleTex, 1, -1)
	glUseShader(0)
	
	glUseShader(blurShaderV)
		glUniform(inverseRYloc, 2.0/vsy)
		glUniformInt(bigBlurVloc, 0)
		mglRenderToTexture(blurTex, pongTex, 1, -1)
	glUseShader(0)
	
	if options.useBloom.value and bloomTex then
		mglRenderToTexture(bloomTex, blurTex, 1, -1)
		--apply a larger gaussian blur to the downscaled image for bloom
		glUseShader(blurShaderH)
			glUniform(inverseRXloc, 4.0/vsx)
			glUniformInt(bigBlurHloc, 1)
			mglRenderToTexture(smallPongTex, bloomTex, 1, -1)
		glUseShader(0)
	
		glUseShader(blurShaderV)
			glUniform(inverseRXloc, 4.0/vsy)
			glUniformInt(bigBlurVloc, 1)
			mglRenderToTexture(bloomTex, smallPongTex, 1, -1)
		glUseShader(0)
	end
end

function widget:DrawWorld()
	if dofShader then
		gl.ActiveShader(dofShader, function() glUniformMatrix(projectionLoc, "projection") end)
	end
end

function widget:DrawScreenEffects()
	if not options.useDoF.value and not options.useBloom.value then
		return -- if the option is disabled don't draw anything.
	end

	glResetMatrices()
	gl.Blending(false)
	gl.DepthTest(false)
	
	ApplyBlurs()
	
	glUseShader(dofShader)
		-- combine the final image.
		glTexture(0, screenTex)
		if options.useDoF.value then
			glTexture(1, downscaleTex)
			glTexture(2, blurTex)
			glTexture(4, depthTex)
		end
		
		if options.useBloom.value and bloomTex then
			glTexture(3, bloomTex)
			glUniform(bloomFactorLoc, options.bloomIntensity.value)
		end
		
		glTexRect(0, 0, vsx, vsy, false, true)
		
		glTexture(0, false)
		glTexture(1, false)
		glTexture(2, false)
		glTexture(3, false)
	glUseShader(0)
end
