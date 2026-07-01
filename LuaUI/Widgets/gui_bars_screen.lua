function widget:GetInfo()
	return {
		name    = "Screen Space Bars",
		desc    = "Draws GL4 bars for selected units in screen space (selection panel)",
		author  = "Amnykon",
		date    = "2026",
		license = "GNU GPL v2 or later",
		layer   = 10,
		enabled = true
	}
end

-- Renders GL4 health (and later: reload, count) bars at screen-space positions
-- supplied by WG.SelectionsBarPositions.  That table is populated by
-- gui_chili_selections_and_cursortip.lua when it exposes icon positions.
--
-- Entry format in WG.SelectionsBarPositions:
--   { unitID, barname, screenX, screenY, stackIndex }
-- where screenX/Y is the center of the bar in screen pixels (Y from top).
--
-- The same healthbar GL4 shader is reused, compiled with SCREENSPACE = 1.
-- In SCREENSPACE mode height_timers.xy = screen pixel coords (center of bar).

--------------------------------------------------------------------------------
-- includes
--------------------------------------------------------------------------------

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir .. "LuaShader.lua")
VFS.Include(luaShaderDir .. "instancevbotable.lua")

local includeDir = "LuaUI/Widgets/Include/"
VFS.Include(includeDir .. "gl_uniform_channels.lua")

--------------------------------------------------------------------------------
-- Shader config (pixels, not elmos)
--------------------------------------------------------------------------------

local screenBarConfig = {
	SCREENSPACE       = 1,
	BARSCALE          = 1.0,
	BARWIDTH          = 28,      -- half-width in screen pixels
	BARHEIGHT         = 6,       -- height in screen pixels
	BARCORNER         = 0.6,
	SMALLERCORNER     = 0.36,
	MAXVERTICES       = 64,
	HEIGHTOFFSET      = 0,
	CLIPTOLERANCE     = 1.2,
	BGBOTTOMCOLOR     = "vec4(0.25, 0.25, 0.25, 0.85)",
	BGTOPCOLOR        = "vec4(0.1, 0.1, 0.1, 0.85)",
	BOTTOMDARKENFACTOR = 0.6,
	BARFADESTART      = 9999999, -- never fade in screen space
	BARFADEEND        = 9999999,
	ATLASSTEPY        = 0.03125,
	ATLASSTEPX        = 0.0625,
	MINALPHA          = 0.0,
	PERCENT_VISIBILITY_MAX = 0.99,
	TIMER_VISIBILITY_MIN   = 0.0,
	BARSTEP           = 0,
}

local barTypeMap = {
	health = {
		mincolor     = {1.0, 0.0, 0.0, 1.0},
		maxcolor     = {0.0, 1.0, 0.0, 1.0},
		bartype      = 4 + 128 + 32,  -- bitPercentage + bitColorCorrect + bitInverse
		uniformindex = unitHealthChannel,
		uvoffset     = 18,
	},
}

local vsSrcPath = "LuaUI/Widgets/Shaders/UnitOverlayGL4.vert.glsl"
local gsSrcPath = "LuaUI/Widgets/Shaders/UnitOverlayGL4.geom.glsl"
local fsSrcPath = "LuaUI/Widgets/Shaders/UnitOverlayGL4.frag.glsl"

local shaderSourceCache = {
	vssrcpath  = vsSrcPath,
	fssrcpath  = fsSrcPath,
	gssrcpath  = gsSrcPath,
	shaderName = "Screen Space Bars GL4",
	uniformInt   = { iconAtlasTex = 1 },
	uniformFloat = {
		iconDistance           = 0,
		cameraDistanceMult     = 0,
		cameraDistanceMultGlyph = 0,
		skipGlyphsNumbers      = 2.0, -- bars only
		screenWidth            = 1,
		screenHeight           = 1,
	},
	shaderConfig = screenBarConfig,
}

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local screenBarVBO    = nil
local screenBarShader = nil
local vsx, vsy

local function goodbye(reason)
	Spring.Echo("Screen Space Bars: " .. reason)
	widgetHandler:RemoveWidget()
end

local function initializeVBOTable()
	local t = makeInstanceVBOTable(
		{
			{id = 0, name = 'height_timers',      size = 4},
			{id = 1, name = 'type_index_ssboloc',  size = 4, type = GL.UNSIGNED_INT},
			{id = 2, name = 'startcolor',          size = 4},
			{id = 3, name = 'endcolor',            size = 4},
			{id = 4, name = 'instData',            size = 4, type = GL.UNSIGNED_INT},
		},
		256,
		"screenBarVBO",
		4  -- unitIDattribID
	)
	if not t then goodbye("Failed to create screenBarVBO") end
	local vao = gl.GetVAO()
	vao:AttachVertexBuffer(t.instanceVBO)
	t.VAO = vao
	return t
end

--------------------------------------------------------------------------------
-- VBO update helpers
--------------------------------------------------------------------------------

local cache = {}
for i = 1, 20 do cache[i] = 0 end

local function pushBar(unitID, barname, screenX, screenY, stackIndex)
	local bt = barTypeMap[barname]
	if not bt then return end
	local instanceID = unitID .. "_ss_" .. barname
	cache[1]  = screenX        -- height_timers.x: screen pixel X
	cache[2]  = screenY        -- height_timers.y: screen pixel Y (from top)
	cache[3]  = 1              -- range
	cache[4]  = bt.uvoffset    -- uvOffset

	cache[5]  = bt.bartype     -- bartype_index_ssboloc.x
	cache[6]  = stackIndex or 0 -- stacking index
	cache[7]  = bt.uniformindex -- uniformindex (SSBO channel)
	cache[8]  = 0

	cache[9]  = bt.mincolor[1]; cache[10] = bt.mincolor[2]
	cache[11] = bt.mincolor[3]; cache[12] = bt.mincolor[4]
	cache[13] = bt.maxcolor[1]; cache[14] = bt.maxcolor[2]
	cache[15] = bt.maxcolor[3]; cache[16] = bt.maxcolor[4]

	pushElementInstance(screenBarVBO, cache, instanceID, true, nil, unitID)
end

local function clearBars()
	clearInstanceTable(screenBarVBO)
end

--------------------------------------------------------------------------------
-- Rebuild bars from WG.SelectionsBarPositions
--------------------------------------------------------------------------------

local function rebuildBars()
	clearBars()
	local positions = WG.SelectionsBarPositions
	if not positions then return end
	for i = 1, #positions do
		local entry = positions[i]
		pushBar(entry[1], entry[2], entry[3], entry[4], entry[5] or 0)
	end
end

--------------------------------------------------------------------------------
-- Widget callbacks
--------------------------------------------------------------------------------

function widget:DrawScreen()
	if not screenBarVBO then return end
	local positions = WG.SelectionsBarPositions
	if not positions or #positions == 0 then return end

	-- Rebuild VBO from WG table each frame (positions can shift with Chili layout).
	rebuildBars()
	if screenBarVBO.usedElements == 0 then return end

	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	-- TODO (Phase 4): bar fills now sample the runtime icon atlas (unit 1). That atlas is built by
	-- the world-space widget (gui_unit_overlay_gl4); share it in (e.g. via WG) and bind it here.
	if WG.UnitOverlayIconAtlas then gl.Texture(1, WG.UnitOverlayIconAtlas) end
	screenBarShader:Activate()
	screenBarShader:SetUniform("screenWidth",  vsx)
	screenBarShader:SetUniform("screenHeight", vsy)
	screenBarShader:SetUniform("skipGlyphsNumbers", 2.0)

	screenBarVBO.VAO:DrawArrays(GL.POINTS, screenBarVBO.usedElements)

	screenBarShader:Deactivate()
	gl.Texture(1, false)
	gl.Blending(false)
end

function widget:ViewResize(newVsx, newVsy)
	vsx, vsy = newVsx, newVsy
end

function widget:Initialize()
	vsx, vsy = Spring.GetViewGeometry()

	screenBarShader = LuaShader.CheckShaderUpdates(shaderSourceCache)
	if not screenBarShader then goodbye("Failed to compile screen space bars shader") return end

	screenBarVBO = initializeVBOTable()
	if not screenBarVBO then return end

	WG.SelectionsBarPositions = WG.SelectionsBarPositions or {}
end

function widget:Shutdown()
	if screenBarVBO then
		clearInstanceTable(screenBarVBO)
	end
end
