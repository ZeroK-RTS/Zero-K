function widget:GetInfo() return {
	name      = "Contrast Adaptive Sharpen",
	desc      = "Spring port of AMD FidelityFX' Contrast Adaptive Sharpen (CAS)",
	author    = "AMD Inc., SLSNe, martymcmodding, ivand", -- https://gist.github.com/martymcmodding/30304c4bffa6e2bd2eb59ff8bb09d135
	license   = "MIT",
	layer     = 2000, -- probably to draw after most world stuff but not things like UI
	enabled   = true,
} end

if not gl.CreateShader or not gl.GetVAO then
	Spring.Echo("CAS: GLSL not supported.")
	return
end

local vpx, vpy, vsx, vsy
local screenCopyTex
local casShader
local fullTexQuad

local LuaShader = VFS.Include("LuaUI/Widgets/Include/LuaShader.lua", nil, VFS.GAME)

local glTexture  = gl.Texture
local glBlending = gl.Blending
local glCopyToTexture = gl.CopyToTexture
local GL_TRIANGLES = GL.TRIANGLES

local defaultValue = 0
local isDisabled = (defaultValue ~= 0)

local function MakeShader()
	local sharpness = options.cas_sharpness4.value
	if sharpness == 0 then
		-- lazy initialisation; zero is the default so this avoids creating those objects to lay unused
		widgetHandler:RemoveCallIn("DrawScreenEffects")
		widgetHandler:RemoveCallIn("ViewResize")
		return
	end

	vsx, vsy, vpx, vpy = Spring.Orig.GetViewGeometry()

	casShader = LuaShader({
		vertex   = VFS.LoadFile("LuaUI/Widgets/Shaders/cas.vert.glsl"),
		fragment = VFS.LoadFile("LuaUI/Widgets/Shaders/cas.frag.glsl"),
		uniformInt = {
			screenCopyTex = 0,
		},
	}, ": Contrast Adaptive Sharpen")

	if not casShader then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
		widgetHandler:RemoveWidget()
		return
	end

	local shaderCompiled = casShader:Initialize()
	if not shaderCompiled then
		Spring.Echo("Failed to compile Contrast Adaptive Sharpen shader, removing widget")
		widgetHandler:RemoveWidget()
		return
	end

	screenCopyTex = gl.CreateTexture(vsx, vsy, {
		border = false,
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP,
		wrap_t = GL.CLAMP,
	})
	if screenCopyTex == nil then
		Spring.Echo("CAS: failed to gl.CreateTexture")
		widgetHandler:RemoveWidget()
		return
	end

	fullTexQuad = gl.GetVAO()
	if fullTexQuad == nil then
		Spring.Echo("CAS: failed to gl.getVAO")
		widgetHandler:RemoveWidget()
		return
	end
end

local function DisableShader()
	if casShader then
		casShader:Finalize()
		casShader = nil
	end

	if fullTexQuad then
		fullTexQuad:Delete()
		fullTexQuad = nil
	end

	if screenCopyTex then
		gl.DeleteTexture(screenCopyTex)
		screenCopyTex = nil
	end
end

local function UpdateShader()
	if options.cas_sharpness4.value > 0 then
		if isDisabled then
			isDisabled = false
			widgetHandler:UpdateCallIn("DrawScreenEffects")
			widgetHandler:UpdateCallIn("ViewResize")
		end
		if not casShader then
			MakeShader()
		end
		casShader:ActivateWith(function()
			casShader:SetUniform("sharpness", options.cas_sharpness4.value)
			casShader:SetUniform("viewPosX", vpx)
			casShader:SetUniform("viewPosY", vpy)
		end)
	else
		isDisabled = true
		widget:Shutdown()
		widgetHandler:RemoveCallIn("DrawScreenEffects")
		widgetHandler:RemoveCallIn("ViewResize")
	end
end

options_path = 'Settings/Graphics/Effects'
options = {
	cas_sharpness4 = {
		name = 'Sharpening',
		type = 'number',
		value = defaultValue, -- note `isDisabled` above, change to false if not leaving at 0. The value does not seem to be in any specific unit.
		min = 0.0,
		max = 1.25, -- can go even higher but at about 1.5 it degenerates, don't let it get near
		tooltipFunction = function(self)
			return "Current: " .. math.ceil(100*self.value) .. "%\nUse 100% as a reasonable reference value. Higher may be excessive\n"
		end,
		step = 0.01,
		OnChange = function(self)
			UpdateShader(self.value)
		end,
		noHotkey = true,
		update_on_the_fly = true,
	},
}

function widget:Initialize()
	UpdateShader()
end

function widget:Shutdown()
	DisableShader()
end

function widget:ViewResize()
	-- FIXME: could probably be optimized (reuse objects etc) but we're lazy
	DisableShader()
	UpdateShader()
end

function widget:DrawScreenEffects()
	glCopyToTexture(screenCopyTex, 0, 0, vpx, vpy, vsx, vsy)
	glTexture(0, screenCopyTex)
	glBlending(false)
	casShader:Activate()
	fullTexQuad:DrawArrays(GL_TRIANGLES, 3)
	casShader:Deactivate()
	glBlending(true)
	glTexture(0, false)
end
