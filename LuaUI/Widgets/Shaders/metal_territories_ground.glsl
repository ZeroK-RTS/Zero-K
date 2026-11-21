// Bright ground compensation: where the lit ground is bright, a darker colour
// that is more opaque, for contrast. The ground is the map's minimap image times
// its lighting, as the minimap draws it. Dark ground is unchanged.
uniform sampler2D ground;
uniform sampler2D shading;
uniform float brightGround; // 0 off, 1 the strongest
vec4 OnGround(vec4 color, vec2 pos) {
	if (brightGround <= 0.0) return color;
	vec3 lit = texture(shading, pos / mapSize).rgb * texture(ground, pos / mapSize).rgb;
	float k = brightGround * smoothstep(0.25, 0.5, dot(lit, vec3(0.299, 0.587, 0.114)));
	return vec4(color.rgb * (1.0 - 0.6*k), min(color.a * (1.0 + 1.5*k), 1.0));
}
