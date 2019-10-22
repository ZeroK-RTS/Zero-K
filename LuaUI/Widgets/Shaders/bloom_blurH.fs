#version 120
uniform sampler2D texture0;
uniform float inverseRX;
uniform bool bigBlur;
uniform bool alpha = false;

void main(void) {
	vec2 C0 = vec2(gl_TexCoord[0]);
	vec4 S = texture2D(texture0, C0);
	
	if (!bigBlur){
		// A simple 3-tap blur for DoF
		if (alpha){
			float blur = S.a * 0.5;
			blur += texture2D(texture0, C0 - vec2(inverseRX, 0.0)).a * 0.25;
			blur += texture2D(texture0, C0 + vec2(inverseRX, 0.0)).a * 0.25;
			gl_FragColor = vec4(S.rgb, blur);
		}else{
			S *= 0.5;
			
			S += texture2D(texture0, C0 - vec2(inverseRX, 0.0)) * 0.25;
			S += texture2D(texture0, C0 + vec2(inverseRX, 0.0)) * 0.25;
			gl_FragColor = vec4(S.rgb, 1.0);
		}
	}else{
		// A 9-tap linear sampled blur for bloom.
		S *= 0.141509433;
		
		S += texture2D(texture0, C0 - vec2(1.538461 * inverseRX, 0.0)) * 0.24528301885;
		S += texture2D(texture0, C0 + vec2(1.538461 * inverseRX, 0.0)) * 0.24528301885;
		
		S += texture2D(texture0, C0 - vec2(3.38461538 * inverseRX, 0.0)) * 0.183962264;
		S += texture2D(texture0, C0 + vec2(3.38461538 * inverseRX, 0.0)) * 0.183962264;
		gl_FragColor = vec4(S.rgb, 1.0);
	}
}
