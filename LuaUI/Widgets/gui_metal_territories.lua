function widget:GetInfo()
	return {
		name      = "Metal Territories",
		desc      = "Shows metal spot territories and their last seen owners",
		author    = "OpenAI Codex, requested by Sparkezel",
		date      = "2026-10-23",
		license   = "GNU GPL, v2 or later",
		layer     = -10, -- below the selection circles (-9), outlines and range overlays, which draw on top
		enabled   = false,
	}
end

local paletteDirty, closeDirty, updateFrame = true, true, nil
local function RepaintPalette()
	paletteDirty = true
end
local function RebuildClose()
	closeDirty = true
end
local function UpdateNow()
	updateFrame = nil
end

options_path = 'Settings/Graphics/Map/Metal Territories'
-- Headings are labels; a radio button's name is one too.
options_order = {'opacity', 'allyOpacity', 'enemyOpacity', 'neutralOpacity', 'reach', 'reachBorder', 'borders', 'borderWidth', 'borderGap',
	'hatchingHeading', 'hatching', 'hatchWidth', 'hatchSpacing', 'hatchAngle', 'hatchFade', 'tintHeading', 'tint', 'tintOpacity', 'tintFade',
	'minimapHeading', 'minimap', 'minimapBorderWidth', 'minimapTintOpacity', 'minimapTintFade', 'minimapNeutral',
	'minimapNeutralOpacity', 'allies', 'allyColor', 'enemies', 'enemyColor',
	'neutralHeading', 'neutralColor', 'additionalHeading', 'smoothFades', 'brightGround', 'merge', 'mergeDistance',
	'zoomFade', 'zoomFadeOpacity', 'zoomFadeNear', 'zoomFadeFar'}
options = {
	opacity = {
		name = 'Opacity',
		type = 'number',
		value = 0.25,
		min = 0,
		max = 0.8,
		step = 0.01,
	},
	allyOpacity = {
		name = 'Allied territory opacity',
		desc = 'A fraction of Opacity: at 0.6 allied territories are drawn at 60% of it. 0 hides them.',
		type = 'number',
		value = 1,
		min = 0,
		max = 1,
		step = 0.05,
		OnChange = RepaintPalette,
	},
	enemyOpacity = {
		name = 'Enemy territory opacity',
		desc = 'A fraction of Opacity: at 0.6 enemy territories are drawn at 60% of it. 0 hides them.',
		type = 'number',
		value = 1,
		min = 0,
		max = 1,
		step = 0.05,
		OnChange = RepaintPalette,
	},
	neutralOpacity = {
		name = 'Neutral territory opacity',
		desc = 'Territories with no known mex. A fraction of Opacity: at 0.6 they are drawn at 60% of it. 0 hides them.',
		type = 'number',
		value = 1,
		min = 0,
		max = 1,
		step = 0.05,
		OnChange = RepaintPalette,
	},
	borders = {
		name = 'Borders',
		type = 'radioButton',
		value = 'owners',
		items = {
			{key = 'off', name = 'Off'},
			{key = 'all', name = 'Every territory'},
			{key = 'owners', name = 'Between different owners'},
		},
		noHotkey = true,
	},
	borderWidth = {
		name = 'Border width',
		desc = 'In elmos. The line around each mex has the same width.',
		type = 'number',
		value = 12,
		min = 4,
		max = 64,
		step = 1,
	},
	borderGap = {
		name = 'Border gap',
		desc = 'In elmos, between the border and the edge of its territory. At 0 the borders of neighbouring territories touch.',
		type = 'number',
		value = 4,
		min = 0,
		max = 32,
		step = 1,
	},
	merge = {
		name = 'Merge close metal spots',
		desc = 'Spots within Merge distance of each other share one territory while they have the same owner, or no known mex. A spot taken by another owner has its own territory again. With borders between different owners it changes nothing: territories with the same owner are joined anyway.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = RebuildClose,
	},
	mergeDistance = {
		name = 'Merge distance',
		desc = 'In elmos between the metal spots.',
		type = 'number',
		value = 128,
		min = 64,
		max = 512,
		step = 16,
		OnChange = RebuildClose,
	},
	reach = {
		name = 'Territory reach',
		desc = 'In elmos. Farther than this from the metal spots, territories fade out over 256 elmos, or end with Border at territory reach, so they do not cover parts of the map with no metal.',
		type = 'number',
		value = 2048,
		min = 512,
		max = 8192,
		step = 64,
	},
	reachBorder = {
		name = 'Border at territory reach',
		desc = 'End territories at Territory reach instead of fading them out beyond it. With Borders on, a border is drawn there as between territories.',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	hatchingHeading = {
		name = 'Hatching',
		type = 'label',
	},
	hatching = {
		name = 'Show hatching',
		desc = 'Hatching beside borders and around mexes.',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	hatchWidth = {
		name = 'Hatching line width',
		desc = 'In elmos.',
		type = 'number',
		value = 9,
		min = 2,
		max = 32,
		step = 1,
	},
	hatchSpacing = {
		name = 'Hatching spacing',
		desc = 'In elmos between the hatching lines.',
		type = 'number',
		value = 22,
		min = 16,
		max = 128,
		step = 1,
	},
	hatchAngle = {
		name = 'Hatching angle',
		desc = 'In degrees from horizontal, with north up: 45 rises to the right, 90 is vertical, 135 falls to the right.',
		type = 'number',
		value = 45,
		min = 0,
		max = 180,
		step = 1,
	},
	hatchFade = {
		name = 'Hatching fade rate',
		desc = 'At 1 the hatching beside borders and mexes fades out over 240 elmos, at 2 over 120. At 0 it does not fade.',
		type = 'number',
		value = 1.7,
		min = 0,
		max = 4,
		step = 0.05,
	},
	tintHeading = {
		name = 'Tint',
		type = 'label',
	},
	tint = {
		name = 'Show tint',
		desc = 'Tint territories, strongest beside their borders and around mexes.',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	tintOpacity = {
		name = 'Tint opacity',
		desc = 'At 1 the tint beside the border is 45% of Opacity, at 2 it is 90%. 0 hides the tint.',
		type = 'number',
		value = 1,
		min = 0,
		max = 2,
		step = 0.05,
	},
	tintFade = {
		name = 'Tint fade rate',
		desc = 'At 1 the tint fades out over 600 elmos from the border and the line around each mex, at 2 over 300. At 0 it does not fade.',
		type = 'number',
		value = 2,
		min = 0,
		max = 4,
		step = 0.05,
	},
	smoothFades = {
		name = 'Smooth fades (higher quality)',
		desc = 'Fade the hatching and tint from the nearest border even several territories away, with a distance map updated on the GPU. Without it, with borders between different owners or merged territories, a fade can end at a hard edge.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = UpdateNow,
	},
	brightGround = {
		name = 'Bright ground compensation',
		desc = 'Where the lit ground is bright, as on the minimap, territories are drawn darker and more opaque, so they stay visible on light maps. Dark ground is unchanged. 0 turns it off.',
		type = 'number',
		value = 0.5,
		min = 0,
		max = 1,
		step = 0.05,
	},
	minimapHeading = {
		name = 'Minimap',
		type = 'label',
	},
	minimap = {
		name = 'Show on minimap',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	minimapBorderWidth = {
		name = 'Minimap border width',
		desc = 'In pixels.',
		type = 'number',
		value = 2,
		min = 1,
		max = 8,
		step = 0.5,
	},
	minimapTintOpacity = {
		name = 'Minimap tint opacity',
		desc = 'Tint opacity for the minimap.',
		type = 'number',
		value = 1.5,
		min = 0,
		max = 3,
		step = 0.05,
	},
	minimapTintFade = {
		name = 'Minimap tint fade',
		desc = 'Fade the minimap tint as set by Tint fade rate. Off, the minimap tint is even.',
		type = 'bool',
		value = false,
		noHotkey = true,
	},
	minimapNeutral = {
		name = 'Minimap neutral territories',
		desc = 'Show territories with no known mex on the minimap.',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = RepaintPalette,
	},
	minimapNeutralOpacity = {
		name = 'Minimap neutral opacity',
		desc = 'Neutral territories on the minimap, as a fraction of Opacity: at 0.6 they are drawn at 60% of it.',
		type = 'number',
		value = 1,
		min = 0,
		max = 1,
		step = 0.05,
		OnChange = RepaintPalette,
	},
	allies = {
		name = 'Allied territories',
		type = 'radioButton',
		value = 'you',
		items = {
			{key = 'you', name = 'Your colour', desc = "Allies share mex income, so their territories have your colour. Spectators see the colour of the team they spectate."},
			{key = 'players', name = "Each player's colour"},
			{key = 'custom', name = 'Custom', desc = 'The colour below.'},
		},
		noHotkey = true,
		OnChange = RepaintPalette,
	},
	allyColor = {
		name = 'Custom allied colour',
		type = 'colors',
		value = {1, 1, 1, 1},
		OnChange = RepaintPalette,
	},
	enemies = {
		name = 'Enemy territories',
		type = 'radioButton',
		value = 'team',
		items = {
			{key = 'team', name = 'Team colour', desc = 'Each enemy team has the colour of its first player.'},
			{key = 'custom', name = 'Custom', desc = 'The colour below.'},
		},
		noHotkey = true,
		OnChange = RepaintPalette,
	},
	enemyColor = {
		name = 'Custom enemy colour',
		type = 'colors',
		value = {0, 0, 0, 1},
		OnChange = RepaintPalette,
	},
	neutralHeading = {
		name = 'Neutral territories',
		type = 'label',
	},
	neutralColor = {
		name = 'Neutral colour',
		desc = 'Territories with no known mex.',
		type = 'colors',
		value = {0.55, 0.55, 0.55, 1},
		OnChange = RepaintPalette,
	},
	additionalHeading = {
		name = 'Additional options',
		type = 'label',
	},
	zoomFade = {
		name = 'Fade out while zoomed',
		desc = 'Zoomed in, territories fade out to Zoomed in opacity. Zooming out brings them back, to full opacity at Upper zoom limit. The minimap does not fade.',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	zoomFadeOpacity = {
		name = 'Zoomed in opacity',
		desc = 'In % of Opacity, at Lower zoom limit and closer.',
		type = 'number',
		value = 20,
		min = 0,
		max = 100,
		step = 1,
	},
	zoomFadeNear = {
		name = 'Lower zoom limit',
		desc = 'The camera distance in elmos to the ground at the centre of the screen. At this distance or closer, territories are drawn at Zoomed in opacity.',
		type = 'number',
		value = 1000,
		min = 200,
		max = 8000,
		step = 100,
	},
	zoomFadeFar = {
		name = 'Upper zoom limit',
		desc = 'At this camera distance or farther, territories are drawn at full opacity. Between the two limits the opacity changes evenly.',
		type = 'number',
		value = 3000,
		min = 200,
		max = 8000,
		step = 100,
	},
}

local min, max = math.min, math.max
local spots, cells, spotSource
local byPosition, unitSpot, watched, observations, dirty = {}, {}, {}, {}, {}
local myAllyTeam, fullView
local atlas, edges, positions, observed, history, nextHistory, palette, depth
local close, index, groups, nextGroups, seeds, nextSeeds, field, shownGroups
local mergePasses, fieldOn, updateMode = 0, false, nil
local paintShader, cellShader, stateShader, drawShader, minimapShader, groupShader, seedShader, jumpShader, fieldShader, quad
local stateFullView, drawOpacity, drawBorders, drawInverse, drawView, minimapOpacity, minimapBorders
local drawBorder, drawRing, drawTint, drawStripes, drawHatching, drawField, drawReach, minimapTint, minimapLine, minimapField, minimapReach
local seedBorders, jumpStep, drawGround, minimapGround, drawReachBorder, minimapReachBorder
local viewX, viewY, viewW, viewH
local depthFBO
local borderModes = {off = 0, all = 1, owners = 2}
local mexDefs = {}
for id, ud in pairs(UnitDefs) do
	if ud.customParams and ud.customParams.ismex then
		mexDefs[id] = true
	end
end

-- The static atlas has at most 2048 texels on its longest side.
local atlasScale = min(1/4, 2048/max(Game.mapSizeX, Game.mapSizeZ))
local atlasX, atlasZ = max(1, math.ceil(Game.mapSizeX*atlasScale)), max(1, math.ceil(Game.mapSizeZ*atlasScale))
local texelX, texelZ = Game.mapSizeX/atlasX, Game.mapSizeZ/atlasZ
-- The distance map has about 32 elmos a texel, at most 512 on its longest
-- side. Jump flooding steps halve from half its size, then one more of 1. It
-- and the merged territories are updated every updateInterval game frames,
-- and when a setting changes.
local fieldScale = min(1/32, 512/max(Game.mapSizeX, Game.mapSizeZ))
local fieldX, fieldZ = max(1, math.ceil(Game.mapSizeX*fieldScale)), max(1, math.ceil(Game.mapSizeZ*fieldScale))
local jumps = {}
do
	local step = 1
	while 2*step < max(fieldX, fieldZ) do step = 2*step end
	while step >= 1 do
		jumps[#jumps + 1] = step
		step = step/2
	end
	jumps[#jumps + 1] = 1
end
local updateInterval = 15
-- A line like the border 16 elmos out from the mex (48 elmos wide), hatching
-- beside each line that fades out over hatchFade elmos, and a tint everywhere
-- else: tint[1] beside each line, fading to tint[2] over tintFade elmos from
-- it. The fade rate options divide these distances.
local ringRadius, hatchFade, tint, tintFade = 24 + 16, 240, {0.45, 0}, 600
-- Beyond the reach from the metal spots, territories fade out over reachFade elmos.
local reachFade = 256

-- Points p with nx*p.x + nz*p.z <= limit have a lower power distance to a than to b.
local function Bisector(a, b)
	return 2*(b.x - a.x), 2*(b.z - a.z), b.x*b.x + b.z*b.z - b.weight - a.x*a.x - a.z*a.z + a.weight
end

-- Power distance = squared distance - weight. A shared scale keeps equal
-- yields equally weighted. The clamp bounds the weight difference below
-- the squared distance between any two sites, so no site loses its cell.
local function BuildCells(source, width, height)
	local sites, nearest = {}, width*width + height*height
	local used = {}
	for i = 1, #source do
		local s = source[i]
		-- Duplicate sites have one cell; keep the first entry.
		used[s.x] = used[s.x] or {}
		if not used[s.x][s.z] then
			used[s.x][s.z] = true
			sites[#sites + 1] = {x = s.x, z = s.z, metal = s.metal}
		end
	end
	for i = 1, #sites do
		for j = i + 1, #sites do
			local dx, dz = sites[i].x - sites[j].x, sites[i].z - sites[j].z
			nearest = min(nearest, dx*dx + dz*dz)
		end
	end
	for i = 1, #sites do
		sites[i].weight = 0.25*nearest*max(0.5, min(2.5, (sites[i].metal or 2)/2))
	end
	local result, lines = {}, {}
	for i = 1, #sites do
		local a = sites[i]
		-- Each vertex keeps the neighbour across its following edge; nil is the map edge.
		local polygon = {{0, 0}, {width, 0}, {width, height}, {0, height}}
		for j = 1, #sites do
			if i ~= j then
				local nx, nz, limit = Bisector(a, sites[j])
				local clipped = {}
				local p = polygon[#polygon]
				for k = 1, #polygon do
					local q = polygon[k]
					local dp = nx*p[1] + nz*p[2] - limit
					local dq = nx*q[1] + nz*q[2] - limit
					if (dp <= 0) ~= (dq <= 0) then
						local t = dp/(dp - dq)
						clipped[#clipped + 1] = {p[1] + t*(q[1] - p[1]), p[2] + t*(q[2] - p[2]), dq > 0 and j or p[3]}
					end
					if dq <= 0 then
						clipped[#clipped + 1] = q
					end
					p = q
				end
				polygon = clipped
			end
		end
		-- Neighbour edges as two texels: the unit inward normal (distance =
		-- ux*x + uz*z + w) and neighbour, then the extent along (-uz, ux).
		-- An end on the map edge stays open, so borders run into the map edge.
		local list, listed = {}, {}
		for k, v in ipairs(polygon) do
			local j = v[3]
			if j and not listed[j] then
				listed[j] = true
				local nx, nz, limit = Bisector(a, sites[j])
				local length = math.sqrt(nx*nx + nz*nz)
				local ux, uz = -nx/length, -nz/length
				local q = polygon[k%#polygon + 1]
				local from, to = ux*v[2] - uz*v[1], ux*q[2] - uz*q[1]
				local open = to > from and 1e6 or -1e6
				if not polygon[(k - 2)%#polygon + 1][3] then from = from - open end
				if not q[3] then to = to + open end
				list[#list + 1] = {ux, uz, limit/length, j - 1}
				list[#list + 1] = {min(from, to), max(from, to), 0, 0}
			end
		end
		result[i], lines[i] = polygon, list
	end
	return sites, result, lines
end

-- The shaders are in LuaUI/Widgets/Shaders. A line ###NAME### in a shader file
-- is replaced by the shared code of shaderParts[NAME], which can name more.
local shaderDir = 'LuaUI/Widgets/Shaders/'
local shaderParts = {
	EDGE_DISTANCE = 'metal_territories_edge.glsl',
	SHOWN = 'metal_territories_shown.glsl',
	TERRITORY = 'metal_territories_territory.glsl',
	GROUND = 'metal_territories_ground.glsl',
}
local function LoadShader(file)
	local source = VFS.LoadFile(shaderDir .. file)
	return (source:gsub('###([%u_]+)###', function(name) return LoadShader(shaderParts[name]) end))
end

local function NewTexture(width, height, format)
	return assert(gl.CreateTexture(width, height, {
		format = format or GL.RGBA32F,
		min_filter = GL.NEAREST,
		mag_filter = GL.NEAREST,
		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
		fbo = format == nil,
	}), 'Metal Territories: texture allocation failed')
end

local function ClearTexture(texture)
	gl.RenderToTexture(texture, function() gl.Clear(GL.COLOR_BUFFER_BIT, 0, 0, 0, 0) end)
end

local function PaintRows(texture, rows, width)
	gl.UseShader(paintShader)
	gl.RenderToTexture(texture, function()
		gl.BeginEnd(GL.POINTS, function()
			for y, values in pairs(rows) do
				for i, value in pairs(values) do
					gl.Color(value)
					gl.Vertex(2*(i - 0.5)/width - 1, 2*(y - 0.5)/#rows - 1, 0)
				end
			end
		end)
	end)
	gl.UseShader(0)
end

local function PaintRow(texture, values, width)
	PaintRows(texture, {values}, width)
end

local function SetObservation(i, owner, present, learn)
	local old = observations[i]
	if old[1] == owner and old[2] == present and not learn then
		return
	end
	observations[i] = {owner, present, old[3] + (learn and 1 or 0), 0}
	dirty[i] = observations[i]
end

local function ObserveUnit(unitID, unitDefID, teamID)
	if not spots or not mexDefs[unitDefID] then
		return
	end
	local allied = Spring.IsUnitAllied(unitID)
	local los = Spring.GetUnitLosState(unitID, myAllyTeam)
	if not fullView and not allied and not (los and los.los) then
		return
	end
	local x, _, z = Spring.GetUnitPosition(unitID)
	local i = x and byPosition[x] and byPosition[x][z]
	if not i then
		return
	end
	-- Only a finished mex owns its spot, so a spot in sight with a nanoframe shows
	-- as empty. UnitFinished and UnitReverseBuilt report allied mexes (all in full
	-- view); GameFrame watches whether enemy mexes in sight are finished.
	local finished = not Spring.GetUnitIsBeingBuilt(unitID)
	if fullView or allied then
		watched[unitID] = nil
	else
		watched[unitID] = finished
	end
	if finished then
		unitSpot[unitID] = i
		SetObservation(i, teamID + 1, 1, true)
	elseif unitSpot[unitID] then
		-- Reclaimed back into a nanoframe in sight.
		unitSpot[unitID] = nil
		SetObservation(i, 0, 0, true)
	end
end

local function ResetView()
	myAllyTeam = Spring.GetMyAllyTeamID()
	local spectating
	spectating, fullView = Spring.GetSpectatingState()
	fullView = spectating and fullView
	unitSpot, watched, observations, dirty = {}, {}, {}, {}
	for i = 1, #spots do
		observations[i] = {0, 0, 0, 0}
		dirty[i] = observations[i]
	end
	ClearTexture(history)
	ClearTexture(nextHistory)
	-- GetAllUnits is filtered by the LuaUI read allyteam. Radar contacts are
	-- rejected by ObserveUnit. Reset on perspective changes to discard secrets.
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		ObserveUnit(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
	end
	paletteDirty = true
end

-- The palette has a column for each owner value of the owners texture: 0 is
-- neutral (no known mex) and team t is t + 1. Lua tables start at 1, so column
-- c is entry c + 1: neutral is entry 1 and team t is entry t + 2.
local function PaletteEntry(teamID)
	return teamID + 2
end

local function UpdatePalette()
	local neutral = options.neutralColor.value
	local teams, first, colors = Spring.GetTeamList(), {}, {[1] = {neutral[1], neutral[2], neutral[3]}}
	-- Row 1 of the palette: x is the opacity on the map, y on the minimap, and z
	-- the shown owner (neutral 0, otherwise the colour team + 1). Spots with the
	-- same shown owner are one territory with borders between different owners,
	-- and can merge.
	local minimapNeutral = options.minimapNeutral.value and options.minimapNeutralOpacity.value or 0
	local details = {[1] = {options.neutralOpacity.value, minimapNeutral, 0, 0}}
	for _, teamID in ipairs(teams) do
		local ally = select(6, Spring.GetTeamInfo(teamID, false))
		first[ally] = min(first[ally] or teamID, teamID)
	end
	-- Spectators see the territories as the team they spectate: its allies are allied.
	local allies, enemies = options.allies.value, options.enemies.value
	local width = 1
	for _, teamID in ipairs(teams) do
		local ally = select(6, Spring.GetTeamInfo(teamID, false))
		-- Each enemy allyteam is one owner, and so are allies in one colour.
		local mode, custom, colorTeam = enemies, options.enemyColor.value, first[ally]
		local opacity = options.enemyOpacity.value
		if ally == myAllyTeam then
			mode, custom = allies, options.allyColor.value
			colorTeam = mode == 'players' and teamID or Spring.GetMyTeamID()
			opacity = options.allyOpacity.value
		end
		local entry = PaletteEntry(teamID)
		colors[entry] = mode == 'custom' and {custom[1], custom[2], custom[3]} or {Spring.GetTeamColor(colorTeam)}
		details[entry] = {opacity, opacity, colorTeam + 1, 0}
		width = max(width, entry)
	end
	if palette then gl.DeleteTexture(palette) end
	-- Row 0 is the colour of each owner's territories.
	palette = NewTexture(width, 2)
	PaintRows(palette, {colors, details}, width)
	-- Shown owners may have changed: update the merged territories and distance map.
	paletteDirty, updateFrame = false, nil
end

local function DeleteMapTextures()
	for _, texture in pairs({atlas, edges, positions, observed, history, nextHistory, palette,
		close, index, groups, nextGroups, seeds, nextSeeds, field}) do
		gl.DeleteTexture(texture)
	end
	atlas, edges, positions, observed, history, nextHistory, palette = nil, nil, nil, nil, nil, nil, nil
	close, index, groups, nextGroups, seeds, nextSeeds, field, shownGroups = nil, nil, nil, nil, nil, nil, nil, nil
	mergePasses, fieldOn, updateFrame = 0, false, nil
end

-- Each spot's close spots, within the merge distance both ways, and enough
-- group passes to join the largest cluster of them, at most 64.
local function BuildClose()
	closeDirty, updateFrame = false, nil
	if close then gl.DeleteTexture(close) end
	close, mergePasses = nil, 0
	if not options.merge.value then return end
	local limit = options.mergeDistance.value^2
	local rows, width, root, size = {}, 1, {}, {}
	local function Root(i)
		while root[i] ~= i do i = root[i] end
		return i
	end
	for i = 1, #spots do root[i] = i end
	for i, a in ipairs(spots) do
		rows[i] = {}
		for j, b in ipairs(spots) do
			if j ~= i and (a.x - b.x)^2 + (a.z - b.z)^2 <= limit then
				rows[i][#rows[i] + 1] = {j, 0, 0, 0}
				root[Root(i)] = Root(j)
			end
		end
		width = max(width, #rows[i])
	end
	for i = 1, #spots do
		local r = Root(i)
		size[r] = (size[r] or 0) + 1
		mergePasses = max(mergePasses, size[r] - 1)
	end
	if mergePasses == 0 then return end
	mergePasses = min(mergePasses, 64)
	close = NewTexture(width, #spots)
	ClearTexture(close)
	PaintRows(close, rows, width)
end

-- The merged territories, then the distance map where it is needed, every
-- updateInterval game frames and when a setting changes.
local function UpdateTerritories(mode)
	if closeDirty then BuildClose() end
	local frame = Spring.GetGameFrame()
	if updateFrame and updateMode == mode and math.abs(frame - updateFrame) < updateInterval then return end
	updateFrame, updateMode = frame, mode
	-- With borders between different owners, neighbours with the same owner are joined anyway.
	shownGroups = index
	if mergePasses > 0 and mode ~= borderModes.owners then
		gl.Texture(1, close)
		gl.Texture(2, history)
		gl.Texture(3, palette)
		gl.UseShader(groupShader)
		for pass = 1, mergePasses do
			gl.Texture(0, pass == 1 and index or groups)
			gl.RenderToTexture(nextGroups, gl.CallList, quad)
			groups, nextGroups = nextGroups, groups
		end
		shownGroups = groups
	end
	-- With borders on every territory and nothing merged, each territory's own edges are the nearest.
	fieldOn = options.smoothFades.value and (mode == borderModes.owners or shownGroups ~= index)
	if fieldOn then
		gl.Texture(1, atlas)
		gl.Texture(2, history)
		gl.Texture(3, palette)
		gl.Texture(4, edges)
		gl.Texture(6, shownGroups)
		gl.UseShader(seedShader)
		gl.UniformInt(seedBorders, mode)
		gl.RenderToTexture(seeds, gl.CallList, quad)
		gl.UseShader(jumpShader)
		for _, step in ipairs(jumps) do
			gl.Texture(0, seeds)
			gl.UniformInt(jumpStep, step)
			gl.RenderToTexture(nextSeeds, gl.CallList, quad)
			seeds, nextSeeds = nextSeeds, seeds
		end
		gl.Texture(0, seeds)
		gl.UseShader(fieldShader)
		gl.RenderToTexture(field, gl.CallList, quad)
	end
	gl.UseShader(0)
end

local function BuildMap()
	DeleteMapTextures()
	spotSource = WG.metalSpots
	local lines
	spots, cells, lines = BuildCells(spotSource or {}, Game.mapSizeX, Game.mapSizeZ)
	byPosition = {}
	if #spots == 0 then return end
	local pointData, width = {}, 1
	for i, s in ipairs(spots) do
		byPosition[s.x] = byPosition[s.x] or {}
		byPosition[s.x][s.z] = i
		pointData[i] = {s.x, s.z, 0, 0}
		width = max(width, #lines[i])
	end
	positions, observed = NewTexture(#spots, 1), NewTexture(#spots, 1)
	history, nextHistory = NewTexture(#spots, 1), NewTexture(#spots, 1)
	PaintRow(positions, pointData, #spots)
	-- Unmerged, each spot is its own group.
	local indexData = {}
	for i = 1, #spots do indexData[i] = {i - 1, 0, 0, 0} end
	index, groups, nextGroups = NewTexture(#spots, 1), NewTexture(#spots, 1), NewTexture(#spots, 1)
	PaintRow(index, indexData, #spots)
	seeds, nextSeeds = NewTexture(fieldX, fieldZ), NewTexture(fieldX, fieldZ)
	-- Filtered, so fades are smooth between texel centres.
	field = assert(gl.CreateTexture(fieldX, fieldZ, {
		format = GL.RGBA32F, min_filter = GL.LINEAR, mag_filter = GL.LINEAR,
		wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE, fbo = true,
	}))
	closeDirty = true
	-- One row of neighbour edges per cell; unused slots stay zero.
	edges = NewTexture(width, #spots)
	ClearTexture(edges)
	PaintRows(edges, lines, width)
	-- Static cell IDs and two nearest edges; at most 32 MiB, regardless of
	-- map size. Half floats are exact for indices below 2048.
	atlas = assert(gl.CreateTexture(atlasX, atlasZ, {
		format = GL.RGBA16F, min_filter = GL.NEAREST, mag_filter = GL.NEAREST,
		wrap_s = GL.CLAMP_TO_EDGE, wrap_t = GL.CLAMP_TO_EDGE, fbo = true,
	}))
	gl.Texture(0, edges)
	gl.UseShader(cellShader)
	gl.RenderToTexture(atlas, function()
		for i, polygon in ipairs(cells) do
			gl.BeginEnd(GL.TRIANGLE_FAN, function()
				gl.Color(i - 1, 0, 0, 1)
				gl.Vertex(2*spots[i].x/Game.mapSizeX - 1, 2*spots[i].z/Game.mapSizeZ - 1, 0)
				for j = 1, #polygon + 1 do
					local p = polygon[(j - 1)%#polygon + 1]
					gl.Vertex(2*p[1]/Game.mapSizeX - 1, 2*p[2]/Game.mapSizeZ - 1, 0)
				end
			end)
		end
	end)
	gl.UseShader(0)
	gl.Texture(0, false)
	cells = nil
	ResetView()
end

function widget:Initialize()
	-- The Mexspot Fetcher, an API widget that starts first, sets WG.metalSpots
	-- to false on maps without metal spots, such as metal maps.
	local metalSpots = WG.metalSpots
	if metalSpots == false or (metalSpots and #metalSpots == 0) then
		Spring.Echo('Metal Territories: this map has no metal spots')
		widgetHandler:RemoveWidget(self)
		return
	end
	if not gl.CreateShader or not gl.RenderToTexture or not gl.BlitFBO then
		Spring.Echo('Metal Territories requires shaders and render-to-texture support')
		widgetHandler:RemoveWidget(self)
		return
	end
	local vertexSource = LoadShader('metal_territories.vert.glsl')
	paintShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_paint.frag.glsl')})
	cellShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_cell.frag.glsl'),
		uniformInt = {edges = 0},
		uniform = {texelSize = {texelX, texelZ}},
	})
	stateShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_state.frag.glsl'),
		uniformInt = {previousState = 0, observations = 1, positions = 2, los = 3},
		uniform = {mapSize = {Game.mapSizeX, Game.mapSizeZ}},
	})
	drawShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_draw.frag.glsl'),
		uniformInt = {depthTex = 0, atlas = 1, owners = 2, palette = 3, edges = 4, positions = 5, groups = 6, field = 7,
			ground = 8, shading = 9, clipZeroToOne = Platform.glSupportClipSpaceControl and 1 or 0},
		uniform = {mapSize = {Game.mapSizeX, Game.mapSizeZ}},
	})
	minimapShader = gl.CreateShader({vertex = LoadShader('metal_territories_minimap.vert.glsl'),
		fragment = LoadShader('metal_territories_minimap.frag.glsl'),
		uniformInt = {atlas = 1, owners = 2, palette = 3, edges = 4, positions = 5, groups = 6, field = 7, ground = 8,
			shading = 9, opacityChannel = 1},
		uniform = {mapSize = {Game.mapSizeX, Game.mapSizeZ}},
	})
	groupShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_group.frag.glsl'),
		uniformInt = {previous = 0, close = 1, owners = 2, palette = 3},
	})
	local fieldTexel = {Game.mapSizeX/fieldX, Game.mapSizeZ/fieldZ}
	seedShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_seed.frag.glsl'),
		uniformInt = {atlas = 1, owners = 2, palette = 3, edges = 4, groups = 6},
		uniform = {mapSize = {Game.mapSizeX, Game.mapSizeZ}, texelSize = fieldTexel},
	})
	jumpShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_jump.frag.glsl'),
		uniformInt = {previous = 0, edges = 4},
		uniform = {texelSize = fieldTexel},
	})
	fieldShader = gl.CreateShader({vertex = vertexSource, fragment = LoadShader('metal_territories_field.frag.glsl'),
		uniformInt = {seeds = 0, edges = 4},
		uniform = {texelSize = fieldTexel},
	})
	if not paintShader or not cellShader or not stateShader or not drawShader or not minimapShader
		or not groupShader or not seedShader or not jumpShader or not fieldShader then
		Spring.Echo('Metal Territories shader error: ' .. gl.GetShaderLog())
		widgetHandler:RemoveWidget(self)
		return
	end
	stateFullView = gl.GetUniformLocation(stateShader, 'fullView')
	drawOpacity = gl.GetUniformLocation(drawShader, 'opacity')
	drawBorders = gl.GetUniformLocation(drawShader, 'borderMode')
	drawInverse = gl.GetUniformLocation(drawShader, 'inverseViewProjection')
	drawView = gl.GetUniformLocation(drawShader, 'view')
	minimapOpacity = gl.GetUniformLocation(minimapShader, 'opacity')
	minimapBorders = gl.GetUniformLocation(minimapShader, 'borderMode')
	drawBorder = gl.GetUniformLocation(drawShader, 'border')
	drawRing = gl.GetUniformLocation(drawShader, 'ring')
	drawTint = gl.GetUniformLocation(drawShader, 'tint')
	drawStripes = gl.GetUniformLocation(drawShader, 'stripes')
	drawHatching = gl.GetUniformLocation(drawShader, 'hatching')
	minimapTint = gl.GetUniformLocation(minimapShader, 'tint')
	minimapLine = gl.GetUniformLocation(minimapShader, 'lineWidth')
	drawField = gl.GetUniformLocation(drawShader, 'useField')
	minimapField = gl.GetUniformLocation(minimapShader, 'useField')
	drawReach = gl.GetUniformLocation(drawShader, 'reach')
	minimapReach = gl.GetUniformLocation(minimapShader, 'reach')
	drawReachBorder = gl.GetUniformLocation(drawShader, 'reachBorder')
	minimapReachBorder = gl.GetUniformLocation(minimapShader, 'reachBorder')
	drawGround = gl.GetUniformLocation(drawShader, 'brightGround')
	minimapGround = gl.GetUniformLocation(minimapShader, 'brightGround')
	seedBorders = gl.GetUniformLocation(seedShader, 'borderMode')
	jumpStep = gl.GetUniformLocation(jumpShader, 'step')
	quad = gl.CreateList(function() gl.TexRect(-1, -1, 1, 1) end)
	-- Allocation and uploads run in DrawWorldPreUnit, where drawing is allowed.
end

-- A unit ID can be reused after an unseen death. Forget the association,
-- but do not use that fact to clear the last seen territory owner.
local function ForgetUnit(unitID)
	local i = unitSpot[unitID]
	if i then
		SetObservation(i, observations[i][1], 0, false)
		unitSpot[unitID] = nil
	end
end

function widget:UnitCreated(unitID, unitDefID, teamID)
	ForgetUnit(unitID)
	ObserveUnit(unitID, unitDefID, teamID)
end

function widget:UnitFinished(unitID, unitDefID, teamID)
	ObserveUnit(unitID, unitDefID, teamID)
end

function widget:UnitEnteredLos(unitID, teamID)
	ForgetUnit(unitID)
	ObserveUnit(unitID, Spring.GetUnitDefID(unitID), teamID)
end

function widget:UnitLeftLos(unitID)
	watched[unitID] = nil
	local i = unitSpot[unitID]
	if i and not fullView and not Spring.IsUnitAllied(unitID) then
		-- Remember the spot's owner, not an ID that can later be reused.
		ForgetUnit(unitID)
	end
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	watched[unitID] = nil
	if not mexDefs[unitDefID] then ForgetUnit(unitID); return end
	local i = unitSpot[unitID]
	if not i then return end
	local s = spots[i]
	local allied = Spring.AreTeamsAllied(teamID, Spring.GetMyTeamID())
	local visible = Spring.IsPosInLos(s.x, Spring.GetGroundHeight(s.x, s.z), s.z, myAllyTeam)
	local old = observations[i]
	SetObservation(i, (fullView or allied or visible) and 0 or old[1], 0, fullView or allied or visible)
	unitSpot[unitID] = nil
end

-- Reclaim turns a mex back into a nanoframe, which no longer owns its spot.
function widget:UnitReverseBuilt(unitID, unitDefID, teamID)
	widget:UnitDestroyed(unitID, unitDefID, teamID)
end

-- Widgets are not told when an enemy mex is finished or reclaimed back into a
-- nanoframe, so check the enemy mexes in sight each frame.
function widget:GameFrame()
	for unitID, finished in pairs(watched) do
		local now = not Spring.GetUnitIsBeingBuilt(unitID)
		if now ~= finished then
			ObserveUnit(unitID, Spring.GetUnitDefID(unitID), Spring.GetUnitTeam(unitID))
		end
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeam)
	ObserveUnit(unitID, unitDefID, newTeam)
end

function widget:UnitTaken(unitID, unitDefID, oldTeam, newTeam)
	local i = unitSpot[unitID]
	if i then
		-- An allied transfer away is known even if the new unit is out of LOS.
		SetObservation(i, observations[i][1], 0, false)
	end
	ObserveUnit(unitID, unitDefID, newTeam)
end

function widget:TeamColorsChanged()
	paletteDirty = true
end

-- With 'Your colour', allied territories have the colour of your team (for a
-- spectator, the team spectated), so a change of your team repaints them.
-- New team colours come in TeamColorsChanged; a change of allyteam resets the
-- view in DrawWorldPreUnit.
function widget:PlayerChanged(playerID)
	if playerID == Spring.GetMyPlayerID() then paletteDirty = true end
end

-- Beside the border, far from it, and 1/the distance between (0 if it does not fade).
local function SetTint(location, opacity, fades)
	local scale = options.tint.value and opacity or 0
	gl.Uniform(location, scale*tint[1], scale*tint[2], fades and options.tintFade.value/tintFade or 0)
end

-- With Fade out while zoomed, a factor for Opacity: Zoomed in opacity at the lower zoom
-- limit and closer, 1 at the upper limit and farther, linear between. The zoom is the
-- camera's distance to the ground at the centre of the view, or its height above the
-- ground when the centre is off the map.
local function ZoomFade()
	if not options.zoomFade.value then return 1 end
	local cx, cy, cz = Spring.GetCameraPosition()
	local _, pos = Spring.TraceScreenRay(viewW/2, viewH/2, true)
	local zoom
	if pos then
		zoom = math.sqrt((cx - pos[1])^2 + (cy - pos[2])^2 + (cz - pos[3])^2)
	else
		zoom = cy - Spring.GetGroundHeight(cx, cz)
	end
	local near, far = options.zoomFadeNear.value, options.zoomFadeFar.value
	local lower, upper = min(near, far), max(near, far)
	local t = upper > lower and (zoom - lower)/(upper - lower) or (zoom < lower and 0 or 1)
	local low = options.zoomFadeOpacity.value/100
	return low + (1 - low)*max(0, min(1, t))
end

function widget:DrawWorldPreUnit()
	if not drawShader then return end
	gl.PushAttrib(GL.ENABLE_BIT + GL.COLOR_BUFFER_BIT + GL.DEPTH_BUFFER_BIT + GL.POINT_BIT + GL.CURRENT_BIT)
	gl.Culling(false)
	gl.AlphaTest(false)
	gl.Scissor(false)
	gl.StencilTest(false)
	gl.ColorMask(true, true, true, true)
	gl.DepthTest(false)
	gl.DepthMask(false)
	gl.Blending(false)
	gl.PointSize(1)
	if WG.metalSpots ~= spotSource or not spots then BuildMap() end
	if spots and #spots > 0 then
		local spec, full = Spring.GetSpectatingState()
		if myAllyTeam ~= Spring.GetMyAllyTeamID() or fullView ~= (spec and full) then ResetView() end
		if next(dirty) then
			PaintRow(observed, dirty, #spots)
			dirty = {}
		end
		if paletteDirty then UpdatePalette() end
		gl.Texture(0, history)
		gl.Texture(1, observed)
		gl.Texture(2, positions)
		gl.Texture(3, '$info:los')
		gl.UseShader(stateShader)
		gl.UniformInt(stateFullView, fullView and 1 or 0)
		gl.RenderToTexture(nextHistory, gl.CallList, quad)
		gl.UseShader(0)
		history, nextHistory = nextHistory, history
		local borderMode = borderModes[options.borders.value]
		UpdateTerritories(borderMode)
		local w, h, x, y = (Spring.Orig and Spring.Orig.GetViewGeometry or Spring.GetViewGeometry)()
		if not depth or w ~= viewW or h ~= viewH then
			if depthFBO then gl.DeleteFBO(depthFBO) end
			if depth then gl.DeleteTexture(depth) end
			local formats = {[16] = GL.DEPTH_COMPONENT16, [24] = GL.DEPTH_COMPONENT24, [32] = GL.DEPTH_COMPONENT32}
			depth = NewTexture(w, h, formats[Platform.glSupportDepthBufferBitDepth] or GL.DEPTH_COMPONENT24)
			depthFBO = assert(gl.CreateFBO({depth = depth, drawbuffers = {GL.NONE}}))
			depthFBO.readbuffer = GL.NONE
			assert(gl.IsValidFBO(depthFBO), 'Metal Territories: depth framebuffer incomplete')
		end
		viewW, viewH, viewX, viewY = w, h, x, y
		local mode = Spring.GetMapDrawMode()
		if not Spring.IsGUIHidden() and mode ~= 'height' and mode ~= 'path' then
			-- Blit resolves MSAA depth, with the same format as the window.
			gl.BlitFBO(nil, viewX, viewY, viewX + viewW, viewY + viewH,
				depthFBO, 0, 0, viewW, viewH, GL.DEPTH_BUFFER_BIT, GL.NEAREST)
			gl.Texture(0, depth)
			gl.Texture(1, atlas)
			gl.Texture(2, history)
			gl.Texture(3, palette)
			gl.Texture(4, edges)
			gl.Texture(5, positions)
			gl.Texture(6, shownGroups)
			gl.Texture(7, field)
			gl.Texture(8, '$minimap')
			gl.Texture(9, '$shading')
			gl.UseShader(drawShader)
			gl.UniformMatrix(drawInverse, 'viewprojectioninverse')
			gl.Uniform(drawView, viewW, viewH, viewX, viewY)
			gl.Uniform(drawOpacity, options.opacity.value*ZoomFade())
			gl.UniformInt(drawBorders, borderMode)
			gl.UniformInt(drawField, fieldOn and 1 or 0)
			gl.Uniform(drawReach, options.reach.value, 1/reachFade)
			gl.Uniform(drawReachBorder, options.reachBorder.value and 1 or 0, 0)
			local borderWidth, gap = options.borderWidth.value, options.borderGap.value
			gl.Uniform(drawBorder, gap, gap + borderWidth)
			gl.Uniform(drawRing, ringRadius, ringRadius + borderWidth, options.hatchFade.value/hatchFade)
			SetTint(drawTint, options.tintOpacity.value, true)
			-- Lines at the angle from the x axis toward north; the normal is (sin, cos).
			local spacing, angle = options.hatchSpacing.value, math.rad(options.hatchAngle.value)
			gl.Uniform(drawStripes, math.sin(angle)/spacing, math.cos(angle)/spacing, 0.5*options.hatchWidth.value/spacing)
			gl.Uniform(drawHatching, options.hatching.value and 1 or 0)
			gl.Uniform(drawGround, options.brightGround.value)
			gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
			gl.CallList(quad)
			gl.UseShader(0)
		end
	end
	for i = 9, 0, -1 do gl.Texture(i, false) end
	gl.PopAttrib()
end

-- Drawn into the minimap's texture before the world, with the textures of the
-- last world draw, under the unit icons.
function widget:DrawInMiniMapBackground(sx, sy)
	if not options.minimap.value or not palette then return end
	gl.Texture(1, atlas)
	gl.Texture(2, history)
	gl.Texture(3, palette)
	gl.Texture(4, edges)
	gl.Texture(5, positions)
	gl.Texture(6, shownGroups)
	gl.Texture(7, field)
	gl.Texture(8, '$minimap')
	gl.Texture(9, '$shading')
	gl.UseShader(minimapShader)
	gl.Uniform(minimapOpacity, options.opacity.value)
	local borderMode = borderModes[options.borders.value]
	gl.UniformInt(minimapBorders, borderMode)
	gl.UniformInt(minimapField, fieldOn and 1 or 0)
	gl.Uniform(minimapReach, options.reach.value, 1/reachFade)
	gl.Uniform(minimapReachBorder, options.reachBorder.value and 1 or 0, borderMode ~= 0 and 0.5*options.minimapBorderWidth.value or 0)
	SetTint(minimapTint, options.minimapTintOpacity.value, options.minimapTintFade.value)
	gl.Uniform(minimapLine, options.minimapBorderWidth.value)
	gl.Uniform(minimapGround, options.brightGround.value)
	-- The map's top left corner is at the minimap's top left, or bottom right when flipped.
	local flipped = Spring.Utilities.IsMinimapFlipped()
	gl.TexRect(0, 0, sx, sy, flipped, flipped)
	gl.UseShader(0)
	for i = 9, 1, -1 do gl.Texture(i, false) end
end

function widget:Shutdown()
	DeleteMapTextures()
	if depthFBO then gl.DeleteFBO(depthFBO) end
	if depth then gl.DeleteTexture(depth) end
	if quad then gl.DeleteList(quad) end
	if paintShader then gl.DeleteShader(paintShader) end
	if cellShader then gl.DeleteShader(cellShader) end
	if stateShader then gl.DeleteShader(stateShader) end
	if drawShader then gl.DeleteShader(drawShader) end
	if minimapShader then gl.DeleteShader(minimapShader) end
	if groupShader then gl.DeleteShader(groupShader) end
	if seedShader then gl.DeleteShader(seedShader) end
	if jumpShader then gl.DeleteShader(jumpShader) end
	if fieldShader then gl.DeleteShader(fieldShader) end
end
