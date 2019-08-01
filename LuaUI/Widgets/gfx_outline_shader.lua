local wiName = "Outline Shader"
function widget:GetInfo()
	return {
		name      = wiName,
		desc      = "Displays small outline around units based on deferred g-buffer",
		author    = "ivand",
		date      = "2019",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		enabled   = true, --  loaded by default?
	}
end

-----------------------------------------------------------------
-- Constants
-----------------------------------------------------------------

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0

local GL_RGBA = 0x1908
--GL_DEPTH_COMPONENT32F is the default for deferred depth textures, but Lua API only works correctly with GL_DEPTH_COMPONENT32
local GL_DEPTH_COMPONENT32 = 0x81A7

local PI = math.pi

-----------------------------------------------------------------
-- Configuration Constants
-----------------------------------------------------------------

local SUBTLE_MIN = 500
local SUBTLE_MAX = 3000

local DILATE_SINGLE_PASS = false --true is slower on my system
local DILATE_HALF_KERNEL_SIZE = 3
local DILATE_PASSES = 1

local OUTLINE_COLOR = {0.0, 0.0, 0.0, 1.0}
--local OUTLINE_COLOR = {0.75, 0.75, 0.75, 1.0}
--local OUTLINE_COLOR = {0.0, 0.0, 0.0, 1.0}
local OUTLINE_STRENGTH_BLENDED = 1.0
local OUTLINE_STRENGTH_ALWAYS_ON = 0.6

local USE_MATERIAL_INDICES = true


-----------------------------------------------------------------
-- File path Constants
-----------------------------------------------------------------

local shadersDir = "LuaUI/Widgets/Shaders/"
local luaShaderDir = "LuaUI/Widgets/Include/"

-----------------------------------------------------------------
-- Global Variables
-----------------------------------------------------------------

local LuaShader = VFS.Include(luaShaderDir.."LuaShader.lua")

local vsx, vsy, vpx, vpy

local screenQuadList
local screenWideList


local shapeDepthTex
local shapeColorTex

local dilationDepthTexes = {}
local dilationColorTexes = {}

local shapeFBO
local dilationFBOs = {}

local shapeShader
local dilationShader
local applicationShader

local pingPongIdx = 1

local shadersEnabled = Spring.Utilities.IsCurrentVersionNewerThan(104, 1243) and LuaShader.isDeferredShadingEnabled and LuaShader.GetAdvShadingActive()
-----------------------------------------------------------------
-- Configuration
-----------------------------------------------------------------

local DEFAULT_THICKNESS = 0.5
local thickness = DEFAULT_THICKNESS
local scaleWithHeight = true
local functionScaleWithHeight = true

options_path = 'Settings/Graphics/Unit Visibility/Outline'
options = {
	thickness = {
		name = 'Outline Thickness',
		desc = 'How thick the outline appears around objects',
		type = 'number',
		min = 0.2, max = 1, step = 0.01,
		value = DEFAULT_THICKNESS,
		OnChange = function (self)
			thickness = self.value
		end,
	},
	scaleWithHeight = {
		name = 'Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out.',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function (self)
			scaleWithHeight = self.value
			if not scaleWithHeight then
				thicknessMult = 1
			end
		end,
	},
	functionScaleWithHeight = {
		name = 'Subtle Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out, in a subtle way.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function (self)
			functionScaleWithHeight = self.value
			if not functionScaleWithHeight then
				thicknessMult = 1
			end
		end,
	},
	drawUnderCeg = {
		name = 'Draw through effects',
		desc = 'Reduces the screen space width of outlines when zoomed out.',
		type = 'bool',
		value = false,
	},
}

-----------------------------------------------------------------
-- Local Functions
-----------------------------------------------------------------

local function GetZoomScale()
	if not (scaleWithHeight or functionScaleWithHeight) then
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
	--Spring.Echo("cameraHeight", cameraHeight)

	if functionScaleWithHeight then
		if cameraHeight < SUBTLE_MIN then
			return 1
		end
		if cameraHeight > SUBTLE_MAX then
			return 0.5
		end

		return (((math.cos(PI*(cameraHeight - SUBTLE_MIN)/(SUBTLE_MAX - SUBTLE_MIN)) + 1)/2)^2)/2 + 0.5
	end

	local scaleFactor = 250.0 / cameraHeight
	scaleFactor = math.min(math.max(0.5, scaleFactor), 1.0)
	--Spring.Echo("cameraHeight", cameraHeight, "thicknessMult", thicknessMult)
	return scaleFactor
end

local function PrepareOutline(cleanState)
	gl.DepthTest(true)
	gl.DepthTest(GL.ALWAYS)

	gl.ActiveFBO(shapeFBO, function()
		shapeShader:ActivateWith( function ()
			gl.Texture(2, "$model_gbuffer_zvaltex")
			if USE_MATERIAL_INDICES then
				gl.Texture(1, "$model_gbuffer_misctex")
			end
			gl.Texture(3, "$map_gbuffer_zvaltex")

			gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)

			--gl.Texture(1, false) --will reuse later
			if USE_MATERIAL_INDICES then
				gl.Texture(1, false)
			end
		end)
	end)


	gl.Texture(0, shapeDepthTex)
	gl.Texture(1, shapeColorTex)

	for i = 1, DILATE_PASSES do
		dilationShader:ActivateWith( function ()
			strength = thickness * GetZoomScale()
			dilationShader:SetUniformFloat("strength", strength)

			if DILATE_SINGLE_PASS then
				pingPongIdx = (pingPongIdx + 1) % 2
				gl.ActiveFBO(dilationFBOs[pingPongIdx + 1], function()
					gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
				end)
				gl.Texture(0, dilationDepthTexes[pingPongIdx + 1])
				gl.Texture(1, dilationColorTexes[pingPongIdx + 1])

			else
				pingPongIdx = (pingPongIdx + 1) % 2
				dilationShader:SetUniform("dir", 1.0, 0.0) --horizontal dilation
				gl.ActiveFBO(dilationFBOs[pingPongIdx + 1], function()
					gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
				end)
				gl.Texture(0, dilationDepthTexes[pingPongIdx + 1])
				gl.Texture(1, dilationColorTexes[pingPongIdx + 1])

				pingPongIdx = (pingPongIdx + 1) % 2
				dilationShader:SetUniform("dir", 0.0, 1.0) --vertical dilation
				gl.ActiveFBO(dilationFBOs[pingPongIdx + 1], function()
					gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
				end)
				gl.Texture(0, dilationDepthTexes[pingPongIdx + 1])
				gl.Texture(1, dilationColorTexes[pingPongIdx + 1])
			end
		end)
	end

	if cleanState then
		gl.DepthTest(GL.LEQUAL) --default mode

		gl.Texture(0, false)
		gl.Texture(1, false)
		gl.Texture(2, false)
		gl.Texture(3, false)
	end
end

local function DrawOutline(strength, loadTextures, drawWorld)
	if loadTextures then
		gl.Texture(0, dilationDepthTexes[pingPongIdx + 1])
		gl.Texture(1, dilationColorTexes[pingPongIdx + 1])
		gl.Texture(2, shapeDepthTex)
		gl.Texture(3, "$map_gbuffer_zvaltex")
	end

	gl.AlphaTest(true)
	gl.AlphaTest(GL.GREATER, 0.0);
	gl.DepthTest(GL.LEQUAL) --restore default mode
	gl.Blending("alpha")

	applicationShader:ActivateWith( function ()
		-- For drawing through terrain
		--applicationShader:SetUniformFloat("alwaysShowOutLine", (drawWorld and 1.0) or 0.0)
		applicationShader:SetUniformFloat("strength", strength)
		gl.CallList(screenWideList)
	end)

	gl.Texture(0, false)
	gl.Texture(1, false)
	gl.Texture(2, false)
	gl.Texture(3, false)

	gl.DepthTest(not drawWorld)
	if not drawWorld then
		gl.Blending(false)
	end
	gl.AlphaTest(GL.GREATER, 0.5);  --default mode
	gl.AlphaTest(false)
end


local function EnterLeaveScreenSpace(functionName, ...)
	gl.MatrixMode(GL.MODELVIEW)
	gl.PushMatrix()
	gl.LoadIdentity()

		gl.MatrixMode(GL.PROJECTION)
		gl.PushMatrix()
		gl.LoadIdentity();

			functionName(...)

		gl.MatrixMode(GL.PROJECTION)
		gl.PopMatrix()

	gl.MatrixMode(GL.MODELVIEW)
	gl.PopMatrix()
end

-----------------------------------------------------------------
-- Widget Functions
-----------------------------------------------------------------

function widget:ViewResize()
	widget:Shutdown()
	widget:Initialize()
end

function widget:Initialize()
	if not shadersEnabled then
		Spring.Echo(string.format("Error in [%s] widget: %s", wiName, "Deferred shading is not enabled or advanced shading is not active"))
		WG.HudEnableWidget("Outline No Shader")
		widgetHandler:RemoveWidget()
		return
	end
	WG.HudDisableWidget("Outline No Shader")

	local configName = "AllowDrawModelPostDeferredEvents"
	if Spring.GetConfigInt(configName, 0) == 0 then
		Spring.SetConfigInt(configName, 1) --required to enable receiving DrawUnitsPostDeferred/DrawFeaturesPostDeferred
	end

	vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

	-- depth textures
	local commonTexOpts = {
		target = GL_TEXTURE_2D,
		border = false,
		min_filter = GL.NEAREST,
		mag_filter = GL.NEAREST,

		format = GL_DEPTH_COMPONENT32,

		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
	}

	shapeDepthTex = gl.CreateTexture(vsx, vsy, commonTexOpts)
	for i = 1, 2 do
		dilationDepthTexes[i] = gl.CreateTexture(vsx, vsy, commonTexOpts)
	end

	-- color textures
	commonTexOpts.format = GL_RGBA
	shapeColorTex = gl.CreateTexture(vsx, vsy, commonTexOpts)
	for i = 1, 2 do
		dilationColorTexes[i] = gl.CreateTexture(vsx, vsy, commonTexOpts)
	end

	shapeFBO = gl.CreateFBO({
		depth = shapeDepthTex,
		color0 = shapeColorTex,
		drawbuffers = {GL_COLOR_ATTACHMENT0_EXT},
	})

	if not gl.IsValidFBO(shapeFBO) then
		Spring.Echo(string.format("Error in [%s] widget: %s", wiName, "Invalid shapeFBO"))
	end

	for i = 1, 2 do
		dilationFBOs[i] = gl.CreateFBO({
			depth = dilationDepthTexes[i],
			color0 = dilationColorTexes[i],
			drawbuffers = {GL_COLOR_ATTACHMENT0_EXT},
		})
		if not gl.IsValidFBO(dilationFBOs[i]) then
			Spring.Echo(string.format("Error in [%s] widget: %s", wiName, string.format("Invalid dilationFBOs[%d]", i)))
		end
	end

	local identityShaderVert = VFS.LoadFile(shadersDir.."identity.vert.glsl")

	local shapeShaderFrag = VFS.LoadFile(shadersDir.."outlineShape.frag.glsl")

	shapeShaderFrag = shapeShaderFrag:gsub("###USE_MATERIAL_INDICES###", tostring((USE_MATERIAL_INDICES and 1) or 0))

	shapeShader = LuaShader({
		vertex = identityShaderVert,
		fragment = shapeShaderFrag,
		uniformInt = {
			modelDepthTex = 2,
			modelMiscTex = 1,
			mapDepthTex = 3,
		},
		uniformFloat = {
			outlineColor = OUTLINE_COLOR,
			--viewPortSize = {vsx, vsy},
		},
	}, wiName..": Shape identification")
	shapeShader:Initialize()

	local dilationShaderFrag = VFS.LoadFile(shadersDir.."outlineDilate.frag.glsl")
	dilationShaderFrag = dilationShaderFrag:gsub("###DILATE_SINGLE_PASS###", tostring((DILATE_SINGLE_PASS and 1) or 0))
	dilationShaderFrag = dilationShaderFrag:gsub("###DILATE_HALF_KERNEL_SIZE###", tostring(DILATE_HALF_KERNEL_SIZE))
	dilationShaderFrag = dilationShaderFrag:gsub("###STRICT_GL###", tostring((Platform.gpuVendor == "Nvidia" and 0) or 1))

	dilationShader = LuaShader({
		vertex = identityShaderVert,
		fragment = dilationShaderFrag,
		uniformInt = {
			depthTex = 0,
			colorTex = 1,
		},
		uniformFloat = {
			viewPortSize = {vsx, vsy},
		}
	}, wiName..": Dilation")
	dilationShader:Initialize()


	local applicationFrag = VFS.LoadFile(shadersDir.."outlineApplication.frag.glsl")

	applicationShader = LuaShader({
		vertex = identityShaderVert,
		fragment = applicationFrag,
		uniformInt = {
			dilatedDepthTex = 0,
			dilatedColorTex = 1,
			shapeDepthTex = 2,
			mapDepthTex = 3,
		},
		uniformFloat = {
			viewPortSize = {vsx, vsy},
		},
	}, wiName..": Outline Application")
	applicationShader:Initialize()

	screenQuadList = gl.CreateList(gl.TexRect, -1, -1, 1, 1)
	screenWideList = gl.CreateList(gl.TexRect, -1, -1, 1, 1, false, true)
end

function widget:Shutdown()
	if not shadersEnabled then
		return
	end

	if screenQuadList then
		gl.DeleteList(screenQuadList)
	end

	if screenWideList then
		gl.DeleteList(screenWideList)
	end

	gl.DeleteTexture(shapeDepthTex)
	gl.DeleteTexture(shapeColorTex)

	for i = 1, 2 do
		gl.DeleteTexture(dilationColorTexes[i])
		gl.DeleteTexture(dilationDepthTexes[i])
	end


	gl.DeleteFBO(shapeFBO)

	for i = 1, 2 do
		gl.DeleteFBO(dilationFBOs[i])
	end

	shapeShader:Finalize()
	dilationShader:Finalize()
	applicationShader:Finalize()
end

function widget:DrawWorld()
	if options.drawUnderCeg.value then
		EnterLeaveScreenSpace(DrawOutline, OUTLINE_STRENGTH_ALWAYS_ON, true, true)
	end
end

function widget:DrawUnitsPostDeferred()
	EnterLeaveScreenSpace(function ()
		PrepareOutline(false)
		DrawOutline(OUTLINE_STRENGTH_BLENDED, false, false)
	end)
end
