function widget:GetInfo()
	return {
		name      = "Radar Icons GL4",
		desc      = "Draws unit icons and radar dots instead of the engine, with smooth edges without anti-aliasing.",
		author    = "moss-orbit-9f339e",
		date      = "2026-11-24",
		license   = "GNU GPL, v2 or later",
		layer     = -1000000000, -- Below gfx_distortion_gl4: the icons cover all other world drawing, like the engine icons.
		enabled   = false,
	}
end

local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spGetUnitLosState     = Spring.GetUnitLosState
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetUnitRadius       = Spring.GetUnitRadius
local spGetUnitHeading      = Spring.GetUnitHeading
local spGetUnitNoMinimap    = Spring.GetUnitNoMinimap
local spIsUnitSelected      = Spring.IsUnitSelected
local spIsPosInLos          = Spring.IsPosInLos
local spGetMyAllyTeamID     = Spring.GetMyAllyTeamID
local spGetSpectatingState  = Spring.GetSpectatingState
local spAreTeamsAllied      = Spring.AreTeamsAllied
local spGetMyTeamID         = Spring.GetMyTeamID
local spGetDrawFrame        = Spring.GetDrawFrame
local spValidUnitID         = Spring.ValidUnitID

local LOS_INLOS = 1
local LOS_INRADAR = 2
local HEADING_TO_RAD = math.pi / 32768

local KIND_HIDDEN = 0
local KIND_LOS = 1
local KIND_RADAR = 2
local KIND_GHOST = 3

local POS_UNIFORM = 0 -- engine drawPos plus the mid offset turned by the heading
local POS_RADAR = 1 -- radarPos[posSrc.x], written every frame
local POS_FIXED = 2 -- posSrc.xyz

local STEP = 20
local MAX_SLOTS = 8192
local OFFSET_REFRESH_FRAMES = 30
local GHOST_CHECK_FRAMES = 15
local RADAR_BINDING = 5

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir .. "LuaShader.lua")
VFS.Include(luaShaderDir .. "instancevbotable.lua")

local hiddenDefs = {}
if UnitDefNames.terraunit then
	hiddenDefs[UnitDefNames.terraunit.id] = true
end

local ghostDim = Spring.GetConfigFloat("UnitGhostIconsDimming", 0.8)
local mmUnitSize = Spring.GetConfigFloat("MiniMapUnitSize", 2.5)
local mmUnitExp = Spring.GetConfigFloat("MiniMapUnitExp", 0.25)

local iconShader, minimapShader
local instanceVBO, cornerVBO, iconVAO, radarVBO

local fullView = false
local myAllyTeam = 0
local myTeam = 0

local iconCache = {}

-- All icons in one list, in the engine's draw order.
local count = 0
local slotUnit = {}
local slotOf = {}
local kindOf = {}
local inst = {}
local tombstones = 0

-- Radar-only units in any order; their positions are uploaded to radarVBO every frame.
local radarCount = 0
local radarUnit = {}
local radarIndexOf = {}
local radarPos = {}

local dying = {}
local ghosts = {}
local refreshSlot = 0
local ghostCheck = 0
local lastPosFrame = -1

local radiusCache = {}
local seenBy = {} -- unitID -> set of ally teams that saw it in LOS (the engine's PREVLOS)
local defCache = {}
local teamCache = {}
local ghostPos = {}
local selectedUnits = {}

local function SetEngineIconMode()
	Spring.SetConfigInt("LuaRadarIcons", (options.minimap.value == "engine") and 2 or 1, true) -- Read by the Engine Icon Hider gadget.
end

options_path = 'Settings/Graphics/Unit Visibility/Radar Icons'
options_order = {'smooth', 'minimap'}
options = {
	smooth = {
		name = 'Smooth icon edges',
		desc = 'Blend the edges of unit icons. Off draws hard edges, like the engine icons without anti-aliasing.',
		type = 'bool',
		value = true,
		noHotkey = true,
	},
	minimap = {
		name = 'Minimap icons',
		type = 'radioButton',
		value = 'lua',
		items = {
			{key = 'lua', name = 'Drawn by this widget'},
			{key = 'engine', name = 'Drawn by the engine (slower)'},
		},
		noHotkey = true,
		OnChange = SetEngineIconMode,
	},
}

local commonVS = [[
#version 420 compatibility
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (location = 0) in vec2 corner;
layout (location = 1) in vec4 posSrc;     // w: 0 engine drawPos, 1 radarPos[x], 2 xyz
layout (location = 2) in vec4 uvRect;     // atlas x0, y0, x1, y1
layout (location = 3) in vec4 params;     // size, teamID, selected, kind
layout (location = 4) in vec4 offset;     // mid offset at heading 0, size without radius (< 0: not on the minimap)
layout (location = 5) in uvec4 instData;

//__ENGINEUNIFORMBUFFERDEFS__

struct SUniformsBuffer {
	uint composite; // u8 drawFlag; u8 unused1; u16 id;
	uint unused2;
	uint unused3;
	uint unused4;
	float maxHealth;
	float health;
	float unused5;
	float unused6;
	vec4 drawPos;
	vec4 speed;
	vec4[4] userDefined;
};

layout(std140, binding=1) readonly buffer UniformsBuffer {
	SUniformsBuffer uni[];
};

layout(std140, binding=5) readonly buffer RadarBuffer {
	vec4 radarPos[];
};

out DataVS {
	vec2 vUV;
	vec4 vColor;
};

vec3 UnitPos()
{
	if (posSrc.w > 1.5) {
		return posSrc.xyz;
	}
	if (posSrc.w > 0.5) {
		return radarPos[int(posSrc.x)].xyz;
	}
	vec4 drawPos = uni[instData.y].drawPos;
	float c = cos(drawPos.w);
	float s = sin(drawPos.w);
	return drawPos.xyz + vec3(c * offset.x + s * offset.z, offset.y, c * offset.z - s * offset.x);
}

void Cull()
{
	gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
	vUV = vec2(0.0);
	vColor = vec4(0.0);
}

vec2 IconUV()
{
	return vec2(corner.x < 0.0 ? uvRect.x : uvRect.z, corner.y > 0.0 ? uvRect.y : uvRect.w);
}

vec4 IconColor()
{
	if (params.z > 0.5) {
		return vec4(1.0);
	}
	return teamColor[int(params.y)];
}
]]

local worldVS = commonVS .. [[
uniform sampler2D heightTex;

float GroundHeight(vec2 xz) // CGround::GetHeightReal: two triangles per heightmap square
{
	vec2 sq = clamp(xz, vec2(0.0), mapSize.xy) / 8.0;
	ivec2 i = min(ivec2(sq), ivec2(mapSize.xy / 8.0) - 1);
	vec2 d = sq - vec2(i);
	if (d.x + d.y < 1.0) {
		float h00 = texelFetch(heightTex, i, 0).r;
		float h10 = texelFetch(heightTex, i + ivec2(1, 0), 0).r;
		float h01 = texelFetch(heightTex, i + ivec2(0, 1), 0).r;
		return h00 + d.x * (h10 - h00) + d.y * (h01 - h00);
	}
	float h11 = texelFetch(heightTex, i + ivec2(1, 1), 0).r;
	float h10 = texelFetch(heightTex, i + ivec2(1, 0), 0).r;
	float h01 = texelFetch(heightTex, i + ivec2(0, 1), 0).r;
	return h11 + (1.0 - d.x) * (h01 - h11) + (1.0 - d.y) * (h10 - h11);
}

void main()
{
	float kind = params.w;
	if (kind < 0.5 || kind > 2.5 || (kind < 1.5 && (uni[instData.y].composite & 128u) == 0u)) {
		Cull();
		return;
	}
	vec3 pos = UnitPos();
	float h = GroundHeight(pos.xz);
	pos.y = max(pos.y, h);
	float dist = min(8000.0, length(cameraViewInv[3].xyz - pos));
	float scale = params.x * 0.4 * sqrt(dist);
	pos.y = max(pos.y, h + scale);
	vec3 world = pos + cameraViewInv[0].xyz * (corner.x * scale) + cameraViewInv[1].xyz * (corner.y * scale);
	gl_Position = cameraViewProj * vec4(world, 1.0);
	vUV = IconUV();
	vColor = IconColor();
}
]]

local minimapVS = commonVS .. [[
uniform vec2 unitSize;
uniform float ghostDim;

void main()
{
	float kind = params.w;
	if (kind < 0.5 || offset.w < 0.0) {
		Cull();
		return;
	}
	float size = (kind > 2.5) ? offset.w : params.x;
	vec2 xz = UnitPos().xz + corner * vec2(1.0, -1.0) * size * unitSize;
	gl_Position = gl_ModelViewProjectionMatrix * vec4(xz, 0.0, 1.0);
	vUV = IconUV();
	vColor = IconColor();
	if (kind > 2.5) {
		vColor.rgb = floor(floor(vColor.rgb * 255.0 + 0.5) * ghostDim) / 255.0; // like the engine's SColor dimming
	}
}
]]

local fsSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

uniform sampler2D iconTex;
uniform float exactMode;

in DataVS {
	vec2 vUV;
	vec4 vColor;
};

out vec4 fragColor;

void main()
{
	vec4 tex = texture(iconTex, vUV);
	if (exactMode > 1.5) {
		fragColor = tex * vColor;
		if (fragColor.a <= 0.0) {
			discard;
		}
	} else if (exactMode > 0.5) {
		fragColor = tex * vec4(vColor.rgb, 1.0);
		if (fragColor.a <= 0.05) {
			discard;
		}
	} else {
		fragColor = vec4(tex.rgb * vColor.rgb, tex.a);
		if (fragColor.a < 0.004) {
			discard;
		}
	}
}
]]

local INSTANCE_LAYOUT = {
	{id = 1, name = 'posSrc',   size = 4},
	{id = 2, name = 'uvRect',   size = 4},
	{id = 3, name = 'params',   size = 4},
	{id = 4, name = 'offset',   size = 4},
	{id = 5, name = 'instData', size = 4, type = GL.UNSIGNED_INT},
}

local function GetIcon(name)
	local icon = iconCache[name]
	if icon then
		return icon
	end
	local data = Spring.GetIconData(name, true) or Spring.GetIconData("default", true)
	local tc = data.atlasTexCoords
	icon = {
		size = data.size or 1,
		radiusAdjust = data.radiusAdjust and data.name ~= "default",
		x0 = tc.x0, y0 = tc.y0, x1 = tc.x1, y1 = tc.y1,
	}
	iconCache[name] = icon
	return icon
end

local function MarkSeen(unitID, allyTeam)
	local seen = seenBy[unitID]
	if not seen then
		seen = {}
		seenBy[unitID] = seen
	end
	seen[allyTeam] = true
end

local function ForgetSeen(unitID)
	if seenBy[unitID] then
		seenBy[unitID][myAllyTeam] = nil
	end
end

local function IsKnownGhost(unitID) -- CUnitDrawerData::UpdateCurrentUnitIcon: isGhostBuilding
	local unitDefID = defCache[unitID]
	return Game.ghostedBuildings and seenBy[unitID] and seenBy[unitID][myAllyTeam] and unitDefID and UnitDefs[unitDefID].leavesGhost
end

local function IsReadable(unitID)
	if fullView then
		return true
	end
	local team = spGetUnitTeam(unitID)
	return team ~= nil and spAreTeamsAllied(team, myTeam)
end

local function WantedKind(unitID, unitDefID)
	if IsReadable(unitID) then
		return KIND_LOS
	end
	local los = spGetUnitLosState(unitID, myAllyTeam, true)
	if los then
		if los % 2 == LOS_INLOS then
			return KIND_LOS
		end
		if math.floor(los / LOS_INRADAR) % 2 == 1 then
			return KIND_RADAR
		end
	end
	if IsKnownGhost(unitID) and ghostPos[unitID] then
		return KIND_GHOST
	end
	return KIND_HIDDEN
end

local function MidOffset(unitID)
	local px, py, pz = spGetUnitViewPosition(unitID)
	local mx, my, mz = spGetUnitViewPosition(unitID, true)
	if not (px and mx) then
		return 0, 0, 0
	end
	local h = (spGetUnitHeading(unitID) or 0) * HEADING_TO_RAD
	local c, s = math.cos(h), math.sin(h)
	local dx, dz = mx - px, mz - pz
	return c * dx - s * dz, my - py, s * dx + c * dz
end

local function UploadSlot(slot)
	local o = (slot - 1) * STEP
	local unitID = slotUnit[slot]
	if kindOf[slot] == KIND_LOS and not spValidUnitID(unitID) then -- deleted in this sim frame, before the dying check
		kindOf[slot] = KIND_HIDDEN
		inst[o + 12] = KIND_HIDDEN
		tombstones = tombstones + 1
		dying[unitID] = nil
	end
	instanceVBO:Upload(inst, nil, slot - 1, o + 1, o + STEP)
	if kindOf[slot] == KIND_LOS then
		instanceVBO:InstanceDataFromUnitIDs(unitID, 5, slot - 1)
	end
end

local function UploadRadarIndex(unitID)
	local slot = slotOf[unitID]
	if slot then
		local o = (slot - 1) * STEP
		inst[o + 1] = radarIndexOf[unitID] - 1
		instanceVBO:Upload(inst, 1, slot - 1, o + 1, o + 4)
	end
end

local function SetRadar(unitID, isRadar)
	local index = radarIndexOf[unitID]
	if isRadar and not index then
		radarCount = radarCount + 1
		radarUnit[radarCount] = unitID
		radarIndexOf[unitID] = radarCount
		local x, y, z = spGetUnitViewPosition(unitID, true)
		local k = (radarCount - 1) * 4
		radarPos[k + 1], radarPos[k + 2], radarPos[k + 3], radarPos[k + 4] = x or 0, y or 0, z or 0, 0
	elseif index and not isRadar then
		local last = radarUnit[radarCount]
		radarIndexOf[unitID] = nil
		if last ~= unitID then
			radarUnit[index] = last
			radarIndexOf[last] = index
			local k, l = (index - 1) * 4, (radarCount - 1) * 4
			for i = 1, 4 do
				radarPos[k + i] = radarPos[l + i]
			end
			UploadRadarIndex(last)
		end
		radarUnit[radarCount] = nil
		radarCount = radarCount - 1
	end
end

local function FillSlot(slot, unitID, kind)
	local unitDefID = spGetUnitDefID(unitID)
	if unitDefID then
		defCache[unitID] = unitDefID
	elseif kind == KIND_GHOST or (kind == KIND_RADAR and IsKnownGhost(unitID)) then
		unitDefID = defCache[unitID]
	end
	if kind == KIND_LOS and not fullView then
		MarkSeen(unitID, myAllyTeam)
	end
	local ud = unitDefID and UnitDefs[unitDefID]
	if (kind == KIND_LOS or kind == KIND_RADAR) and ud and ud.leavesGhost then
		local x, y, z = spGetUnitViewPosition(unitID, true)
		if x then
			ghostPos[unitID] = {x, y, z}
		end
	end
	if kind == KIND_GHOST and not ghostPos[unitID] then
		kind = KIND_HIDDEN
	end
	local icon = GetIcon(ud and ud.iconType or "default")
	if kind == KIND_LOS then
		radiusCache[unitID] = spGetUnitRadius(unitID) or radiusCache[unitID]
	end
	local size = icon.size
	if icon.radiusAdjust and kind ~= KIND_GHOST then
		size = size * (radiusCache[unitID] or (ud and ud.radius) or 30) / 30
	end
	local team = spGetUnitTeam(unitID) or teamCache[unitID] or 0
	teamCache[unitID] = team

	SetRadar(unitID, kind == KIND_RADAR)
	ghosts[unitID] = (kind == KIND_GHOST) or nil
	kindOf[slot] = kind
	local o = (slot - 1) * STEP
	local ox, oy, oz = 0, 0, 0
	if kind == KIND_LOS then
		inst[o + 1], inst[o + 2], inst[o + 3], inst[o + 4] = 0, 0, 0, POS_UNIFORM
		ox, oy, oz = MidOffset(unitID)
	elseif kind == KIND_RADAR then
		inst[o + 1], inst[o + 2], inst[o + 3], inst[o + 4] = radarIndexOf[unitID] - 1, 0, 0, POS_RADAR
	elseif kind == KIND_GHOST then
		local g = ghostPos[unitID]
		inst[o + 1], inst[o + 2], inst[o + 3], inst[o + 4] = g[1], g[2], g[3], POS_FIXED
	else
		inst[o + 1], inst[o + 2], inst[o + 3], inst[o + 4] = 0, 0, 0, POS_FIXED
		tombstones = tombstones + 1
	end
	inst[o + 5], inst[o + 6], inst[o + 7], inst[o + 8] = icon.x0, icon.y0, icon.x1, icon.y1
	inst[o + 9], inst[o + 10], inst[o + 11], inst[o + 12] = size, team, spIsUnitSelected(unitID) and 1 or 0, kind
	inst[o + 13], inst[o + 14], inst[o + 15] = ox, oy, oz
	inst[o + 16] = spGetUnitNoMinimap(unitID) and -icon.size or icon.size
	inst[o + 17], inst[o + 18], inst[o + 19], inst[o + 20] = 0, 0, 0, 0
	UploadSlot(slot)
end

local function CopySlot(from, to)
	local fo, too = (from - 1) * STEP, (to - 1) * STEP
	for i = 1, STEP do
		inst[too + i] = inst[fo + i]
	end
	local unitID = slotUnit[from]
	slotUnit[to] = unitID
	slotOf[unitID] = to
	kindOf[to] = kindOf[from]
end

local function SwapRemove(unitID)
	local slot = slotOf[unitID]
	if not slot then
		return
	end
	if kindOf[slot] == KIND_HIDDEN then
		tombstones = tombstones - 1
	end
	SetRadar(unitID, false)
	ghosts[unitID] = nil
	slotOf[unitID] = nil
	if slot ~= count then
		CopySlot(count, slot)
		UploadSlot(slot)
	end
	slotUnit[count] = nil
	kindOf[count] = nil
	count = count - 1
end

local function Compact()
	local n = 0
	for slot = 1, count do
		if kindOf[slot] == KIND_HIDDEN then
			slotOf[slotUnit[slot]] = nil
		else
			n = n + 1
			if n ~= slot then
				CopySlot(slot, n)
			end
		end
	end
	for slot = n + 1, count do
		slotUnit[slot], kindOf[slot] = nil, nil
	end
	count = n
	tombstones = 0
	for slot = 1, count do
		UploadSlot(slot)
	end
end

local function RefreshUnit(unitID)
	local unitDefID = spGetUnitDefID(unitID)
	if hiddenDefs[unitDefID or -1] then
		return
	end
	local kind = WantedKind(unitID, unitDefID)
	local slot = slotOf[unitID]
	if not slot then
		if kind == KIND_HIDDEN or kind == KIND_GHOST or count >= MAX_SLOTS then
			return
		end
		count = count + 1
		slot = count
		slotUnit[slot] = unitID
		slotOf[unitID] = slot
	elseif kindOf[slot] == KIND_HIDDEN then
		tombstones = tombstones - 1
	end
	FillSlot(slot, unitID, kind)
end

local function RefreshAll()
	local _, specFullView = spGetSpectatingState()
	fullView = specFullView
	myAllyTeam = spGetMyAllyTeamID()
	myTeam = spGetMyTeamID()
	for slot = 1, count do
		RefreshUnit(slotUnit[slot])
	end
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		if not slotOf[units[i]] then
			RefreshUnit(units[i])
		end
	end
end

local function RefreshOffsets() -- the mid offset tilts with the unit; every unit is read once per OFFSET_REFRESH_FRAMES
	for _ = 1, math.ceil(count / OFFSET_REFRESH_FRAMES) do
		refreshSlot = (refreshSlot % count) + 1
		if kindOf[refreshSlot] == KIND_LOS then
			local o = (refreshSlot - 1) * STEP
			local ox, oy, oz = MidOffset(slotUnit[refreshSlot])
			if math.abs(ox - inst[o + 13]) + math.abs(oy - inst[o + 14]) + math.abs(oz - inst[o + 15]) > 0.01 then
				inst[o + 13], inst[o + 14], inst[o + 15] = ox, oy, oz
				instanceVBO:Upload(inst, 4, refreshSlot - 1, o + 13, o + 16)
			end
		end
	end
end

local function CheckGhosts()
	ghostCheck = ghostCheck + 1
	if ghostCheck < GHOST_CHECK_FRAMES then
		return
	end
	ghostCheck = 0
	for unitID in pairs(ghosts) do
		local g = ghostPos[unitID]
		if spIsPosInLos(g[1], g[2], g[3], myAllyTeam) then -- the building died out of sight
			ForgetSeen(unitID)
			ghostPos[unitID] = nil
			RefreshUnit(unitID)
		end
	end
end

local function UpdatePositions()
	local drawFrame = spGetDrawFrame()
	if drawFrame == lastPosFrame then
		return
	end
	lastPosFrame = drawFrame
	local lost
	for i = 1, radarCount do
		local x, y, z = spGetUnitViewPosition(radarUnit[i], true)
		if x then
			local k = (i - 1) * 4
			radarPos[k + 1], radarPos[k + 2], radarPos[k + 3] = x, y, z
		else
			lost = lost or {}
			lost[#lost + 1] = radarUnit[i]
		end
	end
	for unitID in pairs(dying) do
		if not spGetUnitDefID(unitID) then
			lost = lost or {}
			lost[#lost + 1] = unitID
		end
	end
	if lost then
		for i = 1, #lost do
			dying[lost[i]] = nil
			RefreshUnit(lost[i])
		end
	end
	if radarCount > 0 then
		radarVBO:Upload(radarPos, nil, 0, 1, radarCount * 4)
	end
	if count > 0 then
		RefreshOffsets()
	end
	CheckGhosts()
	if tombstones > math.max(64, count / 8) then
		Compact()
	end
end

function widget:DrawWorld()
	UpdatePositions()
	if count == 0 then
		return
	end
	local exact = not options.smooth.value
	gl.DepthTest(false)
	gl.DepthMask(false)
	if exact then
		gl.Blending(false)
	else
		gl.Blending(GL.ONE, GL.ONE_MINUS_SRC_ALPHA)
	end
	gl.Texture(0, "$icons")
	gl.Texture(1, "$heightmap")
	radarVBO:BindBufferRange(RADAR_BINDING)
	iconShader:Activate()
	iconShader:SetUniform("exactMode", exact and 1 or 0)
	iconVAO:DrawArrays(GL.TRIANGLE_STRIP, 4, 0, count, 0)
	iconShader:Deactivate()
	radarVBO:UnbindBufferRange(RADAR_BINDING)
	gl.Texture(0, false)
	gl.Texture(1, false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.DepthTest(true)
	gl.DepthMask(true)
end

function widget:DrawInMiniMapBackground(sx, sy)
	if options.minimap.value ~= "lua" then
		return
	end
	UpdatePositions()
	if count == 0 then
		return
	end
	local dpr = mmUnitSize / math.pow(200 * 200, mmUnitExp) * math.pow(sx * sy, mmUnitExp) -- CMiniMap::UpdateGeometry
	gl.PushMatrix()
	gl.LoadIdentity()
	gl.Translate(0, 1, 0)
	gl.Scale(1 / Game.mapSizeX, -1 / Game.mapSizeZ, 1)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	gl.Texture(0, "$icons")
	radarVBO:BindBufferRange(RADAR_BINDING)
	minimapShader:Activate()
	minimapShader:SetUniform("unitSize", dpr * Game.mapSizeX / sx, dpr * Game.mapSizeZ / sy)
	minimapShader:SetUniform("ghostDim", ghostDim)
	minimapShader:SetUniform("exactMode", 2)
	iconVAO:DrawArrays(GL.TRIANGLE_STRIP, 4, 0, count, 0)
	minimapShader:Deactivate()
	radarVBO:UnbindBufferRange(RADAR_BINDING)
	gl.Texture(0, false)
	gl.PopMatrix()
end

local function SetSelected(unitID, selected)
	local slot = slotOf[unitID]
	if slot and inst[(slot - 1) * STEP + 11] ~= selected then
		inst[(slot - 1) * STEP + 11] = selected
		UploadSlot(slot)
	end
end

function widget:SelectionChanged(newSelection)
	local newSet = {}
	for i = 1, #(newSelection or {}) do
		newSet[newSelection[i]] = true
		if not selectedUnits[newSelection[i]] then
			SetSelected(newSelection[i], 1)
		end
	end
	for unitID in pairs(selectedUnits) do
		if not newSet[unitID] then
			SetSelected(unitID, 0)
		end
	end
	selectedUnits = newSet
end

function widget:PlayerChanged()
	RefreshAll()
end

function widget:UnitCreated(unitID)
	RefreshUnit(unitID)
end

function widget:RenderUnitDestroyed(unitID)
	SwapRemove(unitID)
	dying[unitID] = nil
	seenBy[unitID] = nil
	radiusCache[unitID] = nil
	defCache[unitID] = nil
	teamCache[unitID] = nil
	ghostPos[unitID] = nil
end

function widget:UnitDestroyed(unitID)
	if slotOf[unitID] and not IsReadable(unitID) then -- no RenderUnitDestroyed for this unit: watch until it is gone
		dying[unitID] = true
		ForgetSeen(unitID)
		ghostPos[unitID] = nil
	end
end

function widget:UnitFinished(unitID)
	if slotOf[unitID] then
		RefreshUnit(unitID)
	end
end

function widget:UnitGiven(unitID)
	RefreshUnit(unitID)
end

function widget:UnitTaken(unitID)
	RefreshUnit(unitID)
end

function widget:UnitEnteredLos(unitID, unitTeam, allyTeam) -- allyTeam is given only in full view
	MarkSeen(unitID, allyTeam or myAllyTeam)
	if not allyTeam or allyTeam == myAllyTeam then
		RefreshUnit(unitID)
	end
end

function widget:UnitLeftLos(unitID, unitTeam, allyTeam)
	if not allyTeam or allyTeam == myAllyTeam then
		RefreshUnit(unitID)
	end
end

function widget:UnitEnteredRadar(unitID, unitTeam, allyTeam)
	if not allyTeam or allyTeam == myAllyTeam then
		RefreshUnit(unitID)
	end
end

function widget:UnitLeftRadar(unitID, unitTeam, allyTeam)
	if allyTeam and allyTeam ~= myAllyTeam then
		return
	end
	local los = spGetUnitLosState(unitID, myAllyTeam, true)
	if los and math.floor(los / LOS_INRADAR) % 2 == 1 then -- still in radar: the Widget Events gadget reports a death
		ForgetSeen(unitID)
		ghostPos[unitID] = nil
	end
	RefreshUnit(unitID)
end

function widget:Initialize()
	if not gl.GetVBO or not gl.CreateShader then
		widgetHandler:RemoveWidget()
		return
	end
	local engineDefs = LuaShader.GetEngineUniformBufferDefs()
	iconShader = LuaShader({
		vertex = worldVS:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineDefs),
		fragment = fsSrc,
		uniformInt = {iconTex = 0, heightTex = 1},
		uniformFloat = {exactMode = 0},
	}, "Radar Icons GL4")
	minimapShader = LuaShader({
		vertex = minimapVS:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineDefs),
		fragment = fsSrc,
		uniformInt = {iconTex = 0},
		uniformFloat = {exactMode = 2, ghostDim = 0.8},
	}, "Radar Icons GL4 minimap")
	if not iconShader:Initialize() or not minimapShader:Initialize() then
		Spring.Echo("Radar Icons GL4: shader failed")
		widgetHandler:RemoveWidget()
		return
	end
	instanceVBO = gl.GetVBO(GL.ARRAY_BUFFER, true)
	instanceVBO:Define(MAX_SLOTS, INSTANCE_LAYOUT)
	cornerVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	cornerVBO:Define(4, {{id = 0, name = 'corner', size = 2}})
	cornerVBO:Upload({-1, 1, -1, -1, 1, 1, 1, -1})
	iconVAO = makeVAOandAttach(cornerVBO, instanceVBO)
	radarVBO = gl.GetVBO(GL.SHADER_STORAGE_BUFFER, true)
	radarVBO:Define(MAX_SLOTS, {{id = 0, name = 'radarPos'}}) -- one vec4 per element
	local selection = Spring.GetSelectedUnits()
	for i = 1, #selection do
		selectedUnits[selection[i]] = true
	end
	SetEngineIconMode()
	RefreshAll()
end

function widget:Shutdown()
	Spring.SetConfigInt("LuaRadarIcons", 0, true)
	if iconVAO then
		iconVAO:Delete()
		instanceVBO:Delete()
		cornerVBO:Delete()
		radarVBO:Delete()
	end
	if iconShader then
		iconShader:Finalize()
	end
	if minimapShader then
		minimapShader:Finalize()
	end
end
