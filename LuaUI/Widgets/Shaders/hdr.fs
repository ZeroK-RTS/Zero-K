uniform sampler2D texture0;

void main(void) {
	vec2 C0 = vec2(gl_TexCoord[0]);
	vec4 hdr = texture2D(texture0, C0);

	// white point correction
	// give super bright lights a white shift for an incandescent look
	float mx = max(hdr.r, max(hdr.g, hdr.b));
	if (mx > 1.0) {
		float whiteShift = (mx - 1.0) * 0.85 / (mx + 3.0);
		hdr.rgb = mix(hdr.rgb, vec3(mx), whiteShift);
	}

	hdr.a = 1.0;
	gl_FragColor = hdr;
}
