local matTemplate = VFS.Include("ModelMaterials/Templates/defaultMaterialTemplate.lua")

local metalWreckTreshold = 1
local function SetWreckMetalThreshold(mwt)
	metalWreckTreshold = mwt
end

local registered = false
local function Initialize(matName, matSrc)
	if not registered then
		gadgetHandler:RegisterGlobal("SetWreckMetalThreshold", SetWreckMetalThreshold)
		registered = true
	end
	if matSrc.ProcessOptions then
		matSrc.ProcessOptions(matSrc, "metal_highlight", {false})
	end
end

local unregistered = false
local function Finalize(matName, matSrc)
	if not unregistered then
		gadgetHandler:DeregisterGlobal("SetWreckMetalThreshold")
		unregistered = true
	end
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

	if luaShaderObj then
		local metalHere = metalInfo[objectID]
		metalHere = ((metalHere >= metalWreckTreshold) and metalHere) or 0.0

		luaShaderObj:SetUniformFloat("floatOptions", 0.0, 0.0, 0.0, metalHere)
	end
end

-- args=<objID, matName, lodMatNum, uniformName, uniformType, uniformData>
local frSetMaterialUniform = {
	[false] = Spring.FeatureRendering.SetForwardMaterialUniform,
	[true]  = Spring.FeatureRendering.SetDeferredMaterialUniform,
}

-- args=<objID, matName, lodMatNum, uniformName>
local frClearMaterialUniform = {
	[false] = Spring.FeatureRendering.ClearForwardMaterialUniform,
	[true]  = Spring.FeatureRendering.ClearDeferredMaterialUniform,
}

local GL_FLOAT_VEC4 = 0x8B52
local GL_FLOAT = 0x1406
local function GameFrameSlow(gf, mat, isDeferred)
	--Spring.Echo("GameFrameSlow", gf, matName, isDeferred)
	local highlightActive
	if isDeferred then
		highlightActive = mat.deferredOptions.metal_highlight
	else
		highlightActive = mat.shaderOptions.metal_highlight
	end

	if highlightActive then
		local fs = Spring.GetAllFeatures()
		--local fs = Spring.GetVisibleFeatures(-1, 30, false)
		for _, fID in ipairs(fs) do
			local metalHere = Spring.GetFeatureResources(fID)
			metalHere = ((metalHere >= metalWreckTreshold) and metalHere) or 0.0
			--Spring.Echo("GameFrameSlow", fID, metalHere)
			frSetMaterialUniform[isDeferred](fID, "opaque", 3, "floatOptions[1]", GL_FLOAT, {metalHere})
			--frSetMaterialUniform[isDeferred](fID, "opaque", 3, "floatOptions", GL_FLOAT_VEC4, {0.0, 0.0, 0.0, metalHere})
		end
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local featureTreeTemplate = Spring.Utilities.MergeWithDefault(matTemplate, {
	texUnits  = {
		[0] = "%%FEATUREDEFID:0",
		[1] = "%%FEATUREDEFID:1",
	},
	feature = true,
	shaderOptions = {
		treewind = true,
	},
	deferredOptions = {
		treewind = true,
	},
})

local materials = {
	featuresTreeMetalFakeNormal = Spring.Utilities.MergeWithDefault(featureTreeTemplate, {
		texUnits  = {
			[5] = "%NORMALTEX",
		},
		shaderOptions = {
			normalmapping = true,
			metal_highlight	= true,
		},
		deferredOptions = {
			normalmapping = true,
			--metal_highlight	= true,
			materialIndex = 128,
		},
		Initialize	= Initialize,
		Finalize	= Finalize,
		--DrawGenesis	= DrawGenesis,
		GameFrameSlow = GameFrameSlow,
		--DrawFeature	= DrawFeature, --mandatory, so api_cus can register "DrawFeature" callin for an objectID
	}),

	featuresTreeMetalNoNormal = Spring.Utilities.MergeWithDefault(featureTreeTemplate, {
		shaderOptions = {
			metal_highlight	= true,
		},
		deferredOptions = {
			--metal_highlight	= true,
			materialIndex = 129,
		},
		Initialize	= Initialize,
		Finalize	= Finalize,
		--DrawGenesis	= DrawGenesis,
		GameFrameSlow = GameFrameSlow,
		--DrawFeature	= DrawFeature, --mandatory, so api_cus can register "DrawFeature" callin for an objectID
	}),

	featuresTreeNoMetalFakeNormal = Spring.Utilities.MergeWithDefault(featureTreeTemplate, {
		texUnits  = {
			[5] = "%NORMALTEX",
		},
		shaderOptions = {
			normalmapping = true,
		},
		deferredOptions = {
			normalmapping = true,
			materialIndex = 130,
		},
	}),

	featuresTreeNoMetalNoNormal = Spring.Utilities.MergeWithDefault(featureTreeTemplate, {
		deferredOptions = {
			materialIndex = 131,
		},
	}),

	featuresMetal = Spring.Utilities.MergeWithDefault(matTemplate, {
		texUnits  = {
			[0] = "%%FEATUREDEFID:0",
			[1] = "%%FEATUREDEFID:1",
		},
		feature = true,
		shaderOptions = {
			metal_highlight	= true,
		},
		deferredOptions = {
			--metal_highlight	= true,
			materialIndex = 132,
		},
		Initialize	= Initialize,
		Finalize	= Finalize,
		--DrawGenesis	= DrawGenesis,
		GameFrameSlow = GameFrameSlow,
		--DrawFeature	= DrawFeature, --mandatory, so api_cus can register "DrawFeature" callin for an objectID
	}),

}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local featureNameTrees = {
	-- all of the 0ad, beherith and artturi features start with these.
	{str = "ad0_", prefix = true, fakeNormal = true},
	{str = "art", prefix = true, fakeNormal = true},

	-- from BAR
	{str = "bush", prefix = true, fakeNormal = true},
	{str = "vegetation", prefix = true, fakeNormal = true},
	{str = "vegitation", prefix = true, fakeNormal = true},
	{str = "baobab", prefix = true, fakeNormal = true},
	{str = "aleppo", prefix = true, fakeNormal = true},
	{str = "pine", prefix = true, fakeNormal = true},
	{str = "senegal", prefix = true, fakeNormal = true},
	{str = "palm", prefix = true, fakeNormal = true},
	{str = "shrub", prefix = true, fakeNormal = true},
	{str = "bloodthorn", prefix = true, fakeNormal = true},
	{str = "birch", prefix = true, fakeNormal = true},
	{str = "maple", prefix = true, fakeNormal = true},
	{str = "oak", prefix = true, fakeNormal = true},
	{str = "fern", prefix = true, fakeNormal = true},
	{str = "grass", prefix = true, fakeNormal = true},
	{str = "weed", prefix = true, fakeNormal = true},
	{str = "plant", prefix = true, fakeNormal = true},
	{str = "palmetto", prefix = true, fakeNormal = true},
	{str = "lowpoly_tree", prefix = true, fakeNormal = true},

	{str = "treetype", prefix = true, fakeNormal = true}, --engine trees

	{str = "btree", prefix = true, fakeNormal = false},	--beherith trees don't gain from fake normal

	-- Other trees will probably contain "tree" as a substring.
	{str = "tree", prefix = false, fakeNormal = true},
}


local featureNameTreeExceptions = {
	"street",
}

local FAKE_NORMALTEX = "UnitTextures/default_tree_normals.dds"
FAKE_NORMALTEX = VFS.FileExists(FAKE_NORMALTEX) and FAKE_NORMALTEX or nil
local function GetTreeInfo(fdef)
	if not fdef or not fdef.name then
		return false, false
	end

	local isTree = false
	local fakeNormal = false

	for _, treeInfo in ipairs(featureNameTrees) do
		local idx = fdef.name:find(treeInfo.str)
		if idx and ((treeInfo.prefix and idx == 1) or (not treeInfo.prefix)) then

			local isException = false
			for _, exc in ipairs(featureNameTreeExceptions) do
				isException = isException or fdef.name:find(exc) ~= nil
			end

			if not isException then
				isTree = true
				fakeNormal = FAKE_NORMALTEX and treeInfo.fakeNormal
			end
		end
	end

	return isTree, fakeNormal
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------




--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local cusFeaturesMaterials = GG.CUS.featureMaterialDefs
local featureMaterials = {}

for id = 1, #FeatureDefs do
	local fdef = FeatureDefs[id]
	if not cusFeaturesMaterials[id] and fdef.modeltype ~= "3do" then
		local isTree, fakeNormal = GetTreeInfo(fdef)
		local metallic = fdef.metal >= 1

		if isTree then
			if fakeNormal then
				if metallic then
					featureMaterials[id] = {"featuresTreeMetalFakeNormal", NORMALTEX = FAKE_NORMALTEX}
				else
					featureMaterials[id] = {"featuresTreeNoMetalFakeNormal", NORMALTEX = FAKE_NORMALTEX}
				end
			else
				if metallic then
					featureMaterials[id] = {"featuresTreeMetalNoNormal"}
				else
					featureMaterials[id] = {"featuresTreeNoMetalNoNormal"}
				end
			end
		elseif metallic then
			featureMaterials[id] = {"featuresMetal"}
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return materials, featureMaterials

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
