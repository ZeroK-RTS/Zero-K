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

-- Pure-visualization gadget: nothing here affects simulation, so we skip the
-- synced sandbox entirely. Unsynced gadgets still receive UnitCreated /
-- UnitDestroyed / UnitGiven for ALL units regardless of LOS (unlike widgets),
-- which is what we need to keep ghost cables alive after enemy pylons leave
-- LOS. Since each client's unsynced sandbox sees the same engine state and
-- runs the same code, every client independently reaches the same topology
-- without any synced→unsynced channel.
if gadgetHandler:IsSyncedCode() then return false end

-- Forward declaration: SendAll (topology side, defined below) hands its
-- per-ally snapshot directly to OnCableTreeFull (rendering side, defined
-- much further down). Both are file-scope locals; the body assignment for
-- OnCableTreeFull happens in the rendering section.
local OnCableTreeFull

-------------------------------------------------------------------------------------
-- Topology + flow computation (was previously the synced half).
-- Reads gridNumber from unit_mex_overdrive as source of truth.
-- Periodically computes desired spanning tree edges per grid; OnCableTreeFull
-- below consumes the result directly (no sandbox crossover).
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
local MST_MODE          = "realistic"

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

-- Per-unit static cache: minWind (set once by unit_windmill_control at unit
-- creation, never changes thereafter). Without this, BuildMpCache re-reads
-- Spring.GetUnitRulesParam("minWind") for every windmill on every topology
-- change — at 3500 windmills that's ~3.5ms of cross-boundary calls, fired on
-- every cascade tick during destruction events. Cache on first read; drop
-- on UnitDestroyed (handled where nodeDefByUID is cleared).
local minWindByUID = {}             -- [unitID] = cached minWind value (E/s)
local function GetCachedMinWind(uid)
	local v = minWindByUID[uid]
	if v ~= nil then return v end
	v = spGetUnitRulesParam(uid, "minWind") or 0
	minWindByUID[uid] = v
	return v
end

-- Index of pylon-eligible CONSUMER units only (mexes, voltage units, builders).
-- Maintained on UnitCreated / SyncWithGrid death-sweep / UnitGiven so SendAll
-- can do a cheap O(consumers) pre-check (~50 reads at 4000 nodes) instead of
-- always running the O(N) ComputeMaxPotentials. Generators (windmills/solar/
-- fusion) never appear here; only nodes whose defs publish a non-zero draw.
local consumerNodeIndex = {}        -- [unitID] = unitDefID
local lastConsumerDcur  = {}        -- [unitID] = last-seen Dcurrent reading
local lastWindFrac      = -1        -- last-tick windFrac for change detection

local function GetCurWindFrac()
	local f = Spring.GetGameRulesParam("WindStrength") or 0
	if f < 0 then return 0 elseif f > 1 then return 1 end
	return f
end

-- Spatial-hash and candidate-cap constants. Declared early so the pylon-
-- neighbour helpers below capture them as upvalues. Re-referenced (without
-- redeclaration) by BuildGridMSTFromScratch and the incremental MST ops.
local SPATIAL_CELL       = 2000   -- cell size; 3x3 covers ~4000-elmo pairs
local MST_CANDIDATE_R    = 4000   -- hard cap on candidate-pair distance
local MST_CANDIDATE_R_SQ = MST_CANDIDATE_R * MST_CANDIDATE_R
local MST_EUCLIDEAN_MODE = MST_MODE == "euclidean"

-- Global precomputed neighbour index. The MST candidate-set for any pylon is
-- a function ONLY of (positions, ranges) of nearby same-ally pylons — all
-- static once a pylon exists. So we compute it once on UnitCreated and reuse
-- on every MST build/update.
--
-- Without this, BuildGridMSTFromScratch was rebuilding neighbour lists from
-- the spatial hash on every call: 3×3 cells × cellsize candidates × N pylons.
-- In dense scenes (4000 windmills @ 110 elmo spacing → ~325 pylons per
-- 2000-elmo cell → 3000 candidates per pylon) that's 12M iterations per
-- rebuild — the dominant cost. With cached neighbours, MST builders just
-- iterate `pylonNeighbours[uid]` (typical degree 20-50) and filter by grid
-- membership.
--
-- Bidirectional: pylonNeighbours[a][b] and pylonNeighbours[b][a] are both
-- set, both with the same distSq. Same-ally only.
local pylonNeighbours = {}          -- [uid] = { [otherUid] = distSq }

-- Per-ally spatial hash maintained alongside `nodes`. Used to find neighbour
-- candidates when a pylon is created — ONE 3×3-cell scan against the live
-- ally hash, then bidirectional add. Subsequent MST work consumes
-- pylonNeighbours directly without ever touching the hash.
local pylonSpatialHash = {}         -- [allyID] = { [cellKey] = { uid1, ... } }

local function PylonCellKey(x, z)
	return floor(x / SPATIAL_CELL) * 100000 + floor(z / SPATIAL_CELL)
end

local function PylonAddSpatial(allyID, uid, x, z)
	local hash = pylonSpatialHash[allyID]
	if not hash then hash = {}; pylonSpatialHash[allyID] = hash end
	local ck = PylonCellKey(x, z)
	local cell = hash[ck]
	if not cell then cell = {}; hash[ck] = cell end
	cell[#cell + 1] = uid
end

local function PylonRemoveSpatial(allyID, uid, x, z)
	local hash = pylonSpatialHash[allyID]
	if not hash then return end
	local cell = hash[PylonCellKey(x, z)]
	if not cell then return end
	for i = 1, #cell do
		if cell[i] == uid then
			cell[i] = cell[#cell]
			cell[#cell] = nil
			return
		end
	end
end

-- Walk the 3×3 spatial-hash neighbourhood of `uid`'s ally; for every other
-- pylon within candidate cap, write a bidirectional pylonNeighbours entry.
local function PylonBuildNeighbours(allyID, uid)
	local allyNodes = nodes[allyID]
	if not allyNodes then return end
	local node = allyNodes[uid]
	if not node then return end
	local hash = pylonSpatialHash[allyID]
	if not hash then return end
	local nb = pylonNeighbours[uid]
	if not nb then nb = {}; pylonNeighbours[uid] = nb end
	local px, pz, pr = node.x, node.z, node.range
	local cx = floor(px / SPATIAL_CELL)
	local cz = floor(pz / SPATIAL_CELL)
	local euclidean = MST_EUCLIDEAN_MODE
	local rSq = MST_CANDIDATE_R_SQ
	for dcx = -1, 1 do
		for dcz = -1, 1 do
			local cell = hash[(cx + dcx) * 100000 + (cz + dcz)]
			if cell then
				for ci = 1, #cell do
					local j = cell[ci]
					if j ~= uid then
						local jnode = allyNodes[j]
						if jnode then
							local dx = px - jnode.x
							local dz = pz - jnode.z
							local distSq = dx * dx + dz * dz
							local cap = euclidean and rSq
								or ((pr + jnode.range) * (pr + jnode.range))
							if distSq < cap then
								nb[j] = distSq
								local other = pylonNeighbours[j]
								if not other then other = {}; pylonNeighbours[j] = other end
								other[uid] = distSq
							end
						end
					end
				end
			end
		end
	end
end

local function PylonClearNeighbours(uid)
	local nb = pylonNeighbours[uid]
	if not nb then return end
	for n in pairs(nb) do
		local other = pylonNeighbours[n]
		if other then other[uid] = nil end
	end
	pylonNeighbours[uid] = nil
end

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

-- Detail level — three states, persisted under OverdriveCableDetail:
--   0 = off    (no cables drawn at all; clears geometry)
--   1 = noflow (static lines; skips per-tick flow reads + FS bubble pass)
--   2 = full   (default: animated bubbles, per-tick flow updates)
-- The two derived flags (cableEnabled / cableFlowMode) drive existing code
-- paths unchanged; only the chat command + widget settings menu speak in
-- terms of the unified detail level.
local DETAIL_OFF, DETAIL_NOFLOW, DETAIL_FULL = 0, 1, 2

local function readDetailFromConfig()
	local v = Spring.GetConfigInt("OverdriveCableDetail", DETAIL_FULL) or DETAIL_FULL
	if v < DETAIL_OFF or v > DETAIL_FULL then v = DETAIL_FULL end
	return v
end
local cableDetail = readDetailFromConfig()

-- Runtime toggles, driven by the /cabletree chat command (see CableTreeCmd).
local cableEnabled  = cableDetail ~= DETAIL_OFF
local cablePerf     = false
local cableFlowMode = cableDetail == DETAIL_FULL

-- Per-tick perf stats. Filled by SyncWithGrid / ComputeMaxPotentials /
-- SendAll only when cablePerf is on; RunSyncTick reads them and emits one
-- summary line per tick. Module-scope for zero-cost write paths when perf
-- is off (the writers gate on cablePerf themselves).
local perfStats = {
	dropMs = 0, refreshMs = 0, mstMs = 0, mstRebuilds = 0, mstIncrements = 0,
	composeMs = 0, diffMs = 0,
	mpBuildMs = 0, mpComputeMs = 0,
	binMs = 0, dispatchMs = 0,
	skipped = 0,
	-- Slowest single MST rebuild this tick: ms, member count, and a
	-- breakdown of what the heap-Prim spent its time on.
	worstRebuildMs = 0, worstRebuildN = 0,
	worstRebuildHashMs = 0, worstRebuildNeighMs = 0, worstRebuildPrimMs = 0,
	-- Slowest single incremental this tick: ms, members removed/added.
	worstIncrMs = 0, worstIncrRem = 0, worstIncrAdd = 0,
}

-- Last-sent snapshot of per-edge (flow, eff) so SendAll can short-circuit
-- when nothing meaningfully changed. Quiet ticks (settled grid, no draw
-- spikes) become near-zero on the topology side.
local lastSentFlow = {}   -- [edgeKey] = flow (E/s)
local lastSentEff  = {}   -- [edgeKey] = grid efficiency
-- A send is forced if max relative flow change exceeds this OR any eff
-- changed by more than EFF_EPSILON. The thresholds are loose because
-- visual-flow only needs ballpark accuracy: bubble speed ∝ sqrt(flow), so
-- a 10% flow change is ~5% bubble-speed change — well below perception.
local FLOW_REL_EPSILON = 0.10
local FLOW_ABS_EPSILON = 0.5    -- E/s, for tiny flows where relative is noisy
local EFF_EPSILON      = 0.02
-- Force a refresh at least this often even when stable, so any drift in
-- the FS phase extrapolation doesn't accumulate without bound.
local FORCE_SEND_TICKS = 5      -- ~5 seconds at SYNC_PERIOD=30 / 30fps
local ticksSinceSend   = 0

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

-- Track per-tick membership changes per grid. SyncWithGrid then applies them
-- incrementally on top of the cached MST instead of rebuilding the whole grid
-- from scratch — Prim's full rebuild on a 4000-node grid is ~800ms; the
-- incremental path stays in the local-neighborhood of the affected nodes.
--
-- pendingGridDirty[gk] = { ally, gridID, adds = { uid1, uid2, ... }, removes = { uid1, ... } }
-- The same uid never appears in both adds and removes for the same grid in
-- a single tick (membership flip is observed once in step 2 of SyncWithGrid).
local function GetPendingEntry(ally, gridID)
	if not gridID or gridID <= 0 or not ally then return nil end
	local gk = GridKey(ally, gridID)
	local entry = pendingGridDirty[gk]
	if not entry then
		entry = { ally = ally, gridID = gridID, adds = {}, removes = {} }
		pendingGridDirty[gk] = entry
	end
	return entry
end

local function MarkGridAdd(ally, gridID, uid)
	local entry = GetPendingEntry(ally, gridID)
	if entry then entry.adds[#entry.adds + 1] = uid end
end

local function MarkGridRemove(ally, gridID, uid)
	local entry = GetPendingEntry(ally, gridID)
	if entry then entry.removes[#entry.removes + 1] = uid end
end

-- Backward-compat for callers (UnitGiven) that just want to flag a grid as
-- needing reconsideration without naming a specific unit (e.g. when a whole
-- pylon's affiliation changes).
local function MarkGridDirty(ally, gridID)
	GetPendingEntry(ally, gridID)
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
-- Per-grid MST. The MST cache is *incremental*: when a single pylon joins/
-- leaves a grid we patch the local neighbourhood instead of rebuilding the
-- whole tree (Prim's full rebuild on a 4000-node grid is ~800ms; an
-- incremental remove-and-reconnect of one node is ~ms).
--
-- Algorithm:
--  - Add: cheapest cross-edge from new node to current tree (Prim cut prop).
--  - Remove: cut all incident tree edges, identify the resulting components,
--            Borůvka-merge them back via cheapest cross-edges (using the
--            spatial hash so each merge is local-neighborhood-bounded).
--  - From scratch (new grid): Prim's expanding from the highest-production
--    seed; same code path as a "single batch add" into an empty MST.
--
-- Spatial hashing gates candidate pairs to a generous radius so even huge
-- grids stay sub-quadratic; cell size is set so any realistic MST edge
-- falls within a 3x3 cell neighbourhood.
--
-- mstByGrid[gk] = { ally, gridID, members = {[uid]=true}, edges = {[ek]=einfo}, adj = {[uid]={[neighbor]=true}} }
-- `adj` is the persistent undirected adjacency derived from `edges`, kept up
-- to date by MstAddEdge / MstRemoveEdge so incremental ops don't have to
-- rebuild it per call.
-------------------------------------------------------------------------------------

-- (SPATIAL_CELL / MST_CANDIDATE_R_SQ / MST_EUCLIDEAN_MODE are declared near
-- the top of the file so the pylon-neighbour helpers can see them as upvalues.)

-- Build a spatial hash over EVERY pylon in an ally team (not just the ones
-- in a particular grid). Reused across all dirty grids of that ally inside
-- a single SyncWithGrid call. cells[ck] = {uid, ...}, allyNodes[uid] = node.
local function BuildAllySpatialHash(allyTeamID)
	local cells = {}
	local allyNodes = nodes[allyTeamID]
	if not allyNodes then return cells, nil end
	for uid, node in pairs(allyNodes) do
		local cx = floor(node.x / SPATIAL_CELL)
		local cz = floor(node.z / SPATIAL_CELL)
		local ck = cx * 100000 + cz
		local cell = cells[ck]
		if not cell then cell = {}; cells[ck] = cell end
		cell[#cell + 1] = uid
	end
	return cells, allyNodes
end

-- Distance² between two pylons; returns nil if the pair exceeds the candidate
-- cap (so the caller treats them as non-candidates).
local function CandidateDistSq(p, o)
	local dx = p.x - o.x
	local dz = p.z - o.z
	local distSq = dx * dx + dz * dz
	local cap = MST_EUCLIDEAN_MODE and MST_CANDIDATE_R_SQ
		or ((p.range + o.range) * (p.range + o.range))
	if distSq >= cap then return nil end
	return distSq
end

-- Edge add/remove primitives that keep `mst.edges` and `mst.adj` in lock-step.
local function MstAddEdge(mst, fromUid, toUid, einfo)
	mst.edges[EdgeKey(fromUid, toUid)] = einfo
	local af = mst.adj[fromUid]; if not af then af = {}; mst.adj[fromUid] = af end
	local at = mst.adj[toUid];   if not at then at = {}; mst.adj[toUid]   = at end
	af[toUid] = true
	at[fromUid] = true
end

local function MstRemoveEdge(mst, fromUid, toUid)
	mst.edges[EdgeKey(fromUid, toUid)] = nil
	local af = mst.adj[fromUid]; if af then af[toUid] = nil; if not next(af) then mst.adj[fromUid] = nil end end
	local at = mst.adj[toUid];   if at then at[fromUid] = nil; if not next(at) then mst.adj[toUid]   = nil end end
end

-- Mint a fresh edge info record (the einfo shape that downstream consumers expect).
local function MakeEdgeInfo(fromUid, toUid, allyNodes)
	local p1 = allyNodes[fromUid]
	local p2 = allyNodes[toUid]
	return {
		parentID = fromUid, childID = toUid,
		px = p1.x, pz = p1.z, cx = p2.x, cz = p2.z,
	}
end

-- Spatial-hash neighbour iteration: walks the 3×3 cell block around `uid`
-- and invokes `cb(j, distSq)` for every other pylon within candidate cap.
local function ForEachCandidate(uid, allyNodes, cells, cb)
	local p = allyNodes[uid]
	if not p then return end
	local cx = floor(p.x / SPATIAL_CELL)
	local cz = floor(p.z / SPATIAL_CELL)
	for dcx = -1, 1 do
		for dcz = -1, 1 do
			local ck = (cx + dcx) * 100000 + (cz + dcz)
			local cell = cells[ck]
			if cell then
				for ci = 1, #cell do
					local j = cell[ci]
					if j ~= uid then
						local o = allyNodes[j]
						if o then
							local distSq = CandidateDistSq(p, o)
							if distSq then cb(j, distSq) end
						end
					end
				end
			end
		end
	end
end

-- Add a batch of new nodes to the MST via Prim's expansion. The current
-- members form the starting "tree"; pending adds are attached one at a
-- time by cheapest cross-edge. With existing tree as the frontier, this is
-- Prim correct for the merged member set (Cut Property: the cheapest edge
-- crossing any cut is in some MST, so picking cheapest pending↔tree at each
-- step yields an MST).
local function MstAddNodes(mst, addUids, allyNodes, cells)
	if not allyNodes then return end

	local pending = {}    -- [uid] = true
	local toAddCount = 0
	for i = 1, #addUids do
		local uid = addUids[i]
		if not mst.members[uid] and allyNodes[uid] then
			pending[uid] = true
			toAddCount = toAddCount + 1
		end
	end
	if toAddCount == 0 then return end

	-- bestEdge[uid] = { distSq, fromUid } — uid is pending, fromUid is in tree.
	local bestEdge = {}
	-- Seed bestEdge for each pending against current members.
	-- For each pending uid, walk its 3×3 cells and check existing members.
	-- (If tree is currently empty, no seeding happens; we'll bootstrap below.)
	if next(mst.members) then
		for uid in pairs(pending) do
			ForEachCandidate(uid, allyNodes, cells, function(j, distSq)
				if mst.members[j] then
					local cur = bestEdge[uid]
					if not cur or distSq < cur.distSq then
						bestEdge[uid] = { distSq = distSq, fromUid = j }
					end
				end
			end)
		end
	end

	-- Prim expansion loop.
	while toAddCount > 0 do
		-- Pick cheapest pending uid that has a candidate edge.
		local pickUid, pickDistSq = nil, math.huge
		for uid in pairs(pending) do
			local be = bestEdge[uid]
			if be and be.distSq < pickDistSq then
				pickUid, pickDistSq = uid, be.distSq
			end
		end

		if not pickUid then
			-- No reachable pending. Either tree is empty (bootstrap) OR the
			-- remaining pending are unreachable from the tree. In both cases
			-- seed an arbitrary pending as a new member without an edge; the
			-- next iterations will discover edges to it from the rest of the
			-- pending pool via ForEachCandidate's neighbour update below.
			local seed = next(pending)
			mst.members[seed] = true
			pending[seed] = nil
			bestEdge[seed] = nil
			toAddCount = toAddCount - 1

			ForEachCandidate(seed, allyNodes, cells, function(j, distSq)
				if pending[j] then
					local cur = bestEdge[j]
					if not cur or distSq < cur.distSq then
						bestEdge[j] = { distSq = distSq, fromUid = seed }
					end
				end
			end)
		else
			local fromUid = bestEdge[pickUid].fromUid
			mst.members[pickUid] = true
			pending[pickUid] = nil
			bestEdge[pickUid] = nil
			toAddCount = toAddCount - 1
			MstAddEdge(mst, fromUid, pickUid, MakeEdgeInfo(fromUid, pickUid, allyNodes))

			-- Update bestEdge for any pending node whose nearest tree member
			-- might now be the just-added pickUid.
			ForEachCandidate(pickUid, allyNodes, cells, function(j, distSq)
				if pending[j] then
					local cur = bestEdge[j]
					if not cur or distSq < cur.distSq then
						bestEdge[j] = { distSq = distSq, fromUid = pickUid }
					end
				end
			end)
		end
	end
end

-- Remove a batch of nodes from the MST. Cut all incident edges, then
-- identify the components left behind by BFS over `mst.adj` (seeded by
-- the surviving neighbours of the removed nodes). Reconnect components
-- pairwise by cheapest cross-edge until all collapse back into one.
local function MstRemoveNodes(mst, removeUids, allyNodes, cells)
	-- Snapshot the set of removed uids and their surviving neighbours.
	local removedSet = {}
	local seeds = {}
	for i = 1, #removeUids do
		local uid = removeUids[i]
		if mst.members[uid] then
			removedSet[uid] = true
			local nb = mst.adj[uid]
			if nb then
				for n in pairs(nb) do seeds[n] = true end
			end
		end
	end
	if not next(removedSet) then return end
	-- A removed node's neighbours might also be in removedSet; filter them.
	for uid in pairs(removedSet) do seeds[uid] = nil end

	-- Cut all edges incident to any removed uid, then drop the removed members.
	for uid in pairs(removedSet) do
		local nb = mst.adj[uid]
		if nb then
			local toCut = {}
			for n in pairs(nb) do toCut[#toCut + 1] = n end
			for k = 1, #toCut do
				MstRemoveEdge(mst, uid, toCut[k])
			end
		end
		mst.members[uid] = nil
	end

	if not next(seeds) then return end  -- nothing to reconnect (all removed leaves)

	-- Identify components remaining in the cut graph by BFS over mst.adj
	-- seeded at each surviving neighbour of a removed node.
	local componentOf = {}
	local components = {}    -- [seedUid] = { [memberUid] = true }
	local compIds = {}
	for seed in pairs(seeds) do
		if not componentOf[seed] then
			local mem = { [seed] = true }
			componentOf[seed] = seed
			local stack = { seed }
			while #stack > 0 do
				local u = stack[#stack]; stack[#stack] = nil
				local nb = mst.adj[u]
				if nb then
					for n in pairs(nb) do
						if not mem[n] then
							mem[n] = true
							componentOf[n] = seed
							stack[#stack + 1] = n
						end
					end
				end
			end
			components[seed] = mem
			compIds[#compIds + 1] = seed
		end
	end

	if #compIds <= 1 then return end  -- all neighbours converged into one component

	-- Borůvka reconnect: find the globally cheapest cross-edge between any
	-- two components, add it, merge, repeat until one component remains.
	while #compIds > 1 do
		local bestDistSq = math.huge
		local bestFrom, bestTo, bestFromComp, bestToComp = nil, nil, nil, nil
		for ci = 1, #compIds do
			local cid = compIds[ci]
			local mem = components[cid]
			for uid in pairs(mem) do
				ForEachCandidate(uid, allyNodes, cells, function(j, distSq)
					local jcid = componentOf[j]
					if jcid and jcid ~= cid and distSq < bestDistSq then
						bestDistSq = distSq
						bestFrom, bestTo = uid, j
						bestFromComp, bestToComp = cid, jcid
					end
				end)
			end
		end
		if not bestFrom then break end  -- truly disconnected (engine should split gridID first)

		MstAddEdge(mst, bestFrom, bestTo, MakeEdgeInfo(bestFrom, bestTo, allyNodes))

		-- Merge components: union toComp into fromComp.
		local fc = components[bestFromComp]
		local tc = components[bestToComp]
		for u in pairs(tc) do
			fc[u] = true
			componentOf[u] = bestFromComp
		end
		components[bestToComp] = nil
		for i = 1, #compIds do
			if compIds[i] == bestToComp then
				table.remove(compIds, i)
				break
			end
		end
	end
end

-- Mint a fresh, empty MST record for a grid.
local function MakeEmptyMst(allyTeamID, gridID)
	return {
		ally = allyTeamID, gridID = gridID,
		members = {}, edges = {}, adj = {},
	}
end

-- From-scratch build for grids with no cached MST. Uses inline Prim's over
-- a per-grid spatial hash (the same algorithm as the original BuildGridMST
-- before incremental was introduced); fast at large N because the inner
-- loops avoid closures and table lookups stay tight. MstAddNodes is reserved
-- for SMALL incremental add batches into an existing tree where the closure
-- overhead is negligible relative to the savings vs full rebuild.
local function BuildGridMSTFromScratch(allyTeamID, gridID, allyNodes, allyCells)
	local perf = cablePerf
	local tStart = perf and Spring.GetTimer()
	local mst = MakeEmptyMst(allyTeamID, gridID)
	if not allyNodes then return mst end

	-- Collect this grid's pylons + per-pylon position+range in arrays.
	local px, pz, prange, puid = {}, {}, {}, {}
	for uid, node in pairs(allyNodes) do
		if lastGridNum[uid] == gridID then
			local idx = #puid + 1
			puid[idx] = uid
			px[idx] = node.x
			pz[idx] = node.z
			prange[idx] = node.range
		end
	end
	local n = #puid
	if n == 0 then return mst end
	-- Single-member grid: just register the lone pylon, no edges.
	if n == 1 then mst.members[puid[1]] = true; return mst end

	-- (No per-grid spatial hash needed — pylonNeighbours is the precomputed
	-- bidirectional global neighbour index, maintained on UnitCreated.)
	local tHash = perf and Spring.GetTimer()

	-- Per-pylon neighbour list (indices into px/pz/etc) sourced from the
	-- global pylonNeighbours cache, filtered down to pylons in this grid.
	-- Replaces an O(N × cellsize) spatial-hash scan with O(sum of degrees).
	local uidToIdx = {}
	for i = 1, n do uidToIdx[puid[i]] = i end
	local neighbors = {}
	for i = 1, n do
		local nlist = {}
		local nb = pylonNeighbours[puid[i]]
		if nb then
			for nuid in pairs(nb) do
				local idx = uidToIdx[nuid]
				if idx then nlist[#nlist + 1] = idx end
			end
		end
		neighbors[i] = nlist
	end
	local tNeigh = perf and Spring.GetTimer()

	-- Pick highest-Pmax pylon as the seed (stable across wind/load).
	local bestRoot = 1
	local bestProd = -1
	for i = 1, n do
		local prod = GetNodePmax(allyNodes[puid[i]].unitDefID)
		if prod > bestProd then bestProd = prod; bestRoot = i end
	end

	-- Prim with a binary min-heap on the frontier. The previous version did
	-- a linear scan over `bestEdge` per pick → O(N²) overall, which dominated
	-- runtime once N ≳ 1000. The heap pushes each frontier-update in O(log N)
	-- and the pick is O(log N), making the whole MST construction O(E log V).
	-- We use lazy invalidation: when we update a node's bestEdge to a cheaper
	-- distance, we just push a new heap entry; older entries get skipped on
	-- pop because they no longer match `bestEdge[pickJ].distSq`.
	-- Heap is a flat array: entries are integer-packed `distSq * MAX_N + idx`
	-- to avoid per-entry table allocation. (Lua sin sin sin: math, not tables.)
	local inTree = { [bestRoot] = true }
	mst.members[puid[bestRoot]] = true
	local treeSize = 1
	local bestEdge = {}    -- [idx] = { distSq, fromIdx }
	local heapD = {}       -- distSq values; heap[1..#] is the heap
	local heapI = {}       -- frontier idx, parallel array to heapD
	local heapN = 0

	local function heapPush(d, i)
		heapN = heapN + 1
		heapD[heapN] = d
		heapI[heapN] = i
		local ci = heapN
		while ci > 1 do
			local p = floor(ci / 2)
			if heapD[p] > heapD[ci] then
				heapD[ci], heapD[p] = heapD[p], heapD[ci]
				heapI[ci], heapI[p] = heapI[p], heapI[ci]
				ci = p
			else
				break
			end
		end
	end

	local function heapPop()
		if heapN == 0 then return nil, nil end
		local d, i = heapD[1], heapI[1]
		heapD[1], heapI[1] = heapD[heapN], heapI[heapN]
		heapD[heapN], heapI[heapN] = nil, nil
		heapN = heapN - 1
		local ci = 1
		while true do
			local l = ci * 2
			local r = l + 1
			local s = ci
			if l <= heapN and heapD[l] < heapD[s] then s = l end
			if r <= heapN and heapD[r] < heapD[s] then s = r end
			if s == ci then break end
			heapD[ci], heapD[s] = heapD[s], heapD[ci]
			heapI[ci], heapI[s] = heapI[s], heapI[ci]
			ci = s
		end
		return d, i
	end

	do
		local pxi, pzi = px[bestRoot], pz[bestRoot]
		for _, j in ipairs(neighbors[bestRoot]) do
			local dx = pxi - px[j]
			local dz = pzi - pz[j]
			local distSq = dx * dx + dz * dz
			bestEdge[j] = { distSq = distSq, from = bestRoot }
			heapPush(distSq, j)
		end
	end

	while treeSize < n do
		-- Pop cheapest; skip stale entries (already in tree, or superseded
		-- by a cheaper bestEdge update since this entry was pushed).
		local pickD, pickJ
		while true do
			pickD, pickJ = heapPop()
			if not pickJ then break end
			local be = bestEdge[pickJ]
			if be and not inTree[pickJ] and be.distSq == pickD then break end
		end
		if not pickJ then break end
		inTree[pickJ] = true
		treeSize = treeSize + 1
		local fromIdx = bestEdge[pickJ].from
		bestEdge[pickJ] = nil

		local fromUid, toUid = puid[fromIdx], puid[pickJ]
		mst.members[toUid] = true
		MstAddEdge(mst, fromUid, toUid, {
			parentID = fromUid, childID = toUid,
			px = px[fromIdx], pz = pz[fromIdx],
			cx = px[pickJ],   cz = pz[pickJ],
		})

		local pxj, pzj = px[pickJ], pz[pickJ]
		for _, k in ipairs(neighbors[pickJ]) do
			if not inTree[k] then
				local dx = pxj - px[k]
				local dz = pzj - pz[k]
				local distSq = dx * dx + dz * dz
				local cur = bestEdge[k]
				if not cur or distSq < cur.distSq then
					bestEdge[k] = { distSq = distSq, from = pickJ }
					-- Push the new (cheaper) entry; the old heap slot for k
					-- will be skipped on pop because its stored distSq won't
					-- match bestEdge[k].distSq anymore (lazy invalidation).
					heapPush(distSq, k)
				end
			end
		end
	end

	if perf then
		local tEnd = Spring.GetTimer()
		local totalMs  = Spring.DiffTimers(tEnd, tStart) * 1000
		if totalMs > perfStats.worstRebuildMs then
			perfStats.worstRebuildMs    = totalMs
			perfStats.worstRebuildN     = n
			perfStats.worstRebuildHashMs  = Spring.DiffTimers(tHash, tStart) * 1000
			perfStats.worstRebuildNeighMs = Spring.DiffTimers(tNeigh, tHash) * 1000
			perfStats.worstRebuildPrimMs  = Spring.DiffTimers(tEnd, tNeigh) * 1000
		end
	end

	return mst
end

-------------------------------------------------------------------------------------
-- Grid sync: snapshot every pylon's current gridNumber, rebuild every grid in
-- the snapshot, diff resulting edge set against `edges` so survivors keep
-- their stable identity (and unsynced animation state) while drops/adds flip
-- topologyDirty. Stateless w.r.t. previous gridIDs — robust against gridID
-- reuse, merges, splits, and rules-param resets we can't observe.
-------------------------------------------------------------------------------------

local function SyncWithGrid()
	local perf = cablePerf
	local t0 = perf and Spring.GetTimer()

	-- 1) Drop dead units; mark their last-known grid as losing the dying uid.
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
				local node = allyNodes[uid]
				if node then
					PylonRemoveSpatial(allyTeamID, uid, node.x, node.z)
				end
				PylonClearNeighbours(uid)
				MarkGridRemove(allyTeamID, lastGridNum[uid], uid)
				allyNodes[uid] = nil
				lastGridNum[uid] = nil
				allyOfUnit[uid] = nil
				nodeDefByUID[uid] = nil
				consumerNodeIndex[uid] = nil
				lastConsumerDcur[uid] = nil
				minWindByUID[uid] = nil
			end
		end
	end
	local t1 = perf and Spring.GetTimer()

	-- 2) Refresh lastGridNum from rules-params and detect membership changes.
	--    Any pylon whose effective gridID flipped is "removed" from the old
	--    grid AND "added" to the new grid (gridID 0 = inactive, no-op).
	--    Track each migrating uid's source gridID so step 2.5 can transfer
	--    the cached MST when a grid is just being renumbered (engine
	--    reassigns gridIDs on topology shifts → 1000s of pylons going
	--    gridA→gridB in one tick → without rename detection we'd full-
	--    rebuild gridB from scratch).
	local unitFromGrid = {}    -- [uid] = oldG (only for uids that flipped to a non-zero newG)
	for allyTeamID, allyNodes in pairs(nodes) do
		for unitID, _ in pairs(allyNodes) do
			local newG = (IsActiveForGrid(unitID) and (spGetUnitRulesParam(unitID, "gridNumber") or 0)) or 0
			local oldG = lastGridNum[unitID]
			if oldG ~= newG then
				if oldG and oldG > 0 then MarkGridRemove(allyTeamID, oldG, unitID) end
				if newG > 0 then MarkGridAdd(allyTeamID, newG, unitID) end
				lastGridNum[unitID] = newG
				if oldG and oldG > 0 and newG > 0 then
					unitFromGrid[unitID] = oldG
				end
			end
		end
	end

	-- 2.5) MST transfer when a new grid's add-set substantially overlaps an
	--      existing cached MST's members (i.e. the engine just renumbered
	--      most of the grid). Transfer the cache under the new key, then
	--      derive minimal "effective" remove/add lists so the post-transfer
	--      tree converges on the actual new membership in O(diff) instead
	--      of O(N).
	local renames = 0
	for newGk, newInfo in pairs(pendingGridDirty) do
		if not mstByGrid[newGk] and #newInfo.adds > 0 then
			-- Look up source grid via the migration record of any add.
			local sampleUid = newInfo.adds[1]
			local sourceOldG = unitFromGrid[sampleUid]
			if sourceOldG then
				local oldGk = GridKey(newInfo.ally, sourceOldG)
				local oldMst = mstByGrid[oldGk]
				if oldMst then
					-- Count overlap between new adds and old MST members.
					local addsSet = {}
					for _, u in ipairs(newInfo.adds) do addsSet[u] = true end
					local oldMemCount = 0
					local kept = 0
					for u in pairs(oldMst.members) do
						oldMemCount = oldMemCount + 1
						if addsSet[u] then kept = kept + 1 end
					end
					-- Worth transferring only if this is a near-rename (≥75%
					-- retained AND ≤200 cleanup removes). For split scenarios
					-- (e.g. grid cut in half) the cleanup-remove cost on the
					-- larger side dominates; full Prim from scratch on each
					-- piece is cheaper than transfer-then-prune-half.
					local needRemove = oldMemCount - kept
					if oldMemCount > 0 and kept * 4 >= oldMemCount * 3 and needRemove <= 200 then
						oldMst.gridID = newInfo.gridID
						mstByGrid[newGk] = oldMst
						mstByGrid[oldGk] = nil
						-- Build effective remove/add lists relative to the
						-- transferred MST's current members:
						--   remove = oldMembers \ adds (dead or migrated elsewhere)
						--   add    = adds \ oldMembers (genuinely new pylons)
						local effRemoves = {}
						for u in pairs(oldMst.members) do
							if not addsSet[u] then
								effRemoves[#effRemoves + 1] = u
							end
						end
						local effAdds = {}
						for _, u in ipairs(newInfo.adds) do
							if not oldMst.members[u] then
								effAdds[#effAdds + 1] = u
							end
						end
						newInfo.removes = effRemoves
						newInfo.adds = effAdds
						-- Old grid's pending entry is now redundant: its
						-- removes are either covered by effRemoves above
						-- (if they're still in oldMst.members) or never
						-- existed in the MST in the first place.
						pendingGridDirty[oldGk] = nil
						renames = renames + 1
					end
				end
			end
		end
	end
	local t2 = perf and Spring.GetTimer()

	-- 3) Apply per-grid changes. Strategy gating:
	--    a) New grid (no cached MST) → full rebuild via fast Prim's.
	--    b) Big cached MST → full rebuild on any change. The Borůvka
	--       reconnect inside MstRemoveNodes scans every member of every
	--       cut-component looking for cheapest cross-edges; on large dense
	--       grids that's O(N²) and can blow up to seconds. Full Prim is
	--       O(N log N) with much tighter inner loops, so above the size
	--       threshold rebuild is cheaper than incremental.
	--    c) Small cached MST + small diff → incremental.
	--    d) Cached MST + big diff (>50 changes) → also rebuild.
	local INCR_GRID_SIZE_LIMIT = 200  -- skip incremental on grids bigger than this
	local INCR_DIFF_LIMIT      = 50   -- skip incremental on diffs bigger than this
	local rebuilds = 0
	local incrementals = 0
	local allyHashCache = {}  -- [allyTeamID] = { cells, allyNodes }
	local function getAllyHash(allyTeamID)
		local h = allyHashCache[allyTeamID]
		if not h then
			local cells, allyNodesRef = BuildAllySpatialHash(allyTeamID)
			h = { cells = cells, allyNodes = allyNodesRef }
			allyHashCache[allyTeamID] = h
		end
		return h.cells, h.allyNodes
	end
	for gk, info in pairs(pendingGridDirty) do
		local cells, allyNodesRef = getAllyHash(info.ally)
		local mst = mstByGrid[gk]
		local memCount = 0
		if mst then
			for _ in pairs(mst.members) do memCount = memCount + 1 end
		end
		local rebuildFromScratch = (not mst)
			or memCount > INCR_GRID_SIZE_LIMIT
			or #info.removes > INCR_DIFF_LIMIT
			or #info.adds    > INCR_DIFF_LIMIT
		if rebuildFromScratch then
			mst = BuildGridMSTFromScratch(info.ally, info.gridID, allyNodesRef, cells)
			rebuilds = rebuilds + 1
		else
			if #info.removes > 0 then
				MstRemoveNodes(mst, info.removes, allyNodesRef, cells)
			end
			if #info.adds > 0 then
				MstAddNodes(mst, info.adds, allyNodesRef, cells)
			end
			incrementals = incrementals + 1
		end
		if next(mst.members) then
			mstByGrid[gk] = mst
		else
			mstByGrid[gk] = nil
		end
		pendingGridDirty[gk] = nil
	end
	local t3 = perf and Spring.GetTimer()

	-- 4) Compose the desired edge set from cached MSTs.
	local newEdges = {}
	for _, mst in pairs(mstByGrid) do
		for ek, einfo in pairs(mst.edges) do
			newEdges[ek] = einfo
		end
	end
	local t4 = perf and Spring.GetTimer()

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
	if perf then
		local t5 = Spring.GetTimer()
		perfStats.dropMs    = Spring.DiffTimers(t1, t0) * 1000
		perfStats.refreshMs = Spring.DiffTimers(t2, t1) * 1000
		perfStats.mstMs     = Spring.DiffTimers(t3, t2) * 1000
		perfStats.mstRebuilds   = rebuilds
		perfStats.mstIncrements = incrementals
		perfStats.composeMs = Spring.DiffTimers(t4, t3) * 1000
		perfStats.diffMs    = Spring.DiffTimers(t5, t4) * 1000
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
			subWindBase[u] = GetCachedMinWind(u)
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

-- `flowMode = false` skips the per-tick consumer rules-param reads and the
-- post-order subDcur accumulation, returning all flows = 0. At 1500+ pylons
-- this is the bulk of the per-tick cost (the only path that scales with the
-- consumer set size). Capacities still come from the static cache, and edge
-- reorientation falls back to capacity direction so the layout stays stable.
local function ComputeMaxPotentials(flowMode)
	local perf = cablePerf
	local tBuild0 = perf and Spring.GetTimer()
	if not mpCache.valid then BuildMpCache() end
	local tBuild1 = perf and Spring.GetTimer()
	local order          = mpCache.order
	local parentInTree   = mpCache.parentInTree
	local componentRoot  = mpCache.componentRoot
	local subPmax        = mpCache.subPmax
	local subDmax        = mpCache.subDmax

	local subPcur, subDcur
	if flowMode then
		local subPmaxNonWind = mpCache.subPmaxNonWind
		local subWindCount   = mpCache.subWindCount
		local subWindBase    = mpCache.subWindBase

		-- ZK's per-windmill formula (unit_windmill_control.lua:142):
		--   windEnergy_i = (windMax − curr_strength) * myMin_i + curr_strength
		-- This is linear in curr_strength, so the subtree sum is also linear:
		--   Σ windE = subWindBase * (1 − f) + windMax * f * subWindCount
		-- where f = curr_strength / windMax = WindStrength rules-param ∈ [0,1].
		--
		-- IMPORTANT: ZK's `strength` and Spring.GetWind() are different. The
		-- engine-side GetWind() is NOT capped to windMax (returns ~27 on a
		-- map whose windMax=2.5) — using it forces windFrac to clamp to 1
		-- every tick, attributing windMax × N to wind output (~2× truth).
		-- The authoritative ZK value is GameRulesParam("WindStrength").
		local windMax = Spring.GetGameRulesParam("WindMax") or 2.5
		local windFrac = GetCurWindFrac()

		-- subPcur from cached aggregates: 0 per-pylon reads.
		subPcur = {}
		for i = 1, #order do
			local u = order[i]
			subPcur[u] = subWindBase[u] + windFrac * (windMax * subWindCount[u] - subWindBase[u])
				+ subPmaxNonWind[u]
		end

		-- Consumer reads still per-tick (mex draw / builder energyUse fluctuate).
		subDcur = {}
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

		local flow, flowSrcSubtree
		if flowMode then
			local totalPcur, totalDcur = subPcur[r], subDcur[r]
			local sPc, sDc = subPcur[cid], subDcur[cid]
			local oPc, oDc = totalPcur - sPc, totalDcur - sDc
			local flowAB = (sPc < oDc) and sPc or oDc
			local flowBA = (oPc < sDc) and oPc or sDc
			if flowAB >= flowBA then
				flow, flowSrcSubtree = flowAB, true
			else
				flow, flowSrcSubtree = flowBA, false
			end
			if flow < 0 then flow = 0 end
			if flow <= 0 then flowSrcSubtree = potentialSrcSubtree end
		else
			flow, flowSrcSubtree = 0, potentialSrcSubtree
		end
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

	if perf then
		local tEnd = Spring.GetTimer()
		perfStats.mpBuildMs   = Spring.DiffTimers(tBuild1, tBuild0) * 1000
		perfStats.mpComputeMs = Spring.DiffTimers(tEnd, tBuild1) * 1000
	end

	return capacities, flows
end

-------------------------------------------------------------------------------------
-- Hand a Full snapshot to the rendering side. One snapshot per ally; the
-- per-ally batching is preserved because OnCableTreeFull's diff is per-ally.
-- Capacity drift between topology changes is ignored (acceptable: cable
-- colour only updates when the grid actually mutates).
-------------------------------------------------------------------------------------

-- Returns true if newFlow differs enough from oldFlow to warrant a re-send.
-- Loose absolute floor + a relative threshold above it: small absolute flows
-- are noisy (mex draw fluctuates by ±0.x E/s as targets move), while large
-- ones need relative tolerance because bubble speed ∝ sqrt(flow).
local function flowChanged(newFlow, oldFlow)
	local d = newFlow - oldFlow
	if d < 0 then d = -d end
	if d <= FLOW_ABS_EPSILON then return false end
	local base = oldFlow
	if base < 0 then base = -base end
	if base < FLOW_ABS_EPSILON then return true end  -- big abs change off ~zero
	return (d / base) > FLOW_REL_EPSILON
end

-- Cheap pre-check that runs BEFORE ComputeMaxPotentials. The mp.compute
-- pass is O(N) over every pylon (~4ms at 4000 nodes) — running it just to
-- discover "nothing changed" is wasted work. Instead, sample only the
-- consumer-typed nodes (typically ~50 of 4000) plus the wind state; if
-- nothing has shifted, skip mp + bin + dispatch entirely. The bubble shader
-- keeps extrapolating from its last bake at the last-sent speed, which is
-- the correct visual when flows haven't changed.
local function ConsumersOrWindChanged()
	for uid, did in pairs(consumerNodeIndex) do
		local cur = GetNodeDcurrent(uid, did)
		local last = lastConsumerDcur[uid]
		if not last or math.abs(cur - last) > 0.5 then
			return true
		end
	end
	if math.abs(GetCurWindFrac() - lastWindFrac) > 0.05 then return true end
	return false
end

local function SendAll()
	local perf = cablePerf

	-- O(consumers) early-skip BEFORE the expensive O(N) ComputeMaxPotentials.
	-- Topology changes always force through; FORCE_SEND_TICKS clamps drift.
	ticksSinceSend = ticksSinceSend + 1
	if not topologyDirty and ticksSinceSend < FORCE_SEND_TICKS then
		if not ConsumersOrWindChanged() then
			if perf then perfStats.skipped = (perfStats.skipped or 0) + 1 end
			return false
		end
	end

	local capacities, flows = ComputeMaxPotentials(cableFlowMode)

	-- Belt-and-suspenders flow-comparison: even after consumer/wind changed,
	-- the resulting flows may still be within tolerance (binding constraint
	-- elsewhere). Skip if no edge's flow changed visibly.
	if not topologyDirty and ticksSinceSend < FORCE_SEND_TICKS then
		local anyChanged = false
		for key, _ in pairs(edges) do
			local newFlow = flows[key] or 0
			local oldFlow = lastSentFlow[key]
			if oldFlow == nil or flowChanged(newFlow, oldFlow) then
				anyChanged = true
				break
			end
		end
		if not anyChanged then
			if perf then perfStats.skipped = (perfStats.skipped or 0) + 1 end
			return false
		end
	end
	ticksSinceSend = 0

	local tBin0 = perf and Spring.GetTimer()

	-- Per-grid efficiency cache. gridefficiency is uniform across a whole
	-- grid (set on every member by unit_mex_overdrive), so reading it per
	-- edge does ~2*E rules-param reads where ~G (G = number of distinct
	-- grids, typically <10) suffices. At 460+ edges this turns ~900 reads
	-- into ~5. lastGridNum is the SyncWithGrid-maintained gridID per pylon.
	local effByGrid = {}
	local function gridEffForUnit(uid)
		local gid = lastGridNum[uid]
		if not gid or gid == 0 then return nil end
		local cached = effByGrid[gid]
		if cached ~= nil then return cached end
		local eff = spGetUnitRulesParam(uid, "gridefficiency")
		if eff and eff < 0 then eff = 0 end
		effByGrid[gid] = eff or false  -- `false` distinguishes "tried, nil" from "uncached"
		return eff
	end

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
			-- Cached per-grid lookup; fall back to child end if parent's grid
			-- is unknown. 0 → magenta in the shader (unit_mex_overdrive's
			-- "no grid" sentinel).
			local eff = gridEffForUnit(edge.parentID) or gridEffForUnit(edge.childID) or 0
			pa.effs[i] = eff
			-- Snapshot for the next tick's stability check.
			lastSentFlow[key] = pa.flows[i]
			lastSentEff[key]  = eff
		end
	end
	local tBin1 = perf and Spring.GetTimer()

	-- One snapshot per ally that currently has edges.
	for ally, pa in pairs(perAlly) do
		OnCableTreeFull({
			allyTeamID = ally, edgeCount = pa.n,
			keys = pa.keys, pxs = pa.pxs, pzs = pa.pzs,
			cxs = pa.cxs, czs = pa.czs,
			caps = pa.caps, flows = pa.flows, effs = pa.effs,
		})
		alliesWithEdges[ally] = true
	end

	-- Allies whose last edge just disappeared get one zero-edge snapshot so
	-- the renderer clears them; then we forget them.
	for ally in pairs(alliesWithEdges) do
		if not perAlly[ally] then
			OnCableTreeFull({
				allyTeamID = ally, edgeCount = 0,
				keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {},
				caps = {}, flows = {}, effs = {},
			})
			alliesWithEdges[ally] = nil
		end
	end
	-- Update the snapshots ConsumersOrWindChanged() compares against next
	-- tick. Doing this only on the success path means a skipped tick keeps
	-- the previous baseline so a stable run continues to skip.
	for uid, did in pairs(consumerNodeIndex) do
		lastConsumerDcur[uid] = GetNodeDcurrent(uid, did)
	end
	lastWindFrac = GetCurWindFrac()

	if perf then
		local tEnd = Spring.GetTimer()
		perfStats.binMs      = Spring.DiffTimers(tBin1, tBin0) * 1000
		perfStats.dispatchMs = Spring.DiffTimers(tEnd, tBin1) * 1000
	end
end

-------------------------------------------------------------------------------------
-- GameFrame
-------------------------------------------------------------------------------------

-- Sends one zero-edge snapshot per ally that currently has cables, so the
-- renderer clears its geometry. Used when the visualization is toggled off
-- so no stale cables linger.
local function ClearAll()
	for ally in pairs(alliesWithEdges) do
		OnCableTreeFull({
			allyTeamID = ally, edgeCount = 0,
			keys = {}, pxs = {}, pzs = {}, cxs = {}, czs = {},
			caps = {}, flows = {}, effs = {},
		})
	end
	alliesWithEdges = {}
	edges = {}
	topologyDirty = false
	-- Reset stability snapshots; on next enable, all edges read as new.
	lastSentFlow = {}
	lastSentEff  = {}
	ticksSinceSend = 0
end

-- Periodic topology refresh + send. Driven by gadget:GameFrame on the
-- SYNC_PERIOD cadence so the cost is bounded regardless of how often pylons
-- move/build.
local function RunSyncTick(n)
	if not cableEnabled then return end
	if n % SYNC_PERIOD == 2 then
		local perf = cablePerf
		local tStart = perf and Spring.GetTimer()
		SyncWithGrid()
		-- Flow mode: always send (flow magnitudes + grid efficiency colour
		-- change every tick). No-flow mode: only send on topology change —
		-- there's no per-tick state to refresh, and the per-tick send cost
		-- (capacity-only ComputeMaxPotentials + per-ally upload) is the
		-- entire point of the toggle.
		local sentThisTick = false
		if cableFlowMode or topologyDirty then
			-- SendAll returns false when its stability check short-circuited.
			sentThisTick = (SendAll() ~= false)
			topologyDirty = false
		end
		if perf then
			local tEnd = Spring.GetTimer()
			local nEdges = 0
			for _ in pairs(edges) do nEdges = nEdges + 1 end
			local nNodes = 0
			for _, allyNodes in pairs(nodes) do
				for _ in pairs(allyNodes) do nNodes = nNodes + 1 end
			end
			-- Total wallclock for this tick (sync + send).
			local totalMs = Spring.DiffTimers(tEnd, tStart) * 1000
			local rebuildLine = ""
			if perfStats.worstRebuildMs > 0 then
				rebuildLine = string.format(
					" | worstRebuild=%dms[N=%d hash=%.1f neigh=%.1f prim=%.1f]",
					perfStats.worstRebuildMs, perfStats.worstRebuildN,
					perfStats.worstRebuildHashMs, perfStats.worstRebuildNeighMs,
					perfStats.worstRebuildPrimMs)
			end
			Spring.Echo(string.format(
				"[CableTree] tick: nodes=%d edges=%d total=%.2fms | " ..
				"sync(drop=%.2f refresh=%.2f mst=%.2f[rebuild=%d incr=%d] compose=%.2f diff=%.2f) | " ..
				"mp(build=%.2f compute=%.2f) | send(bin=%.2f dispatch=%.2f sent=%s flow=%s skipped=%d)%s",
				nNodes, nEdges, totalMs,
				perfStats.dropMs, perfStats.refreshMs, perfStats.mstMs,
				perfStats.mstRebuilds, perfStats.mstIncrements,
				perfStats.composeMs, perfStats.diffMs,
				perfStats.mpBuildMs, perfStats.mpComputeMs,
				perfStats.binMs, perfStats.dispatchMs,
				tostring(sentThisTick), tostring(cableFlowMode),
				perfStats.skipped or 0,
				rebuildLine))
			-- Reset per-tick stats so the next tick starts clean.
			perfStats.binMs, perfStats.dispatchMs = 0, 0
			perfStats.mpBuildMs, perfStats.mpComputeMs = 0, 0
			perfStats.worstRebuildMs, perfStats.worstRebuildN = 0, 0
			perfStats.worstRebuildHashMs = 0
			perfStats.worstRebuildNeighMs = 0
			perfStats.worstRebuildPrimMs  = 0
		end
	end
end

local DETAIL_KEYS = { off = DETAIL_OFF, noflow = DETAIL_NOFLOW, full = DETAIL_FULL }
local DETAIL_NAMES = { [DETAIL_OFF] = "off", [DETAIL_NOFLOW] = "noflow", [DETAIL_FULL] = "full" }

-- Single point that mutates the visualisation state. Sets cableEnabled +
-- cableFlowMode atomically so the FS uniform and the topology-loop gating
-- stay consistent. Persists to Spring config and forces one immediate send
-- so the new state shows up without waiting for the next tick.
local function SetDetailLevel(level)
	if level == cableDetail then return end
	cableDetail = level
	cableEnabled  = level ~= DETAIL_OFF
	cableFlowMode = level == DETAIL_FULL
	Spring.SetConfigInt("OverdriveCableDetail", level)
	if level == DETAIL_OFF then
		ClearAll()
	else
		-- Reset stability snapshots so the next SendAll definitely fires
		-- (toggling between noflow ↔ full needs to push the new flow values
		-- to the renderer; the FS uniform also needs the new enableFlow).
		lastSentFlow = {}
		lastSentEff  = {}
		ticksSinceSend = FORCE_SEND_TICKS  -- force-send next tick
		topologyDirty = true
		SendAll()
		topologyDirty = false
	end
end

-- /cabletree detail off|noflow|full  — set detail level (the menu widget
--                                       drives this; can also be typed)
-- /cabletree perf                    — toggle per-cycle timing log
-- /cabletree status                  — print current state
local function CableTreeCmd(cmd, line, words, playerID)
	local arg = (words and words[1]) or ""
	if arg == "detail" then
		local key = (words and words[2]) or ""
		local lvl = DETAIL_KEYS[key]
		if lvl then
			SetDetailLevel(lvl)
			Spring.Echo("[CableTree] detail=" .. DETAIL_NAMES[cableDetail])
		else
			Spring.Echo("[CableTree] usage: /cabletree detail off|noflow|full")
		end
	elseif arg == "perf" then
		cablePerf = not cablePerf
		Spring.Echo("[CableTree] perf logging " .. (cablePerf and "ON" or "OFF"))
	elseif arg == "status" then
		local nEdges = 0
		for _ in pairs(edges) do nEdges = nEdges + 1 end
		Spring.Echo(string.format(
			"[CableTree] detail=%s perf=%s edges=%d",
			DETAIL_NAMES[cableDetail], tostring(cablePerf), nEdges))
	else
		Spring.Echo("[CableTree] usage: /cabletree detail off|noflow|full | perf | status")
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
	if consumerByDef[unitDefID] then
		consumerNodeIndex[unitID] = unitDefID
	end
	-- Add to global spatial hash + compute neighbours (bidirectional, written
	-- into both this pylon's and each candidate's pylonNeighbours table).
	PylonAddSpatial(allyTeamID, unitID, x, z)
	PylonBuildNeighbours(allyTeamID, unitID)
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
		-- Old ally's grid loses this specific pylon: queue an incremental
		-- remove so SyncWithGrid patches the MST without rebuilding it.
		MarkGridRemove(oldAlly, lastGridNum[unitID], unitID)
		local oldNode = nodes[oldAlly] and nodes[oldAlly][unitID]
		if oldNode then
			PylonRemoveSpatial(oldAlly, unitID, oldNode.x, oldNode.z)
		end
		PylonClearNeighbours(unitID)
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
			if consumerByDef[unitDefID] then
				consumerNodeIndex[unitID] = unitDefID
			end
			PylonAddSpatial(newAlly, unitID, x, z)
			PylonBuildNeighbours(newAlly, unitID)
		else
			consumerNodeIndex[unitID] = nil
			lastConsumerDcur[unitID] = nil
		end
	end
end

-- Topology setup: registers chat command, scans pre-existing pylons (for
-- luarules-reload paths). Called from gadget:Initialize below — the rendering
-- half's Initialize is the one entry point now that there is no synced tier.
local function InitTopology()
	gadgetHandler:AddChatAction("cabletree", CableTreeCmd)
	-- First pass: register every existing pylon in nodes + spatial hash.
	-- Second pass: build neighbour lists (so each pylon can see the others
	-- that were also added in pass one).
	local seenUnits = {}
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
			if consumerByDef[unitDefID] then
				consumerNodeIndex[unitID] = unitDefID
			end
			PylonAddSpatial(allyTeamID, unitID, x, z)
			seenUnits[#seenUnits + 1] = { unitID, allyTeamID }
		end
	end
	for i = 1, #seenUnits do
		PylonBuildNeighbours(seenUnits[i][2], seenUnits[i][1])
	end
end

-------------------------------------------------------------------------------------
-- Rendering side: shader-based cable drawing via DrawWorldPreUnit. Cables are
-- drawn as quad strips projected onto ground height; fragment shader provides
-- procedural organic texture + LOS-gated animation.
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
-- One singu's output (energysingu.energyMake = 225) saturates the cable to
-- max thickness. Below that, thickness scales linearly with capacity.
local MAX_CAPACITY_REF = 225

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
local BUBBLE_CAP_REF        = MAX_CAPACITY_REF

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
-- (drawPerf collapsed into cablePerf at the top of the file; flowMode
-- collapsed into cableFlowMode. Both names live in the topology block above.)
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
		local isOwn = e.isOwnAlly and 1 or 0

		-- Vertex 0: parent end (9 floats: pos2 + data3 + grid4)
		verts[k+1] = e.px;          verts[k+2] = e.pz
		verts[k+3] = cap;           verts[k+4] = appearTime;  verts[k+5] = witherTime
		verts[k+6] = eff;           verts[k+7] = flow;        verts[k+8] = phase;       verts[k+9] = isOwn
		-- Vertex 1: child end (same per-edge payload)
		verts[k+10] = e.cx;         verts[k+11] = e.cz
		verts[k+12] = cap;          verts[k+13] = appearTime; verts[k+14] = witherTime
		verts[k+15] = eff;          verts[k+16] = flow;       verts[k+17] = phase;      verts[k+18] = isOwn
		k = k + 18
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

-- Cable shader sources live in dedicated .glsl files alongside the gadget
-- (LuaRules/Gadgets/Shaders/) so they get proper editor syntax highlighting
-- and the gadget itself stays focused on Lua state. The placeholder
-- '//__ENGINEUNIFORMBUFFERDEFS__' inside the GS/FS files is substituted at
-- shader-compile time in gadget:Initialize below.
local SHADER_DIR = 'LuaRules/Gadgets/Shaders/'
local cableVSSrc = VFS.LoadFile(SHADER_DIR .. 'gfx_overdrive_cables.vert.glsl')
local cableGSSrc = VFS.LoadFile(SHADER_DIR .. 'gfx_overdrive_cables.geom.glsl')
local cableFSSrc = VFS.LoadFile(SHADER_DIR .. 'gfx_overdrive_cables.frag.glsl')

-------------------------------------------------------------------------------------
-- Receive data from synced
-------------------------------------------------------------------------------------

-- Whether the local viewer should treat `allyTeamID`'s cables as "own"
-- (always visible, optionally ghosted out of LOS) vs "enemy" (only visible
-- inside actual LOS). Specs and full-view see everything as own.
local function isOwnAlly(allyTeamID)
	local spec, fullview = spGetSpectatingState()
	if (spec or fullview) then return true end
	return allyTeamID == spGetMyAllyTeamID()
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
-- Bound to the forward-declared local at the top of the file so the
-- topology side can call it directly.
function OnCableTreeFull(data)
	if not data then return end
	local ally = data.allyTeamID
	-- Always accept; the FS gates enemy fragments by LOS so unscouted enemy
	-- cables are invisible without dropping their data here.
	local ownAlly = isOwnAlly(ally)

	local tStart = cablePerf and Spring.GetTimer() or nil
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
			e.isOwnAlly = ownAlly
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
				isOwnAlly = ownAlly,
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
	local tDiff = cablePerf and Spring.GetTimer() or nil
	RebuildRenderEdges()
	needsRebuild = true

	if cablePerf then
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
	local tStart = cablePerf and Spring.GetTimer() or nil

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

	local tGen0 = cablePerf and Spring.GetTimer() or nil
	local verts, vertCount = GenerateOrganicTree()
	if vertCount == 0 then
		numCableVerts = 0
		needsRebuild = false
		return
	end

	cableVAO = nil
	local vbo = gl.GetVBO(GL.ARRAY_BUFFER, false)
	if not vbo then return end
	-- Per-vertex layout (9 floats): vertPos(2) + vertData(3) + vertGrid(4).
	-- Two vertices per cable form one GL_LINES primitive; the geometry shader
	-- expands each line into a wiggly ribbon at draw time.
	vbo:Define(vertCount, {
		{ id = 0, name = "vertPos",   size = 2 },
		{ id = 1, name = "vertData",  size = 3 },  -- (capacity, appearTime, witherTime)
		{ id = 2, name = "vertGrid",  size = 4 },  -- (efficiency, flow E/s, bubble phase elmos, isOwnAlly)
	})
	local tUp0 = cablePerf and Spring.GetTimer() or nil
	vbo:Upload(verts)
	cableVAO = gl.GetVAO()
	if cableVAO then cableVAO:AttachVertexBuffer(vbo) end
	numCableVerts = vertCount
	needsRebuild = false

	if cablePerf then
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
	-- 1) Topology refresh (was previously a synced gadget:GameFrame). Runs
	--    on the SYNC_PERIOD cadence, may invoke OnCableTreeFull (sets
	--    needsRebuild) and update edgesByAllyTeam.
	RunSyncTick(n)

	-- 2) Drop fully-withered edges so geometry doesn't grow unboundedly.
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

	-- 3) Rebuild immediately when dirty. Throttling caused visible phase
	--    jumps: between OnCableTreeFull (which mutates per-edge bubbleSpeed)
	--    and the rebake, the shader still extrapolates with the OLD speed,
	--    then snaps to the new baked state. The jump magnitude is
	--    Δspeed × (bakeTime - nowSec) so any latency here directly produces
	--    a visible discontinuity.
	if needsRebuild then
		RebuildVBO()
	end
end

function gadget:DrawWorldPreUnit()
	if not cableVAO or numCableVerts == 0 or not cableShader then return end

	cableShader:Activate()
	-- Smooth gameTime: GetGameSeconds() ticks at the sim rate (GAME_SPEED).
	-- At higher game speeds each sim step covers more game-time, so the
	-- per-frame phase delta the FS sees gets bigger and bubbles visibly jump
	-- between sim ticks. Adding GetFrameTimeOffset() (the [0,1] fraction
	-- through the current sim interval, used by the engine for visual interp)
	-- divided by GAME_SPEED gives a continuous time that advances smoothly
	-- between sim ticks on all game speeds.
	local frameOff = Spring.GetFrameTimeOffset and Spring.GetFrameTimeOffset() or 0
	cableShader:SetUniform("gameTime", Spring.GetGameSeconds() + frameOff / GAME_SPEED)
	cableShader:SetUniform("bakeTime", bubbleBakeTime)
	cableShader:SetUniform("enableFlow", cableFlowMode and 1.0 or 0.0)

	-- $info:los is the actual game-logic LOS texture (single-channel red), NOT
	-- the user's visual LOS-overlay (which is what plain $info samples and which
	-- becomes a height-map view when the overlay is toggled off — defeating any
	-- LOS gating done against it).
	gl.Texture(0, "$info:los")
	gl.Texture(1, "$heightmap")
	gl.Culling(false)
	gl.DepthTest(GL.LEQUAL)
	gl.DepthMask(true)
	-- Fully opaque output — every path writes alpha=1.0 (enemy ghost branch
	-- is gone; out-of-LOS enemy fragments are discarded). Disable blending
	-- so depth-tested cables compose cleanly against the world.
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
			enableFlow = cableFlowMode and 1.0 or 0.0,
		},
	}, "Cable Forward Shader")

	if not cableShader:Initialize() then
		Spring.Echo("[CableTree] Shader compile failed")
		gadgetHandler:RemoveGadget()
		return
	end
	-- Topology side: register chat command + scan existing pylons.
	InitTopology()
end

function gadget:Shutdown()
	if cableShader then cableShader:Finalize() end
	cableVAO = nil
end

