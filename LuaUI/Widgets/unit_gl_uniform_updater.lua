function widget:GetInfo()
   return {
      name      = "Unit gl uniform updater",
      desc      = "Maintains sl unit and feature uniforms",
      author    = "Amnykon",
      date      = "Jan 2025",
      license   = "GNU GPL v2 or later",
      layer     = -100,
      enabled   = true
   }
end

local ceil = math.ceil

local updateCount = 0

-----------------------------------------------------------------
-- Units
-----------------------------------------------------------------

local GetVisibleUnits = Spring.GetVisibleUnits

function updateUnit()
end

function updateUnits()
end

-----------------------------------------------------------------
-- Features
-----------------------------------------------------------------

local GetVisibleFeatures   = Spring.GetVisibleFeatures
local GetFeatureDefID      = Spring.GetFeatureDefID
local GetFeatureHealth     = Spring.GetFeatureHealth
local GetFeaturePosition   = Spring.GetFeaturePosition
local GetFeatureResources  = Spring.GetFeatureResources
local glSetFeatureBufferUniforms = gl.SetFeatureBufferUniforms

local trackedFeatures = {}
for i = 1, #FeatureDefs do
	trackedFeatures[i] = FeatureDefs[i].destructable and FeatureDefs[i].drawTypeString == "model"
end

local features = {}

local featureUpdateRate = 200.0

local featureUniform = {0, 0, 0}
function updateFeature(featureID)
	local health, maxHealth, resurrect, reclaim
	health, maxHealth, resurrect = GetFeatureHealth(featureID)
	_, _, _, _, reclaim = GetFeatureResources(featureID)
	featureUniform[1] = (health or 0)/(maxHealth or 1)
	featureUniform[2] = resurrect
	featureUniform[3] = reclaim
	glSetFeatureBufferUniforms(featureID, featureUniform, 1)
end

function addFeature(featureID, defID)
	features[featureID] = defID
	updateFeature(featureID)

	for _, callback in pairs(WG.GlUnionUpdaterAddFeatureCallbacks) do
		callback(featureID)
	end
end

function removeFeature(featureID)
	features[featureID] = nil

	for _, callback in pairs(WG.GlUnionUpdaterRemoveFeatureCallbacks) do
		callback(featureID)
	end
end

function updateFeatures()
	local visibleFeatures = GetVisibleFeatures(-1, nil, false, false)
	local removedFeatures = {}

	local updatePercent = ceil(#visibleFeatures / featureUpdateRate)
	for featureID, _ in pairs(features) do
		removedFeatures[featureID] = true
	end

	local cnt = #visibleFeatures
	for i = cnt, 1, -1 do
		featureID = visibleFeatures[i]
		featureDefID = GetFeatureDefID(featureID) or -1
		if trackedFeatures[featureDefID] then
			if removedFeatures[featureID] then
				if (updateCount + featureID) % updatePercent == 0 then
					updateFeature(featureID)
				end
				removedFeatures[featureID] = nil
			else
				addFeature(featureID, featureDefID)
			end
		end
	end

	for featureID, val in pairs(removedFeatures) do
		if val ~= nil then
			removeFeature(featureID)
		end
	end
end

-----------------------------------------------------------------
-- Widget
-----------------------------------------------------------------

function widget:Update()
	updateCount = updateCount + 1
	updateUnits()
	updateFeatures()
end

function widget:Initialize()
	WG.GlUnionUpdaterAddFeatureCallbacks = WG.GlUnionUpdaterAddFeatureCallbacks or {}
	WG.GlUnionUpdaterRemoveFeatureCallbacks = WG.GlUnionUpdaterRemoveFeatureCallbacks or {}
end

function widget:Shutdown()
end
