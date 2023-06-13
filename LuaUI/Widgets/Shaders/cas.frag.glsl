#version 330
#line 20058

uniform sampler2D screenCopyTex;
uniform float sharpness;

#if 0 // in case AMD drivers refuse to compile the shader, though according to GLSL spec they shouldn't
	#define TEXEL_FETCH_OFFSET(t, c, l, o) texelFetch(t, c + o, l)
#else
	#define TEXEL_FETCH_OFFSET texelFetchOffset
#endif

in vec2 viewPos;
out vec4 fragColor;

vec3 CASPass(ivec2 tc) {
	// fetch a 3x3 neighborhood around the pixel 'e',
	//  a b c
	//  d(e)f
	//  g h i
	vec3 a = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2(-1, -1)).rgb;
	vec3 b = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2( 0, -1)).rgb;
	vec3 c = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2( 1, -1)).rgb;
	vec3 d = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2(-1,  0)).rgb;
	vec3 e = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2( 0,  0)).rgb;
	vec3 f = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2( 1,  0)).rgb;
	vec3 g = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2(-1,  1)).rgb;
	vec3 h = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2( 0,  1)).rgb;
	vec3 i = TEXEL_FETCH_OFFSET(screenCopyTex, tc, 0, ivec2( 1,  1)).rgb;

	// Soft min and max.
	//  a b c    b
	//  d e f * 0.5  +  d e f * 0.5
	//  g h i    h
	// These are 2.0x bigger (factored out the extra multiply).
	vec3 mnRGB = min(min(min(d, e), min(f, b)), h);
	vec3 mnRGB2 = min(mnRGB, min(min(a, c), min(g, i)));
	mnRGB += mnRGB2;

	vec3 mxRGB = max(max(max(d, e), max(f, b)), h);
	vec3 mxRGB2 = max(mxRGB, max(max(a, c), max(g, i)));
	mxRGB += mxRGB2;

	// Smooth minimum distance to signal limit divided by smooth max.
	vec3 rcpMRGB = vec3(1.0) / mxRGB;
	vec3 ampRGB = clamp(min(mnRGB, 2.0 - mxRGB) * rcpMRGB, vec3(0.0), vec3(1.0));

	// Shaping amount of sharpening.
	ampRGB = inversesqrt(ampRGB);

	float peak = 8.0 - 3.0 * sharpness;
	vec3 wRGB = vec3(-1.0) / (ampRGB * peak);

	vec3 rcpWeightRGB = vec3(1.0) / (1.0 + 4.0 * wRGB);

	//                 0 w 0
	// Filter shape:   w 1 w
	//                 0 w 0
	vec3 window = (b + d) + (f + h);
	vec3 outColor = clamp((window * wRGB + e) * rcpWeightRGB, vec3(0.0), vec3(1.0));

	return outColor;
}

void main() {
	fragColor = vec4(CASPass(ivec2(gl_FragCoord.xy - viewPos)), 1.0);
}
