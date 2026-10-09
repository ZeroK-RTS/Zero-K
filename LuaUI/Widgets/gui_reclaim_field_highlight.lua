
function widget:GetInfo()
	return {
		name      = "Reclaim Field Highlight",
		desc      = "Highlights clusters of reclaimable material",
		author    = "ivand, refactored by esainane",
		date      = "2020",
		license   = "public",
		layer     = 0,
		enabled   = false  --  loaded by default?
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options

local flashStrength = 0.0
local fontScaling = 25 / 40
local fontSizeMin = 70
local fontSizeMax = 250

local textParametersChanged = false

options_path = "Settings/Interface/Reclaim Highlight"
options_order = { 'showhighlight', 'flashStrength', 'fontSizeMin', 'fontSizeMax', 'fontScaling' }
options = {
	showhighlight = {
		name = 'Show Field Summary',
		type = 'radioButton',
		value = 'constructors',
		items = {
			{key ='always', name='Always'},
			{key ='withecon', name='With the Economy Overlay'},
			{key ='constructors',  name='With Constructors Selected'},
			{key ='conorecon',  name='With Constructors or Overlay'},
			{key ='conandecon',  name='With Constructors and Overlay'},
			{key ='reclaiming',  name='When Reclaiming'},
		},
		noHotkey = true,
	},
	flashStrength = {
		name = "Field flashing strength",
		type = 'number',
		value = flashStrength,
		min = 0.0, max = 0.5, step = 0.05,
		desc = "How intensely the reclaim fields should pulse over time",
		OnChange = function()
			flashStrength = options.flashStrength.value
		end,
	},
	fontSizeMin = {
		name = "Minimum font size",
		type = 'number',
		value = fontSizeMin,
		min = 20, max = 150, step = 10,
		desc = "The smallest font size to use for the smallest reclaim fields",
		OnChange = function()
			fontSizeMin = options.fontSizeMin.value
			textParametersChanged = true
		end,
	},
	fontSizeMax = {
		name = "Maximum font size",
		type = 'number',
		value = fontSizeMax,
		min = 20, max = 300, step = 10,
		desc = "The largest font size to use for the largest reclaim fields",
		OnChange = function()
			fontSizeMax = options.fontSizeMax.value
			textParametersChanged = true
		end,
	},
	fontScaling = {
		name = "Font scaling factor",
		type = 'number',
		value = fontScaling,
		min = 0.2, max = 0.8, step = 0.025,
		desc = "How quickly the font size of the metal value display should grow with the size of the field",
		OnChange = function()
			fontScaling = options.fontScaling.value
			textParametersChanged = true
		end,
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedups

local glBeginEnd = gl.BeginEnd
local glBlending = gl.Blending
local glCallList = gl.CallList
local glColor = gl.Color
local glCreateList = gl.CreateList
local glDeleteList = gl.DeleteList
local glDepthTest = gl.DepthTest
local glLineWidth = gl.LineWidth
local glPolygonMode = gl.PolygonMode
local glPopMatrix = gl.PopMatrix
local glPushMatrix = gl.PushMatrix
local glRotate = gl.Rotate
local glText = gl.Text
local glTranslate = gl.Translate
local glVertex = gl.Vertex
local spGetAllFeatures = Spring.GetAllFeatures
local spGetCameraPosition = Spring.GetCameraPosition
local spGetFeatureHeight = Spring.GetFeatureHeight
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureResources = Spring.GetFeatureResources
local spGetFeatureTeam = Spring.GetFeatureTeam
local spGetGaiaTeamID = Spring.GetGaiaTeamID
local spGetGameFrame = Spring.GetGameFrame
local spGetGroundHeight = Spring.GetGroundHeight
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spIsGUIHidden = Spring.IsGUIHidden
local spIsPosInLos = Spring.IsPosInLos
local spTraceScreenRay = Spring.TraceScreenRay
local spValidFeatureID = Spring.ValidFeatureID
local spGetActiveCommand = Spring.GetActiveCommand
local spGetActiveCmdDesc = Spring.GetActiveCmdDesc

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Data

local screenx, screeny

local Benchmark = false and VFS.Include("LuaRules/Gadgets/Include/Benchmark.lua")
local ConvexHull = VFS.Include("LuaRules/Gadgets/Include/ConvexHull.lua")

local gaiaTeamId = spGetGaiaTeamID()

local benchmark = Benchmark and Benchmark.new()

local scanInterval = 1 * Game.gameSpeed
local scanForRemovalInterval = 10 * Game.gameSpeed --10 sec

local minDistance = 300
local minSqDistance = minDistance^2
local minFeatureMetal = 8 --flea

local drawEnabled = true
local BASE_FONT_SIZE = 192

local knownFeatures = {}

--local reclaimColor = (1.0, 0.2, 1.0, 0.7);
local reclaimColor = {1.0, 0.2, 1.0, 0.3}
local reclaimEdgeColor = {1.0, 0.2, 1.0, 0.5}

local E2M = 0 -- doesn't convert too well, plus would be inconsistent since trees aren't counted

local checkFrequency = 30
local cumDt = 0
local minDim = 100

-- Two features are neighbours when they are at most minDistance apart (x/z).
-- Spatial hash of the known features: features in cells next to each other (diagonally too) are
-- always neighbours (2 * GRID_SIZE * sqrt(2) < minDistance), and all neighbours of a feature are
-- within GRID_REACH cells.
local GRID_SIZE = 105
local GRID_REACH = 3
local GRID_ROW = 8192
local featureGrid = {}

-- Clusters are the connected components of the neighbour graph: OPTICS with minPoints = 2 and a
-- cluster threshold equal to the neighbour distance (what this widget used to run over every
-- feature on every change) yields exactly those, plus single-feature clusters. They are kept
-- across scans; a scan only re-forms the clusters that features were added to, removed from or
-- moved in, and only recomputes hulls and display lists of the clusters that changed.
local clusterList = {} -- draw order
local clusterOf = {} -- fID -> cluster
local unassigned = {} -- known features not in a cluster yet (added or moved this scan)
local brokenClusters = {} -- clusters that lost members this scan
local changedClusters = {} -- clusters whose members, metal or heights changed this scan
local scanCount = 0
local dataBuilt = false

local font = gl.LoadFont("FreeSansBold.otf", BASE_FONT_SIZE, 0, 0)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- State update

local function UpdateDrawEnabled()
	if (options.showhighlight.value == 'always')
			or (options.showhighlight.value == 'withecon' and WG.showeco)
			or (options.showhighlight.value == "constructors" and conSelected)
			or (options.showhighlight.value == 'conorecon' and (conSelected or WG.showeco))
			or (options.showhighlight.value == 'conandecon' and (conSelected and WG.showeco)) then
		return true
	end
	
	local currentCmd = spGetActiveCommand()
	if currentCmd then
		local activeCmdDesc = spGetActiveCmdDesc(currentCmd)
		return (activeCmdDesc and (activeCmdDesc.name == "Reclaim" or activeCmdDesc.name == "Resurrect"))
	end
	return false
end

function widget:SelectionChanged(units)
	if (WG.selectionEntirelyCons) then
		conSelected = true
	else
		conSelected = false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Feature Tracking

local function GridAdd(fID, fInfo)
	local gx, gz = math.floor(fInfo.x / GRID_SIZE), math.floor(fInfo.z / GRID_SIZE)
	local key = gx * GRID_ROW + gz
	local cell = featureGrid[key]
	if not cell then
		cell = {}
		featureGrid[key] = cell
	end
	cell[fID] = true
	fInfo.gridKey, fInfo.gx, fInfo.gz = key, gx, gz
end

local function GridRemove(fID, fInfo)
	local key = fInfo.gridKey
	local cell = featureGrid[key]
	cell[fID] = nil
	if next(cell) == nil then
		featureGrid[key] = nil
	end
end

-- Takes a feature out of its cluster before it is removed or moved. Its position is kept: the
-- members it was a neighbour of are what ProcessBrokenClusters looks at.
local function DetachFeature(fID, fInfo)
	unassigned[fID] = nil
	local cluster = clusterOf[fID]
	if not cluster then
		return
	end
	clusterOf[fID] = nil
	cluster.members[fID] = nil
	cluster.count = cluster.count - 1
	local lostX = cluster.lostX
	if not lostX then
		lostX = {}
		cluster.lostX, cluster.lostZ = lostX, {}
		brokenClusters[#brokenClusters + 1] = cluster
	end
	local n = #lostX + 1
	lostX[n] = fInfo.x
	cluster.lostZ[n] = fInfo.z
end

local function SetFeaturePosition(fID, fInfo, fx, fy, fz)
	fInfo.x = fx
	fInfo.y = fy
	fInfo.z = fz
	fInfo.drawAlt = ((fy > 0 and fy) or 0) + fInfo.height + 10
	-- hull vertex; a new table, older hulls may still reference the previous one
	fInfo.point = {x = fx, y = fInfo.drawAlt, z = fz, fID = fID}
end

local function RemoveFeature(fID, fInfo)
	DetachFeature(fID, fInfo)
	GridRemove(fID, fInfo)
	knownFeatures[fID] = nil
end

local function UpdateFeatures(gf)
	if benchmark then
		benchmark:Enter("UpdateFeatures")
	end
	local myAllyTeamID = spGetMyAllyTeamID()
	scanCount = scanCount + 1
	local features = spGetAllFeatures()
	for i = 1, #features do
		local fID = features[i]
		local metal, _, energy = spGetFeatureResources(fID)
		metal = metal + energy * E2M

		local fInfo = knownFeatures[fID]
		if (not fInfo) and (metal >= minFeatureMetal) then --first time seen
			local f = {}
			f.lastScanned = gf
			f.seen = scanCount

			local fx, _, fz = spGetFeaturePosition(fID)
			local fy = spGetGroundHeight(fx, fz)

			f.isGaia = (spGetFeatureTeam(fID) == gaiaTeamId)
			f.height = spGetFeatureHeight(fID)
			SetFeaturePosition(fID, f, fx, fy, fz)

			f.metal = metal

			knownFeatures[fID] = f
			GridAdd(fID, f)
			unassigned[fID] = true
		elseif fInfo then
			fInfo.seen = scanCount
			if gf - fInfo.lastScanned >= scanInterval then
				fInfo.lastScanned = gf

				local fx, _, fz = spGetFeaturePosition(fID)
				local fy = spGetGroundHeight(fx, fz)

				if fInfo.x ~= fx or fInfo.z ~= fz then
					DetachFeature(fID, fInfo)
					GridRemove(fID, fInfo)
					SetFeaturePosition(fID, fInfo, fx, fy, fz)
					GridAdd(fID, fInfo)
					unassigned[fID] = true
				elseif fInfo.y ~= fy then
					-- ground height changed (terrain deformation): same neighbours and cluster,
					-- only the hull height may change
					SetFeaturePosition(fID, fInfo, fx, fy, fz)
					local cluster = clusterOf[fID]
					if cluster then
						cluster.heightChanged = true
						changedClusters[cluster] = true
					end
				end

				if fInfo.metal ~= metal then
					if metal >= minFeatureMetal then
						fInfo.metal = metal
						local cluster = clusterOf[fID]
						if cluster then
							changedClusters[cluster] = true
						end
					else
						RemoveFeature(fID, fInfo)
					end
				end
			end
		end
	end

	for fID, fInfo in pairs(knownFeatures) do
		-- a feature returned by GetAllFeatures in this scan is valid
		if fInfo.isGaia and fInfo.seen ~= scanCount and spValidFeatureID(fID) == false then
			RemoveFeature(fID, fInfo)
		elseif gf - fInfo.lastScanned >= scanForRemovalInterval then --long time unseen features, maybe they were relcaimed or destroyed?
			local los = spIsPosInLos(fInfo.x, fInfo.y, fInfo.z, myAllyTeamID)
			if los then --this place has no feature, it's been moved or reclaimed or destroyed
				RemoveFeature(fID, fInfo)
			end
		end
	end

	if benchmark then
		benchmark:Leave("UpdateFeatures")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Clusters

local DeleteClusterLists, BucketRemove -- drawing side, defined below

local function NewCluster()
	local cluster = {members = {}, count = 0, metal = 0, fullHull = true}
	local index = #clusterList + 1
	clusterList[index] = cluster
	cluster.index = index
	changedClusters[cluster] = true
	return cluster
end

local function DestroyCluster(cluster)
	DeleteClusterLists(cluster)
	BucketRemove(cluster)
	local index, last = cluster.index, clusterList[#clusterList]
	clusterList[index] = last
	last.index = index
	clusterList[#clusterList] = nil
	changedClusters[cluster] = nil
end

local function MoveMembers(fromCluster, toCluster, fIDs)
	local fromMembers, toMembers = fromCluster.members, toCluster.members
	for i = 1, #fIDs do
		local fID = fIDs[i]
		fromMembers[fID] = nil
		toMembers[fID] = true
		clusterOf[fID] = toCluster
	end
	fromCluster.count = fromCluster.count - #fIDs
	toCluster.count = toCluster.count + #fIDs
end

-- Union-find over arbitrary keys.
local function Find(parent, a)
	local root = a
	while parent[root] ~= root do
		root = parent[root]
	end
	while parent[a] ~= root do
		local nextA = parent[a]
		parent[a] = root
		a = nextA
	end
	return root
end

local function IsNear(i, j)
	return i >= -1 and i <= 1 and j >= -1 and j <= 1
end

-- Members lost by a cluster (removed or moved features), grouped into connected groups by their
-- old positions. For each group: the grid cells holding remaining members that were neighbours of
-- the group, with one such member per cell (a cell's members are neighbours of each other), and
-- one of them per part of these cells that touch each other (only one part if they are linked).
local function GetLostGroups(cluster)
	local lostX, lostZ = cluster.lostX, cluster.lostZ
	cluster.lostX, cluster.lostZ = nil, nil
	local n = #lostX
	local gxs, gzs, parent = {}, {}, {}
	local lostGrid = {}
	for k = 1, n do
		local gx, gz = math.floor(lostX[k] / GRID_SIZE), math.floor(lostZ[k] / GRID_SIZE)
		gxs[k], gzs[k] = gx, gz
		parent[k] = k
		local key = gx * GRID_ROW + gz
		local list = lostGrid[key]
		if not list then
			list = {}
			lostGrid[key] = list
		end
		list[#list + 1] = k
	end
	for k = 1, n do
		local x, z = lostX[k], lostZ[k]
		for i = -GRID_REACH, GRID_REACH do
			for j = -GRID_REACH, GRID_REACH do
				local list = lostGrid[(gxs[k] + i) * GRID_ROW + gzs[k] + j]
				if list then
					local near = IsNear(i, j)
					for m = 1, #list do
						local k2 = list[m]
						if k2 > k and (near or (x - lostX[k2])^2 + (z - lostZ[k2])^2 <= minSqDistance) then
							local a, b = Find(parent, k), Find(parent, k2)
							if a ~= b then
								parent[a] = b
							end
						end
					end
				end
			end
		end
	end

	local groups, groupOf = {}, {}
	for k = 1, n do
		local root = Find(parent, k)
		local group = groupOf[root]
		if not group then
			group = {reps = {}, repOf = {}, cellX = {}, cellZ = {}}
			groupOf[root] = group
			groups[#groups + 1] = group
		end
		local reps, repOf, cellX, cellZ = group.reps, group.repOf, group.cellX, group.cellZ
		local x, z = lostX[k], lostZ[k]
		for i = -GRID_REACH, GRID_REACH do
			for j = -GRID_REACH, GRID_REACH do
				local key = (gxs[k] + i) * GRID_ROW + gzs[k] + j
				local cell = not repOf[key] and featureGrid[key]
				if cell then
					local near = IsNear(i, j)
					for fID in pairs(cell) do
						if clusterOf[fID] == cluster then
							local fInfo = knownFeatures[fID]
							if near or (x - fInfo.x)^2 + (z - fInfo.z)^2 <= minSqDistance then
								local r = #reps + 1
								reps[r] = fID
								repOf[key] = r
								cellX[r], cellZ[r] = gxs[k] + i, gzs[k] + j
								break
							end
						end
					end
				end
			end
		end
	end

	for g = 1, #groups do
		local group = groups[g]
		local reps, repOf, cellX, cellZ = group.reps, group.repOf, group.cellX, group.cellZ
		local cellParent = {}
		for r = 1, #reps do
			cellParent[r] = r
		end
		for r = 1, #reps do
			for i = -1, 1 do
				for j = -1, 1 do
					local r2 = repOf[(cellX[r] + i) * GRID_ROW + cellZ[r] + j]
					if r2 then
						local a, b = Find(cellParent, r), Find(cellParent, r2)
						if a ~= b then
							cellParent[a] = b
						end
					end
				end
			end
		end
		local parts, isPart = {}, {}
		for r = 1, #reps do
			local root = Find(cellParent, r)
			if not isPart[root] then
				isPart[root] = true
				parts[#parts + 1] = reps[r]
			end
		end
		if #parts > 1 then
			group.parts = parts
		end
	end
	return groups
end

-- Searches from all seeds in turn that merge when they meet. A search owns grid cells, i.e. all
-- members of the cluster in them (they are neighbours of each other). It grows to touching cells
-- first, whose members are neighbours of its own, which is cheap and enough in dense fields;
-- after that, to cells further away that hold a neighbour of one of its members. A search that
-- runs out of both has found a complete component, which becomes a new cluster. Stops when a
-- single search is left. Each turn a search does about SEARCH_STEP lookups, so the cost follows
-- the cheaper side. Returns true if anything was split off.
local SEARCH_STEP = 64

local function SearchComponents(cluster, seedList)
	local n = #seedList
	if n <= 1 then
		return false
	end

	local owner, noMembers = {}, {}
	local parent, cellX, cellZ, cellHead, nodes, nodeHead, cells = {}, {}, {}, {}, {}, {}, {}
	local active = n
	local split = false

	local function Claim(s, key, gx, gz)
		local cell = featureGrid[key]
		local nq = nodes[s]
		local before = #nq
		if cell then
			for fID in pairs(cell) do
				if clusterOf[fID] == cluster then
					nq[#nq + 1] = fID
				end
			end
		end
		if #nq > before then
			owner[key] = s
			local cx, cz, cl = cellX[s], cellZ[s], cells[s]
			cx[#cx + 1] = gx
			cz[#cz + 1] = gz
			cl[#cl + 1] = key
		else
			noMembers[key] = true
		end
	end

	-- merges the search with fewer cells into the other one, returns the remaining search
	local function Merge(a, b)
		if #cells[a] < #cells[b] then
			a, b = b, a
		end
		local ax, az, bx, bz = cellX[a], cellZ[a], cellX[b], cellZ[b]
		for k = cellHead[b], #bx do
			ax[#ax + 1] = bx[k]
			az[#az + 1] = bz[k]
		end
		local an, bn = nodes[a], nodes[b]
		for k = nodeHead[b], #bn do
			an[#an + 1] = bn[k]
		end
		local ac, bc = cells[a], cells[b]
		for k = 1, #bc do
			ac[#ac + 1] = bc[k]
		end
		parent[b] = a
		cellX[b], cellZ[b], nodes[b], cells[b] = nil, nil, nil, nil
		active = active - 1
		return a
	end

	for i = 1, n do
		parent[i] = i
		cellX[i], cellZ[i], nodes[i], cells[i] = {}, {}, {}, {}
		cellHead[i], nodeHead[i] = 1, 1
	end
	for i = 1, n do
		local fInfo = knownFeatures[seedList[i]]
		local key = fInfo.gridKey
		local o = owner[key]
		if o then
			o = Find(parent, o)
			local me = Find(parent, i)
			if o ~= me then
				Merge(o, me)
			end
		else
			Claim(Find(parent, i), key, fInfo.gx, fInfo.gz)
		end
	end

	while active > 1 do
		for i = 1, n do
			local work = 0
			while work < SEARCH_STEP and parent[i] == i and cells[i] do
				local me = i
				local cx, cz = cellX[me], cellZ[me]
				local h = cellHead[me]
				if h <= #cx then
					-- touching cells
					cellHead[me] = h + 1
					local gx, gz = cx[h], cz[h]
					for x = gx - 1, gx + 1 do
						for z = gz - 1, gz + 1 do
							local key = x * GRID_ROW + z
							local o = owner[key]
							if o then
								o = Find(parent, o)
								if o ~= me then
									me = Merge(me, o)
									if active <= 1 then
										return split
									end
								end
							elseif not noMembers[key] then
								Claim(me, key, x, z)
							end
						end
					end
					work = work + 9
				else
					local nq = nodes[me]
					local nh = nodeHead[me]
					if nh <= #nq then
						-- cells further away holding a neighbour of a member (the touching ones are
						-- done: all owned cells have been expanded)
						nodeHead[me] = nh + 1
						local fInfo = knownFeatures[nq[nh]]
						local x, z, gx, gz = fInfo.x, fInfo.z, fInfo.gx, fInfo.gz
						for i2 = -GRID_REACH, GRID_REACH do
							for j2 = -GRID_REACH, GRID_REACH do
								if not IsNear(i2, j2) then
									local key = (gx + i2) * GRID_ROW + gz + j2
									local o = owner[key]
									if o then
										o = Find(parent, o)
									end
									if o ~= me and not noMembers[key] then
										local cell = featureGrid[key]
										if cell then
											for fID2 in pairs(cell) do
												work = work + 1
												if clusterOf[fID2] == cluster then
													local fInfo2 = knownFeatures[fID2]
													if (x - fInfo2.x)^2 + (z - fInfo2.z)^2 <= minSqDistance then
														if o then
															me = Merge(me, o)
															if active <= 1 then
																return split
															end
														else
															Claim(me, key, gx + i2, gz + j2)
														end
														break
													end
												end
											end
										end
									end
								end
							end
						end
						work = work + 1
					else
						-- complete component
						local members = {}
						local cl = cells[me]
						for k = 1, #cl do
							for fID in pairs(featureGrid[cl[k]]) do
								if clusterOf[fID] == cluster then
									members[#members + 1] = fID
								end
							end
						end
						MoveMembers(cluster, NewCluster(), members)
						cellX[me], cellZ[me], nodes[me], cells[me] = nil, nil, nil, nil
						split = true
						active = active - 1
						if active <= 1 then
							return split
						end
					end
				end
			end
		end
	end
	return split
end

-- A cluster lost members: split off the parts that are no longer connected. Returns true if
-- anything was split off.
-- Every remaining member is connected to a remaining neighbour of some lost group (its old path to
-- a lost member enters a group from such a neighbour). A path through a group can be rerouted
-- through the group's neighbours if those are connected, so the rest is one cluster when every
-- group's neighbours are connected. That is checked per group: first by touching cells, then by
-- searching from the unlinked parts, which meet nearby unless the group really cut something
-- off (then the cut-off part is found and split off).
-- A split-off part that touches two groups may have been what connected their neighbours. If the
-- rest fell apart, an old path between two of its parts leaves the first one only into split-off
-- parts, and must leave one of those through a different group than it entered: so every part
-- holds the neighbours of a group touching such a split-off part. Searching from one neighbour
-- of each of those groups settles it.
local function SplitCluster(cluster)
	local groups = GetLostGroups(cluster)
	local split = false
	for g = 1, #groups do
		local parts = groups[g].parts
		if parts then
			local seeds = {}
			for j = 1, #parts do
				if clusterOf[parts[j]] == cluster then -- not in a part split off already
					seeds[#seeds + 1] = parts[j]
				end
			end
			split = SearchComponents(cluster, seeds) or split
		end
	end
	if split then
		local pieceGroup, bridging = {}, {}
		local bridged = false
		for g = 1, #groups do
			local reps = groups[g].reps
			for j = 1, #reps do
				local piece = clusterOf[reps[j]]
				if piece ~= cluster then
					if pieceGroup[piece] and pieceGroup[piece] ~= g then
						bridging[piece] = true
						bridged = true
					end
					pieceGroup[piece] = g
				end
			end
		end
		if bridged then
			local seeds, isSeed = {}, {}
			for g = 1, #groups do
				local reps = groups[g].reps
				local touches, survivor = false, nil
				for j = 1, #reps do
					local fID = reps[j]
					local piece = clusterOf[fID]
					if piece == cluster then
						survivor = survivor or fID
					elseif bridging[piece] then
						touches = true
					end
				end
				if touches and survivor and not isSeed[survivor] then -- groups can share neighbours
					isSeed[survivor] = true
					seeds[#seeds + 1] = survivor
				end
			end
			SearchComponents(cluster, seeds)
		end
	end
	return split
end

local function ProcessBrokenClusters()
	for i = 1, #brokenClusters do
		local cluster = brokenClusters[i]
		brokenClusters[i] = nil
		if cluster.count == 0 then
			cluster.lostX, cluster.lostZ = nil, nil
			DestroyCluster(cluster)
		else
			changedClusters[cluster] = true
			if SplitCluster(cluster) then
				cluster.fullHull = true
			elseif cluster.hullIsChain and not cluster.fullHull then
				-- removing points that are not hull vertices leaves the hull as it is
				local hull = cluster.hull
				for j = 1, #hull do
					if clusterOf[hull[j].fID] ~= cluster then
						cluster.fullHull = true
						break
					end
				end
			end
		end
	end
end

-- Candidate hull points of a cluster that is merged into another one.
local function AddHullCandidates(cluster, points)
	if cluster.fullHull or not cluster.hullIsChain then
		for fID in pairs(cluster.members) do
			points[#points + 1] = knownFeatures[fID].point
		end
	else
		local hull = cluster.hull
		for j = 1, #hull do
			points[#points + 1] = knownFeatures[hull[j].fID].point -- current height
		end
		local extra = cluster.extraPoints
		if extra then
			for j = 1, #extra do
				points[#points + 1] = extra[j]
			end
		end
	end
end

-- Added and moved features join the clusters they are neighbours of; clusters joined by them
-- merge into the largest one. The hull of a union is the hull of the parts' hull vertices and the
-- new points.
local function AssignNewFeatures()
	local list = {}
	for fID in pairs(unassigned) do
		list[#list + 1] = fID
	end
	for i = 1, #list do
		local start = list[i]
		if unassigned[start] then
			unassigned[start] = nil
			local group = {start}
			local adjacent = {}
			local k = 1
			while k <= #group do
				local fInfo = knownFeatures[group[k]]
				local x, z, gx, gz = fInfo.x, fInfo.z, fInfo.gx, fInfo.gz
				for i2 = -GRID_REACH, GRID_REACH do
					for j2 = -GRID_REACH, GRID_REACH do
						local cell = featureGrid[(gx + i2) * GRID_ROW + gz + j2]
						if cell then
							local near = IsNear(i2, j2)
							for fID2 in pairs(cell) do
								local cluster = clusterOf[fID2]
								if cluster then
									if not adjacent[cluster] then
										local fInfo2 = knownFeatures[fID2]
										if near or (x - fInfo2.x)^2 + (z - fInfo2.z)^2 <= minSqDistance then
											adjacent[cluster] = true
										end
									end
								elseif unassigned[fID2] then
									local fInfo2 = knownFeatures[fID2]
									if near or (x - fInfo2.x)^2 + (z - fInfo2.z)^2 <= minSqDistance then
										unassigned[fID2] = nil
										group[#group + 1] = fID2
									end
								end
							end
						end
					end
				end
				k = k + 1
			end

			local base
			for cluster in pairs(adjacent) do
				if not base or cluster.count > base.count then
					base = cluster
				end
			end
			if base then
				changedClusters[base] = true
				if not base.hullIsChain then
					base.fullHull = true
				end
			else
				base = NewCluster()
			end
			local extra
			if not base.fullHull then
				extra = base.extraPoints or {}
				base.extraPoints = extra
			end

			for cluster in pairs(adjacent) do
				if cluster ~= base then
					if extra then
						AddHullCandidates(cluster, extra)
					end
					local members = {}
					for fID in pairs(cluster.members) do
						members[#members + 1] = fID
					end
					MoveMembers(cluster, base, members)
					DestroyCluster(cluster)
				end
			end
			local baseMembers = base.members
			for j = 1, #group do
				local fID = group[j]
				baseMembers[fID] = true
				clusterOf[fID] = base
				if extra then
					extra[#extra + 1] = knownFeatures[fID].point
				end
			end
			base.count = base.count + #group
		end
	end
end

-- Akl-Toussaint: points strictly inside the polygon of the extreme points in eight directions
-- cannot be hull vertices. Points on or within a small margin of its edges are kept, so the
-- monotone chain result is the same as for all points.
local function PruneInterior(points)
	local n = #points
	local p = points[1]
	local e1, e2, e3, e4, e5, e6, e7, e8 = p, p, p, p, p, p, p, p
	local b1, b2, b3, b4 = p.x, p.x + p.z, p.z, p.z - p.x
	local b5, b6, b7, b8 = -p.x, -p.x - p.z, -p.z, p.x - p.z
	for i = 2, n do
		p = points[i]
		local x, z = p.x, p.z
		if x > b1 then b1, e1 = x, p end
		if x + z > b2 then b2, e2 = x + z, p end
		if z > b3 then b3, e3 = z, p end
		if z - x > b4 then b4, e4 = z - x, p end
		if -x > b5 then b5, e5 = -x, p end
		if -x - z > b6 then b6, e6 = -x - z, p end
		if -z > b7 then b7, e7 = -z, p end
		if x - z > b8 then b8, e8 = x - z, p end
	end
	-- counter-clockwise in the x-z plane, repeated points dropped
	local poly = {}
	local extremes = {e1, e2, e3, e4, e5, e6, e7, e8}
	for k = 1, 8 do
		if extremes[k] ~= poly[#poly] then
			poly[#poly + 1] = extremes[k]
		end
	end
	if #poly > 1 and poly[#poly] == poly[1] then
		poly[#poly] = nil
	end
	local m = #poly
	if m < 3 then
		return points
	end
	local ax, az, ex, ez, margin = {}, {}, {}, {}, {}
	for k = 1, m do
		local a, b = poly[k], poly[k % m + 1]
		ax[k], az[k] = a.x, a.z
		ex[k], ez[k] = b.x - a.x, b.z - a.z
		margin[k] = 1e-6 * (math.abs(ex[k]) + math.abs(ez[k]))
	end
	local kept = {}
	for i = 1, n do
		p = points[i]
		local x, z = p.x, p.z
		for k = 1, m do
			if ex[k] * (z - az[k]) - ez[k] * (x - ax[k]) <= margin[k] then
				kept[#kept + 1] = p
				break
			end
		end
	end
	return kept
end

local function SetClusterHull(cluster, convexHull)
	local cx, cz, cy = 0, 0, 0
	for i = 1, #convexHull do
		local convexHullPoint = convexHull[i]
		cx = cx + convexHullPoint.x
		cz = cz + convexHullPoint.z
		cy = math.max(cy, convexHullPoint.y)
	end

	local totalArea = 0
	local pt1 = convexHull[1]
	for i = 2, #convexHull - 1 do
		local pt2 = convexHull[i]
		local pt3 = convexHull[i + 1]
		--Heron formula to get triangle area
		local a = math.sqrt((pt2.x - pt1.x)^2 + (pt2.z - pt1.z)^2)
		local b = math.sqrt((pt3.x - pt2.x)^2 + (pt3.z - pt2.z)^2)
		local c = math.sqrt((pt3.x - pt1.x)^2 + (pt3.z - pt1.z)^2)
		local p = (a + b + c)/2 --half perimeter

		local triangleArea = math.sqrt(p * (p - a) * (p - b) * (p - c))
		totalArea = totalArea + triangleArea
	end

	convexHull.area = totalArea
	convexHull.center = {x = cx/#convexHull, z = cz/#convexHull, y = cy + 1}

	cluster.hull = convexHull
end

local function ClusterToConvexHull(cluster)
	local convexHull
	if cluster.count >= 3 then
		local clusterPoints = {}
		if cluster.hullIsChain and not cluster.fullHull then
			-- the old hull's vertices plus the points added since
			local hull, extra = cluster.hull, cluster.extraPoints
			for j = 1, #hull do
				clusterPoints[j] = knownFeatures[hull[j].fID].point -- current height
			end
			for j = 1, #extra do
				clusterPoints[#clusterPoints + 1] = extra[j]
			end
		end
		if #clusterPoints < 3 then -- full rebuild, or features stacked on the same spot
			clusterPoints = {}
			for fID in pairs(cluster.members) do
				clusterPoints[#clusterPoints + 1] = knownFeatures[fID].point
			end
		end
		if #clusterPoints > 16 then
			clusterPoints = PruneInterior(clusterPoints)
		end
		convexHull = ConvexHull.MonotoneChain(clusterPoints, benchmark) --twice faster
		cluster.hullIsChain = true
	else
		local xmin, xmax, zmin, zmax = math.huge, -math.huge, math.huge, -math.huge
		local height = -math.huge
		for fID in pairs(cluster.members) do
			local fInfo = knownFeatures[fID]
			xmin = math.min(xmin, fInfo.x)
			xmax = math.max(xmax, fInfo.x)
			zmin = math.min(zmin, fInfo.z)
			zmax = math.max(zmax, fInfo.z)
			height = math.max(height, fInfo.drawAlt)
		end

		local dx, dz = xmax - xmin, zmax - zmin

		if dx < minDim then
			xmin = xmin - (minDim - dx) / 2
			xmax = xmax + (minDim - dx) / 2
		end

		if dz < minDim then
			zmin = zmin - (minDim - dz) / 2
			zmax = zmax + (minDim - dz) / 2
		end

		convexHull = {
			{x = xmin, y = height, z = zmin},
			{x = xmax, y = height, z = zmin},
			{x = xmax, y = height, z = zmax},
			{x = xmin, y = height, z = zmax},
		}
		cluster.hullIsChain = false
	end
	SetClusterHull(cluster, convexHull)
end

local function ColorMul(scalar, actionColor)
	return {scalar * actionColor[1], scalar * actionColor[2], scalar * actionColor[3], actionColor[4]}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Initialize()
	Spring.Echo("Initialize")
	screenx, screeny = widgetHandler:GetViewSizes()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Drawing

local color
local cameraScale

local function DrawHullVertices(hull)
	for j = 1, #hull do
		glVertex(hull[j].x, hull[j].y, hull[j].z)
	end
end

-- Font size and label of a cluster, nil when it has no label (zero hull area).
local function GetClusterText(cluster)
	local fontSize = fontSizeMin * fontScaling
	local area = cluster.hull.area
	if area > 0 then
		fontSize = math.sqrt(area) * fontSize / minDim
		fontSize = math.max(fontSize, fontSizeMin)
		fontSize = math.min(fontSize, fontSizeMax)

		local metal = cluster.metal
		--Spring.Echo(metal)
		local metalText
		if metal < 1000 then
			metalText = string.format("%.0f", metal) --exact number
		elseif metal < 10000 then
			metalText = string.format("%.1fK", math.floor(metal / 100) / 10) --4.5K
		else
			metalText = string.format("%.0fK", math.floor(metal / 1000)) --40K
		end
		return fontSize, metalText, metal
	end
end

local function DrawClusterText(cluster)
	local fontSize, metalText, metal = GetClusterText(cluster)
	if fontSize then
		glPushMatrix()

		local center = cluster.hull.center

		glTranslate(center.x, center.y, center.z)
		glRotate(-90, 1, 0, 0)

		gl.Scale(fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE, fontSize / BASE_FONT_SIZE)

		local x100  = 100  / (100  + metal)
		local x1000 = 1000 / (1000 + metal)
		local r = 1 - x1000
		local g = x1000 - x100
		local b = x100

		--glRect(-200, -200, 200, 200)
		--glColor(r, g, b, 1.0)
		--glText(metalText, 0, 0, fontSize, "cv")
		font:Begin()
			font:SetTextColor(r, g, b, 1.0)
			font:Print(metalText, 0, 0, BASE_FONT_SIZE, "cv")
		font:End()

		glPopMatrix()
	end
end

--------------------------------------------------------------------------------
-- One display list per cluster and pass, so off-screen clusters can be skipped; a cluster's lists
-- are only rebuilt when it changes. The passes are as before, and a cluster is only skipped when
-- its bounding sphere, which contains the hull, the label and the edge line width, is outside the
-- camera frustum, i.e. when it cannot produce a pixel.
-- The labels cannot share one font:Begin/End: the engine font shader applies the modelview matrix
-- when End() draws, and every label needs its own translate/scale (different heights).

local spGetCameraFOV = Spring.GetCameraFOV
local spIsSphereInView = Spring.IsSphereInView

-- Clusters are prefiltered by 2048-elmo buckets whose spheres enclose their members' spheres.
local BUCKET_SIZE = 2048
local buckets = {} -- key -> bucket
local bucketList = {}
local dirtyBuckets = {}

DeleteClusterLists = function(cluster)
	if cluster.solidList then
		glDeleteList(cluster.solidList)
		glDeleteList(cluster.edgeList)
		cluster.solidList, cluster.edgeList = nil, nil
	end
	if cluster.textList then
		glDeleteList(cluster.textList)
		cluster.textList = nil
	end
end

BucketRemove = function(cluster)
	local bucket = cluster.bucket
	if bucket then
		bucket.members[cluster] = nil
		dirtyBuckets[bucket] = true
		cluster.bucket = nil
	end
end

-- Bounding sphere of a cluster: hull vertices plus the label quad. The label lies in the
-- y = center.y plane; text-space x maps to world x and text-space y to world -z, scaled by
-- fontSize/BASE_FONT_SIZE. Its extent is bounded generously: every glyph advance is below 1 em,
-- glyph overhang below 0.5 em, and the "cv" aligned line stays within 1.5 em of the centre
-- vertically.
local function UpdateCullBounds(cluster)
	local hull = cluster.hull
	local x0, y0, z0 = math.huge, math.huge, math.huge
	local x1, y1, z1 = -math.huge, -math.huge, -math.huge
	for j = 1, #hull do
		local pt = hull[j]
		x0, x1 = math.min(x0, pt.x), math.max(x1, pt.x)
		y0, y1 = math.min(y0, pt.y), math.max(y1, pt.y)
		z0, z1 = math.min(z0, pt.z), math.max(z1, pt.z)
	end
	local fontSize, metalText = GetClusterText(cluster)
	if fontSize then
		local center = hull.center
		local hx = fontSize * (0.5 * #metalText + 0.5) + 2
		local hz = fontSize * 1.5 + 2
		x0, x1 = math.min(x0, center.x - hx), math.max(x1, center.x + hx)
		y0, y1 = math.min(y0, center.y), math.max(y1, center.y)
		z0, z1 = math.min(z0, center.z - hz), math.max(z1, center.z + hz)
	end
	if x0 > x1 then -- no vertices and no label: draws nothing
		x0, x1, y0, y1, z0, z1 = 0, 0, 0, 0, 0, 0
	end
	local cx, cy, cz = 0.5*(x0 + x1), 0.5*(y0 + y1), 0.5*(z0 + z1)
	cluster.cullX, cluster.cullY, cluster.cullZ = cx, cy, cz
	cluster.cullR = 0.5*math.sqrt((x1 - x0)^2 + (y1 - y0)^2 + (z1 - z0)^2) + 1

	local key = math.floor(cx / BUCKET_SIZE) + 4096*math.floor(cz / BUCKET_SIZE)
	local bucket = cluster.bucket
	if not (bucket and bucket.key == key) then
		BucketRemove(cluster)
		bucket = buckets[key]
		if not bucket then
			bucket = {key = key, members = {}, visible = false}
			buckets[key] = bucket
			bucketList[#bucketList + 1] = bucket
			bucket.index = #bucketList
		end
		bucket.members[cluster] = true
		cluster.bucket = bucket
	end
	dirtyBuckets[bucket] = true
end

-- Bucket sphere: encloses the AABB of its member spheres, hence every member sphere.
local function UpdateBuckets()
	for bucket in pairs(dirtyBuckets) do
		local x0, y0, z0 = math.huge, math.huge, math.huge
		local x1, y1, z1 = -math.huge, -math.huge, -math.huge
		for cluster in pairs(bucket.members) do
			local cx, cy, cz, r = cluster.cullX, cluster.cullY, cluster.cullZ, cluster.cullR
			x0, y0, z0 = math.min(x0, cx - r), math.min(y0, cy - r), math.min(z0, cz - r)
			x1, y1, z1 = math.max(x1, cx + r), math.max(y1, cy + r), math.max(z1, cz + r)
		end
		if x0 > x1 then -- empty
			local last = bucketList[#bucketList]
			bucketList[bucket.index] = last
			last.index = bucket.index
			bucketList[#bucketList] = nil
			buckets[bucket.key] = nil
		else
			bucket.x, bucket.y, bucket.z = 0.5*(x0 + x1), 0.5*(y0 + y1), 0.5*(z0 + z1)
			bucket.r = 0.5*math.sqrt((x1 - x0)^2 + (y1 - y0)^2 + (z1 - z0)^2) + 1
		end
	end
	dirtyBuckets = {}
end

local function BuildHullLists(cluster)
	if cluster.solidList then
		glDeleteList(cluster.solidList)
		glDeleteList(cluster.edgeList)
	end
	-- the PolygonMode calls are issued once per pass in DrawWorld
	cluster.solidList = glCreateList(glBeginEnd, GL.TRIANGLE_FAN, DrawHullVertices, cluster.hull)
	cluster.edgeList = glCreateList(glBeginEnd, GL.LINE_LOOP, DrawHullVertices, cluster.hull)
end

local function BuildTextList(cluster)
	if cluster.textList then
		glDeleteList(cluster.textList)
		cluster.textList = nil
	end
	if GetClusterText(cluster) then
		cluster.textList = glCreateList(DrawClusterText, cluster)
	end
	UpdateCullBounds(cluster)
end

-- Metal, hull and display lists of the clusters that changed in this scan.
local function UpdateChangedClusters()
	for cluster in pairs(changedClusters) do
		local metal = 0
		for fID in pairs(cluster.members) do
			metal = metal + knownFeatures[fID].metal
		end
		cluster.metal = metal

		if cluster.fullHull or cluster.count < 3 or not cluster.hullIsChain or cluster.extraPoints then
			ClusterToConvexHull(cluster)
			BuildHullLists(cluster)
		elseif cluster.heightChanged then
			-- same vertices, take their current heights
			local hull = cluster.hull
			local newHull = {}
			local changed = false
			for j = 1, #hull do
				local point = knownFeatures[hull[j].fID].point
				newHull[j] = point
				changed = changed or (point ~= hull[j])
			end
			if changed then
				SetClusterHull(cluster, newHull)
				BuildHullLists(cluster)
			end
		end
		cluster.fullHull = false
		cluster.extraPoints = nil
		cluster.heightChanged = nil
		BuildTextList(cluster)
	end
	changedClusters = {}
end

local function UpdateVisibility()
	local camX, camY, camZ = spGetCameraPosition()
	-- A wide edge line can reach (width/2 + 1) px beyond its geometry; one pixel spans at most
	-- dist * 2*tan(vfov/2) / viewHeight world units at distance dist. Grow the spheres by that.
	local lineHalfWidthPx = 0.5 * (6.0 / cameraScale) + 1
	local marginPerDist = lineHalfWidthPx * 2 * math.tan(math.rad(spGetCameraFOV()) * 0.5) / screeny
	for b = 1, #bucketList do
		local bucket = bucketList[b]
		local x, y, z, r = bucket.x, bucket.y, bucket.z, bucket.r
		local dist = math.sqrt((x - camX)^2 + (y - camY)^2 + (z - camZ)^2)
		bucket.visible = spIsSphereInView(x, y, z, r + marginPerDist * (dist + r))
	end
	for i = 1, #clusterList do
		local cluster = clusterList[i]
		if cluster.bucket.visible then
			local x, y, z, r = cluster.cullX, cluster.cullY, cluster.cullZ, cluster.cullR
			local dist = math.sqrt((x - camX)^2 + (y - camY)^2 + (z - camZ)^2)
			cluster.visible = spIsSphereInView(x, y, z, r + marginPerDist * (dist + r))
		else
			cluster.visible = false
		end
	end
end

local RefreshFeatureData -- defined below; Update calls it when drawing turns on with stale data
local dataStale = true

function widget:Update(dt)
	cumDt = cumDt + dt
	local cx, cy, cz = spGetCameraPosition()

	local desc, w = spTraceScreenRay(screenx / 2, screeny / 2, true)
	if desc then
		local cameraDist = math.min( 8000, math.sqrt( (cx-w[1])^2 + (cy-w[2])^2 + (cz-w[3])^2 ) )
		cameraScale = math.sqrt((cameraDist / 600)) --number is an "optimal" view distance
	else
		cameraScale = 1.0
	end

	drawEnabled = UpdateDrawEnabled()
	if drawEnabled and dataStale then
		RefreshFeatureData(spGetGameFrame())
	end

	local frame = spGetGameFrame()
	color = 0.5 + flashStrength * (frame % checkFrequency - checkFrequency)/(checkFrequency - 1)
	if color < 0 then
		color = 0
	end
	if color > 1 then
		color = 1
	end
end

function widget:GameFrame(frame)
	local frameMod = frame % checkFrequency
	if frameMod ~= 0 then
		return
	end
	if not drawEnabled then
		-- Nothing is drawn (by default only while constructors are selected), so skip the scan of
		-- every feature, the clustering and the display-list rebuilds; Update refreshes on the
		-- frame drawing turns back on. The scan compares against the last known state, so the
		-- result is the same.
		dataStale = true
		return
	end
	RefreshFeatureData(frame)
end

RefreshFeatureData = function(frame)
	dataStale = false
	if benchmark then
		benchmark:Enter("RefreshFeatureData")
	end
	UpdateFeatures(frame)
	ProcessBrokenClusters()
	AssignNewFeatures()
	UpdateChangedClusters()
	if textParametersChanged then
		for i = 1, #clusterList do
			BuildTextList(clusterList[i])
		end
		textParametersChanged = false
	end
	UpdateBuckets()
	dataBuilt = true
	if benchmark then
		benchmark:Leave("RefreshFeatureData")
	end
end

function widget:ViewResize(viewSizeX, viewSizeY)
	screenx, screeny = widgetHandler:GetViewSizes()
end

function widget:DrawWorld()
	if spIsGUIHidden() or not drawEnabled then
		return
	end

	glDepthTest(false)
	--glDepthTest(true)

	glBlending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	if dataBuilt then
		UpdateVisibility()
		local count = #clusterList

		glColor(ColorMul(color, reclaimColor))
		glPolygonMode(GL.FRONT_AND_BACK, GL.FILL)
		for i = 1, count do
			local cluster = clusterList[i]
			if cluster.visible then
				glCallList(cluster.solidList)
			end
		end

		glLineWidth(6.0 / cameraScale)
		glColor(ColorMul(color, reclaimEdgeColor))
		glPolygonMode(GL.FRONT_AND_BACK, GL.LINE)
		for i = 1, count do
			local cluster = clusterList[i]
			if cluster.visible then
				glCallList(cluster.edgeList)
			end
		end
		glPolygonMode(GL.FRONT_AND_BACK, GL.FILL)
		glLineWidth(1.0)

		for i = 1, count do
			local cluster = clusterList[i]
			if cluster.visible and cluster.textList then
				glCallList(cluster.textList)
			end
		end
	end

	glDepthTest(true)
end

function widget:Shutdown()
	for i = 1, #clusterList do
		DeleteClusterLists(clusterList[i])
	end
	if benchmark then
		benchmark:PrintAllStat()
	end
end
