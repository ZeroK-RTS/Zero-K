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
-- UNSYNCED — PCB-style cable rendering onto ground texture
-------------------------------------------------------------------------------------

local glTexture       = gl.Texture
local glCreateTexture = gl.CreateTexture
local glColor         = gl.Color
local glTexRect       = gl.TexRect
local glResetState    = gl.ResetState
local glResetMatrices = gl.ResetMatrices
local glVertex        = gl.Vertex

local spGetMapSquareTexture = Spring.GetMapSquareTexture
local spSetMapSquareTexture = Spring.SetMapSquareTexture
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetSpectatingState  = Spring.GetSpectatingState

local floor = math.floor
local sqrt  = math.sqrt
local max   = math.max
local min   = math.min
local abs   = math.abs
local PI    = math.pi
local cos   = math.cos
local sin   = math.sin

local MAP_WIDTH    = Game.mapSizeX
local MAP_HEIGHT   = Game.mapSizeZ
local SQUARE_SIZE  = 1024
local SQUARES_X    = MAP_WIDTH / SQUARE_SIZE
local SQUARES_Z    = MAP_HEIGHT / SQUARE_SIZE

-------------------------------------------------------------------------------------
-- PCB style config
-------------------------------------------------------------------------------------

local MIN_TRACE_WIDTH  = 5     -- min trace width in elmos
local MAX_TRACE_WIDTH  = 22    -- max trace width in elmos
local MAX_CAPACITY_REF = 100
local PAD_RADIUS_MULT  = 1.8   -- pad radius = trace_width * this
local PAD_SEGMENTS     = 12    -- polygon segments for circular pads
local VIA_RADIUS       = 3     -- small via dots along traces
local VIA_SPACING      = 80    -- elmos between via dots

-- Colors (copper on dark substrate)
local TRACE_BORDER_COLOR = { 0.02, 0.04, 0.06, 0.92 }
local TRACE_COPPER_COLOR = { 0.75, 0.55, 0.20, 0.95 } -- default copper
local PAD_BORDER_COLOR   = { 0.02, 0.04, 0.06, 0.95 }
local PAD_COPPER_COLOR   = { 0.85, 0.65, 0.25, 0.95 }
local VIA_COLOR          = { 0.15, 0.12, 0.08, 0.90 }

-------------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------------

local squareFBOs = {}
local renderEdges = {}
local edgesByAllyTeam = {}
local lastVersions = {}
local needsRedraw = false
local drawnSquares = {}

-------------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------------

local function SquareKey(sx, sz)
	return sx * 10000 + sz
end

local function GetTraceWidth(capacity)
	local t = min(1, capacity / MAX_CAPACITY_REF)
	return MIN_TRACE_WIDTH + t * (MAX_TRACE_WIDTH - MIN_TRACE_WIDTH)
end

-- Get trace color based on capacity (copper tint shifts brighter with more flow)
local function GetTraceColor(capacity)
	local t = min(1, capacity / MAX_CAPACITY_REF)
	return 0.55 + t * 0.35,   -- R: warm copper to bright gold
	       0.40 + t * 0.30,   -- G
	       0.12 + t * 0.15,   -- B
	       0.95
end

-------------------------------------------------------------------------------------
-- PCB routing: Manhattan + 45° chamfer
-- Returns list of segments { {x1, z1, x2, z2}, ... }
-------------------------------------------------------------------------------------

local function RoutePCB(x1, z1, x2, z2)
	local dx = x2 - x1
	local dz = z2 - z1
	local adx = abs(dx)
	local adz = abs(dz)

	if adx < 2 or adz < 2 then
		return {{ x1, z1, x2, z2 }}
	end

	local diagLen = min(adx, adz)
	local segments = {}

	if adx >= adz then
		local horizLen = adx - diagLen
		local sx = (dx > 0) and 1 or -1
		local mx = x1 + sx * horizLen
		if horizLen > 2 then
			segments[#segments + 1] = { x1, z1, mx, z1 }
		end
		segments[#segments + 1] = { mx, z1, x2, z2 }
	else
		local vertLen = adz - diagLen
		local sz = (dz > 0) and 1 or -1
		local mz = z1 + sz * vertLen
		if vertLen > 2 then
			segments[#segments + 1] = { x1, z1, x1, mz }
		end
		segments[#segments + 1] = { x1, mz, x2, z2 }
	end

	return segments
end

-------------------------------------------------------------------------------------
-- Segment merging: when multiple routed edges produce collinear overlapping
-- segments, merge them into a single segment with accumulated capacity.
-- Only merges axis-aligned (horizontal/vertical) segments.
-------------------------------------------------------------------------------------

local SNAP = 16 -- snap resolution for merging (elmos)

local function SegKey(isHoriz, fixed, lo, hi)
	-- Key for an axis-aligned segment: axis + snapped fixed coord + interval
	return (isHoriz and "H" or "V") .. floor(fixed / SNAP) .. ":" .. floor(lo / SNAP) .. ":" .. floor(hi / SNAP)
end

local function MergeSegments(rawSegments)
	-- rawSegments = { {x1,z1,x2,z2,capacity}, ... }
	-- Returns merged list: { {x1,z1,x2,z2,capacity}, ... }

	local axisSegs = {} -- [segKey] = { fixed, lo, hi, capacity, isHoriz }
	local diagSegs = {} -- diagonal segments can't be merged, pass through

	for i = 1, #rawSegments do
		local s = rawSegments[i]
		local dx = abs(s[3] - s[1])
		local dz = abs(s[4] - s[2])

		if dz < 2 then
			-- Horizontal segment
			local fixed = s[2]
			local lo = min(s[1], s[3])
			local hi = max(s[1], s[3])
			local key = SegKey(true, fixed, lo, hi)
			if axisSegs[key] then
				axisSegs[key].capacity = axisSegs[key].capacity + s[5]
			else
				axisSegs[key] = { fixed = fixed, lo = lo, hi = hi, capacity = s[5], isHoriz = true }
			end
		elseif dx < 2 then
			-- Vertical segment
			local fixed = s[1]
			local lo = min(s[2], s[4])
			local hi = max(s[2], s[4])
			local key = SegKey(false, fixed, lo, hi)
			if axisSegs[key] then
				axisSegs[key].capacity = axisSegs[key].capacity + s[5]
			else
				axisSegs[key] = { fixed = fixed, lo = lo, hi = hi, capacity = s[5], isHoriz = false }
			end
		else
			-- Diagonal — just pass through
			diagSegs[#diagSegs + 1] = { s[1], s[2], s[3], s[4], capacity = s[5] }
		end
	end

	-- Convert back to segment list with named fields
	local result = {}
	for _, seg in pairs(axisSegs) do
		local w = GetTraceWidth(seg.capacity)
		if seg.isHoriz then
			result[#result + 1] = { x1 = seg.lo, z1 = seg.fixed, x2 = seg.hi, z2 = seg.fixed, width = w, capacity = seg.capacity }
		else
			result[#result + 1] = { x1 = seg.fixed, z1 = seg.lo, x2 = seg.fixed, z2 = seg.hi, width = w, capacity = seg.capacity }
		end
	end
	for i = 1, #diagSegs do
		local d = diagSegs[i]
		local w = GetTraceWidth(d.capacity)
		result[#result + 1] = { x1 = d[1], z1 = d[2], x2 = d[3], z2 = d[4], width = w, capacity = d.capacity }
	end

	return result
end

-------------------------------------------------------------------------------------
-- Drawing primitives (all in FBO NDC space)
-------------------------------------------------------------------------------------

-- Convert world coords to FBO NDC [-1, 1] for a given square
local function MakeW2T(sqX, sqZ)
	return function(wx, wz)
		return 2 * (wx - sqX) / SQUARE_SIZE - 1,
		       2 * (wz - sqZ) / SQUARE_SIZE - 1
	end
end

-- Emit a quad for a trace segment (call inside gl.BeginEnd GL.QUADS)
local function EmitTraceQuad(w2t, x1, z1, x2, z2, hw)
	local dx = x2 - x1
	local dz = z2 - z1
	local len = sqrt(dx * dx + dz * dz)
	if len < 0.5 then return end

	local px = -dz / len * hw
	local pz =  dx / len * hw

	local t1x, t1z = w2t(x1 - px, z1 - pz)
	local t2x, t2z = w2t(x1 + px, z1 + pz)
	local t3x, t3z = w2t(x2 + px, z2 + pz)
	local t4x, t4z = w2t(x2 - px, z2 - pz)

	glVertex(t1x, t1z, 0)
	glVertex(t2x, t2z, 0)
	glVertex(t3x, t3z, 0)
	glVertex(t4x, t4z, 0)
end

-- Emit a filled circle (call inside gl.BeginEnd GL.TRIANGLE_FAN)
local function EmitCircle(w2t, cx, cz, radius)
	local tx, tz = w2t(cx, cz)
	glVertex(tx, tz, 0) -- center
	for i = 0, PAD_SEGMENTS do
		local angle = (i / PAD_SEGMENTS) * PI * 2
		local px, pz = w2t(cx + cos(angle) * radius, cz + sin(angle) * radius)
		glVertex(px, pz, 0)
	end
end

-------------------------------------------------------------------------------------
-- Drawing hook
-------------------------------------------------------------------------------------

function gadget:DrawGenesis()
	if not needsRedraw then return end
	if #renderEdges == 0 then
		needsRedraw = false
		return
	end

	glResetState()
	glResetMatrices()

	-- Revert previously modified squares
	for _, sq in pairs(drawnSquares) do
		spSetMapSquareTexture(sq.sx, sq.sz, "")
	end

	-- Step 1: Route all edges as PCB segments, collect raw segments with capacity
	local rawSegments = {}
	local allPads = {}
	local padSet = {}
	local maxPadRadius = {}  -- [padKey] = max radius seen

	for i = 1, #renderEdges do
		local e = renderEdges[i]
		if e.length > 0 then
			local frac = min(1, e.progress / e.length)
			if frac > 0.01 then
				local ex = e.px + frac * (e.cx - e.px)
				local ez = e.pz + frac * (e.cz - e.pz)
				local cap = max(1, e.capacity)

				local segments = RoutePCB(e.px, e.pz, ex, ez)
				for j = 1, #segments do
					local s = segments[j]
					rawSegments[#rawSegments + 1] = { s[1], s[2], s[3], s[4], cap }
				end

				-- Pads at endpoints (accumulate max radius)
				local w = GetTraceWidth(cap)
				local pkey = floor(e.px) .. "," .. floor(e.pz)
				if not maxPadRadius[pkey] or w * PAD_RADIUS_MULT > maxPadRadius[pkey] then
					maxPadRadius[pkey] = w * PAD_RADIUS_MULT
					padSet[pkey] = { cx = e.px, cz = e.pz }
				end

				if frac >= 0.99 then
					local ckey = floor(e.cx) .. "," .. floor(e.cz)
					if not maxPadRadius[ckey] or w * PAD_RADIUS_MULT > maxPadRadius[ckey] then
						maxPadRadius[ckey] = w * PAD_RADIUS_MULT
						padSet[ckey] = { cx = e.cx, cz = e.cz }
					end
				end
			end
		end
	end

	if #rawSegments == 0 then
		needsRedraw = false
		return
	end

	-- Step 2: Merge overlapping axis-aligned segments (reinforcement)
	local allSegments = MergeSegments(rawSegments)

	-- Build pad list with accumulated radii
	for pkey, pdata in pairs(padSet) do
		allPads[#allPads + 1] = { cx = pdata.cx, cz = pdata.cz, radius = maxPadRadius[pkey] }
	end

	-- Collect needed squares (from segments + pads)
	local neededSquares = {}
	for i = 1, #allSegments do
		local s = allSegments[i]
		local m = s.width + 20
		local minSx = max(0, floor((min(s.x1, s.x2) - m) / SQUARE_SIZE))
		local maxSx = min(SQUARES_X - 1, floor((max(s.x1, s.x2) + m) / SQUARE_SIZE))
		local minSz = max(0, floor((min(s.z1, s.z2) - m) / SQUARE_SIZE))
		local maxSz = min(SQUARES_Z - 1, floor((max(s.z1, s.z2) + m) / SQUARE_SIZE))
		for sx = minSx, maxSx do
			for sz = minSz, maxSz do
				neededSquares[SquareKey(sx, sz)] = { sx = sx, sz = sz }
			end
		end
	end
	for i = 1, #allPads do
		local p = allPads[i]
		local m = p.radius + 5
		local minSx = max(0, floor((p.cx - m) / SQUARE_SIZE))
		local maxSx = min(SQUARES_X - 1, floor((p.cx + m) / SQUARE_SIZE))
		local minSz = max(0, floor((p.cz - m) / SQUARE_SIZE))
		local maxSz = min(SQUARES_Z - 1, floor((p.cz + m) / SQUARE_SIZE))
		for sx = minSx, maxSx do
			for sz = minSz, maxSz do
				neededSquares[SquareKey(sx, sz)] = { sx = sx, sz = sz }
			end
		end
	end

	-- Render on each needed square
	drawnSquares = {}
	for key, sq in pairs(neededSquares) do
		local sx, sz = sq.sx, sq.sz

		-- Ensure FBO pair exists
		if not squareFBOs[sx] then squareFBOs[sx] = {} end
		if not squareFBOs[sx][sz] then
			local cur = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
				fbo = true, min_filter = GL.LINEAR_MIPMAP_NEAREST,
				wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE,
			})
			local orig = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
				fbo = true,
				wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE,
			})
			if cur and orig then
				squareFBOs[sx][sz] = { cur = cur, orig = orig }
			else
				if cur then gl.DeleteTextureFBO(cur) end
				if orig then gl.DeleteTextureFBO(orig) end
			end
		end

		local pair = squareFBOs[sx] and squareFBOs[sx][sz]
		if pair then
			-- Snapshot orig, copy to cur
			spGetMapSquareTexture(sx, sz, 0, pair.orig)
			glTexture(pair.orig)
			gl.RenderToTexture(pair.cur, function()
				glTexRect(-1, 1, 1, -1)
			end)
			glTexture(false)

			local sqX = sx * SQUARE_SIZE
			local sqZ = sz * SQUARE_SIZE
			local w2t = MakeW2T(sqX, sqZ)

			gl.RenderToTexture(pair.cur, function()
				gl.Texture(false)

				-- Layer 1: Trace borders (dark substrate)
				glColor(TRACE_BORDER_COLOR[1], TRACE_BORDER_COLOR[2], TRACE_BORDER_COLOR[3], TRACE_BORDER_COLOR[4])
				gl.BeginEnd(GL.QUADS, function()
					for i = 1, #allSegments do
						local s = allSegments[i]
						EmitTraceQuad(w2t, s.x1, s.z1, s.x2, s.z2, s.width * 0.55)
					end
				end)

				-- Layer 2: Trace copper fill (additive so overlapping traces reinforce)
				gl.Blending(GL.SRC_ALPHA, GL.ONE)
				gl.BeginEnd(GL.QUADS, function()
					for i = 1, #allSegments do
						local s = allSegments[i]
						local r, g, b, a = GetTraceColor(s.capacity)
						glColor(r, g, b, a)
						EmitTraceQuad(w2t, s.x1, s.z1, s.x2, s.z2, s.width * 0.4)
					end
				end)

				-- Reset blending for pads
				gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

				-- Layer 3: Pad borders
				glColor(PAD_BORDER_COLOR[1], PAD_BORDER_COLOR[2], PAD_BORDER_COLOR[3], PAD_BORDER_COLOR[4])
				for i = 1, #allPads do
					local p = allPads[i]
					gl.BeginEnd(GL.TRIANGLE_FAN, function()
						EmitCircle(w2t, p.cx, p.cz, p.radius)
					end)
				end

				-- Layer 4: Pad copper fill
				glColor(PAD_COPPER_COLOR[1], PAD_COPPER_COLOR[2], PAD_COPPER_COLOR[3], PAD_COPPER_COLOR[4])
				for i = 1, #allPads do
					local p = allPads[i]
					gl.BeginEnd(GL.TRIANGLE_FAN, function()
						EmitCircle(w2t, p.cx, p.cz, p.radius * 0.75)
					end)
				end

				-- Layer 5: Via dots along traces
				glColor(VIA_COLOR[1], VIA_COLOR[2], VIA_COLOR[3], VIA_COLOR[4])
				for i = 1, #allSegments do
					local s = allSegments[i]
					local dx = s.x2 - s.x1
					local dz = s.z2 - s.z1
					local len = sqrt(dx * dx + dz * dz)
					if len > VIA_SPACING then
						local steps = floor(len / VIA_SPACING)
						for v = 1, steps do
							local t = v / (steps + 1)
							local vx = s.x1 + t * dx
							local vz = s.z1 + t * dz
							gl.BeginEnd(GL.TRIANGLE_FAN, function()
								EmitCircle(w2t, vx, vz, VIA_RADIUS)
							end)
						end
					end
				end

				glColor(1, 1, 1, 1)
			end)

			-- Apply
			gl.GenerateMipmap(pair.cur)
			spSetMapSquareTexture(sx, sz, pair.cur)
			drawnSquares[key] = sq
		end
	end

	needsRedraw = false
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

	needsRedraw = true
end

-------------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------------

function gadget:Initialize()
	if not gl.RenderToTexture then
		gadgetHandler:RemoveGadget()
		return
	end
	gadgetHandler:AddSyncAction("CableTreeUpdate", OnCableTreeUpdate)
end

function gadget:Shutdown()
	for _, sq in pairs(drawnSquares) do
		spSetMapSquareTexture(sq.sx, sq.sz, "")
	end
	for sx, szMap in pairs(squareFBOs) do
		for sz, pair in pairs(szMap) do
			if pair.cur then gl.DeleteTextureFBO(pair.cur) end
			if pair.orig then gl.DeleteTextureFBO(pair.orig) end
		end
	end
	squareFBOs = {}
	drawnSquares = {}
	gadgetHandler:RemoveSyncAction("CableTreeUpdate")
end

end -- UNSYNCED
