--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "NoGoZone Api",
		desc      = "API for NoGoZones!.",
		author    = "Pilfered from GoogleFrog by Stiofan",
		date      = "24 October 2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local floor = math.floor
local lava = (Game.waterDamage > 0)

local BUILD_RESOLUTION = 16
local STRUCTURE_SPACING = 128

local spGetGroundHeight = Spring.GetGroundHeight
local spTestBuildOrder = Spring.TestBuildOrder

local vector = Spring.Utilities.Vector

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local globalNoGoZones = nil --to added to and modified by other things
local mexGeoNoGoZones = nil --static to only mex and geos



local function InitialiseNoGoZones()
	local noGoZones = {count = 0, data = {}}

	local geoUnitDef = UnitDefNames["energygeo"]
	local features = Spring.GetAllFeatures()
	
	local sX = geoUnitDef.xsize*4
	local sZ = geoUnitDef.zsize*4
	local oddX = geoUnitDef.xsize % 4 == 2
	local oddZ = geoUnitDef.zsize % 4 == 2
	for i = 1, #features do
		local fID = features[i]
		if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
			local x, _, z = Spring.GetFeaturePosition(fID)
			if (oddX) then
				x = (floor( x / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
			else
				x = floor( x / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
			end
			if (oddZ) then
				z = (floor( z / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
			else
				z = floor( z / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
			end
			
			noGoZones.count = noGoZones.count + 1
			noGoZones.data[noGoZones.count] = {zl = z-sZ, zu = z+sZ, xl = x-sX, xu = x+sX}
		end
	end
	
	local mexUnitDef = UnitDefNames["staticmex"]
	local metalSpots = GG.metalSpots
	if metalSpots then
		local sX = mexUnitDef.xsize*4
		local sZ = mexUnitDef.zsize*4
		for i = 1, #metalSpots do
			local x = metalSpots[i].x
			local z = metalSpots[i].z
			noGoZones.count = noGoZones.count + 1
			noGoZones.data[noGoZones.count] = {zl = z-sZ, zu = z+sZ, xl = x-sX, xu = x+sX}
		end
	end
	--[[
	for i = 1, noGoZones.count do
		local d = noGoZones.data[i]
		--Spring.Echo("bla")
		Spring.MarkerAddPoint(d.xl,0,d.zl,"")
		Spring.MarkerAddPoint(d.xl,0,d.zu,"")
		Spring.MarkerAddPoint(d.xu,0,d.zl,"")
		Spring.MarkerAddPoint(d.xu,0,d.zu,"")
		Spring.MarkerAddLine(d.xl,0,d.zl,d.xu,0,d.zl)
		Spring.MarkerAddLine(d.xu,0,d.zl,d.xu,0,d.zu)
		Spring.MarkerAddLine(d.xu,0,d.zu,d.xl,0,d.zu)
		Spring.MarkerAddLine(d.xl,0,d.zu,d.xl,0,d.zl)
	end
	--]]
	mexGeoNoGoZones = noGoZones
	return noGoZones
end

local function AddNoGoZone(x, z, size, noGoZones)
	if not noGoZones then
		noGoZones = globalNoGoZones
		if not globalNoGoZones then
			noGoZones = InitialiseNoGoZones()
		end
	end
	noGoZones.count = noGoZones.count + 1
	noGoZones.data[noGoZones.count] = {zl = z - size, zu = z + size, xl = x - size, xu = x + size}
	return noGoZones
end

local function CheckOverlapWithNoGoZone(xl, zl, xu, zu, noGoZones) -- intersection check does not include boundry points
	if not noGoZones then
		noGoZones = globalNoGoZones
		if not globalNoGoZones then
			noGoZones = InitialiseNoGoZones()
		end
	end
	
	for i = 1, noGoZones.count do
		local d = noGoZones.data[i]
		if xl < d.xu and xu > d.xl and zl < d.zu and zu > d.zl then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local flattenAreas = false

local function FlattenFunc(left, top, right, bottom, height)
	-- top and bottom
	for x = left + 8, right - 8, 8 do
		Spring.SetHeightMap(x, top, height, 0.5)
		Spring.SetHeightMap(x, bottom, height, 0.5)
	end
	
	-- left and right
	for z = top + 8, bottom - 8, 8 do
		Spring.SetHeightMap(left, z, height, 0.5)
		Spring.SetHeightMap(right, z, height, 0.5)
	end
	
	-- corners
	Spring.SetHeightMap(left, top, height, 0.5)
	Spring.SetHeightMap(left, bottom, height, 0.5)
	Spring.SetHeightMap(right, top, height, 0.5)
	Spring.SetHeightMap(right, bottom, height, 0.5)
end

local function FlattenRectangle(left, top, right, bottom, height)
	Spring.LevelHeightMap(left + 8, top + 8, right - 8, bottom - 8, height)
	Spring.SetHeightMapFunc(FlattenFunc, left, top, right, bottom, height)
end

local function SetUnitAlwaysVisible (unitID)
	Spring.SetUnitAlwaysVisible(unitID, true)
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]
		Spring.SetUnitLosState(unitID, allyTeamID, 15)
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetRandomPosition(position, iteration)
	local point = vector.Add(position, vector.RandomPointInCircle(math.sqrt(iteration) * 75))
	return point[1], point[2]
end


local function ValidPosition(x, z, sX, sZ, minHeight, maxHeight, noGoZones,unitDefID,direction)
	if unitDefID and direction and spTestBuildOrder(unitDefID, x, 0 ,z, direction) == 0 then
		return false
	end
	local height = spGetGroundHeight(x, z)
	if (lava and height <= 0) or (minHeight and height < minHeight) or (maxHeight and height > maxHeight) then
		return false
	end
	if CheckOverlapWithNoGoZone(x - sX, z - sZ, x + sX, z + sZ, noGoZones) then
		return false
	end
	return true
end

-- minHeight and onward parameters are optional
local function IterateToValidPosition(x, z, sX, sZ, minHeight, maxHeight, allowFailure, noGoZones, unitDefID, direction)
	local initX,initZ = x,z
	local iteration = 0
	--Spring.MarkerAddPoint(x, 0, z, "START")
	while not ValidPosition(x, z, sX, sZ, minHeight, maxHeight, noGoZones,unitDefID, direction) do
		x, z = GetRandomPosition({initX,initZ}, iteration)
		--Spring.MarkerAddPoint(x, 0, z, "")
		iteration = iteration + 1
		if iteration > 300 then -- could be a variable, but it seems arbitrary
			if allowFailure then
				return initX,initZ,false
			end
			break
		end
	end
	return x,z,true
end



local function GetValidSpawnPositionForUnit(unitDefID, position, allowFailure, noGoZones)
	if not noGoZones then
		if not globalNoGoZones then
			globalNoGoZones = InitialiseNoGoZones()
		end
		noGoZones = globalNoGoZones
	end
	
	local minHeight = Spring.GetGameRulesParam("mex_min_height")
	if minHeight then
		if minHeight > 0 then
			minHeight = math.max(0, minHeight - 60)
		else
			minHeight = minHeight - 60
		end
	end
	
	local maxHeight = Spring.GetGameRulesParam("mex_max_height")
	if maxHeight then
		maxHeight = maxHeight + 150
	end
	
	local unitDef = UnitDefs[unitDefID]
	
	local x, z = position[1], position[2]
	local direction = math.floor(math.random()*4)
	
	local oddX = unitDef.xsize % 4 == 2
	local oddZ = unitDef.zsize % 4 == 2
	local sX = unitDef.xsize*4
	local sZ = unitDef.zsize*4
	
	if direction == 1 or direction == 3 then
		sX, sZ = sZ, sX
		oddX, oddZ = oddZ, oddX
	end
	local succededToPlace = false
	x,z,succededToPlace = IterateToValidPosition(x, z, sX, sZ, minHeight, maxHeight, allowFailure, noGoZones,unitDefID, direction)
	

	
	if oddX then
		x = (floor( x / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
	else
		x = floor( x / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
	end
	if oddZ then
		z = (floor( z / BUILD_RESOLUTION) + 0.5) * BUILD_RESOLUTION
	else
		z = floor( z / BUILD_RESOLUTION + 0.5) * BUILD_RESOLUTION
	end
	if not allowFailure and not succededToPlace then
		return x,z,direction,sX,sZ, false
	end
	return x,z,direction,sX,sZ, true
end

local function SpawnUnit(unitDefID, teamID, position, alwaysVisible, allowFailure, createAsWreck, noGoZones,dontAddToGlobal)
	if not noGoZones then
		if not globalNoGoZones then
			globalNoGoZones = InitialiseNoGoZones()
		end
		noGoZones = globalNoGoZones
	end
	
	local unitDef = UnitDefs[unitDefID]
	local x,z,direction,sX,sZ = GetValidSpawnPositionForUnit(unitDefID,position,allowFailure,noGoZones)
	if not x then
		return false
	end
	
	local y = spGetGroundHeight(x,z)
	if unitDef.speed and unitDef.speed ~= 0 then
		if (y > 0 or (not unitDef.floatOnWater)) then
			flattenAreas = flattenAreas or {}
			flattenAreas[#flattenAreas + 1] = {x-sX, z-sZ, x+sX, z+sZ, y}
		end
	else
		y = y + 20
	end
	if y < 0 and unitDef.floatOnWater then --assume this covers hovers and amphs too?
		y = 0
	end
	local returnID = nil
	local unitID = Spring.CreateUnit(unitDefID, x, y, z, direction, teamID, false, alwaysVisible)
	if not unitID then
		return false
	end 
	if createAsWreck then
		returnID = Spring.CreateUnitWreck(unitID)
		Spring.DestroyUnit(unitID,false,true)
	else
		returnID = unitID
	-- TODO unsure if this is available for features, so it goes here
		if alwaysVisible then
			SetUnitAlwaysVisible(unitID)
		end
	end
	
	--TODO check usages of this functions to flip this bool so we dont have double negatives?
	if not dontAddToGlobal then
		globalNoGoZones = AddNoGoZone(x, z, math.max(sX, sZ) + STRUCTURE_SPACING, globalNoGoZones)
	end
	noGoZones = AddNoGoZone(x, z, math.max(sX, sZ) + STRUCTURE_SPACING, noGoZones)
	return returnID, {x, z}
end

local function GetMexAndGeoNoGoZones()
	if not mexGeoNoGoZones then
		InitialiseNoGoZones()
	end
	return mexGeoNoGoZones
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--TODO for some reason I cant get the gadget table to allow a subcategory for unit spawner?
GG.NoGoZonesSetUnitAlwaysVisible = SetUnitAlwaysVisible --TODO this may be best elsewhere
GG.NoGoZonesIterateToValidPosition = IterateToValidPosition
GG.NoGoZonesCheckOverlapWithNoGoZone = CheckOverlapWithNoGoZone
GG.NoGoZonesAddNoGoZone = AddNoGoZone
GG.NoGoZonesGetValidSpawnPositionForUnit = GetValidSpawnPositionForUnit
GG.NoGoZonesGetMexAndGeoNoGoZones = GetMexAndGeoNoGoZones
GG.NoGoZonesSpawnUnit = SpawnUnit --TODO leftover from before

function gadget:GameFrame(frame)
	if flattenAreas then
		for i = 1, #flattenAreas do
			local rec = flattenAreas[i]
			FlattenRectangle(rec[1], rec[2], rec[3], rec[4], rec[5])
		end
		flattenAreas = nil
	end
end