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
local huge  = math.huge

-------------------------------------------------------------------------------------
-- Config
-------------------------------------------------------------------------------------

local SEND_PERIOD       = 6
local TICK_PERIOD       = 3   -- only tick edges every N frames (not every frame)
local GROWTH_RATE       = 250 -- elmos per second
local WITHER_RATE       = 400 -- elmos per second
local GAME_SPEED        = Game.gameSpeed or 30
local GROWTH_PER_TICK   = GROWTH_RATE / GAME_SPEED * 3 -- adjusted for TICK_PERIOD
local WITHER_PER_TICK   = WITHER_RATE / GAME_SPEED * 3
local MIN_CABLE_CAPACITY = 0.5

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
-- Persistent tree data per allyTeam
-------------------------------------------------------------------------------------

local trees = {}
local treeVersion = 0
local dirty = false

-- Queue of nodes that just became connected and need orphan scanning.
-- Processed outside of edge iteration to avoid modifying edges during pairs().
local newlyConnected = {} -- list of {tree, unitID}

local function InitTree(allyTeamID)
	trees[allyTeamID] = {
		nodes = {},
		edges = {},
	}
end

do
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		InitTree(allyTeamList[i])
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

local function InRange(n1, n2)
	return Dist(n1.x, n1.z, n2.x, n2.z) < (n1.range + n2.range)
end

-- Is a node connected? Iterative (no recursion) to avoid stack overflow.
local function IsConnected(tree, unitID)
	local visited = {}
	local current = unitID
	while current do
		if visited[current] then return false end -- cycle detected, bail
		visited[current] = true
		local node = tree.nodes[current]
		if not node then return false end
		if node.isRoot then return true end
		local edge = tree.edges[current]
		if not edge then return false end
		if not edge.grown then return false end
		current = edge.parentID
	end
	return false
end

-- Find root of a node's subtree (follow parent chain up).
local function FindRoot(tree, unitID)
	local visited = {}
	local current = unitID
	while current do
		if visited[current] then return current end
		visited[current] = true
		local node = tree.nodes[current]
		if not node then return current end
		if node.isRoot then return current end
		if not node.parent then return current end
		current = node.parent
	end
	return unitID
end

-- Find the nearest connected node within range of (x, z, range).
local function FindNearestConnected(tree, x, z, range, excludeID)
	local bestID = nil
	local bestDist = huge
	for uid, node in pairs(tree.nodes) do
		if uid ~= excludeID and IsConnected(tree, uid) then
			local d = Dist(x, z, node.x, node.z)
			if d < (range + node.range) and d < bestDist then
				bestDist = d
				bestID = uid
			end
		end
	end
	return bestID, bestDist
end

-- Find all nearby nodes in range that belong to DIFFERENT root subtrees.
-- Returns list of {nodeID, rootID} for each unique foreign root.
local function FindNearbyForeignRoots(tree, unitID)
	local node = tree.nodes[unitID]
	if not node then return {} end
	local myRoot = FindRoot(tree, unitID)
	local foundRoots = {} -- [rootID] = nearest nodeID in that subtree
	local foundDists = {}

	for uid, other in pairs(tree.nodes) do
		if uid ~= unitID and InRange(node, other) then
			local otherRoot = FindRoot(tree, uid)
			if otherRoot ~= myRoot then
				local d = Dist(node.x, node.z, other.x, other.z)
				if not foundRoots[otherRoot] or d < foundDists[otherRoot] then
					foundRoots[otherRoot] = uid
					foundDists[otherRoot] = d
				end
			end
		end
	end

	local result = {}
	for rootID, nearestID in pairs(foundRoots) do
		result[#result + 1] = { nodeID = nearestID, rootID = rootID }
	end
	return result
end

-- Connect a node to nearby foreign subtrees by creating edges to their roots.
-- Called OUTSIDE of edge iteration.
local function BridgeNearbySubtrees(tree, unitID)
	local node = tree.nodes[unitID]
	if not node then return end

	local foreignRoots = FindNearbyForeignRoots(tree, unitID)
	for i = 1, #foreignRoots do
		local rootID = foreignRoots[i].rootID
		local rootNode = tree.nodes[rootID]
		-- Re-check: root must still be a root and not already have an edge
		if rootNode and rootNode.isRoot and not tree.edges[rootID] then
			tree.edges[rootID] = {
				parentID = unitID,
				childID = rootID,
				length = max(1, Dist(node.x, node.z, rootNode.x, rootNode.z)),
				progress = 0,
				grown = false,
				withering = false,
			}
			rootNode.parent = unitID
			rootNode.isRoot = false
			node.children[rootID] = true
			dirty = true
		end
	end
end

-------------------------------------------------------------------------------------
-- Node capacity
-------------------------------------------------------------------------------------

local function GetNodeCapacity(unitID, unitDefID)
	if not spValidUnitID(unitID) then return 0, 0 end
	local stunned = spGetUnitIsStunned(unitID) or
		(spGetUnitRulesParam(unitID, "disarmed") == 1)
	if stunned then return 0, 0 end

	local production = 0
	local consumption = 0
	if generatorDefs[unitDefID] then
		production = spGetUnitRulesParam(unitID, "current_energyIncome") or 0
	end
	if mexDefs[unitDefID] then
		consumption = spGetUnitRulesParam(unitID, "overdrive_energyDrain") or 0
	end
	return production, consumption
end

-------------------------------------------------------------------------------------
-- Tree mutations
-------------------------------------------------------------------------------------

local function OnPylonAdded(allyTeamID, unitID, unitDefID)
	local x, _, z = spGetUnitPosition(unitID)
	local range = pylonDefs[unitDefID]
	if not range then return end

	local tree = trees[allyTeamID]
	if tree.nodes[unitID] then return end

	-- Create node
	tree.nodes[unitID] = {
		x = x, z = z, range = range, unitDefID = unitDefID,
		parent = nil, children = {}, isRoot = false,
	}

	-- Find nearest node in range (connected or not — we link to nearest in any case)
	local bestID = nil
	local bestDist = huge
	for uid, node in pairs(tree.nodes) do
		if uid ~= unitID then
			local d = Dist(x, z, node.x, node.z)
			if d < (range + node.range) and d < bestDist then
				bestDist = d
				bestID = uid
			end
		end
	end

	if bestID then
		local nearNode = tree.nodes[bestID]
		local length = max(1, Dist(x, z, nearNode.x, nearNode.z))
		tree.edges[unitID] = {
			parentID = bestID,
			childID = unitID,
			length = length,
			progress = 0,
			grown = false,
			withering = false,
		}
		tree.nodes[unitID].parent = bestID
		nearNode.children[unitID] = true
		-- Also bridge any other subtrees in range
		newlyConnected[#newlyConnected + 1] = { tree = tree, unitID = unitID }
	else
		-- No node in range — become a root
		tree.nodes[unitID].isRoot = true
	end

	dirty = true
end

local function OnPylonRemoved(allyTeamID, unitID)
	local tree = trees[allyTeamID]
	local node = tree.nodes[unitID]
	if not node then return end

	-- Collect immediate children
	local orphans = {}
	for childID, _ in pairs(node.children) do
		orphans[#orphans + 1] = childID
	end

	-- Remove our parent edge
	if node.parent then
		local parentNode = tree.nodes[node.parent]
		if parentNode then
			parentNode.children[unitID] = nil
		end
	end
	tree.edges[unitID] = nil

	-- Remove children's parent edges
	for _, childID in ipairs(orphans) do
		tree.edges[childID] = nil
		local childNode = tree.nodes[childID]
		if childNode then
			childNode.parent = nil
		end
	end

	-- Remove node
	tree.nodes[unitID] = nil

	-- Reconnect orphans
	for _, childID in ipairs(orphans) do
		local childNode = tree.nodes[childID]
		if childNode then
			local nearestID = FindNearestConnected(tree, childNode.x, childNode.z, childNode.range, childID)
			if nearestID then
				local nearNode = tree.nodes[nearestID]
				local length = max(1, Dist(childNode.x, childNode.z, nearNode.x, nearNode.z))
				tree.edges[childID] = {
					parentID = nearestID,
					childID = childID,
					length = length,
					progress = 0,
					grown = false,
					withering = false,
				}
				childNode.parent = nearestID
				childNode.isRoot = false
				nearNode.children[childID] = true
			else
				childNode.isRoot = true
				-- This orphan root might be able to adopt other orphans
				newlyConnected[#newlyConnected + 1] = { tree = tree, unitID = childID }
			end
		end
	end

	dirty = true
end

-------------------------------------------------------------------------------------
-- Edge growth tick — called periodically, NOT every frame
-------------------------------------------------------------------------------------

local function TickEdges()
	-- Grow / wither all edges. Collect newly-grown nodes for orphan scanning.
	for _, tree in pairs(trees) do
		local toRemove = {}

		for childID, edge in pairs(tree.edges) do
			if edge.withering then
				edge.progress = edge.progress - WITHER_PER_TICK
				if edge.progress <= 0 then
					toRemove[#toRemove + 1] = childID
				end
				edge.grown = false
				dirty = true
			elseif edge.progress < edge.length then
				edge.progress = min(edge.length, edge.progress + GROWTH_PER_TICK)
				if edge.progress >= edge.length then
					edge.grown = true
					-- Queue orphan scan (do NOT modify edges here)
					newlyConnected[#newlyConnected + 1] = { tree = tree, unitID = childID }
				end
				dirty = true
			end
		end

		-- Remove fully-withered edges (after iteration)
		for i = 1, #toRemove do
			local childID = toRemove[i]
			local edge = tree.edges[childID]
			if edge then
				local parentNode = tree.nodes[edge.parentID]
				if parentNode then
					parentNode.children[childID] = nil
				end
				local childNode = tree.nodes[childID]
				if childNode then
					childNode.parent = nil
					childNode.isRoot = true
				end
			end
			tree.edges[childID] = nil
		end
	end

	-- Process newly connected nodes (adopt nearby orphan roots).
	-- This is safe because we're outside the edges iteration.
	local batch = newlyConnected
	newlyConnected = {}
	for i = 1, #batch do
		local item = batch[i]
		if item.tree.nodes[item.unitID] then
			BridgeNearbySubtrees(item.tree, item.unitID)
		end
	end
end

-------------------------------------------------------------------------------------
-- Flow computation (post-order DFS on fully-grown edges)
-------------------------------------------------------------------------------------

local function ComputeSubtreeFlows(tree, unitID, flowResults)
	local node = tree.nodes[unitID]
	if not node then return 0, 0 end

	local prod, cons = GetNodeCapacity(unitID, node.unitDefID)

	for childID, _ in pairs(node.children) do
		local edge = tree.edges[childID]
		if edge and edge.grown then
			local childProd, childCons = ComputeSubtreeFlows(tree, childID, flowResults)
			prod = prod + childProd
			cons = cons + childCons
			flowResults[childID] = max(childProd, childCons)
		end
	end

	return prod, cons
end

local function ComputeFlows(tree)
	local flowResults = {}
	for unitID, node in pairs(tree.nodes) do
		if node.isRoot then
			ComputeSubtreeFlows(tree, unitID, flowResults)
		end
	end
	return flowResults
end

-------------------------------------------------------------------------------------
-- Send state to unsynced
-------------------------------------------------------------------------------------

local function SendTreesToUnsynced()
	for allyTeamID, tree in pairs(trees) do
		local flows = ComputeFlows(tree)

		local edgeCount = 0
		local parentXs, parentZs = {}, {}
		local childXs, childZs = {}, {}
		local progresses, lengths, capacities = {}, {}, {}

		for childID, edge in pairs(tree.edges) do
			local parentNode = tree.nodes[edge.parentID]
			local childNode = tree.nodes[childID]
			if parentNode and childNode and edge.progress > 0 then
				edgeCount = edgeCount + 1
				parentXs[edgeCount] = parentNode.x
				parentZs[edgeCount] = parentNode.z
				childXs[edgeCount] = childNode.x
				childZs[edgeCount] = childNode.z
				progresses[edgeCount] = edge.progress
				lengths[edgeCount] = edge.length
				capacities[edgeCount] = flows[childID] or 0
			end
		end

		_G.CableTreeData = {
			allyTeamID = allyTeamID,
			version = treeVersion,
			edgeCount = edgeCount,
			parentXs = parentXs, parentZs = parentZs,
			childXs = childXs, childZs = childZs,
			progresses = progresses, lengths = lengths,
			capacities = capacities,
		}
		SendToUnsynced("CableTreeUpdate")
	end
end

-------------------------------------------------------------------------------------
-- GameFrame
-------------------------------------------------------------------------------------

function gadget:GameFrame(n)
	if n % TICK_PERIOD == 0 then
		TickEdges()
	end

	if dirty and (n % SEND_PERIOD == 0) then
		treeVersion = treeVersion + 1
		SendTreesToUnsynced()
		dirty = false
	end
end

-------------------------------------------------------------------------------------
-- Unit lifecycle
-------------------------------------------------------------------------------------

function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if not pylonDefs[unitDefID] then return end
	OnPylonAdded(spGetUnitAllyTeam(unitID), unitID, unitDefID)
end

function gadget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if not pylonDefs[unitDefID] then return end
	OnPylonRemoved(spGetUnitAllyTeam(unitID), unitID)
end

function gadget:UnitGiven(unitID, unitDefID, newTeam, oldTeam)
	if not pylonDefs[unitDefID] then return end
	local _, _, _, _, _, newAlly = Spring.GetTeamInfo(newTeam, false)
	local _, _, _, _, _, oldAlly = Spring.GetTeamInfo(oldTeam, false)
	if newAlly ~= oldAlly then
		OnPylonRemoved(oldAlly, unitID)
		OnPylonAdded(newAlly, unitID, unitDefID)
	end
end

function gadget:Initialize()
	GG.CableTree = trees
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = spGetUnitDefID(unitID)
		if unitDefID and pylonDefs[unitDefID] then
			OnPylonAdded(spGetUnitAllyTeam(unitID), unitID, unitDefID)
		end
	end
	-- Process any queued orphan adoptions from init
	if #newlyConnected > 0 then
		local batch = newlyConnected
		newlyConnected = {}
		for i = 1, #batch do
			local item = batch[i]
			if item.tree.nodes[item.unitID] then
				AdoptNearbyOrphans(item.tree, item.unitID)
			end
		end
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

else -- UNSYNCED

-------------------------------------------------------------------------------------
-- UNSYNCED — Renders cable edges onto ground texture
-------------------------------------------------------------------------------------

local glTexture       = gl.Texture
local glCreateTexture = gl.CreateTexture
local glColor         = gl.Color
local glTexRect       = gl.TexRect
local glResetState    = gl.ResetState
local glResetMatrices = gl.ResetMatrices
local glVertex        = gl.Vertex
local glTexCoord      = gl.TexCoord

local spGetMapSquareTexture = Spring.GetMapSquareTexture
local spSetMapSquareTexture = Spring.SetMapSquareTexture
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetSpectatingState  = Spring.GetSpectatingState

local floor = math.floor
local sqrt  = math.sqrt
local max   = math.max
local min   = math.min

local MAP_WIDTH    = Game.mapSizeX
local MAP_HEIGHT   = Game.mapSizeZ
local SQUARE_SIZE  = 1024
local SQUARES_X    = MAP_WIDTH / SQUARE_SIZE
local SQUARES_Z    = MAP_HEIGHT / SQUARE_SIZE

local CABLE_TEXTURE    = "LuaRules/Images/overdrive/cable.png"
local CABLE_TEX_HEIGHT = 64

local MIN_CABLE_WIDTH  = 6
local MAX_CABLE_WIDTH  = 28
local MAX_CAPACITY_REF = 100

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
-- FBO management
-------------------------------------------------------------------------------------

local function GetSquareFBO(sx, sz)
	if not squareFBOs[sx] then squareFBOs[sx] = {} end
	if squareFBOs[sx][sz] then return squareFBOs[sx][sz] end
	local fbo = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
		wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE,
		fbo = true, min_filter = GL.LINEAR_MIPMAP_NEAREST,
	})
	if not fbo then return nil end
	squareFBOs[sx][sz] = fbo
	return fbo
end

local function SquareKey(sx, sz)
	return sx * 10000 + sz
end

-------------------------------------------------------------------------------------
-- Draw textured cable onto FBO
-------------------------------------------------------------------------------------

local function DrawCableOnSquare(sx, sz, fbo, x1, z1, x2, z2, width)
	local sqX = sx * SQUARE_SIZE
	local sqZ = sz * SQUARE_SIZE
	local dx = x2 - x1
	local dz = z2 - z1
	local len = sqrt(dx * dx + dz * dz)
	if len < 1 then return end

	local hw = width * 0.5
	local px = -dz / len * hw
	local pz =  dx / len * hw

	local c1x, c1z = x1 - px, z1 - pz
	local c2x, c2z = x1 + px, z1 + pz
	local c3x, c3z = x2 + px, z2 + pz
	local c4x, c4z = x2 - px, z2 - pz

	local function w2t(wx, wz)
		return 2 * (wx - sqX) / SQUARE_SIZE - 1,
		       2 * (wz - sqZ) / SQUARE_SIZE - 1
	end

	local vTile = len / CABLE_TEX_HEIGHT
	local t1x, t1z = w2t(c1x, c1z)
	local t2x, t2z = w2t(c2x, c2z)
	local t3x, t3z = w2t(c3x, c3z)
	local t4x, t4z = w2t(c4x, c4z)

	gl.RenderToTexture(fbo, function()
		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
		glColor(1, 1, 1, 1)
		gl.BeginEnd(GL.QUADS, function()
			glTexCoord(0, 0)     glVertex(t1x, t1z, 0)
			glTexCoord(1, 0)     glVertex(t2x, t2z, 0)
			glTexCoord(1, vTile) glVertex(t3x, t3z, 0)
			glTexCoord(0, vTile) glVertex(t4x, t4z, 0)
		end)
	end)
end

-------------------------------------------------------------------------------------
-- Cable width from capacity
-------------------------------------------------------------------------------------

local function GetCableWidth(capacity)
	local t = min(1, capacity / MAX_CAPACITY_REF)
	return MIN_CABLE_WIDTH + t * t * (MAX_CABLE_WIDTH - MIN_CABLE_WIDTH)
end

-------------------------------------------------------------------------------------
-- Full redraw
-------------------------------------------------------------------------------------

local function RedrawCables()
	glResetState()
	glResetMatrices()

	-- Revert previous squares
	for _, sq in pairs(drawnSquares) do
		spSetMapSquareTexture(sq.sx, sq.sz, "")
	end

	-- Build draw list with growth interpolation
	local drawList = {}
	for i = 1, #renderEdges do
		local e = renderEdges[i]
		if e.length > 0 then
			local frac = min(1, e.progress / e.length)
			if frac > 0.01 then
				local ex = e.px + frac * (e.cx - e.px)
				local ez = e.pz + frac * (e.cz - e.pz)
				drawList[#drawList + 1] = {
					x1 = e.px, z1 = e.pz, x2 = ex, z2 = ez,
					capacity = e.capacity,
				}
			end
		end
	end

	if #drawList == 0 then
		needsRedraw = false
		return
	end

	-- Determine needed squares
	local neededSquares = {}
	for i = 1, #drawList do
		local c = drawList[i]
		-- Use generous margin — 100 elmos
		local m = 100
		local minSx = max(0, floor((min(c.x1, c.x2) - m) / SQUARE_SIZE))
		local maxSx = min(SQUARES_X - 1, floor((max(c.x1, c.x2) + m) / SQUARE_SIZE))
		local minSz = max(0, floor((min(c.z1, c.z2) - m) / SQUARE_SIZE))
		local maxSz = min(SQUARES_Z - 1, floor((max(c.z1, c.z2) + m) / SQUARE_SIZE))
		for sx = minSx, maxSx do
			for sz = minSz, maxSz do
				neededSquares[SquareKey(sx, sz)] = { sx = sx, sz = sz }
			end
		end
	end

	Spring.Echo("[CableTree][U] Drawing " .. #drawList .. " cables on " .. (function() local n=0; for _ in pairs(neededSquares) do n=n+1 end; return n end)() .. " squares")

	-- Snapshot current map texture into FBOs then draw cables
	drawnSquares = {}
	for key, sq in pairs(neededSquares) do
		local fbo = GetSquareFBO(sq.sx, sq.sz)
		if not fbo then
			Spring.Echo("[CableTree][U] FBO creation failed for " .. sq.sx .. "," .. sq.sz)
		else
			-- Snapshot current texture
			spGetMapSquareTexture(sq.sx, sq.sz, 0, fbo)

			-- TEST: Draw a big bright red X across the entire square to verify FBO pipeline
			gl.RenderToTexture(fbo, function()
				gl.Texture(false)
				glColor(1, 0, 0, 1)
				-- Big diagonal cross filling 80% of the square
				gl.BeginEnd(GL.QUADS, function()
					-- Horizontal bar across center
					glVertex(-0.8, -0.05, 0)
					glVertex( 0.8, -0.05, 0)
					glVertex( 0.8,  0.05, 0)
					glVertex(-0.8,  0.05, 0)
					-- Vertical bar across center
					glVertex(-0.05, -0.8, 0)
					glVertex( 0.05, -0.8, 0)
					glVertex( 0.05,  0.8, 0)
					glVertex(-0.05,  0.8, 0)
				end)
				glColor(1, 1, 1, 1)
			end)

			gl.GenerateMipmap(fbo)
			spSetMapSquareTexture(sq.sx, sq.sz, fbo)
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
-- Drawing hook
-------------------------------------------------------------------------------------

local drawCount = 0

function gadget:DrawGenesis()
	if not needsRedraw then return end
	if #renderEdges == 0 then
		needsRedraw = false
		return
	end

	drawCount = drawCount + 1

	glResetState()
	glResetMatrices()

	-- Revert previously modified squares
	for _, sq in pairs(drawnSquares) do
		spSetMapSquareTexture(sq.sx, sq.sz, "")
	end

	-- Build draw list with growth interpolation
	local drawList = {}
	for i = 1, #renderEdges do
		local e = renderEdges[i]
		if e.length > 0 then
			local frac = min(1, e.progress / e.length)
			if frac > 0.01 then
				drawList[#drawList + 1] = {
					x1 = e.px, z1 = e.pz,
					x2 = e.px + frac * (e.cx - e.px),
					z2 = e.pz + frac * (e.cz - e.pz),
					capacity = e.capacity,
				}
			end
		end
	end

	if #drawList == 0 then
		needsRedraw = false
		return
	end

	-- Collect all squares that need updating
	local neededSquares = {}
	for i = 1, #drawList do
		local c = drawList[i]
		local m = 100
		local minSx = max(0, floor((min(c.x1, c.x2) - m) / SQUARE_SIZE))
		local maxSx = min(SQUARES_X - 1, floor((max(c.x1, c.x2) + m) / SQUARE_SIZE))
		local minSz = max(0, floor((min(c.z1, c.z2) - m) / SQUARE_SIZE))
		local maxSz = min(SQUARES_Z - 1, floor((max(c.z1, c.z2) + m) / SQUARE_SIZE))
		for sx = minSx, maxSx do
			for sz = minSz, maxSz do
				neededSquares[SquareKey(sx, sz)] = { sx = sx, sz = sz }
			end
		end
	end

	-- For each square: create orig+cur pair, snapshot, draw cables, apply
	-- Using the exact pattern proven by terrain_texture_handler
	drawnSquares = {}
	for key, sq in pairs(neededSquares) do
		local sx, sz = sq.sx, sq.sz

		-- Get or create the FBO pair for this square
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
			-- Snapshot: capture current map texture into orig
			spGetMapSquareTexture(sx, sz, 0, pair.orig)

			-- Copy orig → cur
			glTexture(pair.orig)
			gl.RenderToTexture(pair.cur, function()
				glTexRect(-1, 1, 1, -1)
			end)
			glTexture(false)

			-- Draw cables onto cur: border + glowing core
			local sqX = sx * SQUARE_SIZE
			local sqZ = sz * SQUARE_SIZE

			local function w2t(wx, wz)
				return 2 * (wx - sqX) / SQUARE_SIZE - 1,
				       2 * (wz - sqZ) / SQUARE_SIZE - 1
			end

			local function drawQuad(x1, z1, x2, z2, hw, dx, dz, len)
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

			gl.RenderToTexture(pair.cur, function()
				gl.Texture(false)

				-- Pass 1: dark border (full width)
				gl.BeginEnd(GL.QUADS, function()
					for i = 1, #drawList do
						local c = drawList[i]
						local cdx = c.x2 - c.x1
						local cdz = c.z2 - c.z1
						local clen = sqrt(cdx * cdx + cdz * cdz)
						if clen > 1 then
							local w = GetCableWidth(c.capacity)
							glColor(0.04, 0.08, 0.12, 0.9)
							drawQuad(c.x1, c.z1, c.x2, c.z2, w * 0.5, cdx, cdz, clen)
						end
					end
				end)

				-- Pass 2: glowing inner core (60% width, color by capacity)
				gl.BeginEnd(GL.QUADS, function()
					for i = 1, #drawList do
						local c = drawList[i]
						local cdx = c.x2 - c.x1
						local cdz = c.z2 - c.z1
						local clen = sqrt(cdx * cdx + cdz * cdz)
						if clen > 1 then
							local w = GetCableWidth(c.capacity)
							-- Color: blue for low capacity, bright cyan for high
							local t = min(1, c.capacity / MAX_CAPACITY_REF)
							local r = 0.05 + t * 0.15
							local g = 0.3 + t * 0.5
							local b = 0.7 + t * 0.3
							glColor(r, g, b, 0.95)
							drawQuad(c.x1, c.z1, c.x2, c.z2, w * 0.3, cdx, cdz, clen)
						end
					end
				end)

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
