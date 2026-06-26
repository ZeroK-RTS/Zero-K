#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// This file is going to be licensed under some sort of GPL-compatible license, but authors are dragging
// their feet. Avoid copying for now (unless this header rots for years on end), and check back later.
// See https://github.com/ZeroK-RTS/Zero-K/issues/5328

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__
layout(points) in;
layout(triangle_strip, max_vertices = MAXVERTICES) out;
#line 20000

uniform float iconDistance;
uniform float skipGlyphsNumbers; // <0.5 means none, <1.5 means percent only, >1.5 means nothing, just bars
uniform float vbarUserX;   // weapon-bar horizontal offset from the unit
uniform float vbarSize;    // weapon-bar size multiplier
uniform float iconSize;    // unit icon half-size in BARWIDTH units
uniform float barBorderWidth; // thickness of the decorative band around the bar's track/fill
uniform float reloadThreshold; // seconds: weapons faster than this hide the timer (commanders show "ready")
uniform float digitAtlasStart; // atlas cell index of the digit strip's first glyph ('s'); +1='%', then 9..0
uniform float jumpIconCell;     // atlas cell of the jump command icon, composited into jump-charge gauges
uniform float pulseAlpha;      // oscillating alpha for BITPULSE hovering icons (flashing build/chicken icons)
uniform float rowOffset;   // the row above the bars (states + status): extra vertical gap above the top bar
uniform float rowSize;     // shared size for the hovering-icon states, status badges and weapon/reload badges
uniform float rowSpacing;  // badge/row spacing multiplier (now applied to ALL badge zones: row, weapon
                           // columns, below-zone, so spacing is uniform everywhere)
uniform float isFeature;   // 1 for the feature draw pass (their status channels differ; keep fixed layout)
uniform float overallScale; // overall overlay scale, multiplied alongside the per-unit size into the
                            // shared transform (so it scales every component uniformly)
// Unified spacing constants (in "half-size" units of each element):
#define BADGE_PITCH 2.6    // center-to-center spacing between adjacent badges/icons (all zones)
#define BAR_PITCH   1.2    // center-to-center spacing between stacked horizontal bars (and the row's
                           // per-bar clearance, so the row always clears the stack by one bar exactly)
#define ROW_GAP     0.5    // extra gap (in badge half-sizes) between the top bar and the row's bottom edge,
                           // on top of the bar clearance, so the states/status row isn't glued to the bar
uniform float barSize;     // size multiplier for the horizontal bar bodies + their numbers (bar size option)
uniform float barOffset;   // extra world-space gap between the unit icon and the bars (bar offset option)
uniform float barSpacing;  // gap multiplier between stacked horizontal bars (bar spacing option)
uniform float belowBadgeHeight; // below-zone ability badges (jump/morph/teleport): raise(+)/lower(-) them
uniform float overlayDepthBand; // >0 squeezes the overlay into a near-plane sliver so the world never
                                // occludes it (the engine ignores depth-buffer clears in DrawWorld);
                                // overlays still depth-write so they sort among themselves. 0 = normal depth.
uniform float statusFadeDistance; // camera distance beyond which status/state row icons are hidden (0 = never)
uniform float iconHideDistance;   // camera distance below which the center unit icon is hidden (0 = never)
#ifdef SCREENSPACE
uniform float screenWidth;
uniform float screenHeight;
#endif

in DataVS { // I recall the sane limit for cache coherence is like 48 floats per vertex? try to stay under that!
	uint v_numvertices;
	vec4 v_mincolor;
	vec4 v_maxcolor;
	vec4 v_centerpos;
	vec4 v_uvoffsets;
	vec4 v_parameters;
	float v_sizeModifier;
	float v_range;
	float v_aboveBars;  // count of visible "above" bars (for placing the row above the top bar)
	float v_rowSlot;    // combined centered slot in the row above the bars (states + status badges)
	float v_iconCloak;  // center-icon cloak fraction 0..1 (own/allied only); fades the icon alpha
	uvec4 v_bartype_index_ssboloc;
} dataIn[];

out DataGS {
	vec4 g_color; // pure rgba (for bar bodies: the health/fill color, used to derive fill+track shades in FS)
	vec4 g_uv; // xy is trivially uv coords, z is fill-uses-texture flag (bar bodies only), w is icon atlas flag
        vec4 g_rect;
        vec2 g_loc;
        float g_corner_radius;
        float g_barmode; // 0 = normal textured quad (glyph/icon), 1 = horizontal bar body, 2 = vertical bar body
        float g_fill;    // fill fraction 0..1, only meaningful when g_barmode != 0
        float g_extracolor; // additive blink amount for the background band, only meaningful when g_barmode != 0
        // Icon-cluster composite (barmode 0, the center unit icon only): rank badge + group number drawn
        // onto the SAME quad as the icon so they share one depth. xy = rank atlas-cell origin, zw = group
        // cell origin; an origin < 0 means "absent". g_clusterCol.rgb = rank tint.
        vec4 g_cluster;
        vec4 g_clusterCol;
        // Status-effect magnitudes for the center unit icon (barmode 0): x = slow, y = disarm,
        // z = paralyze, w = build progress. Zero for every other quad (only the icon VS fills it).
        vec4 g_effect;
        float g_cloak; // center-icon cloak fraction 0..1 (own/allied only); fades the icon alpha
};

mat3 rotY;
float localLift = 0.0; // up-axis offset added INSIDE the shared transform (so it scales with the overlay
                       // like everything else); used for the icon->bar gap (barOffset)
vec4 centerpos;
vec4 uvoffsets;
float zoffset;
float yoffset; // camera-forward (billboard Z) offset
float xoffset;
float depthbuffermod;
mat4 overlayXform;     // shared world transform: unit anchor (centerpos) · billboard · (BARSCALE·overallScale·unitSize)
float posScale = 1.0;  // per-component sub-scale, applied to local coords only (g_loc/g_rect stay raw for the FS)
// Icon-cluster composite (set only in the center-icon branch; default = absent for everything else):
// atlas-cell INDICES (the FS turns each into a cell origin), <0 = absent. x=rank (top-left),
// y=group (bottom-right), z=command (bottom-left).
vec3 clusterCells     = vec3(-1.0);
vec3 clusterRankColor = vec3(1.0);   // rank badge tint

// Shared layout transform. Every component builds its quad in local billboard space (x=right, z=up,
// y=cam-forward) around the unit anchor; this applies the ONE shared transform plus the per-component
// posScale, so all components share the same anchor/billboard/scale and differ only by local offset.
vec4 overlayVertexClip(vec2 pos) {
#ifdef SCREENSPACE
	// Screen-space bars are a separate (currently inactive) widget; keep this path's scaling as-is plus
	// the per-component posScale + localLift. overallScale lives only in the world transform.
	vec2 p = (vec2(pos.x + xoffset, pos.y - zoffset) * posScale + vec2(0.0, localLift)) * BARSCALE;
	vec2 screenPos = centerpos.xy + vec2(p.x, -p.y);
	return vec4(screenPos.x / screenWidth * 2.0 - 1.0, 1.0 - screenPos.y / screenHeight * 2.0, 0.0, 1.0);
#else
	// localLift is added AFTER posScale but still inside overlayXform, so it scales with the overlay (s)
	// but not with the per-component posScale -- a clean, proportional gap routed through the transform.
	vec3 local = vec3(pos.x + xoffset, yoffset, pos.y - zoffset) * posScale + vec3(0.0, 0.0, localLift);
	return cameraViewProj * (overlayXform * vec4(local, 1.0));
#endif
}

#define HALFPIXEL 0.0019765625

#define BARTYPE dataIn[0].v_bartype_index_ssboloc.x
#define BARALPHA dataIn[0].v_parameters.y
#define GLYPHALPHA dataIn[0].v_parameters.z
#define UVOFFSET dataIn[0].v_parameters.w
#define UNIFORMLOC dataIn[0].v_bartype_index_ssboloc.z

#define BITSHOWGLYPH 2u
#define BITTIMELEFT 8u
#define BITINVERSE 32u
#define BITALWAYSSHOW 8192u
#define BITINTEGERNUMBER 16u
#define BITVERTICAL 256u
#define BITLEFT 512u
#define BITRIGHT 1024u
#define BITICON 4096u
#define BITICONROW 16384u
#define BITPULSE 32768u
#define BITCONSTRUCTION 65536u
#define BITGAUGE 131072u
#define BITICONCORNER 262144u
#define BITJUMPCHARGE 1048576u
#define BITRATEETA 2097152u

float iconAtlasFlag = 0.0;

// Goo/Morph (8) and Movement (14) stack below the unit; everything else (incl. build) stacks above.
bool isChannelBelow(uint channel) {
	return channel == 8u || channel == 14u;
}

// Final depth for a billboard vertex. Adds the per-element layering offset (depthbuffermod), and, when
// overlayDepthBand > 0, remaps the whole overlay into a thin band just off the near plane so it always
// wins the depth test against the world while still ordering among itself (depthbuffermod kept in NDC).
void applyOverlayDepth() {
#ifdef SCREENSPACE
	gl_Position.z += depthbuffermod;
#else
	if (overlayDepthBand > 0.0) {
		// The engine uses a [0,1] depth range with the near plane at 0 and GL_LESS, so the smallest
		// depth wins (matches the layering: more-negative depthbuffermod = more in front, e.g. the
		// integer count at -0.004 sits in front of the gauge). Squeeze the whole overlay into a thin
		// band just past the near plane so it always beats world geometry (in a top-down view units,
		// terrain and trees all sit far from the near plane), while keeping the natural depth and the
		// depthbuffermod layering inside the band so the overlays still sort among themselves.
		// band * ndc dominates so overlays sort by true camera distance (nearer unit on top);
		// depthbuffermod gets a small sub-slice that only breaks ties (the layering inside one
		// unit's overlay, where ndc is shared). Scaling it down keeps distance ordering between
		// near-equidistant units from being overridden by another unit's internal layering, while
		// 0.0005-sized steps near the near plane are still far above any z-fighting threshold.
		float ndc = clamp(gl_Position.z / gl_Position.w, 0.0, 1.0);        // natural [0,1] depth
		float z = 0.005 + overlayDepthBand * ndc + depthbuffermod * 0.1;   // near-plane sliver + layering
		gl_Position.z = z * gl_Position.w;
	} else {
		gl_Position.z += depthbuffermod;
	}
#endif
}

void emitRectangleVertex(vec2 pos, vec4 corners, float corner_radius, float useTexture, vec2 uv, vec4 color) {
       g_uv.xy = vec2(uv.x, 1.0 - uv.y);
       g_uv.w = iconAtlasFlag;
       gl_Position = overlayVertexClip(pos);
	applyOverlayDepth();

       g_uv.z = useTexture; // this tells us to use texture
       g_color = color;
       g_color.a *= dataIn[0].v_parameters.z; // blend with text/icon fade alpha
       g_rect = corners;
       g_loc = pos;
       g_corner_radius = corner_radius;
       g_barmode = 0.0;
       g_fill = 0.0;
       g_extracolor = 0.0;
       g_cluster = vec4(clusterCells, 0.0);
       g_clusterCol = vec4(clusterRankColor, 0.0);
       g_effect = dataIn[0].v_uvoffsets; // status-effect magnitudes (icon only; 0 elsewhere)
       g_cloak = dataIn[0].v_iconCloak;  // cloak fade (icon only; 0 elsewhere)

       EmitVertex();
}

// Single-quad bar body: the FS decides per-pixel whether it's drawing the background band,
// the empty track, or the filled portion, instead of us emitting 3 separate quads here.
// The fill texture (only used by horizontal bars) is stretched across the inset area same as
// the old separate fill quad was, so we only pass its origin in the atlas -- the FS reconstructs
// the actual sample point from the pixel's fraction across the inset, not from interpolated UVs.
void emitBarVertex(vec2 pos, vec4 rect, float corner_radius, float barmode, float fill, float extracolor, float fillUsesTexture, vec2 fillUVOrigin, vec4 healthcolor) {
       gl_Position = overlayVertexClip(pos);
	applyOverlayDepth();

       g_color = healthcolor;
       g_color.a *= dataIn[0].v_parameters.z; // blend with text/icon fade alpha
       // w carries the vertical-bar blend mode for the FS: 1 = screen (white core stays white, glows),
       // 0 = multiply (tracer/other bars: colored projectiles on dark "air"). Energy (col 0) and
       // lightning (col 12) are glowing beam/arc types -> screen; everything else multiplies.
       // (Unused by horizontal bars.)
       float screenBlend = (UVOFFSET < 0.5 || abs(UVOFFSET - 12.0) < 0.5) ? 1.0 : 0.0;
       g_uv = vec4(fillUVOrigin.x, fillUVOrigin.y, fillUsesTexture, screenBlend);
       g_rect = rect;
       g_loc = pos;
       g_corner_radius = corner_radius;
       g_barmode = barmode;
       g_fill = fill;
       g_extracolor = extracolor;
       g_cluster = vec4(-1.0);       // bars never composite an icon cluster
       g_clusterCol = vec4(1.0);
       g_effect = vec4(0.0);         // bars are not the center icon
       g_cloak = 0.0;

       EmitVertex();
}

void emitBarRectangle(vec4 destination, float corner_radius, float barmode, float fill, float extracolor, float fillUsesTexture, vec2 fillUVOrigin, vec4 healthcolor) {
       float dl = destination.x;
       float db = destination.y;
       float dr = destination.x + destination.z;
       float dt = destination.y + destination.w;

       emitBarVertex(vec2(dl, db), destination, corner_radius, barmode, fill, extracolor, fillUsesTexture, fillUVOrigin, healthcolor);
       emitBarVertex(vec2(dl, dt), destination, corner_radius, barmode, fill, extracolor, fillUsesTexture, fillUVOrigin, healthcolor);
       emitBarVertex(vec2(dr, db), destination, corner_radius, barmode, fill, extracolor, fillUsesTexture, fillUVOrigin, healthcolor);
       emitBarVertex(vec2(dr, dt), destination, corner_radius, barmode, fill, extracolor, fillUsesTexture, fillUVOrigin, healthcolor);

       EndPrimitive();
}

// Radial timer badge: a billboard quad whose FS draws a regular polygon (sides = magnitude) with a
// clockwise-from-top angular fill. g_uv.x carries the side count, g_fill carries the lit fraction.
// iconOrigin = atlas cell origin (uv) of the icon to composite inside the badge; hasIcon>0.5 enables it.
// The FS draws the polygon fill AND the icon on this one quad, so they share a depth (no sort gap).
void emitRadialVertex(vec2 pos, vec4 rect, float sides, float litFrac, vec4 color, vec2 iconOrigin, float hasIcon) {
       gl_Position = overlayVertexClip(pos);
	applyOverlayDepth();

       g_color = color;
       g_color.a *= dataIn[0].v_parameters.z;
       g_uv = vec4(sides, iconOrigin.x, iconOrigin.y, hasIcon);
       g_rect = rect;
       g_loc = pos;
       g_corner_radius = 0.0;
       g_barmode = 3.0; // radial badge
       g_fill = litFrac;
       g_extracolor = 0.0;
       g_cluster = vec4(-1.0);       // radial badges never composite an icon cluster
       g_clusterCol = vec4(1.0);
       g_effect = vec4(0.0);         // radial badges are not the center icon
       g_cloak = 0.0;
       EmitVertex();
}

void emitRadialBadge(vec4 d, float sides, float litFrac, vec4 color, vec2 iconOrigin, float hasIcon) {
       emitRadialVertex(vec2(d.x,        d.y),        d, sides, litFrac, color, iconOrigin, hasIcon);
       emitRadialVertex(vec2(d.x,        d.y + d.w),  d, sides, litFrac, color, iconOrigin, hasIcon);
       emitRadialVertex(vec2(d.x + d.z,  d.y),        d, sides, litFrac, color, iconOrigin, hasIcon);
       emitRadialVertex(vec2(d.x + d.z,  d.y + d.w),  d, sides, litFrac, color, iconOrigin, hasIcon);
       EndPrimitive();
}

void emitRectangle(vec4 destination, vec4 corners, float corner_radius, float useTexture, vec4 texture, vec4 topColor, vec4 bottomColor) {
       // bottom = .x
       // left = .y
       // height = .z
       // width = .w

       float dl = destination.x;
       float db = destination.y;
       float dr = destination.x + destination.z;
       float dt = destination.y + destination.w;

       // Sample only the cell interior: inset the atlas cell rect by half a texel (64px/cell) so bilinear
       // filtering can't bleed in the neighboring cell at the icon/glyph edges.
       vec2 atlasTexel = vec2(0.5 / (float(ICONATLAS_COLS) * 64.0), 0.5 / (float(ICONATLAS_ROWS) * 64.0));
       texture.xy += atlasTexel;
       texture.zw -= 2.0 * atlasTexel;

       float tl = texture.x;
       float tb = texture.y;
       float tr = texture.x + texture.z;
       float tt = texture.y + texture.w;

       emitRectangleVertex(vec2(dl, db), corners, corner_radius, useTexture, vec2(tl, tb), bottomColor);
       emitRectangleVertex(vec2(dl, dt), corners, corner_radius, useTexture, vec2(tl, tt), topColor);
       emitRectangleVertex(vec2(dr, db), corners, corner_radius, useTexture, vec2(tr, tb), bottomColor);
       emitRectangleVertex(vec2(dr, dt), corners, corner_radius, useTexture, vec2(tr, tt), topColor);

       EndPrimitive();
}

// Emit one digit/symbol glyph from the digit strip in the runtime icon atlas. leftX is the left
// edge in billboard X; cellIndex is the absolute atlas cell. Sets iconAtlasFlag so the FS samples
// iconAtlasTex (caller restores it to 0 afterwards).
void emitGlyphCell(float leftX, float cellIndex) {
       iconAtlasFlag = 1.0;
       float gcol = mod(cellIndex, float(ICONATLAS_COLS));
       float grow = floor(cellIndex / float(ICONATLAS_COLS));
       emitRectangle(
              vec4(leftX, 0, BARHEIGHT, BARHEIGHT),
              vec4(leftX, 0, BARHEIGHT, BARHEIGHT),
              0.0,
              1.0,
              vec4(gcol / float(ICONATLAS_COLS), grow / float(ICONATLAS_ROWS),
                   1.0 / float(ICONATLAS_COLS), 1.0 / float(ICONATLAS_ROWS)),
              vec4(1, 1, 1, 1),
              vec4(1, 1, 1, 1)
       );
}

#line 22000
void main(){
	centerpos = dataIn[0].v_centerpos;
	yoffset = 0.0;

#ifndef SCREENSPACE
	rotY = mat3(cameraViewInv[0].xyz,cameraViewInv[2].xyz, cameraViewInv[1].xyz); // swizzle cause we use xz,
	// ONE shared transform for every component: translate to the unit anchor (centerpos -- already the
	// unit position + half height from the VS), rotate into the camera-facing billboard frame, and apply
	// the shared scale (BARSCALE · overallScale · per-unit size). Each component then only adds its own
	// local offset (+ a per-component posScale), so anchor/billboard/scale are identical across all of them.
	float s = BARSCALE * overallScale * dataIn[0].v_sizeModifier;
	overlayXform = mat4(vec4(rotY[0] * s, 0.0),
	                    vec4(rotY[1] * s, 0.0),
	                    vec4(rotY[2] * s, 0.0),
	                    vec4(centerpos.xyz, 1.0));
#endif
        vec4 g_rect;
        float g_corner_radius;

	g_color = vec4(1.0, 0.0, 1.0, 1.0); // a very noticeable default color

	uvoffsets = dataIn[0].v_uvoffsets; // if an atlas is used, then use this, otherwise dont

	float health = min(1, dataIn[0].v_parameters.x);
	if (BARALPHA < MINALPHA) return; // Dont draw below 50% transparency

	// All the early bail conditions to not draw full/empty bars
	if (dataIn[0].v_numvertices == 0u) return; // for hiding the build bar when full health

	depthbuffermod = 0.001;
	float extraColor = 0.0; // (status bars no longer flash)

	float camDist = length(cameraViewInv[3].xyz - centerpos.xyz);

	if ((BARTYPE & BITICON) != 0u) {
		iconAtlasFlag = 1.0;
		float iconHalf;
		float iconAlpha = 1.0;
		xoffset = 0.0;
		zoffset = 0.0;
		if ((BARTYPE & BITICONROW) != 0u) {
			// Status/state icons: hide when camera is farther than statusFadeDistance (0 = never hide).
			if (statusFadeDistance > 0.0 && camDist > statusFadeDistance) return;
			// Hovering-icon row (WG.icons): shares the bars' baseline (cache[1]) and rides one row
			// above the topmost bar; icons sit left-to-right by their centered slot index (v_range).
			// Pulse icons fade by the shared pulseAlpha. rowSize/rowSpacing/rowOffset also drive the
			// status top-band below, so the two halves of the row stay aligned.
			iconHalf = BARWIDTH * rowSize;
			// Rise by one bar's pitch (BAR_PITCH, in BARHEIGHT·barSpacing·barSize units to match the bar
			// stack -- the row carries barSize itself since posScale doesn't apply to it) for every visible
			// bar, then clear the top bar by the row's own half-height + the user offset.
			// When no bars are visible, omit the ROW_GAP so the row sits tight to the unit icon.
			float rowGapFactor = (dataIn[0].v_aboveBars > 0.5) ? (1.0 + ROW_GAP) : 1.0;
			zoffset = -(BAR_PITCH * BARHEIGHT * barSpacing * barSize * dataIn[0].v_aboveBars + iconHalf * rowGapFactor + rowOffset);
			xoffset = dataIn[0].v_rowSlot * (iconHalf * BADGE_PITCH * rowSpacing); // centered slot across states + statuses
			depthbuffermod = -0.001; // same plane as the status badges (the default 0.001 sits them behind)
			if ((BARTYPE & BITPULSE) != 0u) iconAlpha = pulseAlpha;
		} else {
			// CENTER unit icon. Hide when camera is closer than iconHideDistance (0 = never hide).
			if (iconHideDistance > 0.0 && camDist < iconHideDistance) return;
			// Composite rank (top-left), group number (bottom-right) and current command (bottom-left)
			// onto THIS one quad (one primitive, one depth -- no z-fight, and nothing can sort between
			// them). Cell indices ride the instance: v_range = rank (<0 = none);
			// bartype_index .w = group, .z = command (uint, >=60000u = none). FS turns each into an origin.
			iconHalf = BARWIDTH * iconSize;
			clusterCells.x = dataIn[0].v_range;                              // rank cell (<0 = none)
			clusterRankColor = dataIn[0].v_maxcolor.rgb;
			uint groupCell = dataIn[0].v_bartype_index_ssboloc.w;
			clusterCells.y = (groupCell < 60000u) ? float(groupCell) : -1.0; // group cell
			uint cmdCell = dataIn[0].v_bartype_index_ssboloc.z;
			clusterCells.z = (cmdCell < 60000u) ? float(cmdCell) : -1.0;     // current-command cell
		}
		float iconIdx = floor(UVOFFSET + 0.5);
		float col = mod(iconIdx, float(ICONATLAS_COLS));
		float row = floor(iconIdx / float(ICONATLAS_COLS));
		vec4 iconColor = vec4(dataIn[0].v_mincolor.rgb, iconAlpha);
		emitRectangle(
			vec4(-iconHalf, -iconHalf, iconHalf * 2.0, iconHalf * 2.0),
			vec4(-iconHalf, -iconHalf, iconHalf * 2.0, iconHalf * 2.0),
			BARCORNER,
			1.0,
			vec4(col / float(ICONATLAS_COLS), row / float(ICONATLAS_ROWS),
			     1.0 / float(ICONATLAS_COLS), 1.0 / float(ICONATLAS_ROWS)),
			iconColor,
			iconColor
		);
		iconAtlasFlag = 0.0;
		return;
	}

	// Layout: all bars positioned relative to the icon center (centerpos).
	// Vertical bars (left/right): centered at icon height, stacking outward.
	// Horizontal bars: stacked upward from the icon center; stackIndex=0 (health) is at the bottom.
	float stackIndex = float(dataIn[0].v_bartype_index_ssboloc.y);
	xoffset = 0.0;
	if ((BARTYPE & BITLEFT) != 0u) {
		xoffset = (vbarUserX + stackIndex * BARHEIGHT * 1.2) * vbarSize;
	} else if ((BARTYPE & BITRIGHT) != 0u) {
		xoffset = -(vbarUserX + stackIndex * BARHEIGHT * 1.2) * vbarSize;
	}

	// zoffset > 0 shifts bars downward in billboard space (pos.y - zoffset).
	// Vertical bars: centered at icon level, spanning ±BARWIDTH.
	// Horizontal "above" bars (damage group incl. health): stack upward from icon level,
	// stackIndex=0 (health) sits right at icon center, higher indices stack further up.
	// Horizontal "below" bars (build/goo/movement group): stack downward below the unit.
	if ((BARTYPE & BITVERTICAL) != 0u) {
		zoffset = BARWIDTH * vbarSize;
		yoffset = 0.0;
	} else if (isChannelBelow(UNIFORMLOC)) {
		// Construction/movement group: stacks downward below the unit. (barSize applied via posScale.)
		zoffset = BAR_PITCH * BARHEIGHT * barSpacing * stackIndex;
	} else {
		zoffset = -BAR_PITCH * BARHEIGHT * barSpacing * stackIndex;
	}

	vec4 healthcolor = mix(dataIn[0].v_mincolor, dataIn[0].v_maxcolor, health);

	if ((BARTYPE & BITVERTICAL) != 0u) {
		if ((BARTYPE & BITINTEGERNUMBER) != 0u) {
			// INTEGER COUNT READOUT (e.g. ready stockpiled missiles): the channel value is a raw
			// count (range == 1). Drawn centered on the matching gauge in the weapon column.
			float count = floor(dataIn[0].v_parameters.x + 0.5);
			if (count < 0.5) return; // nothing stockpiled -> no number
			float bsize = BARWIDTH * rowSize;
			float gap   = bsize * BADGE_PITCH * rowSpacing; // matches the weapon-column gauge it labels
			float colX  = BARWIDTH * iconSize + bsize * 1.6 + vbarUserX;
			float slot  = float(dataIn[0].v_bartype_index_ssboloc.w);
			xoffset = ((BARTYPE & BITLEFT) != 0u) ? -colX : colX;
			zoffset = slot * gap + BARHEIGHT * 0.5; // +half glyph height to vertically center
			yoffset = 0.0;
			depthbuffermod = -0.004; // in front of the gauge
			float halfW = BARHEIGHT * 0.5;
			float gw   = BARHEIGHT * 0.8; // glyph advance (matches the horizontal-bar kerning)
			float ones = floor(mod(count, 10.0));
			float tens = floor(mod(count * 0.1, 10.0));
			// digit d sits at cell digitAtlasStart + (11 - d) (strip: 's','%',9..0)
			if (tens != 0.0) {
				emitGlyphCell(-halfW - gw * 0.5, digitAtlasStart + (11.0 - tens));
				emitGlyphCell(-halfW + gw * 0.5, digitAtlasStart + (11.0 - ones));
			} else {
				emitGlyphCell(-halfW, digitAtlasStart + (11.0 - ones));
			}
			iconAtlasFlag = 0.0;
			return;
		}
		// RADIAL TIMER BADGE: the polygon's side count encodes the magnitude tier of the remaining
		// time; a clockwise-from-top fill shows the fraction within that tier (sized by the tier's
		// max so the fill is proportional to the real time, stepping down a shape at each boundary).
		// Sources of "seconds remaining":
		//   - construction (BITCONSTRUCTION): build channel value bands (see updater) -> building/
		//     reclaiming ETA or a constant state, colored by direction.
		//   - status effect (BITTIMELEFT): the channel value's overflow above 1 is the seconds.
		//   - weapon reload: derived from the reload fraction (v_parameters.x) and v_range.
		float sides, litFrac;
		if ((BARTYPE & BITGAUGE) != 0u) {
			// Gauge (heat / speed / charge / teleport): the badge fills to the channel's 0..1 magnitude
			// -- a level meter, not a countdown. Always a circle; color from the bartype (v_maxcolor).
			// Jump charges share one value (reconstructed jumpReload, 0..charges): badge N subtracts its
			// charge index (low nibble of UVOFFSET) so each fills as jumpReload passes it -- full when ready.
			float chargeIdx = ((BARTYPE & BITJUMPCHARGE) != 0u) ? mod(UVOFFSET, 16.0) : 0.0;
			litFrac = clamp(dataIn[0].v_parameters.x - chargeIdx, 0.0, 1.0);
			sides = 1.0;
			healthcolor = vec4(dataIn[0].v_maxcolor.rgb, 1.0);
		} else if ((BARTYPE & (BITCONSTRUCTION | BITRATEETA)) != 0u) {
			// Build channel encoding (must match the updater): [1000,..)=reclaiming (secs=v-1000),
			// [2,..)=building (secs=v-2), (0,2)=constant (rate ~0). v==0 is culled before here.
			float v = dataIn[0].v_parameters.x;
			float secs;
			bool isConstant = false;
			if (v >= 2048.0) {
				// Pausable ETA frame mode (goo advancing): v-2048 = completion frame /2 (mod 2048), counted
				// down smoothly here. The /2 scale must match PAUSE_FRAME_SCALE in the updater. When the
				// updater stops advancing it switches to the static (2+secs) band below, so the needle holds.
				float rem = mod((v - 2048.0) - floor(timeInfo.x / 2.0), 2048.0) * 2.0;
				secs = rem / 30.0;
				healthcolor = vec4(dataIn[0].v_maxcolor.rgb, 1.0);
			} else if (v >= 1000.0) {
				secs = v - 1000.0;
				healthcolor = vec4(1.0, 0.35, 0.2, 1.0);           // reclaiming -> red/orange (construction only)
			} else if (v >= 2.0) {
				secs = v - 2.0;
				healthcolor = vec4(dataIn[0].v_maxcolor.rgb, 1.0); // forward progress -> bartype color (green build / magenta raise)
			} else {
				isConstant = true;
				healthcolor = vec4(0.7, 0.7, 0.7, 1.0);            // constant (working, no estimate) -> grey
			}
			if (isConstant) {
				sides = 1.0; litFrac = 1.0; // static full circle
			} else {
				float tier = (secs < 4.0) ? 0.0 : (secs < 16.0) ? 1.0 : (secs < 64.0) ? 2.0 : (secs < 256.0) ? 3.0 : 4.0;
				sides = (tier < 0.5) ? 1.0 : (7.0 - tier);
				float hi = pow(4.0, tier + 1.0);
				litFrac = 1.0 - clamp(secs / hi, 0.0, 1.0); // fills clockwise as it nears completion
			}
		} else if ((BARTYPE & BITTIMELEFT) != 0u) {
			// Status duration (paralyze/disarm/slow): when locked the channel stores the effect-END frame
			// (value-101 = endFrame mod 3895, must match STATUS_LOCK_BASE/MOD in the updater) so the badge
			// counts down SMOOTHLY on the GPU. value < 100 = charging / not locked -> hide.
			if (dataIn[0].v_parameters.x < 100.0) return;
			float secs = mod((dataIn[0].v_parameters.x - 101.0) - timeInfo.x, 3895.0) / 30.0;
			if (secs <= 0.0) return;
			float tier = (secs < 4.0) ? 0.0 : (secs < 16.0) ? 1.0 : (secs < 64.0) ? 2.0 : (secs < 256.0) ? 3.0 : 4.0;
			sides = (tier < 0.5) ? 1.0 : (7.0 - tier);
			float hi = pow(4.0, tier + 1.0);
			litFrac = 1.0 - clamp(secs / hi, 0.0, 1.0); // fills clockwise as the effect runs out
		} else {
			float reloadSecs = dataIn[0].v_range / 30.0;      // full reload duration of this weapon
			bool alwaysShow = (BARTYPE & BITALWAYSSHOW) != 0u; // commanders
			if (reloadSecs < reloadThreshold) {
				// Too fast to bother timing: normal units hide it entirely; commanders show "ready".
				if (!alwaysShow) return;
				sides = 1.0;      // circle
				litFrac = 1.0;    // full = ready (0s)
			} else {
				float rem = ((BARTYPE & BITINVERSE) != 0u) ? (1.0 - dataIn[0].v_parameters.x) : dataIn[0].v_parameters.x;
				rem = clamp(rem, 0.0, 1.0);
				float secs = rem * dataIn[0].v_range / 30.0;
				// base-4 magnitude tiers, fewer sides as it gets more hopeless: circle 0-4s, hexagon
				// 4-16s, pentagon 16-64s, square 64-256s, triangle 256-1024s (~17min ≈ never).
				float tier = (secs < 4.0) ? 0.0 : (secs < 16.0) ? 1.0 : (secs < 64.0) ? 2.0 : (secs < 256.0) ? 3.0 : 4.0;
				sides = (tier < 0.5) ? 1.0 : (7.0 - tier); // 1 -> circle in FS, else 6/5/4/3 sides
				float hi = pow(4.0, tier + 1.0); // this tier's max seconds (4/16/64/256/1024)
				float f  = clamp(secs / hi, 0.0, 1.0);
				// reload (BITINVERSE) lights up as it nears ready; status durations darken as they run out
				litFrac = ((BARTYPE & BITINVERSE) != 0u) ? (1.0 - f) : f;
			}
		}
		float bsize = BARWIDTH * rowSize; // apothem (distance to side centers); shared size for all badges
		// LAYOUT ZONES (slot baked in Lua, rides v_bartype_index_ssboloc.w):
		//   - TOP band (status/duration: BITTIMELEFT/BITCONSTRUCTION): horizontal row above the bars.
		//   - WEAPON columns (BITLEFT/BITRIGHT): vertical columns flanking the unit icon.
		//   - BELOW (everything else, e.g. teleport/movement): pushed under the icon.
		// Stable zones; only the slot within a zone changes, so badges keep recognizable positions.
		float slot = float(dataIn[0].v_bartype_index_ssboloc.w);
		float gap = bsize * BADGE_PITCH * rowSpacing; // ONE badge pitch for every zone (row, columns, below)
		float colX = BARWIDTH * iconSize + bsize * 1.6 + vbarUserX; // column distance from icon center
		if ((BARTYPE & (BITTIMELEFT | BITCONSTRUCTION)) != 0u) {
			// TOP band: hide when camera is farther than statusFadeDistance (0 = never hide).
			if (statusFadeDistance > 0.0 && camDist > statusFadeDistance) return;
			// The same row as the hovering-icon states, riding above the topmost bar.
			// Features keep a fixed slot layout (their channel meanings differ); units share the centered
			// run with the states via v_rowSlot. Both use the one shared badge pitch (gap).
			xoffset = (isFeature > 0.5) ? (slot * gap) : (dataIn[0].v_rowSlot * gap);
			// per-bar rise matches the bar stack (BAR_PITCH, in barSize units), then clear by half a badge
			// plus ROW_GAP so the row isn't glued to the top bar; rowOffset is the user fine-tune on top.
			// When no bars are visible, omit the ROW_GAP so the row sits tight to the unit.
			float statusGapFactor = (dataIn[0].v_aboveBars > 0.5) ? (1.0 + ROW_GAP) : 1.0;
			zoffset = -(BAR_PITCH * BARHEIGHT * barSpacing * barSize * dataIn[0].v_aboveBars + bsize * statusGapFactor + rowOffset);
		} else if ((BARTYPE & BITLEFT) != 0u) {
			xoffset = -colX;                              // left weapon column, stacked down from icon level
			zoffset = slot * gap;
		} else if ((BARTYPE & BITRIGHT) != 0u) {
			xoffset = colX;                               // right weapon column
			zoffset = slot * gap;
		} else {
			// Below zone (jump charges / sprint / teleport / morph): v_rowSlot is the centered run position
			// computed in the VS (persistent badges baked, morph detected live), so they spread + re-center.
			xoffset = dataIn[0].v_rowSlot * gap;
			zoffset = BARHEIGHT * 2.0 - belowBadgeHeight; // belowBadgeHeight raises (+) / lowers (-)
		}
		yoffset = 0.0;
		depthbuffermod = -0.001;
		// Icon (if any) is composited INTO the badge quad by the FS, so badge + icon are ONE primitive
		// at ONE depth -- nothing (terrain, units, other overlay bits) can sort between them. Gauges have
		// no icon (fill level + color identify them). UVOFFSET carries the icon-atlas cell for the rest.
		// Non-gauge badges carry their icon cell in UVOFFSET. Gauges normally have no icon, EXCEPT jump
		// charges, which show the jump command icon (UVOFFSET is taken by chargeIndex+charges*16 there,
		// so the cell comes from the jumpIconCell uniform instead).
		bool isJumpCharge = (BARTYPE & BITJUMPCHARGE) != 0u;
		vec2 iconOrigin = vec2(0.0);
		// A badge shows an icon only if it has one: UVOFFSET >= 0 is an atlas cell, -1 means "no icon"
		// (iconless gauges like heat/speed, and reload badges whose weapon has no `icon` customParam) so
		// the badge draws just the gauge/countdown ring. Jump charges use the jumpIconCell instead.
		float hasIcon = (isJumpCharge || UVOFFSET > -0.5) ? 1.0 : 0.0;
		if (hasIcon > 0.5) {
			float iconIdx = isJumpCharge ? jumpIconCell : floor(UVOFFSET + 0.5);
			iconOrigin = vec2(mod(iconIdx, float(ICONATLAS_COLS)) / float(ICONATLAS_COLS),
			                  floor(iconIdx / float(ICONATLAS_COLS)) / float(ICONATLAS_ROWS));
		}
		// quad is 2x the apothem so a triangle's corners (up to 2x the apothem) aren't clipped
		emitRadialBadge(vec4(-bsize * 2.0, -bsize * 2.0, bsize * 4.0, bsize * 4.0),
			sides, litFrac, healthcolor, iconOrigin, hasIcon);
	} else {
		// HORIZONTAL BAR (top/below bars): wide and short, fills left to right.
		// These two knobs only touch the bars (and their numbers), not the icon/weapon overlays.
		// posScale (not the shared transform) carries barSize, so the bar's local quad stays in raw
		// units -- the FS's barBorderWidth math is in that raw space and must not be pre-scaled.
		posScale = barSize;                                 // size of the bar itself (+ its numbers)
		// Icon->bar gap, routed THROUGH the shared transform (localLift), so it scales with the overlay
		// instead of being a fixed world gap (which looked huge on small units like puppies). The transform
		// scales by s = BARSCALE·overallScale·v_sizeModifier; dividing barOffset by BARSCALE here cancels
		// that constant, leaving the gap = barOffset · overallScale · v_sizeModifier and keeping barOffset
		// in its existing (full-size) value range.
		localLift = barOffset / BARSCALE;

		// Single quad: FS decides background band / empty track / filled portion per-pixel,
		// reconstructing the fill texture sample from this origin plus the pixel's fraction
		// across the inset (same stretching the old separate fill quad had).
		// The quad is grown by barBorderWidth on every side so the FS's matching inset
		// (which shrinks back by barBorderWidth) leaves the track/fill area unchanged in
		// size -- only the decorative band around it grows or shrinks.
		depthbuffermod = -0.001;
		// Fill comes from the runtime icon atlas: UVOFFSET is the start cell of a BARFILLCELLS-wide
		// run (one row). Pass the cell's atlas origin; the FS walks the run across the bar width.
		// UVOFFSET < 0 means "no fill art" -> flat color (fillUsesTexture = 0).
		float fillCell = floor(UVOFFSET + 0.5);
		float fillCol  = mod(fillCell, float(ICONATLAS_COLS));
		float fillRow  = floor(fillCell / float(ICONATLAS_COLS));
		float fillUsesTexture = (UVOFFSET >= -0.5) ? 1.0 : 0.0;
		emitBarRectangle(
			vec4(-BARWIDTH - barBorderWidth, -barBorderWidth, BARWIDTH * 2 + 2.0 * barBorderWidth, BARHEIGHT + 2.0 * barBorderWidth),
			BARCORNER,
			1.0, // horizontal bar body (fills left to right)
			health,
			extraColor,
			fillUsesTexture,
			vec2(fillCol / float(ICONATLAS_COLS), fillRow / float(ICONATLAS_ROWS)),
			healthcolor
		);

		if ((BARTYPE & BITSHOWGLYPH) != 0u) {
			depthbuffermod = -0.002;
			float drawPos = -BARWIDTH - BARCORNER;
			// The bar's identifying glyph is gone -- the fill artwork itself identifies the bar now.
			// The optional digit readout below comes from the digit strip in the runtime icon atlas:
			// cell digitAtlasStart = 's', +1 = '%', then digits 9..0 (so digit d is at +(11-d)).

			if (skipGlyphsNumbers < 1.5) {
				// Always a percentage readout. health = min(1, value), so a status locked at max
				// (value > 1) reads as 100%; the old seconds-left countdown and its 's' glyph are gone.
				float ones = floor(mod(health*100.0, 10.0));
				float tens = floor(mod(health*10.0, 10.0));
				float hundrends = floor(mod(health, 10.0));
				float unitGlyph = 1.0; // percent

				emitGlyphCell(drawPos - BARHEIGHT, digitAtlasStart + unitGlyph);
				drawPos -= BARHEIGHT * 0.8;
				emitGlyphCell(drawPos - BARHEIGHT, digitAtlasStart + (11.0 - ones));
				drawPos -= BARHEIGHT * 0.8;
				if (tens != 0 || hundrends != 0) {
					emitGlyphCell(drawPos - BARHEIGHT, digitAtlasStart + (11.0 - tens));
				}
				drawPos -= BARHEIGHT * 0.8;
				if (hundrends != 0) {
					emitGlyphCell(drawPos - BARHEIGHT, digitAtlasStart + (11.0 - hundrends));
				}
				iconAtlasFlag = 0.0;
			}
		}
	}

}
