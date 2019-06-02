#version 150 compatibility
//#extension GL_ARB_derivative_control: enable

uniform sampler2D dilatedDepthTex;
uniform sampler2D dilatedColorTex;
uniform sampler2D shapeDepthTex;
uniform sampler2D mapDepthTex;

uniform float strength = 1.0;
uniform float alwaysShowOutLine = 0.0;

const float eps = 1e-3;
//layout(pixel_center_integer) in vec4 gl_FragCoord;
//layout(origin_upper_left) in vec4 gl_FragCoord;

void main() {
	ivec2 imageCoord = ivec2(gl_FragCoord.xy);

	vec4 dilatedColor = texelFetch(dilatedColorTex, imageCoord, 0);
	dilatedColor.a *= strength;

	float dilatedDepth = texelFetch(dilatedDepthTex, imageCoord, 0).r;
	float mapDepth = texelFetch(mapDepthTex, imageCoord, 0).r;
/*
#if 0
	float shapeDepth_p0 = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 1,  0)).r;
	float shapeDepth_0p = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 0,  1)).r;
	float shapeDepth_pp = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 1,  1)).r;

	float shapeDepth_n0 = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2(-1,  0)).r;
	float shapeDepth_0n = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 0, -1)).r;
	float shapeDepth_nn = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2(-1, -1)).r;

	//bool cond = (shapeDepth == 1.0);
	bool cond = any(bvec3(equal(vec3(shapeDepth_p0, shapeDepth_0p, shapeDepth_pp), vec3(1.0)))) ||
				any(bvec3(equal(vec3(shapeDepth_n0, shapeDepth_0n, shapeDepth_nn), vec3(1.0))));
#else
	float shapeDepth_p0 = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 1,  0)).r;
	float shapeDepth_0p = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 0,  1)).r;
	//float shapeDepth_pp = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 1,  1)).r;

	float shapeDepth_n0 = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2(-1,  0)).r;
	float shapeDepth_0n = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 0, -1)).r;
	//float shapeDepth_nn = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2(-1, -1)).r;

	//bool cond = (shapeDepth == 1.0);
	bool cond = any(bvec4(equal(vec4(shapeDepth_p0, shapeDepth_0p, shapeDepth_n0, shapeDepth_0n), vec4(1.0))));
#endif
*/

	float shapeDepth_p0 = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 1,  0)).r;
	float shapeDepth_0p = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 0,  1)).r;

	float shapeDepth_n0 = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2(-1,  0)).r;
	float shapeDepth_0n = texelFetchOffset(shapeDepthTex, imageCoord, 0, ivec2( 0, -1)).r;

	bool cond = any(bvec4(equal(vec4(shapeDepth_p0, shapeDepth_0p, shapeDepth_n0, shapeDepth_0n), vec4(1.0))));


	float depthToWrite = mix(dilatedDepth, 0.0, alwaysShowOutLine);

	gl_FragColor = mix(vec4(0.0), dilatedColor, float(cond));
	gl_FragDepth = mix(1.0, depthToWrite, float(cond));
}
