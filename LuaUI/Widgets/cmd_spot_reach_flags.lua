function widget:GetInfo()
	return {
		name      = "Spot Reach Flags",
		desc      = "Flag mex/geo spots by which constructors can reach them, so area build commands skip them",
		author    = "Amnykon",
		version   = "v1",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 1001, -- Under Chili
		enabled   = true
	}
end

--------------------------------------------------------------------------------
-- API (WG.SpotReach)
--
-- GetBlockedTest(unitIDs) -> function(x, z)
--   Returns a test that is true when the mex/geo spot at (x, z) is flagged as out
--   of reach of every builder in unitIDs (default: the selection; pre-game: the
--   commander). Build the test once per command and reuse it for each spot.
-- SetShown(owner, shown)
--   Keep the flags drawn while an owner (e.g. a widget mid-drag) needs them, on top
--   of the built-in rule: pre-game, while editing or the type menu is open, or while
--   an area mex or grid structure command is active.
-- StartEditing(typeKey)
--   Start flagging spots with a reach type (see REACH_TYPES).
--
-- Every spot is buildable by everything unless the player opts in by flagging it.
-- Flags made pre-game are saved per map; flags made during a game last that game
-- only, since in-game reach changes are usually terraform and won't hold next game.
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")
include("keysym.lua")
VFS.Include("LuaRules/Utilities/glVolumes.lua")

local spGetActiveCommand = Spring.GetActiveCommand
local spGetMouseState    = Spring.GetMouseState
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetUnitDefID     = Spring.GetUnitDefID
local spGetModKeyState   = Spring.GetModKeyState
local spGetGroundHeight  = Spring.GetGroundHeight

local glColor       = gl.Color
local glPushMatrix  = gl.PushMatrix
local glPopMatrix   = gl.PopMatrix
local glTranslate   = gl.Translate

local max  = math.max
local sqrt = math.sqrt
local tan  = math.tan
local pi   = math.pi

local function DistanceSq(x1, z1, x2, z2)
	return (x1 - x2) * (x1 - x2) + (z1 - z2) * (z1 - z2)
end

--------------------------------------------------------------------------------
-- Constructor capabilities and reach types
--------------------------------------------------------------------------------

-- Terrain each constructor can cross, from its movement class (gamedata/movedefs.lua):
-- spiders climb cliffs, amphibious/hover/ship cons cross water, bots take slopes that
-- vehicles and hovers can't. Aircraft have no named moveDef.
local reachCaps = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	if ud.isMobileBuilder then
		local name = ud.moveDef and ud.moveDef.name
		if not name then
			reachCaps[i] = {air = true}
		else
			name = name:lower()
			reachCaps[i] = {
				spider = name:find("tkbot") ~= nil,
				water  = (name:find("akbot") or name:find("^atkbot") or name:find("hover") or name:find("boat")) ~= nil,
				slope  = (name:find("kbot") or name:find("bhover")) ~= nil,
			}
		end
	end
end
-- Pre-game the orders go to the commander, so judge reach by its movement class
-- (all commanders share one, amphibious).
local PREGAME_CAPS = {water = true, slope = true}
for i = 1, #UnitDefs do
	if UnitDefs[i].customParams.dynamic_comm and reachCaps[i] then
		PREGAME_CAPS = reachCaps[i]
		break
	end
end

-- Reach types a spot can be flagged with: which constructors may build there. "all"
-- is the default state of every spot, so choosing it clears a flag; "none" marks
-- spots no constructor should be sent to.
local REACH_TYPES = {
	{key = "none",   name = "None",             icon = "LuaUI/Images/commands/Bold/cancel.png"},
	{key = "air",    name = "Air only",         icon = "icons/air.dds",           allows = {air = true}},
	{key = "water",  name = "Air + water",      icon = "icons/shipgeneric.png",   allows = {air = true, water = true}},
	{key = "spider", name = "Air + spiders",    icon = "icons/spidergeneric.dds", allows = {air = true, spider = true}},
	{key = "slope",  name = "Air + bots",       icon = "icons/kbotgeneric.png",   allows = {air = true, slope = true}},
	{key = "all",    name = "All (clear flag)", icon = "icons/tankgeneric.png"},
}
local reachTypeByKey = {}
for i = 1, #REACH_TYPES do
	reachTypeByKey[REACH_TYPES[i].key] = REACH_TYPES[i]
end

-- Commands whose use should show the flags: area mex and grid structures.
local showForCmd = {}
if CMD_AREA_MEX then
	showForCmd[CMD_AREA_MEX] = true
end
if CMD_AREA_TERRA_MEX then
	showForCmd[CMD_AREA_TERRA_MEX] = true
end
for i = 1, #UnitDefs do
	if UnitDefs[i].customParams.energy_grid then
		showForCmd[-i] = true
	end
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local pregame = (Spring.GetGameFrame() < 1)

-- Flags for this map, each a list of {x, z, t} (t = REACH_TYPES key): this game's
-- in-game edits over the saved pre-game ones. The in-game layer may hold "all" to
-- clear a saved flag for this game.
local sessionSpots = {}
local savedSpots = {}
local LAYERS = {sessionSpots, savedSpots}
-- Saved flags of every map, by map name (widget config).
local savedSpotsByMap = {}

-- Owners that asked for the flags to be drawn (SetShown).
local shownBy = {}

-- Editing: the type being applied (nil when not editing), and the press point and
-- radius of a drag that flags every spot inside it.
local editType
local dragX, dragZ, dragR
local awaitShiftRelease = false -- flagged with shift held; stop editing once shift lifts

local SPOT_MATCH_DIST = 48  -- a flag applies to a site this close to its spot
local SPOT_PICK_DIST = 96   -- a click picks the nearest spot within this distance
local MIN_FLAG_DRAG = 24    -- a drag shorter than this counts as a click

------------------------------------------------------------
-- Config
------------------------------------------------------------

options_path = 'Settings/Interface/Spot Reach Flags'
options_order = { 'editSpots' }
options = {
	editSpots = {
		name = 'Flag unreachable spots',
		type = 'button',
		desc = 'Flag mex/geo spots no constructor should be sent to (None). Pick other types from the Global Commands menu. Click a spot, or drag over several; hold shift to keep editing.',
		-- OnChange set once StartEditing is defined
	},
}

--------------------------------------------------------------------------------
-- Spots and flags
--------------------------------------------------------------------------------

-- Geo vents never move, so scan the (possibly thousands of) map features once.
local geoSpots
local function getGeoSpots()
	if not geoSpots then
		geoSpots = {}
		local features = Spring.GetAllFeatures()
		for i = 1, #features do
			if FeatureDefs[Spring.GetFeatureDefID(features[i])].geoThermal then
				local x, _, z = Spring.GetFeaturePosition(features[i])
				geoSpots[#geoSpots + 1] = {x = x, z = z}
			end
		end
	end
	return geoSpots
end

-- Every mex and geo spot on the map, as {x, z}.
local function allSpots()
	local spots = {}
	local metalSpots = WG.metalSpots or {}
	for i = 1, #metalSpots do
		spots[#spots + 1] = {x = metalSpots[i].x, z = metalSpots[i].z}
	end
	local geos = getGeoSpots()
	for i = 1, #geos do
		spots[#spots + 1] = geos[i]
	end
	return spots
end

-- Nearest mex/geo spot to (x, z) within maxDist, or nil.
local function nearestSpot(x, z, maxDist)
	local spots = allSpots()
	local best, bestD
	for i = 1, #spots do
		local d = DistanceSq(x, z, spots[i].x, spots[i].z)
		if d <= maxDist * maxDist and (not bestD or d < bestD) then
			best, bestD = spots[i], d
		end
	end
	return best
end

-- Index in list of the flag nearest (x, z) within maxDist, or nil.
local function flagAt(list, x, z, maxDist)
	local best, bestD
	for i = 1, #list do
		local d = DistanceSq(x, z, list[i].x, list[i].z)
		if d <= maxDist * maxDist and (not bestD or d < bestD) then
			best, bestD = i, d
		end
	end
	return best
end

-- The reach type of the spot at (x, z) from the layers from firstLayer down, or nil
-- if none flags it.
local function layeredType(x, z, firstLayer)
	for i = firstLayer or 1, #LAYERS do
		local index = flagAt(LAYERS[i], x, z, SPOT_MATCH_DIST)
		if index then
			return LAYERS[i][index].t
		end
	end
end

local function effectiveType(x, z)
	return layeredType(x, z) or "all"
end

-- Flag the spot with typeKey. Pre-game edits are saved; in-game edits last this
-- game only. A flag matching what the layers below already say is dropped.
local function setSpotType(x, z, typeKey)
	local layerIndex = pregame and 2 or 1
	local layer = LAYERS[layerIndex]
	local index = flagAt(layer, x, z, SPOT_MATCH_DIST)
	if index then
		table.remove(layer, index)
	end
	if typeKey ~= (layeredType(x, z, layerIndex + 1) or "all") then
		layer[#layer + 1] = {x = x, z = z, t = typeKey}
	end
end

local function replaceContents(list, newContents)
	for i = #list, 1, -1 do
		list[i] = nil
	end
	for i = 1, #newContents do
		list[i] = newContents[i]
	end
end

--------------------------------------------------------------------------------
-- Blocked test
--------------------------------------------------------------------------------

-- A reach type blocks the builders unless one of them has a capability it allows.
local function typeBlocks(reachType, capsList)
	local allows = reachType.allows
	if not allows then
		return true
	end
	for i = 1, #capsList do
		for cap in pairs(allows) do
			if capsList[i][cap] then
				return false
			end
		end
	end
	return true
end

local function GetBlockedTest(unitIDs)
	local capsList = {}
	if pregame then
		capsList[1] = PREGAME_CAPS
	else
		unitIDs = unitIDs or Spring.GetSelectedUnits()
		for i = 1, #unitIDs do
			local caps = reachCaps[spGetUnitDefID(unitIDs[i])]
			if caps then
				capsList[#capsList + 1] = caps
			end
		end
	end

	local blockedTypes = {}
	for i = 1, #REACH_TYPES do
		local reachType = REACH_TYPES[i]
		if reachType.key ~= "all" and typeBlocks(reachType, capsList) then
			blockedTypes[reachType.key] = true
		end
	end

	return function(x, z)
		return blockedTypes[effectiveType(x, z)] or false
	end
end

--------------------------------------------------------------------------------
-- Editing
--------------------------------------------------------------------------------

local function StopEditing()
	editType = nil
	dragX, dragZ, dragR = nil, nil, nil
	awaitShiftRelease = false
end

local function StartEditing(typeKey)
	if not reachTypeByKey[typeKey] then
		return
	end
	Spring.SetActiveCommand(nil)
	StopEditing()
	editType = typeKey
end
options.editSpots.OnChange = function() StartEditing("none") end

-- Project the cursor ray onto a horizontal plane through the drag origin's height.
-- Used off the map, where TraceScreenRay returns nothing, so a drag keeps growing
-- past the map edge the way engine area commands do. Returns nil until a drag is
-- under way, so an off-map press still can't start one.
local function groundPlaneProject(mouseX, mouseY)
	if not dragX then
		return
	end
	local cvs = Spring.GetCameraVectors()
	local fwd, right, up = cvs and cvs.forward, cvs and cvs.right, cvs and cvs.up
	if not (fwd and right and up) then
		return
	end
	local vsx, vsy, vpx, vpy = Spring.GetViewGeometry()
	if not vsx or vsx == 0 or vsy == 0 then
		return
	end
	local fov = Spring.GetCameraFOV()
	if not fov then
		return
	end
	local t = tan(fov * 0.5 * pi / 180)
	-- mouse coords are window-relative; shift into this view before normalising.
	local sx = (((mouseX - (vpx or 0)) / vsx) * 2 - 1) * (vsx / vsy) * t
	local sy = (((mouseY - (vpy or 0)) / vsy) * 2 - 1) * t
	local dx = fwd[1] + right[1] * sx + up[1] * sy
	local dy = fwd[2] + right[2] * sx + up[2] * sy
	local dz = fwd[3] + right[3] * sx + up[3] * sy
	if dy >= 0 then
		return -- ray isn't heading down toward the ground plane
	end
	local cx, cy, cz = Spring.GetCameraPosition()
	local planeY = max(spGetGroundHeight(dragX, dragZ), 0)
	local dist = (planeY - cy) / dy
	if dist <= 0 then
		return
	end
	return cx + dx * dist, cz + dz * dist
end

local function mousePos()
	local mx, my = spGetMouseState()
	local _, pos = spTraceScreenRay(mx, my, true)
	if pos then
		return pos[1], pos[3]
	end
	-- Off the map: fall back to a ground-plane projection so the drag keeps updating.
	return groundPlaneProject(mx, my)
end

-- After flagging: keep editing while shift is held (until it is released), else
-- stop, like other commands.
local function finishAction()
	local _, _, _, shift = spGetModKeyState()
	if shift then
		awaitShiftRelease = true
	else
		StopEditing()
	end
end

-- A click flags the nearest spot (clicking a spot already flagged with this type
-- clears it); a drag flags every spot inside the circle. Returns whether anything changed.
local function applyFlag()
	if dragR < MIN_FLAG_DRAG then
		local spot = nearestSpot(dragX, dragZ, SPOT_PICK_DIST)
		if not spot then
			return false
		end
		if effectiveType(spot.x, spot.z) == editType then
			setSpotType(spot.x, spot.z, "all")
		else
			setSpotType(spot.x, spot.z, editType)
		end
		return true
	end
	local spots = allSpots()
	local changed = false
	for i = 1, #spots do
		if DistanceSq(dragX, dragZ, spots[i].x, spots[i].z) <= dragR * dragR then
			setSpotType(spots[i].x, spots[i].z, editType)
			changed = true
		end
	end
	return changed
end

------------------------------------------------------------
-- Callins
------------------------------------------------------------

-- Left-press starts a click or drag (resolved on release); right-click stops editing.
function widget:MousePress(x, y, button)
	if not editType then
		return false
	end
	if button == 3 then
		StopEditing()
		return true
	end
	if button ~= 1 then
		return false
	end
	local mx, mz = mousePos()
	if mx then
		dragX, dragZ, dragR = mx, mz, 0
	end
	return true
end

function widget:MouseMove(x, y, dx, dy, button)
	if dragX then
		local mx, mz = mousePos()
		if mx then
			dragR = sqrt(DistanceSq(dragX, dragZ, mx, mz))
		end
	end
end

function widget:MouseRelease(x, y, button)
	if not dragX then
		return false
	end
	-- Missing every spot changes nothing and keeps editing.
	local changed = applyFlag()
	dragX = nil
	if changed then
		finishAction()
	end
	return true
end

function widget:KeyPress(key)
	if editType and key == KEYSYMS.ESCAPE then
		StopEditing()
		return true
	end
	return false
end

function widget:KeyRelease(key)
	if not awaitShiftRelease then
		return false
	end
	if key ~= KEYSYMS.LSHIFT and key ~= KEYSYMS.RSHIFT then
		return false
	end
	-- Only act once shift is fully released (both shift keys up).
	local _, _, _, shift = spGetModKeyState()
	if not shift then
		StopEditing()
	end
	return false
end

function widget:GameFrame(n)
	pregame = false
end

function widget:PlayerChanged(playerID)
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveWidget(widget)
	end
end

function widget:Initialize()
	WG.SpotReach = {
		GetBlockedTest = GetBlockedTest,
		SetShown = function(owner, shown)
			shownBy[owner] = shown or nil
		end,
		StartEditing = StartEditing,
	}

	-- Reach-type menu on the global command bar; picking a type starts flagging spots.
	if WG.GlobalCommandBar and WG.GlobalCommandBar.AddIconMenu then
		local choices = {}
		for i = 1, #REACH_TYPES do
			choices[i] = {file = REACH_TYPES[i].icon, tooltip = REACH_TYPES[i].name}
		end
		WG.GlobalCommandBar.AddIconMenu("LuaUI/Images/commands/Bold/mex.png",
			"Flag mex/geo spots by which constructors can reach them; area mex and energy grid orders skip spots the selected constructors can't. "
			.. "Pick a type, then click a spot or drag over several. All clears flags. Hold shift to keep flagging.",
			choices,
			function(index)
				StartEditing(REACH_TYPES[index].key)
			end,
			function(open)
				shownBy.menu = open or nil
			end)
	end
end

function widget:Shutdown()
	WG.SpotReach = nil
end

function widget:GetConfigData()
	savedSpotsByMap[Game.mapName] = (#savedSpots > 0) and savedSpots or nil
	return {savedSpotsByMap = savedSpotsByMap}
end

function widget:SetConfigData(data)
	savedSpotsByMap = data.savedSpotsByMap or {}
	replaceContents(savedSpots, savedSpotsByMap[Game.mapName] or {})
end

------------------------------------------------------------
-- Drawing
------------------------------------------------------------

-- Flags show pre-game, while editing them or the type menu is open, while an area
-- mex or grid structure command is active, or while another widget asks for them
-- (SetShown).
local function flagsVisible()
	if pregame or editType or next(shownBy) then
		return true
	end
	local _, activeCmdID = spGetActiveCommand()
	return activeCmdID and showForCmd[activeCmdID]
end

local ICON_SIZE = 40
local ICON_HEIGHT = 60 -- above the ground (or water surface)

local function drawSpotIcon(icon, x, z)
	local y = max(spGetGroundHeight(x, z), 0) + ICON_HEIGHT
	gl.Texture(icon)
	glPushMatrix()
	glTranslate(x, y, z)
	gl.Billboard()
	gl.TexRect(-ICON_SIZE, -ICON_SIZE, ICON_SIZE, ICON_SIZE)
	glPopMatrix()
end

function widget:DrawWorld()
	if not flagsVisible() then
		return
	end
	gl.DepthTest(true)

	-- While editing, mark what a release would flag: the spot a click picks, or the
	-- drag circle.
	if editType then
		glColor(1, 1, 1, 0.3)
		if dragX and dragR >= MIN_FLAG_DRAG then
			gl.Utilities.DrawGroundCircle(dragX, dragZ, dragR)
		else
			local x, z = dragX, dragZ
			if not x then
				x, z = mousePos()
			end
			local spot = x and nearestSpot(x, z, SPOT_PICK_DIST)
			if spot then
				gl.Utilities.DrawGroundCircle(spot.x, spot.z, SPOT_MATCH_DIST)
			end
		end
	end

	glColor(1, 1, 1, 1)
	local spots = allSpots()
	for i = 1, #spots do
		local t = effectiveType(spots[i].x, spots[i].z)
		if t ~= "all" then
			drawSpotIcon(reachTypeByKey[t].icon, spots[i].x, spots[i].z)
		end
	end
	gl.Texture(false)
	gl.DepthTest(false)
end
