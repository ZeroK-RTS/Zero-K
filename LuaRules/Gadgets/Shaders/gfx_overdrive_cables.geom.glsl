#version 430
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#extension GL_ARB_gpu_shader5 : require
#extension GL_ARB_shader_storage_buffer_object : require

// Full GS: takes one GL_LINES primitive (cable endpoints) and emits the cable
// ribbon. Uses GS invocations: each invocation runs main() with its own
// max_vertices budget, so we can:
//   invocation 0          → main wiggly ribbon (SEGMENTS+1 boundaries × 2 verts)
//   invocations 1..N-1    → one twig each (4 verts), conditional on a hash
// This sidesteps the per-program max_vertices limit and keeps the FS body
// unchanged.

layout (lines, invocations = 5) in;
// 50 verts/invocation comfortably fits min-spec total components budget;
// invocation 0 uses ~50, twig invocations use 4.
layout (triangle_strip, max_vertices = 50) out;

uniform sampler2D heightmapTex;
uniform sampler2D infoTex;          // $info:los; same texture FS samples

// Per-edge "have I been seen" bitmask. Bit `i` of `.x` is set when segment
// `i` of this cable is currently in LOS. Persistent across frames; never
// cleared in slice 1 (slice 3 will clear bits during the ghost pass when
// the player's LOS confirms the area is empty).
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
// gsLenPerSeg packed at the head of `cableUV` to avoid an extra varying:
// .x = along-elmos (existing), .y = cross [-1,1] (existing).
// Instead, pack lenPerSeg + slot into spawnAlongMain.zw — but that's vec2.
// Simpler: keep it as one float and check max-comp budget.
out DataGS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 timeData;
	vec4 gridData;
	float spawnAlongMain;
	flat int gsSlot;
	flat int gsNumSeg;
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

const int   MAX_SEGMENTS      = 24;   // hardware budget (max_vertices=50 → 25 boundaries × 2). Cable lengths are bounded by pylon range so this isn't expected to clamp in practice.
const float SEG_LEN_TARGET    = 22.0; // elmos of 3D arc per segment
const float NOISE_AMP_ABS     = 4.0;
const float WIDTH_FACTOR      = 0.55;
const float MIN_TRUNK_WIDTH   = 3.0;
const float MAX_TRUNK_WIDTH   = 12.0;
const float MAX_CAPACITY_REF  = 225.0; // one singu (energysingu.energyMake)

// Twig parameters mirror the Lua-side BRANCH_* constants.
const float BRANCH_CHANCE     = 0.78;
const float BRANCH_LEN_MIN    = 15.0;
const float BRANCH_LEN_MAX    = 50.0;
const float BRANCH_ANGLE_MIN  = 0.4;
const float BRANCH_ANGLE_MAX  = 1.1;
const float BRANCH_WIDTH      = 0.85;

// Vertical clearance over the heightmap. CENTERLINE_CLEAR is added on top of
// the max-of-window lift, so it doesn't need a big pad. TWIG_CLEAR is set
// 0.6 elmos below CENTERLINE_CLEAR so the twig sits just under the trunk's
// centerline at the junction (avoids z-fighting while staying visually
// attached). SIDE_CLEAR catches concave cross-slopes where the slope-tangent
// offset would otherwise place the side vertex below local terrain.
const float CENTERLINE_CLEAR  = 1.5;
const float TWIG_CLEAR        = 0.9;
const float SIDE_CLEAR        = 0.8;

float gOutBranch = 0.0;
float gOutSpawnAlong = 0.0;  // set by emitTwig per-twig; main ribbon leaves at 0.
int   gOutSlot       = -1;   // SSBO slot for this cable; carried into every emitVtx.
int   gOutNumSeg     = 0;    // segment count for this cable.
float gOutLenPerSeg  = 0.0;  // along-elmos per segment; FS divides cableUV.x by this to get segIdx.

void emitVtx(vec3 wp, vec3 tangent3D, vec2 cuv,
             float w, vec4 grid, vec2 td, float cap) {
	worldPos = wp;
	capacity = cap;
	isBranch = gOutBranch;
	width = w;
	cableUV = cuv;
	timeData = td;
	gridData = grid;
	spawnAlongMain = gOutSpawnAlong;
	gsSlot = gOutSlot;
	gsNumSeg = gOutNumSeg;
	// (vsTangent varying disabled — exceeded GS output budget on this hardware)
	gl_Position = cameraViewProj * vec4(wp, 1.0);
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
vec2 wigglyCablePoint(vec2 a, vec2 d, vec2 perpAB, float t, float lenAB,
                      float arcDh, float effAmp, float seed) {
	vec2 base = arcBiasedCenter(a, d, perpAB, t, lenAB, arcDh);
	float n = gsHash(base.x * 0.1, base.y * 0.1, seed) * effAmp * gsNoiseScale(t);
	return base + perpAB * n;
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

void emitMainRibbon(vec2 a, vec2 d, vec2 perpAB,
                    float halfW, float widthVal, float effAmp, float seed,
                    vec4 gridD, vec2 timeD, float cap, int numSeg, float arcDh) {
	gOutBranch = 0.0;
	// `along` is fed into the FS as cableUV.x and drives bubble advection.
	// It MUST be a 3D arc length, otherwise downslope cables look like the
	// flow is racing because the same 2D Δalong covers more visible meters.
	float along = 0.0;
	vec3  prev3D = vec3(0.0);
	float lenAB = length(d);

	// Cross-section basis — computed ONCE for the whole cable. Earlier we built
	// N/T3/B3 per-vertex from `terrainNormal(p)`. That made adjacent vertices
	// disagree about which way is "+B3" whenever the local terrain normal
	// rotated between them (rolling terrain, hilltops, cross-slope crossings).
	// Adjacent vertices' left/right edges then sat at slightly different
	// rotational positions around the cable axis, so the ribbon physically
	// twisted between them — visible as a corkscrew. The lighting was already
	// correct; the geometry was twisted.
	//
	// Anchoring the basis to a chord-averaged Navg gives every vertex the SAME
	// "+B3" direction. Per-vertex slope tilt still happens via the side-clamp
	// (each side vertex independently lifted to local terrain+clearance), so
	// the ribbon still appears to follow the slope — it just can't rotate
	// around its own axis between segments.
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
	vec3 T3_g = cableDirH_g - dot(cableDirH_g, Navg) * Navg;
	float T3gL = length(T3_g);
	T3_g = (T3gL > 1e-4) ? T3_g / T3gL : cableDirH_g;
	vec3 B3 = normalize(cross(Navg, T3_g));
	vec3 perpRefH = normalize(vec3(-perpAB.x, 0.0, -perpAB.y));
	if (dot(B3, perpRefH) < 0.0) B3 = -B3;

	vec2 dirH = (lenAB > 0.0) ? d / lenAB : vec2(1.0, 0.0);
	float fullStep = lenAB / float(numSeg);   // full segment span

	for (int i = 0; i <= numSeg; i++) {
		float t = float(i) / float(numSeg);
		vec2 p = wigglyCablePoint(a, d, perpAB, t, lenAB, arcDh, effAmp, seed);

		// Anti-underground (along-cable): see maxHeightInWindow comment.
		float yC = maxHeightInWindow(p, dirH, fullStep) + CENTERLINE_CLEAR;
		vec3 center3D = vec3(p.x, yC, p.y);

		// Geometry convention MUST match the twig emitter:
		//   v = -1  →  vertex at center − B3*halfW  (so outward = −B3)
		//   v = +1  →  vertex at center + B3*halfW  (so outward = +B3)
		// The FS reconstructs perp3D ≈ B3, then cylNormal = perp3D * v at the
		// side, which therefore matches the *actual* outward direction. Prior
		// version had these swapped, which inverted the lit side relative to
		// the sun on every cable (and was inconsistent with twigs).
		vec3 leftPos  = center3D - B3 * halfW;
		vec3 rightPos = center3D + B3 * halfW;

		// Anti-underground clamp: on terrain that curves up faster than linear
		// (concave cross-slope), the slope-tangent-plane offset can put L or R
		// below the actual heightmap at their XZ. Raise to local terrain +
		// SIDE_CLEAR whenever that happens. On linear terrain the L/R points
		// already sit at clearance above ground so this is a no-op there.
		leftPos.y  = max(leftPos.y,  heightAtWorldPos(leftPos.xz)  + SIDE_CLEAR);
		rightPos.y = max(rightPos.y, heightAtWorldPos(rightPos.xz) + SIDE_CLEAR);

		// Also raise center3D if a clamp lifted the sides above it (preserves the
		// cylinder appearance — center should never sit below a side vertex).
		float midY = max(center3D.y, 0.5 * (leftPos.y + rightPos.y));
		center3D.y = midY;

		// Per-vertex tangent: forward-diff at vertex 0 (chord direction), and
		// back-diff for subsequent vertices (centerline direction from the
		// previous vertex). Smoothly interpolated across the triangle strip,
		// this gives the FS a continuous cable along-direction so the
		// cylinder normal bends with up/down hills. (Geometry itself is rigid:
		// adjacent vertices share the same B3 cross-direction, so the ribbon
		// cannot twist around its axis.)
		vec3 vtxTangent;
		if (i == 0) {
			vtxTangent = cableDirH_g;
		} else {
			vtxTangent = center3D - prev3D;
			float vtL = length(vtxTangent);
			vtxTangent = (vtL > 1e-4) ? vtxTangent / vtL : cableDirH_g;
		}

		if (i > 0) along += distance(prev3D, center3D);
		prev3D = center3D;

		emitVtx(leftPos,  vtxTangent, vec2(along, -1.0), widthVal, gridD, timeD, cap);
		emitVtx(rightPos, vtxTangent, vec2(along,  1.0), widthVal, gridD, timeD, cap);
	}
	EndPrimitive();
}

// Emit a small lateral twig at parametric position tCenter along the main
// (wiggly) cable, deterministic on the cable seed + tCenter so the same
// twigs appear every frame in the same place. Returns silently when the
// hash says "no twig here" — leaving an empty primitive, which is a no-op.
void emitTwig(vec2 a, vec2 d, vec2 perpAB,
              float halfMainW, float widthVal, float effAmp, float seed,
              vec4 gridD, vec2 timeD, float cap, float tCenter, float invSeed,
              float spawnAlongMain, int twigIdx, float arcDh, int numSeg) {
	// Resolve spawn point on the wiggly main path at tCenter so twigs root on
	// the visible cable.
	float lenAB = length(d);
	vec2 spawn = wigglyCablePoint(a, d, perpAB, tCenter, lenAB, arcDh, effAmp, seed);

	float twigSeed = spawn.x * 7.13 + spawn.y * 3.77 + invSeed;
	float chance = gsHashU(spawn.x, spawn.y, twigSeed);
	if (chance > BRANCH_CHANCE) return;

	// Side: STRICTLY alternate by twigIdx so neighbouring twigs along the
	// main cable land on opposite sides. Two same-side adjacent twigs flashing
	// in lockstep look like a single pulse "bouncing" — alternating sides
	// breaks that visual coupling. Angle is still hash-randomised below.
	float side = ((twigIdx & 1) == 0) ? 1.0 : -1.0;
	float angleOff = BRANCH_ANGLE_MIN +
		gsHashU(spawn.x, spawn.y, twigSeed + 2.0) * (BRANCH_ANGLE_MAX - BRANCH_ANGLE_MIN);
	float bLen = BRANCH_LEN_MIN +
		gsHashU(spawn.x, spawn.y, twigSeed + 3.0) * (BRANCH_LEN_MAX - BRANCH_LEN_MIN);

	float twigW    = max(2.5, widthVal * BRANCH_WIDTH);
	float twigHWr  = min(twigW, widthVal * 0.55) * WIDTH_FACTOR;
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
	float twigHWt  = twigHWr * 0.45;

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

	// Anchor spawn to the same max-of-window lift the main ribbon uses, so the
	// twig roots on the visible trunk. TWIG_CLEAR is slightly less than
	// CENTERLINE_CLEAR so the junction sits just under the trunk's centerline
	// (z-fight avoidance, see TWIG_CLEAR comment).
	vec2 dirH = (lenAB > 0.0) ? d / lenAB : vec2(1.0, 0.0);
	float fullStep = lenAB / float(numSeg);
	float spawnYc = maxHeightInWindow(spawn, dirH, fullStep) + TWIG_CLEAR;
	vec3 spawn3D = vec3(spawn.x, spawnYc, spawn.y);

	// Anchor the root to the spawn-side edge of the cable's in-slope cross
	// section so the twig pokes out of the side, not the midline.
	vec3 root3D = spawn3D + B * (halfMainW * 0.45 * side);
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
	emitVtx(tipR,  twigDir3D, vec2(spawnAlongMain + bLen,  1.0), twigW, gridD, timeD, cap);
	EndPrimitive();
	gOutSpawnAlong = 0.0;
}

void main() {
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

	float widthVal = MIN_TRUNK_WIDTH +
		clamp(cap / MAX_CAPACITY_REF, 0.0, 1.0) * (MAX_TRUNK_WIDTH - MIN_TRUNK_WIDTH);
	float halfW  = widthVal * WIDTH_FACTOR;
	float effAmp = NOISE_AMP_ABS * (lenAB < 80.0 ? (lenAB / 80.0) : 1.0);
	float seed   = a.x * 0.137 + a.y * 0.781 + b.x * 0.293 + b.y * 0.461;

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
			if (j > 1) curv += abs(dy - prevDy);  // sum |Δslope| as curvature proxy
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
	float arcDh = cableArcDh(a, d, perpAB, lenAB);

	gOutSlot       = dataIn[0].vsSlot;
	gOutNumSeg     = numSeg;

	if (gl_InvocationID == 0) {
		// Coverage SSBO update — once per cable per frame, not per fragment.
		// Live edges (gridData.w >= -0.5) atomicOr bits for segments currently
		// in LOS; ghost edges (gridData.w < -0.5) atomicAnd to clear bits the
		// player has re-scouted (confirmed empty). Sampling along the actual
		// wiggly path keeps reveal accurate even with arc bias on slopes.
		int slot = dataIn[0].vsSlot;
		bool isGhost = gridD.w < -0.5;
		if (slot >= 0) {
			uint setMask = 0u;
			uint clrMask = 0u;
			int n = min(numSeg, 24);
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
		emitMainRibbon(a, d, perpAB, halfW, widthVal, effAmp, seed, gridD, timeD, cap, numSeg, arcDh);
	} else {
		// Twig density scales with 3D arc length: ~one twig per 110 elmos,
		// capped at 4. Short cables get 0-1 twigs, long ones get the full set.
		// Surviving twigs are then respread across [0.15, 0.85] so spacing
		// remains roughly even regardless of twig count.
		int idx = gl_InvocationID - 1;          // 0..3
		int expectedTwigs = clamp(int(len3D / 85.0 + 0.5), 0, 4);
		if (idx >= expectedTwigs) return;
		float tCenterRaw = 0.15 + (float(idx) + 0.5) * (0.7 / float(expectedTwigs));
		// Snap to a main-ribbon segment vertex. The cable is rendered as
		// piecewise-linear chords between samples at t = i/numSeg, so anchoring
		// the twig at the analytical centerline (which curves between samples)
		// would leave the root edge floating off the visible cable surface.
		// Snapping makes the spawn point coincide with an actual rendered
		// vertex of the main ribbon.
		float tCenter = clamp(round(tCenterRaw * float(numSeg)), 1.0, float(numSeg) - 1.0)
		              / float(numSeg);
		float spawnAlongMain = len3D * tCenter;
		emitTwig(a, d, perpAB, halfW, widthVal, effAmp, seed,
		         gridD, timeD, cap, tCenter, float(idx) * 13.7, spawnAlongMain, idx, arcDh, numSeg);
	}
}
