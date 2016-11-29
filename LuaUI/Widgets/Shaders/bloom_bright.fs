uniform sampler2D texture0;
uniform float illuminationThreshold;
uniform float inverseRX;
uniform float inverseRY;

void main(void) {
	vec2 C0 = vec2(gl_TexCoord[0]);
	vec3 color = vec3(texture2D(texture0, C0));
	float illum = dot(color, vec3(0.2990, 0.5870, 0.1140));

	if (illum > illuminationThreshold) {
		// Apply tone mapping when adding to the bloom texture, because otherwise the bloom intensity setting has no effect.
		// white point correction
		const float whiteStart = 2.0; // the minimum color intensity for starting white point transition
		const float whiteMax = 0.35; // the maximum amount of white shifting applied
		const float whiteScale = 0.1; // the rate at which to transition to white 
		
		float mx = max(color.r, max(color.g, color.b));
		if (mx > whiteStart) {
			color.rgb += min(vec3((mx - whiteStart) * whiteScale), vec3(whiteMax));
		}
							
		// tone mapping
		// I'm using exponential exposure for tone mapping here, because reinhard is suseptible
		// to precision overflows which propogate to the blur shaders, causing artifacts.
		color = vec3(1.0) - exp(-color * 1.5);
		color = mix(vec3(dot(color, vec3(0.299, 0.587, 0.114))), color, 1.15); // increase saturation because exponential exposure reduces it.
		gl_FragColor = vec4(color.rgb, 1.0);
		} else {
			gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
		}
	}