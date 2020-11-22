local wiName = "Outline Shader v2"
function widget:GetInfo()
	return {
		name      = wiName,
		desc      = "Displays small outline around units based on deferred g-buffer",
		author    = "ivand",
		date      = "2019",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end

-----------------------------------------------------------------
-- Constants
-----------------------------------------------------------------

local GL_COLOR_ATTACHMENT0_EXT = 0x8CE0

-----------------------------------------------------------------
-- Configuration Constants
-----------------------------------------------------------------

local BLUR_PASSES = 2 -- number of blur passes
local BLUR_SIGMA = 1

local BLUR_HALF_KERNEL_SIZE_MIN = 3
local BLUR_HALF_KERNEL_SIZE_MAX = 8

local STRENGTH_MULT_MIN = 0.1
local STRENGTH_MULT_MAX = 10

local OUTLINE_COLOR = {0.0, 0.0, 0.0, 1.0}
local OUTLINE_STRENGTH = 6 -- make it much smaller for softer edges

local USE_MATERIAL_INDICES = true

local DEFAULT_STRENGTH_MULT = 0.5

local SUBTLE_MIN = 300
local SUBTLE_MAX = 3000

local WEIGHT_CACHE_FIDELITY = 60

-----------------------------------------------------------------
-- Configuration
-----------------------------------------------------------------

local configStrengthMult = DEFAULT_STRENGTH_MULT
local scaleWithHeight = true
local functionScaleWithHeight = true

options_path = 'Settings/Graphics/Unit Visibility/Outline'
options = {
	thickness = {
		name = 'Outline Thickness',
		desc = 'How thick the outline appears around objects',
		type = 'number',
		min = 0.2, max = 2, step = 0.01,
		value = DEFAULT_STRENGTH_MULT,
		OnChange = function (self)
			configStrengthMult = self.value
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
}

-----------------------------------------------------------------
-- File path Constants
-----------------------------------------------------------------

local shadersDir = "LuaUI/Widgets/Shaders/"

-----------------------------------------------------------------
-- Global Variables
-----------------------------------------------------------------

local LuaShader = VFS.Include("LuaRules/Gadgets/Include/LuaShader.lua")

local vsx, vsy, vpx, vpy
local firstTime

local screenQuadList
local screenWideList

local shapeTex
local blurTexes = {}

local shapeFBO
local blurFBOs = {}

local shapeShader
local gaussianBlurShader = {}
local applicationShader

local blurShaderHalfKernal = 6
local strengthMult = 1
local weightsCache = {}
local offsetsCache = {}

-----------------------------------------------------------------
-- Local Functions
-----------------------------------------------------------------

local function G(x, sigma)
	return ( 1 / ( math.sqrt(2 * math.pi) * sigma ) ) * math.exp( -(x * x) / (2 * sigma * sigma) )
end

local function GetGaussDiscreteWeightsOffsets(sigma, kernelHalfSize, valMult)
	local weights = {}
	local offsets = {}

	weights[1] = G(0, sigma)
	local sum = weights[1]

	for i = 1, kernelHalfSize - 1 do
		weights[i + 1] = G(i, sigma)
		sum = sum + 2.0 * weights[i + 1]
	end

	for i = 0, kernelHalfSize - 1 do --normalize so the weights sum up to valMult
		weights[i + 1] = weights[i + 1] / sum * valMult
		offsets[i + 1] = i
	end
	return weights, offsets
end

--see http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
local function GetGaussLinearWeightsOffsets(sigma, cacheIndex, kernelHalfSize, valMult)
	if weightsCache[cacheIndex] then
		return weightsCache[cacheIndex], offsetsCache[cacheIndex]
	end

	local dWeights, dOffsets = GetGaussDiscreteWeightsOffsets(sigma, kernelHalfSize, 1.0)

	local weights = {dWeights[1]}
	local offsets = {dOffsets[1]}

	for i = 1, (kernelHalfSize - 1) / 2 do
		local newWeight = dWeights[2 * i] + dWeights[2 * i + 1]
		weights[i + 1] = newWeight * valMult
		offsets[i + 1] = (dOffsets[2 * i] * dWeights[2 * i] + dOffsets[2 * i + 1] * dWeights[2 * i + 1]) / newWeight
	end

	weightsCache[cacheIndex] = weights
	offsetsCache[cacheIndex] = offsets
	return weights, offsets
end

local function SetThickness()
	local gaussWeights, gaussOffsets = GetGaussLinearWeightsOffsets(BLUR_SIGMA, math.floor(strengthMult*WEIGHT_CACHE_FIDELITY), blurShaderHalfKernal, strengthMult*OUTLINE_STRENGTH)
	gaussianBlurShader[blurShaderHalfKernal]:SetUniformFloatArrayAlways("weights", gaussWeights)
	gaussianBlurShader[blurShaderHalfKernal]:SetUniformFloatArrayAlways("offsets", gaussOffsets)
end

local function GetGaussianBlurShader(halfKernalSize)
	local blurFrag = VFS.LoadFile(shadersDir.."gaussianBlur.frag.glsl")

	blurFrag = blurFrag:gsub("###BLUR_HALF_KERNEL_SIZE###", tostring(halfKernalSize))
	
	local blurShader = LuaShader({
		vertex = identityShaderVert,
		fragment = blurFrag,
		uniformInt = {
			tex = 0,
		},
		uniformFloat = {
			viewPortSize = {vsx, vsy},
		},
	}, wiName..": Gaussian Blur")
	blurShader:Initialize()

	return blurShader
end

-----------------------------------------------------------------
-- Zoom Scale Functions
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

		return (((math.cos(math.pi*(cameraHeight - SUBTLE_MIN)/(SUBTLE_MAX - SUBTLE_MIN)) + 1)/2)^2)/2 + 0.5
	end

	local scaleFactor = 250.0 / cameraHeight
	scaleFactor = math.min(math.max(0.5, scaleFactor), 1.0)
	--Spring.Echo("cameraHeight", cameraHeight, "thicknessMult", thicknessMult)
	return scaleFactor
end

local function UpdateThicknessWithZoomScale()
	-- Warning: Magic numbers
	strengthMult = configStrengthMult*GetZoomScale()*0.6
	strengthMult = math.max(STRENGTH_MULT_MIN, math.min(STRENGTH_MULT_MAX, strengthMult))
	
	blurShaderHalfKernal = math.floor(strengthMult*7 + 0.5)
	blurShaderHalfKernal = math.max(BLUR_HALF_KERNEL_SIZE_MIN, math.min(BLUR_HALF_KERNEL_SIZE_MAX, blurShaderHalfKernal))
	if not gaussianBlurShader[blurShaderHalfKernal] then
		gaussianBlurShader[blurShaderHalfKernal] = GetGaussianBlurShader(blurShaderHalfKernal)
	end
	
	--Spring.Echo("strengthMult", strengthMult, blurShaderHalfKernal)
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
		target = GL_TEXTURE_2D,
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

	local shapeShaderFrag = VFS.LoadFile(shadersDir.."outlineShape2.frag.glsl")

	shapeShaderFrag = shapeShaderFrag:gsub("###USE_MATERIAL_INDICES###", tostring((USE_MATERIAL_INDICES and 1) or 0))

	shapeShader = LuaShader({
		vertex = identityShaderVert,
		fragment = shapeShaderFrag,
		uniformInt = {
			-- be consistent with gfx_deferred_rendering.lua
			--	glTexture(1, "$model_gbuffer_zvaltex")
			modelDepthTex = 1,
			modelMiscTex = 2,
			mapDepthTex = 3,
		},
		uniformFloat = {
			outlineColor = OUTLINE_COLOR,
		},
	}, wiName..": Shape drawing")
	shapeShader:Initialize()

	local applicationFrag = VFS.LoadFile(shadersDir.."outlineApplication2.frag.glsl")

	applicationShader = LuaShader({
		vertex = identityShaderVert,
		fragment = applicationFrag,
		uniformInt = {
			tex = 0,
			modelDepthTex = 1,
			mapDepthTex = 3,
		},
		uniformFloat = {
			viewPortSize = {vsx, vsy},
		},
	}, wiName..": Outline Application")
	applicationShader:Initialize()
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
	for i = BLUR_HALF_KERNEL_SIZE_MIN, BLUR_HALF_KERNEL_SIZE_MAX do
		if gaussianBlurShader[i] then
			gaussianBlurShader[i]:Finalize()
		end
	end
	applicationShader:Finalize()
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

	local blurShader = gaussianBlurShader[blurShaderHalfKernal]
	for i = 1, BLUR_PASSES do
		blurShader:ActivateWith( function ()

			blurShader:SetUniform("dir", 1.0, 0.0) --horizontal blur
			gl.ActiveFBO(blurFBOs[1], function()
				gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
			end)
			gl.Texture(0, blurTexes[1])

			blurShader:SetUniform("dir", 0.0, 1.0) --vertical blur
			gl.ActiveFBO(blurFBOs[2], function()
				gl.CallList(screenQuadList) -- gl.TexRect(-1, -1, 1, 1)
			end)
			gl.Texture(0, blurTexes[2])

		end)
	end
	
	gl.Blending(true)
	gl.BlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA) --alpha NO pre-multiply

	--gl.Texture(1, "$model_gbuffer_zvaltex") -- already bound

	applicationShader:ActivateWith( function ()
		gl.CallList(screenWideList)
	end)

	gl.Texture(0, false)
	gl.Texture(1, false)
	gl.Texture(3, false)
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
	UpdateThicknessWithZoomScale()
	gaussianBlurShader[blurShaderHalfKernal]:ActivateWith(SetThickness)
	EnterLeaveScreenSpace(DoDrawOutline, false)
end
