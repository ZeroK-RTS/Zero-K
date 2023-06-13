local Spring = Spring
local alwaysColor, losColor, radarColor, jamColor, radarColor2 = Spring.GetLosViewColors()

return {
	definitions = {
		Spring.GetConfigInt("HighResInfoTexture") and "#define HIGH_QUALITY" or "",
	},
	vertex = [[
	#version 130
	varying vec2 texCoord;
	void main() {
		texCoord = gl_MultiTexCoord0.st;
		gl_Position = vec4(gl_Vertex.xyz, 1.0);
	}
	]],
	fragment = [[
	#version 130
	#ifdef HIGH_QUALITY
		#extension GL_ARB_texture_query_lod : enable
		#extension GL_EXT_gpu_shader4_1 : enable
	#endif

	uniform float time;
	uniform vec4 alwaysColor;
	uniform vec4 losColor;
	uniform vec4 radarColor;
	uniform vec4 radarColor2;
	uniform vec4 jamColor;
	uniform sampler2D tex0;  // r = Ground LOS
	uniform sampler2D tex1;  // r = Air LOS
	uniform sampler2D tex2;  // r = Radar coverage, g = Jammer coverage
	varying vec2 texCoord;

	#ifdef HIGH_QUALITY
		#if GL_ARB_texture_query_lod == 1
			#define GET_TEXLOD(tex, p) (int(textureQueryLOD(tex, p).x))
		#elif GL_EXT_gpu_shader4_1 == 1
			#define GET_TEXLOD(tex, p) (int(textureQueryLod(tex, p).x))
		#else
			#define GET_TEXLOD(tex, p) (0)
		#endif

		#define HASHSCALE1 443.8975
		float rand(vec2 p) {
			vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
			p3 += dot(p3, p3.yzx + 19.19);
			return fract((p3.x + p3.y) * p3.z);
		}

		//! source: http://www.iquilezles.org/www/articles/texture/texture.htm
		vec4 getTexel(in sampler2D tex, in vec2 p) {
			int lod = GET_TEXLOD(tex, p);
			vec2 texSize = vec2(textureSize(tex, lod));
			vec2 off = vec2(time);
			vec4 c = vec4(0.0);
			for (int i = 0; i < 4; i++) {
				off = (vec2(rand(p.st + off.st), rand(p.ts - off.ts)) * 2.0 - 1.0) / texSize;
				c += texture2D(tex, p + off);
			}
			c *= 0.25;
			return smoothstep(0.5, 1.0, c);
		}
	#else
		#define getTexel texture2D
	#endif

	void main() {
		float los = getTexel(tex0, texCoord).r;
		float airLos = getTexel(tex1, texCoord).r;
		vec2 radarJammer = getTexel(tex2, texCoord).rg;
		float losMix = los*0.9 + airLos*0.1;
		float radar = radarJammer.r;
		float jammer = radarJammer.g;

		// The radarColor2 fringing occurs as an edge case when it has color channels at 1.0
		// The fract() returns 0.0 for that infill while maintaining the edge falloff
		// Our goal is as follows:
		//   - Ensure radarColor fringe is ALWAYS visible
		//   - Ensure radarColor2 fringe is ALWAYS visible
		//   - Ensure radarColor2 infill is ONLY visible in the absence of LOS
		//   - Do not draw radarColor2 infill for color channels set to 1.0
		//   - Ensure jamColor is ALWAYS visible, especially as it almost always is LOS

		gl_FragColor.rgb =  losColor.rgb * losMix;
		gl_FragColor.rgb += jamColor.rgb * jammer;
		gl_FragColor.rgb += fract(radarColor2.rgb) * step(1.0, radar) * (1.0 - los);  // Radar infill
		gl_FragColor.rgb += radarColor2.rgb * fract(step(0.8, radar) * radar);  // Radar inner edge/fringing
		gl_FragColor.rgb += radarColor.rgb * step(0.2, fract(1.0-radar));  // Radar outer edge/fringing
		gl_FragColor.rgb += alwaysColor.rgb;
		gl_FragColor.a = 0.05;
	}]],
	uniformFloat = {
		alwaysColor = alwaysColor,
		losColor    = losColor,
		radarColor  = radarColor,
		jamColor    = jamColor,
		radarColor2 = radarColor2,
	},
	uniformInt = {
		tex0 = 0,
		tex1 = 1,
		tex2 = 2,
		tex3 = 3,
	},
	textures = {
		[0] = "$info:los",
		[1] = "$info:airlos",
		[2] = "$info:radar",
	},
}
