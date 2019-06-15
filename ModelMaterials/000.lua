local matTemplate = VFS.Include("ModelMaterials/Templates/defaultMaterialTemplate.lua")

local materials = {
	unitsFallback = Spring.Utilities.MergeWithDefault(matTemplate, {
		texunits  = {
			[0] = "%%UNITDEFID:0",
			[1] = "%%UNITDEFID:1",
			[2] = "$shadow",
			[4] = "$reflection",
		},
	})
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
