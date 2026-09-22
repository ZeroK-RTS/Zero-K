
function widget:GetInfo()
	return {
		name      = "energy grid handler",
		desc      = "orders cons to build energy grid",
		author    = "Amnykon (adapted from Google Frog, with parts from Niobium and Evil4Zerggin)",
		version   = "v2",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 1001, -- Under Chili
		enabled   = true
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")
include("keysym.lua")
VFS.Include("LuaRules/Utilities/glVolumes.lua")

------------------------------------------------------------
-- Speedups
------------------------------------------------------------
local spGetActiveCommand    = Spring.GetActiveCommand
local spGetMouseState       = Spring.GetMouseState
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetUnitAllyTeam     = Spring.GetUnitAllyTeam
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetMyTeamID         = Spring.GetMyTeamID
local spTestBuildOrder      = Spring.TestBuildOrder
local spGetUnitsInRectangle = Spring.GetUnitsInRectangle
local spGetCommandQueue     = Spring.GetCommandQueue
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGroundNormal     = Spring.GetGroundNormal
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetAllUnits         = Spring.GetAllUnits
local spGetModKeyState      = Spring.GetModKeyState

local glLineWidth        = gl.LineWidth
local glColor            = gl.Color
local glUnitShape        = gl.UnitShape
local glLoadIdentity     = gl.LoadIdentity
local glRotate           = gl.Rotate
local glPopMatrix        = gl.PopMatrix
local glPushMatrix       = gl.PushMatrix
local glTranslate        = gl.Translate


local abs   = math.abs
local floor = math.floor
local ceil = math.ceil
local max   = math.max
local min   = math.min
local sqrt  = math.sqrt
local cos   = math.cos
local sin   = math.sin
local atan2 = math.atan2
local pi    = math.pi


------------------------------------------------------------
-- Functions
------------------------------------------------------------

local function Distance(x1,z1,x2,z2)
	return sqrt((x1-x2)*(x1-x2)+(z1-z2)*(z1-z2))
end

-- Squared distance, for comparisons against a (squared) threshold -- avoids sqrt.
local function DistanceSq(x1,z1,x2,z2)
	return (x1-x2)*(x1-x2)+(z1-z2)*(z1-z2)
end

--------------------------------------------------------------------------------
-- UnitDefID constants
--------------------------------------------------------------------------------

local pylonRange = {}
local pylons = {}
local floatOnWater = {}
local mexDefID = UnitDefNames["staticmex"].id
local mexRange = UnitDefNames["staticmex"].customParams.pylonrange
local geoDefID = UnitDefNames["energygeo"].id
local geoRange = UnitDefNames["energygeo"].customParams.pylonrange
local lltDefID = UnitDefNames["turretlaser"].id
local lltRange = UnitDefNames["turretlaser"].maxWeaponRange or 460

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
        local cp = ud.customParams
	if cp.energy_grid then
		pylons[i] = true
	end
	if cp.pylonrange then
		pylonRange[i] = cp.pylonrange
	end
	if ud.floatOnWater then
		floatOnWater[i] = true
	end
end

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local pregame = true

local myTeamID = spGetMyTeamID()

-- Planned-but-not-built structures to treat as anchors/occupancy (never rebuilt),
-- rebuilt each recompute: the initial build queue pre-game, or -- in-game -- the
-- build queues of the units this command is being issued to (so re-dragging with
-- the same con doesn't stack duplicate orders). Each entry: {defID, x, z, range}.
local queuedBuildings = {}

-- In-game grid structures queued by OTHER ally constructors (not the current
-- selection). Zero-K lets several cons share a build site, so a drag with a
-- different unit should build these too rather than skip them. Same entry shape.
local queuedByOthers = {}

------------------------------------------------------------
-- Config
------------------------------------------------------------

options_path = 'Settings/Interface/Energy Grid'
options_order = { 'autoTerraform', 'clearEnemyMex', 'recomputeStep', 'terrainPenalty' }
options = {
	autoTerraform = {
		name = 'Terraform unbuildable spots',
		type = 'bool',
		value = true,
		desc = 'Level (and submerge geos) spots that are not buildable as-is, instead of leaving them out.',
	},
	clearEnemyMex = {
		name = 'Attack enemy-held spots with LLTs',
		type = 'bool',
		value = false,
		desc = 'When a metal or geo spot is held by an enemy, queue an LLT to clear it before building.',
	},
	recomputeStep = {
		name = 'Recompute step',
		type = 'number',
		value = 16, min = 1, max = 128, step = 1,
		desc = 'How far (elmos) the drag radius must move before the grid preview is recomputed.',
	},
	terrainPenalty = {
		name = 'Terrain avoidance',
		type = 'number',
		value = 300, min = 0, max = 2000, step = 10,
		desc = 'How strongly routing avoids crossing unbuildable ground.',
	},
}

--------------------------------------------------------------------------------
-- command
--------------------------------------------------------------------------------

local cmdID
local cmdIndex
local cmdCenterX
local cmdCenterZ
local cmdDist
local cmdPylonRange
local planDirty = false  -- recompute the build plan only when the drag changes
local lastPlanDist = 0   -- cmdDist at the last recompute (drag radius)
local awaitingShiftRelease = false -- an order was given with shift held; deselect once shift lifts

local function GetDistanceFromCmd(x,z)
	return sqrt((cmdCenterX-x)*(cmdCenterX-x)+(cmdCenterZ-z)*(cmdCenterZ-z))
end

local function clearCmd()
	cmdID = nil
	cmdIndex = nil
	cmdCenterX = nil
	cmdCenterZ = nil
	cmdDist = nil
	cmdPylonRange = nil
end

------------------------------------------------------------
-- Terrain awareness
------------------------------------------------------------

-- (A) Exact buildability test at (x, z). TestBuildOrder accounts for the unit's
-- max build slope and water rules, plus blocking. 0 == cannot build here.
local function PosBuildable(defID, x, z, facing)
	local y = spGetGroundHeight(x, z)
	return spTestBuildOrder(defID, x, y, z, facing or 0) ~= 0
end

-- Ground-height range across a structure's footprint (centre + four corners).
local function footprintHeightRange(defID, x, z)
	local ud = UnitDefs[defID]
	local hx = (ud.xsize or 8) * 4
	local hz = (ud.zsize or 8) * 4
	local minH = spGetGroundHeight(x, z)
	local maxH = minH
	local cx = {-hx, -hx, hx, hx}
	local cz = {-hz, hz, -hz, hz}
	for i = 1, 4 do
		local gh = spGetGroundHeight(x + cx[i], z + cz[i])
		if gh < minH then minH = gh end
		if gh > maxH then maxH = gh end
	end
	return minH, maxH
end

-- Terraform target height for a mex/geo that can't be built as-is. Normally level
-- to the current ground height (flatten in place). A geo additionally cannot be
-- partially submerged, so if its footprint straddles the water line, level it
-- below water to fully submerge it rather than raising it out.
local SUBMERGE_MARGIN = 8
local function terraformTargetHeight(defID, x, z)
	local h = spGetGroundHeight(x, z)
	if defID == geoDefID then
		local minH, maxH = footprintHeightRange(defID, x, z)
		if minH < 0 and maxH > 0 then
			return min(h, -SUBMERGE_MARGIN)
		end
	end
	return h
end

-- (B) Cheap "bad ground for a pylon" proxy for routing: underwater (for a pylon
-- that can't float) or too steep. Lighter than TestBuildOrder for the many
-- samples the distance metric takes. Results are memoized per recompute on a
-- coarse grid: this feeds only the routing heuristic (never actual placement), so
-- quantizing the sample position is harmless and cuts the O(n^2) sampling cost.
local TERRAIN_MIN_FLAT = 0.9 -- ground-normal y below this counts as too steep
local GROUND_CACHE_CELL = 16 -- elmos per memo cell
local groundBadCache = {}
local function GroundBadForPylon(x, z)
	local key = floor(x / GROUND_CACHE_CELL) * 100000 + floor(z / GROUND_CACHE_CELL)
	local cached = groundBadCache[key]
	if cached ~= nil then
		return cached
	end
	local bad
	if spGetGroundHeight(x, z) < 0 and not floatOnWater[cmdID] then
		bad = true
	else
		local _, ny = spGetGroundNormal(x, z)
		bad = ny ~= nil and ny < TERRAIN_MIN_FLAT
	end
	groundBadCache[key] = bad
	return bad
end

-- (B) Straight-line distance plus a penalty for each sampled point over bad
-- ground, so the routing heuristics prefer links that stay buildable.
local TERRAIN_SAMPLES = 4
local function TerrainDistance(x1, z1, x2, z2)
	local cost = Distance(x1, z1, x2, z2)
	local penalty = options.terrainPenalty.value
	for i = 1, TERRAIN_SAMPLES do
		local t = i / (TERRAIN_SAMPLES + 1)
		if GroundBadForPylon(x1 + (x2 - x1) * t, z1 + (z2 - z1) * t) then
			cost = cost + penalty
		end
	end
	return cost
end
	
------------------------------------------------------------
-- Mouse functions
------------------------------------------------------------

local function GetMousePos()
        local mouseX, mouseY = spGetMouseState()
        local _, mouse = spTraceScreenRay(mouseX, mouseY, true, true, false, not floatOnWater[cmdID])
        if not mouse then
                return
        end

        return mouse[1], mouse[3]
end

local function GetMouseDistance() 
	local edgeX, edgeZ = GetMousePos()
	if not edgeX then
		return nil
	end
	return GetDistanceFromCmd(edgeX, edgeZ)
end


--------------------------------------------------------------------------------
-- all pylons
--------------------------------------------------------------------------------

local allPylonsPos = {}
local allPylonsDefID = {}
local allPylonsID = {}
local allPylonsRange = {}
local allPylonsX = {}
local allPylonsZ = {}
local allPylonsCount = 0

local function addUnitToAllPylons(unitID, unitDefID)
	if not pylonRange[unitDefID] then
		return 
	end
	local x,_,z = spGetUnitPosition(unitID)
	allPylonsCount = allPylonsCount + 1
	allPylonsPos[unitID] = allPylonsCount  
	allPylonsDefID[allPylonsCount] = unitDefID
	allPylonsID[allPylonsCount] = unitID
	allPylonsRange[allPylonsCount] = pylonRange[unitDefID]
	allPylonsX[allPylonsCount] = x
	allPylonsZ[allPylonsCount] = z
end

local function removeUnitFromAllPylons(unitID)
	if not allPylonsPos[unitID] then
		return
	end
	local pos = allPylonsPos[unitID]
	allPylonsDefID[pos] = allPylonsDefID[allPylonsCount]
	allPylonsID[pos] = allPylonsID[allPylonsCount]
	allPylonsRange[pos] = allPylonsRange[allPylonsCount]
	allPylonsX[pos] = allPylonsX[allPylonsCount]
	allPylonsZ[pos] = allPylonsZ[allPylonsCount]

	allPylonsPos[allPylonsID[allPylonsCount]] = pos
	allPylonsPos[unitID] = nil

	allPylonsDefID[allPylonsCount] = nil
	allPylonsID[allPylonsCount] = nil
	allPylonsRange[allPylonsCount] = nil
	allPylonsX[allPylonsCount] = nil
	allPylonsZ[allPylonsCount] = nil

	allPylonsCount = allPylonsCount - 1
end

local function clearAllPylons()
	allPylonsPos = {}
	allPylonsDefID = {}
	allPylonsID = {}
	allPylonsRange = {}
	allPylonsX = {}
	allPylonsZ = {}
	allPylonsCount = 0
end

-- (Re)build the pylon set from every structure on our ally team. The grid is
-- ally-wide, so allied pylons/mexes/geos are anchors too.
local function rescanUnits()
	clearAllPylons()
	local myAllyTeam = spGetMyAllyTeamID()
	local units = spGetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		if spGetUnitAllyTeam(unitID) == myAllyTeam then
			addUnitToAllPylons(unitID, spGetUnitDefID(unitID))
		end
	end
end

------------------------------------------------------------
-- pylons to build
------------------------------------------------------------

local pylonsToBuildDefID = {}
local pylonsToBuildX = {}
local pylonsToBuildZ = {}
local pylonsToBuildRange = {}
local pylonsToBuildBuild = {}
local pylonsToBuildTerraform = {}
local pylonsToBuildCount = 0

-- Extra structures to build alongside the grid (e.g. LLTs to clear enemy-held mex
-- spots). Kept separate from the pylon lists so they take no part in grid routing.
local extraBuildDefID = {}
local extraBuildX = {}
local extraBuildZ = {}
local extraBuildCount = 0

local function addExtraBuild(defID, x, z)
	extraBuildCount = extraBuildCount + 1
	extraBuildDefID[extraBuildCount] = defID
	extraBuildX[extraBuildCount] = x
	extraBuildZ[extraBuildCount] = z
end

local function clearExtraBuild()
	extraBuildDefID = {}
	extraBuildX = {}
	extraBuildZ = {}
	extraBuildCount = 0
end

-- terraformHeight is the level-to height when the spot must be terraformed first,
-- or nil when it is naturally buildable.
local function addPylonsToBuild(defID, x, z, range, build, terraformHeight)
	pylonsToBuildCount = pylonsToBuildCount + 1
	pylonsToBuildDefID[pylonsToBuildCount] = defID
	pylonsToBuildX[pylonsToBuildCount] = x
	pylonsToBuildZ[pylonsToBuildCount] = z
	pylonsToBuildRange[pylonsToBuildCount] = range
	pylonsToBuildBuild[pylonsToBuildCount] = build
	pylonsToBuildTerraform[pylonsToBuildCount] = terraformHeight
end

local function clearPylonsToBuild() 
	pylonsToBuildDefID = {}
	pylonsToBuildX = {}
	pylonsToBuildZ = {}
	pylonsToBuildRange = {}
	pylonsToBuildBuild = {}
	pylonsToBuildTerraform = {}
	pylonsToBuildNext = {}
	pylonsToBuildCount = 0
end

local EMPTY_TABLE = {}

-- How many structures we may still queue. Pre-game the initial queue has a hard
-- cap (MAX_QUEUE); in-game there is no such limit.
local function buildLimit()
	if not pregame then
		return math.huge
	end
	-- Pre-game we always append to the initial queue, so the room left is the cap
	-- minus what is already queued (ours or the player's).
	local maxCount = WG.InitialQueueMaxCount or 30
	local count = (WG.InitialQueueGetCount and WG.InitialQueueGetCount()) or 0
	return max(0, maxCount - count)
end

-- Register an actual level-terraform of a structure's footprint with the terraform
-- gadget (CMD_TERRAFORM_INTERNAL) and return its tag; the caller then queues a
-- CMD_LEVEL marker carrying that tag ahead of the build. Without this the queued
-- CMD_LEVEL refers to no terraform, so the constructor skips it (and the build).
local function issueTerraform(x, z, targetHeight, defID, facing, constructors)
	if #constructors == 0 or not CMD_TERRAFORM_INTERNAL or not WG.Terraform_GetNextTag then
		return nil
	end
	local ud = UnitDefs[defID]
	local footX = (ud.xsize / 2) * 8 - 0.1
	local footZ = (ud.zsize / 2) * 8 - 0.1
	if facing == 1 or facing == 3 then
		footX, footZ = footZ, footX
	end
	local tag = WG.Terraform_GetNextTag()
	local params = {
		1,                                    -- terraform type = level
		Spring.GetUnitTeam(constructors[1]) or myTeamID,
		x, z, tag,
		1,                                    -- loop
		targetHeight,                         -- level-to height
		5,                                    -- number of boundary points
		#constructors,
		0,                                    -- ordinary volume selection
		x + footX, z + footZ,                 -- footprint rectangle (closed loop)
		x + footX, z - footZ,
		x - footX, z - footZ,
		x - footX, z + footZ,
		x + footX, z + footZ,
	}
	for i = 1, #constructors do
		params[#params + 1] = constructors[i]
	end
	Spring.GiveOrderToUnit(constructors[1], CMD_TERRAFORM_INTERNAL, params, 0)
	return tag
end

-- Order the buildable items into a nearest-neighbour path from (startX, startZ), so
-- the queue follows the worker's route -- structures get built as it passes them --
-- instead of all mexes first then all pylons. Returns pylonsToBuild indices.
local function orderBuildItemsByPath(startX, startZ)
	local items = {}
	for i = 1, pylonsToBuildCount do
		if pylonsToBuildBuild[i] then
			items[#items + 1] = i
		end
	end
	local ordered = {}
	local taken = {}
	local cx, cz = startX, startZ
	for _ = 1, #items do
		local best, bestD
		for k = 1, #items do
			local idx = items[k]
			if not taken[idx] then
				local dx = pylonsToBuildX[idx] - cx
				local dz = pylonsToBuildZ[idx] - cz
				local d = dx * dx + dz * dz
				if not bestD or d < bestD then
					bestD, best = d, idx
				end
			end
		end
		taken[best] = true
		ordered[#ordered + 1] = best
		cx, cz = pylonsToBuildX[best], pylonsToBuildZ[best]
	end
	return ordered
end

local function orderPylonsToBuild()
	local a,c,m,s = spGetModKeyState()

	-- Pre-game: route through the initial build queue and respect its cap.
	if pregame then
		if not WG.InitialQueueHandleCommand then
			return
		end
		local limit = buildLimit()
		-- Always shift-append so we add to (never wipe) the player's initial queue.
		local cmdOpts = { shift = true }
		-- Continue the worker's route from where its initial queue currently ends; if
		-- nothing is queued yet, start from the team's start position (start-area centre).
		local sx, sz
		if WG.InitialQueueGetTail then
			sx, sz = WG.InitialQueueGetTail()
		end
		if not sx then
			local tx, _, tz = Spring.GetTeamStartPosition(myTeamID)
			if tx and tx > 0 then
				sx, sz = tx, tz
			else
				sx, sz = cmdCenterX, cmdCenterZ
			end
		end
		local ordered = orderBuildItemsByPath(sx, sz)
		local issued = 0
		for k = 1, #ordered do
			if issued >= limit then
				break
			end
			local index = ordered[k]
			local defID = pylonsToBuildDefID[index]
			local x = pylonsToBuildX[index]
			local z = pylonsToBuildZ[index]
			local y = Spring.GetGroundHeight(x, z)
			WG.InitialQueueHandleCommand(-defID, {x, y, z, Spring.GetBuildFacing()}, cmdOpts)
			issued = issued + 1
		end
		return
	end

	if not WG.CommandInsert then
		return -- the command-insert provider widget isn't available
	end

	local cmdOpts = {
		alt = a,
		shift = true,
		ctrl = c,
		meta = m,
		coded = (a and CMD.OPT_ALT   or 0)
		      + (m and CMD.OPT_META  or 0)
		      + (CMD.OPT_SHIFT)
		      + (c and CMD.OPT_CTRL  or 0)
	}

	if not s then
		Spring.GiveOrder (CMD.STOP, EMPTY_TABLE, 0)
	end

	-- Selected mobile builders, needed to register terraform for unbuildable spots.
	local terraformCons = {}
	local selected = Spring.GetSelectedUnits()
	for i = 1, #selected do
		local ud = UnitDefs[spGetUnitDefID(selected[i])]
		if ud and ud.isMobileBuilder then
			terraformCons[#terraformCons + 1] = selected[i]
		end
	end

	local pos = 0

	-- Clear enemy-held mex spots first, so the mex queued behind them can build once clear.
	for index = 1, extraBuildCount do
		local defID = extraBuildDefID[index]
		local x = extraBuildX[index]
		local z = extraBuildZ[index]
		local y = Spring.GetGroundHeight(x, z)
		local facing = Spring.GetBuildFacing()
		WG.CommandInsert(-defID, {x, y, z, facing}, cmdOpts, pos)
		pos = pos + 1
	end

	-- Order builds along the worker's route (nearest-neighbour from a selected
	-- builder, else the drag centre), so they're built as it passes them.
	local sx, sz = cmdCenterX, cmdCenterZ
	if terraformCons[1] then
		local ux, _, uz = Spring.GetUnitPosition(terraformCons[1])
		if ux then
			sx, sz = ux, uz
		end
	end
	local ordered = orderBuildItemsByPath(sx, sz)

	for k = 1, #ordered do
		local index = ordered[k]
		local defID = pylonsToBuildDefID[index]
		local x = pylonsToBuildX[index]
		local z = pylonsToBuildZ[index]

		local terraH = pylonsToBuildTerraform[index]
		local y = terraH or Spring.GetGroundHeight(x, z)
		local facing = Spring.GetBuildFacing()

		-- Terraform-level the spot (to terraH) first when it isn't buildable as-is:
		-- register the terraform, then queue its CMD_LEVEL marker ahead of the build.
		if terraH and options.autoTerraform.value and CMD_LEVEL then
			local tag = issueTerraform(x, z, terraH, defID, facing, terraformCons)
			if tag then
				WG.CommandInsert(CMD_LEVEL, {x, terraH, z, tag}, cmdOpts, pos)
				pos = pos + 1
			end
		end

		WG.CommandInsert(-defID, {x, y, z, facing}, cmdOpts, pos)
		pos = pos + 1
	end
end

local function drawPylonsToBuild()
	-- Match the preview to what will actually be queued (pre-game cap).
	local limit = buildLimit()
	local shown = 0
	for index = 1, pylonsToBuildCount do
		-- Only preview things we're actually building; skip existing-structure anchors.
		if pylonsToBuildBuild[index] and shown < limit then
			shown = shown + 1
			local defID = pylonsToBuildDefID[index]
			local x = pylonsToBuildX[index]
			local z = pylonsToBuildZ[index]
			local range = pylonsToBuildRange[index]

			local facing = Spring.GetBuildFacing()
			--grid (orange tint marks a pylon that will terraform its spot first)
			if pylonsToBuildTerraform[index] then
				glColor(1,0.6,0,0.3)
			else
				glColor(1,1,0,0.3)
			end
			gl.Utilities.DrawGroundCircle(x, z, range)

			--ghost
			glPushMatrix()
			glLoadIdentity()
			glTranslate(x, spGetGroundHeight(x, z), z)
			glRotate(90 * facing, 0, 1.0, 0 )
			glUnitShape(defID, myTeamID, false, false, false)
			glPopMatrix()
		end
	end

	-- LLTs queued to clear enemy-held mex spots
	local facing = Spring.GetBuildFacing()
	for index = 1, extraBuildCount do
		local defID = extraBuildDefID[index]
		local x = extraBuildX[index]
		local z = extraBuildZ[index]

		--attack range
		glColor(1,0.3,0.3,0.3)
		gl.Utilities.DrawGroundCircle(x, z, lltRange)

		--ghost
		glPushMatrix()
		glLoadIdentity()
		glTranslate(x, spGetGroundHeight(x, z), z)
		glRotate(90 * facing, 0, 1.0, 0)
		glUnitShape(defID, myTeamID, false, false, false)
		glPopMatrix()
	end
end

------------------------------------------------------------
-- pylons to connect
------------------------------------------------------------

local pylonsToConnectDefID = {}
local pylonsToConnectX = {}
local pylonsToConnectZ = {}
local pylonsToConnectRange = {}
local pylonsToConnectBuild = {}
local pylonsToConnectCount = 0

local function addPylonsToConnect(defID, x, z, range, build) 
	if GetDistanceFromCmd(x,z) - range > cmdDist + cmdPylonRange then
		return
	end
	pylonsToConnectCount = pylonsToConnectCount + 1
	pylonsToConnectDefID[pylonsToConnectCount] = defID
	pylonsToConnectX[pylonsToConnectCount] = x
	pylonsToConnectZ[pylonsToConnectCount] = z
	pylonsToConnectRange[pylonsToConnectCount] = range
	pylonsToConnectBuild[pylonsToConnectCount] = build
end

local function clearPylonsToConnect()
	pylonsToConnectDefID = {}
	pylonsToConnectX = {}
	pylonsToConnectZ = {}
	pylonsToConnectRange = {}
	pylonsToConnectBuild = {}
	pylonsToConnectCount = 0
end

-- Choose the next pylon stepping from (fromX, fromZ) toward the target. It is
-- placed as far along as connectivity allows (fromRange + cmdPylonRange, less a
-- margin). If that ground is unbuildable, nudge it ONLY closer to the previous
-- pylon -- never sideways or past it -- so it always stays within link range.
-- If nothing buildable is found within that budget, return the ideal spot flagged
-- for terraforming. Returns x, z, needsTerraform.
local CONNECT_MARGIN = 16   -- keep neighbours this far inside link range
local STEP_SEARCH = 16      -- granularity of the back-toward-prev search
local MIN_STEP_FRAC = 0.5   -- closest a nudged pylon may sit (fraction of the ideal step)
local MAX_BRIDGE_PYLONS = 64 -- safety cap on pylons laid for a single bridge
local NO_DRAG_DIST = 16     -- a drag shorter than this counts as a plain click
local FOOTPRINT_MARGIN = 8  -- extra spacing kept between our planned footprints
-- Perpendicular shifts to try when the on-axis spot is blocked, so a pylon can be
-- nudged out of alignment to fit past a footprint rather than overlapping it.
local PERP_OFFSETS = {0, 24, -24, 48, -48, 72, -72}

-- Footprint half-extents (elmos) for a structure, facing-aware.
local function footprintHalf(defID, facing)
	local ud = UnitDefs[defID]
	local hx = (ud.xsize or 8) * 4
	local hz = (ud.zsize or 8) * 4
	if facing == 1 or facing == 3 then
		return hz, hx
	end
	return hx, hz
end

-- True if a defID footprint at (x, z) overlaps something already on a build queue
-- (the initial queue pre-game, or ally constructor queues in-game). TestBuildOrder
-- only sees the live world, so this is what catches not-yet-built queued structures.
local function queuedClash(defID, x, z, facing)
	local hx, hz = footprintHalf(defID, facing)
	for i = 1, #queuedBuildings do
		local q = queuedBuildings[i]
		local ohx, ohz = footprintHalf(q.defID, facing)
		if abs(x - q.x) < hx + ohx + FOOTPRINT_MARGIN
			and abs(z - q.z) < hz + ohz + FOOTPRINT_MARGIN then
			return true
		end
	end
	return false
end

-- As queuedClash, but also against structures we've already planned this drag.
local function footprintClash(defID, x, z, facing)
	local hx, hz = footprintHalf(defID, facing)
	for i = 1, pylonsToBuildCount do
		local ohx, ohz = footprintHalf(pylonsToBuildDefID[i], facing)
		if abs(x - pylonsToBuildX[i]) < hx + ohx + FOOTPRINT_MARGIN
			and abs(z - pylonsToBuildZ[i]) < hz + ohz + FOOTPRINT_MARGIN then
			return true
		end
	end
	return queuedClash(defID, x, z, facing)
end

-- Buildable ground AND clear of our other planned/queued footprints.
local function canPlace(defID, x, z, facing)
	return PosBuildable(defID, x, z, facing) and not footprintClash(defID, x, z, facing)
end

local function placeStepPylon(fromX, fromZ, targetX, targetZ, fromRange, facing)
	local dx = targetX - fromX
	local dz = targetZ - fromZ
	local d = sqrt(dx * dx + dz * dz)
	local ux, uz = dx / d, dz / d   -- along the link
	local rx, rz = -uz, ux          -- perpendicular

	local maxStep = fromRange + cmdPylonRange - CONNECT_MARGIN
	if maxStep > d - CONNECT_MARGIN then
		maxStep = d - CONNECT_MARGIN -- don't overshoot the target node
	end
	local minStep = maxStep * MIN_STEP_FRAC
	local linkRange = fromRange + cmdPylonRange
	local linkRangeSq = linkRange * linkRange

	local s = maxStep
	while s >= minStep do
		for o = 1, #PERP_OFFSETS do
			local off = PERP_OFFSETS[o]
			local nx = fromX + ux * s + rx * off
			local nz = fromZ + uz * s + rz * off
			-- stay within link range of the previous node (keeps the chain connected),
			-- then require buildable ground clear of our other planned footprints.
			if DistanceSq(fromX, fromZ, nx, nz) <= linkRangeSq and canPlace(cmdID, nx, nz, facing) then
				return nx, nz, nil
			end
		end
		s = s - STEP_SEARCH
	end

	-- Nothing buildable/clear near the ideal: terraform the on-axis ideal spot. This
	-- fixes sloped ground; it can't clear a blocker, but it's the best fallback.
	local tx, tz = fromX + ux * maxStep, fromZ + uz * maxStep
	return tx, tz, spGetGroundHeight(tx, tz)
end

local function movePylonsFromConnectToBuild()
	-- Add the new (buildable) connect nodes to the build list alongside the anchors.
	-- A mex/geo can't be nudged off its spot, so terraform it if it isn't buildable
	-- as-is (geos submerge when straddling water).
	for i = 1, pylonsToConnectCount do
		local defID = pylonsToConnectDefID[i]
		local x = pylonsToConnectX[i]
		local z = pylonsToConnectZ[i]
		local build = pylonsToConnectBuild[i]
		local terraH
		if build and not PosBuildable(defID, x, z) then
			terraH = terraformTargetHeight(defID, x, z)
		end
		addPylonsToBuild(defID, x, z, pylonsToConnectRange[i], build, terraH)
	end

	local n = pylonsToBuildCount
	if n == 0 then
		return
	end

	-- Union-find over all nodes. Union any two already within link range: this
	-- captures the existing grid's connectivity (and immediate adjacency), so nodes
	-- an existing grid already connects are never relinked.
	local parent = {}
	for i = 1, n do
		parent[i] = i
	end
	local function find(a)
		while parent[a] ~= a do
			parent[a] = parent[parent[a]]
			a = parent[a]
		end
		return a
	end
	for i = 1, n do
		local xi, zi, ri = pylonsToBuildX[i], pylonsToBuildZ[i], pylonsToBuildRange[i]
		for j = i + 1, n do
			local rr = ri + pylonsToBuildRange[j]
			if DistanceSq(xi, zi, pylonsToBuildX[j], pylonsToBuildZ[j]) <= rr * rr then
				parent[find(i)] = find(j)
			end
		end
	end

	-- Bridge the closest disconnected pair repeatedly until everything -- including
	-- separate existing groups -- is one component. Gap uses TerrainDistance so
	-- bridges prefer buildable ground.
	local facing = Spring.GetBuildFacing()
	for _ = 1, n do
		local bestGap, bi, bj
		for i = 1, n do
			local ci = find(i)
			local xi, zi, ri = pylonsToBuildX[i], pylonsToBuildZ[i], pylonsToBuildRange[i]
			for j = i + 1, n do
				if find(j) ~= ci then
					local gap = TerrainDistance(xi, zi, pylonsToBuildX[j], pylonsToBuildZ[j])
						- ri - pylonsToBuildRange[j]
					if not bestGap or gap < bestGap then
						bestGap, bi, bj = gap, i, j
					end
				end
			end
		end
		if not bi then
			break -- all connected
		end

		-- Lay a pylon chain from bi toward bj.
		local lastX, lastZ, lastRange = pylonsToBuildX[bi], pylonsToBuildZ[bi], pylonsToBuildRange[bi]
		local tx, tz, trange = pylonsToBuildX[bj], pylonsToBuildZ[bj], pylonsToBuildRange[bj]
		local steps = 0
		while steps < MAX_BRIDGE_PYLONS do
			local lim = lastRange + trange
			if DistanceSq(lastX, lastZ, tx, tz) <= lim * lim then
				break
			end
			steps = steps + 1
			local px, pz, needTerra = placeStepPylon(lastX, lastZ, tx, tz, lastRange, facing)
			addPylonsToBuild(cmdID, px, pz, cmdPylonRange, true, needTerra)
			lastX, lastZ, lastRange = px, pz, cmdPylonRange
		end
		parent[find(bi)] = find(bj)
	end
end

-- Seed the existing (already-built) ally structures straight into the build list
-- as anchors: build=false so they are never re-ordered or re-drawn, and they never
-- go through the connect/lay-pylons loop (so we don't relink structures that the
-- existing grid already connects). New nodes then connect to the nearest anchor.
local function seedExistingPylons()
	for index = 1, allPylonsCount do
		local x = allPylonsX[index]
		local z = allPylonsZ[index]
		local range = allPylonsRange[index]
		if GetDistanceFromCmd(x, z) - range <= cmdDist + cmdPylonRange then
			addPylonsToBuild(allPylonsDefID[index], x, z, range, false)
		end
	end
end

-- Seed planned-but-not-built structures (queuedBuildings) as anchors too, so the
-- grid connects to what's already queued instead of duplicating it.
local function seedQueuedBuildings()
	for i = 1, #queuedBuildings do
		local q = queuedBuildings[i]
		if GetDistanceFromCmd(q.x, q.z) - q.range <= cmdDist + cmdPylonRange then
			addPylonsToBuild(q.defID, q.x, q.z, q.range, false)
		end
	end
end

-- Co-build grid structures queued by OTHER ally cons: add them as buildable connect
-- nodes so the current selection builds the same sites (Zero-K allows shared build
-- sites) and the grid routes through them. Mex/geo spots are already handled by the
-- metal/geo passes, so only pure energy/pylon structures are taken here -- adding a
-- mex/geo here as well would double-order that spot.
local function seedQueuedByOthers()
	for i = 1, #queuedByOthers do
		local q = queuedByOthers[i]
		if q.defID ~= mexDefID and q.defID ~= geoDefID then
			addPylonsToConnect(q.defID, q.x, q.z, q.range, true)
		end
	end
end

-- Returns enemyHeld, allyHeld for the spot at (x, z), based on a structure of
-- defID (a mex or a geo) sitting on it.
local function spotOwnership(x, z, defID)
	-- Anything already on a build queue overlapping this spot (pre-game initial queue
	-- or in-game ally constructor queues) counts as ours, so we don't build over it.
	if queuedClash(defID, x, z) then
		return false, true
	end
	if pregame then
		return false, false
	end
	local units = spGetUnitsInRectangle(x - 1, z - 1, x + 1, z + 1)
	for i = 1, #units do
		local unitID = units[i]
		if spGetUnitDefID(unitID) == defID then
			if spGetUnitAllyTeam(unitID) == spGetMyAllyTeamID() then
				return false, true
			else
				return true, false
			end
		end
	end
	return false, false
end

-- An LLT clearing an enemy structure can stand anywhere buildable within its
-- weapon range of the spot, so search outward for a buildable spot, biased toward
-- the grid centre (our side). Returns x, z or nil if nothing buildable is in range.
local LLT_MIN_OFFSET = 64      -- keep off the target footprint
local LLT_RANGE_MARGIN = 32    -- stay comfortably inside weapon range
local LLT_RING_STEP = 48
local LLT_ANGLES = 12
local function FindLLTPos(x, z)
	local dx = (cmdCenterX or x) - x
	local dz = (cmdCenterZ or z) - z
	local d = sqrt(dx * dx + dz * dz)
	local baseAng = (d > 1) and atan2(dz, dx) or 0
	local maxRadius = lltRange - LLT_RANGE_MARGIN
	local radius = LLT_MIN_OFFSET
	while radius <= maxRadius do
		for a = 0, LLT_ANGLES - 1 do
			-- fan out symmetrically from the preferred (grid-side) direction
			local step = ceil(a / 2) * (2 * pi / LLT_ANGLES)
			local ang = baseAng + ((a % 2 == 0) and step or -step)
			local nx = x + radius * cos(ang)
			local nz = z + radius * sin(ang)
			if PosBuildable(lltDefID, nx, nz) then
				return nx, nz
			end
		end
		radius = radius + LLT_RING_STEP
	end
	return nil
end

local function addLLTToClear(x, z)
	local lx, lz = FindLLTPos(x, z)
	if lx then
		addExtraBuild(lltDefID, lx, lz)
	end
end

-- Same ownership rules as mex spots: skip allied geos (already grid-connected via
-- the existing-pylon pass), build on empty geos, LLT-clear enemy-held ones.
local function copyPylonsFromFeaturesToConnect()
	local features = Spring.GetAllFeatures()
	for i = 1, #features do
		local fID = features[i]
		if FeatureDefs[Spring.GetFeatureDefID(fID)].geoThermal then
			local x, _, z = Spring.GetFeaturePosition(fID)
			if GetDistanceFromCmd(x, z) - geoRange <= cmdDist + cmdPylonRange then
				local enemyHeld, allyHeld = spotOwnership(x, z, geoDefID)
				-- Ally-held spots are already grid-connected via the existing-pylon pass.
				if not allyHeld and not (enemyHeld and not options.clearEnemyMex.value) then
					if enemyHeld then
						addLLTToClear(x, z) -- clear the enemy geo first
					end
					addPylonsToConnect(geoDefID, x, z, geoRange, true)
				end
			end
		end
	end
end

local function copyPylonsFromMexesToConnect()
	for i = 1, #WG.metalSpots do
		local spot = WG.metalSpots[i]
		local x, z = spot.x, spot.z

		-- Only act on spots within the dragged area (same reach test addPylonsToConnect uses).
		if GetDistanceFromCmd(x, z) - mexRange <= cmdDist + cmdPylonRange then
			local enemyHeld, allyHeld = spotOwnership(x, z, mexDefID)
			-- Ally-held spots are already grid-connected via the existing-pylon pass.
			if not allyHeld and not (enemyHeld and not options.clearEnemyMex.value) then
				if enemyHeld then
					-- Occupied by an enemy: queue an LLT to clear it first.
					addLLTToClear(x, z)
				end
				-- Empty (or soon-to-be-cleared): build our own mex and route the grid to it.
				addPylonsToConnect(mexDefID, x, z, mexRange, true)
			end
		end
	end
end

-- Collect planned-but-not-built grid structures. Pre-game: the initial build queue,
-- all into queuedBuildings. In-game: the selection's own queued buildings go into
-- queuedBuildings (skip-anchors, so a drag doesn't duplicate them on the same con);
-- every other ally con's queued buildings go into queuedByOthers (to co-build). Only
-- structures with a pylon range are kept.
local function gatherQueuedBuildings()
	queuedBuildings = {}
	queuedByOthers = {}

	if pregame then
		local queue = WG.InitialQueueGetQueue and WG.InitialQueueGetQueue()
		if queue then
			for i = 1, #queue do
				local b = queue[i]
				local range = pylonRange[b[1]]
				if range then
					queuedBuildings[#queuedBuildings + 1] = {defID = b[1], x = b[2], z = b[4], range = range}
				end
			end
		end
		return
	end

	-- The command is issued to the current selection; buildings those units already
	-- have queued are skip-anchors (don't duplicate on the same con), while buildings
	-- queued by other ally cons are ones this selection should co-build.
	local selected = {}
	local sel = Spring.GetSelectedUnits()
	for i = 1, #sel do
		selected[sel[i]] = true
	end

	local myAllyTeam = spGetMyAllyTeamID()
	local units = spGetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		if spGetUnitAllyTeam(unitID) == myAllyTeam then
			local ud = UnitDefs[spGetUnitDefID(unitID)]
			if ud and ud.isMobileBuilder then
				local cmds = spGetCommandQueue(unitID, -1)
				if cmds then
					local list = selected[unitID] and queuedBuildings or queuedByOthers
					for c = 1, #cmds do
						local cmd = cmds[c]
						local id = cmd.id
						if id and id < 0 then
							local range = pylonRange[-id]
							if range then
								local p = cmd.params
								list[#list + 1] = {defID = -id, x = p[1], z = p[3], range = range}
							end
						end
					end
				end
			end
		end
	end
end

local function updatePylonsToBuild()
	clearPylonsToConnect()
	clearPylonsToBuild()
	clearExtraBuild()
	groundBadCache = {} -- fresh per recompute: no cross-frame staleness

	local distance = GetMouseDistance()
	if not distance then
		return false
	end

	gatherQueuedBuildings()

	-- No drag: place a single pylon at the clicked spot (terraform if needed), unless
	-- that spot is already on a build queue.
	if cmdDist < NO_DRAG_DIST then
		if not queuedClash(cmdID, cmdCenterX, cmdCenterZ) then
			local terraH
			if not PosBuildable(cmdID, cmdCenterX, cmdCenterZ) then
				terraH = terraformTargetHeight(cmdID, cmdCenterX, cmdCenterZ)
			end
			addPylonsToBuild(cmdID, cmdCenterX, cmdCenterZ, cmdPylonRange, true, terraH)
		end
		return
	end

	seedExistingPylons()
	seedQueuedBuildings()
	seedQueuedByOthers()
	copyPylonsFromFeaturesToConnect()
	copyPylonsFromMexesToConnect()

	movePylonsFromConnectToBuild()
end


------------------------------------------------------------
-- Callins
------------------------------------------------------------

function widget:CommandNotify(cmdID, params, cmdOpts)
	if not WG.metalSpots then
		return false
	end
	return false
end

function widget:GameFrame(n)
	pregame = false
end

------------------------------------------------------------
-- Mouse Callins
------------------------------------------------------------

function widget:MousePress(x, y, button)
	if button ~= 1 or not WG.metalSpots then
		return false
	end
	cmdIndex, cmdID = spGetActiveCommand()

	if not cmdID then
		return false
	end

	cmdID = -cmdID

	if not pylons[cmdID] then
		clearCmd()
		return false
	end
  
	cmdCenterX, cmdCenterZ = GetMousePos()

	if not cmdCenterX then
		clearCmd()
		return false
        end

	cmdPylonRange = pylonRange[cmdID]
	if not cmdPylonRange then
		-- energy_grid unit without a pylonrange: nothing sensible to route.
		clearCmd()
		return false
	end
	cmdDist = 0
	lastPlanDist = 0
	planDirty = true

	-- Drop the engine's active build command. While a building command stays active
	-- and LMB is held, the engine draws (and places) its own line of buildings along
	-- the drag, independent of us consuming the press. We drive placement ourselves
	-- from the cmdID captured above, so clear it to suppress that engine line.
	Spring.SetActiveCommand(nil)

	return true
end

function widget:MouseMove(x, y, dx, dy, button)
	-- Keep cmdDist smooth for the drawn radius and for an accurate reach test when
	-- we recompute, but only flag a recompute once the radius has moved a full step
	-- (the plan only changes when a node crosses in/out of reach). Off the map,
	-- GetMouseDistance is nil -- keep the last radius rather than collapsing to 0.
	local d = GetMouseDistance()
	if d then
		cmdDist = d
		if abs(cmdDist - lastPlanDist) >= options.recomputeStep.value then
			planDirty = true
		end
	end
end

function widget:MouseRelease(x, y, button)
	if cmdID == nil then
		return false
	end
	if button ~= 1 then
		clearCmd()
		return false
	end

	local distance = GetMouseDistance()
	if not distance then
		clearCmd()
		return false
	end

	cmdDist = distance
	updatePylonsToBuild()
	orderPylonsToBuild()

	-- Re-arm the command on shift so the player can drag another grid without
	-- reselecting. It was cleared on press to suppress the engine line-build, so
	-- reselect it here by its saved index; without shift, leave it deselected.
	local _, _, _, shift = spGetModKeyState()
	local reselectIndex = cmdIndex

	clearCmd()

	if shift and reselectIndex then
		Spring.SetActiveCommand(reselectIndex)
		-- Keep the command armed while shift stays down so the player can queue
		-- more grids; deselect it as soon as shift is released (see KeyRelease).
		awaitingShiftRelease = true
	end

	return true
end

function widget:KeyRelease(key)
	if not awaitingShiftRelease then
		return false
	end
	if key ~= KEYSYMS.LSHIFT and key ~= KEYSYMS.RSHIFT then
		return false
	end
	-- Only act once shift is fully released (both shift keys up).
	local _, _, _, shift = spGetModKeyState()
	if shift then
		return false
	end

	awaitingShiftRelease = false

	-- Deselect only if our re-armed pylon command is still the active one, so we
	-- don't clobber a different command the player picked in the meantime.
	local _, activeCmdID = spGetActiveCommand()
	if activeCmdID and pylons[-activeCmdID] then
		Spring.SetActiveCommand(nil)
	end

	return false
end

------------------------------------------------------------
-- Unit Callins
------------------------------------------------------------

local function addUnit(unitID, unitDefID, unitTeam)
	-- Track structures on our ally team (the grid is ally-wide), not just our own.
	if spGetUnitAllyTeam(unitID) ~= spGetMyAllyTeamID() then
		return
	end
	addUnitToAllPylons(unitID, unitDefID)
end

local function removeUnit(unitID, unitDefID)
	removeUnitFromAllPylons(unitID)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)
	removeUnit(unitID, unitDefID)
end

function widget:UnitTaken(unitID, unitDefID, unitTeam, newTeam)
	removeUnit(unitID, unitDefID)
end

function widget:UnitGiven(unitID, unitDefID, newTeam, unitTeam)
	addUnit(unitID, unitDefID, unitTeam)
end

function widget:Initialize()
	rescanUnits()
end

function widget:PlayerChanged(playerID)
        if spGetSpectatingState() then
                widgetHandler:RemoveWidget(widget)
                return
        end
        -- Our team (and thus ally set) may have changed; rebuild the pylon set.
        myTeamID = spGetMyTeamID()
        rescanUnits()
end

------------------------------------------------------------
-- Draw callins
------------------------------------------------------------

function widget:DrawWorld()
	if not cmdID then
		return false
	end

	glPushMatrix()

	gl.DepthTest(true)

	glColor(1,1,0,0.3)
	glLineWidth(4)

	gl.Utilities.DrawGroundCircle(cmdCenterX, cmdCenterZ, cmdDist)

	if planDirty then
		updatePylonsToBuild()
		planDirty = false
		lastPlanDist = cmdDist
	end
	drawPylonsToBuild()

	glPopMatrix()

	glLineWidth(1.0)
	glColor(1,1,1,1)
end
