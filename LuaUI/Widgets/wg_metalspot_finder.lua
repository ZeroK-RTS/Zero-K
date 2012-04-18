
function widget:GetInfo()
	return {
		name      = "Metalspot Finder",
		desc      = "Finds metal spots for other widgets",
		author    = "Niobium",
		version   = "v1.1",
		date      = "November 2010",
		license   = "GNU GPL, v2 or later",
		layer     = -30000,
		enabled   = true
	}
end

------------------------------------------------------------
-- Config
------------------------------------------------------------
local gridSize = 16 -- Resolution of metal map
local buildGridSize = 8 -- Resolution of build positions

local MEX_OWNER_SHARE = 0.05
local METAL_MAP_SQUARE_SIZE = 16
local MEX_RADIUS = Game.extractorRadius
local MAP_SIZE_X = Game.mapSizeX
local MAP_SIZE_X_SCALED = MAP_SIZE_X / METAL_MAP_SQUARE_SIZE
local MAP_SIZE_Z = Game.mapSizeZ
local MAP_SIZE_Z_SCALED = MAP_SIZE_Z / METAL_MAP_SQUARE_SIZE

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local min, max = math.min, math.max
local floor, ceil = math.floor, math.ceil
local sqrt = math.sqrt
local huge = math.huge

local spGetGroundInfo = Spring.GetGroundInfo
local spGetGroundHeight = Spring.GetGroundHeight
local spTestBuildOrder = Spring.TestBuildOrder

local extractorRadius = Game.extractorRadius
local extractorRadiusSqr = extractorRadius * extractorRadius
 
local buildmapSizeX = Game.mapSizeX - buildGridSize
local buildmapSizeZ = Game.mapSizeZ - buildGridSize
local buildmapStartX = buildGridSize
local buildmapStartZ = buildGridSize

local metalmapSizeX = Game.mapSizeX - 1.5 * gridSize
local metalmapSizeZ = Game.mapSizeZ - 1.5 * gridSize
local metalmapStartX = 1.5 * gridSize
local metalmapStartZ = 1.5 * gridSize

------------------------------------------------------------
-- Variables
------------------------------------------------------------

local mexDefInfos = {}
local defaultDefID = 0

------------------------------------------------------------
-- Callins
------------------------------------------------------------
function widget:Initialize()
	WG.metalSpots = GetSpots()
	WG.GetMexPositions = GetMexPositions
	WG.IsMexPositionValid = IsMexPositionValid
	widgetHandler:RemoveWidget(self)
end

------------------------------------------------------------
-- Shared functions
------------------------------------------------------------
function GetMexPositions(spot, uDefID, facing, testBuild)
	
	local positions = {}
	
	local xoff, zoff
	local uDef = UnitDefs[uDefID]
	if facing == 0 or facing == 2 then
		xoff = (4 * uDef.xsize) % 16
		zoff = (4 * uDef.zsize) % 16
	else
		xoff = (4 * uDef.zsize) % 16
		zoff = (4 * uDef.xsize) % 16
	end
	
	if not spot.validLeft then
		GetValidStrips(spot)
	end
	
	local validLeft = spot.validLeft
	local validRight = spot.validRight
	for z, vLeft in pairs(validLeft) do
		if z % 16 == zoff then
			for x = gridSize *  ceil((vLeft         + xoff) / gridSize) - xoff,
					gridSize * floor((validRight[z] + xoff) / gridSize) - xoff,
					gridSize do
				local y = spGetGroundHeight(x, z)
				if not (testBuild and spTestBuildOrder(uDefID, x, y, z, facing) == 0) then
					positions[#positions + 1] = {x, y, z}
				end
			end
		end
	end
	
	return positions
end

function IsMexPositionValid(spot, x, z)
	
	if z <= spot.maxZ - extractorRadius or
	   z >= spot.minZ + extractorRadius then -- Test for metal being included is dist < extractorRadius
		return false
	end
	
	local sLeft, sRight = spot.left, spot.right
	for sz = spot.minZ, spot.maxZ, gridSize do
		local dz = sz - z
		local maxXOffset = sqrt(extractorRadiusSqr - dz * dz) -- Test for metal being included is dist < extractorRadius
		if x <= sRight[sz] - maxXOffset or
		   x >= sLeft[sz] + maxXOffset then
			return false
		end
	end
	
	return true
end

------------------------------------------------------------
-- Extractor Income Processing
------------------------------------------------------------

local function SetupMexDefInfos() 
	local minExtractsMetal
	
	local armMexDef = UnitDefNames["armmex"]
	
	if armMexDef and armMexDef.extractsMetal > 0 then
		defaultDefID = UnitDefNames["armmex"].id
		minExtractsMetal = 0
	end
	
	for unitDefID = 1,#UnitDefs do
		local unitDef = UnitDefs[unitDefID]
		local extractsMetal = unitDef.extractsMetal
		if (extractsMetal > 0) then
			mexDefInfos[unitDefID] = {}
			mexDefInfos[unitDefID][1] = extractsMetal
			mexDefInfos[unitDefID][2] = unitDef.extractSquare
			if (unitDef.xsize % 4 == 2) then
				mexDefInfos[unitDefID][3] = true
			end
			if (unitDef.zsize % 4 == 2) then
				mexDefInfos[unitDefID][4] = true
			end
			if not minExtractsMetal or extractsMetal < minExtractsMetal then
				defaultDefID = unitDefID
				minExtractsMetal = extractsMetal
			end
		end
	end
	
end


local function IntegrateMetal(x, z)
	local centerX, centerZ
	
	local mexDefInfo = mexDefInfos[defaultDefID]
	
	if (mexDefInfo[3]) then
		centerX = (floor( x / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		centerX = floor( x / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end
	
	if (mexDefInfo[4]) then
		centerZ = (floor( z / METAL_MAP_SQUARE_SIZE) + 0.5) * METAL_MAP_SQUARE_SIZE
	else
		centerZ = floor( z / METAL_MAP_SQUARE_SIZE + 0.5) * METAL_MAP_SQUARE_SIZE
	end
	
	
	local startX = floor((centerX - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local startZ = floor((centerZ - MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endX = floor((centerX + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	local endZ = floor((centerZ + MEX_RADIUS) / METAL_MAP_SQUARE_SIZE)
	startX, startZ = max(startX, 0), max(startZ, 0)
	endX, endZ = min(endX, MAP_SIZE_X_SCALED - 1), min(endZ, MAP_SIZE_Z_SCALED - 1)
	
	local mult = mexDefInfo[1] / MEX_OWNER_SHARE -- multiplied to show correct value due to overdrive system which sets extraction to 5%
	local square = mexDefInfo[2]
	local result = 0
	
	if (square) then
		for i = startX, endX do
			for j = startZ, endZ do
				local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
				local _, metal = spGetGroundInfo(cx, cz)
				result = result + metal
			end
		end
	else
		for i = startX, endX do
			for j = startZ, endZ do
				local cx, cz = (i + 0.5) * METAL_MAP_SQUARE_SIZE, (j + 0.5) * METAL_MAP_SQUARE_SIZE
				local dx, dz = cx - centerX, cz - centerZ
				local dist = sqrt(dx * dx + dz * dz)
				
				if (dist < MEX_RADIUS) then
					local _, metal = spGetGroundInfo(cx, cz)
					result = result + metal
				end
			end
		end
	end
	
	return result * mult, centerX, centerZ
end

------------------------------------------------------------
-- Mex finding
------------------------------------------------------------
function GetSpots()
	
	SetupMexDefInfos() 
	
	-- Main group collection
	local uniqueGroups = {}
	
	-- Strip info
	local nStrips = 0
	local stripLeft = {}
	local stripRight = {}
	local stripGroup = {}
	
	-- Indexes
	local aboveIdx
	local workingIdx
	
	-- Strip processing function (To avoid some code duplication)
	local function DoStrip(x1, x2, z, worth)
		
		local assignedTo
		
		for i = aboveIdx, workingIdx - 1 do
			if stripLeft[i] > x2 + gridSize then
				break
			elseif stripRight[i] + gridSize >= x1 then
				local matchGroup = stripGroup[i]
				if assignedTo then
					if matchGroup ~= assignedTo then
						for iz = matchGroup.minZ, assignedTo.minZ - gridSize, gridSize do
							assignedTo.left[iz] = matchGroup.left[iz]
						end
						for iz = matchGroup.minZ, matchGroup.maxZ, gridSize do
							assignedTo.right[iz] = matchGroup.right[iz]
						end
						if matchGroup.minZ < assignedTo.minZ then
							assignedTo.minZ = matchGroup.minZ
						end
						assignedTo.maxZ = z
						assignedTo.worth = assignedTo.worth + matchGroup.worth
						uniqueGroups[matchGroup] = nil
					end
				else
					assignedTo = matchGroup
					assignedTo.left[z] = assignedTo.left[z] or x1 -- Only accept the first
					assignedTo.right[z] = x2 -- Repeated overwrite gives us result we want
					assignedTo.maxZ = z -- Repeated overwrite gives us result we want
					assignedTo.worth = assignedTo.worth + worth
				end
			else
				aboveIdx = aboveIdx + 1
			end
		end
		
		nStrips = nStrips + 1
		stripLeft[nStrips] = x1
		stripRight[nStrips] = x2
		
		if assignedTo then
			stripGroup[nStrips] = assignedTo
		else
			local newGroup = {
					left = {[z] = x1},
					right = {[z] = x2},
					minZ = z,
					maxZ = z,
					worth = worth
				}
			stripGroup[nStrips] = newGroup
			uniqueGroups[newGroup] = true
		end
	end
	
	-- Strip finding
	workingIdx = huge
	for mz = metalmapStartX, metalmapSizeZ, gridSize do
		
		aboveIdx = workingIdx
		workingIdx = nStrips + 1
		
		local stripStart = nil
		local stripWorth = 0
		
		for mx = metalmapStartZ, metalmapSizeX, gridSize do
			local _, groundMetal = spGetGroundInfo(mx, mz)
			if groundMetal > 0 then
				stripStart = stripStart or mx
				stripWorth = stripWorth + groundMetal
			elseif stripStart then
				DoStrip(stripStart, mx - gridSize, mz, stripWorth)
				stripStart = nil
				stripWorth = 0
			end
		end
		
		if stripStart then
			DoStrip(stripStart, metalmapSizeX, mz, stripWorth)
		end
	end
	
	-- Final processing
	local spots = {}
	for g, _ in pairs(uniqueGroups) do
		
		local gMinX, gMaxX = huge, -1
		local gLeft, gRight = g.left, g.right
		for iz = g.minZ, g.maxZ, gridSize do
			if gLeft[iz] < gMinX then gMinX = gLeft[iz] end
			if gRight[iz] > gMaxX then gMaxX = gRight[iz] end
		end
		g.minX = gMinX
		g.maxX = gMaxX
		
		g.x = (gMinX + gMaxX) * 0.5
		g.z = (g.minZ + g.maxZ) * 0.5
		
		g.metal = IntegrateMetal(g.x,g.z)
		
		g.y = spGetGroundHeight(g.x, g.z)
		
		local merged = false
		
		for i = 1, #spots do
			local spot = spots[i]
			local dis = (g.x - spot.x)^2 + (g.z - spot.z)^2
			if dis < extractorRadiusSqr*4 then
				local mx = (g.x + spot.x) * 0.5
				local mz = (g.z + spot.z) * 0.5
				local metal = IntegrateMetal(mx,mz)
				
				if dis < extractorRadiusSqr*2 or metal > (g.metal + spot.metal)*0.95 then
					spot.x = mx
					spot.y = spGetGroundHeight(mx, mx)
					spot.z = mz
					spot.metal = metal
					merged = true
					break
				end
			end
		end
		
		if not merged then
			spots[#spots + 1] = g
		end
	end
	
	--for i = 1, #spots do
	--	Spring.MarkerAddPoint(spots[i].x,spots[i].y,spots[i].z,"")
	--end
	
	return spots
end

function GetValidStrips(spot)
	
	local sMinZ, sMaxZ = spot.minZ, spot.maxZ
	local sLeft, sRight = spot.left, spot.right
	
	local validLeft = {}
	local validRight = {}
	
	local maxZOffset = buildGridSize * ceil(extractorRadius / buildGridSize - 1)
	for mz = max(sMaxZ - maxZOffset, buildmapStartZ), min(sMinZ + maxZOffset, buildmapSizeZ), buildGridSize do
		local vLeft, vRight = buildmapStartX, buildmapSizeX
		for sz = sMinZ, sMaxZ, gridSize do
			local dz = sz - mz
			local maxXOffset = buildGridSize * ceil(sqrt(extractorRadiusSqr - dz * dz) / buildGridSize - 1) -- Test for metal being included is dist < extractorRadius
			local left, right = sRight[sz] - maxXOffset, sLeft[sz] + maxXOffset
			if left  > vLeft  then vLeft  = left  end
			if right < vRight then vRight = right end
		end
		validLeft[mz] = vLeft
		validRight[mz] = vRight
	end
	
	spot.validLeft = validLeft
	spot.validRight = validRight
end
