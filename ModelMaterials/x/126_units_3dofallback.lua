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
	units3doFallback = {
		shaderDefinitions = {
			"#define deferred_mode 0",
			"#define SHADOW_SOFTNESS SHADOW_SOFT",
		},
		deferredDefinitions = {
			"#define deferred_mode 1",
			"#define SHADOW_SOFTNESS SHADOW_HARD",
			"#define MAT_IDX 126",
		},
		usecamera = false,
		culling   = false,
		texunits  = {
			[0] = "$units1",
			[1] = "$units2",
			[2] = "$shadow",
			--[3] = "$specular",
			[4] = "$reflection",
		},
		SunChanged = SunChanged,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local cusUnitMaterials = GG.CUS[1].bufMaterials

local unitMaterials = {}

for id = 1, #UnitDefs do
	local udef = UnitDefs[id]
	if not cusUnitMaterials[id] and udef.modeltype == "3do" then
		unitMaterials[id] = {"units3doFallback"}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
