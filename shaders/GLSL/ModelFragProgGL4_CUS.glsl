#version 430 core

layout(binding = 0) uniform sampler2D tex1;
layout(binding = 1) uniform sampler2D tex2;

#if (USE_SHADOWS == 1)
	layout(binding = 2) uniform sampler2DShadow shadowTex;
	layout(binding = 3) uniform sampler2D shadowColorTex;
#endif

layout(binding = 4) uniform samplerCube reflectTex;

layout(std140, binding = 1) uniform UniformParamsBuffer {
	vec3 rndVec3; //new every draw frame.
	uint renderCaps; //various render booleans

	vec4 timeInfo;     //gameFrame, gameSeconds, drawFrame, frameTimeOffset
	vec4 viewGeometry; //vsx, vsy, vpx, vpy
	vec4 mapSize;      //xz, xzPO2
	vec4 mapHeight;    //height minCur, maxCur, minInit, maxInit

	vec4 fogColor;  //fog color
	vec4 fogParams; //fog {start, end, 0.0, scale}

	vec4 sunDir;

	vec4 sunAmbientModel;
	vec4 sunAmbientMap;
	vec4 sunDiffuseModel;
	vec4 sunDiffuseMap;
	vec4 sunSpecularModel;
	vec4 sunSpecularMap;

	vec4 shadowDensity; // {ground, units, 0.0, 0.0}

	vec4 windInfo; // windx, windy, windz, windStrength
	vec2 mouseScreenPos; //x, y. Screen space.
	uint mouseStatus; // bits 0th to 32th: LMB, MMB, RMB, offscreen, mmbScroll, locked
	uint mouseUnused;
	vec4 mouseWorldPos; //x,y,z; w=0 -- offmap. Ignores water, doesn't ignore units/features under the mouse cursor

	vec4 teamColor[255]; //all team colors
};

in Data {
	centroid vec4 uvCoord;
	vec4 teamCol;

	vec4 worldPos;
	vec3 worldNormal;

	// main light vector(s)
	vec3 worldCameraDir;
	// shadowPosition
	vec4 shadowVertexPos;
	// Auxilary
	float fogFactor;
};

uniform int shadingMode = 0; //NORMAL_SHADING

uniform vec4 alphaCtrl = vec4(0.0, 0.0, 0.0, 1.0); //always pass
uniform vec4 colorMult = vec4(1.0);
uniform vec4 nanoColor = vec4(0.0);

bool AlphaDiscard(float a) {
	float alphaTestGT = float(a > alphaCtrl.x) * alphaCtrl.y;
	float alphaTestLT = float(a < alphaCtrl.x) * alphaCtrl.z;

	return ((alphaTestGT + alphaTestLT + alphaCtrl.w) == 0.0);
}

vec3 GetShadowMult(vec3 shadowCoord, float NdotL) {
	#if (USE_SHADOWS == 1)
		float sh = min(texture(shadowTex, shadowCoord).r, smoothstep(0.0, 0.35, NdotL));
		vec3 shColor = texture(shadowColorTex, shadowCoord.xy).rgb;
		return mix(1.0, sh, shadowDensity.y) * shColor;
	#else
		return vec3(1.0);
	#endif
}

#if (DEFERRED_MODE == 1)
	out vec4 fragColor[GBUFFER_ZVALTEX_IDX];
#else
	out vec4 fragColor;
#endif

#define NORM2SNORM(value) (value * 2.0 - 1.0)
#define SNORM2NORM(value) (value * 0.5 + 0.5)

void main(void)
{
	vec4 texColor1 = texture(tex1, uvCoord.xy);
	vec4 texColor2 = texture(tex2, uvCoord.xy);

	float alpha = teamCol.a * float(texColor2.a >= 0.5);
	if (AlphaDiscard(alpha))
		discard;

	texColor1.rgb = mix(texColor1.rgb, teamCol.rgb, texColor1.a);
	vec3 finalColor = texColor1.rgb;

	if (shadingMode == 0) { // NORMAL_SHADING
		vec3 L = normalize(sunDir.xyz);
		vec3 V = normalize(worldCameraDir);
		vec3 H = normalize(L + V); //half vector
		vec3 N = normalize(worldNormal);
		vec3 R = -reflect(V, N);

		vec3 reflColor = texture(reflectTex, R).rgb;

		float NdotL = clamp(dot(N, L), 0.0, 1.0);
		float HdotN = clamp(dot(N, H), 0.0, 1.0);

		vec3 shadowMult = GetShadowMult(shadowVertexPos.xyz / shadowVertexPos.w, NdotL);

		vec3 light = sunAmbientModel.rgb + (NdotL * sunDiffuseModel.rgb);

		// A general rule of thumb is to set Blinn-Phong exponent between 2 and 4 times the Phong shininess exponent.
		vec3 specular = sunSpecularModel.rgb * min(pow(HdotN, 2.5 * sunSpecularModel.a) + 0.3 * pow(HdotN, 2.0 * 3.0), 1.0);
		specular *= (texColor2.g * 4.0);

		// no highlights if in shadow; decrease light to ambient level
		specular *= shadowMult;

		light = mix(sunAmbientModel.rgb, light, shadowMult);
		light = mix(light, reflColor, texColor2.g); // reflection
		light += texColor2.rrr; // self-illum

		finalColor = finalColor * light + specular;
	}

	#if (DEFERRED_MODE == 1)
		vec4 diffColor = colorMult * vec4(mix(texColor1.rgb, nanoColor.rgb, nanoColor.a), alpha);
		fragColor[GBUFFER_NORMTEX_IDX] = vec4(SNORM2NORM(worldNormal), 1.0);
		fragColor[GBUFFER_DIFFTEX_IDX] = diffColor;
		fragColor[GBUFFER_SPECTEX_IDX] = vec4(texColor2.rgb, alpha);
		fragColor[GBUFFER_EMITTEX_IDX] = vec4(0.0, 0.0, 0.0, 0.0);
		fragColor[GBUFFER_MISCTEX_IDX] = vec4(255.0, 0.0, 0.0, 0.0);
	#else
		fragColor.rgb = mix(finalColor.rgb, fogColor.rgb, (1.0 - fogFactor) * int(shadingMode == 0) );
		fragColor.rgb = mix(fragColor.rgb ,  nanoColor.rgb, nanoColor.a * int(shadingMode == 0));
		fragColor.a   = alpha;
		fragColor *= colorMult;
	#endif
}