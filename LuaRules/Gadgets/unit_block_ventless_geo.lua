if not gadgetHandler:IsSyncedCode() then
	return false
end

function gadget:GetInfo()
	return {
		name    = "Block ventless geo",
		desc    = "Fixes an engine bug that lets you place geos anywhere",
		author  = "Sprung",
		date    = "2023-10-16",
		license = "Public Domain",
		layer   = 0,
		enabled = not Script.IsEngineMinVersion(105, 0, 2032),
	}
end

local geoSizes = {}
for i = 1, #UnitDefs do
	if UnitDefs[i].needGeo then
		local ud = UnitDefs[i]
		geoSizes[i] = math.max(ud.xsize, ud.zsize)*4 - 2
	end
end

local function IsNearGeo(unitDefID, x, z)
	local size = geoSizes[unitDefID] or 40
	local features = Spring.GetFeaturesInRectangle(x - size, z - size, x + size, z + size)
	for i = 1, #features do
		local fd = features[i] and Spring.GetFeatureDefID(features[i]) and FeatureDefs[Spring.GetFeatureDefID(features[i])]
		if fd and fd.geoThermal then
			return true
		end
	end
	return false
end

function gadget:AllowUnitCreation(unitDefID, builderID, builderTeam, x, y, z, facing)
	if not geoSizes[unitDefID] then
		return true
	end
	return IsNearGeo(unitDefID, x, z)
end
