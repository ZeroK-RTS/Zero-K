local OPTION_SHADOWMAPPING      = 1     -- Self shadowing
local OPTION_NORMALMAPPING      = 2     -- Applies normalmapping
local OPTION_SHIFT_RGBHSV       = 4     -- currently a No-op due to performance concerns
local OPTION_VERTEX_AO          = 8     -- Per vertex Ambient Occlusion
local OPTION_FLASHLIGHTS        = 16    -- All emissive (tex2.red) will strobe in brightness
local OPTION_TREADS_U           = 32    -- Treads that scroll left-right (texture U coord)
local OPTION_TREADS_V           = 64    -- Treads that scroll up-down (texture V coord)
local OPTION_HEALTH_TEXTURING   = 128   -- Gradually overlays wreck texture as unit gets damaged (units only)
local OPTION_HEALTH_DISPLACE    = 256   -- Gradually bends vertices out of shape as unit gets damaged
local OPTION_HEALTH_TEXRAPTORS  = 512   -- Progressive blood pooling on damaged raptors based on low heightmap values stored in alpha channel of normal map
local OPTION_MODELSFOG          = 1024  -- Applies linear fog effect to units based on zoom level
local OPTION_TREEWIND           = 2048  -- Makes trees sway gently in the breeze
local OPTION_PBROVERRIDE        = 4096  -- Forces Recoil default tex2 (non PBR) behaviour

local defaultBitShaderOptions = OPTION_SHADOWMAPPING + OPTION_MODELSFOG
local defaultUnitBitShaderOptions = defaultBitShaderOptions + OPTION_HEALTH_TEXTURING + OPTION_HEALTH_DISPLACE + OPTION_NORMALMAPPING -- + OPTION_VERTEX_AO
--  OPTION_VERTEX_AO causes black splodges on curved surfaces and some overly dark textures.

local uniformBins = {
	-- Special overriding uniformBins go here, i.e. so that you can set different uniforms:
		-- bitOptions               - Determines which of the above options are enabled for units assigned to this uniformBin
		-- baseVertexDisplacement   - If using OPTION_HEALTH_DISPLACE and OPTION_HEALTH_TEXTURING determines the starting distortion
		-- brightnessFactor         - How bright the units in this uniformBin will appear
		-- treadRect                - Defines the region (in pixels) on the texture that the tank treads belong to; left, top, width, height
		-- treadLinkWidth,          - Defines the width (in pixels) of a single track link on the texture
		-- treadSpeedMult           - Allows to speed up or reverse direction (with negative values) tank tread 
	
	-- To force a unit or feature into any uniformBin, assign customParams.uniformbin = binName,
	-- this method is preferred to the mix of BAR customparams which are kept for backwards compat
	
	-- myunitswithflashinglights = {
	--		bitOptions = defaultUnitBitShaderOptions + OPTION_FLASHLIGHTS,
	--		baseVertexDisplacement = 0.0,
	--		brightnessFactor = 1.5,
	-- },
	--treadsexample = {
	--	bitOptions = defaultUnitBitShaderOptions + OPTION_TREADS_V, -- treads are top-bottom on the texture
	--	baseVertexDisplacement = 0.0,
	--	brightnessFactor = 1.1,
	--	treadRect = {933, 0, 1024 - 933, 1024}, 
	--	treadLinkWidth = 22,
	--	treadSpeedMult = 4.0,
	--},
	
	-- DEFAULT UNIFORM BINS
	defaultunit = {
		-- by default gadget will assign these options to every unit texture set bin
		bitOptions = defaultUnitBitShaderOptions,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 1,
	},
	defaultunit_transparent = {
		-- by default gadget will assign these options to every unit texture set bin
		bitOptions = defaultUnitBitShaderOptions,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 1,
	},
	-- These are the default featureDef uniformBins, you probably don't want to mess with them unless you really know what you're doing
	feature = {
		-- by default gadget will assign these options to every (non-wreck, non-tree) feature texture set bin
		bitOptions = defaultBitShaderOptions + OPTION_PBROVERRIDE,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 0.9,
	},
	featurepbr = {
		-- any feature with featureDef.customParams.cuspbr, or that appears in ModelMaterials_GL4/known_pbr_features.lua
		bitOptions = defaultBitShaderOptions,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 1.3,
	},
	treepbr = {
		-- Currently unused?
		bitOptions = defaultBitShaderOptions + OPTION_TREEWIND + OPTION_PBROVERRIDE,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 1.3,
	},
	tree = {
		-- any whitelisted tree in ModelMaterials_GL4/known_feature_trees.lua, or with featureDef.customParams.treeshader = 'yes', or which contains 'tree' and not 'stree'
		bitOptions = defaultBitShaderOptions + OPTION_TREEWIND + OPTION_PBROVERRIDE,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 1.3,
	},
	wreck = {
		-- any feature referenced in a unitDef.corpse, or featureDef.featureDead or with '_x', '_dead' or '_heap' in the name
		bitOptions = defaultBitShaderOptions + OPTION_VERTEX_AO,
		baseVertexDisplacement = 0.0,
		brightnessFactor = 1.3,
	},
} -- maps uniformbins to a table of uniform names/values

local uniformBinOrder = {
	"wreck",
	"tree",
	"treepbr",
	"featurepbr",
	"feature",
	"defaultunit",
	"defaultunit_transparent",
}

local texToPreload = {
	-- only preload textures not loaded by engine e.g. normals or custom wreckTex
	--[[ BAR example
	"unittextures/Arm_wreck_color_normal.dds",
	"unittextures/Arm_normal.dds",
	"unittextures/cor_color_wreck_normal.dds",
	"unittextures/cor_normal.dds",--]]
}
-- BAR example of changing based on ModOption
--[[if Spring.GetModOptions().experimentallegionfaction then
	table.insert(texToPreload, "unittextures/leg_wreck_normal.dds")
end--]]

return uniformBins, uniformBinOrder, texToPreload