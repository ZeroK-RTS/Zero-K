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
local spGetUnitResources  = Spring.GetUnitResources

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

local SYNC_PERIOD       = 30    -- frames between grid sync (~1/s); also send cadence
local DEBUG_FLOW        = false -- echo per-edge capacity table on every Send (chatty)
-- Spanning-tree topology mode:
--   "euclidean"  visually-pleasing layout — every pair of pylons in the same
--                grid is a candidate edge (subject to MST_CANDIDATE_R), so
--                co-linear chains form naturally and long-range pylons don't
--                fan into stars. Cables may not match actual pylon-to-pylon
--                links the engine uses internally.
--   "realistic"  cables only between pylons whose pylon ranges actually reach
--                each other (the engine's own connectivity graph). Faithful
--                to physical wiring; can produce hub-fan stars and miss
--                trunk-sharing opportunities.
local MST_MODE          = "euclidean"

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

-- Cached MSTs per (ally, gridID): only rebuilt when membership of that grid
-- actually changes. SyncWithGrid composes the desired edge set from this cache.
local mstByGrid = {}                -- [gridKey] = { ally, gridID, edges = {ek = einfo} }

-- Grids that need a rebuild on the next SyncWithGrid call. Sync also adds
-- entries it discovers itself by diffing rules-params against lastGridNum.
local pendingGridDirty = {}         -- [gridKey] = { ally, gridID }

-- Flat unitID -> unitDefID map; saves the per-call ally scan in
-- ComputeMaxPotentials' nodeUnitDefID (which used to walk every ally's nodes
-- table per node per tick).
local nodeDefByUID = {}             -- [unitID] = unitDefID

-- mpCache: topology-stable cache used by ComputeMaxPotentials. Adjacency,
-- DFS visit order, parentInTree, per-component root, and *static* per-subtree
-- aggregates (Pmax, Dmax, plus wind-decomposed terms) are computed once per
-- topology and reused every tick. Per-tick the only work is: re-fetch live
-- draw rules-params, post-order accumulate subDcur, compute subPcur via the
-- wind formula, run min-cut math.
local mpCache = {
	valid = false,
}

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		nodes[allyTeamList[i]] = {}
	end
end

-- Runtime toggles, driven by the /cabletree chat command (see CableTreeCmd).
local cableEnabled = true
local cablePerf    = false

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

local function MarkGridDirty(ally, gridID)
	if not gridID or gridID <= 0 or not ally then return end
	local gk = GridKey(ally, gridID)
	if not pendingGridDirty[gk] then
		pendingGridDirty[gk] = { ally = ally, gridID = gridID }
	end
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

-- Current real production: any generator publishes "current_energyIncome"
-- (windgens, solar, fusion, singu — all set by unit_mex_overdrive each tick).
local function GetNodePcurrent(unitID, unitDefID)
	if not generatorDefs[unitDefID] then return 0 end
	return spGetUnitRulesParam(unitID, "current_energyIncome") or 0
end

-- Current real draw. Mexes consume via the overdrive system, which the
-- mex_overdrive gadget reports per-unit as "overdrive_energyDrain". Every
-- *other* pylon-tracked unit (strider hubs building units, factories,
-- firing turrets, charging weapons, …) reports its live consumption via
-- Spring.GetUnitResources().energyUse — so that's the right quantity to
-- treat as cable draw at the consumer end.
--
-- The two are mutually exclusive: mexes don't have direct energyUse for the
-- OD spend (the mex_overdrive gadget allocates from the team pool, not via
-- the mex's own use), and non-mex consumers don't have an
-- "overdrive_energyDrain" rules-param.
local function GetNodeDcurrent(unitID, unitDefID)
	if mexDefs[unitDefID] then
		return spGetUnitRulesParam(unitID, "overdrive_energyDrain") or 0
	end
	local _, _, _, eUse = spGetUnitResources(unitID)
	return eUse or 0
end

-------------------------------------------------------------------------------------
-- Per-grid Euclidean MST — Prim's where every pair within visual reach is a
-- candidate (no per-pylon range filter). Grid membership is whatever
-- unit_mex_overdrive decides; once "these N pylons are one grid", we lay the
-- shortest-total-cable spanning tree over them. This produces co-linear chains
-- and avoids hub-fan artifacts a long-range pylon would otherwise create.
-- The spatial hash still gates candidate pairs to a generous radius so very
-- large grids stay sub-quadratic; cell size is set large enough that any
-- realistic MST edge falls within a 3x3 cell neighbourhood.
-------------------------------------------------------------------------------------

local SPATIAL_CELL    = 2000  -- cell size; 3x3 neighbourhood covers ~4000 elmo pairs
local MST_CANDIDATE_R = 4000  -- hard cap on candidate-pair distance (squared below)

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

	-- Spatial hash bucket pylons by cell.
	local cells = {}
	for i = 1, #pylons do
		local p = pylons[i]
		local cx = floor(p.x / SPATIAL_CELL)
		local cz = floor(p.z / SPATIAL_CELL)
		local ck = cx * 100000 + cz
		if not cells[ck] then cells[ck] = {} end
		cells[ck][#cells[ck] + 1] = i
	end

	-- Neighbour list. In "euclidean" mode every pair within MST_CANDIDATE_R is
	-- a candidate (clean visual MST). In "realistic" mode we keep the engine's
	-- pylon-range filter (cables only where pylons can actually reach each
	-- other) — faithful to physical wiring.
	local rSq = MST_CANDIDATE_R * MST_CANDIDATE_R
	local euclidean = MST_MODE == "euclidean"
	local neighbors = {}
	for i = 1, #pylons do
		neighbors[i] = {}
		local p = pylons[i]
		local cx = floor(p.x / SPATIAL_CELL)
		local cz = floor(p.z / SPATIAL_CELL)
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
							local distSq = dx * dx + dz * dz
							local cap = euclidean and rSq
								or ((p.range + o.range) * (p.range + o.range))
							if distSq < cap then
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
-- Grid sync: snapshot every pylon's current gridNumber, rebuild every grid in
-- the snapshot, diff resulting edge set against `edges` so survivors keep
-- their stable identity (and unsynced animation state) while drops/adds flip
-- topologyDirty. Stateless w.r.t. previous gridIDs — robust against gridID
-- reuse, merges, splits, and rules-param resets we can't observe.
-------------------------------------------------------------------------------------

local function SyncWithGrid()
	-- 1) Drop dead units; mark their last-known grid dirty so its MST is
	--    rebuilt without them.
	for allyTeamID, allyNodes in pairs(nodes) do
		local toRemove
		for unitID, _ in pairs(allyNodes) do
			if not spValidUnitID(unitID) then
				toRemove = toRemove or {}
				toRemove[#toRemove + 1] = unitID
			end
		end
		if toRemove then
			for i = 1, #toRemove do
				local uid = toRemove[i]
				MarkGridDirty(allyTeamID, lastGridNum[uid])
				allyNodes[uid] = nil
				lastGridNum[uid] = nil
				allyOfUnit[uid] = nil
				nodeDefByUID[uid] = nil
			end
		end
	end

	-- 2) Refresh lastGridNum from rules-params and detect membership changes.
	--    Any pylon whose effective gridID flipped marks BOTH the old and new
	--    grid dirty (the old one because it lost a member, the new one
	--    because it gained one). Inactive pylons map to 0 and drop out.
	for allyTeamID, allyNodes in pairs(nodes) do
		for unitID, _ in pairs(allyNodes) do
			local newG = (IsActiveForGrid(unitID) and (spGetUnitRulesParam(unitID, "gridNumber") or 0)) or 0
			local oldG = lastGridNum[unitID]
			if oldG ~= newG then
				MarkGridDirty(allyTeamID, oldG)
				MarkGridDirty(allyTeamID, newG)
				lastGridNum[unitID] = newG
			end
		end
	end

	-- 3) Rebuild only dirty grids; everything else stays cached. An empty
	--    rebuild result (1 or 0 members → no MST edges) drops the grid from
	--    the cache entirely.
	for gk, info in pairs(pendingGridDirty) do
		local newMst = BuildGridMST(info.ally, info.gridID)
		if next(newMst) then
			mstByGrid[gk] = { ally = info.ally, gridID = info.gridID, edges = newMst }
		else
			mstByGrid[gk] = nil
		end
		pendingGridDirty[gk] = nil
	end

	-- 4) Compose the desired edge set from cached MSTs.
	local newEdges = {}
	for _, mst in pairs(mstByGrid) do
		for ek, einfo in pairs(mst.edges) do
			newEdges[ek] = einfo
		end
	end

	-- 5) Diff: drop missing, add new. Survivors keep their entry (and
	--    ComputeMaxPotentials reorientation) untouched. Topology change here
	--    invalidates the mpCache so its DFS / aggregates get rebuilt next call.
	for ek, _ in pairs(edges) do
		if not newEdges[ek] then
			edges[ek] = nil
			topologyDirty = true
			mpCache.valid = false
		end
	end
	for ek, einfo in pairs(newEdges) do
		if not edges[ek] then
			edges[ek] = {
				parentID = einfo.parentID, childID = einfo.childID,
				px = einfo.px, pz = einfo.pz, cx = einfo.cx, cz = einfo.cz,
			}
			topologyDirty = true
			mpCache.valid = false
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

-- Build the topology-stable mpCache: adjacency, DFS order, parentInTree,
-- per-component root, and *static* per-subtree aggregates.
--
-- Static aggregates per subtree (recomputed only on topology change):
--   subPmax        Σ nameplate production (windmill counts as windMax)
--   subDmax        Σ nameplate draw     (mexes = INF_DRAW, voltage units = neededlink)
--   subPmaxNonWind Σ nameplate production over non-wind generators only.
--                  Wind contribution to Pcur is computed per tick from
--                  subWindCount + subWindBase via the aggregate formula.
--   subWindCount   number of windmills in the subtree
--   subWindBase    Σ minWind (per-windmill rules-param, in absolute E/s).
--                  Combined with current wind strength to produce subPcur:
--                    windPcur = subWindBase + (curr/windMax) *
--                               (windMax * subWindCount - subWindBase)
--                  This eliminates per-windmill rules-param reads on the hot
--                  path: one Spring.GetWind() suffices for the whole tick.
local function BuildMpCache()
	local adj = {}
	local nodeSet = {}
	for key, edge in pairs(edges) do
		local a, b = edge.parentID, edge.childID
		adj[a] = adj[a] or {}; adj[a][#adj[a] + 1] = { neigh = b, key = key }
		adj[b] = adj[b] or {}; adj[b][#adj[b] + 1] = { neigh = a, key = key }
		nodeSet[a] = true
		nodeSet[b] = true
	end

	local parentInTree = {}
	local order = {}
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
				local did = nodeDefByUID[v]
				local p = did and GetNodePmax(did) or 0
				if p > bestP then bestP = p; bestID = v end
			end
			dfsRoot(bestID)
		end
	end

	-- componentRoot is computable in one forward pass over `order` because
	-- each parent appears earlier than its child in DFS order.
	local componentRoot = {}
	for i = 1, #order do
		local u = order[i]
		local pi = parentInTree[u]
		if not pi then
			componentRoot[u] = u
		else
			componentRoot[u] = componentRoot[pi.parent]
		end
	end

	-- Static per-subtree aggregates (post-order over `order`).
	local subPmax = {}
	local subDmax = {}
	local subPmaxNonWind = {}
	local subWindCount = {}
	local subWindBase = {}
	for i = 1, #order do
		local u = order[i]
		local did = nodeDefByUID[u]
		subPmax[u] = did and GetNodePmax(did) or 0
		subDmax[u] = did and GetNodeDmax(did) or 0
		if did and isWindgenByDef[did] then
			subWindCount[u] = 1
			subWindBase[u] = spGetUnitRulesParam(u, "minWind") or 0
			subPmaxNonWind[u] = 0
		else
			subWindCount[u] = 0
			subWindBase[u] = 0
			subPmaxNonWind[u] = (did and pmaxByDef[did]) or 0
		end
	end
	for i = #order, 1, -1 do
		local u = order[i]
		local pi = parentInTree[u]
		if pi then
			local p = pi.parent
			subPmax[p]        = subPmax[p]        + subPmax[u]
			subDmax[p]        = subDmax[p]        + subDmax[u]
			subPmaxNonWind[p] = subPmaxNonWind[p] + subPmaxNonWind[u]
			subWindCount[p]   = subWindCount[p]   + subWindCount[u]
			subWindBase[p]    = subWindBase[p]    + subWindBase[u]
		end
	end

	mpCache.adj            = adj
	mpCache.parentInTree   = parentInTree
	mpCache.order          = order
	mpCache.componentRoot  = componentRoot
	mpCache.subPmax        = subPmax
	mpCache.subDmax        = subDmax
	mpCache.subPmaxNonWind = subPmaxNonWind
	mpCache.subWindCount   = subWindCount
	mpCache.subWindBase    = subWindBase
	mpCache.valid          = true
end

local function ComputeMaxPotentials()
	if not mpCache.valid then BuildMpCache() end
	local order          = mpCache.order
	local parentInTree   = mpCache.parentInTree
	local componentRoot  = mpCache.componentRoot
	local subPmax        = mpCache.subPmax
	local subDmax        = mpCache.subDmax
	local subPmaxNonWind = mpCache.subPmaxNonWind
	local subWindCount   = mpCache.subWindCount
	local subWindBase    = mpCache.subWindBase

	-- Per-tick wind globals: one read each, then everything is arithmetic.
	local windMax = Spring.GetGameRulesParam("WindMax") or 2.5
	local _, _, _, currStrength = Spring.GetWind()
	currStrength = currStrength or 0
	local windFrac = (windMax > 0) and (currStrength / windMax) or 0
	if windFrac < 0 then windFrac = 0 elseif windFrac > 1 then windFrac = 1 end

	-- subPcur derived directly from cached aggregates — no per-node Pcur read.
	-- Wind: linear-in-strength sum collapses to (1-f)*base + f*windMax*N.
	-- Non-wind generators in MST are assumed to be producing nameplate
	-- (any inactive generator has gridID=0 and so isn't in the cached tree).
	local subPcur = {}
	for i = 1, #order do
		local u = order[i]
		subPcur[u] = subWindBase[u] + windFrac * (windMax * subWindCount[u] - subWindBase[u])
			+ subPmaxNonWind[u]
	end

	-- subDcur DOES still need per-node reads — mex draw and turret
	-- consumption fluctuate per tick and are not derivable from anything
	-- topology-cached.
	local subDcur = {}
	for i = 1, #order do
		local u = order[i]
		local did = nodeDefByUID[u]
		subDcur[u] = did and GetNodeDcurrent(u, did) or 0
	end
	for i = #order, 1, -1 do
		local u = order[i]
		local pi = parentInTree[u]
		if pi then
			subDcur[pi.parent] = subDcur[pi.parent] + subDcur[u]
		end
	end

	-- Per-edge min-cut math + reorientation. Component root is precomputed
	-- so we don't walk parent chains per edge.
	local capacities = {}
	local flows = {}
	local debugLog = DEBUG_FLOW and {} or nil
	local function fmtD(v) return v >= INF_DRAW * 0.5 and "INF" or string.format("%.0f", v) end

	for cid, info in pairs(parentInTree) do
		local key = info.key
		local pid = info.parent
		local r = componentRoot[cid]

		local totalP, totalD = subPmax[r], subDmax[r]
		local sP, sD = subPmax[cid], subDmax[cid]
		local oP, oD = totalP - sP, totalD - sD
		local capAB = (sP < oD) and sP or oD
		local capBA = (oP < sD) and oP or sD
		local cap = (capAB > capBA) and capAB or capBA
		capacities[key] = cap
		local potentialSrcSubtree = capAB > capBA

		local totalPcur, totalDcur = subPcur[r], subDcur[r]
		local sPc, sDc = subPcur[cid], subDcur[cid]
		local oPc, oDc = totalPcur - sPc, totalDcur - sDc
		local flowAB = (sPc < oDc) and sPc or oDc
		local flowBA = (oPc < sDc) and oPc or sDc
		local flow, flowSrcSubtree
		if flowAB >= flowBA then
			flow, flowSrcSubtree = flowAB, true
		else
			flow, flowSrcSubtree = flowBA, false
		end
		if flow < 0 then flow = 0 end
		if flow <= 0 then flowSrcSubtree = potentialSrcSubtree end
		flows[key] = flow

		local edge = edges[key]
		if edge then
			local newParent = flowSrcSubtree and cid or pid
			local newChild  = flowSrcSubtree and pid or cid
			if edge.parentID ~= newParent then
				local pAlly = allyOfUnit[newParent]
				local cAlly = allyOfUnit[newChild]
				local np = pAlly and nodes[pAlly] and nodes[pAlly][newParent]
				local nc = cAlly and nodes[cAlly] and nodes[cAlly][newChild]
				if np and nc then
					edge.parentID, edge.childID = newParent, newChild
					edge.px, edge.pz = np.x, np.z
					edge.cx, edge.cz = nc.x, nc.z
				end
			end
		end

		if debugLog then
			local e = edges[key]
			local pname = nodeDefByUID[e.parentID] and UnitDefs[nodeDefByUID[e.parentID]].name or tostring(e.parentID)
			local cname = nodeDefByUID[e.childID]  and UnitDefs[nodeDefByUID[e.childID]].name  or tostring(e.childID)
			debugLog[#debugLog + 1] = string.format(
				"  %-13s -> %-13s  sP=%-7.1f sD=%-5s oP=%-7.1f oD=%-5s  cap=%.1f flow=%.1f",
				pname, cname, sP, fmtD(sD), oP, fmtD(oD), cap, flow)
		end
	end

	if debugLog and #debugLog > 0 then
		Spring.Echo("[OD-cables] capacities:")
		for i = 1, #debugLog do Spring.Echo(debugLog[i]) end
	end

	return capacities, flows
end

-------------------------------------------------------------------------------------
-- Send state to unsynced. One Full snapshot per ally, only when topology changed.
-- Capacity drift between topology changes is ignored (acceptable: cable colour
-- only updates when the grid actually mutates).
-------------------------------------------------------------------------------------

local function SendAll()
	local capacities, flows = ComputeMaxPotentials()

	-- Bin edges by ally, in one pass.
	local perAlly = {}
	for key, edge in pairs(edges) do
		local ally = allyOfUnit[edge.parentID] or allyOfUnit[edge.childID]
		if ally then
			local pa = perAlly[ally]
			if not pa then
				pa = {
					keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {},
					caps = {}, flows = {}, effs = {}, n = 0,
				}
				perAlly[ally] = pa
			end
			pa.n = pa.n + 1
			local i = pa.n
			pa.keys[i] = key
			pa.pxs[i], pa.pzs[i] = edge.px, edge.pz
			pa.cxs[i], pa.czs[i] = edge.cx, edge.cz
			pa.caps[i]  = capacities[key] or 0
			pa.flows[i] = flows[key] or 0
			-- Grid efficiency (E/M ratio) is uniform across a grid; read it from
			-- the parent end. Negative means "no grid" (sentinel from
			-- unit_mex_overdrive); we forward 0 in that case → magenta in shader.
			local eff = spGetUnitRulesParam(edge.parentID, "gridefficiency")
				or spGetUnitRulesParam(edge.childID, "gridefficiency") or 0
			if eff < 0 then eff = 0 end
			pa.effs[i] = eff
		end
	end

	-- Fire one message per ally that currently has edges.
	for ally, pa in pairs(perAlly) do
		_G.CableTreeFull = {
			allyTeamID = ally, edgeCount = pa.n,
			keys = pa.keys, pxs = pa.pxs, pzs = pa.pzs,
			cxs = pa.cxs, czs = pa.czs,
			caps = pa.caps, flows = pa.flows, effs = pa.effs,
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
				keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {},
				caps = {}, flows = {}, effs = {},
			}
			SendToUnsynced("CableTreeFull")
			alliesWithEdges[ally] = nil
		end
	end
end

-------------------------------------------------------------------------------------
-- GameFrame
-------------------------------------------------------------------------------------

-- Sends one zero-edge snapshot per ally that currently has cables, so the
-- unsynced side clears its geometry. Used when the visualization is toggled
-- off so no stale cables linger.
local function ClearAll()
	for ally in pairs(alliesWithEdges) do
		_G.CableTreeFull = {
			allyTeamID = ally, edgeCount = 0,
			keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {},
			caps = {}, flows = {}, effs = {},
		}
		SendToUnsynced("CableTreeFull")
	end
	alliesWithEdges = {}
	edges = {}
	topologyDirty = false
end

function gadget:GameFrame(n)
	if not cableEnabled then return end
	if n % SYNC_PERIOD == 2 then
		SyncWithGrid()
		-- Always send: flow magnitudes and grid efficiency colour change every
		-- tick, so unsynced needs the periodic refresh even when topology is
		-- unchanged. Diff cost on the unsynced side is cheap (key lookup +
		-- attribute upload); geometry only re-generates when keys change.
		SendAll()
		topologyDirty = false
		-- Synced has no timing API (Spring.GetTimer is unsynced-only, and the
		-- sandbox doesn't expose `os`). Just report the edge count from here;
		-- the real cost numbers come from the unsynced rebuild log, which
		-- captures the heavier path (geometry + VBO upload).
		if cablePerf then
			local nEdges = 0
			for _ in pairs(edges) do nEdges = nEdges + 1 end
			Spring.Echo(string.format("[CableTree] sync edges=%d", nEdges))
		end
	end
end

-- /cabletree              — toggle on/off
-- /cabletree on / off     — explicit
-- /cabletree perf         — toggle per-cycle timing log
-- /cabletree status       — print current state
local function CableTreeCmd(cmd, line, words, playerID)
	local arg = (words and words[1]) or ""
	if arg == "" or arg == "toggle" then
		cableEnabled = not cableEnabled
		if not cableEnabled then ClearAll() end
		Spring.Echo("[CableTree] " .. (cableEnabled and "ON" or "OFF"))
	elseif arg == "on" then
		cableEnabled = true
		Spring.Echo("[CableTree] ON")
	elseif arg == "off" then
		cableEnabled = false
		ClearAll()
		Spring.Echo("[CableTree] OFF")
	elseif arg == "perf" then
		cablePerf = not cablePerf
		_G.CableTreePerf = { perf = cablePerf }
		SendToUnsynced("CableTreePerf")
		Spring.Echo("[CableTree] perf logging " .. (cablePerf and "ON" or "OFF"))
	elseif arg == "status" then
		local nEdges = 0
		for _ in pairs(edges) do nEdges = nEdges + 1 end
		Spring.Echo(string.format(
			"[CableTree] enabled=%s perf=%s edges=%d",
			tostring(cableEnabled), tostring(cablePerf), nEdges))
	else
		Spring.Echo("[CableTree] usage: /cabletree [on|off|toggle|perf|status]")
	end
	return true
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
	nodeDefByUID[unitID] = unitDefID
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
		-- Old ally's grid loses a member: dirty it before we forget which
		-- grid this unit was in.
		MarkGridDirty(oldAlly, lastGridNum[unitID])
		if nodes[oldAlly] then nodes[oldAlly][unitID] = nil end
		lastGridNum[unitID] = nil
		allyOfUnit[unitID] = nil
		nodeDefByUID[unitID] = nil
		if nodes[newAlly] then
			local x, _, z = spGetUnitPosition(unitID)
			nodes[newAlly][unitID] = {
				x = x, z = z,
				range = pylonDefs[unitDefID],
				unitDefID = unitDefID,
			}
			allyOfUnit[unitID] = newAlly
			nodeDefByUID[unitID] = unitDefID
		end
	end
end

function gadget:Initialize()
	GG.CableTree = { nodes = nodes, edges = edges }
	gadgetHandler:AddChatAction("cabletree", CableTreeCmd)
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
			nodeDefByUID[unitID] = unitDefID
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
-- Noise amplitude is in absolute elmos (not a fraction of cable width). Tying
-- it to width made thick trunks visibly more wobbly than thin twigs, which is
-- the opposite of the intended look (a thick trunk should read as "stable").
local NOISE_AMP_ABS    = 1.0
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

-- Bubble speed mapping — must mirror the formula in the fragment shader. We
-- integrate phase = ∫ speed(t) dt CPU-side per edge, so speed changes don't
-- jump bubbles across the cable; the shader just extrapolates from the last
-- anchor with the current speed.
local BUBBLE_FLOW_REF  = 80
local BUBBLE_MAX_SPEED = 220
local function flowToSpeed(flow)
	if not flow or flow < 0 then return 0 end
	local n = flow / BUBBLE_FLOW_REF
	if n > 1.6 then n = 1.6 end
	return BUBBLE_MAX_SPEED * n
end

-------------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------------

-- edgesByAllyTeam[ally][edgeKey] = { px, pz, cx, cz, capacity, appearFrame, witherFrame }
local edgesByAllyTeam = {}
local renderEdges = {}
local renderEdgesByKey = {}    -- flat lookup: edgeKey -> renderEdge entry
local needsRebuild = false

-- Geometry cache. Topology-stable rebuilds reuse `allPaths` (the noisy paths,
-- twigs and cluster stems). Per-call, we walk the prov objects (one per
-- emitNoisyPath invocation) and refresh just the dynamic fields (flow, eff,
-- bubblePhase, appearFrame, witherFrame) from the current renderEdges.
-- Vert emission then re-reads from prov.
--
-- Invalidated by: new edge in OnCableTreeFull, edge marked withering,
-- withering edge dropped in GameFrame, cluster sign-flip during refresh.
local geomCache = {
	valid = false,
	allPaths = nil,       -- [{ points, widths, capacity, isBranch, prov }]
	provs = nil,          -- [provObj] (distinct, one per emitNoisyPath call)
}

local cableShader       -- forward shader for cable rendering
local cableVAO          -- live cable geometry
local numCableVerts = 0
local drawPerf = false  -- toggled by the synced /cabletree perf command
-- Game-second timestamp captured the moment the current VBO's bubblePhase
-- snapshots were taken. The shader extrapolates each cable's phase forward
-- from this anchor using `phase = bakedPhase + flowToSpeed(flow) * (gameTime
-- - bakeTime)`, which means flow changes update the rate of advance without
-- ever teleporting the bubbles.
local bubbleBakeTime = 0

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
	-- Cap effective amplitude by a fraction of the segment length: very short
	-- cables shouldn't get the same wiggle as long ones.
	local effAmp = amplitude
	if len < 80 then effAmp = amplitude * (len / 80) end
	for i = 0, steps do
		local t = i / steps
		local px = x1 + t * dx
		local pz = z1 + t * dz
		local noiseScale = 1
		if t < 0.1 then noiseScale = t / 0.1
		elseif t > 0.9 then noiseScale = (1 - t) / 0.1 end
		local n = Hash(px * 0.1, pz * 0.1, seed) * effAmp * noiseScale
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
-- Generic angle clustering: groups items whose angles are within MERGE_ANGLE
-- of an immediate neighbour (after sorting). Handles wrap-around.
local function clusterByAngle(items)
	if #items == 0 then return {} end
	table.sort(items, function(a, b) return (a.angle or 0) < (b.angle or 0) end)
	local clusters = { { items[1] } }
	for i = 2, #items do
		local cur = clusters[#clusters]
		if abs(normalizeAngle(items[i].angle - items[i-1].angle)) < MERGE_ANGLE then
			cur[#cur + 1] = items[i]
		else
			clusters[#clusters + 1] = { items[i] }
		end
	end
	if #clusters > 1 then
		local first, last = clusters[1], clusters[#clusters]
		if abs(normalizeAngle(first[1].angle - last[#last].angle)) < MERGE_ANGLE then
			for i = 1, #last do first[#first + 1] = last[i] end
			clusters[#clusters] = nil
		end
	end
	return clusters
end

-- Phase 1: heavy build. Walks renderEdges, clusters per-node, emits noisy
-- paths + twigs + cluster stems. Each `emitNoisyPath` call produces one or
-- more allPaths entries that all share a single `prov` object — the prov
-- carries the dynamic fields (flow/eff/bubblePhase/appear/wither) and is
-- refreshed in-place on cache-hit calls so we don't need to regenerate
-- geometry on every send.
local function BuildAllPaths()
	local allPaths = {}
	local provs = {}

	local nodePos = {}
	-- Undirected adjacency: every edge contributes one entry to each endpoint.
	-- `side` is 1 for parent end, 2 for child end (used so each edge ends up
	-- with one attach point on each side after clustering).
	local nodeNeighbors = {}

	local function posKey(x, z)
		return floor(x) .. ":" .. floor(z)
	end

	for i = 1, #renderEdges do
		local e = renderEdges[i]
		local pk = posKey(e.px, e.pz)
		local ck = posKey(e.cx, e.cz)
		nodePos[pk] = { x = e.px, z = e.pz }
		nodePos[ck] = { x = e.cx, z = e.cz }
		nodeNeighbors[pk] = nodeNeighbors[pk] or {}
		nodeNeighbors[ck] = nodeNeighbors[ck] or {}
		local cap = max(1, e.capacity)
		nodeNeighbors[pk][#nodeNeighbors[pk] + 1] = {
			nKey = ck, edgeIdx = i, side = 1, cap = cap,
		}
		nodeNeighbors[ck][#nodeNeighbors[ck] + 1] = {
			nKey = pk, edgeIdx = i, side = 2, cap = cap,
		}
	end

	local function emitNoisyPath(x1, z1, x2, z2, widthStart, widthEnd, capacity, seed, isBranch, prov)
		local path = NoisyPath(x1, z1, x2, z2, NOISE_AMP_ABS, seed)
		local widths = {}
		for pi = 1, #path do
			local t = (pi - 1) / max(1, #path - 1)
			widths[pi] = widthStart + t * (widthEnd - widthStart)
		end
		allPaths[#allPaths + 1] = {
			points = path, widths = widths,
			capacity = capacity, isBranch = isBranch and 1 or 0,
			prov = prov,
		}
		-- Twigs: spawn from ribbon edge, not center. They share the parent's
		-- prov so dynamic fields stay consistent across the visual cluster.
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

				local perpX = -dz / pathLen * side
				local perpZ =  dx / pathLen * side
				local edgeX = p1.x + perpX * w * 0.45
				local edgeZ = p1.z + perpZ * w * 0.45

				local bx2 = edgeX + cos(angle) * bLen
				local bz2 = edgeZ + sin(angle) * bLen
				local bw = w * BRANCH_WIDTH * (isBranch and 0.6 or 1.0)
				local twigPts = NoisyPath(edgeX, edgeZ, bx2, bz2, NOISE_AMP_ABS * 0.7, tseed + 10)
				local twigWidths = {}
				twigWidths[1] = min(bw, w * 0.4)
				for ti = 2, #twigPts do
					local tt = (ti - 1) / max(1, #twigPts - 1)
					twigWidths[ti] = twigWidths[1] * (1 - tt * 0.8)
				end
				allPaths[#allPaths + 1] = {
					points = twigPts, widths = twigWidths,
					capacity = capacity, isBranch = 1,
					prov = prov,
				}
			end
		end
	end

	-- For each node, cluster all incident half-edges by direction. A cluster
	-- of >=2 emits a stem cable from the node along the cluster's average
	-- direction; every edge in that cluster gets the stem-end as its attach
	-- point on this side. Singletons attach directly at the node.
	local edgeAttach = {}
	for nk, nbrs in pairs(nodeNeighbors) do
		local pos = nodePos[nk]
		for i = 1, #nbrs do
			local n = nbrs[i]
			local npos = nodePos[n.nKey]
			if npos then
				n.angle = atan2(npos.z - pos.z, npos.x - pos.x)
				n.dist = sqrt((npos.x - pos.x)^2 + (npos.z - pos.z)^2)
			end
		end
		local clusters = clusterByAngle(nbrs)
		for ci = 1, #clusters do
			local cluster = clusters[ci]
			if #cluster == 1 then
				local n = cluster[1]
				edgeAttach[n.edgeIdx] = edgeAttach[n.edgeIdx] or {}
				edgeAttach[n.edgeIdx][n.side] = { x = pos.x, z = pos.z, hasStem = false }
			else
				-- Aggregate cluster geometry. Dynamic fields are computed once
				-- here for the initial prov; refresh path will re-read them
				-- from renderEdgesByKey via prov.members on cache-hit calls.
				local avgCos, avgSin, clusterCap, minDist = 0, 0, 0, math.huge
				local clusterFlow = 0
				local netFlowSigned = 0
				local effSum, capForEff = 0, 0
				local phaseSum = 0
				local stemAppear = math.huge
				local stemWither = -math.huge
				local allWither = true
				local members = {}
				for i = 1, #cluster do
					local n = cluster[i]
					local re = renderEdges[n.edgeIdx]
					local f = re.flow or 0
					local effv = re.eff or 0
					local phasev = re.bubblePhase or 0
					avgCos = avgCos + cos(n.angle)
					avgSin = avgSin + sin(n.angle)
					clusterCap = clusterCap + n.cap
					clusterFlow = clusterFlow + f
					-- side=1 → this node is the parent (source) → flow leaves
					-- side=2 → this node is the child (sink)   → flow enters
					netFlowSigned = netFlowSigned + ((n.side == 1) and f or -f)
					effSum = effSum + effv * n.cap
					phaseSum = phaseSum + phasev * n.cap
					capForEff = capForEff + n.cap
					if n.dist and n.dist < minDist then minDist = n.dist end
					local af = re.appearFrame or 0
					if af < stemAppear then stemAppear = af end
					if re.witherFrame then
						if re.witherFrame > stemWither then stemWither = re.witherFrame end
					else
						allWither = false
					end
					members[#members + 1] = { key = re.key, side = n.side, cap = n.cap }
				end
				if stemAppear == math.huge then stemAppear = 0 end
				local stemWitherFinal = (allWither and stemWither > -math.huge) and stemWither or nil
				local avgAngle = atan2(avgSin, avgCos)
				local stemLen = min(minDist * STEM_FRACTION, 120)
				if stemLen < 4 then stemLen = 4 end
				local stemX = pos.x + cos(avgAngle) * stemLen
				local stemZ = pos.z + sin(avgAngle) * stemLen
				local stemW = GetTrunkWidth(clusterCap)
				local outward = netFlowSigned >= 0

				local prov = {
					kind = "stem",
					members = members,
					capForEff = capForEff,
					outward = outward,
					flow = clusterFlow,
					eff = (capForEff > 0) and (effSum / capForEff) or 0,
					bubblePhase = (capForEff > 0) and (phaseSum / capForEff) or 0,
					appearFrame = stemAppear,
					witherFrame = stemWitherFinal,
				}
				provs[#provs + 1] = prov

				if outward then
					emitNoisyPath(pos.x, pos.z, stemX, stemZ,
						stemW, stemW * 0.9, clusterCap,
						pos.x + pos.z + ci * 7.3, false, prov)
				else
					emitNoisyPath(stemX, stemZ, pos.x, pos.z,
						stemW * 0.9, stemW, clusterCap,
						pos.x + pos.z + ci * 7.3, false, prov)
				end

				for i = 1, #cluster do
					local n = cluster[i]
					edgeAttach[n.edgeIdx] = edgeAttach[n.edgeIdx] or {}
					edgeAttach[n.edgeIdx][n.side] = {
						x = stemX, z = stemZ, hasStem = true, stemW = stemW,
					}
				end
			end
		end
	end

	-- Emit each edge once between its two attach points. attach[1] is the
	-- parent (source) end and attach[2] is the child (sink) end, so emitting
	-- attach[1] -> attach[2] makes pulses travel in the +u direction = actual
	-- direction of energy flow.
	for i = 1, #renderEdges do
		local e = renderEdges[i]
		local attach = edgeAttach[i]
		if attach and attach[1] and attach[2] then
			local cap = max(1, e.capacity)
			local edgeW = GetTrunkWidth(cap)
			local function endWidth(a)
				if a.hasStem then return min(edgeW * 1.2, a.stemW * 0.55) end
				return edgeW
			end
			local startW = endWidth(attach[1])
			local endW   = endWidth(attach[2])
			local seed = attach[1].x * 0.137 + attach[1].z * 0.781
				+ attach[2].x * 0.293 + attach[2].z * 0.461
			local prov = {
				kind = "edge",
				key = e.key,
				flow = e.flow or 0, eff = e.eff or 0,
				bubblePhase = e.bubblePhase or 0,
				appearFrame = e.appearFrame, witherFrame = e.witherFrame,
			}
			provs[#provs + 1] = prov
			emitNoisyPath(attach[1].x, attach[1].z, attach[2].x, attach[2].z,
				startW, endW, cap, seed, false, prov)
		end
	end

	return allPaths, provs
end

-- Phase 2: refresh dynamic fields on cached provs from the current
-- renderEdgesByKey. A cluster sign-flip (net flow direction reversed)
-- invalidates the cache so the next call regenerates with the correct
-- emission direction.
local function RefreshProvs(provs)
	for i = 1, #provs do
		local p = provs[i]
		if p.kind == "edge" then
			local e = renderEdgesByKey[p.key]
			if e then
				p.flow = e.flow or 0
				p.eff  = e.eff or 0
				p.bubblePhase = e.bubblePhase or 0
				p.appearFrame = e.appearFrame
				p.witherFrame = e.witherFrame
			end
		else
			local clusterFlow = 0
			local netFlowSigned = 0
			local effSum, phaseSum = 0, 0
			local stemAppear, stemWither = math.huge, -math.huge
			local allWither = true
			local members = p.members
			for j = 1, #members do
				local m = members[j]
				local e = renderEdgesByKey[m.key]
				if e then
					local f = e.flow or 0
					clusterFlow = clusterFlow + f
					netFlowSigned = netFlowSigned + ((m.side == 1) and f or -f)
					effSum = effSum + (e.eff or 0) * m.cap
					phaseSum = phaseSum + (e.bubblePhase or 0) * m.cap
					local af = e.appearFrame or 0
					if af < stemAppear then stemAppear = af end
					if e.witherFrame then
						if e.witherFrame > stemWither then stemWither = e.witherFrame end
					else
						allWither = false
					end
				end
			end
			if (netFlowSigned >= 0) ~= p.outward then
				geomCache.valid = false
			end
			p.flow = clusterFlow
			p.eff = (p.capForEff > 0) and (effSum / p.capForEff) or 0
			p.bubblePhase = (p.capForEff > 0) and (phaseSum / p.capForEff) or 0
			if stemAppear == math.huge then stemAppear = 0 end
			p.appearFrame = stemAppear
			p.witherFrame = (allWither and stemWither > -math.huge) and stemWither or nil
		end
	end
end

-- Phase 3: convert cached paths to triangle vertices. Reads dynamic fields
-- from path.prov (refreshed per-call). All other per-vertex data is purely
-- a function of (points, widths) and stays constant across cache-hit calls.
local function EmitVerts(allPaths)
	local verts = {}
	local vertCount = 0

	for pi = 1, #allPaths do
		local path = allPaths[pi]
		local pts = path.points
		local wds = path.widths
		local cap = path.capacity
		local branch = path.isBranch
		local prov = path.prov
		local appearTime = (prov.appearFrame or 0) / GAME_SPEED
		local witherTime = prov.witherFrame and (prov.witherFrame / GAME_SPEED) or 0
		local pathEff   = prov.eff or 0
		local pathFlow  = prov.flow or 0
		local pathPhase = prov.bubblePhase or 0

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
				verts[#verts+1]=pathEff; verts[#verts+1]=pathFlow; verts[#verts+1]=pathPhase
				verts[#verts+1]=R1.x; verts[#verts+1]=R1.y; verts[#verts+1]=R1.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w1
				verts[#verts+1]=u1; verts[#verts+1]=1
				verts[#verts+1]=p1x; verts[#verts+1]=p1z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=pathEff; verts[#verts+1]=pathFlow; verts[#verts+1]=pathPhase
				verts[#verts+1]=R2.x; verts[#verts+1]=R2.y; verts[#verts+1]=R2.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w2
				verts[#verts+1]=u2; verts[#verts+1]=1
				verts[#verts+1]=p2x; verts[#verts+1]=p2z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=pathEff; verts[#verts+1]=pathFlow; verts[#verts+1]=pathPhase

				-- Tri 2: L1, R2, L2
				verts[#verts+1]=L1.x; verts[#verts+1]=L1.y; verts[#verts+1]=L1.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w1
				verts[#verts+1]=u1; verts[#verts+1]=-1
				verts[#verts+1]=p1x; verts[#verts+1]=p1z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=pathEff; verts[#verts+1]=pathFlow; verts[#verts+1]=pathPhase
				verts[#verts+1]=R2.x; verts[#verts+1]=R2.y; verts[#verts+1]=R2.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w2
				verts[#verts+1]=u2; verts[#verts+1]=1
				verts[#verts+1]=p2x; verts[#verts+1]=p2z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=pathEff; verts[#verts+1]=pathFlow; verts[#verts+1]=pathPhase
				verts[#verts+1]=L2.x; verts[#verts+1]=L2.y; verts[#verts+1]=L2.z
				verts[#verts+1]=cap; verts[#verts+1]=brVal; verts[#verts+1]=w2
				verts[#verts+1]=u2; verts[#verts+1]=-1
				verts[#verts+1]=p2x; verts[#verts+1]=p2z
				verts[#verts+1]=appearTime; verts[#verts+1]=witherTime
				verts[#verts+1]=pathEff; verts[#verts+1]=pathFlow; verts[#verts+1]=pathPhase

				vertCount = vertCount + 6
			end
		end
	end

	return verts, vertCount
end

-- Top-level entrypoint. On topology-stable rebuilds, walks the cached provs
-- to refresh dynamic fields and re-emits verts using cached path geometry —
-- no NoisyPath, no clustering, no twig generation. On topology change,
-- rebuilds allPaths from scratch.
local function GenerateOrganicTree()
	if #renderEdges == 0 then
		geomCache.valid = false
		geomCache.allPaths = nil
		geomCache.provs = nil
		return {}, 0
	end

	if geomCache.valid then
		RefreshProvs(geomCache.provs)
	end
	-- RefreshProvs may flip geomCache.valid off if it detected a sign change.
	if not geomCache.valid then
		local allPaths, provs = BuildAllPaths()
		geomCache.allPaths = allPaths
		geomCache.provs = provs
		geomCache.valid = true
	end

	return EmitVerts(geomCache.allPaths)
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
layout (location = 5) in vec3 vertGrid;  // x = grid efficiency (E/M ratio), y = current flow (E/s), z = bubble phase at bake (elmos)

uniform sampler2D heightmapTex;

out DataVS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 perp;
	vec2 timeData;
	vec3 gridData;
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
	gridData = vertGrid;
	gl_Position = cameraViewProj * vec4(pos, 1.0);
}
]]

local cableFSSrc = [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

uniform sampler2D infoTex;
uniform float gameTime;
uniform float bakeTime;

in DataVS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 perp;
	vec2 timeData;  // x = appearTime, y = witherTime (0 = not withering)
	vec3 gridData;  // x = efficiency (E/M), y = flow (E/s), z = bubble phase at bake (elmos)
};

//__ENGINEUNIFORMBUFFERDEFS__

const float GROWTH_RATE = 250.0;  // elmos/s — must match unsynced GROWTH_RATE
const float WITHER_RATE = 400.0;

out vec4 fragColor;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float hash1(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// One layer of advecting bubbles drawn as world-space-round glassy spheroids.
// Density is fixed per layer (`spacing` constant); only `speed` changes with
// flow. Each bubble has hash-derived size + cross-axis offset jitter so the
// cable looks like bubbly fluid rather than a metronome.
//
// Crucially, distance is measured in actual world-space elmos in BOTH axes
// (along + cross), so bubbles are real circles regardless of cable thickness.
// `halfWidthE` is the cable cross half-extent in elmos at this fragment
// (= width * 0.5); `radiusE` is each bubble's target radius in elmos and is
// clamped so big bubbles fit inside thin cables instead of clipping to a
// stripe.
//
// Shading: faint inner glow + Fresnel rim + small offset highlight, all with
// smoothstep edges to avoid pixelation at oblique camera angles. Returns
// (body, specular).
// `phase` is the integrated travel distance baked + extrapolated by the
// caller (CPU integrates ∫ speed dt, shader extrapolates the last segment
// with the current speed). Subtracting from `along` advects bubbles smoothly
// across speed changes.
//
// Returns vec3: (body, specular, halo). Caller composites all three with
// possibly different colour weights for richer look.
vec3 bubbleLayer(float along, float phase, float spacing,
                 float radiusMax, float v, float halfWidthE, float layerSeed) {
	float along2 = along - phase;
	float idxLow  = floor(along2 / spacing);
	float coord   = along2 - idxLow * spacing;     // [0, spacing)
	float idxNear = (coord < spacing * 0.5) ? idxLow : (idxLow + 1.0);
	float dAlong  = (coord < spacing * 0.5) ? coord : (spacing - coord);

	float h1 = hash1(idxNear + layerSeed);
	float h2 = hash1(idxNear + layerSeed + 71.3);
	// Bubble radius in elmos. Random per bubble; clamped so it sits within
	// the cable cross-section even on thin twigs.
	float radiusE = radiusMax * (0.7 + 0.3 * h1);
	radiusE = min(radiusE, halfWidthE * 0.97);
	if (radiusE < 0.5) return vec3(0.0);

	// Cross-axis offset: in elmos, only as much margin as the cable can
	// afford. Skinny cables → bubble centred; chunky cables → bubble can
	// drift a little off-axis.
	float crossMargin = max(0.0, halfWidthE - radiusE);
	float yOffsetE    = (h2 - 0.5) * crossMargin * 1.0;

	float dCrossE = v * halfWidthE - yOffsetE;
	// Use the wider "halo radius" for the early-exit so the halo, which
	// extends past r=1, isn't truncated.
	float haloR = radiusE * 1.5;
	float r2H = (dAlong * dAlong + dCrossE * dCrossE) / (haloR * haloR);
	if (r2H >= 1.0) return vec3(0.0);

	float r2 = (dAlong * dAlong + dCrossE * dCrossE) / (radiusE * radiusE);
	float r  = sqrt(r2);
	float xn = dAlong / radiusE;
	float yn = dCrossE / radiusE;

	// Screen-space derivative AA. Keeps every smoothstep edge ~1 pixel wide
	// regardless of zoom; fixes thick-cable staircase pixelation.
	float aa = clamp(fwidth(r) * 1.4, 0.005, 0.20);

	// HOT CORE — Gaussian-style bright nucleus, peaks at r=0. Reads as
	// glowing plasma rather than a flat disc.
	float core = exp(-r2 * 4.5);
	core *= 1.0 - smoothstep(1.0 - aa, 1.0, r);

	// SHARP RIM — thin meniscus highlight near r ≈ 0.85.
	float rim = smoothstep(0.55 - aa, 0.85, r)
	          * (1.0 - smoothstep(0.85, 1.0 - aa * 0.4, r));
	rim *= 1.4;

	// SPECULAR — small bright dot offset toward the light direction.
	vec2 hd = vec2(xn + 0.32, yn + 0.42);
	float hr = length(hd);
	float spec = 1.0 - smoothstep(0.0, 0.22 + aa, hr);
	spec *= spec * spec;   // cubed → very sharp

	// HALO — soft additive bloom outside the bubble's hard edge. Extends
	// from r=0 out to r=1.5 with a gentle Gaussian falloff.
	float halo = exp(-r2 * 0.9) * 0.45;

	return vec3(core + rim, spec, halo);
}

// HSL → RGB at S=1, L=0.5 — matches LuaUI/Headers/overdrive.lua's GetGridColor
// (hue is the same triangle wave used for the panel/grid colour). Hue in [0,1).
vec3 hueToRgb(float h) {
	h = fract(h);
	float r = clamp(abs(h * 6.0 - 3.0) - 1.0, 0.0, 1.0);
	float g = clamp(2.0 - abs(h * 6.0 - 2.0), 0.0, 1.0);
	float b = clamp(2.0 - abs(h * 6.0 - 4.0), 0.0, 1.0);
	return vec3(r, g, b);
}

// efficiency (energy/metal ratio) → bubble colour, matching the economy
// panel's grid swatch (LuaUI/Headers/overdrive.lua). The Lua side computes
// `h = 5760 / (eff+2)^2` (clamped at eff < 3.5 to h = 190) and then feeds
// `h / 255` into HSLtoRGB — so the hue divisor here is 255, not 360.
// Result: low-load grids are blue/teal, fully-saturated grids go yellow→red.
vec3 gridEfficiencyColor(float eff) {
	if (eff <= 0.0) return vec3(1.0, 0.25, 1.0);
	float h;
	if (eff < 3.5) {
		h = 190.0;
	} else {
		h = 5760.0 / ((eff + 2.0) * (eff + 2.0));
	}
	return hueToRgb(h / 255.0);
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

	// Cylinder cross-section normal that respects cable slope.
	//
	// `perp` is the *horizontal* cross-section direction baked at the
	// vertex. The cable's true tangent in world space (which can have a Y
	// component when the cable climbs/descends) is reconstructed from
	// screen-space derivatives of `cableUV.x` (= along) versus worldPos —
	// this works because `along` is monotone along the cable and screen
	// derivatives sample along the surface. With both vectors known, the
	// real "up" direction relative to the cable is cross(tangent, perp);
	// this rotates with the slope, so an uphill cable shades brightest on
	// its actual top side instead of where a horizontal cable would.
	vec3 perp3D = normalize(vec3(perp.x, 0.0, perp.y));

	vec3 dWdx = dFdx(worldPos);
	vec3 dWdy = dFdy(worldPos);
	float duDx = dFdx(cableUV.x);
	float duDy = dFdy(cableUV.x);
	float denom = duDx * duDx + duDy * duDy;
	vec3 cableT;
	if (denom > 1e-6) {
		cableT = normalize((dWdx * duDx + dWdy * duDy) / denom);
	} else {
		// Fallback if derivatives are degenerate (single-pixel cable, etc.):
		// horizontal tangent perpendicular to perp.
		cableT = normalize(vec3(perp.y, 0.0, -perp.x));
	}

	vec3 trueUp = cross(cableT, perp3D);
	if (trueUp.y < 0.0) trueUp = -trueUp;   // ensure pointing skyward
	trueUp = normalize(trueUp);

	float up = sqrt(max(0.0, 1.0 - v * v));
	vec3 cylNormal = normalize(trueUp * up + perp3D * v);

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

	// Energy bubbles travelling along the cable, like fluid in a pipe.
	//
	// Design:
	//   - +u is the direction of energy flow (synced reorients edges by
	//     current flow); all cables share one global phase so we never get
	//     the optical illusion of "counter motion" inside a single cable.
	//   - Density (bubbles per elmo) is FIXED: every cable shows the same
	//     bubbly look regardless of how loaded it is. What changes with
	//     flow is the SPEED bubbles travel at — zero flow leaves them
	//     motionless; high flow makes them zip.
	//   - Three layered streams of bubbles (big, medium, small) with random
	//     per-bubble size + cross-axis offset, so the cable looks like a
	//     real bubbly slurry instead of a metronome of identical dots.
	// Bubble speed mapping must match the CPU's flowToSpeed (otherwise the
	// CPU-integrated phase and shader-extrapolated phase disagree and we get
	// the very jumps this anchor scheme exists to eliminate).
	const float FLOW_REF  = 80.0;
	const float MAX_SPEED = 220.0;
	float flow = gridData.y;
	float speed = MAX_SPEED * clamp(flow / FLOW_REF, 0.0, 1.6);

	// Phase = CPU's baked phase (snapshot at bakeTime) + linear extrapolation
	// at the current speed. Speed *changes* update the rate of advance from
	// here — bubbles don't teleport.
	float phase = gridData.z + speed * (gameTime - bakeTime);
	float halfWidthE = width * 0.5;       // cable cross half-extent in elmos

	// Two layers of mixed-size bubbles. Density is fixed (constant spacing);
	// per-bubble radius jitter inside each layer gives the small/big mix.
	// Each layer returns (body, spec, halo); we composite them with
	// different colour weights so the bubble reads as glowing plasma.
	vec3 bA = bubbleLayer(along, phase, 75.0, 7.5, v, halfWidthE,  3.7);
	vec3 bB = bubbleLayer(along, phase, 32.0, 4.0, v, halfWidthE, 19.1);

	float bubbleBody = bA.x + bB.x * 0.85;
	float bubbleSpec = bA.y + bB.y * 0.85;
	float bubbleHalo = bA.z + bB.z * 0.55;

	// Bubble colour: keep the grid efficiency hue (low dilution → punchier).
	vec3 gridColor   = gridEfficiencyColor(gridData.x);
	vec3 bubbleColor = mix(gridColor, vec3(1.0), 0.15);
	vec3 haloColor   = gridColor;            // pure grid-colour halo

	// Halo first (soft underglow), then body (hot core/rim), then a pure-
	// white specular pop on top. Multipliers are tuned for "energy" feel —
	// the halo gives bloom, the core gives plasma, the spec gives sparkle.
	color += haloColor   * bubbleHalo * fullLOS * 0.70;
	color += bubbleColor * bubbleBody * fullLOS * 2.0;
	color += vec3(1.0)   * bubbleSpec * fullLOS * 1.2;

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
	renderEdgesByKey = {}
	for _, edges in pairs(edgesByAllyTeam) do
		for k, e in pairs(edges) do
			e.key = k
			renderEdges[#renderEdges + 1] = e
			renderEdgesByKey[k] = e
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
			geomCache.valid = false   -- topology change → full geometry rebuild
		end
	end

	-- Add new, refresh capacity / flow / efficiency on survivors.
	-- For each surviving edge, we integrate its bubble phase up to NOW with
	-- the *old* speed before swapping in the new one. That way, when flow
	-- (and hence speed) changes, the bubble position remains continuous —
	-- it just starts evolving at a different rate from this moment on.
	local nowSec = Spring.GetGameSeconds()
	for k, i in pairs(incoming) do
		local e = existing[k]
		local newFlow = data.flows and data.flows[i] or 0
		if e and not e.witherFrame then
			-- Catch the phase up to `nowSec` using whatever speed the cable
			-- was running at since its last anchor.
			local oldSpeed = e.bubbleSpeed or 0
			local oldAnchor = e.bubbleAnchorTime or nowSec
			e.bubblePhase = (e.bubblePhase or 0) + oldSpeed * (nowSec - oldAnchor)
			e.bubbleAnchorTime = nowSec
			e.bubbleSpeed = flowToSpeed(newFlow)

			e.capacity = data.caps[i]
			e.flow     = newFlow
			e.eff      = data.effs and data.effs[i] or 0
			-- positions are stable for unchanged edges; assign anyway in case parent moved
			e.px, e.pz = data.pxs[i], data.pzs[i]
			e.cx, e.cz = data.cxs[i], data.czs[i]
		else
			existing[k] = {
				px = data.pxs[i], pz = data.pzs[i],
				cx = data.cxs[i], cz = data.czs[i],
				capacity = data.caps[i],
				flow     = newFlow,
				eff      = data.effs and data.effs[i] or 0,
				appearFrame = frame,
				witherFrame = nil,
				key      = k,
				-- Fresh edge starts with zero phase; speed is set so the
				-- shader can extrapolate forward from this anchor.
				bubblePhase      = 0,
				bubbleAnchorTime = nowSec,
				bubbleSpeed      = flowToSpeed(newFlow),
			}
			geomCache.valid = false   -- topology change → full geometry rebuild
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
	local tStart = drawPerf and Spring.GetTimer() or nil

	-- Snapshot every edge's bubble phase to NOW before geometry generation,
	-- and re-anchor; the shader will extrapolate from `bubbleBakeTime`.
	bubbleBakeTime = Spring.GetGameSeconds()
	for _, edges in pairs(edgesByAllyTeam) do
		for _, e in pairs(edges) do
			local oldSpeed = e.bubbleSpeed or 0
			local oldAnchor = e.bubbleAnchorTime or bubbleBakeTime
			e.bubblePhase = (e.bubblePhase or 0) + oldSpeed * (bubbleBakeTime - oldAnchor)
			e.bubbleAnchorTime = bubbleBakeTime
		end
	end

	local tGen0 = drawPerf and Spring.GetTimer() or nil
	local cacheHit = geomCache.valid
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
		{ id = 5, name = "vertGrid",  size = 3 },  -- (efficiency, flow E/s, bubble phase elmos)
	})
	local tUp0 = drawPerf and Spring.GetTimer() or nil
	vbo:Upload(verts)
	cableVAO = gl.GetVAO()
	if cableVAO then cableVAO:AttachVertexBuffer(vbo) end
	numCableVerts = vertCount
	needsRebuild = false

	if drawPerf then
		local tEnd = Spring.GetTimer()
		Spring.Echo(string.format(
			"[CableTree] draw rebuild (%s): phase=%.2f ms  geom=%.2f ms  upload=%.2f ms  verts=%d",
			cacheHit and "cache-hit" or "FULL",
			Spring.DiffTimers(tGen0, tStart) * 1000,
			Spring.DiffTimers(tUp0,  tGen0)  * 1000,
			Spring.DiffTimers(tEnd,  tUp0)   * 1000,
			vertCount))
	end
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
		geomCache.valid = false
	end

	if needsRebuild and n % 6 == 0 then
		RebuildVBO()
	end
end

function gadget:DrawWorldPreUnit()
	if not cableVAO or numCableVerts == 0 or not cableShader then return end

	cableShader:Activate()
	cableShader:SetUniform("gameTime", Spring.GetGameSeconds())
	cableShader:SetUniform("bakeTime", bubbleBakeTime)

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
			bakeTime = 0,
		},
	}, "Cable Forward Shader")

	if not cableShader:Initialize() then
		Spring.Echo("[CableTree] Shader compile failed")
		gadgetHandler:RemoveGadget()
		return
	end
	gadgetHandler:AddSyncAction("CableTreeFull", OnCableTreeFull)
	gadgetHandler:AddSyncAction("CableTreePerf", function()
		local data = SYNCED.CableTreePerf
		if data then drawPerf = data.perf and true or false end
	end)
end

function gadget:Shutdown()
	if cableShader then cableShader:Finalize() end
	cableVAO = nil
	gadgetHandler:RemoveSyncAction("CableTreeFull")
	gadgetHandler:RemoveSyncAction("CableTreePerf")
end

end -- UNSYNCED
