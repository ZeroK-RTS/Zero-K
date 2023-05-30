--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Springboard Fixer",
		desc      = "Sets feature resources.",
		author    = "GoogleFrog",
		date      = "6 April 2020",
		license   = "GNU GPL, v2 or later",
		layer     = 1000000000,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--SYNCED
if (not gadgetHandler:IsSyncedCode()) then
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local abs = math.abs

local mapEnergyMult          = 0.1
local mapEnergyMultThreshold = 60
local energyDefaultBound     = 5
local energyDefault          = 25

local EMPTY_TABLE            = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local preloadFeatureCount = 0

local processedFeature = {}
local mapFeatureDefs = {}

for i = 1, #FeatureDefs do
	local fd = FeatureDefs[i]
	if fd.customParams and fd.customParams.is_tracked_map_feature then
		mapFeatureDefs[i] = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function FixFeature(featureID)
	local featureDefID = Spring.GetFeatureDefID(featureID)
	if not (featureDefID and mapFeatureDefs[featureDefID]) then
		return
	end
	
	if not processedFeature[featureDefID] then
		local fd = FeatureDefs[featureDefID]
		local defMetal, defEnergy, defReclaim = fd.metal, fd.energy, fd.reclaimTime
		local _, maxMetal, _, maxEnergy, _, reclaimTime = Spring.GetFeatureResources(featureID)
		reclaimTime = reclaimTime or defReclaim -- reclaimTime is not in older engines
		
		if abs(defMetal - maxMetal) > 1 or abs(defEnergy - maxEnergy) > 1 or abs(defReclaim - reclaimTime) > 1 then
			-- Try to make this match featuredefs_posts
			local metal = maxMetal or defMetal
			
			local energy = maxEnergy or defEnergy
			if energy > mapEnergyMultThreshold then
				energy = energy * mapEnergyMult
			elseif energy > 0 and energy < energyDefaultBound then
				energy = energyDefault
			end
			
			processedFeature[featureDefID] = {
				change = true,
				metal = metal,
				energy = energy ,
				reclaimTime = energy + metal,
			}
			--local def = processedFeature[featureDefID]
			--Spring.Echo("FeatureCreated", fd.name, def.metal, def.energy, def.reclaimTime)
		else
			processedFeature[featureDefID] = EMPTY_TABLE
		end
	end
	
	local def = processedFeature[featureDefID]
	if def and def.change then
		Spring.SetFeatureResources(featureID, def.metal, def.energy, def.reclaimTime, 1, def.metal, def.energy)
	end
end

function gadget:GamePreload()
	local features = Spring.GetAllFeatures()
	if GG.game_count_features_preload ~= #features then
		Spring.Echo("Running Springboard Feature Fixer", GG.game_count_features_preload, #features)
		for i = 1, #features do
			FixFeature(features[i])
		end
	end
	gadgetHandler:RemoveGadget()
end
