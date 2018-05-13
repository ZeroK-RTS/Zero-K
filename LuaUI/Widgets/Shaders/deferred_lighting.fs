//This code authored by Peter Sarkozy aka Beherith (mysterme@gmail.com )
//License is GPL V2
// old version with calced normals is 67 fps for 10 beamers full screen at 1440p
// new version with buffered normals is 88 fps for 10 beamers full screen at 1440p


//#define DEBUG

#define LIGHTRADIUS lightpos.w
uniform sampler2D modelnormals;
uniform sampler2D modeldepths;
uniform sampler2D mapnormals;
uniform sampler2D mapdepths;
uniform sampler2D modelExtra;

uniform vec3 eyePos;
uniform vec4 lightpos;
#if (BEAM_LIGHT == 1)
	uniform vec4 lightpos2;
#endif
uniform vec4 lightcolor;
uniform mat4 viewProjectionInv;

float attenuate(float dist, float radius) {
	// float raw = constant-linear * dist / radius - squared * dist * dist / (radius * radius);
	// float att = clamp(raw, 0.0, 0.5);
	float raw = 0.7 - 0.3 * dist / radius - 1.0 * dist * dist / (radius * radius);
	float att = clamp(raw, 0.0, 1.0);
	return (att * att);
}

void main(void)
{
	float mapDepth = texture2D(  mapdepths, gl_TexCoord[0].st).x;
	float mdlDepth = texture2D(modeldepths, gl_TexCoord[0].st).x;

	#if (CLIP_CONTROL == 1)
	vec4 mappos4   = vec4(  vec3(gl_TexCoord[0].st * 2.0 - 1.0, mapDepth),  1.0);
	vec4 modelpos4 = vec4(  vec3(gl_TexCoord[0].st * 2.0 - 1.0, mdlDepth),  1.0);
	#else
	vec4 mappos4   = vec4(  vec3(gl_TexCoord[0].st, mapDepth) * 2.0 - 1.0,  1.0);
	vec4 modelpos4 = vec4(  vec3(gl_TexCoord[0].st, mdlDepth) * 2.0 - 1.0,  1.0);
	#endif

	vec4 map_normals4   = texture2D(mapnormals  , gl_TexCoord[0].st) * 2.0 - 1.0;
	vec4 model_normals4 = texture2D(modelnormals, gl_TexCoord[0].st) * 2.0 - 1.0;
	vec4 model_extra4   = texture2D(modelExtra  , gl_TexCoord[0].st) * 2.0 - 1.0;


	float specularHighlight = 1.0;
	float model_lighting_multiplier = 1.0; //models recieve additional lighting, looks better.


	if ((mappos4.z - modelpos4.z) > 0.0) {
		// this means we are processing a model fragment, not a map fragment
		if (model_extra4.a > 0.5) {
			map_normals4 = model_normals4;
			mappos4 = modelpos4;
			model_lighting_multiplier = 1.5;
			specularHighlight = specularHighlight + 2.0 * model_extra4.g;
		}
	}


	mappos4 = viewProjectionInv * mappos4;
	mappos4.xyz = mappos4.xyz / mappos4.w;

	vec3 light_direction;

	#if (BEAM_LIGHT == 0)
		light_direction = normalize(lightpos.xyz - mappos4.xyz);

		float dist_light_here = dot(lightpos.xyz - mappos4.xyz, light_direction);
		float cosphi = max(0.0, dot(normalize(map_normals4.xyz), light_direction));
		float attenuation = attenuate(dist_light_here, LIGHTRADIUS);

	#else

		/*distance( Point P,  Segment P0:P1 ) // http://geomalgorithms.com/a02-_lines.html
		{
			v = P1 - P0
			w = P - P0
			if ( (c1 = w dot v) <= 0 )  // before P0
				return d(P, P0)
			if ( (c2 = v dot v) <= c1 ) // after P1
				return d(P, P1)
			b = c1 / c2
			Pb = P0 + bv
			return d(P, Pb)
		}
		*/

		vec3 v = lightpos2.xyz - lightpos.xyz;
		vec3 w = mappos4.xyz   - lightpos.xyz;
		float c1 = dot(v, w);
		float c2 = dot(v, v);

		if (c1 <= 0.0){
			v = mappos4.xyz;
			w = lightpos.xyz;
		} else if (c2 < c1) {
			v = mappos4.xyz;
			w = lightpos2.xyz;
		} else {
			w = lightpos.xyz + (c1 / c2) * v;
			v = mappos4.xyz;
		}

		light_direction = normalize(w.xyz - v.xyz);

		float dist_light_here = dot(w - v, light_direction);
		float cosphi = max(0.0, dot(normalize(map_normals4.xyz), light_direction));
		// float attenuation = max(0.0, (1.0 * LIGHT_CONSTANT - LIGHT_SQUARED * (dist_light_here * dist_light_here) / (LIGHTRADIUS * LIGHTRADIUS) - LIGHT_LINEAR * (dist_light_here) / (LIGHTRADIUS)));
		float attenuation = attenuate(dist_light_here, LIGHTRADIUS);
	#endif

	vec3 viewDirection = normalize(vec3(eyePos - mappos4.xyz));

	// light source on the wrong side?
	if (dot(map_normals4.xyz, light_direction) > 0.02) {
		vec3 reflection = reflect(-1.0 * light_direction, map_normals4.xyz);

		float glossiness = dot(reflection, viewDirection);
		float highlight = pow(max(0.0, glossiness), 8.0);

		specularHighlight *= (0.5 * highlight);
	} else {
		specularHighlight = 0.0;
	}


	//OK, our blending func is the following: Rr=Lr*Dr+1*Dr
	float lightalpha = cosphi * attenuation + attenuation * specularHighlight;
	//dont light underwater:
	lightalpha = clamp(lightalpha, 0.0, lightalpha * ((mappos4.y + 50.0) * (0.02)));

	gl_FragColor = vec4(lightcolor.rgb * lightalpha * model_lighting_multiplier, 1.0);

	#ifdef DEBUG
		gl_FragColor = vec4(map_normals4.xyz, 1.0); //world normals debugging
		gl_FragColor = vec4(fract(modelpos4.z * 0.01),sign(mappos4.z - modelpos4.z), 0.0, 1.0); //world pos debugging, very useful
		if (length(lightcolor.rgb * lightalpha * model_lighting_multiplier) < (1.0 / 256.0)){ //shows light boudaries
			gl_FragColor=vec4(vec3(0.5, 0.0, 0.5), 0.0);
		}
	#endif
}

