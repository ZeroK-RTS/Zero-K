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
-- Per-tick consumer set: only nodes whose def could plausibly draw current
-- get hit with Spring.GetUnitResources / overdrive_energyDrain reads each
-- ComputeMaxPotentials cycle. Pure generators (windmill, solar, fusion) and
-- range-only pylons are skipped — at 1500+ pylons that read alone took the
-- bulk of the 1Hz hitch.
local consumerByDef = {}

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
	-- Mex / voltage unit / anything that builds (factory, strider hub,
	-- builder commander, etc.) can draw energy on the cable.
	local hasBuildPower = (udef.buildSpeed and udef.buildSpeed > 0) or
		(udef.buildPower and udef.buildPower > 0)
	if mexDefs[i] or voltageByDef[i] or hasBuildPower then
		consumerByDef[i] = true
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
	-- topology-cached. But we only call into the engine for nodes whose def
	-- can possibly draw (mexes, voltage units, builders). Pure generators
	-- (windmills/solar/fusion) and range-only pylons stay at 0 → at 1500+
	-- pylons this skips most of the per-tick rules-param reads.
	local subDcur = {}
	for i = 1, #order do
		local u = order[i]
		local did = nodeDefByUID[u]
		subDcur[u] = (did and consumerByDef[did]) and GetNodeDcurrent(u, did) or 0
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
--
-- Cable-thickness/capacity is treated as orthogonal identity (it's the cable's
-- "how big a pipe" reading, NOT a flow signal). Flow itself is encoded by
-- speed + density only. Each scales as sqrt(flow / FLOW_REF) and they grow
-- together, so the product (= perceived flow ≈ density × speed) is linear in
-- flow. One unified "more lively" gestalt instead of three integrated dials.
local BUBBLE_MAX_SPEED      = 110
local BUBBLE_FLOW_REF       = 50.0   -- flow at which n=1 (reference speed/density)
local BUBBLE_TRUNK_W_MIN    = 3.0    -- mirror of GLSL MIN_TRUNK_WIDTH
local BUBBLE_TRUNK_W_MAX    = 12.0   -- mirror of GLSL MAX_TRUNK_WIDTH
local BUBBLE_CAP_REF        = 100.0

local function widthOfCapacity(cap)
	local t = (cap or 0) / BUBBLE_CAP_REF
	if t < 0 then t = 0 elseif t > 1 then t = 1 end
	return BUBBLE_TRUNK_W_MIN + t * (BUBBLE_TRUNK_W_MAX - BUBBLE_TRUNK_W_MIN)
end

-- Slight negative bias for thicker cables: divide flow by (width/minWidth).
-- A max-thickness cable (4× minWidth) sees its flow signal scaled to 1/4
-- before the sqrt, yielding ~0.5× visual liveliness vs a thin cable at the
-- same actual flow. Conveys "this thick cable is wide so the same flow looks
-- relatively calmer through it" without the heavier 2.5-power weighting we
-- tried before.
local function flowToSpeed(flow, capacity)
	if not flow or flow <= 0 then return 0 end
	local widthVal = widthOfCapacity(capacity)
	local thicknessRatio = widthVal / BUBBLE_TRUNK_W_MIN
	local effFlow = flow / thicknessRatio
	return BUBBLE_MAX_SPEED * math.sqrt(effFlow / BUBBLE_FLOW_REF)
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

-- Per-edge VBO build: emit two vertices per cable (the two endpoints), each
-- carrying the same per-edge payload. The geometry shader expands each line
-- into the noisy wiggly ribbon. CPU work shrinks from "build full triangle
-- soup" (lots of NoisyPath / clustering / twig generation) to "iterate edges".
-- Cluster stems and twigs are deliberately gone in this first GS pass — to be
-- reintroduced as either CPU-emitted phantom edges (stems) or GS-side branches
-- (twigs) once the basic pipeline is verified.
local function GenerateOrganicTree()
	local n = #renderEdges
	if n == 0 then return {}, 0 end

	local verts = {}
	local k = 0
	for i = 1, n do
		local e = renderEdges[i]
		local cap = max(1, e.capacity or 1)
		local appearTime = (e.appearFrame or 0) / GAME_SPEED
		local witherTime = e.witherFrame and (e.witherFrame / GAME_SPEED) or 0
		local eff = e.eff or 0
		local flow = e.flow or 0
		local phase = e.bubblePhase or 0

		-- Vertex 0: parent end
		verts[k+1] = e.px;          verts[k+2] = e.pz
		verts[k+3] = cap;           verts[k+4] = appearTime;  verts[k+5] = witherTime
		verts[k+6] = eff;           verts[k+7] = flow;        verts[k+8] = phase
		-- Vertex 1: child end (same per-edge payload)
		verts[k+9] = e.cx;          verts[k+10] = e.cz
		verts[k+11] = cap;          verts[k+12] = appearTime; verts[k+13] = witherTime
		verts[k+14] = eff;          verts[k+15] = flow;       verts[k+16] = phase
		k = k + 16
	end
	return verts, n * 2
end

-- Old generic angle clustering — kept commented as a reference for when we
-- reintroduce CPU-side stem merging (cluster decomposition is a graph
-- operation that doesn't fit cleanly in a geometry shader).

-------------------------------------------------------------------------------------
-- Forward cable rendering via DrawWorldPreUnit.
-- Vertex shader resamples heightmap each frame so cables follow terraform.
-- Fragment shader does its own diffuse+specular lighting on a synthesized
-- cylinder normal, plus traveling energy pulses gated by LOS ($info).
-------------------------------------------------------------------------------------

-- Pass-through VS: each cable is a single GL_LINES primitive (2 vertices,
-- both carrying the same per-edge attributes). The geometry shader then
-- expands the line into a wiggly noisy ribbon with N segments. All the
-- expensive per-vertex math that used to live on the CPU now lives on the GPU.
local cableVSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (location = 0) in vec2 vertPos;     // (x, z) world coords
layout (location = 1) in vec3 vertData;    // (capacity, appearTime, witherTime)
layout (location = 2) in vec3 vertGrid;    // (gridEfficiency, flow, bubblePhase)

out gl_PerVertex {
	vec4 gl_Position;
};

out DataVS {
	vec2 vsWorldXZ;
	vec3 vsCableData;
	vec3 vsGridData;
};

void main() {
	vsWorldXZ   = vertPos;
	vsCableData = vertData;
	vsGridData  = vertGrid;
	gl_Position = vec4(0.0);
}
]]

-- (dead-code block removed)

-- Full GS: takes one GL_LINES primitive (cable endpoints) and emits the cable
-- ribbon. Uses GS invocations: each invocation runs main() with its own
-- max_vertices budget, so we can:
--   invocation 0          → main wiggly ribbon (SEGMENTS+1 boundaries × 2 verts)
--   invocations 1..N-1    → one twig each (4 verts), conditional on a hash
-- This sidesteps the per-program max_vertices limit and keeps the FS body
-- unchanged.
local cableGSSrc = [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#extension GL_ARB_gpu_shader5 : require

layout (lines, invocations = 5) in;
// 50 verts/invocation comfortably fits min-spec total components budget;
// invocation 0 uses ~50, twig invocations use 4.
layout (triangle_strip, max_vertices = 50) out;

uniform sampler2D heightmapTex;

in DataVS {
	vec2 vsWorldXZ;
	vec3 vsCableData;
	vec3 vsGridData;
} dataIn[];

out DataGS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 perp;
	vec2 timeData;
	vec3 gridData;
	float localU;     // twig-local along (0 at root, bLen at tip). Unused for main ribbon.
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

// Terrain normal at a world XZ point via 4-tap finite-difference of the
// heightmap. Cheap (4 fetches) and good enough for placing twigs into the
// slope's local tangent plane.
vec3 terrainNormal(vec2 xz) {
	const float E = 8.0;
	float hxR = heightAtWorldPos(xz + vec2( E, 0.0));
	float hxL = heightAtWorldPos(xz + vec2(-E, 0.0));
	float hzU = heightAtWorldPos(xz + vec2(0.0,  E));
	float hzD = heightAtWorldPos(xz + vec2(0.0, -E));
	return normalize(vec3(hxL - hxR, 2.0 * E, hzD - hzU));
}

// Mirror of Lua-side Hash() / NoisyPath() so cables look exactly like before.
float gsHash(float x, float z, float seed) {
	return fract(sin(x * 12.9898 + z * 78.233 + seed * 43.17) * 43758.5453) * 2.0 - 1.0;
}
float gsHashU(float x, float z, float seed) {  // [0,1] variant
	return (gsHash(x, z, seed) + 1.0) * 0.5;
}
float gsNoiseScale(float t) {
	if (t < 0.1) return t / 0.1;
	if (t > 0.9) return (1.0 - t) / 0.1;
	return 1.0;
}

const int   MAX_SEGMENTS      = 24;   // hardware budget (max_vertices=50 → 25 boundaries × 2). Cable lengths are bounded by pylon range so this isn't expected to clamp in practice.
const float SEG_LEN_TARGET    = 22.0; // elmos of 3D arc per segment
const float NOISE_AMP_ABS     = 4.0;
const float WIDTH_FACTOR      = 0.55;
const float MIN_TRUNK_WIDTH   = 3.0;
const float MAX_TRUNK_WIDTH   = 12.0;
const float MAX_CAPACITY_REF  = 100.0;

// Twig parameters mirror the Lua-side BRANCH_* constants.
const float BRANCH_CHANCE     = 0.78;
const float BRANCH_LEN_MIN    = 15.0;
const float BRANCH_LEN_MAX    = 50.0;
const float BRANCH_ANGLE_MIN  = 0.4;
const float BRANCH_ANGLE_MAX  = 1.1;
const float BRANCH_WIDTH      = 0.85;

float gOutBranch = 0.0;

float gOutLocalU = 0.0;  // set per-vertex by twig emitters; main ribbon leaves at 0.

void emitVtx(vec3 wp, vec2 perpHere, vec2 cuv,
             float w, vec3 grid, vec2 td, float cap) {
	worldPos = wp;
	capacity = cap;
	isBranch = gOutBranch;
	width = w;
	cableUV = cuv;
	perp = perpHere;
	timeData = td;
	gridData = grid;
	localU = gOutLocalU;
	gl_Position = cameraViewProj * vec4(wp, 1.0);
	EmitVertex();
}

void emitMainRibbon(vec2 a, vec2 d, vec2 perpAB,
                    float halfW, float widthVal, float effAmp, float seed,
                    vec3 gridD, vec2 timeD, float cap, int numSeg) {
	gOutBranch = 0.0;
	// `along` is fed into the FS as cableUV.x and drives bubble advection.
	// It MUST be a 3D arc length, otherwise downslope cables look like the
	// flow is racing because the same 2D Δalong covers more visible meters.
	float along = 0.0;
	vec3  prev3D = vec3(0.0);
	for (int i = 0; i <= numSeg; i++) {
		float t = float(i) / float(numSeg);
		vec2 base = a + d * t;
		float n = gsHash(base.x * 0.1, base.y * 0.1, seed) * effAmp * gsNoiseScale(t);
		vec2 p = base + perpAB * n;

		// Sample heightmap independently at the two ribbon edges so the strip
		// drapes across cross-slope terrain instead of clipping into the uphill
		// side. `along` uses the (untwisted) centerline.
		vec2 leftXZ  = vec2(p.x - perpAB.x * halfW, p.y - perpAB.y * halfW);
		vec2 rightXZ = vec2(p.x + perpAB.x * halfW, p.y + perpAB.y * halfW);
		float yC = heightAtWorldPos(p)       + 5.0;
		float yL = heightAtWorldPos(leftXZ)  + 5.0;
		float yR = heightAtWorldPos(rightXZ) + 5.0;

		vec3 curr3D = vec3(p.x, yC, p.y);
		if (i > 0) along += distance(prev3D, curr3D);
		prev3D = curr3D;

		vec3 leftPos  = vec3(leftXZ.x,  yL, leftXZ.y);
		vec3 rightPos = vec3(rightXZ.x, yR, rightXZ.y);

		emitVtx(leftPos,  perpAB, vec2(along, -1.0), widthVal, gridD, timeD, cap);
		emitVtx(rightPos, perpAB, vec2(along,  1.0), widthVal, gridD, timeD, cap);
	}
	EndPrimitive();
}

// Emit a small lateral twig at parametric position tCenter along the main
// (wiggly) cable, deterministic on the cable seed + tCenter so the same
// twigs appear every frame in the same place. Returns silently when the
// hash says "no twig here" — leaving an empty primitive, which is a no-op.
void emitTwig(vec2 a, vec2 d, vec2 perpAB,
              float halfMainW, float widthVal, float effAmp, float seed,
              vec3 gridD, vec2 timeD, float cap, float tCenter, float invSeed,
              float spawnAlongMain) {
	// Resolve spawn point on the wiggly main path at tCenter.
	vec2 base = a + d * tCenter;
	float n = gsHash(base.x * 0.1, base.y * 0.1, seed) * effAmp * gsNoiseScale(tCenter);
	vec2 spawn = base + perpAB * n;

	float twigSeed = spawn.x * 7.13 + spawn.y * 3.77 + invSeed;
	float chance = gsHashU(spawn.x, spawn.y, twigSeed);
	if (chance > BRANCH_CHANCE) return;

	// Side & angle off the main direction.
	float side = (gsHash(spawn.x, spawn.y, twigSeed + 1.0) > 0.0) ? 1.0 : -1.0;
	float angleOff = BRANCH_ANGLE_MIN +
		gsHashU(spawn.x, spawn.y, twigSeed + 2.0) * (BRANCH_ANGLE_MAX - BRANCH_ANGLE_MIN);
	float bLen = BRANCH_LEN_MIN +
		gsHashU(spawn.x, spawn.y, twigSeed + 3.0) * (BRANCH_LEN_MAX - BRANCH_LEN_MIN);

	float twigW    = max(2.5, widthVal * BRANCH_WIDTH);
	float twigHWr  = min(twigW, widthVal * 0.55) * WIDTH_FACTOR;
	float twigHWt  = twigHWr * 0.25;

	// Build the twig as a flat ribbon in the slope's local tangent plane at
	// the spawn point. This way, viewing perpendicular to the slope, the twig
	// looks exactly like a flat-ground twig — no downhill tilt artefact.
	//
	// Basis: N = terrain normal at spawn; T = cable tangent projected into the
	// slope plane; B = N × T (in-slope perp to cable). Twig direction is
	// (cos(angleOff)*T + side*sin(angleOff)*B), and twigPerp3D = N × twigDir3D.
	vec3 N = terrainNormal(spawn);
	vec3 cableDirH = normalize(vec3(d.x, 0.0, d.y));
	vec3 T = normalize(cableDirH - dot(cableDirH, N) * N);
	vec3 B = normalize(cross(N, T));

	float ca = cos(angleOff);
	float sa = sin(angleOff) * side;
	vec3 twigDir3D  = ca * T + sa * B;
	vec3 twigPerp3D = normalize(cross(N, twigDir3D));

	float clearance = 5.0;
	vec3 spawn3D = vec3(spawn.x, heightAtWorldPos(spawn), spawn.y) + N * clearance;

	// Anchor the root to the spawn-side edge of the cable's in-slope cross
	// section so the twig pokes out of the side, not the midline.
	vec3 root3D = spawn3D + B * (halfMainW * 0.45 * side);
	vec3 tip3D  = root3D + twigDir3D * bLen;

	vec3 rootL = root3D - twigPerp3D * twigHWr;
	vec3 rootR = root3D + twigPerp3D * twigHWr;
	vec3 tipL  = tip3D  - twigPerp3D * twigHWt;
	vec3 tipR  = tip3D  + twigPerp3D * twigHWt;

	// Horizontal projection of twigPerp for the FS varying (the FS reconstructs
	// the cable normal via screen-space derivatives + this horizontal hint).
	vec2 twigPerpH = vec2(twigPerp3D.x, twigPerp3D.z);
	float lh = length(twigPerpH);
	if (lh > 1e-4) twigPerpH /= lh; else twigPerpH = vec2(1.0, 0.0);

	// cableUV.x carries the cable-wide along distance so the FS growth gate
	// hides this twig until the main growth front has reached spawnAlongMain.
	// localU is twig-local along (0..bLen) — the FS uses it for the synced
	// single-bubble animation in twigs (independent of cable-global phase).
	gOutBranch = 1.0;
	gOutLocalU = 0.0;
	emitVtx(rootL, twigPerpH, vec2(spawnAlongMain,        -1.0), twigW,        gridD, timeD, cap);
	emitVtx(rootR, twigPerpH, vec2(spawnAlongMain,         1.0), twigW,        gridD, timeD, cap);
	gOutLocalU = bLen;
	emitVtx(tipL,  twigPerpH, vec2(spawnAlongMain + bLen, -1.0), twigW * 0.25, gridD, timeD, cap);
	emitVtx(tipR,  twigPerpH, vec2(spawnAlongMain + bLen,  1.0), twigW * 0.25, gridD, timeD, cap);
	EndPrimitive();
}

void main() {
	vec2 a = dataIn[0].vsWorldXZ;
	vec2 b = dataIn[1].vsWorldXZ;
	vec2 d = b - a;
	float lenAB = length(d);
	if (lenAB < 0.5) return;
	vec2 dirAB  = d / lenAB;
	vec2 perpAB = vec2(-dirAB.y, dirAB.x);

	float cap   = dataIn[0].vsCableData.x;
	vec2  timeD = dataIn[0].vsCableData.yz;
	vec3  gridD = dataIn[0].vsGridData;

	float widthVal = MIN_TRUNK_WIDTH +
		clamp(cap / MAX_CAPACITY_REF, 0.0, 1.0) * (MAX_TRUNK_WIDTH - MIN_TRUNK_WIDTH);
	float halfW  = widthVal * WIDTH_FACTOR;
	float effAmp = NOISE_AMP_ABS * (lenAB < 80.0 ? (lenAB / 80.0) : 1.0);
	float seed   = a.x * 0.137 + a.y * 0.781 + b.x * 0.293 + b.y * 0.461;

	// Coarse 3D length: 6 sub-spans of the straight a→b path, summing the
	// terrain-aware Euclidean distance between samples. Slopes inflate len3D
	// versus lenAB, so hilly cables get more turns AND tighter 2D spacing per
	// segment (because each segment is len3D/numSeg in 3D arc, but spaced
	// uniformly in 2D parameter t). Noise wiggle is ignored here — keeping the
	// scan cheap matters more than a few % accuracy on segment count.
	float len3D = 0.0;
	{
		vec3 prev3 = vec3(a.x, heightAtWorldPos(a) + 2.0, a.y);
		for (int j = 1; j <= 6; j++) {
			float tj = float(j) * (1.0 / 6.0);
			vec2 bj = a + d * tj;
			vec3 p3 = vec3(bj.x, heightAtWorldPos(bj) + 2.0, bj.y);
			len3D += distance(p3, prev3);
			prev3 = p3;
		}
	}
	int numSeg = clamp(int(len3D / SEG_LEN_TARGET + 0.5), 1, MAX_SEGMENTS);

	if (gl_InvocationID == 0) {
		emitMainRibbon(a, d, perpAB, halfW, widthVal, effAmp, seed, gridD, timeD, cap, numSeg);
	} else {
		// Twig density scales with 3D arc length: ~one twig per 110 elmos,
		// capped at 4. Short cables get 0-1 twigs, long ones get the full set.
		// Surviving twigs are then respread across [0.15, 0.85] so spacing
		// remains roughly even regardless of twig count.
		int idx = gl_InvocationID - 1;          // 0..3
		int expectedTwigs = clamp(int(len3D / 85.0 + 0.5), 0, 4);
		if (idx >= expectedTwigs) return;
		float tCenterRaw = 0.15 + (float(idx) + 0.5) * (0.7 / float(expectedTwigs));
		// Snap to a main-ribbon segment vertex. The cable is rendered as
		// piecewise-linear chords between samples at t = i/numSeg, so anchoring
		// the twig at the analytical centerline (which curves between samples)
		// would leave the root edge floating off the visible cable surface.
		// Snapping makes the spawn point coincide with an actual rendered
		// vertex of the main ribbon.
		float tCenter = clamp(round(tCenterRaw * float(numSeg)), 1.0, float(numSeg) - 1.0)
		              / float(numSeg);
		float spawnAlongMain = len3D * tCenter;
		emitTwig(a, d, perpAB, halfW, widthVal, effAmp, seed,
		         gridD, timeD, cap, tCenter, float(idx) * 13.7, spawnAlongMain);
	}
}
]]

local cableFSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

uniform sampler2D infoTex;
uniform float gameTime;
uniform float bakeTime;

in DataGS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 perp;
	vec2 timeData;  // x = appearTime, y = witherTime (0 = not withering)
	vec3 gridData;  // x = efficiency (E/M), y = flow (E/s), z = bubble phase at bake (elmos)
	float localU;   // twig-local along (0 at root, bLen at tip). Unused for main ribbon.
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
	// Bubble speed/density mapping. MUST match the CPU's flowToSpeed for the
	// integrated phase anchoring to stay consistent.
	//
	// Cable thickness conveys capacity (orthogonal); flow is encoded by speed
	// and density together. Each scales as sqrt(flow/FLOW_REF) and ramps
	// monotonically, so they read as one fused "more lively" signal. Their
	// product = (sqrt(...))² is linear in flow, matching actual throughput.
	const float MAX_SPEED   = 110.0;
	const float FLOW_REF    = 50.0;
	const float MIN_TRUNK_W = 3.0;
	float flow = gridData.y;
	// Linear thickness divisor: a cable 4× thicker than min gets its flow
	// signal scaled to 1/4 before the sqrt → ~0.5× visual liveliness. Slight
	// negative bias for thick cables, matching the CPU's flowToSpeed.
	float thicknessRatio = max(1.0, width / MIN_TRUNK_W);
	float effFlow = max(flow, 0.0) / thicknessRatio;
	float n = sqrt(effFlow / FLOW_REF);
	float speed = MAX_SPEED * n;

	float halfWidthE = width * 0.5;        // cable cross half-extent in elmos

	// Phase = CPU's baked phase (snapshot at bakeTime) + linear extrapolation
	// at the current speed. Speed *changes* update the rate of advance from
	// here — bubbles don't teleport.
	float phase = gridData.z + speed * (gameTime - bakeTime);

	// Density: spacing inversely scales with the same sqrt factor, floored at
	// `n=0.3` so a near-zero-flow cable still shows widely-spaced bubbles
	// rather than nothing or overlapping spam.
	float spacingMul = max(0.3, n);
	float spacingA = 105.0 / spacingMul;
	float spacingB = 48.0  / spacingMul;

	// Bubble pass: main ribbon uses two layers of advecting bubbles whose
	// spacing is modulated by densityFactor. Twigs instead show synced bubbles
	// at the same big-bubble rhythm so every twig in a cable pulses in lockstep
	// at the main cable's speed.
	float bubbleBody, bubbleSpec, bubbleHalo;
	if (isBranch > 0.5) {
		float twigPhase = mod(gameTime * speed, spacingA);
		vec3 bT = bubbleLayer(localU, twigPhase, spacingA, 5.0, v, halfWidthE, 0.0);
		bubbleBody = bT.x;
		bubbleSpec = bT.y;
		bubbleHalo = bT.z;
	} else {
		vec3 bA = bubbleLayer(along, phase, spacingA, 7.5, v, halfWidthE,  3.7);
		vec3 bB = bubbleLayer(along, phase, spacingB, 4.0, v, halfWidthE, 19.1);
		bubbleBody = bA.x + bB.x * 0.85;
		bubbleSpec = bA.y + bB.y * 0.85;
		bubbleHalo = bA.z + bB.z * 0.55;
	}

	// Bubble colour: keep the grid efficiency hue (low dilution → punchier).
	vec3 gridColor   = gridEfficiencyColor(gridData.x);
	vec3 bubbleColor = mix(gridColor, vec3(1.0), 0.15);
	vec3 haloColor   = gridColor;            // pure grid-colour halo

	// Composition order is chosen so the bubble core never picks up the bark's
	// hue:
	//   - Halo: additive (soft underglow that should mix with bark colour).
	//   - Body: max() over current colour, so the dark green/brown bark can't
	//     leak into the bubble's true grid hue. Plain additive composition
	//     causes hue shifts (orange → yellow, magenta → pink) because the
	//     bark's green channel piles onto the emissive. max() lets the
	//     emissive plasma show its real colour through the cable in shadow.
	//   - Spec: additive white sparkle on top.
	color += haloColor * bubbleHalo * fullLOS * 0.70;
	vec3 bubbleEmissive = bubbleColor * bubbleBody * fullLOS * 2.0;
	color = max(color, bubbleEmissive);
	color += vec3(1.0) * bubbleSpec * fullLOS * 1.2;

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

	local tStart = drawPerf and Spring.GetTimer() or nil
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
			e.bubbleSpeed = flowToSpeed(newFlow, data.caps[i])

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
				bubbleSpeed      = flowToSpeed(newFlow, data.caps[i]),
			}
			geomCache.valid = false   -- topology change → full geometry rebuild
		end
	end

	edgesByAllyTeam[ally] = existing
	local tDiff = drawPerf and Spring.GetTimer() or nil
	RebuildRenderEdges()
	needsRebuild = true

	if drawPerf then
		local tEnd = Spring.GetTimer()
		Spring.Echo(string.format(
			"[CableTree] OnCableTreeFull: diff=%.2f ms  rebuildIdx=%.2f ms  edges=%d",
			Spring.DiffTimers(tDiff,  tStart) * 1000,
			Spring.DiffTimers(tEnd,   tDiff)  * 1000,
			data.edgeCount))
	end
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
	local verts, vertCount = GenerateOrganicTree()
	if vertCount == 0 then
		numCableVerts = 0
		needsRebuild = false
		return
	end

	cableVAO = nil
	local vbo = gl.GetVBO(GL.ARRAY_BUFFER, false)
	if not vbo then return end
	-- Per-vertex layout (8 floats): vertPos(2) + vertData(3) + vertGrid(3).
	-- Two vertices per cable form one GL_LINES primitive; the geometry shader
	-- expands each line into a wiggly ribbon at draw time.
	vbo:Define(vertCount, {
		{ id = 0, name = "vertPos",   size = 2 },
		{ id = 1, name = "vertData",  size = 3 },  -- (capacity, appearTime, witherTime)
		{ id = 2, name = "vertGrid",  size = 3 },  -- (efficiency, flow E/s, bubble phase elmos)
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
			"[CableTree] draw rebuild: phase=%.2f ms  build=%.2f ms  upload=%.2f ms  verts=%d edges=%d",
			Spring.DiffTimers(tGen0, tStart) * 1000,
			Spring.DiffTimers(tUp0,  tGen0)  * 1000,
			Spring.DiffTimers(tEnd,  tUp0)   * 1000,
			vertCount, vertCount / 2))
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

	-- Rebuild immediately when dirty. Throttling caused visible phase jumps:
	-- between OnCableTreeFull (which mutates per-edge bubbleSpeed) and the
	-- rebake, the shader still extrapolates with the OLD speed, then snaps to
	-- the new baked state. The jump magnitude is Δspeed × (bakeTime - nowSec)
	-- so any latency here directly produces a visible discontinuity.
	if needsRebuild then
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

	-- GL_LINES: every 2 verts form one cable; the geometry shader expands
	-- them into a triangle_strip ribbon.
	cableVAO:DrawArrays(GL.LINES, numCableVerts)

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
	local gsSrc = cableGSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	local fsSrc = cableFSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)


	cableShader = LuaShader({
		vertex = vsSrc,
		geometry = gsSrc,
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
