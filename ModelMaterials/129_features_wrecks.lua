-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SunChanged(curShaderObj)
	curShaderObj:SetUniformAlways("shadowDensity", gl.GetSun("shadowDensity" ,"unit"))

	curShaderObj:SetUniformAlways("sunAmbient", gl.GetSun("ambient" ,"unit"))
	curShaderObj:SetUniformAlways("sunDiffuse", gl.GetSun("diffuse" ,"unit"))
	curShaderObj:SetUniformAlways("sunSpecular", gl.GetSun("specular" ,"unit"))
end

local materials = {
	feature_wrecks = {
		shaderDefinitions = {
			"#define deferred_mode 0",
			"#define SPECULARSUNEXP 24.0",
			"#define SPECULARMULT 1.0",
			"#define EXTRACOLOR_G_NOISE vec2(16.0)",
			"#define SHADOW_SOFTNESS SHADOW_HARD",
		},
		deferredDefinitions = {
			"#define deferred_mode 1",
			"#define SPECULARSUNEXP 24.0",
			"#define SPECULARMULT 1.0",
			"#define EXTRACOLOR_G_NOISE vec2(16.0)",
			"#define SHADOW_SOFTNESS SHADOW_HARD",
			"#define MAT_IDX 129",
		},
		force     = false, --// always use the shader even when normalmapping is disabled
		feature   = true, --// This is used to define that this is a feature shader
		usecamera = false,
		culling   = GL.BACK,
		texunits  = {
			[0] = "%%FEATUREDEFID:0",
			[1] = "%%FEATUREDEFID:1",
			[2] = "$shadow",
			--[3] = "$specular",
			[4] = "$reflection",
		},
		SunChanged = SunChanged,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local cusFeatureMaterials = GG.CUS[2].bufMaterials

local featureMaterials = {}

for id = 1, #FeatureDefs do
	local fdef = FeatureDefs[id]
	if not cusFeatureMaterials[id] and fdef.customParams.fromunit then
		featureMaterials[id] = {"feature_wrecks"}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
