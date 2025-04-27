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
};

uniform sampler2D healthbartexture;
out vec4 fragColor;

void main(void)
{
    float width = g_rect.z;
    float height = g_rect.w;

    vec2 loc = g_loc;

    float center_x = g_rect.x + (width / 2);
    float center_y = g_rect.y + (height / 2);

    // Map fragment pos to first quadrant, taking rect center as origin
    if (loc.x > center_x) {
        loc.x += 2 * (center_x - loc.x);
    }

    if (loc.y > center_y) {
        loc.y += 2 * (center_y - loc.y);
    }

    vec2 r0 = vec2(g_rect.x + g_corner_radius, g_rect.y + g_corner_radius);

    if (loc.x < r0.x && loc.y < r0.y) {
//discard;
/*
        if (loc.x - g_rect.x + (loc.y - g_rect.y) < g_corner_radius) {
           discard;
        }
*/

        if (distance(loc, r0) > g_corner_radius) {
            discard;
        }
    }

	vec4 texcolor = vec4(1.0);
	texcolor = texture(healthbartexture, g_uv.xy);
	texcolor.a *= g_color.a;
	fragColor.rgba = mix(g_color, texcolor, g_uv.z);
	if (fragColor.a < 0.05) discard;
}
