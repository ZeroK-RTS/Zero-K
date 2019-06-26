#version 150 compatibility

uniform sampler2D modelDepthTex;
uniform sampler2D mapDepthTex;
uniform sampler2D modelMiscTex;

uniform vec4 outlineColor;

uniform mat4 projMatrix;

float GetViewSpaceDepth(float depthNDC) {
	return -projMatrix[3][2] / (projMatrix[2][2] + depthNDC);
}

#define USE_MATERIAL_INDICES ###USE_MATERIAL_INDICES###
#define DEPTH_CLIP01 ###DEPTH_CLIP01###

#define NORM2SNORM(value) (value * 2.0 - 1.0)
#define SNORM2NORM(value) (value * 0.5 + 0.5)

void main() {
	ivec2 imageCoord = ivec2(gl_FragCoord.xy);

	float mapDepth = texelFetch(mapDepthTex, imageCoord, 0).r;
	float modelDepth = texelFetch(modelDepthTex, imageCoord, 0).r;

	float modelDepthMin = modelDepth;
	float modelDepthMax = modelDepth;

	float modelDepth_X;

	modelDepth_X = texelFetchOffset(modelDepthTex, imageCoord, 0, ivec2(-1,  0)).x;
	modelDepthMin = min(modelDepthMin, modelDepth_X); modelDepthMax = max(modelDepthMax, modelDepth_X);

	modelDepth_X = texelFetchOffset(modelDepthTex, imageCoord, 0, ivec2( 1,  0)).x;
	modelDepthMin = min(modelDepthMin, modelDepth_X); modelDepthMax = max(modelDepthMax, modelDepth_X);

	modelDepth_X = texelFetchOffset(modelDepthTex, imageCoord, 0, ivec2( 0, -1)).x;
	modelDepthMin = min(modelDepthMin, modelDepth_X); modelDepthMax = max(modelDepthMax, modelDepth_X);

	modelDepth_X = texelFetchOffset(modelDepthTex, imageCoord, 0, ivec2( 0,  1)).x;
	modelDepthMin = min(modelDepthMin, modelDepth_X); modelDepthMax = max(modelDepthMax, modelDepth_X);

	#if (DEPTH_CLIP01 == 1)
		// Nothing. NDC and window/texture space are same for depth
	#else
		modelDepthMin = NORM2SNORM(modelDepthMin);
		modelDepthMax = NORM2SNORM(modelDepthMax);
	#endif
	
	modelDepthMin = -GetViewSpaceDepth(modelDepthMin);
	modelDepthMax = -GetViewSpaceDepth(modelDepthMax);

	bool cond =
		modelDepthMax / modelDepthMin >= 1.02;


	cond = cond && mapDepth >= modelDepth;

	vec4 validUnit = vec4(cond);
	#if (USE_MATERIAL_INDICES == 1)
		#define MATERIAL_UNITS_MAX_INDEX 127
		#define MATERIAL_UNITS_MIN_INDEX 1

		if (cond) {
			int matIndices = int(texelFetch(modelMiscTex, imageCoord, 0).r * 255.0);
			validUnit *= float( (matIndices >= MATERIAL_UNITS_MIN_INDEX) && (matIndices <= MATERIAL_UNITS_MAX_INDEX) );
		}
	#endif

	gl_FragColor = mix(vec4(0.0), outlineColor, validUnit);
}