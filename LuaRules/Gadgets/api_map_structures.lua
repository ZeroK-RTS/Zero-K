--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Map Structure API",
		desc      = "API for spawning structures on the map at the start of the game.",
		author    = "GoogleFrog",
		date      = "16 July 2023",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true
	}
end

if (not gadgetHandler:IsSyncedCode()) then
	return
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

local noGoZones = false

local function AddNoGoZone(x, z, size)
	noGoZones.count = noGoZones.count + 1
	noGoZones.data[noGoZones.count] = {zl = z - size, zu = z + size, xl = x - size, xu = x + size}
end

local function InitialiseNoGoZones()
	noGoZones = {count = 0, data = {}}

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
end

local function CheckOverlapWithNoGoZone(xl, zl, xu, zu) -- intersection check does not include boundry points
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetRandomPosition(position, iteration)
	local point = vector.Add(position, vector.RandomPointInCircle(math.sqrt(iteration) * 75))
	return point[1], point[2]
end

local function ValidPosition(unitDefID, x, z, sX, sZ, minHeight, maxHeight, direction)
	if spTestBuildOrder(unitDefID, x, 0 ,z, direction) == 0 then
		return false
	end
	local height = spGetGroundHeight(x, z)
	if (lava and height <= 0) or (minHeight and height < minHeight) or (maxHeight and height > maxHeight) then
		return false
	end
	if CheckOverlapWithNoGoZone(x - sX, z - sZ, x + sX, z + sZ) then
		return false
	end
	return true
end

local function SpawnPregameStructure(unitDefID, teamID, position, alwaysVisible)
	if not noGoZones then
		InitialiseNoGoZones()
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
	
	local iteration = 0
	while not ValidPosition(unitDefID, x, z, sX, sZ, minHeight, maxHeight, direction) do
		x, z = GetRandomPosition(position, iteration)
		--Spring.MarkerAddPoint(x, 0, z, "")
		iteration = iteration + 1
		if iteration > 300 then
			x, z = position[1], position[2]
			break
		end
	end
	
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
	
	local y = spGetGroundHeight(x,z)
	if (y > 0 or (not unitDef.floatOnWater)) then
		flattenAreas = flattenAreas or {}
		flattenAreas[#flattenAreas + 1] = {x-sX, z-sZ, x+sX, z+sZ, y}
	end
	
	local unitID = Spring.CreateUnit(unitDefID, x, y, z, direction, teamID, false, alwaysVisible)
	if alwaysVisible then
		Spring.SetUnitAlwaysVisible(unitID, true)
		local allyTeamList = Spring.GetAllyTeamList()
		for i = 1, #allyTeamList do
			local allyTeamID = allyTeamList[i]
			Spring.SetUnitLosState(unitID, allyTeamID, 15)
		end
	end
	AddNoGoZone(x, z, math.max(sX, sZ) + STRUCTURE_SPACING)
	return unitID
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

GG.SpawnPregameStructure = SpawnPregameStructure

function gadget:GameFrame(frame)
	if flattenAreas then
		for i = 1, #flattenAreas do
			local rec = flattenAreas[i]
			FlattenRectangle(rec[1], rec[2], rec[3], rec[4], rec[5])
		end
		flattenAreas = nil
	end
end
