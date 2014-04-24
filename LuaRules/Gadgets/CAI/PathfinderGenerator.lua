---------------------------------------------------------------
-- Configuration and Localization
---------------------------------------------------------------

local ceil = math.ceil
local floor = math.floor
local max = math.max
local min = math.min
local sqrt = math.sqrt
local abs = math.abs

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ

local PATH_SQUARE_SIZE = 256 -- Matches low resolution spring pathfinder size
local PATH_MID = PATH_SQUARE_SIZE/2
local PATH_X = ceil(MAP_WIDTH/PATH_SQUARE_SIZE) - 1
local PATH_Z = ceil(MAP_HEIGHT/PATH_SQUARE_SIZE) - 1

local PathfinderGenerator = {
	PATH_SQUARE_SIZE = PATH_SQUARE_SIZE,
	PATH_X = PATH_X,
	PATH_Z = PATH_Z,
}

---------------------------------------------------------------
-- Helper functions 
---------------------------------------------------------------
local CoordToIDarray = {}
local IdToCoordarray = {}

for i = 0, PATH_X do
	CoordToIDarray[i] = {}
	for j = 0, PATH_Z do
		IdToCoordarray[#IdToCoordarray+1] = {x = i, z = j}
		CoordToIDarray[i][j] = #IdToCoordarray
	end
end

local function IdToCoords(id)
	return IdToCoordarray[id].x, IdToCoordarray[id].z
end

local function CoordsToID(x, z)
	return CoordToIDarray[x][z]
end

local function DisSQ(x1,z1,x2,z2)
	return (x1 - x2)^2 + (z1 - z2)^2
end

local function WorldToArray(x,z)
	local i,j
	if x < 0 then
		i = 0
	elseif x >= MAP_WIDTH then
		i = PATH_X
	else
		i = floor(x/PATH_SQUARE_SIZE)
	end
	if z < 0 then
		j = 0
	elseif z >= MAP_HEIGHT then
		j = PATH_Z
	else
		j = floor(z/PATH_SQUARE_SIZE)
	end
	return i, j
end

local function ArrayToWorld(i,j) -- gets midpoint
	return i*PATH_SQUARE_SIZE + PATH_MID, j*PATH_SQUARE_SIZE + PATH_MID
end

---------------------------------------------------------------
-- astar overrides
---------------------------------------------------------------
local function astarOverride_GetDistanceEstimate(id1, id2)
	local x1,z1 = IdToCoords(id1)
	local x2,z2 = IdToCoords(id2)
	return sqrt((x1 - x2)^2 + (z1 - z2)^2)
end

---------------------------------------------------------------
-- PathMap creation
---------------------------------------------------------------

-- Points to check around the middle of a path point for the creation of a valid point.
local checkPoints = {
	{x = 0, z = 0},
	{x = 64, z = 0},
	{x = 0, z = 64},
	{x = -64, z = 0},
	{x = 0, z = -64},
	{x = 64, z = 64},
	{x = -64, z = -64},
	{x = -64, z = 64},
	{x = 64, z = -64},
	{x = 100, z = 0},
	{x = 0, z = 100},
	{x = -100, z = 0},
	{x = 0, z = -100},
	{x = 100, z = 100},
	{x = -100, z = -100},
	{x = -100, z = 100},
	{x = 100, z = -100},
}

-- Functions for modifying and checking links.
local function AddLink(point, relation, cost)
	point.linkCount = point.linkCount + 1
	point.linkList[point.linkCount] = {x = point.x + relation[1], z = point.z + relation[2], cost = cost}
	--if relation[1] == 0 then
	--	relation[1] = 0
	--end
	--if relation[2] == 0 then
	--	relation[2] = 0
	--end
	
	if not point.linkRelationMap[relation[1]] then
		point.linkRelationMap[relation[1]] = {}
	end
	point.linkRelationMap[relation[1]][relation[2]] = point.linkCount
end

local function UpdatePathLink(start, finish, relation, moveDef)
	if moveDef then
		if start.passable and finish.passable then
			local sx = start.px
			local sz = start.pz
			local fx = finish.px
			local fz = finish.pz
			local myPath = Spring.RequestPath(moveDef, sx, 0, sz, fx, 0, fz, 16)
			if myPath then
				local waypoints, estimate = myPath:GetPathWayPoints()
				local endX = waypoints[#waypoints][1]
				local endZ = waypoints[#waypoints][3]
				if #waypoints <= 25 and DisSQ(endX, endZ, fx, fz) < 256 then
					AddLink(start, relation, #waypoints)
					AddLink(finish, {-relation[1], -relation[2]}, #waypoints)
				end
				--if DisSQ(endX, endZ, fx, fz) > 256 then
				--	Spring.MarkerAddPoint(fx, 0, fz, sqrt(DisSQ(endX, endZ, fx, fz)))
				--	for i = 1, #waypoints do
				--		local w = waypoints[i]
				--		Spring.MarkerAddPoint(w[1], w[2], w[3], i)
				--	end
				--end
			end
		end
	else
		AddLink(start, relation, 1)
		AddLink(finish, {-relation[1], -relation[2]}, 1)
	end
end

local function CreatePathMap(pathUnitDefID, pathMoveDefName)
	-- pathUnitDefID is an example unitDef to use to check for valid location
	-- pathMoveDefName is the name of the movedef used for the path
	
	local pathMap = {}
	
	-- Create the positions of the path map which will be used for connection testing.
	for i = 0, PATH_X do
		pathMap[i] = {}
		for j = 0, PATH_Z do
			
			pathMap[i][j] = {
				x = i,
				z = j,
				mx = PATH_MID + i*PATH_SQUARE_SIZE, 
				mz = PATH_MID + j*PATH_SQUARE_SIZE,
				linkList = {},
				linkCount = 0,
				linkRelationMap = {}
			}
			
			local point = 1
			local px = checkPoints[point].x + PATH_MID + i*PATH_SQUARE_SIZE
			local pz = checkPoints[point].z + PATH_MID + j*PATH_SQUARE_SIZE
			while point < #checkPoints and pathUnitDefID and not Spring.TestMoveOrder(pathUnitDefID, px/2, 0, pz/2) do
				point = point + 1
				px = checkPoints[point].x + PATH_MID + i*PATH_SQUARE_SIZE
				pz = checkPoints[point].z + PATH_MID + j*PATH_SQUARE_SIZE	
				--Spring.MarkerAddPoint(px,0,pz, "")
			end
			
			if point < #checkPoints then
				pathMap[i][j].px = px
				pathMap[i][j].py = Spring.GetGroundHeight(px, pz)
				pathMap[i][j].pz = pz
				pathMap[i][j].passable = true
			else
				pathMap[i][j].passable = false
			end
		end
	end
	
	-- Check links between points, this only checks orthagonal but could easily change.
	for i = 0, PATH_X do
		for j = 0, PATH_Z do
			if i < PATH_X then
				UpdatePathLink(pathMap[i][j], pathMap[i+1][j], {1,0}, pathMoveDefName)
			end
			if j < PATH_Z then
				UpdatePathLink(pathMap[i][j], pathMap[i][j+1], {0,1}, pathMoveDefName)
			end
		end
	end
	
	--for i = 0, PATH_X do
	--	for j = 0, PATH_Z do
	--		if pathMap[i][j].passable then
	--			local str = ""
	--			local linkList = pathMap[i][j].linkList
	--			for id = 1, pathMap[i][j].linkCount do
	--				str = str .. "(" .. linkList[id].x .. ", " .. linkList[id].z .. ") "
	--			end
	--			Spring.MarkerAddPoint(pathMap[i][j].px,0,pathMap[i][j].pz,str)
	--		end
	--	end
	--end
	
	return pathMap
end

---------------------------------------------------------------
-- Pathfinder object definition
---------------------------------------------------------------

function PathfinderGenerator.CreatePathfinder(pathUnitDefID, pathMoveDefName)
	
	local aStar = VFS.Include("LuaRules/Gadgets/CAI/astar.lua")

	local heatmapFear = false
	local heatFearFactor = false
	
	local defenseHeatmaps = {}
	local defenseHeatmapCount = 0
	local pathMap = CreatePathMap(pathUnitDefID, pathMoveDefName)
	
	-- Heatmap functions
	function SetDefenseHeatmaps(newDefenseHeatmaps)
		defenseHeatmaps = newDefenseHeatmaps
		defenseHeatmapCount = #newDefenseHeatmaps
	end
	
	local function IsPositionHeatmapFeared(x,z)
		if heatmapFear then
			for i = 1, defenseHeatmapCount do
				local heatValue = defenseHeatmaps[i].GetValueByIndex(x, z)
				if heatValue >= heatmapFear then
					return true
				end
			end
		end
		return false
	end
	
	local function GetHeatmapFearSum(x,z)
		local sum = 0
		if heatmapFear then
			for i = 1, defenseHeatmapCount do
				local heatValue = defenseHeatmaps[i].GetValueByIndex(x, z)
				sum = sum + heatValue
			end
		end
		return false
	end
	
	-- aStar overrides
	function aStar.GetNeighbors(id)
		local x, z = IdToCoords(id)
		local posData = pathMap[x][z]
		
		local passable = {}
		local passableCount = 0
		for i = 1, posData.linkCount do
			local linkData = posData.linkList[i]
			local nx, nz = linkData.x, linkData.z
			if not IsPositionHeatmapFeared(nx, nz) then
				passableCount = passableCount + 1
				passable[passableCount] = CoordsToID(nx, nz)
			end
		end
		return passable
	end

	aStar.GetDistanceEstimate = astarOverride_GetDistanceEstimate
	
	function aStar.GetDistance(id1, id2)
		if heatFearFactor then
			local x1, z1 = IdToCoords(id1)
			local x2, z2 = IdToCoords(id2)
			return 1 + (GetHeatmapFearSum(x1, z1) + GetHeatmapFearSum(x2, z2))*newHeatFearFactor
		else
			return 1
		end
	end
	
	-- 
	function GetPath(startX, startZ, finishX, finishZ, newHeatmapFear, newHeatFearFactor)
		heatmapFear = newHeatmapFear
		heatFearFactor = (newHeatFearFactor and newHeatFearFactor > 0 and newHeatFearFactor) or false
		
		local sx, sz = WorldToArray(startX,startZ)
		local fx, fz = WorldToArray(finishX,finishZ)
		
		--Spring.MarkerAddPoint(startX, 0, startZ, sx .. "  " .. sz .. ":  " .. CoordsToID(sx, sz))
		--Spring.MarkerAddPoint(finishX, 0, finishZ, fx .. "  " .. fz .. ":  " .. CoordsToID(fx, fz))
		
		local path = aStar.GetPath(CoordsToID(sx, sz), CoordsToID(fx, fz))
		
		if (not path) or #path == 0 then
			return false
		end
		
		--for i = 1, #path do
		--	local x, z = IdToCoords(path[i])
		--	local wx, wz = ArrayToWorld(x,z)
		--	Spring.MarkerAddPoint(wx, 0, wz, i)
		--end
		
		-- Functions for culling the path of useless nodes
		local function CheckLink(x1, z1, x2, z2)
			local dx, dz = x2 - x1, z2 - z1
			local linkRelationMap = pathMap[x1][z1].linkRelationMap
			--GG.TableEcho(linkRelationMap)
			--Spring.Echo(dx .. "  " .. dz)
			--Spring.Echo((linkRelationMap[dx] and linkRelationMap[dx][dz] and "link") or "no link")
			return linkRelationMap[dx] and linkRelationMap[dx][dz]
		end
		
		local function CheckDirectPath(x1, z1, x2, z2)
			local xDiff = x2 - x1
			local zDiff = z2 - z1
			local stepsNeeded = abs(xDiff) + abs(zDiff)
			
			if xDiff == 0 then
				if zDiff == 0 then
					return true
				end
				zDiff = zDiff/abs(zDiff)
			elseif zDiff == 0 then
				xDiff = xDiff/abs(xDiff)
			elseif abs(xDiff) > abs(zDiff) then
				zDiff = zDiff/abs(xDiff)
				xDiff = xDiff/abs(xDiff)
			else
				xDiff = xDiff/abs(zDiff)
				zDiff = zDiff/abs(zDiff)
			end
			
			local directPath = true
			
			local steps = 1
			local x, z = x1, z1
			local rx, rz = x1, z1
			--Spring.Echo(xDiff .. "  " .. zDiff)
			while steps <= stepsNeeded do
				x = x + xDiff
				local newRx = floor(x + 0.5)
				if newRx ~= rx then
					steps = steps + 1
					if (not CheckLink(rx, rz, newRx, rz)) or IsPositionHeatmapFeared(newRx, rz) then
						--local w1, w2 = ArrayToWorld(rx,rz)
						--local w3, w4 = ArrayToWorld(newRx,rz)
						--Spring.MarkerAddLine(w1, 0, w2, w3, 0, w4)
						--Spring.MarkerAddPoint(w3, 0, w4, "bla")
						directPath = false
						break
					end
					rx = newRx
				end
				
				z = z + zDiff
				local newRz = floor(z + 0.5)
				if newRz ~= rz then
					steps = steps + 1
					if (not CheckLink(rx, rz, rx, newRz)) or IsPositionHeatmapFeared(rx, newRz) then
						--local w1, w2 = ArrayToWorld(rx,rz)
						--local w3, w4 = ArrayToWorld(rx,newRz)
						--Spring.MarkerAddLine(w1, 0, w2, w3, 0, w4)
						--Spring.MarkerAddPoint(w3, 0, w4, "bla")
						directPath = false
						break
					end
					rz = newRz
				end
			end
			
			return directPath, rx, rz
		end
		
		-- Do the path cull
		local waypoints = {}
		local waypointCount = 0
		local function AddWaypoint(x, z)
			local pathPoint = pathMap[x][z]
			local px, py, pz = pathPoint.px, pathPoint.py, pathPoint.pz
			waypointCount = waypointCount + 1
			waypoints[waypointCount] = {x = px, y = py, z = pz}
		end
		
		local from = 1
		local fromX, fromZ = IdToCoords(path[from])
		for to = 2, #path do
			local x, z = IdToCoords(path[to])
			local clear, rx, rz = CheckDirectPath(fromX,fromZ,x,z)
			if not clear then
				from = to - 1
				fromX, fromZ = IdToCoords(path[from])
				local toX, toZ = IdToCoords(path[from])
				AddWaypoint(toX, toZ)
				--local wrx, wrz = ArrayToWorld(rx, rz)
				--Spring.MarkerAddPoint(wx, 0, wz, "Path: " .. from)
				--Spring.MarkerAddPoint(wrx, 0, wrz, "Blocked: " .. from)
			end
		end
		
		-- Note that the final waypoint is added by CAI directly because it may want
		-- the units to spread out when they reach their destination.
		
		return waypoints, waypointCount
	end
	
	local pathMapData = {
		pathMap = pathMap,
		aStar = aStar,
		GetPath = GetPath,
		SetDefenseHeatmaps = SetDefenseHeatmaps,
	}
	
	return pathMapData
end


return PathfinderGenerator