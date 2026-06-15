#version 430
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#extension GL_ARB_gpu_shader5 : require
#extension GL_ARB_shader_storage_buffer_object : require

// Full GS: takes one GL_LINES primitive (cable endpoints) and emits the cable
// ribbon. Uses GS invocations: each invocation runs main() with its own
// max_vertices budget, so we can:
//   invocation 0          → left tent slope  (ridge→ground, SEGMENTS+1 × 2 verts)
//   invocation 1          → right tent slope (ridge→ground, SEGMENTS+1 × 2 verts)
//   invocations 2..N-1    → one twig each (4 verts), conditional on a hash
// Splitting the cross-section into two single-sheet slopes (one per invocation)
// is what lets the full raised-ridge tent fit: each slope gets its own
// GL_MAX_GEOMETRY_OUTPUT_COMPONENTS budget, so neither busts the 1024 ceiling a
// single combined sheet (~100 verts) would.
// This sidesteps the per-program max_vertices limit and keeps the FS body
// unchanged.

layout (lines, invocations = 5) in;
// 46 verts/invocation fits the min-spec total-components budget once the
// per-vertex cableTangent varying is included (46 × 22 = 1012 ≤ 1024). The
// tent-slope invocations use the full 46 (= 23 boundaries × 2); twig
// invocations use 4.
layout (triangle_strip, max_vertices = 46) out;

uniform sampler2D heightmapTex;
uniform sampler2D infoTex;          // $info:los; same texture FS samples
uniform float ghostsEnabled;        // 1.0 = run coverage SSBO updates, 0.0 = bypass entirely

// Per-edge "have I been seen" bitmask. Bit `i` of `.x` is set when segment
// `i` of the cable in slot s has been in LOS at any point. Persistent across
// frames. Live edges atomicOr bits in; ghost edges atomicAnd them off when
// the player re-scouts the area (re-scout-clear pass).
//
// Slots are declared as uvec4 because Spring's VBO API requires vec4-aligned
// attributes; we only use `.x` and ignore `.yzw`.
layout (std430, binding = 6) coherent buffer cableCoverageBuffer {
	uvec4 cableCoverage[];
};

in DataVS {
	vec2 vsWorldXZ;
	vec3 vsCableData;
	vec4 vsGridData;
	flat int vsSlot;
} dataIn[];

// Block must match `in DataGS` in gfx_overdrive_cables.frag.glsl exactly.
// PACKING NOTE: `spawnAlongMain` is reused. For twig fragments (isBranch>0.5)
// it carries the twig's root-along distance (existing semantics, drives twig
// pulse animation). For main-ribbon fragments (isBranch<0.5) it carries the
// cable's len-per-segment so the FS can derive a per-segment bit index for
// the coverage SSBO. The two semantics are disjoint by isBranch so no conflict.
// BUDGET NOTE: `gridData` is a vec3 (was vec4 — the .z component was never read
// by the FS). Shrinking it reclaimed one component so `cableTangent` could be
// added without busting GL_MAX_GEOMETRY_OUTPUT_COMPONENTS' total budget: with
// the tangent the per-vertex count is 22 (incl. gl_Position), so max_vertices
// drops 50→46 to keep 46 × 22 = 1012 ≤ 1024 (min-spec).
out DataGS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 timeData;
	vec3 gridData;
	// Smooth per-vertex cable along-direction (3D). Linearly interpolated by
	// the rasteriser so the FS frame (perp3D/trueUp → cylinder normal) rotates
	// continuously across segment seams instead of stepping per-triangle (the
	// flat-shaded look the old dFdx reconstruction produced). Constant across
	// each cross-section (apex+outer share it) so it can't twist the tube.
	vec3 cableTangent;
	float spawnAlongMain;
	flat int gsSlot;
};

//__ENGINEUNIFORMBUFFERDEFS__

vec2 inverseMapSize = 1.0 / mapSize.xy;

float heightAtWorldPos(vec2 w) {
	const vec2 heightmaptexel = vec2(8.0, 8.0);
	w += vec2(-8.0, -8.0) * (w * inverseMapSize) + vec2(4.0, 4.0);
	vec2 uvhm = clamp(w, heightmaptexel, mapSize.xy - heightmaptexel);
	uvhm = uvhm * inverseMapSize;
	return textureLod(heightmapTex, uvhm, 0.0).x;
}

// Terrain normal at a world XZ point via 4-tap finite-difference of the
// heightmap. Cheap (4 fetches) and good enough for placing twigs into the
// slope's local tangent plane.
vec3 terrainNormal(vec2 xz) {
	const float E = 8.0;
	float hxR = heightAtWorldPos(xz + vec2( E, 0.0));
	float hxL = heightAtWorldPos(xz + vec2(-E, 0.0));
	float hzU = heightAtWorldPos(xz + vec2(0.0,  E));
	float hzD = heightAtWorldPos(xz + vec2(0.0, -E));
	return normalize(vec3(hxL - hxR, 2.0 * E, hzD - hzU));
}

// Mirror of Lua-side Hash() / NoisyPath() so cables look exactly like before.
float gsHash(float x, float z, float seed) {
	return fract(sin(x * 12.9898 + z * 78.233 + seed * 43.17) * 43758.5453) * 2.0 - 1.0;
}
float gsHashU(float x, float z, float seed) {  // [0,1] variant
	return (gsHash(x, z, seed) + 1.0) * 0.5;
}
float gsNoiseScale(float t) {
	if (t < 0.1) return t / 0.1;
	if (t > 0.9) return (1.0 - t) / 0.1;
	return 1.0;
}
float hash1(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

const int   MAX_SEGMENTS      = 22;   // hardware budget (max_vertices=46 → 23 boundaries × 2; lowered from 24 to make room for the cableTangent varying). Cable lengths are bounded by pylon range (longest ≈ energypylon's 500 elmo); at SEG_LEN_TARGET this wants ~23, so the very longest backbone cables lose ~1-2 segments — far outweighed by the tangent killing the per-segment faceting.
const float SEG_LEN_TARGET    = 22.0; // elmos of 3D arc per segment
const float NOISE_AMP_ABS     = 4.0;
const float WIDTH_FACTOR      = 0.6;
// Tent cross-section: ridge height above the two ground edges, as a fraction of
// halfW (the cross "radius"). The two slopes meet at the ridge. This is now the
// DIRECT visible ridge height (built from the edge midpoint, not the buried
// belly), so the knob is linear: 0.0 collapses to a flat ribbon, 1.0 ≈ a full
// semicircular tube. ~0.7 reproduces the apparent tube height of the old
// belly-based formula (which lost ~SIDE_CLEAR to the edge-vs-belly offset).
const float TENT_HEIGHT_FACTOR = 0.45;
const float MIN_TRUNK_WIDTH   = 2.2;
const float MAX_TRUNK_WIDTH   = 4.2;
const float MAX_CAPACITY_REF  = 200.0;

// Adaptive vertex placement (slope-aware tessellation). We oversample the
// rendered centerline profile this many times the emit budget, then EMIT a
// curvature-clustered subset of those samples — so the same numSeg vertices
// land densely where the cable bends and sparsely where it ramps, instead of
// uniformly. KINK_GAIN is the weight added to a grid cell per elmo of |Δslope|
// (second difference of the profile); higher = tighter clustering at kinks.
const int   PLACEMENT_OVERSAMPLE = 2;
const int   MAX_GRID             = MAX_SEGMENTS * 2;   // local-array bound for the scan
const float KINK_GAIN            = 0.15;

// Twig parameters mirror the Lua-side BRANCH_* constants.
const float BRANCH_CHANCE     = 0.85;
const float BRANCH_LEN_MIN    = 6.0;
const float BRANCH_LEN_MAX    = 8.0;
const float BRANCH_ANGLE_MIN  = 1.2;
const float BRANCH_ANGLE_MAX  = 1.5;
const float BRANCH_WIDTH      = 2.1;
const float CONE_TIP_WIDTH    = 0.0;
const float BRANCH_WIDTH_TWIG_LENGTH_FACTOR = 2.0;

// Clearance over the heightmap, applied along the cable's chord-averaged surface
// normal Navg (the same axis the tent apex uses) rather than global +Y, so on a
// slope it's measured perpendicular to the surface and the cable hugs the incline
// instead of being shunted out along +Y. The old Y-only push made the off-ground
// gap read much larger on slopes than the nominal pad.
// CENTERLINE_CLEAR is added on top of the max-of-window lift along Navg. At 0.0
// the centerline sits exactly on the windowed terrain max, so the belly is held
// off the ground solely by SIDE_CLEAR (the outer-edge anti-underground clamp) —
// ~0.4 on flat ground, and the only margin left on slopes. TWIG_CLEAR keeps the
// twig root just under that lifted belly so the junction stays seated without
// z-fighting. SIDE_CLEAR catches concave cross-slopes where the slope-tangent
// offset would otherwise place the side vertex below local terrain.
const float CENTERLINE_CLEAR  = 0.0;
const float TWIG_CLEAR        = 0.3;
const float SIDE_CLEAR        = 0.4;

float gOutBranch    = 0.0;
// gOutSpawnAlong is overloaded (see DataGS comment): for main-ribbon emits
// (gOutBranch=0) it carries len-per-segment; for twig emits (gOutBranch=1)
// it carries the twig's root-along distance.
float gOutSpawnAlong = 0.0;
int   gOutSlot       = -1;

void emitVtx(vec3 wp, vec3 tangent3D, vec2 cuv,
             float w, vec4 grid, vec2 td, float cap) {
	worldPos = wp;
	capacity = cap;
	isBranch = gOutBranch;
	width = w;
	cableUV = cuv;
	timeData = td;
	gridData = grid.xyw;          // .z dropped (unused by FS); see DataGS BUDGET NOTE
	cableTangent = tangent3D;     // smooth along-dir → FS interpolates the lit frame
	spawnAlongMain = gOutSpawnAlong;
	gsSlot = gOutSlot;
#ifdef SHADOW_PASS
	// Recoil shadow-map convention (mirrors cus_gl4.vert.glsl's shadow pass):
	// it is NOT shadowViewProj * world. shadowView maps to a recentred space
	// that needs +0.5 on XY before shadowProj; the precombined shadowViewProj
	// omits that offset, which shoved the cable out of the shadow frustum.
	vec4 lightVertexPos = shadowView * vec4(wp, 1.0);
	lightVertexPos.xy += vec2(0.5);
	lightVertexPos.z += 5e-5;            // small constant depth bias (acne)
	gl_Position = shadowProj * lightVertexPos;
#else
	gl_Position = cameraViewProj * vec4(wp, 1.0);
#endif
	EmitVertex();
}

// Arc-bias parameters: at each point along the cable, probe the heightmap
// sideways and pull the centerline toward the lower-elevation side. The
// per-point lateral budget shrinks tent-style toward the endpoints, so the
// path is anchored at the pylons and free in the middle — worst case the
// whole cable forms a smooth arc. Adds *on top of* the existing high-frequency
// wiggle (which gives bark/seam variation), so the result is "arched chord
// with bark wiggle" rather than either alone.
const float ARC_PROBE_DIST   = 35.0;   // elmos to each side for the slope probe
const float ARC_MAX_DEV_FRAC = 0.18;   // midpoint cap = ARC_MAX_DEV_FRAC * lenAB
const float ARC_DH_SAT       = 6.0;    // probe Δheight (elmos) at which pull saturates to maxDev
const float ARC_MIN_LEN      = 80.0;   // shorter cables: skip arc bias entirely

// Computes ONE cable-global pull direction by averaging dh probes at 5
// anchor points along the chord. Computed once per cable in main() and
// reused for all segments and twigs.
//
// Why averaging instead of per-t probing:
// Probing dh at *each* segment t evaluates a fresh terrain feature at the
// chord position, so the pull direction can flip between adjacent segments
// — the cable then 90°-zigzags through the terrain. A single global dh
// (signed mean across the chord) produces a monotonic arc: the whole cable
// bends in one direction, magnitude shaped by the tent envelope. Micro
// wiggles still come from the existing high-frequency noise pass, so the
// "still perturbed for micro wiggles" property is preserved.
float cableArcDh(vec2 a, vec2 d, vec2 perpAB, float lenAB) {
	if (lenAB <= ARC_MIN_LEN) return 0.0;
	float dhSum = 0.0;
	for (int j = 0; j < 5; j++) {
		float tj = (float(j) + 0.5) * (1.0 / 5.0);   // 0.1, 0.3, 0.5, 0.7, 0.9
		vec2 mj = a + d * tj;
		float hL = heightAtWorldPos(mj - perpAB * ARC_PROBE_DIST);
		float hR = heightAtWorldPos(mj + perpAB * ARC_PROBE_DIST);
		dhSum += (hR - hL);
	}
	return dhSum * (1.0 / 5.0);
}

// Returns the arc-biased centerline point at parameter t along the chord.
// `dh` is the cable-global signed pull magnitude from cableArcDh().
//
// Pull saturation: rather than a linear gain (which left visibly steep
// terrain only weakly arched, then reverted to chord beyond budget), we
// smoothstep from 0 to maxDev as |dh| grows from 0 → ARC_DH_SAT. So as
// soon as there's any meaningful slope, the cable commits to the maximum
// allowed lateral deviation — it goes "as far around the hill as the
// arc budget permits" rather than reverting to the steep chord.
vec2 arcBiasedCenter(vec2 a, vec2 d, vec2 perpAB, float t, float lenAB, float dh) {
	vec2 base = a + d * t;
	if (lenAB <= ARC_MIN_LEN) return base;
	float tent = 4.0 * t * (1.0 - t);
	float maxDev = lenAB * ARC_MAX_DEV_FRAC * tent;
	float pull = sign(dh) * maxDev * smoothstep(0.0, ARC_DH_SAT, abs(dh));
	// dh>0 (right higher) → pull base toward left = -perpAB * |pull|.
	return base - perpAB * pull;
}

// Wiggly cable point at chord parameter t — arc-biased centerline plus
// high-frequency noise. Used by both main ribbon (per-segment) and twig
// emitter (at spawn) so they sit on the same path.
//
// `perpCanon` orients the noise offset to a chord-direction-independent
// half-plane so the wiggle hits the same world position regardless of
// which endpoint is treated as "a". `arcBiasedCenter` is already
// direction-symmetric on its own (perpAB and dh both flip together).
vec2 wigglyCablePoint(vec2 a, vec2 d, vec2 perpAB, float t, float lenAB,
                      float arcDh, float effAmp, float seed) {
	vec2 base = arcBiasedCenter(a, d, perpAB, t, lenAB, arcDh);
	float n = gsHash(base.x * 0.1, base.y * 0.1, seed) * effAmp * gsNoiseScale(t);
	vec2 perpCanon = perpAB;
	if (perpCanon.x < 0.0 || (perpCanon.x == 0.0 && perpCanon.y < 0.0)) {
		perpCanon = -perpCanon;
	}
	return base + perpCanon * n;
}

// Lift y to the max heightmap value sampled within ±fullStep along dirH.
// Linear interpolation between adjacent segment vertices can dip below
// terrain on convex/rolling slopes — taking the max within a window that
// covers the next vertex's position guarantees adjacent envelopes overlap
// at the segment midpoint, so the rendered ribbon stays above any peak in
// the gap. Used by the main ribbon (centerline lift) and twig emitter
// (spawn point lift) so they share the same vertical anchor.
float maxHeightInWindow(vec2 p, vec2 dirH, float fullStep) {
	float yMax = heightAtWorldPos(p);
	yMax = max(yMax, heightAtWorldPos(p + dirH * (fullStep * 0.30)));
	yMax = max(yMax, heightAtWorldPos(p - dirH * (fullStep * 0.30)));
	yMax = max(yMax, heightAtWorldPos(p + dirH * (fullStep * 0.55)));
	yMax = max(yMax, heightAtWorldPos(p - dirH * (fullStep * 0.55)));
	yMax = max(yMax, heightAtWorldPos(p + dirH * (fullStep * 0.85)));
	yMax = max(yMax, heightAtWorldPos(p - dirH * (fullStep * 0.85)));
	return yMax;
}

// Adaptive vertex placement, factored out so the twig emitter can replay the
// EXACT vertex set the ribbon renders and root onto it. Scans the max-filtered
// centerline profile on a grid PLACEMENT_OVERSAMPLE× denser than the emit
// budget, then curvature-clusters a numSeg+1 subset (dense at slope kinks,
// sparse on ramps). Reports each emitted vertex's grid index, base terrain
// height, and accumulated 3D along-distance; returns the grid resolution G.
//
// CRUCIAL: both emitTentHalf and the twig dispatch call this, so a twig snaps to
// a vertex the ribbon ACTUALLY emits. The old twig code snapped to the raw scan
// grid, but the ribbon only renders a clustered SUBSET of that grid — so on
// smooth-but-wiggly stretches (where clustering pulls vertices away to spend on
// kinks) the twig rooted on the analytical wiggle while the ribbon drew a coarse
// chord beneath it, leaving the root floating up to a full wiggle amplitude
// (~NOISE_AMP_ABS elmos) off the rendered surface.
int placeRibbonVertices(vec2 a, vec2 d, vec2 perpAB, float lenAB, float arcDh,
                        float effAmp, float seed, int numSeg,
                        out int   idxArr[MAX_SEGMENTS + 1],
                        out float yBaseArr[MAX_SEGMENTS + 1],
                        out float alongArr[MAX_SEGMENTS + 1]) {
	vec2  dirH     = (lenAB > 0.0) ? d / lenAB : vec2(1.0, 0.0);
	float fullStep = lenAB / float(numSeg);   // max-filter window ~ avg emit span
	int   G        = clamp(PLACEMENT_OVERSAMPLE * numSeg, 1, MAX_GRID);

	// Profile scan: max-filtered terrain height along the cable path. Its second
	// difference (below) is the along-cable curvature — directional by
	// construction (crossing a ridge spikes it, running along a crest does not).
	float yCgrid[MAX_GRID + 1];
	for (int i = 0; i <= G; i++) {
		float tg = float(i) / float(G);
		vec2 pg = wigglyCablePoint(a, d, perpAB, tg, lenAB, arcDh, effAmp, seed);
		yCgrid[i] = maxHeightInWindow(pg, dirH, fullStep);   // base terrain profile
	}

	// Per-cell importance = uniform floor (1.0, keeps flats at equal arc spacing)
	// + KINK_GAIN × |Δslope| averaged over the cell's endpoints. cum[] is the
	// prefix sum, so equal cumulative-weight steps cluster vertices at kinks.
	float cum[MAX_GRID + 1];
	cum[0] = 0.0;
	for (int i = 0; i < G; i++) {
		float sdL = (i   >= 1 && i   <= G - 1) ? abs(yCgrid[i-1] - 2.0*yCgrid[i]   + yCgrid[i+1]) : 0.0;
		float sdR = (i+1 >= 1 && i+1 <= G - 1) ? abs(yCgrid[i]   - 2.0*yCgrid[i+1] + yCgrid[i+2]) : 0.0;
		cum[i+1] = cum[i] + 1.0 + KINK_GAIN * 0.5 * (sdL + sdR);
	}
	float wStep = cum[G] / float(numSeg);

	int   gi       = 0;
	int   prevIdx  = -1;
	float along    = 0.0;
	vec3  prevBase = vec3(0.0);
	for (int k = 0; k <= numSeg; k++) {
		// Pick the grid index whose cumulative weight is nearest k·wStep. gi and k
		// both advance monotonically → one linear sweep. The max(prevIdx+1) guard
		// forces strictly increasing indices so a single very sharp cell can't
		// swallow two targets into a degenerate vertex.
		float target = float(k) * wStep;
		while (gi < G && cum[gi+1] < target) gi++;
		int idx = gi;
		if (gi < G && (target - cum[gi]) > (cum[gi+1] - target)) idx = gi + 1;
		idx = min(max(idx, prevIdx + 1), G);
		prevIdx = idx;

		// Accumulate 3D arc length over the emitted vertices. The clearance pad is
		// a uniform per-cable Navg shift, so it cancels in consecutive distances —
		// accumulating over the bare (xz, yBase) points matches emitTentHalf's
		// center3D-based accumulation exactly.
		vec2 p    = wigglyCablePoint(a, d, perpAB, float(idx) / float(G), lenAB, arcDh, effAmp, seed);
		vec3 base = vec3(p.x, yCgrid[idx], p.y);
		if (k > 0) along += distance(prevBase, base);
		prevBase = base;

		idxArr[k]   = idx;
		yBaseArr[k] = yCgrid[idx];
		alongArr[k] = along;
	}
	return G;
}

// Emit ONE slope of the cable's raised "tent" cross-section as a single
// triangle strip: from the outer ground edge (cableUV.y = side) up to the
// shared ridge apex at the centerline (cableUV.y = 0). `side` = -1 → left
// slope, +1 → right; the two are dispatched to separate GS invocations and
// meet watertight at the ridge. Per-slope cost == the old flat ribbon (2
// verts/boundary), so the full tent only costs one extra invocation.
void emitTentHalf(float side, vec2 a, vec2 d, vec2 perpAB,
                  float halfW, float widthVal, float effAmp, float seed,
                  vec4 gridD, vec2 timeD, float cap, int numSeg, float arcDh) {
	gOutBranch = 0.0;
	float tentHeight = halfW * TENT_HEIGHT_FACTOR;
	// `along` is fed into the FS as cableUV.x and drives bubble advection.
	// It MUST be a 3D arc length, otherwise downslope cables look like the
	// flow is racing because the same 2D Δalong covers more visible meters.
	float along = 0.0;
	vec3  prev3D = vec3(0.0);
	float lenAB = length(d);

	// Cross-section frame. The VERTICAL part — the apex lift and the clearance
	// pad — rides the chord-averaged surface normal Navg (computed once per
	// cable) so the tent hugs the slope and can't roll around its own axis
	// between segments. Navg is deliberately NOT per-vertex: building it from
	// terrainNormal(p) at each vertex made adjacent vertices disagree about
	// "up", twisting the ribbon into a corkscrew (the lighting was fine, the
	// geometry rolled).
	//
	// The TRANSVERSE (width) axis is per-vertex instead — see B_v in the loop.
	// It's the horizontal perpendicular of the LOCAL cable tangent, so the
	// cross-sections fan around the curve and the texture's transverse grain
	// follows the arc rather than staying welded to the straight chord (the old
	// global-B3 behaviour laid every row perpendicular to a→b, so an arced cable
	// just sheared the texture). This is NOT the old corkscrew source — that was
	// vertical ROLL from the terrain normal; cross(worldUp, tangent) has no roll
	// (worldUp is fixed), it only yaws to track the bend. It also matches the FS
	// lighting frame, which already derives perp3D = cross(worldUp, cableTangent),
	// so geometry and shading agree.
	vec3 Navg;
	{
		vec3 nAcc = vec3(0.0);
		for (int j = 0; j < 5; j++) {
			float tj = (float(j) + 0.5) * (1.0 / 5.0);
			nAcc += terrainNormal(a + d * tj);
		}
		Navg = normalize(nAcc);
	}
	vec3 cableDirH_g = normalize(vec3(d.x, 0.0, d.y));
	// Fallback width axis for the first vertex (chord tangent) and any vertex
	// whose local tangent degenerates: horizontal, perpendicular to the chord.
	vec3 B_fallback = normalize(cross(vec3(0.0, 1.0, 0.0), cableDirH_g));

	// Adaptive vertex placement, shared with the twig emitter (see
	// placeRibbonVertices) so twigs root on a vertex this ribbon actually emits.
	// Returns the emitted grid index, base height and 3D along-distance per
	// vertex; the loop below builds the cross-section frame from them.
	int   idxArr[MAX_SEGMENTS + 1];
	float yBaseArr[MAX_SEGMENTS + 1];
	float alongArr[MAX_SEGMENTS + 1];
	int   G = placeRibbonVertices(a, d, perpAB, lenAB, arcDh, effAmp, seed, numSeg,
	                              idxArr, yBaseArr, alongArr);

	for (int k = 0; k <= numSeg; k++) {
		float t = float(idxArr[k]) / float(G);
		vec2  p = wigglyCablePoint(a, d, perpAB, t, lenAB, arcDh, effAmp, seed);
		along   = alongArr[k];                  // 3D arc length from placeRibbonVertices
		// Clearance pad along Navg (chord-averaged surface normal, the same axis the
		// tent apex uses) instead of global +Y, so on a slope the gap stays
		// perpendicular to the surface and the cable hugs the incline. Navg is
		// constant per-cable → a uniform offset that leaves the curvature-based
		// tessellation and the apex/outer frame relationships intact.
		vec3 center3D = vec3(p.x, yBaseArr[k], p.y) + Navg * CENTERLINE_CLEAR;

		// Per-vertex cable along-direction: chord at the first vertex, back-diff of
		// adjacent centerline points after. This single tangent is BOTH the
		// lighting tangent handed to the FS (emitted below) AND the axis the
		// cross-section is built on, so width, texture and shading all agree.
		vec3 vtxTangent;
		if (k == 0) {
			vtxTangent = cableDirH_g;
		} else {
			vtxTangent = center3D - prev3D;
			float vtL = length(vtxTangent);
			vtxTangent = (vtL > 1e-4) ? vtxTangent / vtL : cableDirH_g;
		}

		// Transverse (width) axis: horizontal perpendicular of the LOCAL tangent,
		// so cross-sections fan around the curve instead of staying chord-locked.
		// cross(worldUp, tangent) drops the tangent's vertical part → purely
		// horizontal, and is the SAME vector the FS lights with (perp3D). Both
		// tent invocations compute it identically from the shared path, so the
		// ridge stays watertight.
		vec3 B_v = cross(vec3(0.0, 1.0, 0.0), vtxTangent);
		float bvL = length(B_v);
		B_v = (bvL > 1e-3) ? B_v / bvL : B_fallback;

		// Tent cross-section. Both ground edges along B_v; we emit only the one on
		// `side` this invocation, but compute both so the ridge guard below is
		// identical in both slopes. Anti-underground clamp (concave cross-slope can
		// push an edge below the heightmap) is unchanged from the flat ribbon.
		vec3 outerL = center3D - B_v * halfW;
		outerL.y = max(outerL.y, heightAtWorldPos(outerL.xz) + SIDE_CLEAR);
		vec3 outerR = center3D + B_v * halfW;
		outerR.y = max(outerR.y, heightAtWorldPos(outerR.xz) + SIDE_CLEAR);
		vec3 outerPos = (side < 0.0) ? outerL : outerR;

		// Ridge apex: lift along Navg from the MIDPOINT of the two ground edges,
		// NOT from center3D. center3D sits on the windowed terrain max (the belly)
		// while the outer edges are independently held SIDE_CLEAR above local
		// terrain, so the pre-tent cross-section is a shallow valley — the edges
		// sit ~SIDE_CLEAR above the belly. Lifting from center3D meant FACTOR first
		// had to climb out of that valley before any ridge showed: the visible
		// ridge was max(tentHeight - SIDE_CLEAR, 0.1), so 0.0 still bulged (the
		// +0.1 floor never collapsed to flat ribbons) and the low end was squashed
		// (0.2 ≈ 0.4, both pinned near the floor). Building from the edge midpoint
		// makes the visible ridge exactly tentHeight = halfW * FACTOR: 0.0 is flat
		// and the knob reads linearly. (At equal FACTOR the tube is now ~SIDE_CLEAR
		// taller than before, so the TENT_HEIGHT_FACTOR default is retuned to match.)
		//
		// Lift is along Navg (the chord-averaged surface normal). The base axis B_v
		// is horizontal, so on a slope it isn't exactly orthogonal to Navg and the
		// cross-section area is only approximately slope-invariant — a negligible
		// shear at realistic cable inclines, and the apex still shares Navg with the
		// lift so it can't roll. edgeMid uses BOTH outer edges (identical in the
		// left and right invocations → watertight ridge) and its xz is the
		// centerline.
		vec3 edgeMid = 0.5 * (outerL + outerR);
		vec3 apexPos = edgeMid + Navg * tentHeight;
		// Anti-inversion only (no added floor, so FACTOR=0 stays flat): a concave
		// cross-slope can clamp one edge above edgeMid + lift, folding that half
		// under. max() pins the apex to the higher edge there instead of inverting.
		apexPos.y = max(apexPos.y, max(outerL.y, outerR.y));

		// vtxTangent (computed above) is interpolated across the triangle strip,
		// giving the FS a continuous along-direction so the cylinder normal bends
		// with up/down hills. The ribbon itself can't twist around its axis: both
		// cross-section vertices share one B_v, which has no roll component.
		// `along` is supplied per-vertex by placeRibbonVertices (same arc-length
		// integration), so the twig emitter can match it exactly at the junction.
		prev3D = center3D;
		// Strip order: apex (v=0, ridge — FS points the cylinder normal up) then
		// outer (v=side, ground — FS leans the normal fully sideways). The faked
		// cylinder normal now matches the real raised ridge instead of fighting a
		// flat strip, and both slopes share the apex line so they form one tube.
		emitVtx(apexPos,  vtxTangent, vec2(along, 0.0),  widthVal, gridD, timeD, cap);
		emitVtx(outerPos, vtxTangent, vec2(along, side), widthVal, gridD, timeD, cap);
	}
	EndPrimitive();
}

// Emit a small lateral twig at parametric position tCenter along the main
// (wiggly) cable, deterministic on the cable seed + tCenter so the same
// twigs appear every frame in the same place. Returns silently when the
// hash says "no twig here" — leaving an empty primitive, which is a no-op.
void emitTwig(vec2 a, vec2 d, vec2 perpAB,
              float halfMainW, float widthVal, float effAmp, float seed,
              vec4 gridD, vec2 timeD, float cap, float tCenter,
              float spawnAlongMain, int twigIdx, float arcDh, int numSeg) {
	// Resolve spawn point on the wiggly main path at tCenter so twigs root on
	// the visible cable.
	float lenAB = length(d);
	vec2 spawn = wigglyCablePoint(a, d, perpAB, tCenter, lenAB, arcDh, effAmp, seed);

	float twigSeed = spawn.x * 7.13 + spawn.y * 3.77;
	float chance = gsHashU(spawn.x, spawn.y, twigSeed);
	if (chance > BRANCH_CHANCE) return;

	// Side: STRICTLY alternate by twigIdx so neighbouring twigs along the
	// main cable land on opposite sides. Two same-side adjacent twigs flashing
	// in lockstep look like a single pulse "bouncing" — alternating sides
	// breaks that visual coupling. Angle is still hash-randomised below.
	// Multiply by perpAB parity to keep side stable when flow is reversed.
	float segParity = (((numSeg & 1) == 0) ? 1.0 : -1.0);
	float parity = (perpAB.y > 0.0 ? 1.0 : -1.0);
	if (segParity < 0.0 && parity < 0.0) {
		// There are an odd number of segments so we need to shift the index half the time
		twigIdx += 1;
	}
	float side = (((twigIdx & 1) == 0) ? 1.0 : -1.0) * parity * (chance > BRANCH_CHANCE*0.5 ? -1.0 : 1.0);
	
	float angleOff = BRANCH_ANGLE_MIN +
		gsHashU(spawn.x, spawn.y, twigSeed + 2.0) * (BRANCH_ANGLE_MAX - BRANCH_ANGLE_MIN);
	float bLen = BRANCH_LEN_MIN + widthVal*BRANCH_WIDTH_TWIG_LENGTH_FACTOR +
		gsHashU(spawn.x, spawn.y, twigSeed + 3.0) * (BRANCH_LEN_MAX - BRANCH_LEN_MIN);

	float twigW    = max(2.5, widthVal * BRANCH_WIDTH);
	float twigHWr  = min(twigW, widthVal * 0.55) * BRANCH_WIDTH;
	// Geometric cone taper at 0.45 — visible shape narrows toward the tip
	// (looks like a branch, not a tube). The WIDTH varying we pass to the FS
	// stays UNIFORM at `twigW` along the entire twig, so bubble math sees
	// constant halfWidthE and bubble radius/spacing don't change with along
	// position. The visible bubble naturally fits the tapered geometry: in v
	// space the bubble keeps the same cross-axis extent (relative to the
	// cable's UV cross), which projects to a smaller world-cross at the
	// thinner tip. At the very end the cable's `t > 0.9` cross discard clips
	// any bubble that runs off the tip. This decouples "bubble flow looks
	// uniform" from "twig has cone shape".
	float twigHWt  = twigHWr * CONE_TIP_WIDTH;

	// Build the twig as a flat ribbon in the slope's local tangent plane at
	// the spawn point. This way, viewing perpendicular to the slope, the twig
	// looks exactly like a flat-ground twig — no downhill tilt artefact.
	//
	// Basis: N = terrain normal at spawn; T = cable tangent projected into the
	// slope plane; B = N × T (in-slope perp to cable). Twig direction is
	// (cos(angleOff)*T + side*sin(angleOff)*B), and twigPerp3D = N × twigDir3D.
	vec3 N = terrainNormal(spawn);
	vec3 cableDirH = normalize(vec3(d.x, 0.0, d.y));
	vec3 T = normalize(cableDirH - dot(cableDirH, N) * N);
	vec3 B = normalize(cross(N, T));

	float ca = cos(angleOff);
	float sa = sin(angleOff) * side;
	vec3 twigDir3D  = ca * T + sa * B;
	vec3 twigPerp3D = normalize(cross(N, twigDir3D));

	// Anchor spawn to the same max-of-window lift the main ribbon uses, offset
	// along the local normal N — at this 0.3 magnitude N tracks the trunk's
	// chord-averaged Navg pad closely enough to keep the junction seated, and N
	// is already the twig's own basis. TWIG_CLEAR is slightly less than
	// CENTERLINE_CLEAR so the junction sits just under the trunk's centerline
	// (z-fight avoidance, see TWIG_CLEAR comment).
	vec2 dirH = (lenAB > 0.0) ? d / lenAB : vec2(1.0, 0.0);
	float fullStep = lenAB / float(numSeg);
	float spawnYbase = maxHeightInWindow(spawn, dirH, fullStep);
	vec3 spawn3D = vec3(spawn.x, spawnYbase, spawn.y) + N * TWIG_CLEAR;

	// Anchor the root to the spawn-side edge of the cable's in-slope cross
	// section so the twig pokes out of the side, not the midline.
	vec3 root3D = spawn3D + B * (halfMainW * 0.2 * side);
	vec3 tip3D  = root3D + twigDir3D * bLen;

	vec3 rootL = root3D - twigPerp3D * twigHWr;
	vec3 rootR = root3D + twigPerp3D * twigHWr;
	vec3 tipL  = tip3D  - twigPerp3D * twigHWt;
	vec3 tipR  = tip3D  + twigPerp3D * twigHWt;

	// cableUV.x carries the cable-wide along distance so the FS growth gate
	// hides this twig until the main growth front has reached spawnAlongMain.
	// vsTangent for twigs is the twigDir3D (the twig's along-direction); the
	// FS derives perp3D from cross(worldUp, vsTangent) so cylindrical lighting
	// follows the twig's pointing direction.
	gOutBranch = 1.0;
	gOutSpawnAlong = spawnAlongMain;   // shared by all 4 twig vertices; lets FS compute twig-local along
	emitVtx(rootL, twigDir3D, vec2(spawnAlongMain,        -1.0), twigW,        gridD, timeD, cap);
	emitVtx(rootR, twigDir3D, vec2(spawnAlongMain,         1.0), twigW,        gridD, timeD, cap);
	emitVtx(tipL,  twigDir3D, vec2(spawnAlongMain + bLen, -1.0), twigW, gridD, timeD, cap);
	EndPrimitive();
	gOutSpawnAlong = 0.0;
}

void main() {
	// IMPORTANT: parent/child orientation is gameplay info — the bubble
	// advection direction (driven by cableUV.x growing from a to b) signals
	// power flow, so we MUST keep the synced parent→child order. The wiggle
	// is made direction-independent below via a symmetric `seed`, which
	// prevents the live→ghost transition from teleporting the noise pattern
	// when MST reroutes flip parent/child while preserving the flow visual.
	vec2 a = dataIn[0].vsWorldXZ;
	vec2 b = dataIn[1].vsWorldXZ;
	vec2 d = b - a;
	float lenAB = length(d);
	if (lenAB < 0.5) return;
	vec2 dirAB  = d / lenAB;
	vec2 perpAB = vec2(-dirAB.y, dirAB.x);

	float cap   = dataIn[0].vsCableData.x;
	vec2  timeD = dataIn[0].vsCableData.yz;
	vec4  gridD = dataIn[0].vsGridData;

	// Ghost edges (gridData.w = -1.0) emit the same two tent slopes as live
	// (no twigs), using the SAME wiggly path so the live→ghost transition has
	// no visual snap. Ghost FS path is fast (no lighting/bubble math), and the
	// GS still skips the 3 twig invocations. Coverage updates use the live
	// atomicAnd path with the wiggly samples → consistent with what the player
	// visually sees.
	bool isGhostEdge = gridD.w < -0.5;
	if (isGhostEdge && gl_InvocationID > 1) return;

	float widthVal = MIN_TRUNK_WIDTH +
		clamp(cap / MAX_CAPACITY_REF, 0.0, 1.0) * (MAX_TRUNK_WIDTH - MIN_TRUNK_WIDTH);
	float halfW  = widthVal * WIDTH_FACTOR;
	float effAmp = NOISE_AMP_ABS * (lenAB < 80.0 ? (lenAB / 80.0) : 1.0);
	// Symmetric seed: same multiplier on both endpoints so reversing (a,b)
	// gives the same value. Keeps the wiggle stable across MST reroutes
	// that flip parent/child orientation. Direction-dependent visuals (flow
	// bubbles) are driven by cableUV.x which still respects the parent→child
	// order, so flow direction is unaffected.
	float seed   = (a.x + b.x) * 0.215 + (a.y + b.y) * 0.621;

	// Coarse 3D length: 6 sub-spans of the straight a→b path, summing the
	// terrain-aware Euclidean distance between samples. Slopes inflate len3D
	// versus lenAB, so hilly cables get more turns AND tighter 2D spacing per
	// segment (because each segment is len3D/numSeg in 3D arc, but spaced
	// uniformly in 2D parameter t). Noise wiggle is ignored here — keeping the
	// scan cheap matters more than a few % accuracy on segment count.
	//
	// Also tracks slope curvature: if the second derivative of height along
	// the chord is large (terrain undulates rather than ramps), bump segment
	// count further so the linear interpolation between vertices doesn't dip
	// underground between samples.
	float len3D = 0.0;
	float curv  = 0.0;
	{
		float h0 = heightAtWorldPos(a) + 2.0;
		vec3 prev3 = vec3(a.x, h0, a.y);
		float prevDy = 0.0;
		for (int j = 1; j <= 6; j++) {
			float tj = float(j) * (1.0 / 6.0);
			vec2 bj = a + d * tj;
			float hj = heightAtWorldPos(bj) + 2.0;
			vec3 p3 = vec3(bj.x, hj, bj.y);
			len3D += distance(p3, prev3);
			float dy = hj - prev3.y;
			if (j > 1) curv += abs(dy - prevDy);
			prevDy = dy;
			prev3 = p3;
		}
	}
	// Bump segment count by curvature: every 6 elmos of cumulative |Δslope|
	// adds one extra segment, capped at MAX_SEGMENTS.
	int baseSeg = int(len3D / SEG_LEN_TARGET + 0.5);
	int curvSeg = int(curv * (1.0 / 6.0));
	int numSeg = clamp(baseSeg + curvSeg, 1, MAX_SEGMENTS);

	// One global pull direction per cable: averaged dh across 5 chord anchors.
	// Per-segment probing was the source of zigzag — see cableArcDh comment.
	// Skipped for ghosts (10 heightmap probes) — they don't arc, so 0 is fine.
	float arcDh = isGhostEdge ? 0.0 : cableArcDh(a, d, perpAB, lenAB);

	gOutSlot       = dataIn[0].vsSlot;
	// Pack lenPerSeg into gOutSpawnAlong for the main-ribbon emit (twigs reset
	// it to their own value inside emitTwig). See DataGS comment for packing.
	gOutSpawnAlong = (numSeg > 0) ? (len3D / float(numSeg)) : 1.0;

	// Ghost and live cables emit the same ribbon shape so live→ghost has no
	// visual snap. Twig invocations already skipped above, and the FS takes
	// a fast path for ghost fragments (no lighting/bubble math), so cost is
	// bounded.

	if (gl_InvocationID == 0) {
		// Coverage SSBO update — once per cable per frame, not per fragment.
		// Live edges (gridData.w >= -0.5) atomicOr bits for segments currently
		// in LOS; ghost edges (gridData.w < -0.5) atomicAnd to clear bits the
		// player has re-scouted. Sampling along the actual wiggly path keeps
		// reveal accurate even with arc bias on slopes.
		//
		// Saturation skip: read once and bail out when there's nothing to do.
		// Live edges with all bits set will never get more bits → skip the
		// LOS scan entirely. Ghost edges with all bits clear have nothing
		// left to clear → skip too. Massive savings on long-running matches
		// where most live cables hit saturation quickly.
		//
		// Excluded from BOTH the shadow and deferred passes: the forward pass
		// owns coverage. The deferred draw binds nothing at binding=6, so a
		// stray atomicOr/atomicAnd there would hit an unbound buffer; and a
		// second per-frame update would risk double-clearing ghost bits.
#if !defined(SHADOW_PASS) && !defined(DEFERRED_PASS)
		int slot = dataIn[0].vsSlot;
		bool isGhost = gridD.w < -0.5;
		// Hard gate on the user-facing ghosts toggle — skip ALL coverage
		// bookkeeping (the n-tap LOS scan, atomic ops, even the SSBO read)
		// when ghosts are off. Restores live-only perf parity with pre-slice-1.
		if (slot >= 0 && ghostsEnabled >= 0.5) {
			int n = min(numSeg, 24);
			uint fullMask = (n >= 32) ? 0xFFFFFFFFu : ((1u << uint(n)) - 1u);
			uint cur = cableCoverage[slot].x;
			bool skip = isGhost ? (cur == 0u) : ((cur & fullMask) == fullMask);
			if (!skip) {
				uint setMask = 0u;
				uint clrMask = 0u;
				for (int i = 0; i < n; i++) {
					float t = (float(i) + 0.5) / float(numSeg);
					vec2 p = wigglyCablePoint(a, d, perpAB, t, lenAB, arcDh, effAmp, seed);
					vec2 losUV = clamp(p, vec2(0.0), mapSize.xy) / mapSize.zw;
					float los = texture(infoTex, losUV).r;
					if (los >= 0.5) {
						if (isGhost) clrMask |= (1u << uint(i));
						else         setMask |= (1u << uint(i));
					}
				}
				if (setMask != 0u) atomicOr (cableCoverage[slot].x,  setMask);
				if (clrMask != 0u) atomicAnd(cableCoverage[slot].x, ~clrMask);
			}
		}
#endif
		emitTentHalf(-1.0, a, d, perpAB, halfW, widthVal, effAmp, seed, gridD, timeD, cap, numSeg, arcDh);
	} else if (gl_InvocationID == 1) {
		// Right slope of the tent — its own invocation, hence its own
		// GL_MAX_GEOMETRY_OUTPUT_COMPONENTS budget. This is what lets the full
		// raised-ridge tent fit: one combined sheet (~100 verts) would bust the
		// 1024 ceiling, two single-sheet slopes (~50 each) don't.
		emitTentHalf(1.0, a, d, perpAB, halfW, widthVal, effAmp, seed, gridD, timeD, cap, numSeg, arcDh);
	} else {
		if (isGhostEdge) return;   // ghosts skip twig invocations entirely
		// Twig density scales with 3D arc length: ~one twig per 85 elmos. Twigs
		// live on invocations 2..4 (3 slots; invocation 1 is the second tent
		// slope), so cap to 3 and reindex from gl_InvocationID-2.
		int twigIdx = gl_InvocationID - 2;          // 0..2
		int expectedTwigs = clamp(int(len3D / 85.0 + 0.5), 0, 3);
		if (twigIdx >= expectedTwigs) return;
		float tCenterRaw = 0.15 + (float(twigIdx) + 0.5) * (0.7 / float(expectedTwigs));

		// Root the twig on a vertex the ribbon ACTUALLY emits. Replay the same
		// adaptive placement (placeRibbonVertices) and pick the emitted INTERIOR
		// vertex nearest tCenterRaw, then take ITS t (→ spawn position) and its
		// accumulated along (→ cableUV.x, matching the trunk exactly at the
		// junction). The old code snapped tCenter to the raw scan grid, but the
		// ribbon renders only a curvature-clustered SUBSET of that grid — so the
		// twig rooted on the analytical wiggle at a point the ribbon skipped,
		// leaving it floating up to a full wiggle amplitude off the chord surface.
		int   idxArr[MAX_SEGMENTS + 1];
		float yBaseArr[MAX_SEGMENTS + 1];
		float alongArr[MAX_SEGMENTS + 1];
		int   G = placeRibbonVertices(a, d, perpAB, lenAB, arcDh, effAmp, seed, numSeg,
		                              idxArr, yBaseArr, alongArr);
		// Skip the two endpoints (k = 0, numSeg) so a twig never roots at the
		// cable's start/end. expectedTwigs >= 1 implies numSeg >= 2, so there is
		// always at least one interior vertex to choose.
		int   bestK   = 1;
		float bestErr = 1e9;
		for (int k = 1; k <= numSeg - 1; k++) {
			float err = abs(float(idxArr[k]) / float(G) - tCenterRaw);
			if (err < bestErr) { bestErr = err; bestK = k; }
		}
		float tCenter        = float(idxArr[bestK]) / float(G);
		float spawnAlongMain = alongArr[bestK];
		emitTwig(a, d, perpAB, halfW, widthVal, effAmp, seed,
		         gridD, timeD, cap, tCenter, spawnAlongMain, twigIdx, arcDh, numSeg);
	}
}
#if !defined(SHADOW_PASS) && !defined(DEFERRED_PASS)
#endif
