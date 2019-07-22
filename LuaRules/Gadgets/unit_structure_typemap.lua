function gadget:GetInfo()
	return {
		name    = "Structure Typemap",
		desc    = "Sets structures to have unpathable terrain under them.",
		author  = "GoogleFrog",
		date    = "2 December 2018",
		license = "GNU LGPL, v2.1 or later",
		layer   = 0,
		enabled = false
	}
end

if not (gadgetHandler:IsSyncedCode()) then
	return
end

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

local spGetUnitDefID     = Spring.GetUnitDefID
local IMPASSIBLE_TERRAIN = 137 -- Hope that this does not conflict with any maps

local structureDefs = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if (ud.isImmobile or ud.speed == 0) and not ud.customParams.mobilebuilding then
		structureDefs[i] = {
			xsize = (ud.xsize)*4,
			zsize = (ud.ysize or ud.zsize)*4,
		}
	end
end

-------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUnitExtents(unitID, def)
	local ux,_,uz = Spring.GetUnitPosition(unitID, true)
	local face = Spring.GetUnitBuildFacing(unitID)
	local xsize = def.xsize
	local zsize = def.zsize
	local minx, minz, maxx, maxz
	if ((face == 0) or (face == 2)) then
		if xsize%16 == 0 then
			ux = math.floor((ux+8)/16)*16
		else
			ux = math.floor(ux/16)*16+8
		end
	if zsize%16 == 0 then
			uz = math.floor((uz+8)/16)*16
		else
			uz = math.floor(uz/16)*16+8
		end
		minx = ux - xsize
		minz = uz - zsize
		maxx = ux + xsize
		maxz = uz + zsize
	else
		if xsize%16 == 0 then
			uz = math.floor((uz+8)/16)*16
		else
			uz = math.floor(uz/16)*16+8
		end
		if zsize%16 == 0 then
			ux = math.floor((ux+8)/16)*16
		else
			ux = math.floor(ux/16)*16+8
		end
		minx = ux - zsize
		minz = uz - xsize
		maxx = ux + zsize
		maxz = uz + xsize
	end
	return minx - 8, minz - 8, maxx, maxz
end

local function SetTypemapSquare(minx, minz, maxx, maxz, value)
	for x = minx, maxx, 8 do
		for z = minz, maxz, 8 do
			Spring.SetMapSquareTerrainType(x, z, value)
		end
	end
end

-------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID)
	if not structureDefs[unitDefID] then
		return
	end

	local minx, minz, maxx, maxz = GetUnitExtents(unitID, structureDefs[unitDefID])
	SetTypemapSquare(minx, minz, maxx, maxz, IMPASSIBLE_TERRAIN)
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if not structureDefs[unitDefID] then
		return
	end

	local minx, minz, maxx, maxz = GetUnitExtents(unitID, ud)
	SetTypemapSquare(minx, minz, maxx, maxz, 0)
end

function gadget:Initialize()
	Spring.SetTerrainTypeData(IMPASSIBLE_TERRAIN, 0, 0, 0, 0)
	local allUnits = Spring.GetAllUnits()
	for i = 1, #allUnits do
		local unitID = allUnits[i]
		gadget:UnitCreated(unitID, spGetUnitDefID(unitID))
	end
end
