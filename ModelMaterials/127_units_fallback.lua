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
	unitsFallback = {
		shaderDefinitions = {
			"#define deferred_mode 0",
			"#define SHADOW_SOFTNESS SHADOW_SOFTER",
		},
		deferredDefinitions = {
			"#define deferred_mode 1",
			"#define SHADOW_SOFTNESS SHADOW_SOFTER",
			"#define MAT_IDX 1",
		},
		force     = true,
		usecamera = false,
		culling   = GL.BACK,
		texunits  = {
			[0] = "%%UNITDEFID:0",
			[1] = "%%UNITDEFID:1",
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
	if not cusUnitMaterials[id] then
		unitMaterials[id] = {"unitsFallback"}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



return materials, unitMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
