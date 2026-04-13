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
-- Organic tree style config
-------------------------------------------------------------------------------------

local MIN_TRUNK_WIDTH  = 4
local MAX_TRUNK_WIDTH  = 20
local MAX_CAPACITY_REF = 100
local PAD_SEGMENTS     = 10

-- Noise & branching
local SEG_LENGTH       = 16    -- subdivide cables every N elmos
local NOISE_AMP        = 0.6   -- noise amplitude as fraction of width
local BRANCH_CHANCE    = 0.25  -- chance of side branch per segment
local BRANCH_LEN_MIN   = 15   -- min branch length (elmos)
local BRANCH_LEN_MAX   = 50   -- max branch length
local BRANCH_ANGLE_MIN = 0.4  -- min angle offset (radians, ~23°)
local BRANCH_ANGLE_MAX = 1.1  -- max angle offset (radians, ~63°)
local BRANCH_WIDTH     = 0.5  -- branch width as fraction of parent
local TWIG_CHANCE      = 0.3  -- chance of sub-branch from a branch
local TWIG_LEN_MIN     = 8
local TWIG_LEN_MAX     = 25
local TWIG_WIDTH       = 0.4
local TAPER_START      = 0.7  -- start tapering at this fraction along cable

-- Colors (organic: dark bark border, greenish/amber glow)
local BARK_COLOR  = { 0.06, 0.04, 0.02, 0.90 }
local INNER_COLOR = { 0.20, 0.55, 0.15, 0.85 } -- green energy
local INNER_COLOR_HIGH = { 0.50, 0.80, 0.20, 0.90 } -- bright for high capacity
local PAD_BARK_COLOR  = { 0.08, 0.05, 0.02, 0.92 }
local PAD_INNER_COLOR = { 0.25, 0.60, 0.18, 0.90 }

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

-------------------------------------------------------------------------------------
-- Deterministic noise: hash-based pseudo-random from position
-- Returns value in [-1, 1], stable for same inputs across redraws
-------------------------------------------------------------------------------------

local function Hash(x, z, seed)
	local h = sin(x * 12.9898 + z * 78.233 + (seed or 0) * 43.17) * 43758.5453
	return (h - floor(h)) * 2 - 1 -- [-1, 1]
end

local function HashUnit(x, z, seed) -- [0, 1]
	return (Hash(x, z, seed) + 1) * 0.5
end

-------------------------------------------------------------------------------------
-- Organic tree path generator
-- Takes a cable edge and produces many small noisy segments + side branches.
-------------------------------------------------------------------------------------

local function GetTrunkWidth(capacity)
	local t = min(1, capacity / MAX_CAPACITY_REF)
	return MIN_TRUNK_WIDTH + t * (MAX_TRUNK_WIDTH - MIN_TRUNK_WIDTH)
end

-- Generate noisy path points along a line from (x1,z1) to (x2,z2)
-- Returns array of {x, z} waypoints with perpendicular noise
local function NoisyPath(x1, z1, x2, z2, amplitude, seed)
	local dx = x2 - x1
	local dz = z2 - z1
	local len = sqrt(dx * dx + dz * dz)
	if len < 2 then
		return { {x = x1, z = z1}, {x = x2, z = z2} }
	end

	local steps = max(2, floor(len / SEG_LENGTH))
	local nx = -dz / len -- perpendicular
	local nz =  dx / len

	local points = {}
	for i = 0, steps do
		local t = i / steps
		local px = x1 + t * dx
		local pz = z1 + t * dz

		-- No noise at endpoints (connect cleanly to pads)
		local noiseScale = 1
		if t < 0.1 then noiseScale = t / 0.1
		elseif t > 0.9 then noiseScale = (1 - t) / 0.1 end

		local n = Hash(px * 0.1, pz * 0.1, seed) * amplitude * noiseScale
		points[#points + 1] = { x = px + nx * n, z = pz + nz * n }
	end
	return points
end

-- Generate organic segments for one cable edge.
-- Returns list of { x1, z1, x2, z2, width, capacity, isBranch }
local function GenerateOrganicEdge(ex1, ez1, ex2, ez2, capacity)
	local segments = {}
	local trunkW = GetTrunkWidth(capacity)
	local len = sqrt((ex2 - ex1)^2 + (ez2 - ez1)^2)
	if len < 2 then return segments end

	local dx = (ex2 - ex1) / len
	local dz = (ez2 - ez1) / len

	-- Generate noisy trunk path
	local path = NoisyPath(ex1, ez1, ex2, ez2, trunkW * NOISE_AMP, ex1 + ez1)

	-- Emit trunk segments with taper
	for i = 1, #path - 1 do
		local p1 = path[i]
		local p2 = path[i + 1]
		local t = (i - 1) / (#path - 1) -- 0..1 along cable

		-- Taper: full width until TAPER_START, then narrow to 60%
		local w = trunkW
		if t > TAPER_START then
			local taperT = (t - TAPER_START) / (1 - TAPER_START)
			w = trunkW * (1 - taperT * 0.4)
		end

		segments[#segments + 1] = {
			x1 = p1.x, z1 = p1.z, x2 = p2.x, z2 = p2.z,
			width = w, capacity = capacity, isBranch = false,
		}

		-- Side branches
		if i > 1 and i < #path - 1 then
			local branchSeed = p1.x * 7.13 + p1.z * 3.77
			if HashUnit(p1.x, p1.z, branchSeed) < BRANCH_CHANCE then
				-- Branch direction: perpendicular with random angle offset
				local side = (Hash(p1.x, p1.z, branchSeed + 1) > 0) and 1 or -1
				local angle = BRANCH_ANGLE_MIN + HashUnit(p1.x, p1.z, branchSeed + 2) * (BRANCH_ANGLE_MAX - BRANCH_ANGLE_MIN)
				local bAngle = math.atan2(dz, dx) + side * angle
				local bLen = BRANCH_LEN_MIN + HashUnit(p1.x, p1.z, branchSeed + 3) * (BRANCH_LEN_MAX - BRANCH_LEN_MIN)
				local bx2 = p1.x + cos(bAngle) * bLen
				local bz2 = p1.z + sin(bAngle) * bLen
				local bw = w * BRANCH_WIDTH

				-- Noisy branch path (fewer segments)
				local bPath = NoisyPath(p1.x, p1.z, bx2, bz2, bw * 0.8, branchSeed + 10)
				for bi = 1, #bPath - 1 do
					local bp1 = bPath[bi]
					local bp2 = bPath[bi + 1]
					local bt = bi / (#bPath - 1)
					local bwTaper = bw * (1 - bt * 0.6) -- taper to 40% at tip

					segments[#segments + 1] = {
						x1 = bp1.x, z1 = bp1.z, x2 = bp2.x, z2 = bp2.z,
						width = bwTaper, capacity = capacity * 0.3, isBranch = true,
					}

					-- Sub-twigs
					if bi > 1 and bi < #bPath - 1 and HashUnit(bp1.x, bp1.z, branchSeed + 20 + bi) < TWIG_CHANCE then
						local tSide = (Hash(bp1.x, bp1.z, branchSeed + 30 + bi) > 0) and 1 or -1
						local tAngle = bAngle + tSide * (0.3 + HashUnit(bp1.x, bp1.z, branchSeed + 40 + bi) * 0.8)
						local tLen = TWIG_LEN_MIN + HashUnit(bp1.x, bp1.z, branchSeed + 50 + bi) * (TWIG_LEN_MAX - TWIG_LEN_MIN)
						local tx2 = bp1.x + cos(tAngle) * tLen
						local tz2 = bp1.z + sin(tAngle) * tLen
						local tw = bwTaper * TWIG_WIDTH

						segments[#segments + 1] = {
							x1 = bp1.x, z1 = bp1.z, x2 = tx2, z2 = tz2,
							width = tw, capacity = capacity * 0.1, isBranch = true,
						}
					end
				end
			end
		end
	end

	return segments
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

	-- Generate organic tree segments from all edges
	local allSegments = {}
	local allPads = {}
	local padSet = {}

	for i = 1, #renderEdges do
		local e = renderEdges[i]
		if e.length > 0 then
			local frac = min(1, e.progress / e.length)
			if frac > 0.01 then
				local ex = e.px + frac * (e.cx - e.px)
				local ez = e.pz + frac * (e.cz - e.pz)
				local cap = max(1, e.capacity)

				-- Generate organic noisy path with branches
				local segs = GenerateOrganicEdge(e.px, e.pz, ex, ez, cap)
				for j = 1, #segs do
					allSegments[#allSegments + 1] = segs[j]
				end

				-- Pads at endpoints
				local w = GetTrunkWidth(cap)
				local pkey = floor(e.px) .. "," .. floor(e.pz)
				if not padSet[pkey] then
					padSet[pkey] = true
					allPads[#allPads + 1] = { cx = e.px, cz = e.pz, radius = w * 1.5 }
				end
				if frac >= 0.99 then
					local ckey = floor(e.cx) .. "," .. floor(e.cz)
					if not padSet[ckey] then
						padSet[ckey] = true
						allPads[#allPads + 1] = { cx = e.cx, cz = e.cz, radius = w * 1.2 }
					end
				end
			end
		end
	end

	if #allSegments == 0 then
		needsRedraw = false
		return
	end

	-- Collect needed squares (from segments + pads)
	local neededSquares = {}
	for i = 1, #allSegments do
		local s = allSegments[i]
		local m = s.width + 60 -- extra margin for branch noise
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

				-- Layer 1: Dark bark border (all segments)
				glColor(BARK_COLOR[1], BARK_COLOR[2], BARK_COLOR[3], BARK_COLOR[4])
				gl.BeginEnd(GL.QUADS, function()
					for i = 1, #allSegments do
						local s = allSegments[i]
						EmitTraceQuad(w2t, s.x1, s.z1, s.x2, s.z2, s.width * 0.55)
					end
				end)

				-- Layer 2: Inner glow (energy color, varies by capacity)
				gl.BeginEnd(GL.QUADS, function()
					for i = 1, #allSegments do
						local s = allSegments[i]
						local t = min(1, s.capacity / MAX_CAPACITY_REF)
						local r = INNER_COLOR[1] + t * (INNER_COLOR_HIGH[1] - INNER_COLOR[1])
						local g = INNER_COLOR[2] + t * (INNER_COLOR_HIGH[2] - INNER_COLOR[2])
						local b = INNER_COLOR[3] + t * (INNER_COLOR_HIGH[3] - INNER_COLOR[3])
						local a = INNER_COLOR[4]
						if s.isBranch then a = a * 0.7 end
						glColor(r, g, b, a)
						EmitTraceQuad(w2t, s.x1, s.z1, s.x2, s.z2, s.width * 0.35)
					end
				end)

				-- Layer 3: Pad borders (dark bark circles at nodes)
				glColor(PAD_BARK_COLOR[1], PAD_BARK_COLOR[2], PAD_BARK_COLOR[3], PAD_BARK_COLOR[4])
				for i = 1, #allPads do
					local p = allPads[i]
					gl.BeginEnd(GL.TRIANGLE_FAN, function()
						EmitCircle(w2t, p.cx, p.cz, p.radius)
					end)
				end

				-- Layer 4: Pad inner glow
				glColor(PAD_INNER_COLOR[1], PAD_INNER_COLOR[2], PAD_INNER_COLOR[3], PAD_INNER_COLOR[4])
				for i = 1, #allPads do
					local p = allPads[i]
					gl.BeginEnd(GL.TRIANGLE_FAN, function()
						EmitCircle(w2t, p.cx, p.cz, p.radius * 0.65)
					end)
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
