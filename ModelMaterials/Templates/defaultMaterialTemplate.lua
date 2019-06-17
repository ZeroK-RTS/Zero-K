local shaderTemplate = {
vertex = [[
	//shader version is added via gadget
	%%GLOBAL_NAMESPACE%%
	#line 10005

	/***********************************************************************/
	// Options in use
	#define OPTION_SHADOWMAPPING 0
	#define OPTION_NORMALMAPPING 1
	#define OPTION_MOVING_THREADS 2
	#define OPTION_VERTEX_AO 3
	#define OPTION_FLASHLIGHTS 4
	#define OPTION_UNITSFOG 5
	#define OPTION_NORMALMAP_FLIP 6
	#define OPTION_METAL_HIGHLIGHT 7
	#define OPTION_TREEWIND 8
	%%EXTRA_OPTIONS%%

	/***********************************************************************/
	// Definitions
	#define BITMASK_FIELD(value, pos) ((uint(value) & (1u << uint(pos))) != 0u)

	//For a moment let's pretend we have passed OpenGL 2.0 gl_XYZ era
	#define modelMatrix gl_ModelViewMatrix			// don't trust the ModelView name, it's modelMatrix in fact
	#define modelNormalMatrix gl_NormalMatrix		// gl_NormalMatrix seems to represent world space model matrix

	/***********************************************************************/
	// Matrix uniforms
	uniform mat4 viewMatrix;
	uniform mat4 projectionMatrix;
	uniform mat4 shadowMatrix;

	/***********************************************************************/
	// Uniforms
	uniform vec3 cameraPos; // world space camera position
	uniform vec3 cameraDir; // forward vector of camera

	uniform vec3 rndVec; //engine supplied
	uniform int simFrame;
	uniform int drawFrame; //TODO dblcheck if it works

	uniform vec4 floatOptions;
	uniform int bitOptions;

	%%VERTEX_GLOBAL_NAMESPACE%%

	/***********************************************************************/
	// Varyings
	out Data {
		// TBN matrix components
		vec3 worldTangent;
		vec3 worldBitangent;
		vec3 worldNormal;
		// main light vector(s)
		vec3 worldCameraDir;

		// main textureCoord
		vec2 modelUV;

		// shadowPosition
		vec4 shadowVertexPos;

		// auxilary varyings
		vec4 addColor;
		float aoTerm;
		float selfIllumMod;
		float fogFactor;

		// extra varyings
		%%EXTRA_VARYINGS%%
	};

	/***********************************************************************/
	// Vertex shader main()
	void main(void)
	{
		vec4 modelVertexPos = gl_Vertex;
		vec3 modelVertexNormal = gl_Normal;

		%%VERTEX_PRE_TRANSFORM%%

		vec4 worldVertexPos = modelMatrix * modelVertexPos;

		/***********************************************************************/
		// Main vectors for lighting
		// V
		worldCameraDir = normalize(cameraPos - worldVertexPos.xyz); //from fragment to camera, world space

		if (BITMASK_FIELD(bitOptions, OPTION_SHADOWMAPPING)) {
			shadowVertexPos = shadowMatrix * worldVertexPos;
			shadowVertexPos.xy += vec2(0.5);  //no need for shadowParams anymore
		}

		if (BITMASK_FIELD(bitOptions, OPTION_NORMALMAPPING)) {
			//no need to do Gram-Schmidt re-orthogonalization, because engine does it for us anyway
			vec3 T = gl_MultiTexCoord5.xyz;
			vec3 B = gl_MultiTexCoord6.xyz;

			// tangent --> world space transformation (for vectors)
			worldTangent = modelNormalMatrix * T;
			worldBitangent = modelNormalMatrix * B;
			worldNormal = modelNormalMatrix * modelVertexNormal;
		} else {
			worldNormal = modelNormalMatrix * modelVertexNormal;
		}

		modelUV = gl_MultiTexCoord0.xy;
		if (BITMASK_FIELD(bitOptions, OPTION_MOVING_THREADS)) {
			const vec4 treadBoundaries = vec4(0.6279296875, 0.74951171875, 0.5702890625, 0.6220703125);

			if ( all(bvec4(
					greaterThanEqual(modelUV, treadBoundaries.xz),
					lessThanEqual(modelUV, treadBoundaries.yw)))) {
				modelUV.x += floatOptions.x;
			}
		}

		if (BITMASK_FIELD(bitOptions, OPTION_VERTEX_AO)) {
			aoTerm = max(0.4, fract(gl_MultiTexCoord0.s * 16384.0) * 1.3); // great
		}

		if (BITMASK_FIELD(bitOptions, OPTION_FLASHLIGHTS)) {
			// modelMatrix[3][0] + modelMatrix[3][2] are Tx, Tz elements of translation of matrix
			selfIllumMod = max(-0.2, sin(simFrame * 0.067 + (modelMatrix[3][0] + modelMatrix[3][2]) * 0.1)) + 0.2;
		}

		if (BITMASK_FIELD(bitOptions, OPTION_METAL_HIGHLIGHT)) {
			//	local alpha = (0.25*(intensity/100)) + (0.5 * (intensity/100) * math.abs(1 - (timer * 2) % 2))

			//	local x100  = 100  / (100  + metal)
			//	local x1000 = 1000 / (1000 + metal)
			//	local r = 1 - x1000
			//	local g = x1000 - x100
			//	local b = x100

			//#define wreckMetal floatOptions.w
			float wreckMetal = 20.0;

			float alpha = 0.25 + 0.75 * mod(simFrame * 0.022, 1.0);
			vec2 x100_1000 = vec2(100.0 / (100.0 + wreckMetal), 1000.0 / (1000.0 + wreckMetal));
			addColor = vec4(1.0 - x100_1000.y, x100_1000.y - x100_1000.x, x100_1000.x, alpha);

			//#undef wreckMetal
		}

		gl_Position = projectionMatrix * viewMatrix * worldVertexPos;

		%%VERTEX_POST_TRANSFORM%%

		if (BITMASK_FIELD(bitOptions, OPTION_UNITSFOG)) {
			float fogCoord = length(gl_Position.xyz);
			fogFactor = (gl_Fog.end - fogCoord) * gl_Fog.scale; //linear

			// these two don't work correctly as they should. Probably gl_Fog.density is not set correctly
			//fogFactor = exp(-gl_Fog.density * fogCoord); //exp
			//fogFactor = exp(-pow((gl_Fog.density * fogCoord), 2.0)); //exp2

			fogFactor = clamp(fogFactor, 0.0, 1.0);
		}
	}
]],
fragment = [[
	//shader version is added via gadget
	%%GLOBAL_NAMESPACE%%

	/***********************************************************************/
	// Options in use
	#define OPTION_SHADOWMAPPING 0
	#define OPTION_NORMALMAPPING 1
	#define OPTION_MOVING_THREADS 2
	#define OPTION_VERTEX_AO 3
	#define OPTION_FLASHLIGHTS 4
	#define OPTION_UNITSFOG 5
	#define OPTION_NORMALMAP_FLIP 6
	#define OPTION_METAL_HIGHLIGHT 7
	#define OPTION_TREEWIND 8
	%%EXTRA_OPTIONS%%

	/***********************************************************************/
	// Definitions
	#define BITMASK_FIELD(value, pos) ((uint(value) & (1u << uint(pos))) != 0u)

	#define NORM2SNORM(value) (value * 2.0 - 1.0)
	#define SNORM2NORM(value) (value * 0.5 + 0.5)

	#if (DEFERRED_MODE == 1)
		#define GBUFFER_NORMTEX_IDX 0
		#define GBUFFER_DIFFTEX_IDX 1
		#define GBUFFER_SPECTEX_IDX 2
		#define GBUFFER_EMITTEX_IDX 3
		#define GBUFFER_MISCTEX_IDX 4

		#define GBUFFER_COUNT 5
	#endif

	%%FRAGMENT_GLOBAL_NAMESPACE%%
	#line 20169


	/***********************************************************************/
	// Sampler uniforms
	uniform sampler2D texture1;
	uniform sampler2D texture2;
	uniform sampler2D normalTex;
	uniform samplerCube reflectTex;
	uniform sampler2DShadow shadowTex;

	/***********************************************************************/
	// Sunlight uniforms
	uniform vec3 sunDir;
	uniform vec3 sunDiffuse;
	uniform vec3 sunAmbient;
	uniform vec3 sunSpecular;
	uniform vec3 sunSpecularParams; // Exponent, multiplier, bias


	/***********************************************************************/
	// Misc. uniforms
	uniform vec4 teamColor;
	uniform float shadowDensity;
	uniform int shadowsQuality;
	uniform int materialIndex;

	uniform vec3 rndVec; //engine supplied
	uniform int simFrame;
	uniform int drawFrame; //TODO dblcheck if it works

	uniform vec4 floatOptions;
	uniform int bitOptions;


	/***********************************************************************/
	// Shadow mapping quality params
	struct ShadowQuality {
		float samplingRandomness;	// 0.0 - blocky look, 1.0 - random points look
		float samplingDistance;		// how far shadow samples go (in shadowmap texels) as if it was applied to 8192x8192 sized shadow map
		int shadowSamples;			// number of shadowmap samples per fragment
	};

	#define SHADOW_QUALITY_PRESETS 4
	const ShadowQuality shadowQualityPresets[SHADOW_QUALITY_PRESETS] = ShadowQuality[](
		ShadowQuality(0.0, 0.0, 1),	// hard
		ShadowQuality(1.0, 1.0, 3),	// soft
		ShadowQuality(0.4, 2.0, 6),	// softer
		ShadowQuality(0.4, 3.0, 8)	// softest
	);

	/***********************************************************************/
	// Varyings
	in Data {
		// TBN matrix components
		vec3 worldTangent;
		vec3 worldBitangent;
		vec3 worldNormal;

		// main light vector(s)
		vec3 worldCameraDir;

		// main textureCoord
		vec2 modelUV;

		// shadowPosition
		vec4 shadowVertexPos;

		// auxilary varyings
		vec4 addColor;
		float aoTerm;
		float selfIllumMod;
		float fogFactor;

		// extra varyings
		%%EXTRA_VARYINGS%%
	};

	/***********************************************************************/
	// Shadow mapping functions
	const float PI = acos(0.0) * 2.0;

	// http://blog.marmakoide.org/?p=1
	const float goldenAngle = PI * (3.0 - sqrt(5.0));
	vec2 SpiralSNorm(int i, int N) {
		float theta = float(i) * goldenAngle;
		float r = sqrt(float(i)) / sqrt(float(N));
		return vec2 (r * cos(theta), r * sin(theta));
	}

	float hash12L(vec2 p) {
		const float HASHSCALE1 = 0.1031;
		vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
		p3 += dot(p3, p3.yzx + 19.19);
		return fract((p3.x + p3.y) * p3.z);
	}

	// Derivatives of light-space depth with respect to texture2D coordinates
	vec2 DepthGradient(vec3 xyz) {
		vec2 dZduv = vec2(0.0, 0.0);

		vec3 dUVZdx = dFdx(xyz);
		vec3 dUVZdy = dFdy(xyz);

		dZduv.x  = dUVZdy.y * dUVZdx.z;
		dZduv.x -= dUVZdx.y * dUVZdy.z;

		dZduv.y  = dUVZdx.x * dUVZdy.z;
		dZduv.y -= dUVZdy.x * dUVZdx.z;

		float det = (dUVZdx.x * dUVZdy.y) - (dUVZdx.y * dUVZdy.x);
		dZduv /= det;

		return dZduv;
	}

	float BiasedZ(float z0, vec2 dZduv, vec2 offset) {
		return z0 + dot(dZduv, offset);
	}

	float GetShadowPCFRandom(float NdotL) {
		float shadow = 0.0;

		vec3 shadowCoord = shadowVertexPos.xyz / shadowVertexPos.w;
		int presetIndex = clamp(shadowsQuality, 0, SHADOW_QUALITY_PRESETS - 1);

		float samplingRandomness = shadowQualityPresets[presetIndex].samplingRandomness;
		float samplingDistance = shadowQualityPresets[presetIndex].samplingDistance;
		int shadowSamples = shadowQualityPresets[presetIndex].shadowSamples;

		if (shadowSamples > 1) {
			vec2 dZduv = DepthGradient(shadowCoord.xyz);

			float rndRotAngle = NORM2SNORM(hash12L(gl_FragCoord.xy)) * PI / 2.0 * samplingRandomness;

			vec2 vSinCos = vec2(sin(rndRotAngle), cos(rndRotAngle));
			mat2 rotMat = mat2(vSinCos.y, -vSinCos.x, vSinCos.x, vSinCos.y);

			vec2 filterSize = vec2(samplingDistance / 8192.0);

			for (int i = 0; i < shadowSamples; ++i) {
				// SpiralSNorm return low discrepancy sampling vec2
				vec2 offset = (rotMat * SpiralSNorm( i, shadowSamples )) * filterSize;

				vec3 shadowSamplingCoord = vec3(shadowCoord.xy, 0.0) + vec3(offset, BiasedZ(shadowCoord.z, dZduv, offset));
				shadow += texture( shadowTex, shadowSamplingCoord );
			}
			shadow /= float(shadowSamples);
		} else { //shadowSamples == 0
			const float cb = 0.00005;
			float bias = cb * tan(acos(NdotL));
			bias = clamp(bias, 0.0, 5.0 * cb);

			vec3 shadowSamplingCoord = shadowCoord;
			shadowSamplingCoord.z -= bias;
			shadow = texture( shadowTex, shadowSamplingCoord );
		}
		return shadow;
	}

	/***********************************************************************/
	// Shader output definitions
	#if (DEFERRED_MODE == 1)
		out vec4 fragData[GBUFFER_COUNT];
	#else
		out vec4 fragData[1];
	#endif

	/***********************************************************************/
	// Fragment shader main()
	void main(void){
		%%FRAGMENT_PRE_SHADING%%
		#line 30342

		vec4 texColor1 = texture(texture1, modelUV);
		vec4 texColor2 = texture(texture2, modelUV);

		// N - worldFragNormal
		vec3 N;
		if (BITMASK_FIELD(bitOptions, OPTION_NORMALMAPPING)) {
			vec2 nmUV = modelUV;
			if (BITMASK_FIELD(bitOptions, OPTION_NORMALMAP_FLIP)) {
				nmUV.y = 1.0 - nmUV.y;
			}
			vec3 tbnNormal = normalize(NORM2SNORM(texture(normalTex, nmUV).xyz));
			#if 1 //TODO, check if required
				N = mat3(normalize(worldTangent), normalize(worldBitangent), normalize(worldNormal)) * tbnNormal;
			#else
				N = mat3(worldTangent, worldBitangent, worldNormal) * tbnNormal;
			#endif
		} else {
			N = normalize(worldNormal);
		}

		// L - worldLightDir
		/// Sun light is considered infinitely far, so it stays same no matter worldVertexPos.xyz
		vec3 L = normalize(sunDir); //from fragment to light, world space

		// V - worldCameraDir
		vec3 V = normalize(worldCameraDir);

		// H - worldHalfVec
		vec3 H = normalize(L + V); //half vector

		// R - reflection of worldCameraDir against worldFragNormal
		vec3 Rv = -reflect(V, N);

		// N.L
		float NdotLu = dot(N, L);
		float NdotL = max(NdotLu, 1e-3);

		// N.H
		float HdotN = max(dot(N, H), 1e-3);

		// shadows
		float nShadow = smoothstep(0.0, 0.35, NdotLu); //normal based shadowing, always on
		float gShadow = 1.0; // shadow mapping
		if (BITMASK_FIELD(bitOptions, OPTION_SHADOWMAPPING)) {
			gShadow = GetShadowPCFRandom(NdotL);
		}
		float shadow = min(nShadow, gShadow);
		float shadowMult = mix(1.0, shadow, shadowDensity);

		// ambient occlusion
		float ao = 1.0;
		if (BITMASK_FIELD(bitOptions, OPTION_VERTEX_AO)) {
			ao = aoTerm;
		}

		// light
		vec3 lightAmbient = ao * sunAmbient;
		vec3 lightDiffuse = NdotL * sunDiffuse;

		// sunSpecularParams = (exponent, multiplier, bias)
		vec3 lightSpecular = sunSpecular * pow(HdotN, sunSpecularParams.x);
		lightSpecular *= sunSpecularParams.z + texColor2.g * sunSpecularParams.y;

		// apply shadows
		vec3 lightAD = lightAmbient + lightDiffuse * shadowMult;
		lightSpecular *= shadowMult;

		// environment reflection
		vec3 lightADR = texture(reflectTex,  Rv).rgb;
		lightADR = mix(lightAD, lightADR, texColor2.g);

		// emissive color
		vec3 emissiveMult = texColor2.rrr;
		if (BITMASK_FIELD(bitOptions, OPTION_FLASHLIGHTS)) {
			emissiveMult *= selfIllumMod;
		}

		// final color
		vec3 finalColor;
		finalColor = mix(texColor1.rgb, teamColor.rgb, texColor1.a); //mix diffuse texture with team color
		finalColor = finalColor.rgb * (lightADR + emissiveMult) + lightSpecular;

		if (BITMASK_FIELD(bitOptions, OPTION_UNITSFOG)) {
			finalColor = mix(gl_Fog.color.rgb, finalColor, fogFactor);
		}

		if (BITMASK_FIELD(bitOptions, OPTION_METAL_HIGHLIGHT)) {
			finalColor = mix(finalColor, addColor.aaa, addColor.rgb);
		}

		#if 0
			finalColor = addColor;
		#endif

		#if (DEFERRED_MODE == 0)
			fragData[0] = vec4(finalColor, texColor2.a);
		#else
			fragData[GBUFFER_NORMTEX_IDX] = vec4(SNORM2NORM(N), 1.0);
			fragData[GBUFFER_DIFFTEX_IDX] = vec4(finalColor, texColor2.a); //TODO, fix finalColor
			fragData[GBUFFER_SPECTEX_IDX] = vec4(lightSpecular, texColor2.a);
			fragData[GBUFFER_EMITTEX_IDX] = vec4(texColor2.rrr, 1.0);
			fragData[GBUFFER_MISCTEX_IDX] = vec4(float(materialIndex) / 255.0, 0.0, 0.0, 0.0);
		#endif

		%%FRAGMENT_POST_SHADING%%
	}
]],
	uniformInt = {
		texture1 	= 0,
		texture2 	= 1,
		shadowTex	= 2,
		reflectTex	= 4,
		normalTex	= 5,
	},
	uniformFloat = {
		sunAmbient		= {gl.GetSun("ambient" ,"unit")},
		sunDiffuse		= {gl.GetSun("diffuse" ,"unit")},
		sunSpecular		= {gl.GetSun("specular" ,"unit")},
		shadowDensity	=  gl.GetSun("shadowDensity" ,"unit"),
	},
}

local defaultMaterialTemplate = {
	--standardUniforms --locs, set by api_cus
	--deferredUniforms --locs, set by api_cus

	shader = shaderTemplate, -- `shader` is replaced with standardShader later in api_cus
	deferred = shaderTemplate, -- `deferred` is replaced with deferredShader later in api_cus

	shaderDefinitions = {
		"#define DEFERRED_MODE 0",
	},
	deferredDefinitions = {
		"#define DEFERRED_MODE 1",
	},

	shaderOptions = {
		shadowmapping 	= true,
		normalmapping 	= false,
		threads 		= false,
		vertex_ao		= false,
		flashlights		= false,
		unitsfog		= false,
		normalmap_flip	= false,
		treewind		= false,

		shadowsQuality	= 2,
		materialIndex	= 0,
		sunSpecularParams = {18.0, 4.0, 0.0}, -- Exponent, multiplier, bias
	},

	deferredOptions = {
		shadowmapping 	= true,
		normalmapping 	= false,
		threads 		= false,
		vertex_ao		= false,
		flashlights		= false,
		unitsfog		= false,
		normalmap_flip	= false,
		treewind		= false,

		shadowsQuality	= 0,
		materialIndex	= 0,
		sunSpecularParams = {18.0, 4.0, 0.0}, -- Exponent, multiplier, bias
	},

	feature = false,

	texUnits = {},

	predl = nil, -- `predl` is replaced with `prelist` later in api_cus
	postdl = nil, -- `postdl` is replaced with `postlist` later in api_cus

	uuid = nil, -- currently unused (not sent to engine)
	order = nil, -- currently unused (not sent to engine)

	culling = GL.BACK, -- usually GL.BACK is default, except for 3do
	usecamera = false, -- usecamera ? {gl_ModelViewMatrix, gl_NormalMatrix} = {modelViewMatrix, modelViewNormalMatrix} : {modelMatrix, modelNormalMatrix}
}

local shaderPlugins = {
}


--[[
	#define OPTION_SHADOWMAPPING 0
	#define OPTION_NORMALMAPPING 1
	#define OPTION_MOVING_THREADS 2
	#define OPTION_VERTEX_AO 3
	#define OPTION_FLASHLIGHTS 4
	#define OPTION_UNITSFOG 5
	#define OPTION_NORMALMAP_FLIP 6
	#define OPTION_METAL_HIGHLIGHT 7
	#define OPTION_TREEWIND 8
]]--

-- bit = (index - 1)
local knownBitOptions = {
	["shadowmapping"] = 0,
	["normalmapping"] = 1,
	["threads"] = 2,
	["vertex_ao"] = 3,
	["flashlights"] = 4,
	["unitsfog"] = 5,
	["normalmap_flip"] = 6,
	["metal_highlight"] = 7,
	["treewind"] = 8,
}

local knownIntOptions = {
	["shadowsQuality"] = 1,
	["materialIndex"] = 1,

}
local knownFloatOptions = {
	["sunSpecularParams"] = 3,
}

local allOptions = nil

-- Lua limitations only allow to send 24 bits. Should be enough for now.
local function EncodeBitmaskField(bitmask, option, position)
	return math.bit_or(bitmask, ((option and 1) or 0) * math.floor(2 ^ position))
end

local function ProcessOptions(optTable, optName, optValues)
	local handled = false
	if knownBitOptions[optName] then --boolean
		local optValue = tonumber(unpack(optValues or {}) or nil)
		--Spring.Echo(optName, "optValue", optValue)
		if optValue then
			optTable[optName] = (optValue > 0) and true or false
		else
			optTable[optName] = not optTable[optName] -- apparently `not nil` == true
		end
		handled = true
	elseif knownIntOptions[optName] then --integer
		--TODO
		--handled = true
	elseif knownFloatOptions[optName] then --float
		--TODO
		--handled = true
	end
	Spring.Echo("ProcessOptions")
	return handled
end

local function ApplyOptions(luaShader, optionsTbl)
	local intOption = 0

	--Spring.Utilities.TableEcho(optionsTbl, "optionsTbl")

	for optName, optValue in pairs(optionsTbl) do
		if knownBitOptions[optName] then --boolean

			intOption = EncodeBitmaskField(intOption, optValue, knownBitOptions[optName]) --encode options into Int.

		elseif knownIntOptions[optName] then --integer

			if type(optValue) == "number" then
				luaShader:SetUniformInt(optName, optValue)
			elseif type(optValue) == "table" and knownIntOptions[optName] == #optValue then
				luaShader:SetUniformInt(optName, unpack(optValue))
			end

		elseif knownFloatOptions[optName] then --float

			if type(optValue) == "number" then
				luaShader:SetUniformFloat(optName, optValue)
			elseif type(optValue) == "table" and knownFloatOptions[optName] == #optValue then
				luaShader:SetUniformFloat(optName, unpack(optValue))
			end

		end
	end

	Spring.Echo("ApplyOptions")
	luaShader:SetUniformInt("bitOptions", intOption)
end

local function GetAllOptions()
	if not allOptions then
		allOptions = {}
		for k, _ in pairs(knownBitOptions) do
			allOptions[k] = true
		end

		for k, _ in pairs(knownIntOptions) do
			allOptions[k] = true
		end

		for k, _ in pairs(knownFloatOptions) do
			allOptions[k] = true
		end
	end
	return allOptions
end

defaultMaterialTemplate.ProcessOptions = ProcessOptions
defaultMaterialTemplate.ApplyOptions = ApplyOptions
defaultMaterialTemplate.GetAllOptions = GetAllOptions

return defaultMaterialTemplate