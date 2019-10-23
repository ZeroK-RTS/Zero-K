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

options_order = {'useDoF', 'useHQ', 'useBloom', 'bloomIntensity'}

options = {
	useDoF = { type='bool', name='Apply Depth of Field Effect', value=false, noHotkey = true, advanced = false},
	useHQ = { type='bool', name='Use High Quality DoF Effect', value=false, noHotkey = true, advanced = false},
	useBloom = { type='bool', name='Apply Bloom Effect', value=false, noHotkey = true, advanced = false},
	bloomIntensity  = {type = 'number', name = 'Bloom Intensity', value = 0.7, min = 0.05, max = 1, step = 0.05,}
}

local function onChangeFunc()
	widget:Initialize()
end

options.useDoF.OnChange = onChangeFunc
options.useHQ.OnChange = onChangeFunc
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
local glActiveFBO			 = gl.ActiveFBO

local GL_DEPTH_COMPONENT24 = 0x81A6
local GL_RGBA16F_ARB = 0x881A

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0
local GL_COLOR_ATTACHMENT1_EXT = 0x8CE1
local GL_COLOR_ATTACHMENT2_EXT = 0x8CE2

-----------------------------------------------------------------


-----------------------------------------------------------------
-- Global Vars
-----------------------------------------------------------------

local vsx = nil	-- current viewport width
local vsy = nil	-- current viewport height

-- Shaders
local blurShaderH = nil
local blurShaderV = nil
local dofPrepass = nil
local bokehInitialPass = nil
local bokehFinalPass = nil
local dofShader = nil

-- Textures
local screenTex = nil
local downscaleTex = nil
local blurTex = nil
local pongTex = nil
local Rtex = nil
local Gtex = nil
local Btex = nil
local smallPongTex = nil
local bloomTex = nil
local depthTex = nil

--FBOs
local bokehFBO = nil

-- prepass shader uniform handles
local projectionLoc = nil

-- combine shader uniform handles
local bloomFactorLoc = nil

-- bokeh shader uniform handles
local bokehInverseRXloc = nil
local bokehInverseRYloc = nil

-- blur shader uniform handles
local bloomInverseRXloc = nil
local bloomInverseRYloc = nil
local bigBlurHloc = nil
local bigBlurVloc = nil
local alphaHloc = nil
local alphaVloc = nil

-----------------------------------------------------------------
local function CleanTextures()
	if bokehFBO then
		gl.DeleteFBO(bokehFBO)
		bokehFBO = nil
	end
	
	if glDeleteTexture then
		glDeleteTexture(downscaleTex or "")
		glDeleteTexture(screenTex or "")
		glDeleteTexture(blurTex or "")
		glDeleteTexture(pongTex or "")
		glDeleteTexture(Rtex or "")
		glDeleteTexture(Gtex or "")
		glDeleteTexture(Btex or "")
		glDeleteTexture(smallPongTex or "")
		glDeleteTexture(bloomTex or "")
		glDeleteTexture(depthTex or "")
	end
	
	screenTex = nil
	downscaleTex = nil
	blurTex = nil
	pongTex = nil
	Rtex, Gtex, Btex = nil, nil, nil
	smallPongTex = nil
	bloomTex = nil
	depthTex = nil
end

local function CleanShaders()
	if (glDeleteShader) then
		glDeleteShader(dofPrepass)
		glDeleteShader(dofShader)
		glDeleteShader(blurShaderH)
		glDeleteShader(blurShaderV)
		glDeleteShader(bokehInitialPass)
		glDeleteShader(bokehFinalPass)
	end
	blurShaderH = nil
	blurShaderV = nil
	bokehInitialPass = nil
	bokehFinalPass = nil
	dofShader = nil
	dofPrepass = nil
end

function widget:ViewResize(x, y)
	vsx, vsy = gl.GetViewSizes()
	CleanTextures()
	
	if bokehInitialPass and bokehFinalPass then
		gl.ActiveShader(bokehInitialPass, function() glUniform(bokehInverseRXloc, 2.0/vsx) end)
		gl.ActiveShader(bokehFinalPass, function() glUniform(bokehInverseRYloc, 2.0/vsy) end)
	end
	
	screenTex = glCreateTexture(vsx, vsy, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT,
	})
	
	downscaleTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT,
	})
	
	blurTex = glCreateTexture(vsx/2, vsy/2, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT,
	})
	
	if options.useDoF.value then
		depthTex = gl.CreateTexture(vsx,vsy, {
			border = false,
			format = GL_DEPTH_COMPONENT24,
			min_filter = GL.NEAREST,
			mag_filter = GL.NEAREST,
		})
		
		if options.useHQ.value then
			Rtex = glCreateTexture(vsx/2, vsy/2, {
				fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
				wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT, format = GL_RGBA16F_ARB
			})
			
			Gtex = glCreateTexture(vsx/2, vsy/2, {
				fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
				wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT, format = GL_RGBA16F_ARB
			})
			
			Btex = glCreateTexture(vsx/2, vsy/2, {
				fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
				wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT, format = GL_RGBA16F_ARB
			})
			
			if not Rtex or not Gtex or not Btex then
				Spring.Echo("DoF/Bloom: Failed to create HQ textures!")
				widget:Shutdown()
				widgetHandler:RemoveWidget()
				return
			end
			
			bokehFBO = gl.CreateFBO({
				color0 = Rtex,
				color1 = Gtex,
				color2 = Btex,
				drawbuffers = {
					GL_COLOR_ATTACHMENT0_EXT,
					GL_COLOR_ATTACHMENT1_EXT,
					GL_COLOR_ATTACHMENT2_EXT
				}
			})
			
			if not bokehFBO then
				Spring.Echo("DoF/Bloom: Failed to create FBO!")
				widget:Shutdown()
				widgetHandler:RemoveWidget()
				return
			end
		end
	end
	
	if not options.useDoF.value or not options.useHQ.value then
		pongTex = glCreateTexture(vsx/2, vsy/2, {
			fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
			wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT,
		})

		if not pongTex then
			Spring.Echo("DoF/Bloom: Failed to create intermediate blur texture!")
			widget:Shutdown()
			widgetHandler:RemoveWidget()
			return
		end
	end
	
	if options.useBloom.value then
		bloomTex = glCreateTexture(vsx/4, vsy/4, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT})
		
		smallPongTex = glCreateTexture(vsx/4, vsy/4, {
		fbo = true, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.MIRRORED_REPEAT, wrap_t = GL.MIRRORED_REPEAT,
		})
	end
	
	if not downscaleTex or not screenTex or not blurTex or (options.useDoF.value and not depthTex) or (options.useBloom.value and (not bloomTex or not smallPongTex)) then
		Spring.Echo("DoF/Bloom: Failed to create textures!")
		widget:Shutdown()
		widgetHandler:RemoveWidget()
		return
	end
end

local function InitShaders()
	CleanShaders()
	
	dofShader = glCreateShader({
		defines = {
			"#version 120\n",
			"#define USE_DOF " .. (options.useDoF.value and "1" or "0") .. "\n",
			"#define USE_HQ " .. (options.useHQ.value and "1" or "0") .. "\n",
			"#define USE_BLOOM " .. (options.useBloom.value and "1" or "0") .. "\n"
		},
		fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\dof.fs", VFS.ZIP),
		
		uniformInt = {origTex = 0, downscaleTex = 1, blurTex = 2, bloomTex = 3},
	})
	
	if not dofShader then
		Spring.Echo("DOF/Bloom Widget: Failed to create DoF shader!")
		Spring.Echo(gl.GetShaderLog())
		widget:Shutdown()
		widgetHandler:RemoveWidget()
		return
	end
	
	bloomFactorLoc = gl.GetUniformLocation(dofShader, "bloomFactor")
	
	if options.useDoF.value then
		dofPrepass = glCreateShader({
			fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\dof_prepass.fs", VFS.ZIP),
			
			uniformInt = {origTex = 0, depthTex = 1},
		})
		
		if not dofPrepass then
			Spring.Echo("DOF/Bloom Widget: Failed to create DoF prepass shader!")
			Spring.Echo(gl.GetShaderLog())
			widget:Shutdown()
			widgetHandler:RemoveWidget()
			return
		end
		
		projectionLoc = gl.GetUniformLocation(dofPrepass, "projection")
		
		if options.useHQ.value then
			bokehInitialPass = glCreateShader({
				fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\bokeh_blur_initial_pass.fs", VFS.ZIP),
				
				uniformInt = {downscaleTex = 0},
			})
			
			if not bokehInitialPass then
				Spring.Echo("DOF/Bloom Widget: Failed to create DoF initial bokeh pass shader!")
				Spring.Echo(gl.GetShaderLog())
				widget:Shutdown()
				widgetHandler:RemoveWidget()
				return
			end
		
			bokehInverseRXloc = gl.GetUniformLocation(bokehInitialPass, "inverseRX")
			
			bokehFinalPass = glCreateShader({
				fragment = VFS.LoadFile("LuaUI\\Widgets\\Shaders\\bokeh_blur_final_pass.fs", VFS.ZIP),
				
				uniformInt = {downscaleTex = 0, Rtex = 1, Gtex = 2, Btex = 3},
			})
			
			if not bokehFinalPass then
				Spring.Echo("DOF/Bloom Widget: Failed to create DoF initial bokeh pass shader!")
				Spring.Echo(gl.GetShaderLog())
				widget:Shutdown()
				widgetHandler:RemoveWidget()
				return
			end
		
			bokehInverseRYloc = gl.GetUniformLocation(bokehFinalPass, "inverseRY")
		end
	end
		
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
	
	bloomInverseRXloc = gl.GetUniformLocation(blurShaderH, "inverseRX")
	bigBlurHloc = gl.GetUniformLocation(blurShaderH, "bigBlur")
	alphaHloc = gl.GetUniformLocation(blurShaderH, "alpha")
	
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
	
	bloomInverseRYloc = gl.GetUniformLocation(blurShaderV, "inverseRY")
	bigBlurVloc = gl.GetUniformLocation(blurShaderV, "bigBlur")
	alphaVloc = gl.GetUniformLocation(blurShaderV, "alpha")
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

local function renderToTextureFunc(tex, s, t)
	glTexture(tex)
	glTexRect(-1 * s, -1 * t,  1 * s, 1 * t)
	glTexture(false)
end

local function mglRenderToTexture(FBOTex, tex, s, t)
	glRenderToTexture(FBOTex, renderToTextureFunc, tex, s, t)
end

local function ApplyPreproc()
	-- first copy the screen textures.
	glCopyToTexture(screenTex, 0, 0, 0, 0, vsx, vsy) -- the original screen image
	if options.useDoF.value then
		glCopyToTexture(depthTex, 0, 0, 0, 0, vsx, vsy)
		
		glUseShader(dofPrepass)
			glTexture(0, screenTex)
			glTexture(1, depthTex)
			glRenderToTexture(screenTex, glTexRect, -1, 1, 1, -1)
			glTexture(0, false)
			glTexture(1, false)
		glUseShader(0)
	end
	
	-- then downscale 2x2
	mglRenderToTexture(downscaleTex, screenTex, 1, -1)
	
	if options.useDoF.value and options.useHQ.value then
		-- blur the alpha values by 1px to smooth out the blur scaling
		glUseShader(blurShaderH)
			glUniform(bloomInverseRXloc, 2.0/vsx)
			glUniformInt(bigBlurHloc, 0)
			glUniformInt(alphaHloc, 1)
			mglRenderToTexture(blurTex, downscaleTex, 1, -1)
			glUniformInt(alphaHloc, 0)
		glUseShader(0)
		
		glUseShader(blurShaderV)
			glUniform(bloomInverseRYloc, 2.0/vsy)
			glUniformInt(bigBlurVloc, 0)
			glUniformInt(alphaVloc, 1)
			mglRenderToTexture(downscaleTex, blurTex, 1, -1)
			glUniformInt(alphaVloc, 0)
		glUseShader(0)
		
		-- apply bokeh blur
		glUseShader(bokehInitialPass)
			glTexture(0, downscaleTex)
			glActiveFBO(bokehFBO, glTexRect, 0, 0, vsx, vsy, false, true)
			glTexture(0, false)
		glUseShader(0)
		
		glUseShader(bokehFinalPass)
			glTexture(0, downscaleTex)
			glTexture(1, Rtex)
			glTexture(2, Gtex)
			glTexture(3, Btex)
			glRenderToTexture(blurTex, glTexRect, -1, 1, 1, -1)
			glTexture(0, false)
			glTexture(1, false)
			glTexture(2, false)
			glTexture(3, false)
		glUseShader(0)
	else
		--apply a small gaussian blur to the downscaled image for DoF
		glUseShader(blurShaderH)
			glUniform(bloomInverseRXloc, 2.0/vsx)
			glUniformInt(bigBlurHloc, 0)
			mglRenderToTexture(pongTex, downscaleTex, 1, -1)
		glUseShader(0)
		
		glUseShader(blurShaderV)
			glUniform(bloomInverseRYloc, 2.0/vsy)
			glUniformInt(bigBlurVloc, 0)
			mglRenderToTexture(blurTex, pongTex, 1, -1)
		glUseShader(0)
	end
	
	if options.useBloom.value and bloomTex then
		mglRenderToTexture(bloomTex, blurTex, 1, -1)
		--apply a larger gaussian blur to the downscaled image for bloom
		glUseShader(blurShaderH)
			glUniform(bloomInverseRXloc, 4.0/vsx)
			glUniformInt(bigBlurHloc, 1)
			mglRenderToTexture(smallPongTex, bloomTex, 1, -1)
		glUseShader(0)
	
		glUseShader(blurShaderV)
			glUniform(bloomInverseRXloc, 4.0/vsy)
			glUniformInt(bigBlurVloc, 1)
			mglRenderToTexture(bloomTex, smallPongTex, 1, -1)
		glUseShader(0)
	end
end

function widget:DrawWorld()
	if dofPrepass then
		gl.ActiveShader(dofPrepass, function() glUniformMatrix(projectionLoc, "projection") end)
	end
end

function widget:DrawScreenEffects()
	if not options.useDoF.value and not options.useBloom.value then
		return -- if the option is disabled don't draw anything.
	end

	glResetMatrices()
	gl.Blending(false)
	gl.DepthTest(false)
	
	ApplyPreproc()
	
	glUseShader(dofShader)
		-- combine the final image.
		glTexture(0, screenTex)
		if options.useDoF.value then
			glTexture(1, downscaleTex)
			glTexture(2, blurTex)
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
