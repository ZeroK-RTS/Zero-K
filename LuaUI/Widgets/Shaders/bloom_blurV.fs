#version 120
uniform sampler2D texture0;
uniform float inverseRY;
uniform bool bigBlur;

void main(void) {
	vec2 C0 = vec2(gl_TexCoord[0]);
	vec4 S = texture2D(texture0, C0);
	
	if (!bigBlur){
		// A simple 3-tap blur for DoF
		S *= 0.5;
		
		S += texture2D(texture0, C0 - vec2(0.0, inverseRY)) * 0.25;
		S += texture2D(texture0, C0 + vec2(0.0, inverseRY)) * 0.25;
	}else{
		// A 5-tap linear sampled blur for bloom.
		S *= 0.141509433;
		
		S += texture2D(texture0, C0 - vec2(0.0, 1.538461 * inverseRY)) * 0.24528301885;
		S += texture2D(texture0, C0 + vec2(0.0, 1.538461 * inverseRY)) * 0.24528301885;
		
		S += texture2D(texture0, C0 - vec2(0.0, 3.38461538 * inverseRY)) * 0.183962264;
		S += texture2D(texture0, C0 + vec2(0.0, 3.38461538 * inverseRY)) * 0.183962264;
	}

	gl_FragColor = vec4(S.rgb, 1.0);
}
