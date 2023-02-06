function widget:GetInfo() return {
	name      = "Contrast Adaptive Sharpen",
	desc      = "Spring port of AMD FidelityFX' Contrast Adaptive Sharpen (CAS)",
	author    = "martymcmodding, ivand",
	layer     = 2000,
	enabled   = true,
} end

if not gl.CreateShader then
	Spring.Echo(widget:GetInfo().name .. ": GLSL not supported.")
	return
end

-- Shameless port from https://gist.github.com/martymcmodding/30304c4bffa6e2bd2eb59ff8bb09d135

-----------------------------------------------------------------
-- Constants
-----------------------------------------------------------------

local SHARPNESS = 1.0
local version = 1.06

-----------------------------------------------------------------
-- Lua Shortcuts
-----------------------------------------------------------------

local glTexture  = gl.Texture
local glBlending = gl.Blending

-----------------------------------------------------------------
-- Global Variables
-----------------------------------------------------------------

local LuaShader = VFS.Include("LuaUI/Widgets/Include/LuaShader.lua")

local vpx, vpy, vsx, vsy
local screenCopyTex
local casShader

local fullTexQuad

local glCopyToTexture = gl.CopyToTexture


-----------------------------------------------------------------
-- Local Functions
-----------------------------------------------------------------

local function UpdateShader()
	casShader:ActivateWith(function()
		casShader:SetUniform("sharpness", SHARPNESS)
		casShader:SetUniform("viewPosX", vpx)
		casShader:SetUniform("viewPosY", vpy)
	end)
end

-----------------------------------------------------------------
-- Widget Functions
-----------------------------------------------------------------

function widget:Initialize()
	vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

	casShader = LuaShader({
		vertex   = VFS.LoadFile("LuaUI/Widgets/Shaders/cas.vert.glsl"),
		fragment = VFS.LoadFile("LuaUI/Widgets/Shaders/cas.frag.glsl"),
		uniformInt = {
			screenCopyTex = 0,
		},
	}, ": Contrast Adaptive Sharpen")

	if not casShader then
		Spring.Log(widget:GetInfo().name, LOG.ERROR, gl.GetShaderLog())
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

	UpdateShader()

	fullTexQuad = gl.GetVAO()
	if fullTexQuad == nil then
		widgetHandler:RemoveWidget() --no fallback for potatoes
		return
	end
end

function widget:Shutdown()
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

function widget:ViewResize()
	-- FIXME: could probably be optimized (reuse objects etc) but we're lazy
	widget:Shutdown()
	widget:Initialize()
end

function widget:DrawScreenEffects()
	glCopyToTexture(screenCopyTex, 0, 0, vpx, vpy, vsx, vsy)
	glTexture(0, screenCopyTex)
	glBlending(false)
	casShader:Activate()
	fullTexQuad:DrawArrays(GL.TRIANGLES, 3)
	casShader:Deactivate()
	glBlending(true)
	glTexture(0, false)
end

function widget:GetConfigData()
	return {
		version = version,
		SHARPNESS = SHARPNESS
	}
end

function widget:SetConfigData(data)
	if data.SHARPNESS ~= nil and data.version ~= nil and data.version == version then
		SHARPNESS = data.SHARPNESS
	end
end
