local matTemplate = VFS.Include("ModelMaterials/Templates/defaultMaterialTemplate.lua")

local materials = {
	featuresFallback = Spring.Utilities.MergeWithDefault(matTemplate, {
		texunits  = {
			[0] = "%%FEATUREDEFID:0",
			[1] = "%%FEATUREDEFID:1",
			[2] = "$shadow",
			[4] = "$reflection",
		},
		feature = true,
		shaderOptions = {
			metal_highlight	= true,
		},
		deferredOptions = {
			materialIndex	= 128,
		},
	})
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local cusFeaturesMaterials = GG.CUS[2].bufMaterials
local featureMaterials = {}

for id = 1, #FeatureDefs do
	if not cusFeaturesMaterials[id] then
		featureMaterials[id] = {"featuresFallback"}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
