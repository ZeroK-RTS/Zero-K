#version 330
// This file is going to be licensed under some sort of GPL-compatible license, but authors are dragging
// their feet. Avoid copying for now (unless this header rots for years on end), and check back later.
// See https://github.com/ZeroK-RTS/Zero-K/issues/5328

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 20000

//__ENGINEUNIFORMBUFFERDEFS__

//__DEFINES__

in DataVS {
	flat vec4 blendedcolor;
	#ifdef USE_STIPPLE
		float worldscale_circumference;
	#endif
};

out vec4 fragColor;

void main() {
	fragColor.rgba = blendedcolor.rgba;
}