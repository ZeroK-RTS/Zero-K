#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// This file is going to be licensed under some sort of GPL-compatible license, but authors are dragging
// their feet. Avoid copying for now (unless this header rots for years on end), and check back later.
// See https://github.com/ZeroK-RTS/Zero-K/issues/5328

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

#line 30000
uniform float addRadius = 0.0;
uniform float iconDistance = 20000.0;
uniform float opacity = 1.0;
in DataGS {
	vec4 g_color;
	vec4 g_uv;
};

uniform sampler2D DrawPrimitiveAtUnitTexture;
out vec4 fragColor;

void main(void)
{
	vec4 texcolor = vec4(1.0);
	#if (USETEXTURE == 1)
		texcolor = texture(DrawPrimitiveAtUnitTexture, g_uv.xy);
	#endif
	fragColor.rgba = vec4(g_color.rgb * texcolor.rgb + addRadius, texcolor.a * TRANSPARENCY + addRadius);
	POST_SHADING
	//fragColor.rgba = vec4(1.0);
	#if (DISCARD == 1)
		if (fragColor.a < 0.01) discard;
	#endif
}