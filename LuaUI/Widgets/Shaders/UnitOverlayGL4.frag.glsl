#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// This file is going to be licensed under some sort of GPL-compatible license, but authors are dragging
// their feet. Avoid copying for now (unless this header rots for years on end), and check back later.
// See https://github.com/ZeroK-RTS/Zero-K/issues/5328

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

#line 30000
in DataGS {
	vec4 g_color;
	vec4 g_uv;
	vec4 g_rect;
	vec2 g_loc;
	float g_corner_radius;
	float g_barmode; // 0 = normal textured quad (glyph/icon), 1 = horizontal bar body, 3 = radial timer badge
	float g_fill;
	float g_extracolor;
	vec4 g_cluster;    // icon cluster: xy = rank cell origin, zw = group cell origin (<0 = absent)
	vec4 g_clusterCol; // rgb = rank tint
	vec4 g_effect;     // center-icon status effects: x = slow, y = disarm, z = paralyze, w = build (0 elsewhere)
};

uniform sampler2D iconAtlasTex;
uniform float barBorderWidth;
uniform float trackDarken; // brightness of the empty/remaining portion of a bar relative to the filled part (1.0 = same, lower = darker)
out vec4 fragColor;

// Signed distance from p to a rounded box of the given half-size and corner radius, centered
// on the origin. Negative = inside. Used for both the outer silhouette and the inset boundary
// so "which zone is this pixel in" is always a single continuous threshold, not several
// independently-folded/clamped tests that can disagree by a sub-pixel epsilon at the seam
// between zones (the previous quadrant-fold + nested-if approach did exactly that).
float roundedBoxSDF(vec2 p, vec2 halfSize, float radius) {
    vec2 q = abs(p) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

// Signed distance to a regular polygon of n sides, apothem r, centered on origin, point-up.
float polygonSDF(vec2 p, float r, float n) {
    float an = 3.14159265 / n;
    vec2 acs = vec2(cos(an), sin(an));
    float bn = mod(atan(p.x, p.y) + an, 2.0 * an) - an;
    p = length(p) * vec2(cos(bn), abs(sin(bn)));
    p -= r * acs;
    p.y += clamp(-p.y, 0.0, r * acs.y);
    return length(p) * sign(p.x);
}

void main(void)
{
    vec2 rectCenter = g_rect.xy + g_rect.zw * 0.5;
    if (roundedBoxSDF(g_loc - rectCenter, g_rect.zw * 0.5, g_corner_radius) > 0.0) {
        discard;
    }

    if (g_barmode > 2.5) {
        // Radial timer badge: regular polygon (g_uv.x = side count, <2.5 = circle) filled clockwise
        // from the top (12 o'clock). g_fill = lit fraction; lit area is full color, the rest dim.
        vec2 c = g_rect.xy + g_rect.zw * 0.5;
        vec2 p = g_loc - c;
        float quadHalf = min(g_rect.z, g_rect.w) * 0.5;
        float apothem = quadHalf * 0.5;              // shape sized by side-centers; corners reach the quad edge
        float sides = g_uv.x;
        float sd;
        if (sides < 2.5) {
            sd = length(p) - apothem;                // circle
        } else {
            float circum = apothem / cos(3.14159265 / sides);
            sd = polygonSDF(vec2(p.x, -p.y), circum, sides); // flip Y so polygons point up
        }
        // NOTE: no early "outside the polygon" discard -- the icon is allowed to spill past the badge
        // silhouette (its square corners exceed the polygon), matching the old separate-quad look while
        // staying one quad / one depth. The fill is drawn only inside the badge; the icon draws anywhere.
        float ang = atan(p.x, p.y);                  // 0 at top, increasing clockwise
        if (ang < 0.0) ang += 6.28318530718;
        float frac = ang / 6.28318530718;
        bool lit = frac <= g_fill;
        bool insideBadge = (sd <= 0.0);
        vec3 fillRGB = g_color.rgb * (lit ? 1.0 : 0.25);
        // Icon (g_uv.w > 0.5): atlas cell origin g_uv.yz, sized to the badge's inscribed region but NOT
        // clipped to the polygon -- corners outside the badge still draw.
        vec4 ic = vec4(0.0);
        if (g_uv.w > 0.5 && abs(p.x) <= apothem && abs(p.y) <= apothem) {
            vec2 frac2 = (p / apothem) * 0.5 + 0.5; // [0,1] across the central icon region, y up
            vec2 cell = vec2(1.0 / float(ICONATLAS_COLS), 1.0 / float(ICONATLAS_ROWS));
            ic = texture(iconAtlasTex, g_uv.yz + frac2 * cell);
        }
        vec3 rgb;
        float alpha;
        if (insideBadge) {
            rgb = mix(fillRGB, ic.rgb, ic.a);        // icon over the gauge fill
            alpha = g_color.a;
        } else {
            rgb = ic.rgb;                            // icon spilling outside the badge
            alpha = ic.a * g_color.a;
        }
        if (alpha < 0.05) discard;                   // nothing here (outside badge, no icon)
        fragColor = vec4(rgb, alpha);
        return;
    }

    if (g_barmode > 0.5) {
        // Bar body: the outer rect is the background band; barBorderWidth inset from it is the
        // track/fill area. Decide which zone this pixel is in and shade it accordingly,
        // replacing what used to be 3 separately-emitted quads (background/tint/fill).
        vec4 inset = vec4(g_rect.x + barBorderWidth, g_rect.y + barBorderWidth, g_rect.z - 2.0 * barBorderWidth, g_rect.w - 2.0 * barBorderWidth);

        float outerYFrac = clamp((g_loc.y - g_rect.y) / g_rect.w, 0.0, 1.0);

        // The track/fill layer has its own (smaller) rounded corners nested inside the
        // background's corners -- a single SDF threshold against the inset rect handles both
        // the straight edges and the corners in one continuous test, so there's no seam between
        // "inside" and "outside" for the renderer to disagree on by a fraction of a pixel.
        vec2 insetCenter = inset.xy + inset.zw * 0.5;
        bool insideInset = roundedBoxSDF(g_loc - insetCenter, inset.zw * 0.5, SMALLERCORNER) <= 0.0;

        if (!insideInset) {
            fragColor = mix(BGBOTTOMCOLOR, BGTOPCOLOR, outerYFrac) + g_extracolor;
        } else {
            float insetXFrac = clamp((g_loc.x - inset.x) / inset.z, 0.0, 1.0);
            float insetT      = clamp((g_loc.y - inset.y) / inset.w, 0.0, 1.0);

            // Filled vs empty is just a brightness factor: the empty (un-progressed) portion is a
            // darkened version of the same fill, opaque throughout -- not a see-through wash.
            float bright = (insetXFrac <= g_fill) ? 1.0 : trackDarken;
            // Horizontal bar: bottom-darken gradient, optionally modulated by the fill pattern.
            vec3 surface = mix(g_color.rgb * BOTTOMDARKENFACTOR, g_color.rgb, insetT);
            if (g_uv.z > 0.5) {
                // Fill is a BARFILLCELLS-wide run in the runtime icon atlas starting at the cell
                // whose atlas origin is g_uv.xy. Walk it horizontally across the bar (insetXFrac)
                // and vertically within the one cell (insetT, bottom-up like the icon path). Inset
                // by half an atlas texel so bilinear filtering never bleeds in the neighboring
                // cell above/below or the adjacent bar at the run's ends.
                vec2 atlasTexel = vec2(0.5 / (float(ICONATLAS_COLS) * 64.0), 0.5 / (float(ICONATLAS_ROWS) * 64.0));
                float spanW = float(BARFILLCELLS) / float(ICONATLAS_COLS);
                float cellH = 1.0 / float(ICONATLAS_ROWS);
                vec2 atlasUV = vec2(
                    g_uv.x + atlasTexel.x + insetXFrac * (spanW - 2.0 * atlasTexel.x),
                    g_uv.y + atlasTexel.y + insetT     * (cellH - 2.0 * atlasTexel.y));
                surface *= texture(iconAtlasTex, atlasUV).rgb;
            }
            fragColor = vec4(surface * bright, g_color.a);
        }
        if (fragColor.a < 0.05) discard;
        return;
    }

	// Glyphs/icons (barmode 0) all sample the runtime icon atlas now.
	vec4 col = g_color * texture(iconAtlasTex, vec2(g_uv.x, 1.0 - g_uv.y));
	// Icon cluster: the center unit icon composites a rank badge (top-left), group number (bottom-right)
	// and current command (bottom-left) onto this SAME quad, so all share one depth (no z-fight, nothing
	// sorts between them). g_cluster holds atlas-cell INDICES: x=rank, y=group, z=command (<0 = absent).
	if (g_cluster.x >= 0.0 || g_cluster.y >= 0.0 || g_cluster.z >= 0.0) {
		vec2 frac = (g_loc - g_rect.xy) / g_rect.zw;       // [0,1] across the quad (y up)
		vec2 cellsz = vec2(1.0 / float(ICONATLAS_COLS), 1.0 / float(ICONATLAS_ROWS));
		// Sample only the cell's interior: bilinear filtering at the exact cell edge bleeds the neighbor,
		// so inset by half a texel (atlas is 64px/cell) and map each quadrant's [0,1] across that interior.
		vec2 texel = vec2(0.5 / (float(ICONATLAS_COLS) * 64.0), 0.5 / (float(ICONATLAS_ROWS) * 64.0));
		vec2 inner = cellsz - 2.0 * texel;
		if (g_cluster.x >= 0.0 && frac.x < 0.5 && frac.y > 0.5) {       // rank -> top-left
			vec2 o = vec2(mod(g_cluster.x, float(ICONATLAS_COLS)), floor(g_cluster.x / float(ICONATLAS_COLS))) * cellsz;
			vec4 r = texture(iconAtlasTex, o + texel + vec2(frac.x, frac.y - 0.5) * 2.0 * inner);
			r.rgb *= g_clusterCol.rgb;
			col = mix(col, r, r.a);
		}
		if (g_cluster.y >= 0.0 && frac.x > 0.5 && frac.y < 0.5) {       // group -> bottom-right
			vec2 o = vec2(mod(g_cluster.y, float(ICONATLAS_COLS)), floor(g_cluster.y / float(ICONATLAS_COLS))) * cellsz;
			vec4 grp = texture(iconAtlasTex, o + texel + vec2(frac.x - 0.5, frac.y) * 2.0 * inner);
			grp.rgb *= vec3(0.4, 1.0, 0.4);                // group number green tint
			col = mix(col, grp, grp.a);
		}
		if (g_cluster.z >= 0.0 && frac.x < 0.5 && frac.y < 0.5) {       // current command -> bottom-left
			vec2 o = vec2(mod(g_cluster.z, float(ICONATLAS_COLS)), floor(g_cluster.z / float(ICONATLAS_COLS))) * cellsz;
			vec4 c = texture(iconAtlasTex, o + texel + vec2(frac.x, frac.y) * 2.0 * inner);
			col = mix(col, c, c.a);
		}
	}

	// Status-effect tint on the center unit icon, echoing the on-model effects. The bars/badges already
	// show the precise states; this is only a secondary at-a-glance cue for radar range (icon-only), so
	// keep the icon legible: (a) show only the DOMINANT effect rather than stacking washes into mud, and
	// (b) tint hue-only -- the effect colour is scaled by the icon's own luminance, so the silhouette and
	// relative brightness (hence team shade) read through. g_effect is non-zero only for the center icon.
	// Colours mirror gfx_paralyze_effect; priority paralyze > disarm > slow (most disabling first).
	vec3 effectColor = vec3(0.0);
	float effectAmt = 0.0;
	if (g_effect.z > 0.001) {        // paralyze (EMP): light blue
		effectColor = vec3(0.49, 0.5, 1.0);
		effectAmt = clamp(g_effect.z * 0.55, 0.0, 0.55);
	} else if (g_effect.y > 0.001) { // disarm: desaturated khaki/tan
		effectColor = vec3(0.7, 0.7, 0.55);
		effectAmt = clamp(g_effect.y * 0.5, 0.0, 0.5);
	} else if (g_effect.x > 0.001) { // slow: magenta
		effectColor = vec3(1.0, 0.1, 1.0);
		effectAmt = clamp(sqrt(g_effect.x) * 0.5, 0.0, 0.5);
	}
	if (effectAmt > 0.0) {
		float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
		vec3 tinted = effectColor * (0.35 + lum); // effect hue, icon's own brightness -> silhouette survives
		col.rgb = mix(col.rgb, tinted, effectAmt);
	}

	fragColor = col;
	if (fragColor.a < 0.05) discard;
}
