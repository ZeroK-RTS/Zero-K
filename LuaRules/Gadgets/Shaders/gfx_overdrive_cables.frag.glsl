#version 430
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#extension GL_ARB_shader_storage_buffer_object : require

uniform sampler2D infoTex;
uniform float gameTime;
uniform float bakeTime;
uniform float enableFlow;     // 1.0 = full bubble pass; 0.0 = static cables (no animation)
uniform float ghostsEnabled;  // 1.0 = ghost branch active; 0.0 = enemy OOL discards immediately

// Same SSBO as the GS — slot 0 is the FS-write probe target (debug only).
layout (std430, binding = 6) coherent buffer cableCoverageBuffer {
	uvec4 cableCoverage[];
};

in DataGS {
	vec3 worldPos;
	float capacity;
	float isBranch;
	float width;
	vec2 cableUV;
	vec2 timeData;
	vec4 gridData;
	float spawnAlongMain;   // overloaded: main ribbon → lenPerSeg; twig → twig-along
	flat int gsSlot;
};

//__ENGINEUNIFORMBUFFERDEFS__

// =====================================================================
// VISUAL TUNING — knobs you most likely want to tweak when devving.
// Pure aesthetic constants; nothing here changes geometry or topology.
// =====================================================================

// Grow/wither animation rates (elmos/s) — must match unsynced GROWTH_RATE/
// WITHER_RATE so the CPU-side bubble phase anchor and the FS-side growth
// front sweep at the same speed.
const float GROWTH_RATE        = 250.0;
const float WITHER_RATE        = 400.0;

// Bark / inner colours. Bark = visible outer cable; inner = brighter core
// shown through the centre line by `innerMix`. capT (capacity / 100) only
// blends `innerColor` between two grey levels; no hue.
const vec3  BARK_COLOR         = vec3(0.55);
const vec3  INNER_COLOR_LO     = vec3(0.65);   // capT = 0
const vec3  INNER_COLOR_HI     = vec3(0.85);   // capT = 1
const float TWIG_INNER_DAMPEN  = 0.7;          // twigs read more uniformly than trunks

// Lighting: floor on diffuse keeps fully-shaded sides from going pitch black
// (cables read as plasma conduits, not asphalt); spec is blinn-phong on a
// synthetic cylinder normal.
const float DIFFUSE_FLOOR      = 0.25;
const float SPEC_EXP           = 24.0;
const float SPEC_MAGNITUDE     = 0.35;
const vec3  SPEC_TINT          = vec3(1.0, 0.95, 0.85);

// LOS / ghost: dim factor remaps losState through this range; fullLOS uses
// a hard threshold so bubbles only animate inside actual visibility.
const float DIM_LOS_LO         = 0.3;
const float DIM_LOS_HI         = 0.8;
const float DIM_FACTOR_MIN     = 0.3;          // bark brightness at full darkness
const float FULLLOS_LO         = 0.7;
const float FULLLOS_HI         = 1.0;

// Enemy LOS gating: below this losState, enemy fragments are hidden entirely
// (no ghost). Own-ally fragments ignore this threshold — they fade via
// dimFactor instead but always render.
const float ENEMY_LOS_CUT      = 0.5;

// Bubble flow mapping. Must mirror Lua flowToSpeed() exactly for CPU-baked
// phase anchoring + FS extrapolation to remain continuous across baking.
const float MAX_SPEED          = 110.0;
const float FLOW_REF           = 50.0;
const float MIN_TRUNK_W        = 3.0;
const float SPACING_A          = 105.0;        // big bubble layer
const float SPACING_B          = 48.0;         // small bubble layer
const float BUBBLE_BIG_R       = 7.5;
const float BUBBLE_SMALL_R     = 4.0;

// Bubble compositing weights.
const float HALO_WEIGHT        = 0.70;
const float BODY_WEIGHT        = 1.85;
const float SPEC_WEIGHT        = 1.10;
const float GRID_DESAT         = 0.18;         // how much to mute saturated grid hue
const float BUBBLE_WHITE_MIX   = 0.15;         // mix into pure white for "hot core"
const float HALO_WEIGHT_LAYER  = 0.55;         // layer-B halo blend

// Twig pulse: a fast wave sweeps along the cable's `along` axis (used to
// pick which twig fires next, encoding direction-from-root). When the wave
// passes a twig's root, a slow sub-wave sweeps the twig itself.
const float CABLE_PROP_SPEED   = 400.0;        // elmos/s — fast inter-twig stagger
const float CABLE_PROP_PERIOD  = 2800.0;       // elmos → 7s recurrence at 400/s
const float TWIG_SWEEP_SPEED   = 90.0;         // elmos/s — visible motion within a twig
const float PULSE_HW           = 5.0;          // Gaussian sigma in elmos
const float PULSE_INTENSITY    = 0.55;
const float PULSE_BODY_W       = 1.10;
const float PULSE_SPEC_W       = 0.55;
const float PULSE_HALO_W       = 0.50;

out vec4 fragColor;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float hash1(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

// One layer of advecting bubbles drawn as world-space-round glassy spheroids.
// Density is fixed per layer (`spacing` constant); only `speed` changes with
// flow. Each bubble has hash-derived size + cross-axis offset jitter so the
// cable looks like bubbly fluid rather than a metronome.
//
// Crucially, distance is measured in actual world-space elmos in BOTH axes
// (along + cross), so bubbles are real circles regardless of cable thickness.
// `halfWidthE` is the cable cross half-extent in elmos at this fragment
// (= width * 0.5); `radiusE` is each bubble's target radius in elmos and is
// clamped so big bubbles fit inside thin cables instead of clipping to a
// stripe.
//
// Shading: faint inner glow + Fresnel rim + small offset highlight, all with
// smoothstep edges to avoid pixelation at oblique camera angles. Returns
// (body, specular).
// `phase` is the integrated travel distance baked + extrapolated by the
// caller (CPU integrates ∫ speed dt, shader extrapolates the last segment
// with the current speed). Subtracting from `along` advects bubbles smoothly
// across speed changes.
//
// Returns vec3: (body, specular, halo). Caller composites all three with
// possibly different colour weights for richer look.
vec3 bubbleLayer(float along, float phase, float spacing,
                 float radiusMax, float v, float halfWidthE, float layerSeed) {
	float along2 = along - phase;
	float idxLow  = floor(along2 / spacing);
	float coord   = along2 - idxLow * spacing;     // [0, spacing)
	float idxNear = (coord < spacing * 0.5) ? idxLow : (idxLow + 1.0);
	float dAlong  = (coord < spacing * 0.5) ? coord : (spacing - coord);

	float h1 = hash1(idxNear + layerSeed);
	float h2 = hash1(idxNear + layerSeed + 71.3);
	// Bubble radius in elmos. Random per bubble; clamped so it sits within
	// the cable cross-section even on thin twigs.
	float radiusE = radiusMax * (0.7 + 0.3 * h1);
	radiusE = min(radiusE, halfWidthE * 0.97);
	if (radiusE < 0.5) return vec3(0.0);

	// Cross-axis offset: in elmos, only as much margin as the cable can
	// afford. Skinny cables → bubble centred; chunky cables → bubble can
	// drift a little off-axis.
	float crossMargin = max(0.0, halfWidthE - radiusE);
	float yOffsetE    = (h2 - 0.5) * crossMargin * 1.0;

	float dCrossE = v * halfWidthE - yOffsetE;
	// Use the wider "halo radius" for the early-exit so the halo, which
	// extends past r=1, isn't truncated.
	float haloR = radiusE * 1.5;
	float r2H = (dAlong * dAlong + dCrossE * dCrossE) / (haloR * haloR);
	if (r2H >= 1.0) return vec3(0.0);

	float r2 = (dAlong * dAlong + dCrossE * dCrossE) / (radiusE * radiusE);
	float r  = sqrt(r2);
	float xn = dAlong / radiusE;
	float yn = dCrossE / radiusE;

	// Screen-space derivative AA. Keeps every smoothstep edge ~1 pixel wide
	// regardless of zoom; fixes thick-cable staircase pixelation.
	float aa = clamp(fwidth(r) * 1.4, 0.005, 0.20);

	// HOT CORE — Gaussian-style bright nucleus, peaks at r=0. Reads as
	// glowing plasma rather than a flat disc.
	float core = exp(-r2 * 4.5);
	core *= 1.0 - smoothstep(1.0 - aa, 1.0, r);

	// SHARP RIM — thin meniscus highlight near r ≈ 0.85.
	float rim = smoothstep(0.55 - aa, 0.85, r)
	          * (1.0 - smoothstep(0.85, 1.0 - aa * 0.4, r));
	rim *= 1.4;

	// SPECULAR — small bright dot offset toward the light direction.
	vec2 hd = vec2(xn + 0.32, yn + 0.42);
	float hr = length(hd);
	float spec = 1.0 - smoothstep(0.0, 0.22 + aa, hr);
	spec *= spec * spec;   // cubed → very sharp

	// HALO — soft additive bloom outside the bubble's hard edge. Extends
	// from r=0 out to r=1.5 with a gentle Gaussian falloff.
	float halo = exp(-r2 * 0.9) * 0.45;

	return vec3(core + rim, spec, halo);
}

// HSL → RGB at S=1, L=0.5 — matches LuaUI/Headers/overdrive.lua's GetGridColor
// (hue is the same triangle wave used for the panel/grid colour). Hue in [0,1).
vec3 hueToRgb(float h) {
	h = fract(h);
	float r = clamp(abs(h * 6.0 - 3.0) - 1.0, 0.0, 1.0);
	float g = clamp(2.0 - abs(h * 6.0 - 2.0), 0.0, 1.0);
	float b = clamp(2.0 - abs(h * 6.0 - 4.0), 0.0, 1.0);
	return vec3(r, g, b);
}

// efficiency (energy/metal ratio) → bubble colour, matching the economy
// panel's grid swatch (LuaUI/Headers/overdrive.lua). The Lua side computes
// `h = 5760 / (eff+2)^2` (clamped at eff < 3.5 to h = 190) and then feeds
// `h / 255` into HSLtoRGB — so the hue divisor here is 255, not 360.
// Result: low-load grids are blue/teal, fully-saturated grids go yellow→red.
vec3 gridEfficiencyColor(float eff) {
	if (eff <= 0.0) return vec3(1.0, 0.25, 1.0);
	float h;
	if (eff < 3.5) {
		h = 190.0;
	} else {
		h = 5760.0 / ((eff + 2.0) * (eff + 2.0));
	}
	return hueToRgb(h / 255.0);
}

// Ghost shading constants — flat memory render for unscouted enemy fragments
// that fall inside the seen-segment range.
const vec3  GHOST_BASE_LO      = vec3(0.30);   // capT = 0
const vec3  GHOST_BASE_HI      = vec3(0.55);   // capT = 1
const float GHOST_BRANCH_DAMP  = 0.65;

void main() {
	float v = cableUV.y;
	float t = abs(v);
	if (t > 0.90) discard;

	// Visual grow/wither: cableUV.x is distance along cable in elmos.
	// Growth front advances from u=0 forward.
	float along = cableUV.x;
	float visibleFront = (gameTime - timeData.x) * GROWTH_RATE;
	if (along > visibleFront) discard;
	// Wither: tail eats forward from u=0 (witherTime > 0 means withering).
	if (timeData.y > 0.5) {
		float witherFront = (gameTime - timeData.y) * WITHER_RATE;
		if (along < witherFront) discard;
	}

	// FAST GHOST PATH — orphaned-enemy edges (gridData.w = -1.0) skip all the
	// cylinder-normal / lighting / bubble math below. Big perf win when the
	// player has accumulated map-wide ghost coverage. Read LOS + coverage,
	// decide, render flat ghost or discard. Nothing else.
	if (gridData.w < -0.5) {
		vec2 losUV0 = clamp(worldPos.xz, vec2(0.0), mapSize.xy) / mapSize.zw;
		float los0 = texture(infoTex, losUV0).r;
		// Currently-visible ground beneath a dead cable → discard (player is
		// looking at empty terrain; the GS already cleared this segment's bit).
		if (los0 >= ENEMY_LOS_CUT) discard;
		uint cov0 = (gsSlot >= 0) ? cableCoverage[gsSlot].x : 0u;
		if (cov0 == 0u) discard;
		float capT0 = clamp(capacity / 100.0, 0.0, 1.0);
		vec3 ghost0 = mix(GHOST_BASE_LO, GHOST_BASE_HI, capT0);
		if (isBranch > 0.5) ghost0 *= GHOST_BRANCH_DAMP;
		float edgeFade0 = 1.0 - smoothstep(0.55, 0.90, t);
		fragColor = vec4(ghost0 * edgeFade0, 1.0);
		return;
	}

	// Cylinder cross-section normal that respects cable slope, derived from
	// the smoothly-interpolated cable tangent passed in by the GS.
	//
	// `vsTangent` is set per-vertex to the local cable along-direction (back-
	// diff of adjacent centerline vertices). The triangle-strip rasteriser
	// linearly interpolates it across triangles → adjacent fragments along the
	// cable see a continuously rotating tangent, so the cylinder's lit side
	// bends smoothly with up/down hills instead of stepping per triangle (as
	// happens when the basis is reconstructed from `dFdx(worldPos)`, which is
	// flat per triangle).
	//
	// Cross-section axis is `cross(worldUp, cableT)` — purely horizontal, which
	// matches the GS's global B3 (≈ cross(Navg, T_g)) closely enough for any
	// terrain whose Navg is near +Y. Sign matches: GS emits leftPos at -B3
	// (cableUV.y = -1), rightPos at +B3 (cableUV.y = +1), and `cross(Y, T)`
	// gives the same direction as cross(Navg, T) up to a small Y component.
	// Reconstruct cable tangent from screen-space derivatives of (worldPos, cableUV.x).
	// This is per-triangle flat (cableUV.x is linearly interpolated, so derivatives
	// are constant within a triangle), but cheaper than passing a vec3 varying.
	vec3 dWdx_loc = dFdx(worldPos);
	vec3 dWdy_loc = dFdy(worldPos);
	float duDx = dFdx(cableUV.x);
	float duDy = dFdy(cableUV.x);
	float duDenom = duDx * duDx + duDy * duDy;
	vec3 cableT = (duDenom > 1e-6)
	    ? normalize((dWdx_loc * duDx + dWdy_loc * duDy) / duDenom)
	    : vec3(1.0, 0.0, 0.0);
	vec3 perp3D = cross(vec3(0.0, 1.0, 0.0), cableT);
	float perp3DL = length(perp3D);
	if (perp3DL > 1e-3) {
		perp3D /= perp3DL;
	} else {
		// Cable nearly vertical — pick an arbitrary horizontal perp.
		perp3D = vec3(1.0, 0.0, 0.0);
	}

	vec3 trueUp = cross(cableT, perp3D);
	if (trueUp.y < 0.0) trueUp = -trueUp;   // ensure pointing skyward
	trueUp = normalize(trueUp);

	float up = sqrt(max(0.0, 1.0 - v * v));
	vec3 cylNormal = normalize(trueUp * up + perp3D * v);

	// Own lighting (forward rendered, no engine lighting applies)
	float diffuse = max(DIFFUSE_FLOOR, dot(cylNormal, normalize(sunDir.xyz)));

	// Specular
	vec3 viewDir = normalize(cameraViewInv[3].xyz - worldPos);
	vec3 halfDir = normalize(normalize(sunDir.xyz) + viewDir);
	float spec = pow(max(0.0, dot(cylNormal, halfDir)), SPEC_EXP) * SPEC_MAGNITUDE;

	// Bark / inner gray-scale tint by capacity. Industrial conduit look.
	float capT = clamp(capacity / 100.0, 0.0, 1.0);
	vec3 innerColor = mix(INNER_COLOR_LO, INNER_COLOR_HI, capT);

	float innerMix = smoothstep(0.85, 0.15, t);
	if (isBranch > 0.5) innerMix *= TWIG_INNER_DAMPEN;
	vec3 baseColor = mix(BARK_COLOR, innerColor, innerMix);

	// Surface noise detail
	float surfN = hash(worldPos.xz * 0.5) * 0.04;
	baseColor += vec3(surfN);

	// LOS state — sampled from $info:los (single-channel red), the engine's
	// actual game-logic LOS texture. Independent of the user's overlay toggle:
	// 0.0 = unscouted, 1.0 = currently in LOS.
	vec2 losUV = clamp(worldPos.xz, vec2(0.0), mapSize.xy) / mapSize.zw;
	float losState = texture(infoTex, losUV).r;
	float fullLOS = smoothstep(FULLLOS_LO, FULLLOS_HI, losState);

	// Coverage bits are written by the GS (per-segment, per cable per frame).
	// Per-fragment gating: derive segIdx from along-distance + len-per-segment
	// packed into spawnAlongMain (see DataGS comment). Twigs use bit 0 as a
	// fallback — they're decorative and only show when the parent has any
	// coverage anyway.
	uint segBit;
	if (isBranch < 0.5) {
		float lenPerSeg = spawnAlongMain;
		int segIdx = (lenPerSeg > 0.0) ? clamp(int(cableUV.x / lenPerSeg), 0, 23) : 0;
		segBit = 1u << uint(segIdx);
	} else {
		segBit = 0xFFFFFFu;   // twig: any-bit-set OK
	}

	// Three render classes for the FS:
	//   isOwnAlly =  1.0 → own ally, always live (existing path below).
	//   isOwnAlly =  0.0 → live enemy edge: render live in LOS, ghost in fog
	//                       (gated by segment bit), discard if never seen.
	//   isOwnAlly = -1.0 → orphaned ghost (synced removed it; we kept a
	//                       snapshot). Always render ghost gated by segment
	//                       bit; never live, regardless of LOS. This is the
	//                       "you don't know it died" persistence.
	float isOwnAlly = gridData.w;
	bool isGhostEdge = isOwnAlly < -0.5;

	// Re-scout clear is handled by the GS (atomicAnd at segment midpoints
	// when the ghost edge's bits overlap with current LOS). Here in the FS
	// we just discard the ghost fragment when it's in current LOS — the
	// player is looking at empty ground, the cable shouldn't show.
	if (isGhostEdge && losState >= ENEMY_LOS_CUT) discard;

	bool enemyOutOfLOS = (isOwnAlly < 0.5 && isOwnAlly > -0.5 && losState < ENEMY_LOS_CUT);
	if (enemyOutOfLOS) {
		// Ghosts disabled: no SSBO read, no branch evaluation; just discard.
		if (ghostsEnabled < 0.5) discard;
		uint cov = (gsSlot >= 0) ? cableCoverage[gsSlot].x : 0u;
		if ((cov & segBit) == 0u) discard;
		float capT2 = clamp(capacity / 100.0, 0.0, 1.0);
		vec3 ghost = mix(GHOST_BASE_LO, GHOST_BASE_HI, capT2);
		if (isBranch > 0.5) ghost *= GHOST_BRANCH_DAMP;
		float edgeFade = 1.0 - smoothstep(0.55, 0.90, t);
		fragColor = vec4(ghost * edgeFade, 1.0);
		return;
	}

	// Apply lighting
	vec3 color = baseColor * diffuse + SPEC_TINT * spec;

	// Static-cable detail level: skip the entire bubble pass and bark dim.
	// `enableFlow` is a uniform driven by the synced /cabletree flow toggle,
	// so the same draw call cheaply shortcuts to a flat-lit cable when the
	// player has opted out of the animated visual.
	if (enableFlow < 0.5) {
		// Still apply LOS-aware bark dim so out-of-LOS cables read as
		// shadowed; just don't add bubble glow on top.
		color *= mix(DIM_FACTOR_MIN, 1.0, smoothstep(DIM_LOS_LO, DIM_LOS_HI, losState));
		fragColor = vec4(color, 1.0);
		return;
	}

	// Energy bubbles travelling along the cable, like fluid in a pipe.
	//
	// Design:
	//   - +u is the direction of energy flow (synced reorients edges by
	//     current flow); all cables share one global phase so we never get
	//     the optical illusion of "counter motion" inside a single cable.
	//   - Density (bubbles per elmo) is FIXED: every cable shows the same
	//     bubbly look regardless of how loaded it is. What changes with
	//     flow is the SPEED bubbles travel at — zero flow leaves them
	//     motionless; high flow makes them zip.
	//   - Two layered streams of bubbles (big + small) with random per-bubble
	//     size + cross-axis offset, so the cable looks like a real bubbly
	//     slurry instead of a metronome of identical dots.
	// Bubble speed/density mapping. MUST match the CPU's flowToSpeed for the
	// integrated phase anchoring to stay consistent.
	//
	// Cable thickness conveys capacity (orthogonal); flow is encoded by speed
	// and density together. Each scales as sqrt(flow/FLOW_REF) and ramps
	// monotonically, so they read as one fused "more lively" signal. Their
	// product = (sqrt(...))² is linear in flow, matching actual throughput.
	float flow = gridData.y;
	// Linear thickness divisor: a cable 4× thicker than min gets its flow
	// signal scaled to 1/4 before the sqrt → ~0.5× visual liveliness. Slight
	// negative bias for thick cables, matching the CPU's flowToSpeed.
	float thicknessRatio = max(1.0, width / MIN_TRUNK_W);
	float effFlow = max(flow, 0.0) / thicknessRatio;
	float n = sqrt(effFlow / FLOW_REF);
	float speed = MAX_SPEED * n;

	float halfWidthE = width * 0.5;        // cable cross half-extent in elmos

	// Phase = CPU's baked phase (snapshot at bakeTime) + linear extrapolation
	// at the current speed. Speed *changes* update the rate of advance from
	// here — bubbles don't teleport.
	float phase = gridData.z + speed * (gameTime - bakeTime);

	// Density: spacing inversely scales with the same sqrt factor, floored at
	// `n=0.3` so a near-zero-flow cable still shows widely-spaced bubbles
	// rather than nothing or overlapping spam.
	float spacingMul = max(0.3, n);
	float spacingA = SPACING_A / spacingMul;
	float spacingB = SPACING_B / spacingMul;

	// Bubble pass: main ribbon uses two advecting bubble layers; twigs do a
	// two-stage wave (see CABLE_PROP_SPEED + TWIG_SWEEP_SPEED).
	float bubbleBody, bubbleSpec, bubbleHalo;
	if (isBranch > 0.5) {
		// Two-stage wavefront (decoupled cable-stagger + twig-sweep):
		//   1. CABLE_PROP_SPEED sweeps a virtual fast wave along the cable's
		//      `along` axis. Twigs at lower spawnAlongMain get hit earlier,
		//      so the stagger encodes direction-from-root.
		//   2. When that wave passes a twig's root, a slower sub-wave starts
		//      at twig-local 0 and propagates through the twig at
		//      TWIG_SWEEP_SPEED. Inter-twig stagger feels snappy while motion
		//      *within* a twig stays comfortable.
		// `spawnAlongMain` is what lets us decouple these — without it both
		// speeds would be tied to the same propagation rate.
		float wavePassedElmos = mod(gameTime * CABLE_PROP_SPEED - spawnAlongMain, CABLE_PROP_PERIOD);
		float subwavePos = TWIG_SWEEP_SPEED * (wavePassedElmos / CABLE_PROP_SPEED);
		float localAlong = along - spawnAlongMain;
		float d = localAlong - subwavePos;
		// No wrap correction: when subwavePos overshoots the twig the
		// Gaussian naturally falls to ~0 for any fragment.
		float pulse = exp(-(d * d) / (PULSE_HW * PULSE_HW));
		float crossT = 1.0 - smoothstep(0.7, 1.0, v * v);
		float intensity = pulse * crossT * PULSE_INTENSITY;
		bubbleBody = intensity * PULSE_BODY_W;
		bubbleSpec = intensity * PULSE_SPEC_W;
		bubbleHalo = intensity * PULSE_HALO_W;
	} else {
		vec3 bA = bubbleLayer(along, phase, spacingA, BUBBLE_BIG_R,   v, halfWidthE,  3.7);
		vec3 bB = bubbleLayer(along, phase, spacingB, BUBBLE_SMALL_R, v, halfWidthE, 19.1);
		bubbleBody = bA.x + bB.x * 0.85;
		bubbleSpec = bA.y + bB.y * 0.85;
		bubbleHalo = bA.z + bB.z * HALO_WEIGHT_LAYER;
	}

	// Bubble colour: grid-efficiency hue, lightly toned down so it still
	// glows clearly but isn't neon-saturated.
	vec3 gridColor   = gridEfficiencyColor(gridData.x);
	float gridLum    = dot(gridColor, vec3(0.299, 0.587, 0.114));
	vec3 grayedGrid  = mix(gridColor, vec3(gridLum), GRID_DESAT);
	vec3 bubbleColor = mix(grayedGrid, vec3(1.0), BUBBLE_WHITE_MIX);
	vec3 haloColor   = grayedGrid;

	// LOS-aware dimming on the BARK ONLY. Bubbles are plasma — emissive, so
	// they shouldn't fade in shadow. Composing them after the dim means
	// glowing balls remain "lights in the dark" rather than disappearing in
	// LOS-dim regions.
	float dimFactor = mix(DIM_FACTOR_MIN, 1.0, smoothstep(DIM_LOS_LO, DIM_LOS_HI, losState));
	color *= dimFactor;

	// Composition order:
	//   - Halo: additive (soft underglow that should mix with bark colour).
	//   - Body: max() over current colour, so dark bark can't leak into the
	//     bubble's true grid hue. Plain additive composition causes hue
	//     shifts (orange → yellow, magenta → pink) because the bark's green
	//     channel piles onto the emissive. max() lets the emissive plasma
	//     show its real colour through the cable in shadow.
	//   - Spec: additive white sparkle on top.
	color += haloColor * bubbleHalo * fullLOS * HALO_WEIGHT;
	vec3 bubbleEmissive = bubbleColor * bubbleBody * fullLOS * BODY_WEIGHT;
	color = max(color, bubbleEmissive);
	color += vec3(1.0) * bubbleSpec * fullLOS * SPEC_WEIGHT;

	// FULLY OPAQUE output — like lava. No alpha blending.
	fragColor = vec4(color, 1.0);
}
