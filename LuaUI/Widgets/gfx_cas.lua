function widget:GetInfo()
	return {
		name      = "Contrast Adaptive Sharpen",
		desc      = "Spring port of AMD FidelityFX' Contrast Adaptive Sharpen (CAS)",
		author    = "AMD Inc., SLSNe, martymcmodding, ivand", -- https://gist.github.com/martymcmodding/30304c4bffa6e2bd2eb59ff8bb09d135
		license   = "MIT",
		layer     = 2000, -- probably to draw after most world stuff but not things like UI
		enabled   = true,
	}
end

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

local defaultValue = 1
local isDisabled = (defaultValue ~= 0)

-----------------------------------------------------------------
-- Zoom configuration
-----------------------------------------------------------------

local oldZoomScale = false

local function GetZoomScale()
	if options.cas_height_scale.value == 1 then
		return 1
	end
	local cs = Spring.GetCameraState()
	local gy = Spring.GetGroundHeight(cs.px, cs.pz)
	local cameraHeight
	if cs.name == "ta" then
		cameraHeight = cs.height - gy
	else
		cameraHeight = cs.py - gy
	end
	cameraHeight = math.max(1.0, cameraHeight)

	local zoomMin = options.cas_height_scale_start.value
	local zoomMax = options.cas_height_scale_end.value
	if cameraHeight < zoomMin then
		return 1
	end
	if cameraHeight > zoomMax then
		return options.cas_height_scale.value
	end
	
	local zoomScale = (math.cos(math.pi*((cameraHeight - zoomMin)/(zoomMax - zoomMin))^0.75) + 1)/2
	--Spring.Echo("zoomScale", zoomScale)
	return zoomScale*(1 - options.cas_height_scale.value) + options.cas_height_scale.value
end

local function GetCurrentZoomScale()
	oldZoomScale = GetZoomScale()
	return oldZoomScale
end

local function GetChangedZoomScale()
	local newZoomScale = GetZoomScale()
	if newZoomScale == oldZoomScale then
		return false 
	end
	oldZoomScale = newZoomScale
	return 
end

-----------------------------------------------------------------
-- Shader stuff
-----------------------------------------------------------------

local function MakeShader()
	local sharpness = options.cas_sharpness5.value
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

-----------------------------------------------------------------
-- Settings
-----------------------------------------------------------------

local function UpdateShader()
	if options.cas_sharpness5.value > 0 then
		if isDisabled then
			isDisabled = false
			widgetHandler:UpdateCallIn("DrawScreenEffects")
			widgetHandler:UpdateCallIn("ViewResize")
		end
		if not casShader then
			MakeShader()
		end
		casShader:ActivateWith(function()
			casShader:SetUniform("sharpness", options.cas_sharpness5.value * GetCurrentZoomScale())
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

options_path = 'Settings/Graphics/Effects/CAS'
options_order = {'cas_sharpness5', 'cas_height_scale', 'cas_height_scale_start', 'cas_height_scale_end'}
options = {
	cas_sharpness5 = {
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
			UpdateShader()
		end,
		noHotkey = true,
		update_on_the_fly = true,
	},
	cas_height_scale = {
		name = 'Zoom sharpening range',
		type = 'number',
		value = 0.65,
		min = 0,
		max = 1,
		tooltipFunction = function(self)
			return "Current: " .. math.ceil(100*self.value) .. "%\nUse 100% to retain the same sharpening over all zoom levels and, 0% to scale to nothing\n"
		end,
		step = 0.01,
		OnChange = function(self)
			UpdateShader()
		end,
		noHotkey = true,
		update_on_the_fly = true,
	},
	cas_height_scale_start = {
		name = 'Zoom start',
		type = 'number',
		value = 300, 
		min = 0,
		max = 8000,
		tooltipFunction = function(self)
			return "Current: " .. self.value .. "\nMinimum camera height for zoom scaling."
		end,
		step = 50,
		OnChange = function(self)
			UpdateShader()
		end,
		noHotkey = true,
		update_on_the_fly = true,
	},
	cas_height_scale_end = {
		name = 'Zoom end',
		type = 'number',
		value = 4000, 
		min = 0,
		max = 8000,
		tooltipFunction = function(self)
			return "Current: " .. self.value .. "\nMaximum camera height for zoom scaling."
		end,
		step = 50,
		OnChange = function(self)
			UpdateShader()
		end,
		noHotkey = true,
		update_on_the_fly = true,
	},
}

-----------------------------------------------------------------
-- API
-----------------------------------------------------------------

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
	if options.cas_height_scale.value ~= 1 then
		local zoomScale = GetChangedZoomScale()
		if zoomScale then
			casShader:SetUniform("sharpness", options.cas_sharpness5.value * zoomScale)
		end
	end
	fullTexQuad:DrawArrays(GL_TRIANGLES, 3)
	casShader:Deactivate()
	glBlending(true)
	glTexture(0, false)
end
