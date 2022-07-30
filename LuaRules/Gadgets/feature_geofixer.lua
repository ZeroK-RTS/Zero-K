if not gadgetHandler:IsSyncedCode() then
	return
end

function gadget:GetInfo()
	return {
		name      = "Geo fixer",
		desc      = "Fixes geothermals",
		author    = "Shaman",
		date      = "30 July, 2022",
		license   = "CC-0",
		layer     = -1000, -- low enough to catch any geo creation.
		enabled   = true,
	}
end

local geoDef = FeatureDefNames["geovent"].id
local geos = {}

function gadget:GameStart()
	if #geos > 0 then
		for i = 1, #geos do
			local featureID = geos[i]
			local x, _, z = Spring.GetFeaturePosition(featureID)
			local gy = Spring.GetGroundHeight(x, z)
			--Spring.Echo("[geofixer]: Setting up for " .. featureID)
			Spring.SetFeatureMoveCtrl(featureID, true)
			Spring.SetFeaturePosition(featureID, x, gy, z, true)
			Spring.SetFeatureMoveCtrl(featureID, false, 0, 1, 0, 0, 1, 0, 0, 1, 0) -- unlock y axis movement, so geo can move with terrain
		end
	end
	gadgetHandler:RemoveGadget()
end

function gadget:FeatureCreated(featureID, allyTeamID)
	local defID = Spring.GetFeatureDefID(featureID)
	--Spring.Echo("FeatureCreated: " .. FeatureDefs[defID].name)
	if defID == geoDef then -- this is a geo.
		geos[#geos + 1] = featureID
	end
end
