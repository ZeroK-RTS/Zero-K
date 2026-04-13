-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Overdrive Cable Tree Visualization
-- Maintains a persistent tree that grows organically as pylons are built/destroyed.
-- Cables grow from nearest connected node toward new pylons.
-- Cables wither when pylons are destroyed; orphans reconnect.
-- Per-edge energy flows computed on fully-grown edges only.
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Overdrive Cable Tree",
		desc      = "Visualizes overdrive grid as cables drawn on ground texture",
		author    = "Licho",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = -3,
		enabled   = true,
	}
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if gadgetHandler:IsSyncedCode() then

-------------------------------------------------------------------------------------
-- SYNCED
-- Reads gridNumber from unit_mex_overdrive as source of truth.
-- Periodically computes desired spanning tree edges per grid.
-- Diffs against current edges to produce grow/wither animations.
-------------------------------------------------------------------------------------

local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spValidUnitID       = Spring.ValidUnitID

local sqrt  = math.sqrt
local max   = math.max
local min   = math.min
local floor = math.floor

-------------------------------------------------------------------------------------
-- Config
-------------------------------------------------------------------------------------

local SYNC_PERIOD       = 30  -- frames between grid sync (~1/s)
local TICK_PERIOD       = 3
local SEND_PERIOD       = 6
local GROWTH_RATE       = 250 -- elmos/s
local WITHER_RATE       = 400
local GAME_SPEED        = Game.gameSpeed or 30
local GROWTH_PER_TICK   = GROWTH_RATE / GAME_SPEED * TICK_PERIOD
local WITHER_PER_TICK   = WITHER_RATE / GAME_SPEED * TICK_PERIOD

-------------------------------------------------------------------------------------
-- Unit definitions
-------------------------------------------------------------------------------------

local pylonDefs = {}
local mexDefs = {}
local generatorDefs = {}

for i = 1, #UnitDefs do
	local udef = UnitDefs[i]
	local cp = udef.customParams
	local pylonRange = tonumber(cp.pylonrange) or 0
	if pylonRange > 0 then
		pylonDefs[i] = pylonRange
	end
	if cp.metal_extractor_mult then
		mexDefs[i] = true
	end
	local energyIncome = tonumber(cp.income_energy) or 0
	local isWind = (cp.windgen and true) or false
	if energyIncome > 0 or isWind then
		generatorDefs[i] = true
	end
end

-------------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------------

-- All tracked pylons per allyTeam: nodes[allyTeamID][unitID] = {x, z, range, unitDefID}
local nodes = {}

-- Edges: edges[edgeKey] = {parentID, childID, px, pz, cx, cz, length, progress, withering, gridKey}
local edges = {}

-- Desired edges: desiredEdges[edgeKey] = true
local desiredEdges = {}

-- Change detection
local lastGridNum = {} -- [unitID] = gridNumber
local lastGridMembers = {} -- [gridKey] = { [unitID]=true } — who was in each grid last time
local structureChanged = true

local treeVersion = 0
local dirty = false

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		nodes[allyTeamList[i]] = {}
	end
end

-------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------

local function Dist(x1, z1, x2, z2)
	local dx = x1 - x2
	local dz = z1 - z2
	return sqrt(dx * dx + dz * dz)
end

local function EdgeKey(id1, id2)
	if id1 < id2 then return id1 .. ":" .. id2
	else return id2 .. ":" .. id1 end
end

local function GridKey(allyTeamID, gridID)
	return allyTeamID .. ":" .. gridID
end

local function GetNodeCapacity(unitID, unitDefID)
	if not spValidUnitID(unitID) then return 0, 0 end
	local stunned = spGetUnitIsStunned(unitID) or
		(spGetUnitRulesParam(unitID, "disarmed") == 1)
	if stunned then return 0, 0 end
	local production, consumption = 0, 0
	if generatorDefs[unitDefID] then
		production = spGetUnitRulesParam(unitID, "current_energyIncome") or 0
	end
	if mexDefs[unitDefID] then
		consumption = spGetUnitRulesParam(unitID, "overdrive_energyDrain") or 0
	end
	return production, consumption
end

-------------------------------------------------------------------------------------
-- Per-grid Prim's MST — only runs for grids whose membership changed.
-- O(k²) per changed grid where k = grid size (typically 10-50, trivial).
-------------------------------------------------------------------------------------

local SPATIAL_CELL = 600 -- spatial hash cell size (covers max pylon range pair)

local function BuildGridMST(allyTeamID, gridID)
	local pylons = {}
	for unitID, node in pairs(nodes[allyTeamID]) do
		if spValidUnitID(unitID) then
			local gid = spGetUnitRulesParam(unitID, "gridNumber") or 0
			if gid == gridID then
				pylons[#pylons + 1] = {
					unitID = unitID, x = node.x, z = node.z,
					range = node.range, unitDefID = node.unitDefID,
				}
			end
		end
	end

	local result = {}
	if #pylons < 2 then return result end

	-- Build spatial hash for fast neighbor lookup
	local cells = {} -- [cellKey] = { idx, idx, ... }
	for i = 1, #pylons do
		local p = pylons[i]
		local cx = floor(p.x / SPATIAL_CELL)
		local cz = floor(p.z / SPATIAL_CELL)
		local ck = cx * 100000 + cz
		if not cells[ck] then cells[ck] = {} end
		cells[ck][#cells[ck] + 1] = i
	end

	-- Precompute neighbor lists (indices within range)
	local neighbors = {} -- [idx] = { idx, idx, ... }
	for i = 1, #pylons do
		neighbors[i] = {}
		local p = pylons[i]
		local cx = floor(p.x / SPATIAL_CELL)
		local cz = floor(p.z / SPATIAL_CELL)
		-- Check 3x3 neighborhood of cells
		for dcx = -1, 1 do
			for dcz = -1, 1 do
				local ck = (cx + dcx) * 100000 + (cz + dcz)
				local cell = cells[ck]
				if cell then
					for ci = 1, #cell do
						local j = cell[ci]
						if j ~= i then
							local o = pylons[j]
							local dx = p.x - o.x
							local dz = p.z - o.z
							local cr = p.range + o.range
							if dx * dx + dz * dz < cr * cr then
								neighbors[i][#neighbors[i] + 1] = j
							end
						end
					end
				end
			end
		end
	end

	-- Root = highest production
	local bestRoot = 1
	local bestProd = -1
	for i = 1, #pylons do
		local prod = GetNodeCapacity(pylons[i].unitID, pylons[i].unitDefID)
		if prod > bestProd then bestProd = prod; bestRoot = i end
	end

	-- Prim's MST using neighbor lists: O(n * avg_neighbors)
	local inTree = { [bestRoot] = true }
	local treeSize = 1
	-- Frontier: unvisited nodes adjacent to tree. Track best distance per node.
	local bestEdge = {} -- [idx] = { distSq, treeIdx }
	for _, j in ipairs(neighbors[bestRoot]) do
		local p = pylons[bestRoot]
		local o = pylons[j]
		local dx = p.x - o.x
		local dz = p.z - o.z
		bestEdge[j] = { distSq = dx * dx + dz * dz, from = bestRoot }
	end

	while treeSize < #pylons do
		-- Find frontier node with smallest distance
		local bestDistSq = math.huge
		local bestJ = nil
		for j, be in pairs(bestEdge) do
			if not inTree[j] and be.distSq < bestDistSq then
				bestDistSq = be.distSq
				bestJ = j
			end
		end

		if not bestJ then break end
		inTree[bestJ] = true
		treeSize = treeSize + 1

		local parentIdx = bestEdge[bestJ].from
		bestEdge[bestJ] = nil

		local p, c = pylons[parentIdx], pylons[bestJ]
		local key = EdgeKey(p.unitID, c.unitID)
		result[key] = {
			parentID = p.unitID, childID = c.unitID,
			px = p.x, pz = p.z, cx = c.x, cz = c.z,
		}

		-- Update frontier: check neighbors of newly added node
		for _, j in ipairs(neighbors[bestJ]) do
			if not inTree[j] then
				local o = pylons[j]
				local nj = pylons[bestJ]
				local dx = nj.x - o.x
				local dz = nj.z - o.z
				local distSq = dx * dx + dz * dz
				if not bestEdge[j] or distSq < bestEdge[j].distSq then
					bestEdge[j] = { distSq = distSq, from = bestJ }
				end
			end
		end
	end

	return result
end

-------------------------------------------------------------------------------------
-- Grid sync: detect gridNumber changes, rebuild only affected grids
-------------------------------------------------------------------------------------

-- Per-grid desired edges
local desiredByGrid = {} -- [gridKey] = { [edgeKey] = info }

local function SyncWithGrid()
	-- Detect which grids changed
	local changedGrids = {} -- [gridKey] = { allyTeamID, gridID }

	for allyTeamID, allyNodes in pairs(nodes) do
		-- Clean up dead units first
		local toRemove = {}
		for unitID, _ in pairs(allyNodes) do
			if not spValidUnitID(unitID) then
				toRemove[#toRemove + 1] = unitID
			end
		end
		for i = 1, #toRemove do
			local uid = toRemove[i]
			local oldGrid = lastGridNum[uid] or 0
			if oldGrid > 0 then
				changedGrids[GridKey(allyTeamID, oldGrid)] = { allyTeamID = allyTeamID, gridID = oldGrid }
			end
			allyNodes[uid] = nil
			lastGridNum[uid] = nil
		end

		-- Check living units for grid changes
		for unitID, _ in pairs(allyNodes) do
			local gridID = spGetUnitRulesParam(unitID, "gridNumber") or 0
			local oldGrid = lastGridNum[unitID] or 0
			if gridID ~= oldGrid then
				lastGridNum[unitID] = gridID
				if oldGrid > 0 then
					changedGrids[GridKey(allyTeamID, oldGrid)] = { allyTeamID = allyTeamID, gridID = oldGrid }
				end
				if gridID > 0 then
					changedGrids[GridKey(allyTeamID, gridID)] = { allyTeamID = allyTeamID, gridID = gridID }
				end
			end
		end
	end

	-- Nothing changed?
	local hasChanges = false
	for _ in pairs(changedGrids) do hasChanges = true; break end
	if not hasChanges then
		structureChanged = false
		return
	end

	-- Rebuild only changed grids
	for gk, info in pairs(changedGrids) do
		-- Wither old edges for this grid
		if desiredByGrid[gk] then
			for ek, _ in pairs(desiredByGrid[gk]) do
				if edges[ek] and not edges[ek].withering then
					edges[ek].withering = true
					desiredEdges[ek] = nil
					dirty = true
				end
			end
		end

		-- Compute new MST
		local newEdges = BuildGridMST(info.allyTeamID, info.gridID)
		desiredByGrid[gk] = newEdges

		-- Create or revive edges
		for ek, einfo in pairs(newEdges) do
			desiredEdges[ek] = true
			if edges[ek] then
				if edges[ek].withering then
					edges[ek].withering = false
					dirty = true
				end
			else
				edges[ek] = {
					parentID = einfo.parentID, childID = einfo.childID,
					px = einfo.px, pz = einfo.pz, cx = einfo.cx, cz = einfo.cz,
					length = max(1, Dist(einfo.px, einfo.pz, einfo.cx, einfo.cz)),
					progress = 0, withering = false,
				}
				dirty = true
			end
		end
	end

	structureChanged = false
end

-------------------------------------------------------------------------------------
-- Edge growth / wither tick
-------------------------------------------------------------------------------------

local function TickEdges()
	local toRemove = {}

	for key, edge in pairs(edges) do
		if edge.withering then
			edge.progress = edge.progress - WITHER_PER_TICK
			if edge.progress <= 0 then
				toRemove[#toRemove + 1] = key
			end
			dirty = true
		elseif edge.progress < edge.length then
			edge.progress = min(edge.length, edge.progress + GROWTH_PER_TICK)
			dirty = true
		end
	end

	for i = 1, #toRemove do
		edges[toRemove[i]] = nil
	end
end

-------------------------------------------------------------------------------------
-- Flow computation: per-edge capacity via post-order DFS on spanning tree
-------------------------------------------------------------------------------------

local function ComputeFlows()
	-- Rebuild tree structure for DFS from edges
	local children = {} -- [parentID] = { childID, ... }
	local roots = {}    -- [unitID] = true
	local parentOf = {} -- [childID] = parentID
	local edgeByChild = {} -- [childID] = edgeKey

	-- Collect all participating nodes
	local nodeSet = {}
	for key, edge in pairs(edges) do
		if edge.progress >= edge.length and not edge.withering then
			local pid, cid = edge.parentID, edge.childID
			if not children[pid] then children[pid] = {} end
			children[pid][#children[pid] + 1] = cid
			parentOf[cid] = pid
			edgeByChild[cid] = key
			nodeSet[pid] = true
			nodeSet[cid] = true
		end
	end

	-- Find roots (nodes with no parent)
	for uid, _ in pairs(nodeSet) do
		if not parentOf[uid] then
			roots[uid] = true
		end
	end

	-- Post-order DFS
	local flowResults = {} -- [edgeKey] = capacity
	local function dfs(uid)
		local prod, cons = 0, 0
		-- Get this node's capacity from any allyTeam
		for _, allyNodes in pairs(nodes) do
			local node = allyNodes[uid]
			if node then
				local p, c = GetNodeCapacity(uid, node.unitDefID)
				prod = prod + p
				cons = cons + c
				break
			end
		end

		if children[uid] then
			for i = 1, #children[uid] do
				local cid = children[uid][i]
				local cProd, cCons = dfs(cid)
				prod = prod + cProd
				cons = cons + cCons
				flowResults[edgeByChild[cid]] = max(cProd, cCons)
			end
		end
		return prod, cons
	end

	for uid, _ in pairs(roots) do
		dfs(uid)
	end

	return flowResults
end

-------------------------------------------------------------------------------------
-- Send state to unsynced
-------------------------------------------------------------------------------------

local function SendToUnsyncedAll()
	local flows = ComputeFlows()

	-- Build per-allyTeam edge lists (so unsynced only sees own team's cables)
	local perAlly = {} -- [allyTeamID] = { edgeCount, parentXs, ... }

	-- Figure out which allyTeam each edge belongs to by checking parentID
	for key, edge in pairs(edges) do
		if edge.progress > 0 then
			-- Find allyTeam of this edge's parent
			local atID
			for allyTeamID, allyNodes in pairs(nodes) do
				if allyNodes[edge.parentID] or allyNodes[edge.childID] then
					atID = allyTeamID
					break
				end
			end
			if atID then
				if not perAlly[atID] then
					perAlly[atID] = {
						edgeCount = 0,
						parentXs = {}, parentZs = {},
						childXs = {}, childZs = {},
						progresses = {}, lengths = {}, capacities = {},
					}
				end
				local pa = perAlly[atID]
				pa.edgeCount = pa.edgeCount + 1
				local n = pa.edgeCount
				pa.parentXs[n] = edge.px
				pa.parentZs[n] = edge.pz
				pa.childXs[n] = edge.cx
				pa.childZs[n] = edge.cz
				pa.progresses[n] = edge.progress
				pa.lengths[n] = edge.length
				pa.capacities[n] = flows[key] or 0
			end
		end
	end

	-- Send one message per allyTeam
	for atID, pa in pairs(perAlly) do
		_G.CableTreeData = {
			allyTeamID = atID,
			version = treeVersion,
			edgeCount = pa.edgeCount,
			parentXs = pa.parentXs, parentZs = pa.parentZs,
			childXs = pa.childXs, childZs = pa.childZs,
			progresses = pa.progresses, lengths = pa.lengths,
			capacities = pa.capacities,
		}
		SendToUnsynced("CableTreeUpdate")
	end
end

-------------------------------------------------------------------------------------
-- GameFrame
-------------------------------------------------------------------------------------

function gadget:GameFrame(n)
	-- Check for gridNumber changes even without unit create/destroy
	-- (stun, disable, activate can change grid membership)
	if n % SYNC_PERIOD == 2 then
		SyncWithGrid()
	end

	if n % TICK_PERIOD == 0 then
		TickEdges()
	end

	if dirty and (n % SEND_PERIOD == 0) then
		treeVersion = treeVersion + 1
		SendToUnsyncedAll()
		dirty = false
	end
end

-------------------------------------------------------------------------------------
-- Unit lifecycle: only track node positions
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if not pylonDefs[unitDefID] then return end
	local allyTeamID = spGetUnitAllyTeam(unitID)
	local x, _, z = spGetUnitPosition(unitID)
	nodes[allyTeamID][unitID] = {
		x = x, z = z,
		range = pylonDefs[unitDefID],
		unitDefID = unitDefID,
	}
	structureChanged = true
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if not pylonDefs[unitDefID] then return end
	-- Don't remove from nodes/lastGridNum here.
	-- SyncWithGrid will detect the dead unit via spValidUnitID,
	-- mark the affected grid as changed, and clean up.
	structureChanged = true
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if not pylonDefs[unitDefID] then return end
	local _, _, _, _, _, newAlly = Spring.GetTeamInfo(newTeam, false)
	local _, _, _, _, _, oldAlly = Spring.GetTeamInfo(oldTeam, false)
	if not newAlly or not oldAlly then return end
	if newAlly ~= oldAlly then
		-- Remove from old allyTeam, add to new
		if nodes[oldAlly] then nodes[oldAlly][unitID] = nil end
		lastGridNum[unitID] = nil
		if nodes[newAlly] then
			local x, _, z = spGetUnitPosition(unitID)
			nodes[newAlly][unitID] = {
				x = x, z = z,
				range = pylonDefs[unitDefID],
				unitDefID = unitDefID,
			}
		end
		structureChanged = true
	end
end

function gadget:Initialize()
	GG.CableTree = { nodes = nodes, edges = edges }
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		if unitDefID and pylonDefs[unitDefID] then
			local allyTeamID = spGetUnitAllyTeam(unitID)
			local x, _, z = spGetUnitPosition(unitID)
			nodes[allyTeamID][unitID] = {
				x = x, z = z,
				range = pylonDefs[unitDefID],
				unitDefID = unitDefID,
			}
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

else -- UNSYNCED

-------------------------------------------------------------------------------------
-- UNSYNCED — Shader-based cable rendering via DrawWorldPreUnit
-- Cables are drawn as quad strips projected onto ground height.
-- Fragment shader: procedural organic texture, LOS-gated animation.
-------------------------------------------------------------------------------------

local spGetMyAllyTeamID    = Spring.GetMyAllyTeamID
local spGetSpectatingState = Spring.GetSpectatingState
local spGetGroundHeight    = Spring.GetGroundHeight

local floor = math.floor
local sqrt  = math.sqrt
local max   = math.max
local min   = math.min
local abs   = math.abs
local PI    = math.pi
local cos   = math.cos
local sin   = math.sin
local atan2 = math.atan2

local MAP_WIDTH  = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir .. "LuaShader.lua")
VFS.Include(luaShaderDir .. "instancevbotable.lua")

-------------------------------------------------------------------------------------
-- Config
-------------------------------------------------------------------------------------

local MIN_TRUNK_WIDTH  = 4
local MAX_TRUNK_WIDTH  = 20
local MAX_CAPACITY_REF = 100

local SEG_LENGTH       = 10    -- shorter = smoother curves
local NOISE_AMP        = 0.6
local BRANCH_CHANCE    = 0.25
local BRANCH_LEN_MIN   = 15
local BRANCH_LEN_MAX   = 50
local BRANCH_ANGLE_MIN = 0.4
local BRANCH_ANGLE_MAX = 1.1
local BRANCH_WIDTH     = 0.5

local MERGE_ANGLE    = 0.8
local STEM_FRACTION  = 0.35

-------------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------------

local renderEdges = {}
local edgesByAllyTeam = {}
local lastVersions = {}
local needsRebuild = false

local cableShader       -- 3D shader for live cables + snapshot sampling
local cableVAO          -- live cable geometry
local numCableVerts = 0

local snapshotTex       -- persistent 2D texture (top-down map projection)
local snapshotShader    -- simple shader to render cables to snapshot
local SNAPSHOT_SCALE = 4 -- snapshot pixels per elmo (4 = quarter resolution)
local snapshotW, snapshotH
local needsSnapshotUpdate = false

-------------------------------------------------------------------------------------
-- Deterministic noise
-------------------------------------------------------------------------------------

local function Hash(x, z, seed)
	local h = sin(x * 12.9898 + z * 78.233 + (seed or 0) * 43.17) * 43758.5453
	return (h - floor(h)) * 2 - 1
end

local function HashUnit(x, z, seed)
	return (Hash(x, z, seed) + 1) * 0.5
end

local function GetTrunkWidth(capacity)
	local t = min(1, capacity / MAX_CAPACITY_REF)
	return MIN_TRUNK_WIDTH + t * (MAX_TRUNK_WIDTH - MIN_TRUNK_WIDTH)
end

local function NoisyPath(x1, z1, x2, z2, amplitude, seed)
	local dx = x2 - x1
	local dz = z2 - z1
	local len = sqrt(dx * dx + dz * dz)
	if len < 2 then
		return { {x = x1, z = z1}, {x = x2, z = z2} }
	end
	local steps = max(2, floor(len / SEG_LENGTH))
	local nx = -dz / len
	local nz =  dx / len
	local points = {}
	for i = 0, steps do
		local t = i / steps
		local px = x1 + t * dx
		local pz = z1 + t * dz
		local noiseScale = 1
		if t < 0.1 then noiseScale = t / 0.1
		elseif t > 0.9 then noiseScale = (1 - t) / 0.1 end
		local n = Hash(px * 0.1, pz * 0.1, seed) * amplitude * noiseScale
		points[#points + 1] = { x = px + nx * n, z = pz + nz * n }
	end
	return points
end

-------------------------------------------------------------------------------------
-- Organic tree router (same logic, outputs vertex data for VBO)
-------------------------------------------------------------------------------------

local function normalizeAngle(a)
	while a > PI do a = a - PI * 2 end
	while a < -PI do a = a + PI * 2 end
	return a
end

-- Build all cable geometry from renderEdges, return flat vertex array.
-- Paths are converted to smooth triangle strips with averaged normals at junctions.
local function BuildCableVertices()
	if #renderEdges == 0 then return {}, 0 end

	-- Each path = { points = { {x,z}, ... }, widths = { w, ... }, capacity, isBranch }
	local allPaths = {}

	-- Same tree-building + routing code as before, but collect into allSegs
	local nodePos = {}
	local nodeChildren = {}
	local nodeParent = {}
	local roots = {}

	local function posKey(x, z)
		return floor(x) .. ":" .. floor(z)
	end

	for i = 1, #renderEdges do
		local e = renderEdges[i]
		if e.length > 0 then
			local frac = min(1, e.progress / e.length)
			if frac > 0.01 then
				local pk = posKey(e.px, e.pz)
				local ex = e.px + frac * (e.cx - e.px)
				local ez = e.pz + frac * (e.cz - e.pz)
				local ck = posKey(ex, ez)
				nodePos[pk] = { x = e.px, z = e.pz }
				nodePos[ck] = { x = ex, z = ez }
				if not nodeChildren[pk] then nodeChildren[pk] = {} end
				nodeChildren[pk][#nodeChildren[pk] + 1] = {
					key = ck, cap = max(1, e.capacity), frac = frac,
				}
				nodeParent[ck] = pk
			end
		end
	end

	for pk, _ in pairs(nodePos) do
		if not nodeParent[pk] then roots[pk] = true end
	end

	local function emitNoisyPath(x1, z1, x2, z2, widthStart, widthEnd, capacity, seed, isBranch)
		local path = NoisyPath(x1, z1, x2, z2, widthStart * NOISE_AMP, seed)
		local widths = {}
		for pi = 1, #path do
			local t = (pi - 1) / max(1, #path - 1)
			widths[pi] = widthStart + t * (widthEnd - widthStart)
		end
		allPaths[#allPaths + 1] = {
			points = path, widths = widths,
			capacity = capacity, isBranch = isBranch and 1 or 0,
		}
		-- Twigs: spawn from ribbon edge, not center
		for pi = 2, #path - 1 do
			local p1 = path[pi]
			local w = widths[pi]
			local tseed = p1.x * 7.13 + p1.z * 3.77
			local chance = isBranch and (BRANCH_CHANCE * 0.5) or BRANCH_CHANCE
			local lenScale = isBranch and 0.6 or 1.0
			if HashUnit(p1.x, p1.z, tseed) < chance then
				local dx = x2 - x1
				local dz = z2 - z1
				local pathLen = sqrt(dx * dx + dz * dz)
				if pathLen < 1 then pathLen = 1 end
				local baseAngle = atan2(dz, dx)
				local side = (Hash(p1.x, p1.z, tseed + 1) > 0) and 1 or -1
				local angle = baseAngle + side * (BRANCH_ANGLE_MIN + HashUnit(p1.x, p1.z, tseed + 2) * (BRANCH_ANGLE_MAX - BRANCH_ANGLE_MIN))
				local bLen = (BRANCH_LEN_MIN + HashUnit(p1.x, p1.z, tseed + 3) * (BRANCH_LEN_MAX - BRANCH_LEN_MIN)) * lenScale

				-- Offset start point to ribbon edge (perpendicular to path direction)
				local perpX = -dz / pathLen * side
				local perpZ =  dx / pathLen * side
				local edgeX = p1.x + perpX * w * 0.45
				local edgeZ = p1.z + perpZ * w * 0.45

				local bx2 = edgeX + cos(angle) * bLen
				local bz2 = edgeZ + sin(angle) * bLen
				local bw = w * BRANCH_WIDTH * (isBranch and 0.6 or 1.0)
				local twigPts = NoisyPath(edgeX, edgeZ, bx2, bz2, bw * 0.6, tseed + 10)
				local twigWidths = {}
				-- Start at parent width, taper to thin tip
				twigWidths[1] = min(bw, w * 0.4)
				for ti = 2, #twigPts do
					local tt = (ti - 1) / max(1, #twigPts - 1)
					twigWidths[ti] = twigWidths[1] * (1 - tt * 0.8)
				end
				allPaths[#allPaths + 1] = {
					points = twigPts, widths = twigWidths,
					capacity = capacity, isBranch = 1, -- same capacity as parent for color match
				}
			end
		end
	end

	local function clusterByDirection(pos, children)
		for i = 1, #children do
			local cpos = nodePos[children[i].key]
			if cpos then
				children[i].angle = atan2(cpos.z - pos.z, cpos.x - pos.x)
				children[i].dist = sqrt((cpos.x - pos.x)^2 + (cpos.z - pos.z)^2)
			end
		end
		table.sort(children, function(a, b) return (a.angle or 0) < (b.angle or 0) end)
		local clusters = {}
		local current = { children[1] }
		for i = 2, #children do
			if abs(normalizeAngle(children[i].angle - children[i-1].angle)) < MERGE_ANGLE then
				current[#current + 1] = children[i]
			else
				clusters[#clusters + 1] = current
				current = { children[i] }
			end
		end
		clusters[#clusters + 1] = current
		if #clusters > 1 then
			local first, last = clusters[1], clusters[#clusters]
			if abs(normalizeAngle(first[1].angle - last[#last].angle)) < MERGE_ANGLE then
				for i = 1, #last do first[#first + 1] = last[i] end
				clusters[#clusters] = nil
			end
		end
		return clusters
	end

	local function routeNode(pk)
		local pos = nodePos[pk]
		if not pos then return end
		local children = nodeChildren[pk]
		if not children or #children == 0 then return end

		local totalCap = 0
		for i = 1, #children do totalCap = totalCap + children[i].cap end
		local trunkW = GetTrunkWidth(totalCap)

		if #children == 1 then
			local child = children[1]
			local cpos = nodePos[child.key]
			if cpos then
				emitNoisyPath(pos.x, pos.z, cpos.x, cpos.z, trunkW, GetTrunkWidth(child.cap), totalCap, pos.x + pos.z, false)
				routeNode(child.key)
			end
			return
		end

		local clusters = clusterByDirection(pos, children)
		for ci = 1, #clusters do
			local cluster = clusters[ci]
			if #cluster == 1 then
				local child = cluster[1]
				local cpos = nodePos[child.key]
				if cpos then
					local bw = GetTrunkWidth(child.cap)
					emitNoisyPath(pos.x, pos.z, cpos.x, cpos.z, min(bw * 1.3, trunkW * 0.7), bw * 0.8, child.cap, pos.x * 3.7 + pos.z * 1.3 + ci, #clusters > 1)
					routeNode(child.key)
				end
			else
				local avgCos, avgSin, clusterCap, minDist = 0, 0, 0, math.huge
				for i = 1, #cluster do
					local a = cluster[i].angle or 0
					avgCos = avgCos + cos(a)
					avgSin = avgSin + sin(a)
					clusterCap = clusterCap + cluster[i].cap
					if cluster[i].dist and cluster[i].dist < minDist then minDist = cluster[i].dist end
				end
				local avgAngle = atan2(avgSin, avgCos)
				local stemLen = min(minDist * STEM_FRACTION, 120)
				local stemX = pos.x + cos(avgAngle) * stemLen
				local stemZ = pos.z + sin(avgAngle) * stemLen
				local stemW = GetTrunkWidth(clusterCap)
				emitNoisyPath(pos.x, pos.z, stemX, stemZ, stemW, stemW * 0.9, clusterCap, pos.x + pos.z + ci * 7.3, false)
				table.sort(cluster, function(a, b) return a.cap > b.cap end)
				for i = 1, #cluster do
					local child = cluster[i]
					local cpos = nodePos[child.key]
					if cpos then
						local bw = GetTrunkWidth(child.cap)
						emitNoisyPath(stemX, stemZ, cpos.x, cpos.z, min(bw * 1.2, stemW * 0.6), bw * 0.7, child.cap, stemX * 2.1 + stemZ * 5.3 + i, i > 1)
						routeNode(child.key)
					end
				end
			end
		end
	end

	for pk, _ in pairs(roots) do routeNode(pk) end

	-- Convert paths to smooth triangle strips.
	-- At each waypoint, compute perpendicular averaged from incoming+outgoing directions.
	-- Each pair of consecutive waypoints forms a quad (2 triangles, 6 verts).
	local verts = {}
	local vertCount = 0

	for pi = 1, #allPaths do
		local path = allPaths[pi]
		local pts = path.points
		local wds = path.widths
		local cap = path.capacity
		local branch = path.isBranch

		if #pts >= 2 then

		-- Compute averaged perpendicular at each waypoint
		local perps = {} -- { {nx, nz}, ... } perpendicular directions at each point
		for i = 1, #pts do
			local px, pz = 0, 0
			if i > 1 then
				local dx = pts[i].x - pts[i-1].x
				local dz = pts[i].z - pts[i-1].z
				local len = sqrt(dx*dx + dz*dz)
				if len > 0.01 then
					px = px + (-dz/len)
					pz = pz + ( dx/len)
				end
			end
			if i < #pts then
				local dx = pts[i+1].x - pts[i].x
				local dz = pts[i+1].z - pts[i].z
				local len = sqrt(dx*dx + dz*dz)
				if len > 0.01 then
					px = px + (-dz/len)
					pz = pz + ( dx/len)
				end
			end
			local plen = sqrt(px*px + pz*pz)
			if plen > 0.01 then
				perps[i] = { nx = px/plen, nz = pz/plen }
			else
				perps[i] = { nx = 0, nz = 1 }
			end
		end

		-- Cumulative distance along path
		local uDist = {}
		uDist[1] = 0
		for i = 2, #pts do
			local dx = pts[i].x - pts[i-1].x
			local dz = pts[i].z - pts[i-1].z
			uDist[i] = uDist[i-1] + sqrt(dx*dx + dz*dz)
		end

		-- Generate N separate cable strands, each as its own ribbon
		-- at different heights and lateral offsets
		local numStrands = branch == 1 and 2 or (2 + floor(min(1, cap / MAX_CAPACITY_REF) * 2))
		local strandRadius = max(2, (wds[1] or 5) * 0.25) -- each strand is ~25% of total width

		for strand = 1, numStrands do
			local strandSeed = strand * 17.3 + 5.7
			-- Hash for deterministic strand color ID
			local colorID = floor(Hash(strandSeed, 0, 0) * 2 + 2) -- 0..3 mapped

			for i = 1, #pts do
				local w = wds[i] or wds[#wds] or 5
				local p = perps[i]
				local baseY = spGetGroundHeight(pts[i].x, pts[i].z)

				-- Lateral offset: smooth weave across the bundle width
				local uScaled = (uDist[i] or 0) * 0.012
				local lateralBase = (strand - (numStrands + 1) * 0.5) * (w * 0.3 / numStrands)
				local lateralNoise = (Hash(uScaled * (0.8 + strand * 0.3), strandSeed, strandSeed) * 0.5 +
				                      Hash(uScaled * 0.4 + 3.0, strandSeed + 7, strandSeed) * 0.3) * w * 0.3
				local lateralOffset = lateralBase + lateralNoise

				-- Height offset: cables stack vertically, with noise
				local heightBase = (strand - 1) * strandRadius * 1.2
				local heightNoise = Hash(uScaled * 0.6, strandSeed + 13, strandSeed) * strandRadius * 0.8
				local heightOffset = heightBase + heightNoise + 1.5

				-- Position: center point offset laterally and vertically
				local cx = pts[i].x + p.nx * lateralOffset
				local cz = pts[i].z + p.nz * lateralOffset
				local cy = baseY + heightOffset

				-- Left/right edges of this strand
				local sr = strandRadius * 0.55
				pts[i]["sL" .. strand] = { x = cx - p.nx * sr, y = cy, z = cz - p.nz * sr }
				pts[i]["sR" .. strand] = { x = cx + p.nx * sr, y = cy, z = cz + p.nz * sr }
			end

			-- Emit triangles for this strand
			for i = 1, #pts - 1 do
				local L1 = pts[i]["sL" .. strand]
				local R1 = pts[i]["sR" .. strand]
				local L2 = pts[i+1]["sL" .. strand]
				local R2 = pts[i+1]["sR" .. strand]
				local u1, u2 = uDist[i], uDist[i+1]
				local br = branch == 1 and 1 or 0

				-- Tri 1
				verts[#verts+1]=L1.x; verts[#verts+1]=L1.y; verts[#verts+1]=L1.z
				verts[#verts+1]=cap;  verts[#verts+1]=br + colorID * 0.1; verts[#verts+1]=strandRadius * 2
				verts[#verts+1]=u1;   verts[#verts+1]=-1
				verts[#verts+1]=R1.x; verts[#verts+1]=R1.y; verts[#verts+1]=R1.z
				verts[#verts+1]=cap;  verts[#verts+1]=br + colorID * 0.1; verts[#verts+1]=strandRadius * 2
				verts[#verts+1]=u1;   verts[#verts+1]=1
				verts[#verts+1]=R2.x; verts[#verts+1]=R2.y; verts[#verts+1]=R2.z
				verts[#verts+1]=cap;  verts[#verts+1]=br + colorID * 0.1; verts[#verts+1]=strandRadius * 2
				verts[#verts+1]=u2;   verts[#verts+1]=1

				-- Tri 2
				verts[#verts+1]=L1.x; verts[#verts+1]=L1.y; verts[#verts+1]=L1.z
				verts[#verts+1]=cap;  verts[#verts+1]=br + colorID * 0.1; verts[#verts+1]=strandRadius * 2
				verts[#verts+1]=u1;   verts[#verts+1]=-1
				verts[#verts+1]=R2.x; verts[#verts+1]=R2.y; verts[#verts+1]=R2.z
				verts[#verts+1]=cap;  verts[#verts+1]=br + colorID * 0.1; verts[#verts+1]=strandRadius * 2
				verts[#verts+1]=u2;   verts[#verts+1]=1
				verts[#verts+1]=L2.x; verts[#verts+1]=L2.y; verts[#verts+1]=L2.z
				verts[#verts+1]=cap;  verts[#verts+1]=br + colorID * 0.1; verts[#verts+1]=strandRadius * 2
				verts[#verts+1]=u2;   verts[#verts+1]=-1

				vertCount = vertCount + 6
			end
		end

		end -- if #pts >= 2
	end

	return verts, vertCount
end

-------------------------------------------------------------------------------------
-- Shader sources
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- Snapshot shader: renders cables flat (top-down) into the snapshot texture.
-- Only updates pixels in LOS. Uses $info to mask.
-------------------------------------------------------------------------------------

local snapVSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (location = 0) in vec3 vertPos;
layout (location = 1) in vec3 vertData;
layout (location = 2) in vec2 vertUV;

uniform vec2 mapDims;

out float vCapacity;
out float vIsBranch;

void main() {
	vCapacity = vertData.x;
	vIsBranch = vertData.y;
	vec2 ndc = (vertPos.xz / mapDims) * 2.0 - 1.0;
	gl_Position = vec4(ndc, 0.0, 1.0);
}
]]

local snapFSSrc = [[
#version 330

in float vCapacity;
in float vIsBranch;

out vec4 fragColor;

void main() {
	float capT = clamp(vCapacity / 100.0, 0.0, 1.0);
	// Electric blue for snapshot (static, no animation)
	vec3 color = mix(vec3(0.15, 0.2, 0.5), vec3(0.4, 0.6, 1.0), capT);
	if (vIsBranch > 0.5) color *= 0.5;
	fragColor = vec4(color, 1.0);
}
]]

-------------------------------------------------------------------------------------
-- Main 3D shader: draws live cables in LOS, samples snapshot for fog areas
-------------------------------------------------------------------------------------

local cableVSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (location = 0) in vec3 vertPos;
layout (location = 1) in vec3 vertData;
layout (location = 2) in vec2 vertUV;   // u = along cable, v = -1(left) to +1(right)

out DataVS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
};

//__ENGINEUNIFORMBUFFERDEFS__

void main() {
	worldPos = vertPos;
	capacity = vertData.x;
	isBranch = vertData.y;
	width = vertData.z;
	cableUV = vertUV;
	gl_Position = cameraViewProj * vec4(vertPos, 1.0);
}
]]

local cableFSSrc = [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

uniform sampler2D infoTex;
uniform sampler2D snapshotTex;
uniform float gameTime;
uniform vec2 mapDims;

in DataVS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;  // u = distance along cable (elmos), v = -1(left) to +1(right)
};

//__ENGINEUNIFORMBUFFERDEFS__

out vec4 fragColor;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		val += amp * noise(p);
		p *= 2.1;
		amp *= 0.5;
	}
	return val;
}

void main() {
	// LOS
	vec2 losUV = clamp(worldPos.xz, vec2(0.0), mapSize.xy) / mapSize.zw;
	float losTexSample = dot(vec3(0.33), texture(infoTex, losUV).rgb);
	float losState = clamp(losTexSample * 4.0 - 1.0, 0.0, 1.0);

	vec2 snapUV = clamp(worldPos.xz / mapDims, vec2(0.0), vec2(1.0));
	vec4 snapColor = texture(snapshotTex, snapUV);

	if (losState < 0.05) {
		if (snapColor.a < 0.1) discard;
		fragColor = vec4(snapColor.rgb * 0.3, snapColor.a * 0.6);
		return;
	}

	float capT = clamp(capacity / 100.0, 0.0, 1.0);
	float fullLOS = smoothstep(0.3, 0.8, losState);

	// v = -1 to +1 across this individual strand ribbon
	float v = cableUV.y; // -1 left edge, +1 right edge
	float t = abs(v);     // 0 at center, 1 at edge

	// Cylinder normal: round cross-section
	// The strand ribbon is flat, but we fake a round normal
	float ny = sqrt(max(0.0, 1.0 - t * t)); // hemisphere: 1 at center, 0 at edge
	float nx = v;                             // sideways: -1 left, +1 right
	vec3 cylNormal = normalize(vec3(nx * 0.5, ny, nx * 0.5));

	// Sun diffuse lighting
	float diffuse = max(0.15, dot(cylNormal, normalize(sunDir.xyz)));

	// Specular (Blinn-Phong)
	vec3 viewDir = normalize(cameraViewInv[3].xyz - worldPos);
	vec3 halfDir = normalize(normalize(sunDir.xyz) + viewDir);
	float spec = pow(max(0.0, dot(cylNormal, halfDir)), 40.0) * 0.45;

	// Per-strand color from isBranch field (encodes colorID * 0.1 + branch flag)
	float colorID = floor(fract(isBranch) * 10.0 + 0.5);
	vec3 baseColor;
	if (colorID < 1.0)      baseColor = vec3(0.32, 0.20, 0.07); // brown
	else if (colorID < 2.0) baseColor = vec3(0.14, 0.28, 0.09); // dark green
	else if (colorID < 3.0) baseColor = vec3(0.38, 0.26, 0.11); // copper
	else                    baseColor = vec3(0.22, 0.11, 0.07); // dark red-brown

	baseColor *= (1.0 + capT * 0.3);

	// Final lit color
	vec3 color = baseColor * diffuse + vec3(1.0, 0.95, 0.88) * spec;

	// Subtle surface texture noise
	float surfNoise = hash(worldPos.xz * 0.5) * 0.06;
	color += vec3(surfNoise * 0.5, surfNoise * 0.3, surfNoise * 0.1);

	// Soft edge fade (anti-alias at strand border)
	float edgeFade = smoothstep(1.0, 0.8, t);

	// Dim in radar
	float dimFactor = mix(0.3, 1.0, fullLOS);
	color *= dimFactor;

	fragColor = vec4(color, edgeFade * 0.95);
}
]]

-------------------------------------------------------------------------------------
-- Drawing
-------------------------------------------------------------------------------------

function gadget:DrawWorldPreUnit()
	if not cableShader or numCableVerts == 0 or not cableVAO then return end

	-- Update snapshot texture if needed (must happen in a draw callin)
	if needsSnapshotUpdate and snapshotTex and snapshotShader then
		gl.RenderToTexture(snapshotTex, function()
			gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0)
			snapshotShader:Activate()
			snapshotShader:SetUniform("mapDims", MAP_WIDTH, MAP_HEIGHT)
			gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
			cableVAO:DrawArrays(GL.TRIANGLES, numCableVerts)
			snapshotShader:Deactivate()
		end)
		needsSnapshotUpdate = false
	end

	-- Draw live 3D cables
	cableShader:Activate()
	cableShader:SetUniform("gameTime", Spring.GetGameSeconds())
	cableShader:SetUniform("mapDims", MAP_WIDTH, MAP_HEIGHT)

	gl.Texture(0, "$info")
	if snapshotTex then
		gl.Texture(1, snapshotTex)
	end
	gl.DepthTest(GL.LEQUAL)
	gl.DepthMask(false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

	cableVAO:DrawArrays(GL.TRIANGLES, numCableVerts)

	cableShader:Deactivate()
	gl.Texture(0, false)
	gl.Texture(1, false)
	gl.DepthTest(false)
end

-------------------------------------------------------------------------------------
-- VBO rebuild
-------------------------------------------------------------------------------------

local function RebuildVBO()
	local verts, vertCount = BuildCableVertices()
	if vertCount == 0 then
		numCableVerts = 0
		needsRebuild = false
		return
	end

	-- Rebuild VBO/VAO
	cableVAO = nil

	local vbo = gl.GetVBO(GL.ARRAY_BUFFER, false)
	if not vbo then return end

	vbo:Define(vertCount, {
		{ id = 0, name = "vertPos",  size = 3 },
		{ id = 1, name = "vertData", size = 3 },
		{ id = 2, name = "vertUV",   size = 2 },
	})
	vbo:Upload(verts)

	cableVAO = gl.GetVAO()
	if cableVAO then
		cableVAO:AttachVertexBuffer(vbo)
	end

	numCableVerts = vertCount

	needsSnapshotUpdate = true
	needsRebuild = false
end

-------------------------------------------------------------------------------------
-- Receive data from synced
-------------------------------------------------------------------------------------

local function OnCableTreeUpdate()
	local data = SYNCED.CableTreeData
	if not data then return end

	local spec, fullview = spGetSpectatingState()
	local myAllyTeam = spGetMyAllyTeamID()
	local allyTeamID = data.allyTeamID

	if not (spec or fullview) and allyTeamID ~= myAllyTeam then return end
	if lastVersions[allyTeamID] and data.version == lastVersions[allyTeamID] then return end
	lastVersions[allyTeamID] = data.version

	local edges = {}
	local count = data.edgeCount or 0
	for i = 1, count do
		edges[i] = {
			px = data.parentXs[i], pz = data.parentZs[i],
			cx = data.childXs[i],  cz = data.childZs[i],
			progress = data.progresses[i], length = data.lengths[i],
			capacity = data.capacities[i],
		}
	end
	edgesByAllyTeam[allyTeamID] = edges

	renderEdges = {}
	for _, teamEdges in pairs(edgesByAllyTeam) do
		for j = 1, #teamEdges do
			renderEdges[#renderEdges + 1] = teamEdges[j]
		end
	end

	needsRebuild = true
end

-------------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if needsRebuild and n % 6 == 0 then
		RebuildVBO()
	end
end

function gadget:Initialize()
	if not gl.CreateShader or not gl.GetVBO or not gl.GetVAO or not gl.RenderToTexture then
		Spring.Echo("[CableTree] Missing GL support, disabling")
		gadgetHandler:RemoveGadget()
		return
	end

	-- Create snapshot texture (map-sized, reduced resolution)
	snapshotW = floor(MAP_WIDTH / SNAPSHOT_SCALE)
	snapshotH = floor(MAP_HEIGHT / SNAPSHOT_SCALE)
	snapshotTex = gl.CreateTexture(snapshotW, snapshotH, {
		fbo = true,
		min_filter = GL.LINEAR,
		mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
	})
	if not snapshotTex then
		Spring.Echo("[CableTree] Failed to create snapshot texture")
	end

	-- Compile snapshot shader (flat 2D projection)
	snapshotShader = LuaShader({
		vertex = snapVSSrc,
		fragment = snapFSSrc,
		uniformFloat = {
			mapDims = 0,
		},
	}, "Cable Snapshot Shader")

	local snapCompiled = snapshotShader:Initialize()
	if not snapCompiled then
		Spring.Echo("[CableTree] Snapshot shader failed to compile")
		snapshotShader = nil
	end

	-- Compile main 3D cable shader
	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	local vsSrc = cableVSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	local fsSrc = cableFSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)

	cableShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
		uniformInt = {
			infoTex = 0,
			snapshotTex = 1,
		},
		uniformFloat = {
			gameTime = 0,
			mapDims = 0,
		},
	}, "Cable Tree Shader")

	local compiled = cableShader:Initialize()
	if not compiled then
		Spring.Echo("[CableTree] Shader compilation failed")
		gadgetHandler:RemoveGadget()
		return
	end

	gadgetHandler:AddSyncAction("CableTreeUpdate", OnCableTreeUpdate)
end

function gadget:Shutdown()
	if cableShader then
		cableShader:Finalize()
	end
	if snapshotShader then
		snapshotShader:Finalize()
	end
	if snapshotTex then
		gl.DeleteTextureFBO(snapshotTex)
	end
	cableVAO = nil
	gadgetHandler:RemoveSyncAction("CableTreeUpdate")
end

end -- UNSYNCED
