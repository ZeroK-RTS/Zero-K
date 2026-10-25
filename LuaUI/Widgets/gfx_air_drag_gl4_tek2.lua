local widget = widget

function widget:GetInfo()
	return {
		name      = "TEK2 Wing Drag GL4",
		desc      = "GPU-expanded lDrag/rDrag ribbons; Lua only samples wingtip history",
		author    = "OpenAI / TEK2, GoogleFrog",
		date      = "2026-08-29",
		license   = "GPL-2.0-or-later",
		layer     = 5,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------

-- Keep the same visual cadence/history as the accepted wingDrag version.
local TRAIL_UPDATE_RATE      = 1 / 20
local VISIBLE_REFRESH_RATE   = 0.25
local TRAIL_SAMPLE_RATE      = 0.070
local MAX_TRAIL_POINTS       = 20

-- GPU input vertices. Each trail segment is only TWO input vertices.
-- Geometry shader expands those 2 vertices into the 4-vertex ribbon quad.
local MAX_INPUT_VERTICES     = 40000

-- Distance LOD
local LOD_NEAR_DIST          = 1600
local LOD_MID_DIST           = 3200
local LOD_FAR_DIST           = 5000
local LOD_NEAR_DIST_SQ       = LOD_NEAR_DIST * LOD_NEAR_DIST
local LOD_MID_DIST_SQ        = LOD_MID_DIST  * LOD_MID_DIST
local LOD_FAR_DIST_SQ        = LOD_FAR_DIST  * LOD_FAR_DIST

local TRAIL_MIN_SPEED_RATIO  = 0.42
local TRAIL_FULL_SPEED_RATIO = 0.85
local TRAIL_MIN_ALTITUDE     = 16

local airDragDefs = VFS.Include("LuaUI/Configs/air_drag_defs.lua")

--------------------------------------------------------------------------------
-- LOCALS
--------------------------------------------------------------------------------

local spGetVisibleUnits      = Spring.GetVisibleUnits
local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitPieceMap      = Spring.GetUnitPieceMap
local spGetUnitPiecePosDir   = Spring.GetUnitPiecePosDir
local spGetUnitVelocity      = Spring.GetUnitVelocity
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetGroundHeight      = Spring.GetGroundHeight
local spGetGameSecondsInterp = Spring.GetGameSecondsInterpolated
local spGetCameraPosition    = Spring.GetCameraPosition

local mathMax     = math.max
local mathMin     = math.min
local mathSqrt    = math.sqrt
local stringLower = string.lower
local tonumber    = tonumber
local tostring    = tostring
local pairs       = pairs
local osClock     = os.clock
local tableRemove = table.remove

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = gl.LuaShader
if not LuaShader then
	LuaShader = VFS.Include(luaShaderDir .. "LuaShader.lua")
end
local luaShaderSource = gl.LuaShader and "gl.LuaShader" or (luaShaderDir .. "LuaShader.lua")

local tracked = {}
local visible = {}

local lastVisibleRefreshWall = -100
local lastTrailBuildWall     = -100

local trailVBO, trailVAO
local shader
local gameTimeUniform
local trailVertexCount = 0

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function Clamp(x, lo, hi)
	if x < lo then
		return lo
	end
	if x > hi then
		return hi
	end
	return x
end

local function Saturate(x)
	return Clamp(x, 0, 1)
end

local function Length3(x, y, z)
	return mathSqrt(x*x + y*y + z*z)
end

local function GetPiecePos(unitID, pieceID)
	if not pieceID then
		return
	end
	local x, y, z = spGetUnitPiecePosDir(unitID, pieceID)
	if not x then
		return
	end
	return x, y, z
end

--------------------------------------------------------------------------------
-- UNIT REGISTRATION
--------------------------------------------------------------------------------

local function RegisterUnit(unitID, unitDefID)
	if not (unitDefID and airDragDefs[unitDefID]) then
		tracked[unitID] = nil
		return false
	end

	Spring.Utilities.UnitEcho(unitID, "tracked")
	local pieceMap = spGetUnitPieceMap(unitID)
	if not pieceMap then
		return false
	end

	local def = airDragDefs[unitDefID]
	local emitPieces = {}
	for i = 1, #def.emitPieces do
		emitPieces[i] = pieceMap[def.emitPieces[i]]
		Spring.Echo(emitPieces[i])
	end

	local positions = {}
	for i = 1, #emitPieces do
		positions[i] = {}
	end

	tracked[unitID] = {
		unitDefID = unitDefID,
		color = def.color,
		maxSpeed = def.maxSpeed,
		emitPieces = emitPieces,

		trailWidth   = def.trailWidth,
		trailAlpha   = def.trailAlpha,
		trailSeconds = def.trailSeconds,

		positions = positions,
		lastTrailSample = -100,
		lastSeen = -100,
	}

	return true
end

local function RefreshVisible(nowGame, nowWall)
	local units = spGetVisibleUnits(-1, nil, false) or {}
	local newVisible = {}

	for i = 1, #units do
		local unitID = units[i]
		local unitDefID = spGetUnitDefID(unitID)

		if unitDefID then
			if not tracked[unitID] or tracked[unitID].unitDefID ~= unitDefID then
				RegisterUnit(unitID, unitDefID)
			end
			if tracked[unitID] then
				newVisible[unitID] = true
				tracked[unitID].lastSeen = nowGame
			end
		end
	end

	-- Clear history when an aircraft leaves visible rendering/LOS.
	-- Prevents stale giant reconnect lines and avoids leaking hidden movement.
	for unitID, data in pairs(tracked) do
		if not newVisible[unitID] then
			for i = 1, #data.positions do
				data.positions[i] = {}
			end
			data.lastTrailSample = -100
		end
	end

	visible = newVisible
	lastVisibleRefreshWall = nowWall
end

--------------------------------------------------------------------------------
-- TRAIL HISTORY
--------------------------------------------------------------------------------

local function PushTrailPoint(history, now, x, y, z, strength)
	if not x then return end

	local n = #history

	if n > 0 then
		local last = history[n]
		local dx, dy, dz = x-last.x, y-last.y, z-last.z

		-- Same duplicate-point suppression as the accepted version.
		if dx*dx + dy*dy + dz*dz < 0.20 then
			last.t = now
			last.strength = strength
			return
		end
	end

	history[n + 1] = {
		x = x,
		y = y,
		z = z,
		t = now,
		strength = strength,
	}

	while #history > MAX_TRAIL_POINTS do
		tableRemove(history, 1)
	end
end

local function PruneTrail(history, now, life)
	while #history > 0 and (now - history[1].t) > life do
		tableRemove(history, 1)
	end
end

--------------------------------------------------------------------------------
-- GPU INPUT BUFFER
--------------------------------------------------------------------------------

-- Only endpoints are uploaded.
--
-- position : xyz
-- params   : timestamp, strength, baseWidth, lifetime
-- color    : rgb, trailAlpha
--
-- Old backend:
--   Lua calculated ribbon side + width + 6 triangle vertices per segment.
--
-- New backend:
--   Lua uploads 2 endpoint vertices.
--   Geometry shader calculates camera-facing ribbon + width and emits 4 vertices.
local VBO_LAYOUT = {
	{ id = 0, name = "position", size = 3 },
	{ id = 1, name = "params",   size = 4 },
	{ id = 2, name = "color",    size = 4 },
}

local function AppendTrailVertex(out, p, baseWidth, life, color, trailAlpha)
	local n = #out

	out[n + 1]  = p.x
	out[n + 2]  = p.y
	out[n + 3]  = p.z

	out[n + 4]  = p.t
	out[n + 5]  = p.strength or 1
	out[n + 6]  = baseWidth
	out[n + 7]  = life

	out[n + 8]  = color[1]
	out[n + 9]  = color[2]
	out[n + 10] = color[3]
	out[n + 11] = trailAlpha
end

local function AddTrailHistoryGPU(out, vertexCount, unitData, history, stride)
	local n = #history
	if n < 2 then
		return vertexCount
	end
	stride = stride or 1

	local life = unitData.trailSeconds
	local baseWidth = 1.20 * unitData.trailWidth
	local trailColor = unitData.color
	local trailAlpha = unitData.trailAlpha

	for i = 1, n - 1, stride do
		if vertexCount + 2 > MAX_INPUT_VERTICES then
			break
		end
		local p0 = history[i]
		local p1 = history[mathMin(i + stride, n)]
		AppendTrailVertex(out, p0, baseWidth, life, trailColor, trailAlpha)
		AppendTrailVertex(out, p1, baseWidth, life, trailColor, trailAlpha)
		vertexCount = vertexCount + 2
	end
	return vertexCount
end

--------------------------------------------------------------------------------
-- HISTORY UPDATE + SMALL GPU BUFFER BUILD
--------------------------------------------------------------------------------

local function BuildTrailPointBuffer(now, nowWall)
	if nowWall - lastVisibleRefreshWall >= VISIBLE_REFRESH_RATE then
		RefreshVisible(now, nowWall)
	end

	local trailData = {}
	local tCount = 0

	local camX, camY, camZ = spGetCameraPosition()
	if not camX then
		trailVertexCount = 0
		return
	end

	for unitID in pairs(visible) do
		local data = tracked[unitID]
		if data then
			local ux, uy, uz = spGetUnitPosition(unitID)
			if ux then
				local cdx, cdy, cdz = ux-camX, uy-camY, uz-camZ
				local distSq = cdx*cdx + cdy*cdy + cdz*cdz

				if distSq <= LOD_FAR_DIST_SQ then
					local trailStride
					local trailSampleMul

					if distSq <= LOD_NEAR_DIST_SQ then
						trailStride, trailSampleMul = 1, 1.0
					elseif distSq <= LOD_MID_DIST_SQ then
						trailStride, trailSampleMul = 2, 1.55
					else
						trailStride, trailSampleMul = 3, 2.3
					end

					local vx, vy, vz, speed = spGetUnitVelocity(unitID)
					vx, vy, vz = vx or 0, vy or 0, vz or 0
					speed = speed or Length3(vx, vy, vz)

					local speedRatio = Saturate((speed * 30) / mathMax(data.maxSpeed, 1))

					local groundY = spGetGroundHeight(ux, uz)
					local altitude = uy - groundY

					local trailStrength = Saturate(
						(speedRatio - TRAIL_MIN_SPEED_RATIO) /
						mathMax(TRAIL_FULL_SPEED_RATIO - TRAIL_MIN_SPEED_RATIO, 0.01)
					)

					local canTrail =
						altitude >= TRAIL_MIN_ALTITUDE and
						trailStrength > 0

					local sampleRate = TRAIL_SAMPLE_RATE * trailSampleMul

					if canTrail and (now - data.lastTrailSample) >= sampleRate then
						for i = 1, #data.emitPieces do
							local x, y, z = GetPiecePos(unitID, data.emitPieces[i])
							PushTrailPoint(data.positions[i], now, x, y, z, trailStrength)
						end
						data.lastTrailSample = now
					elseif not canTrail then
						data.lastTrailSample = now
					end

					for i = 1, #data.positions do
						PruneTrail(data.positions[i], now, data.trailSeconds)
						tCount = AddTrailHistoryGPU(
							trailData,
							tCount,
							data,
							data.positions[i],
							trailStride
						)
					end
				else
					for i = 1, #data.positions do
						if #data.positions[i] > 0 then
							data.positions[i] = {}
							data.lastTrailSample = now
						end
					end
				end
			end
		end
	end

	if tCount > 0 then
		trailVBO:Upload(trailData)
	end

	trailVertexCount = tCount
	lastTrailBuildWall = nowWall
end

--------------------------------------------------------------------------------
-- SHADERS
--------------------------------------------------------------------------------

local vertexShader = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack : require

layout(location = 0) in vec3 position;
layout(location = 1) in vec4 params;
layout(location = 2) in vec4 color;

out DataVS {
	vec3 worldPos;
	vec4 params;
	vec4 color;
} vOut;

void main()
{
	vOut.worldPos = position;
	vOut.params = params;
	vOut.color = color;

	// Geometry shader performs the actual world -> clip transform.
	gl_Position = vec4(position, 1.0);
}
]]

local geometryShader = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack : require

//__ENGINEUNIFORMBUFFERDEFS__

layout(lines) in;
layout(triangle_strip, max_vertices = 4) out;

uniform float gameTime;

in DataVS {
	vec3 worldPos;
	vec4 params;
	vec4 color;
} gIn[];

out DataGS {
	vec4 color;
	float side;
} gOut;

void EmitTrailVertex(vec3 p, float sideValue, vec4 colorValue)
{
	gOut.color = colorValue;
	gOut.side = sideValue;
	gl_Position = cameraViewProj * vec4(p, 1.0);
	EmitVertex();
}

void main()
{
	vec3 p0 = gIn[0].worldPos;
	vec3 p1 = gIn[1].worldPos;

	vec3 axis = p1 - p0;
	float axisLen = length(axis);

	if (axisLen < 0.001) {
		return;
	}

	axis /= axisLen;

	float life0 = max(gIn[0].params.w, 0.001);
	float life1 = max(gIn[1].params.w, 0.001);

	float age0 = clamp((gameTime - gIn[0].params.x) / life0, 0.0, 1.0);
	float age1 = clamp((gameTime - gIn[1].params.x) / life1, 0.0, 1.0);

	float baseWidth0 = gIn[0].params.z;
	float baseWidth1 = gIn[1].params.z;

	// EXACT same width curve as the accepted CPU ribbon.
	float width0 = baseWidth0 * (0.75 + age0 * 1.10);
	float width1 = baseWidth1 * (0.75 + age1 * 1.10);

	float fade0 = 1.0 - age0;
	float fade1 = 1.0 - age1;
	fade0 *= fade0;
	fade1 *= fade1;

	// EXACT same alpha before the fragment edge profile.
	float alpha0 =
		0.27 *
		gIn[0].color.a *
		fade0 *
		gIn[0].params.y;

	float alpha1 =
		0.27 *
		gIn[1].color.a *
		fade1 *
		gIn[1].params.y;

	vec3 mid = (p0 + p1) * 0.5;
	vec3 cameraPos = cameraViewInv[3].xyz;
	vec3 viewDir = cameraPos - mid;

	// Same ribbon-side math previously performed in Lua:
	// side = segment axis x camera direction.
	vec3 ribbonSide = cross(axis, viewDir);
	float sideLen = length(ribbonSide);

	// Same degeneracy fallback as the old backend.
	if (sideLen < 0.001) {
		ribbonSide = vec3(-axis.z, 0.0, axis.x);
		sideLen = length(ribbonSide);

		if (sideLen < 0.001) {
			ribbonSide = vec3(1.0, 0.0, 0.0);
			sideLen = 1.0;
		}
	}

	ribbonSide /= sideLen;

	vec3 h0 = ribbonSide * width0;
	vec3 h1 = ribbonSide * width1;

	vec3 l0 = p0 - h0;
	vec3 r0 = p0 + h0;
	vec3 l1 = p1 - h1;
	vec3 r1 = p1 + h1;

	vec4 c0 = vec4(gIn[0].color.rgb, alpha0);
	vec4 c1 = vec4(gIn[1].color.rgb, alpha1);

	EmitTrailVertex(l0, -1.0, c0);
	EmitTrailVertex(r0,  1.0, c0);
	EmitTrailVertex(l1, -1.0, c1);
	EmitTrailVertex(r1,  1.0, c1);
	EndPrimitive();
}
]]

local fragmentShader = [[
#version 420

in DataGS {
	vec4 color;
	float side;
} fIn;

out vec4 fragColor;

void main()
{
	// DO NOT CHANGE:
	// this is the accepted airDrag visual profile from the previous widget.
	float side = abs(fIn.side);
	float edge = clamp(1.0 - side, 0.0, 1.0);
	edge = pow(edge, 1.35);

	float alpha = fIn.color.a * edge * 0.92;

	if (alpha <= 0.002) {
		discard;
	}

	fragColor = vec4(fIn.color.rgb, alpha);
}
]]

--------------------------------------------------------------------------------
-- GL4 INIT
--------------------------------------------------------------------------------

local function InitGL4()
	if not LuaShader then
		Spring.Echo("[TEK2 Wing Drag GPU] LuaShader unavailable")
		return false
	end

	if LuaShader.isGeometryShaderSupported == false then
		Spring.Echo("[TEK2 Wing Drag GPU] geometry shaders unavailable on this renderer")
		return false
	end

	if not gl.GetVBO or not gl.GetVAO then
		Spring.Echo("[TEK2 Wing Drag GPU] VBO/VAO API unavailable")
		return false
	end

	if not LuaShader.GetEngineUniformBufferDefs then
		Spring.Echo("[TEK2 Wing Drag GPU] GetEngineUniformBufferDefs() missing")
		return false
	end

	Spring.Echo("[TEK2 Wing Drag GPU] LuaShader source: " .. tostring(luaShaderSource))

	local engineDefs = LuaShader.GetEngineUniformBufferDefs()
	geometryShader = geometryShader:gsub(
		"//__ENGINEUNIFORMBUFFERDEFS__",
		engineDefs
	)

	shader = LuaShader({
		vertex = vertexShader,
		geometry = geometryShader,
		fragment = fragmentShader,
		uniformFloat = {
			gameTime = 0,
		},
	}, "TEK2 Wing Drag GPU Ribbon")

	if not shader:Initialize() then
		Spring.Echo("[TEK2 Wing Drag GPU] shader compilation failed")
		shader = nil
		return false
	end

	gameTimeUniform = gl.GetUniformLocation(shader.shaderObj, "gameTime")

	trailVBO = gl.GetVBO(GL.ARRAY_BUFFER, true)
	if not trailVBO then
		Spring.Echo("[TEK2 Wing Drag GPU] failed to allocate VBO")
		return false
	end

	trailVBO:Define(MAX_INPUT_VERTICES, VBO_LAYOUT)

	trailVAO = gl.GetVAO()
	if not trailVAO then
		Spring.Echo("[TEK2 Wing Drag GPU] failed to allocate VAO")
		return false
	end

	trailVAO:AttachVertexBuffer(trailVBO)

	return true
end

--------------------------------------------------------------------------------
-- WIDGET CALL-INS
--------------------------------------------------------------------------------

function widget:Initialize()
	if not InitGL4() then
		widgetHandler:RemoveWidget(self)
		return
	end

	RefreshVisible(spGetGameSecondsInterp(), osClock())

	Spring.Echo(
		"[TEK2 Wing Drag GPU] enabled: 2 input verts/segment -> GPU ribbon expansion"
	)
	Spring.Echo(
		"[TEK2 Wing Drag GPU] visual profile preserved; sampling remains 20 Hz backend / 0.070s near"
	)
end

function widget:Shutdown()
	tracked = {}
	visible = {}

	if shader then
		shader:Finalize()
		shader = nil
	end

	if trailVBO then
		trailVBO:Delete()
		trailVBO = nil
	end

	trailVAO = nil
end

function widget:UnitDestroyed(unitID)
	tracked[unitID] = nil
	visible[unitID] = nil
end

function widget:UnitTaken(unitID)
	tracked[unitID] = nil
	visible[unitID] = nil
end

function widget:UnitGiven(unitID)
	tracked[unitID] = nil
	visible[unitID] = nil
end

function widget:DrawWorld()
	if not shader then return end

	local now = spGetGameSecondsInterp()
	local nowWall = osClock()

	if nowWall - lastTrailBuildWall >= TRAIL_UPDATE_RATE then
		BuildTrailPointBuffer(now, nowWall)
	end

	if trailVertexCount <= 0 then
		return
	end

	gl.DepthTest(true)
	gl.DepthMask(false)
	gl.Culling(false)
	gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)

	shader:Activate()

	if gameTimeUniform then
		gl.Uniform(gameTimeUniform, now)
	end

	-- TWO input vertices per segment.
	-- Geometry shader emits the camera-facing 4-vertex ribbon.
	trailVAO:DrawArrays(GL.LINES, trailVertexCount)

	shader:Deactivate()

	gl.Blending(false)
	gl.DepthMask(true)
	gl.DepthTest(false)
end

--------------------------------------------------------------------------------
-- OPTIONAL UNITDEF CUSTOM PARAMS
--
-- customParams = {
--     airenginefx     = 1,     -- master air FX switch (preserved behavior)
--     airdragfx       = 1,     -- enable lDrag/rDrag
--     airtrailwidth   = 1.0,   -- width multiplier
--     airtrailalpha   = 1.0,   -- alpha multiplier
--     airtrailseconds = 1.15,  -- lifetime 0.25 .. 3.0 sec
-- }
--------------------------------------------------------------------------------
