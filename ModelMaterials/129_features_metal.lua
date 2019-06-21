local matTemplate = VFS.Include("ModelMaterials/Templates/defaultMaterialTemplate.lua")


local metalWreckTreshold = 1
local function SetWreckMetalThreshold(mwt)
	metalWreckTreshold = mwt
end

local function Initialize()
	gadgetHandler:RegisterGlobal("SetWreckMetalThreshold", SetWreckMetalThreshold)
end

local function Finalize()
	gadgetHandler:DeregisterGlobal("SetWreckMetalThreshold")
end


local updateTime = true
local metalInfo = {}
local function DrawFeature(objectID, objectDefID, mat, drawMode, luaShaderObj)
	if drawMode ~= 5 and drawMode ~= 1 then
		return
	end

	if updateTime or not metalInfo[objectID] then
		metalInfo[objectID] = Spring.GetFeatureResources(objectID)
	end
	--Spring.Echo(FeatureDefs[objectDefID].name,  metalInfo[objectID])
	if luaShaderObj then

		local metalHere = metalInfo[objectID]
		metalHere = ((metalHere >= metalWreckTreshold) and metalHere) or 0.0

		luaShaderObj:SetUniformFloat("floatOptions", 0.0, 0.0, 0.0, metalHere)
	end
end

local gfUpd = -math.huge
local UPDATE_DELAY = 15  --two times per second
local function DrawGenesis(luaShader, mat)
	local highlightActive = mat.shaderOptions.metal_highlight or mat.deferredOptions.metal_highlight

	if highlightActive then
		local gf = Spring.GetGameFrame()
		updateTime = false
		if gf >= gfUpd then
			gfUpd = gfUpd + UPDATE_DELAY
			updateTime = true
		end

		if mat.DrawFeature then
			mat.DrawFeature = DrawFeature  --restore callin
		end
	else
		if not mat.DrawFeature then
			mat.DrawFeature = nil --remove callin
		end
	end
end

local materials = {
	featuresMetal = Spring.Utilities.MergeWithDefault(matTemplate, {
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
			materialIndex	= 129,
		},
		Initialize	= Initialize,
		Finalize	= Finalize,
		DrawGenesis	= DrawGenesis,
		DrawFeature	= DrawFeature, --mandatory, so api_cus can register "DrawFeature" callin for an objectID
	})
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local cusFeaturesMaterials = GG.CUS[2].bufMaterials
local featureMaterials = {}

for id = 1, #FeatureDefs do
	if not cusFeaturesMaterials[id] and FeatureDefs[id].metal >= 1 then
		featureMaterials[id] = {"featuresMetal"}
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
