local wiName = "Outline Shader v3"
function widget:GetInfo()
	return {
		name      = wiName,
		desc      = "Displays small outline around units based on deferred g-buffer",
		author    = "ivand",
		date      = "2019",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		enabled   = false  --  loaded by default?
	}
end

-----------------------------------------------------------------
-- Constants
-----------------------------------------------------------------

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0
local PI = math.pi

-----------------------------------------------------------------
-- Configuration Constants
-----------------------------------------------------------------

local SUBTLE_MIN = 50
local SUBTLE_MAX = 3000

local BLUR_HALF_KERNEL_SIZE = 3 -- (BLUR_HALF_KERNEL_SIZE + BLUR_HALF_KERNEL_SIZE + 1) samples are used to perform the blur.
local BLUR_PASSES = 1 -- number of blur passes

local BLUR_SIGMA_ZOOMIN = 0.6
local BLUR_SIGMA_ZOOMOUT = 0.3

local OUTLINE_COLOR = {0.0, 0.0, 0.0, 1.0}
local OUTLINE_STRENGTH = 2.5 -- make it much smaller for softer edges

local USE_MATERIAL_INDICES = true

-----------------------------------------------------------------
-- Options
-----------------------------------------------------------------

local functionScaleWithHeight = true

options_path = 'Settings/Graphics/Unit Visibility/Outline v3'
options = {
	thickness = {
		name = 'Outline Thickness',
		desc = 'How thick the outline appears around objects (the thicker - the more expensive)',
		type = 'number',
		min = 1, max = 3, step = 1,
		value = 1,
		OnChange = function (self)
			BLUR_PASSES = self.value
		end,
	},
	functionScaleWithHeight = {
		name = 'Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function (self)
			functionScaleWithHeight = self.value
		end,
	},
}

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
local firstTime

local screenQuadList
local screenWideList


local shapeTex
local blurTexes = {}

local shapeFBO
local blurFBOs = {}

local shapeShader
local gaussianBlurShader


-----------------------------------------------------------------
-- Local Functions
-----------------------------------------------------------------

local function G(x, sigma)
	--return ( 1 / ( math.sqrt(2 * PI) * sigma ) ) * math.exp( -(x * x) / (2 * sigma * sigma) )
	return 0.3989422804 * math.exp(-0.5 * x * x / (sigma * sigma)) / sigma;
end

local dWeights = {}
local dOffsets = {}
local sum = 0
local function FillGaussDiscreteWeightsOffsets(sigma, kernelHalfSize, valMult)
	dWeights[1] = G(0, sigma)
	sum = dWeights[1]

	for i = 1, kernelHalfSize - 1 do
		dWeights[i + 1] = G(i, sigma)
		sum = sum + 2.0 * dWeights[i + 1]
	end

	for i = 0, kernelHalfSize - 1 do --normalize so the weights sum up to valMult
		dWeights[i + 1] = dWeights[i + 1] / sum * valMult
		dOffsets[i + 1] = i
	end
end

--see http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
local fWeights = {}
local fOffsets = {}
local function FillGaussLinearWeightsOffsets(sigma, kernelHalfSize, valMult)
	FillGaussDiscreteWeightsOffsets(sigma, kernelHalfSize, 1.0)

	fWeights = {dWeights[1]}
	fOffsets = {dOffsets[1]}

	for i = 1, (kernelHalfSize - 1) / 2 do
		local newWeight = dWeights[2 * i] + dWeights[2 * i + 1]
		fWeights[i + 1] = newWeight * valMult
		fOffsets[i + 1] = (dOffsets[2 * i] * dWeights[2 * i] + dOffsets[2 * i + 1] * dWeights[2 * i + 1]) / newWeight
	end
end

local function GetZoomScale()
	if not functionScaleWithHeight then
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
			return 0.0
		end

		return (((math.cos(PI * (cameraHeight - SUBTLE_MIN) / (SUBTLE_MAX - SUBTLE_MIN)) + 1) / 2)^2) / 2
	end
end

local function mix(a, b, t)
	return a * (1 - t) + b * t
end

-----------------------------------------------------------------
-- Widget Functions
-----------------------------------------------------------------

function widget:ViewResize()
	widget:Shutdown()
	widget:Initialize()
end

function widget:Initialize()
	local canContinue = LuaShader.isDeferredShadingEnabled and LuaShader.GetAdvShadingActive()
	if not canContinue then
		Spring.Echo(string.format("Error in [%s] widget: %s", wiName, "Deferred shading is not enabled or advanced shading is not active"))
	end

	firstTime = true
	vsx, vsy, vpx, vpy = Spring.GetViewGeometry()

	local commonTexOpts = {
		target = GL.TEXTURE_2D,
		border = false,
		min_filter = GL.NEAREST,
		mag_filter = GL.LINEAR,

		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
	}

	shapeTex = gl.CreateTexture(vsx, vsy, commonTexOpts)

	for i = 1, 2 do
		blurTexes[i] = gl.CreateTexture(vsx, vsy, commonTexOpts)
	end



	shapeFBO = gl.CreateFBO({
		color0 = shapeTex,
		drawbuffers = {GL_COLOR_ATTACHMENT0_EXT},
	})

	if not gl.IsValidFBO(shapeFBO) then
		Spring.Echo(string.format("Error in [%s] widget: %s", wiName, "Invalid shapeFBO"))
	end

	for i = 1, 2 do
		blurFBOs[i] = gl.CreateFBO({
			color0 = blurTexes[i],
			drawbuffers = {GL_COLOR_ATTACHMENT0_EXT},
		})
		if not gl.IsValidFBO(blurFBOs[i]) then
			Spring.Echo(string.format("Error in [%s] widget: %s", wiName, string.format("Invalid blurFBOs[%d]", i)))
		end
	end


	local identityShaderVert = VFS.LoadFile(shadersDir.."identity.vert.glsl")

	local shapeShaderFrag = VFS.LoadFile(shadersDir.."outlineShape3.frag.glsl")

	shapeShaderFrag = shapeShaderFrag:gsub("###USE_MATERIAL_INDICES###", tostring((USE_MATERIAL_INDICES and 1) or 0))
	shapeShaderFrag = shapeShaderFrag:gsub("###DEPTH_CLIP01###", (Platform.glSupportClipSpaceControl and "1" or "0"))


	shapeShader = LuaShader({
		vertex = identityShaderVert,
		fragment = shapeShaderFrag,
		uniformInt = {
			modelDepthTex = 1,
			modelMiscTex = 2,
			mapDepthTex = 3,
		},
		uniformFloat = {
			outlineColor = OUTLINE_COLOR,
		},
	}, wiName..": Shape drawing")
	shapeShader:Initialize()

	local gaussianBlurFrag = VFS.LoadFile(shadersDir.."gaussianBlur.frag.glsl")

	gaussianBlurFrag = gaussianBlurFrag:gsub("###BLUR_HALF_KERNEL_SIZE###", tostring(BLUR_HALF_KERNEL_SIZE))

	gaussianBlurShader = LuaShader({
		vertex = identityShaderVert,
		fragment = gaussianBlurFrag,
		uniformInt = {
			tex = 0,
		},
		uniformFloat = {
			viewPortSize = {vsx, vsy},
		},
	}, wiName..": Gaussian Blur")
	gaussianBlurShader:Initialize()
end

function widget:Shutdown()
	firstTime = nil

	if screenQuadList then
		gl.DeleteList(screenQuadList)
	end

	if screenWideList then
		gl.DeleteList(screenWideList)
	end

	gl.DeleteTexture(shapeTex)

	for i = 1, 2 do
		gl.DeleteTexture(blurTexes[i])
	end

	gl.DeleteFBO(shapeFBO)
	for i = 1, 2 do
		gl.DeleteFBO(blurFBOs[i])
	end

	shapeShader:Finalize()
	gaussianBlurShader:Finalize()
end

local function DoDrawOutline(isScreenSpace)
	gl.DepthTest(false)
	gl.DepthMask(false)
	gl.Blending(false)

	if firstTime then
		screenQuadList = gl.CreateList(gl.TexRect, -1, -1, 1, 1)
		if isScreenSpace then
			--screenWideList = gl.CreateList(gl.TexRect, 0, vsy, vsx, 0)
			screenWideList = gl.CreateList(gl.TexRect, 0, vsy, vsx, 0)
		else
			screenWideList = gl.CreateList(gl.TexRect, -1, -1, 1, 1, false, true)
		end
		firstTime = false
	end

	gl.ActiveFBO(shapeFBO, function()
		shapeShader:ActivateWith( function ()
			shapeShader:SetUniformMatrixAlways("projMatrix", "projection")
			gl.Texture(1, "$model_gbuffer_zvaltex")
			if USE_MATERIAL_INDICES then
				gl.Texture(2, "$model_gbuffer_misctex")
			end
			gl.Texture(3, "$map_gbuffer_zvaltex")

			gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)

			--gl.Texture(1, false) --will reuse later
			if USE_MATERIAL_INDICES then
				gl.Texture(2, false)
			end
		end)
	end)

	gl.Texture(0, shapeTex)

	gaussianBlurShader:ActivateWith( function ()
		local blurSigma = mix(BLUR_SIGMA_ZOOMIN, BLUR_SIGMA_ZOOMOUT, 1.0 - GetZoomScale())

		FillGaussLinearWeightsOffsets(blurSigma, BLUR_HALF_KERNEL_SIZE, OUTLINE_STRENGTH)
		gaussianBlurShader:SetUniformFloatArrayAlways("weights", fWeights)
		gaussianBlurShader:SetUniformFloatArrayAlways("offsets", fOffsets)
	end)

	for i = 1, BLUR_PASSES do
		gaussianBlurShader:ActivateWith( function ()
			gaussianBlurShader:SetUniform("dir", 1.0, 0.0) --horizontal blur
			gl.ActiveFBO(blurFBOs[1], function()
				gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
			end)
			gl.Texture(0, blurTexes[1])

			gaussianBlurShader:SetUniform("dir", 0.0, 1.0) --vertical blur
			gl.ActiveFBO(blurFBOs[2], function()
				gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
			end)
			gl.Texture(0, blurTexes[2])

		end)
	end

	gl.Blending(true)
	gl.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA) --alpha NO pre-multiply

	gl.Texture(1, false)
	gl.Texture(3, false)

	--gl.Texture(0, shapeTex)

	gl.CallList(screenWideList)

	gl.Texture(0, false)
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

function widget:DrawWorld()
	EnterLeaveScreenSpace(DoDrawOutline, false)
end
