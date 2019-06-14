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
	feature_metal = {
		shaderDefinitions = {
			"#define deferred_mode 0",
			"#define SHADOW_SOFTNESS SHADOW_HARD",
		},
		deferredDefinitions = {
			"#define deferred_mode 1",
			"#define SHADOW_SOFTNESS SHADOW_HARD",
			"#define MAT_IDX 130",
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
	if not cusFeatureMaterials[id] and fdef.metal > 1.0 then
		featureMaterials[id] = {"feature_metal"}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
