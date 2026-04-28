-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Overdrive Cable Tree Visualization
-- Synced: maintains topology + per-edge capacity, sends Full/Delta to unsynced.
-- Unsynced: organic-tree geometry, gameframe-based grow/wither animation in shader.
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
-- Periodically computes desired spanning tree edges per grid and sends
-- Full or Delta updates to unsynced. Visual progress is unsynced-only.
-------------------------------------------------------------------------------------

local spGetUnitPosition   = Spring.GetUnitPosition
local spGetUnitAllyTeam   = Spring.GetUnitAllyTeam
local spGetUnitDefID      = Spring.GetUnitDefID
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitIsStunned  = Spring.GetUnitIsStunned
local spValidUnitID       = Spring.ValidUnitID

-- Mirrors the "currentlyActive" check in unit_mex_overdrive.lua so we only
-- show cables for pylons actually contributing to the grid. GetUnitIsStunned
-- covers under-construction, EMP'd, and transported units.
local function IsActiveForGrid(unitID)
	if spGetUnitIsStunned(unitID) then return false end
	if spGetUnitRulesParam(unitID, "disarmed") == 1 then return false end
	if spGetUnitRulesParam(unitID, "morphDisable") == 1 then return false end
	return true
end

local sqrt  = math.sqrt
local max   = math.max
local floor = math.floor

-------------------------------------------------------------------------------------
-- Config
-------------------------------------------------------------------------------------

local SYNC_PERIOD       = 30  -- frames between grid sync (~1/s); also send cadence
local DEBUG_FLOW        = true -- echo per-edge capacity table on every Send

-------------------------------------------------------------------------------------
-- Unit definitions
-------------------------------------------------------------------------------------

local pylonDefs = {}
local mexDefs = {}
local generatorDefs = {}
local pmaxByDef = {}      -- [defID] = nameplate production for non-wind generators
local isWindgenByDef = {} -- [defID] = true (production resolved via WindMax at runtime)
local voltageByDef = {}   -- [defID] = neededlink value (counts as static Dmax)

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
	if energyIncome > 0 then
		pmaxByDef[i] = energyIncome
	end
	if isWind then
		isWindgenByDef[i] = true
	end
	local nl = tonumber(cp.neededlink)
	if nl and nl > 0 then
		voltageByDef[i] = nl
	end
end

-- Mex draw treated as effectively unbounded for max-potential math. Large
-- enough that min(Pmax, INF_DRAW) collapses to Pmax cleanly, small enough to
-- survive float subtraction (totalDmax - subtreeDmax) without precision loss.
local INF_DRAW = 1e9

-- WindMax is set by unit_windmill_control.lua at game start; resolve lazily.
local cachedWindMax
local function GetWindMax()
	if cachedWindMax then return cachedWindMax end
	local v = Spring.GetGameRulesParam("WindMax")
	if v then cachedWindMax = v end
	return v or 2.5
end

-------------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------------

-- All tracked pylons per allyTeam: nodes[allyTeamID][unitID] = {x, z, range, unitDefID}
local nodes = {}

-- Reverse index: unitID -> allyTeamID, for O(1) edge->ally lookup during send
local allyOfUnit = {}

-- Edges: edges[edgeKey] = {parentID, childID, px, pz, cx, cz}
-- Visual progress (grow/wither) is unsynced-only, gameframe-driven.
local edges = {}

-- Change detection
local lastGridNum = {} -- [unitID] = gridNumber
local topologyDirty = false -- set true when SyncWithGrid actually adds or removes an edge
local alliesWithEdges = {}  -- [ally] = true if last send had edges (for empty-clear)

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		nodes[allyTeamList[i]] = {}
	end
end

-------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------

local function EdgeKey(id1, id2)
	if id1 < id2 then return id1 .. ":" .. id2
	else return id2 .. ":" .. id1 end
end

local function GridKey(allyTeamID, gridID)
	return allyTeamID .. ":" .. gridID
end

-- Stable nameplate production: solar/fusion/sing fixed; windgen = current WindMax.
local function GetNodePmax(unitDefID)
	if isWindgenByDef[unitDefID] then return GetWindMax() end
	return pmaxByDef[unitDefID] or 0
end

-- Static draw: mex = effectively infinite (any flow saturates it),
-- voltage units contribute their neededlink threshold.
local function GetNodeDmax(unitDefID)
	if mexDefs[unitDefID] then return INF_DRAW end
	return voltageByDef[unitDefID] or 0
end

-------------------------------------------------------------------------------------
-- Per-grid Prim's MST — only runs for grids whose membership changed.
-- O(k²) per changed grid where k = grid size (typically 10-50, trivial).
-------------------------------------------------------------------------------------

local SPATIAL_CELL = 600 -- spatial hash cell size (covers max pylon range pair)

local function BuildGridMST(allyTeamID, gridID)
	local pylons = {}
	-- lastGridNum is the authoritative effective-grid map maintained by
	-- SyncWithGrid (already accounts for active/inactive state).
	for unitID, node in pairs(nodes[allyTeamID]) do
		if lastGridNum[unitID] == gridID then
			pylons[#pylons + 1] = {
				unitID = unitID, x = node.x, z = node.z,
				range = node.range, unitDefID = node.unitDefID,
			}
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

	-- Root = highest nameplate production (stable across wind/load).
	local bestRoot = 1
	local bestProd = -1
	for i = 1, #pylons do
		local prod = GetNodePmax(pylons[i].unitDefID)
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
			allyOfUnit[uid] = nil
		end

		-- Check living units for grid changes. Inactive units (in-build, EMP'd,
		-- disarmed, morphing) are treated as gridless so they're excluded from
		-- the MST; the active->inactive transition naturally rebuilds the grid.
		for unitID, _ in pairs(allyNodes) do
			local gridID = (IsActiveForGrid(unitID) and (spGetUnitRulesParam(unitID, "gridNumber") or 0)) or 0
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

	-- Rebuild only changed grids. Diff old vs new MST so unchanged edges
	-- are preserved (no spurious add/remove churn).
	for gk, info in pairs(changedGrids) do
		local oldDesired = desiredByGrid[gk] or {}
		local newDesired = BuildGridMST(info.allyTeamID, info.gridID)
		desiredByGrid[gk] = newDesired

		for ek in pairs(oldDesired) do
			if not newDesired[ek] and edges[ek] then
				edges[ek] = nil
				topologyDirty = true
			end
		end

		for ek, einfo in pairs(newDesired) do
			if not edges[ek] then
				edges[ek] = {
					parentID = einfo.parentID, childID = einfo.childID,
					px = einfo.px, pz = einfo.pz, cx = einfo.cx, cz = einfo.cz,
				}
				topologyDirty = true
			end
		end
	end
end

-------------------------------------------------------------------------------------
-- Max-potential per edge: max flow that could ever cross the cable, given the
-- nameplate production and static draw (mex = ∞, voltage units = neededlink)
-- on each side of the cut. Two passes per tree:
--   1. Post-order DFS aggregates subtreePmax / subtreeDmax per child edge.
--   2. Per edge, otherSide = total − subtreeSide; capacity is symmetric:
--        max( min(sP, oDmax), min(oP, sDmax) )
-- With ∞ mex draw this collapses: when both sides have a mex, capacity becomes
-- max(sP, oP) (= the larger producer half feeds the smaller). When only one
-- side has a mex, capacity = the producer-side Pmax. Voltage-only cuts use
-- the (finite) sum of neededlink thresholds.
-------------------------------------------------------------------------------------

local function ComputeMaxPotentials()
	-- Treat edges as undirected: stored parent/child reflects MST traversal
	-- order at the time the edge was inserted, NOT actual energy flow. We
	-- re-derive both subtree sums and parent/child orientation here, then
	-- write the orientation back so downstream rendering animates correctly.
	local adj = {}                  -- [unitID] = { {neigh = id, key = ek}, ... }
	local nodeSet = {}
	local function nodeUnitDefID(uid)
		for _, allyNodes in pairs(nodes) do
			local n = allyNodes[uid]
			if n then return n.unitDefID end
		end
		return nil
	end

	for key, edge in pairs(edges) do
		local a, b = edge.parentID, edge.childID
		adj[a] = adj[a] or {}; adj[a][#adj[a] + 1] = { neigh = b, key = key }
		adj[b] = adj[b] or {}; adj[b][#adj[b] + 1] = { neigh = a, key = key }
		nodeSet[a] = true
		nodeSet[b] = true
	end

	-- Per-component DFS rooted at the highest-Pmax node in that component.
	-- parentInTree maps child -> { parent, edgeKey } so subtree sums are well-defined.
	local parentInTree = {}
	local order = {}                -- DFS visit order, used for post-order pass
	local visited = {}

	local function dfsRoot(rootID)
		visited[rootID] = true
		order[#order + 1] = rootID
		local stack = { rootID }
		while #stack > 0 do
			local u = stack[#stack]; stack[#stack] = nil
			local ns = adj[u]
			if ns then
				for i = 1, #ns do
					local nb, ek = ns[i].neigh, ns[i].key
					if not visited[nb] then
						visited[nb] = true
						parentInTree[nb] = { parent = u, key = ek }
						order[#order + 1] = nb
						stack[#stack + 1] = nb
					end
				end
			end
		end
	end

	for uid in pairs(nodeSet) do
		if not visited[uid] then
			-- pick best root within this component: highest Pmax
			local componentNodes = {}
			local stk = { uid }
			local seen = { [uid] = true }
			while #stk > 0 do
				local v = stk[#stk]; stk[#stk] = nil
				componentNodes[#componentNodes + 1] = v
				local ns = adj[v]
				if ns then
					for i = 1, #ns do
						local nb = ns[i].neigh
						if not seen[nb] then seen[nb] = true; stk[#stk + 1] = nb end
					end
				end
			end
			local bestID, bestP = uid, -1
			for i = 1, #componentNodes do
				local v = componentNodes[i]
				local did = nodeUnitDefID(v)
				local p = did and GetNodePmax(did) or 0
				if p > bestP then bestP = p; bestID = v end
			end
			dfsRoot(bestID)
		end
	end

	-- Post-order traversal: subPmax/subDmax of each node's subtree (inclusive).
	local subPmax, subDmax = {}, {}
	for i = 1, #order do
		local u = order[i]
		local did = nodeUnitDefID(u)
		subPmax[u] = did and GetNodePmax(did) or 0
		subDmax[u] = did and GetNodeDmax(did) or 0
	end
	for i = #order, 1, -1 do
		local u = order[i]
		local pi = parentInTree[u]
		if pi then
			subPmax[pi.parent] = subPmax[pi.parent] + subPmax[u]
			subDmax[pi.parent] = subDmax[pi.parent] + subDmax[u]
		end
	end

	-- Per edge: subtree side = the deeper node (the child in DFS rooting).
	-- capAB = max flow subtree -> other; capBA = max flow other -> subtree.
	-- Whichever is larger sets parent on the source side.
	local capacities = {}
	local debugLog = DEBUG_FLOW and {} or nil
	local function fmtD(v) return v >= INF_DRAW * 0.5 and "INF" or string.format("%.0f", v) end

	for cid, info in pairs(parentInTree) do
		local key = info.key
		local pid = info.parent
		-- Find root of cid's component (walk up parentInTree).
		local r = cid
		while parentInTree[r] do r = parentInTree[r].parent end
		local totalP, totalD = subPmax[r], subDmax[r]
		local sP, sD = subPmax[cid], subDmax[cid]
		local oP, oD = totalP - sP, totalD - sD
		local capAB = (sP < oD) and sP or oD   -- subtree -> other
		local capBA = (oP < sD) and oP or sD   -- other -> subtree
		local cap = (capAB > capBA) and capAB or capBA
		capacities[key] = cap

		-- Orient: parent goes on the source side of dominant flow.
		local edge = edges[key]
		if edge then
			local srcSubtree = capAB > capBA
			local newParent = srcSubtree and cid or pid
			local newChild  = srcSubtree and pid or cid
			if edge.parentID ~= newParent then
				-- Look up positions from `nodes` to get fresh coords.
				local function findNode(uid)
					for _, allyNodes in pairs(nodes) do
						local n = allyNodes[uid]
						if n then return n end
					end
				end
				local np, nc = findNode(newParent), findNode(newChild)
				if np and nc then
					edge.parentID, edge.childID = newParent, newChild
					edge.px, edge.pz = np.x, np.z
					edge.cx, edge.cz = nc.x, nc.z
				end
			end
		end

		if debugLog then
			local function nameOf(uid)
				local d = nodeUnitDefID(uid)
				return d and UnitDefs[d].name or tostring(uid)
			end
			local e = edges[key]
			debugLog[#debugLog + 1] = string.format("  %-13s -> %-13s  sP=%-7.1f sD=%-5s oP=%-7.1f oD=%-5s  cap=%.1f",
				nameOf(e.parentID), nameOf(e.childID),
				sP, fmtD(sD), oP, fmtD(oD), cap)
		end
	end

	if debugLog and #debugLog > 0 then
		Spring.Echo("[OD-cables] capacities:")
		for i = 1, #debugLog do Spring.Echo(debugLog[i]) end
	end

	return capacities
end

-------------------------------------------------------------------------------------
-- Send state to unsynced. One Full snapshot per ally, only when topology changed.
-- Capacity drift between topology changes is ignored (acceptable: cable colour
-- only updates when the grid actually mutates).
-------------------------------------------------------------------------------------

local function SendAll()
	local flows = ComputeMaxPotentials()

	-- Bin edges by ally, in one pass.
	local perAlly = {}  -- [ally] = { keys, pxs, pzs, cxs, czs, caps, n }
	for key, edge in pairs(edges) do
		local ally = allyOfUnit[edge.parentID] or allyOfUnit[edge.childID]
		if ally then
			local pa = perAlly[ally]
			if not pa then
				pa = { keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {}, caps = {}, n = 0 }
				perAlly[ally] = pa
			end
			pa.n = pa.n + 1
			local i = pa.n
			pa.keys[i] = key
			pa.pxs[i], pa.pzs[i] = edge.px, edge.pz
			pa.cxs[i], pa.czs[i] = edge.cx, edge.cz
			pa.caps[i] = flows[key] or 0
		end
	end

	-- Fire one message per ally that currently has edges.
	for ally, pa in pairs(perAlly) do
		_G.CableTreeFull = {
			allyTeamID = ally, edgeCount = pa.n,
			keys = pa.keys, pxs = pa.pxs, pzs = pa.pzs,
			cxs = pa.cxs, czs = pa.czs, caps = pa.caps,
		}
		SendToUnsynced("CableTreeFull")
		alliesWithEdges[ally] = true
	end

	-- Allies whose last edge just disappeared get one zero-edge snapshot so
	-- unsynced clears them; then we forget them.
	for ally in pairs(alliesWithEdges) do
		if not perAlly[ally] then
			_G.CableTreeFull = {
				allyTeamID = ally, edgeCount = 0,
				keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {}, caps = {},
			}
			SendToUnsynced("CableTreeFull")
			alliesWithEdges[ally] = nil
		end
	end
end

-------------------------------------------------------------------------------------
-- GameFrame
-------------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if n % SYNC_PERIOD == 2 then
		SyncWithGrid()
		if topologyDirty then
			SendAll()
			topologyDirty = false
		end
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
	allyOfUnit[unitID] = allyTeamID
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	-- Don't remove from nodes/lastGridNum here.
	-- SyncWithGrid will detect the dead unit via spValidUnitID,
	-- mark the affected grid as changed, and clean up.
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if not pylonDefs[unitDefID] then return end
	local _, _, _, _, _, newAlly = Spring.GetTeamInfo(newTeam, false)
	local _, _, _, _, _, oldAlly = Spring.GetTeamInfo(oldTeam, false)
	if not newAlly or not oldAlly then return end
	if newAlly ~= oldAlly then
		if nodes[oldAlly] then nodes[oldAlly][unitID] = nil end
		lastGridNum[unitID] = nil
		allyOfUnit[unitID] = nil
		if nodes[newAlly] then
			local x, _, z = spGetUnitPosition(unitID)
			nodes[newAlly][unitID] = {
				x = x, z = z,
				range = pylonDefs[unitDefID],
				unitDefID = unitDefID,
			}
			allyOfUnit[unitID] = newAlly
		end
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
			allyOfUnit[unitID] = allyTeamID
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

local MIN_TRUNK_WIDTH  = 3
local MAX_TRUNK_WIDTH  = 12
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

-- Visual grow/wither animation rates (elmos/sec); fragment shader trims geometry.
local GROWTH_RATE = 250
local WITHER_RATE = 400
local GAME_SPEED  = Game.gameSpeed or 30

-------------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------------

-- edgesByAllyTeam[ally][edgeKey] = { px, pz, cx, cz, capacity, appearFrame, witherFrame }
local edgesByAllyTeam = {}
local renderEdges = {}
local needsRebuild = false

local cableShader       -- forward shader for cable rendering
local cableVAO          -- live cable geometry
local numCableVerts = 0

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

-- Build organic tree geometry from renderEdges (full edges; growth/wither
-- is animated in the fragment shader via appearTime / witherTime).
local function GenerateOrganicTree()
	if #renderEdges == 0 then return {}, 0 end

	local allPaths = {}

	local nodePos = {}
	local nodeChildren = {}
	local nodeParent = {}
	local roots = {}

	local function posKey(x, z)
		return floor(x) .. ":" .. floor(z)
	end

	for i = 1, #renderEdges do
		local e = renderEdges[i]
		local pk = posKey(e.px, e.pz)
		local ck = posKey(e.cx, e.cz)
		nodePos[pk] = { x = e.px, z = e.pz }
		nodePos[ck] = { x = e.cx, z = e.cz }
		if not nodeChildren[pk] then nodeChildren[pk] = {} end
		nodeChildren[pk][#nodeChildren[pk] + 1] = {
			key = ck, cap = max(1, e.capacity),
			appearFrame = e.appearFrame, witherFrame = e.witherFrame,
		}
		nodeParent[ck] = pk
	end

	for pk, _ in pairs(nodePos) do
		if not nodeParent[pk] then roots[pk] = true end
	end

	local function emitNoisyPath(x1, z1, x2, z2, widthStart, widthEnd, capacity, seed, isBranch, appearFrame, witherFrame)
		local path = NoisyPath(x1, z1, x2, z2, widthStart * NOISE_AMP, seed)
		local widths = {}
		for pi = 1, #path do
			local t = (pi - 1) / max(1, #path - 1)
			widths[pi] = widthStart + t * (widthEnd - widthStart)
		end
		allPaths[#allPaths + 1] = {
			points = path, widths = widths,
			capacity = capacity, isBranch = isBranch and 1 or 0,
			appearFrame = appearFrame, witherFrame = witherFrame,
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
					capacity = capacity, isBranch = 1,
					appearFrame = appearFrame, witherFrame = witherFrame,
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
				emitNoisyPath(pos.x, pos.z, cpos.x, cpos.z, trunkW, GetTrunkWidth(child.cap), totalCap, pos.x + pos.z, false, child.appearFrame, child.witherFrame)
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
					emitNoisyPath(pos.x, pos.z, cpos.x, cpos.z, min(bw * 1.3, trunkW * 0.7), bw * 0.8, child.cap, pos.x * 3.7 + pos.z * 1.3 + ci, #clusters > 1, child.appearFrame, child.witherFrame)
					routeNode(child.key)
				end
			else
				local avgCos, avgSin, clusterCap, minDist = 0, 0, 0, math.huge
				-- Stem frames: appear with the earliest child; wither only if all children withering
				local stemAppear = math.huge
				local stemWither = -math.huge
				local allWither = true
				for i = 1, #cluster do
					local a = cluster[i].angle or 0
					avgCos = avgCos + cos(a)
					avgSin = avgSin + sin(a)
					clusterCap = clusterCap + cluster[i].cap
					if cluster[i].dist and cluster[i].dist < minDist then minDist = cluster[i].dist end
					local af = cluster[i].appearFrame or 0
					if af < stemAppear then stemAppear = af end
					if cluster[i].witherFrame then
						if cluster[i].witherFrame > stemWither then stemWither = cluster[i].witherFrame end
					else
						allWither = false
					end
				end
				if stemAppear == math.huge then stemAppear = 0 end
				local stemWitherFinal = (allWither and stemWither > -math.huge) and stemWither or nil
				local avgAngle = atan2(avgSin, avgCos)
				local stemLen = min(minDist * STEM_FRACTION, 120)
				local stemX = pos.x + cos(avgAngle) * stemLen
				local stemZ = pos.z + sin(avgAngle) * stemLen
				local stemW = GetTrunkWidth(clusterCap)
				emitNoisyPath(pos.x, pos.z, stemX, stemZ, stemW, stemW * 0.9, clusterCap, pos.x + pos.z + ci * 7.3, false, stemAppear, stemWitherFinal)
				table.sort(cluster, function(a, b) return a.cap > b.cap end)
				for i = 1, #cluster do
					local child = cluster[i]
					local cpos = nodePos[child.key]
					if cpos then
						local bw = GetTrunkWidth(child.cap)
						emitNoisyPath(stemX, stemZ, cpos.x, cpos.z, min(bw * 1.2, stemW * 0.6), bw * 0.7, child.cap, stemX * 2.1 + stemZ * 5.3 + i, i > 1, child.appearFrame, child.witherFrame)
						routeNode(child.key)
					end
				end
			end
		end
	end

	for pk, _ in pairs(roots) do routeNode(pk) end

	-- Convert paths to triangle strip vertices (smooth ribbons with averaged normals)
	-- Format per vertex: x, y, z, capacity, isBranch, width, u, v
	local verts = {}
	local vertCount = 0

	for pi = 1, #allPaths do
		local path = allPaths[pi]
		local pts = path.points
		local wds = path.widths
		local cap = path.capacity
		local branch = path.isBranch
		local appearTime = (path.appearFrame or 0) / GAME_SPEED
		local witherTime = path.witherFrame and (path.witherFrame / GAME_SPEED) or 0

		if #pts >= 2 then
			-- Averaged perpendicular at each waypoint
			local perps = {}
			for i = 1, #pts do
				local px, pz = 0, 0
				if i > 1 then
					local dx = pts[i].x - pts[i-1].x
					local dz = pts[i].z - pts[i-1].z
					local len = sqrt(dx*dx + dz*dz)
					if len > 0.01 then px = px + (-dz/len); pz = pz + (dx/len) end
				end
				if i < #pts then
					local dx = pts[i+1].x - pts[i].x
					local dz = pts[i+1].z - pts[i].z
					local len = sqrt(dx*dx + dz*dz)
					if len > 0.01 then px = px + (-dz/len); pz = pz + (dx/len) end
				end
				local plen = sqrt(px*px + pz*pz)
				if plen > 0.01 then
					perps[i] = { nx = px/plen, nz = pz/plen }
				else
					perps[i] = { nx = 0, nz = 1 }
				end
			end

			-- Cumulative U distance
			local uDist = { [1] = 0 }
			for i = 2, #pts do
				local dx = pts[i].x - pts[i-1].x
				local dz = pts[i].z - pts[i-1].z
				uDist[i] = uDist[i-1] + sqrt(dx*dx + dz*dz)
			end

			-- Left/right vertices at each waypoint
			local lefts = {}
			local rights = {}
			for i = 1, #pts do
				local hw = (wds[i] or 5) * 0.55
				local p = perps[i]
				local y = spGetGroundHeight(pts[i].x, pts[i].z) + 2
				lefts[i]  = { x = pts[i].x - p.nx * hw, y = y, z = pts[i].z - p.nz * hw }
				rights[i] = { x = pts[i].x + p.nx * hw, y = y, z = pts[i].z + p.nz * hw }
			end

			local brVal = branch == 1 and 1 or 0

			for i = 1, #pts - 1 do
				local L1, R1, L2, R2 = lefts[i], rights[i], lefts[i+1], rights[i+1]
				local u1, u2 = uDist[i], uDist[i+1]
				local w1, w2 = wds[i] or 5, wds[i+1] or 5
				-- Perpendicular (cross-section direction) at each waypoint
				local p1x, p1z = perps[i].nx, perps[i].nz
				local p2x, p2z = perps[i+1].nx, perps[i+1].nz

				-- Tri 1: L1, R1, R2
				verts[#verts+1]=L1.x; verts[#verts+1]=L1.y; verts[#verts+1]=L1.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w1
				verts[#verts+1]=u1; verts[#verts+1]=-1
				verts[#verts+1]=p1x; verts[#verts+1]=p1z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=R1.x; verts[#verts+1]=R1.y; verts[#verts+1]=R1.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w1
				verts[#verts+1]=u1; verts[#verts+1]=1
				verts[#verts+1]=p1x; verts[#verts+1]=p1z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=R2.x; verts[#verts+1]=R2.y; verts[#verts+1]=R2.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w2
				verts[#verts+1]=u2; verts[#verts+1]=1
				verts[#verts+1]=p2x; verts[#verts+1]=p2z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime

				-- Tri 2: L1, R2, L2
				verts[#verts+1]=L1.x; verts[#verts+1]=L1.y; verts[#verts+1]=L1.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w1
				verts[#verts+1]=u1; verts[#verts+1]=-1
				verts[#verts+1]=p1x; verts[#verts+1]=p1z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=R2.x; verts[#verts+1]=R2.y; verts[#verts+1]=R2.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w2
				verts[#verts+1]=u2; verts[#verts+1]=1
				verts[#verts+1]=p2x; verts[#verts+1]=p2z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=L2.x; verts[#verts+1]=L2.y; verts[#verts+1]=L2.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w2
				verts[#verts+1]=u2; verts[#verts+1]=-1
				verts[#verts+1]=p2x; verts[#verts+1]=p2z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime

				vertCount = vertCount + 6
			end
		end
	end

	return verts, vertCount
end


-------------------------------------------------------------------------------------
-- Forward cable rendering via DrawWorldPreUnit.
-- Vertex shader resamples heightmap each frame so cables follow terraform.
-- Fragment shader does its own diffuse+specular lighting on a synthesized
-- cylinder normal, plus traveling energy pulses gated by LOS ($info).
-------------------------------------------------------------------------------------

local cableVSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (location = 0) in vec3 vertPos;
layout (location = 1) in vec3 vertData;
layout (location = 2) in vec2 vertUV;
layout (location = 3) in vec2 vertPerp;
layout (location = 4) in vec2 vertTime;  // x = appearTime (s), y = witherTime (s, 0 = not withering)

uniform sampler2D heightmapTex;

out DataVS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 perp;
	vec2 timeData;
};

//__ENGINEUNIFORMBUFFERDEFS__

vec2 inverseMapSize = 1.0 / mapSize.xy;

float heightAtWorldPos(vec2 w) {
	const vec2 heightmaptexel = vec2(8.0, 8.0);
	w += vec2(-8.0, -8.0) * (w * inverseMapSize) + vec2(4.0, 4.0);
	vec2 uvhm = clamp(w, heightmaptexel, mapSize.xy - heightmaptexel);
	uvhm = uvhm * inverseMapSize;
	return textureLod(heightmapTex, uvhm, 0.0).x;
}

void main() {
	// Resample current ground height (so cables track terraform in real time)
	vec3 pos = vertPos;
	pos.y = heightAtWorldPos(vertPos.xz) + 2.0;

	worldPos = pos;
	capacity = vertData.x;
	isBranch = vertData.y;
	width = vertData.z;
	cableUV = vertUV;
	perp = vertPerp;
	timeData = vertTime;
	gl_Position = cameraViewProj * vec4(pos, 1.0);
}
]]

local cableFSSrc = [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

uniform sampler2D infoTex;
uniform float gameTime;

in DataVS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 perp;
	vec2 timeData;  // x = appearTime, y = witherTime (0 = not withering)
};

//__ENGINEUNIFORMBUFFERDEFS__

const float GROWTH_RATE = 250.0;  // elmos/s — must match unsynced GROWTH_RATE
const float WITHER_RATE = 400.0;

out vec4 fragColor;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
	float v = cableUV.y;
	float t = abs(v);
	if (t > 0.90) discard;

	// Visual grow/wither: cableUV.x is distance along cable in elmos.
	// Growth front advances from u=0 forward.
	float along = cableUV.x;
	float visibleFront = (gameTime - timeData.x) * GROWTH_RATE;
	if (along > visibleFront) discard;
	// Wither: tail eats forward from u=0 (witherTime > 0 means withering).
	if (timeData.y > 0.5) {
		float witherFront = (gameTime - timeData.y) * WITHER_RATE;
		if (along < witherFront) discard;
	}

	// Proper cylinder cross-section normal.
	// perp is the cross-section direction in world XZ (perpendicular to cable tangent).
	// At v=0 (cable center), normal points up (+Y).
	// At v=±1 (edges), normal points along perp × sign(v).
	// Interpolate via cylinder equation: up*sqrt(1-v²) + side*v
	vec3 perp3D = normalize(vec3(perp.x, 0.0, perp.y));
	float up = sqrt(max(0.0, 1.0 - v * v));
	vec3 cylNormal = normalize(vec3(0.0, up, 0.0) + perp3D * v);

	// Own lighting (forward rendered, no engine lighting applies)
	float diffuse = max(0.25, dot(cylNormal, normalize(sunDir.xyz)));

	// Specular
	vec3 viewDir = normalize(cameraViewInv[3].xyz - worldPos);
	vec3 halfDir = normalize(normalize(sunDir.xyz) + viewDir);
	float spec = pow(max(0.0, dot(cylNormal, halfDir)), 24.0) * 0.35;

	// Capacity-based color (green glow)
	float capT = clamp(capacity / 100.0, 0.0, 1.0);
	vec3 barkColor  = vec3(0.06, 0.04, 0.02);
	vec3 innerColor = mix(vec3(0.20, 0.55, 0.15), vec3(0.50, 0.80, 0.20), capT);

	float innerMix = smoothstep(0.85, 0.15, t);
	if (isBranch > 0.5) innerMix *= 0.7;
	vec3 baseColor = mix(barkColor, innerColor, innerMix);

	// Surface noise detail
	float surfN = hash(worldPos.xz * 0.5) * 0.04;
	baseColor += vec3(surfN);

	// LOS state (needed first for animation gating)
	vec2 losUV = clamp(worldPos.xz, vec2(0.0), mapSize.xy) / mapSize.zw;
	float losTexSample = dot(vec3(0.33), texture(infoTex, losUV).rgb);
	float losState = clamp(losTexSample * 4.0 - 1.0, 0.0, 1.0);
	float fullLOS = smoothstep(0.7, 1.0, losState);

	// Apply lighting
	vec3 color = baseColor * diffuse + vec3(1.0, 0.95, 0.85) * spec;

	// Traveling energy pulses along the cable.
	// "along" is already in scope from the grow/wither cut above.
	float pulseSpeed = 180.0;   // elmos/second
	float pulsePeriod = 500.0;  // elmos between pulses (spacing)
	float pulseWidth = 35.0;    // elmos (pulse extent)

	// Phase offset per cable branch (derived from perp direction so each cable differs)
	float phaseOffset = (perp.x * 17.3 + perp.y * 31.7) * 100.0;

	// Shift "along" backwards over time so pulses travel forward (+u direction)
	float shifted = along - gameTime * pulseSpeed + phaseOffset;
	float pulsePos = mod(shifted, pulsePeriod);

	// Gaussian falloff — bright bright pulse center, fades to edges
	float pulseIntensity = exp(-pulsePos * pulsePos / (pulseWidth * pulseWidth));

	// Second staggered pulse for richer pattern
	float shifted2 = along - gameTime * pulseSpeed * 0.7 + phaseOffset * 1.5 + pulsePeriod * 0.4;
	float pulsePos2 = mod(shifted2, pulsePeriod);
	pulseIntensity += exp(-pulsePos2 * pulsePos2 / (pulseWidth * pulseWidth)) * 0.6;

	// Pulse color: bright white-green core, more intense at cable center (innerMix)
	vec3 pulseColor = vec3(0.7, 1.0, 0.6);
	color += pulseColor * pulseIntensity * innerMix * fullLOS * 0.9;

	// LOS-aware dimming
	float dimFactor = mix(0.3, 1.0, smoothstep(0.3, 0.8, losState));
	color *= dimFactor;

	// FULLY OPAQUE output — like lava. No alpha blending.
	fragColor = vec4(color, 1.0);
}
]]

-------------------------------------------------------------------------------------
-- Receive data from synced
-------------------------------------------------------------------------------------

local function shouldAcceptForAlly(allyTeamID)
	local spec, fullview = spGetSpectatingState()
	local myAllyTeam = spGetMyAllyTeamID()
	if (spec or fullview) then return true end
	return allyTeamID == myAllyTeam
end

local function RebuildRenderEdges()
	renderEdges = {}
	for _, edges in pairs(edgesByAllyTeam) do
		for _, e in pairs(edges) do
			renderEdges[#renderEdges + 1] = e
		end
	end
end

-- In-place diff of the incoming Full snapshot against existing state:
-- survivors keep their appearFrame (no animation restart), missing edges
-- get marked withering, new edges get appearFrame = current frame.
local function OnCableTreeFull()
	local data = SYNCED.CableTreeFull
	if not data then return end
	local ally = data.allyTeamID
	if not shouldAcceptForAlly(ally) then return end

	local frame = Spring.GetGameFrame()
	local existing = edgesByAllyTeam[ally] or {}

	-- Build a fast lookup of incoming keys.
	local incoming = {}
	for i = 1, data.edgeCount do
		incoming[data.keys[i]] = i
	end

	-- Mark missing edges as withering (or leave them withering if already so).
	for k, e in pairs(existing) do
		if not incoming[k] and not e.witherFrame then
			e.witherFrame = frame
		end
	end

	-- Add new, refresh capacity on survivors.
	for k, i in pairs(incoming) do
		local e = existing[k]
		if e and not e.witherFrame then
			e.capacity = data.caps[i]
			-- positions are stable for unchanged edges; assign anyway in case parent moved
			e.px, e.pz = data.pxs[i], data.pzs[i]
			e.cx, e.cz = data.cxs[i], data.czs[i]
		else
			existing[k] = {
				px = data.pxs[i], pz = data.pzs[i],
				cx = data.cxs[i], cz = data.czs[i],
				capacity = data.caps[i],
				appearFrame = frame,
				witherFrame = nil,
			}
		end
	end

	edgesByAllyTeam[ally] = existing
	RebuildRenderEdges()
	needsRebuild = true
end

-------------------------------------------------------------------------------------
-- VBO rebuild
-------------------------------------------------------------------------------------

local function RebuildVBO()
	local verts, vertCount = GenerateOrganicTree()
	if vertCount == 0 then
		numCableVerts = 0
		needsRebuild = false
		return
	end

	cableVAO = nil
	local vbo = gl.GetVBO(GL.ARRAY_BUFFER, false)
	if not vbo then return end
	vbo:Define(vertCount, {
		{ id = 0, name = "vertPos",   size = 3 },
		{ id = 1, name = "vertData",  size = 3 },
		{ id = 2, name = "vertUV",    size = 2 },
		{ id = 3, name = "vertPerp",  size = 2 },
		{ id = 4, name = "vertTime",  size = 2 },
	})
	vbo:Upload(verts)
	cableVAO = gl.GetVAO()
	if cableVAO then cableVAO:AttachVertexBuffer(vbo) end
	numCableVerts = vertCount
	needsRebuild = false
end

-------------------------------------------------------------------------------------
-- Drawing via DrawWorldPreUnit (forward, opaque)
-------------------------------------------------------------------------------------

-- Conservative cap on how long a withering edge stays in geometry; the
-- fragment shader has already discarded its pixels long before this.
-- Worst case path length ~2000 elmos / 400 elmos/sec = 5s; pad to be safe.
local WITHER_HOLD_FRAMES = 8 * GAME_SPEED

function gadget:GameFrame(n)
	-- Drop fully-withered edges so geometry doesn't grow unboundedly.
	local dropped = false
	for ally, edges in pairs(edgesByAllyTeam) do
		for k, e in pairs(edges) do
			if e.witherFrame and (n - e.witherFrame) >= WITHER_HOLD_FRAMES then
				edges[k] = nil
				dropped = true
			end
		end
	end
	if dropped then
		RebuildRenderEdges()
		needsRebuild = true
	end

	if needsRebuild and n % 6 == 0 then
		RebuildVBO()
	end
end

function gadget:DrawWorldPreUnit()
	if not cableVAO or numCableVerts == 0 or not cableShader then return end

	cableShader:Activate()
	cableShader:SetUniform("gameTime", Spring.GetGameSeconds())

	gl.Texture(0, "$info")
	gl.Texture(1, "$heightmap")
	gl.Culling(false)
	gl.DepthTest(GL.LEQUAL)
	gl.DepthMask(true)
	gl.Blending(false)

	cableVAO:DrawArrays(GL.TRIANGLES, numCableVerts)

	cableShader:Deactivate()
	gl.Texture(0, false)
	gl.Texture(1, false)
	gl.DepthTest(false)
	gl.DepthMask(false)
	gl.Culling(GL.BACK)
end

-------------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------------

function gadget:Initialize()
	if not gl.CreateShader or not gl.GetVBO or not gl.GetVAO then
		gadgetHandler:RemoveGadget()
		return
	end

	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	local vsSrc = cableVSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	local fsSrc = cableFSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)

	cableShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
		uniformInt = {
			infoTex = 0,
			heightmapTex = 1,
		},
		uniformFloat = {
			gameTime = 0,
		},
	}, "Cable Forward Shader")

	if not cableShader:Initialize() then
		Spring.Echo("[CableTree] Shader compile failed")
		gadgetHandler:RemoveGadget()
		return
	end
	gadgetHandler:AddSyncAction("CableTreeFull", OnCableTreeFull)
end

function gadget:Shutdown()
	if cableShader then cableShader:Finalize() end
	cableVAO = nil
	gadgetHandler:RemoveSyncAction("CableTreeFull")
end

end -- UNSYNCED
