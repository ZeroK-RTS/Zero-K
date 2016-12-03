uniform sampler2D texture0;
uniform sampler2D texture1;
uniform float fragMaxBrightness;
uniform int useBloom;

vec3 toneMapEXP(vec3 color){
	float L = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
	float nL = (1.0 - exp(-L * 0.7)) * 1.5;
	float scale = nL / L;
	return color * scale;
	// return vec3(1.0) - exp(-color * 1.4);
}

vec3 toneMapRein(vec3 color)
{
	float L = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
	float nL = (L * (1.0 + L/1.5)) / (1.0 + L);
	float scale = nL / L;
	return color * scale;
}

vec3 levelsControl(vec3 color, float blackPoint, float whitePoint){
	return min(max(color - vec3(blackPoint), vec3(0.0)) / (vec3(whitePoint) - vec3(blackPoint)), vec3(1.0));
}

void main(void) {
	vec2 C0 = vec2(gl_TexCoord[0]);
	vec4 hdr = bool(useBloom) ? texture2D(texture0, C0) + (texture2D(texture1, C0) * fragMaxBrightness) : texture2D(texture0, C0);

	// white point correction
	// give super bright lights a white shift
	const float whiteStart = 1.0; // the minimum color intensity for starting white point transition
	const float whiteMax = 0.85; // the maximum amount of white shifting applied
	const float whiteScale = 10.0; // the rate at which to transition to white 

	float mx = max(hdr.r, max(hdr.g, hdr.b));
	if (mx > whiteStart) {
		hdr.rgb = mix(hdr.rgb, vec3(mx), (mx - whiteStart)/(((mx - whiteStart) * whiteScale) + 1.0));
	}

	// tone mapping and color correction
	// hdr.rgb = toneMapEXP(hdr.rgb);
	hdr.rgb = toneMapRein(hdr.rgb);
	hdr.rgb = levelsControl(hdr.rgb, 0.02, 0.87);
	hdr.rgb = mix(vec3(dot(hdr.rgb, vec3(0.299, 0.587, 0.114))), hdr.rgb, 0.94);

	vec4 map = vec4(hdr.rgb, 1.0);
					
	gl_FragColor = map;
}
