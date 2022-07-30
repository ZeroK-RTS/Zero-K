if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name    = "Geo fixer",
		desc    = "Unlocks vertical movement for Springboard-placed geos",
		author  = "Shaman",
		date    = "30 July, 2022",
		license = "CC-0",
		layer   = 1000000000,
		enabled = true,
	}
end

local geos = {}
function gadget:GamePreload()
	local sp = Spring

	for i = 1, #geos do
		local featureID = geos[i]
		local x, _, z = sp.GetFeaturePosition(featureID)
		sp.SetFeatureMoveCtrl(featureID, true)
		sp.SetFeaturePosition(featureID, x, sp.GetGroundHeight(x, z), z, true)
		sp.SetFeatureMoveCtrl(featureID, false,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0)
	end

	gadgetHandler:RemoveGadget()
end

local FeatureDefs = FeatureDefs
local spGetFeatureDefID = Spring.GetFeatureDefID
function gadget:FeatureCreated(featureID)
	--[[ In theory non-geo features might also be locked, but that may be by mapper design.
	     At this point we can't yet unlock because the lock happens after creation. ]]
	if FeatureDefs[spGetFeatureDefID(featureID)].geoThermal then
		geos[#geos + 1] = featureID
	end
end
