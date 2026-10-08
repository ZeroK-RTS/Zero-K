---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--
--  file:    reflcull.lua
--  brief:   decides which Lups effects can appear in the BumpWater reflection
--
--  The engine renders the water reflection every frame whenever the map has any water, and
--  Lups used to redraw every main-view visible effect into it. The reflection texture is only
--  read where water is visible on screen, so an effect only matters there if its mirror image
--  (mirrored at the water plane y=0) projects onto, or within the reflection-distortion reach
--  of, a water pixel. This module answers that conservatively:
--
--   * a coarse grid of the map marks cells where the ground dips below (or close to) the water
--     plane, with a summed-area table for O(1) "any water in this rectangle" queries;
--   * per visibility pass, the camera frustum is intersected with the water plane;
--   * per effect, the bounding sphere is mirrored, projected to the screen, grown by the
--     largest distortion/blur offset BumpWater applies when sampling the reflection, clipped
--     to the screen and projected back onto the water plane; the effect is relevant iff that
--     area contains water (or leaves the map, or reaches the horizon).
--
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

local floor = math.floor
local ceil  = math.ceil
local min   = math.min
local max   = math.max
local abs   = math.abs
local tan   = math.tan
local rad   = math.rad
local huge  = math.huge

local spGetGroundHeight   = Spring.GetGroundHeight
local spGetGroundExtremes = Spring.GetGroundExtremes
local spGetCameraPosition = Spring.GetCameraPosition
local spGetCameraVectors  = Spring.GetCameraVectors
local spGetCameraFOV      = Spring.GetCameraFOV
local spGetWaterMode      = Spring.GetWaterMode
local spGetConfigInt      = Spring.GetConfigInt
local glGetWaterRendering = gl.GetWaterRendering

local MAP_X  = Game.mapSizeX
local MAP_Z  = Game.mapSizeZ
local SQUARE = Game.squareSize or 8

local CELL      = 128          -- grid cell size (elmos)
local STEP      = 16           -- height sample spacing (elmos), divides CELL
local SPC       = CELL / STEP  -- samples per cell edge
local WET_BELOW = 32           -- a cell counts as water if any sample is below this height
local SAMPLES_PER_UPDATE = 4096 -- ~0.5 ms of GetGroundHeight calls per Update while scanning
local MAX_SYNC_SAMPLES   = 32768 -- larger height map updates restart the incremental scan

local GW = ceil(MAP_X / CELL)
local GH = ceil(MAP_Z / CELL)
local NX = ceil(MAP_X / STEP)  -- sample columns 0..NX
local NZ = ceil(MAP_Z / STEP)  -- sample rows 0..NZ
local W1 = GW + 1

local BUMPWATER_ID = 4

local MODE_OFF    = 0 -- no culling possible (draw as before)
local MODE_NONE   = 1 -- no water on screen: nothing can be seen in the reflection
local MODE_SCREEN = 2 -- all water-plane area on screen is water: only test the screen rect
local MODE_TEST   = 3 -- full test

local wet     = {} -- [iz*GW + ix] = 1 if the cell may contain visible water, else 0
local sat     = {} -- summed-area table of wet, (GW+1)*(GH+1)
local cellMin = {} -- lowest sampled height per cell
local rowMin  = {}
local buildRow     -- next sample row to scan; nil when the scan is complete
local ready   = false

local mode = MODE_OFF
local camX, camY, camZ
local fX, fY, fZ, rX, rY, rZ, uX, uY, uZ
local tanH, tanV
local dA, dB

---------------------------------------------------------------------------------------------
-- water grid
---------------------------------------------------------------------------------------------

local function BuildSAT()
	for x = 0, GW do
		sat[x] = 0
	end
	for z = 1, GH do
		local rowBase = z*W1
		local prevBase = rowBase - W1
		local wetBase = (z - 1)*GW - 1
		local run = 0
		sat[rowBase] = 0
		for x = 1, GW do
			run = run + wet[wetBase + x]
			sat[rowBase + x] = sat[prevBase + x] + run
		end
	end
end

local function CountWet(ax, bx, az, bz)
	local top = az*W1
	local bot = (bz + 1)*W1
	return sat[bot + bx + 1] - sat[top + bx + 1] - sat[bot + ax] + sat[top + ax]
end

local function ScanRow(j)
	local z = j*STEP
	if z > MAP_Z then z = MAP_Z end
	for ix = 0, GW - 1 do
		rowMin[ix] = huge
	end
	for i = 0, NX do
		local x = i*STEP
		if x > MAP_X then x = MAP_X end
		local h = spGetGroundHeight(x, z)
		local c = floor(i / SPC)
		if c < GW and h < rowMin[c] then
			rowMin[c] = h
		end
		if c > 0 and (i % SPC == 0) and h < rowMin[c - 1] then
			rowMin[c - 1] = h
		end
	end
	local r = floor(j / SPC)
	local r0 = ((j % SPC == 0) and r > 0) and (r - 1) or r
	if r > GH - 1 then r = GH - 1 end
	for cz = r0, r do
		local base = cz*GW
		for ix = 0, GW - 1 do
			local h = rowMin[ix]
			if h < cellMin[base + ix] then
				cellMin[base + ix] = h
			end
		end
	end
end

local function FinishScan()
	for c = 0, GW*GH - 1 do
		wet[c] = (cellMin[c] < WET_BELOW) and 1 or 0
	end
	BuildSAT()
	buildRow = nil
	ready = true
end

local function Init()
	for c = 0, GW*GH - 1 do
		cellMin[c] = huge
		wet[c] = 0
	end
	local initMin, _, currMin = spGetGroundExtremes()
	local lowest = min(initMin or -huge, currMin or -huge)
	if lowest >= WET_BELOW then
		-- No water anywhere; later height map updates that dig below it are merged in.
		FinishScan()
	else
		buildRow = 0
		ready = false
	end
end

-- Scans part of the map; call once per Update until the grid is complete.
local function Step()
	if not buildRow then
		return
	end
	local rows = max(1, floor(SAMPLES_PER_UPDATE / (NX + 1)))
	local last = min(NZ, buildRow + rows - 1)
	for j = buildRow, last do
		ScanRow(j)
	end
	if last >= NZ then
		FinishScan()
	else
		buildRow = last + 1
	end
end

-- x1,z1,x2,z2: height map squares (UnsyncedHeightMapUpdate). Heights only ever lower a cell's
-- recorded minimum, so the grid stays conservative (a cell never turns dry again).
local function HeightMapUpdate(x1, z1, x2, z2)
	if not (x1 and z1 and x2 and z2) then
		return
	end
	local i1 = max(0, floor(x1*SQUARE / STEP))
	local i2 = min(NX, ceil(x2*SQUARE / STEP))
	local j1 = max(0, floor(z1*SQUARE / STEP))
	local j2 = min(NZ, ceil(z2*SQUARE / STEP))
	if i2 < i1 or j2 < j1 then
		return
	end
	if (i2 - i1 + 1)*(j2 - j1 + 1) > MAX_SYNC_SAMPLES then
		-- Big update (e.g. whole map): rescan incrementally, keeping the old minima.
		buildRow = 0
		ready = false
		return
	end
	if ready then
		-- Skip if every touched cell is already water.
		local allWet = true
		local cz1, cz2 = max(0, floor(j1 / SPC) - 1), min(GH - 1, floor(j2 / SPC))
		local cx1, cx2 = max(0, floor(i1 / SPC) - 1), min(GW - 1, floor(i2 / SPC))
		for cz = cz1, cz2 do
			for cx = cx1, cx2 do
				if wet[cz*GW + cx] == 0 then
					allWet = false
					break
				end
			end
			if not allWet then
				break
			end
		end
		if allWet then
			return
		end
	end
	-- Merge every sample (i, j), the height at (min(MAP_X, i*STEP), min(MAP_Z, j*STEP)), into the
	-- cells sharing it: cell floor(i / SPC), and the cell before it when the sample lies on their
	-- border (likewise for rows), clamped to the grid. i and j are integers >= 0, so floor(i / SPC)
	-- is (i - i % SPC) / SPC exactly; the rows are computed once per sample row.
	for j = j1, j2 do
		local z = j*STEP
		if z > MAP_Z then z = MAP_Z end
		local jr = j % SPC
		local cz = (j - jr) / SPC
		local cz0 = ((jr == 0) and cz > 0) and (cz - 1) or cz
		if cz > GH - 1 then cz = GH - 1 end
		for i = i1, i2 do
			local x = i*STEP
			if x > MAP_X then x = MAP_X end
			local h = spGetGroundHeight(x, z)
			local ir = i % SPC
			local cx = (i - ir) / SPC
			local cx0 = ((ir == 0) and cx > 0) and (cx - 1) or cx
			if cx > GW - 1 then cx = GW - 1 end
			for zz = cz0, cz do
				local base = zz*GW
				for xx = cx0, cx do
					local c = base + xx
					if h < cellMin[c] then
						cellMin[c] = h
					end
				end
			end
		end
	end
	if ready then
		local changed = false
		local cz1, cz2 = max(0, floor(j1 / SPC) - 1), min(GH - 1, floor(j2 / SPC))
		local cx1, cx2 = max(0, floor(i1 / SPC) - 1), min(GW - 1, floor(i2 / SPC))
		for cz = cz1, cz2 do
			for cx = cx1, cx2 do
				local c = cz*GW + cx
				if wet[c] == 0 and cellMin[c] < WET_BELOW then
					wet[c] = 1
					changed = true
				end
			end
		end
		if changed then
			BuildSAT()
		end
	end
end

-- The height map changed while updates were not being tracked: rescan (old minima are kept,
-- so the result stays conservative).
local function Invalidate()
	buildRow = 0
	ready = false
end

---------------------------------------------------------------------------------------------
-- camera / screen geometry
---------------------------------------------------------------------------------------------

-- Bounding box (on the water plane) of everything seen through the NDC rectangle; nil if a
-- corner ray does not point downwards. The main-camera ray through NDC (a, b) meets the water
-- plane at
--   ah, bv = a*tanH, b*tanV;  dy = fY + ah*rY + bv*uY  (nil if dy > -1e-4);  t = -camY / dy
--   x, z = camX + t*(fX + ah*rX + bv*uX), camZ + t*(fZ + ah*rZ + bv*uZ)
-- Computed for the corners (a1,b1), (a2,b1), (a1,b2), (a2,b2) in that order, sharing the
-- products (every sum is evaluated as written above, so the results are the same as computing
-- each corner on its own), with math.min/max replaced by the same comparisons.
local function RectFootprint(a1, a2, b1, b2)
	local ah1, ah2, bv1, bv2 = a1*tanH, a2*tanH, b1*tanV, b2*tanV
	local h1y, h2y, v1y, v2y = ah1*rY, ah2*rY, bv1*uY, bv2*uY
	local dy1 = fY + h1y + v1y
	if dy1 > -1e-4 then
		return nil
	end
	local dy2 = fY + h2y + v1y
	if dy2 > -1e-4 then
		return nil
	end
	local dy3 = fY + h1y + v2y
	if dy3 > -1e-4 then
		return nil
	end
	local dy4 = fY + h2y + v2y
	if dy4 > -1e-4 then
		return nil
	end
	local h1x, h2x, v1x, v2x = ah1*rX, ah2*rX, bv1*uX, bv2*uX
	local h1z, h2z, v1z, v2z = ah1*rZ, ah2*rZ, bv1*uZ, bv2*uZ
	local t = -camY / dy1
	local x1, z1 = camX + t*(fX + h1x + v1x), camZ + t*(fZ + h1z + v1z)
	t = -camY / dy2
	local x2, z2 = camX + t*(fX + h2x + v1x), camZ + t*(fZ + h2z + v1z)
	t = -camY / dy3
	local x3, z3 = camX + t*(fX + h1x + v2x), camZ + t*(fZ + h1z + v2z)
	t = -camY / dy4
	local x4, z4 = camX + t*(fX + h2x + v2x), camZ + t*(fZ + h2z + v2z)
	local minx, maxx, minz, maxz = x1, x1, z1, z1
	if x2 < minx then minx = x2 end
	if x3 < minx then minx = x3 end
	if x4 < minx then minx = x4 end
	if x2 > maxx then maxx = x2 end
	if x3 > maxx then maxx = x3 end
	if x4 > maxx then maxx = x4 end
	if z2 < minz then minz = z2 end
	if z3 < minz then minz = z3 end
	if z4 < minz then minz = z4 end
	if z2 > maxz then maxz = z2 end
	if z3 > maxz then maxz = z3 end
	if z4 > maxz then maxz = z4 end
	return minx, maxx, minz, maxz
end

-- Number of water cells and of all cells under a bounding box; nil if it leaves the map
-- (the water plane continues there, treat it as water).
local function WetInBox(minx, maxx, minz, maxz)
	if minx < 0 or minz < 0 or maxx > MAP_X or maxz > MAP_Z then
		return nil
	end
	local ax, bx = floor(minx / CELL), floor(maxx / CELL)
	local az, bz = floor(minz / CELL), floor(maxz / CELL)
	if bx > GW - 1 then bx = GW - 1 end
	if bz > GH - 1 then bz = GH - 1 end
	return CountWet(ax, bx, az, bz), (bx - ax + 1)*(bz - az + 1)
end

-- Call once per visibility pass, from the main camera (not during a draw pass).
local function BeginPass(viewSizeY)
	mode = MODE_OFF
	if not ready then
		return mode
	end
	local waterID = spGetWaterMode()
	if waterID ~= BUMPWATER_ID then
		return mode -- other water renderers sample the reflection differently
	end
	camX, camY, camZ = spGetCameraPosition()
	if not camY or camY < 50 then
		return mode
	end
	local v = spGetCameraVectors()
	local f, r, u = v and v.forward, v and v.right, v and v.up
	if not (f and r and u) then
		return mode
	end
	fX, fY, fZ = f[1], f[2], f[3]
	rX, rY, rZ = r[1], r[2], r[3]
	uX, uY, uZ = u[1], u[2], u[3]
	local vfov, hfov = spGetCameraFOV()
	if not (vfov and hfov) then
		return mode
	end
	tanV, tanH = tan(rad(vfov*0.5)), tan(rad(hfov*0.5))
	if not (tanV > 0 and tanH > 0) then
		return mode
	end

	-- Largest offset (UV) between a water pixel and the reflection texel it reads: the normal
	-- map perturbation (|normal.xz| <= 1), the fixed 3 pixel shift, the blur taps and texture
	-- filtering; with a safety factor.
	local k  = abs(glGetWaterRendering("reflectionDistortion") or 1)
	local bb = abs(glGetWaterRendering("blurBase") or 2)
	local be = max(1, abs(glGetWaterRendering("blurExponent") or 1.5))
	local texSize = max(32, spGetConfigInt("BumpWaterTexSizeReflection", 512) or 512)
	local vsy = max(1, viewSizeY or 1)
	local du = 1.25*(0.09*k) + 2/texSize + 0.01
	local dv = 1.25*(0.09*k + (3 + bb*be^6)/vsy) + 2/texSize + 0.01
	dA, dB = 2*du, 2*dv

	local minx, maxx, minz, maxz = RectFootprint(-1, 1, -1, 1)
	if not minx then
		mode = MODE_TEST -- horizon on screen
		return mode
	end
	local n, total = WetInBox(minx, maxx, minz, maxz)
	if not n then
		mode = MODE_TEST
	elseif n == 0 then
		mode = MODE_NONE
	elseif n == total then
		mode = MODE_SCREEN
	else
		mode = MODE_TEST
	end
	return mode
end

-- Can a sphere at (x,y,z) with radius R show up in the reflection? Valid after BeginPass
-- returned MODE_SCREEN or MODE_TEST.
local function SphereRelevant(x, y, z, R)
	local dx, dy, dz = x - camX, -y - camY, z - camZ -- mirrored centre
	local zc = dx*fX + dy*fY + dz*fZ
	if zc < -R then
		return false -- behind the camera
	end
	if zc <= R + 1 then
		return true
	end
	local xr = dx*rX + dy*rY + dz*rZ
	local yu = dx*uX + dy*uY + dz*uZ
	local q = R / (zc*(zc - R))
	local a0 = xr / (zc*tanH)
	-- (x < 0 and -x or x) instead of math.abs(x): no C call; zc > 1 here, so the sign of a zero
	-- does not matter
	local ea = q*(zc + (xr < 0 and -xr or xr)) / tanH + dA
	local a1, a2 = a0 - ea, a0 + ea
	if a1 > 1 or a2 < -1 then
		return false
	end
	local b0 = yu / (zc*tanV)
	local eb = q*(zc + (yu < 0 and -yu or yu)) / tanV + dB
	local b1, b2 = b0 - eb, b0 + eb
	if b1 > 1 or b2 < -1 then
		return false
	end
	if mode ~= MODE_TEST then
		return true
	end
	if a1 < -1 then a1 = -1 end
	if a2 > 1 then a2 = 1 end
	if b1 < -1 then b1 = -1 end
	if b2 > 1 then b2 = 1 end
	local minx, maxx, minz, maxz = RectFootprint(a1, a2, b1, b2)
	if not minx then
		return true
	end
	local n = WetInBox(minx, maxx, minz, maxz)
	return (n == nil) or (n > 0)
end

return {
	MODE_OFF    = MODE_OFF,
	MODE_NONE   = MODE_NONE,
	MODE_SCREEN = MODE_SCREEN,
	MODE_TEST   = MODE_TEST,
	Init            = Init,
	Step            = Step,
	HeightMapUpdate = HeightMapUpdate,
	Invalidate      = Invalidate,
	BeginPass       = BeginPass,
	SphereRelevant  = SphereRelevant,
}
