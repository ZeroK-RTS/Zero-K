function widget:GetInfo()
   return {
      name      = "Unit status values",
      desc      = "Maintains unit status values for other widgets",
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

local featureUpdateRate = 200.0

local featureUniform = {0, 0, 0}
function updateFeature(featureID)
	local health, maxHealth, resurrect, reclaim
	health, maxHealth, resurrect = GetFeatureHealth(featureID)
	_, _, _, _, reclaim = GetFeatureResources(featureID)
	local hp = (health or 0)/(maxHealth or 1)
	WG.FeatureStatusValue.health[featureID] = hp
	WG.FeatureStatusValue.resurrect[featureID] = resurrect
	WG.FeatureStatusValue.reclaim[featureID] = reclaim
	featureUniform[1] = hp
	featureUniform[2] = resurrect
	featureUniform[3] = reclaim
	glSetFeatureBufferUniforms(featureID, featureUniform, 1)
end

function addFeature(featureID, defID)
	WG.FeatureStatusValue.defID[featureID] = defID
	local fx, fy, fz = GetFeaturePosition(featureID)
	WG.FeatureStatusValue.x[featureID] = x
	WG.FeatureStatusValue.y[featureID] = y
	WG.FeatureStatusValue.z[featureID] = z
	updateFeature(featureID)

	for _, callback in pairs(WG.FeatureStatusValueAddFeatureCallbacks) do
		callback(featureID)
	end
end

function removeFeature(featureID)
	WG.FeatureStatusValue.defID[featureID] = nil
	WG.FeatureStatusValue.health[featureID] = nil
	WG.FeatureStatusValue.resurrect[featureID] = nil
	WG.FeatureStatusValue.reclaim[featureID] = nil
	WG.FeatureStatusValue.x[featureID] = nil
	WG.FeatureStatusValue.y[featureID] = nil
	WG.FeatureStatusValue.z[featureID] = nil

	for _, callback in pairs(WG.FeatureStatusValueRemoveFeatureCallbacks) do
		callback(featureID)
	end
end

function updateFeatures()
	local visibleFeatures = GetVisibleFeatures(-1, nil, false, false)
	local removedFeatures = {}

	local updatePercent = ceil(#visibleFeatures / featureUpdateRate)
	for featureID, _ in pairs(WG.FeatureStatusValue.defID) do
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
					for _, callback in pairs(WG.FeatureStatusValueUpdateFeatureCallbacks) do
						callback(featureID)
					end
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
	WG.FeatureStatusValueUpdateFeatureCallbacks = WG.FeatureStatusValueUpdateFeatureCallbacks or {}
	WG.FeatureStatusValueAddFeatureCallbacks = WG.FeatureStatusValueAddFeatureCallbacks or {}
	WG.FeatureStatusValueRemoveFeatureCallbacks = WG.FeatureStatusValueRemoveFeatureCallbacks or {}
	WG.FeatureStatusValue = {
		defID = {},
		x = {},
		y = {},
		z = {},
		health = {},
		resurrect = {},
		reclaim = {}
	}
end

function widget:Shutdown()
	WG.FeatureStatusValue = nil
end
