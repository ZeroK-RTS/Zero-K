uniform sampler2D texture0;
uniform sampler2D texture1;
uniform float illuminationThreshold;
uniform float fragMaxBrightness;
uniform int useBloom;
uniform int useHDR;

vec3 toneMapEXP(vec3 color){
	return vec3(1.0) - exp(-color * 1.4);
}

vec3 levelsControl(vec3 color, float blackPoint, float whitePoint){
	return min(max(color - vec3(blackPoint), vec3(0.0)) / (vec3(whitePoint) - vec3(blackPoint)), vec3(1.0));
}

void main(void) {
	vec2 C0 = vec2(gl_TexCoord[0]);
	vec4 S0 = texture2D(texture0, C0);
	vec4 S1;
	if (bool(useBloom)){
		S1 = texture2D(texture1, C0);
		S1 = S1 * fragMaxBrightness;
	}

	vec4 hdr = bool(useBloom) ? S1 + S0 : S0;

	if (bool(useHDR)){
		// white point correction
		// give super bright lights a white shift
		const float whiteStart = 1.0; // the minimum color intensity for starting white point transition
		const float whiteMax = 0.5; // the maximum amount of white shifting applied
		const float whiteScale = 0.15; // the rate at which to transition to white 
	
		float mx = max(hdr.r, max(hdr.g, hdr.b));
		if (mx > whiteStart) {
			hdr.rgb = mix(hdr.rgb, vec3(mx), 1.0 - exp(-(mx - whiteStart) * 0.15));
		}

		// tone mapping
		hdr.rgb = toneMapEXP(hdr.rgb);
		hdr.rgb = levelsControl(hdr.rgb, 0.15, 0.85);
		hdr.rgb = mix(vec3(dot(hdr.rgb, vec3(0.299, 0.587, 0.114))), hdr.rgb, 1.05);
	}

	vec4 map = vec4(hdr.rgb, 1.0);
					
	gl_FragColor = map;
}