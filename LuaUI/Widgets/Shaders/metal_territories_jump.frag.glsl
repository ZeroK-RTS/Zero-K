#version 420 compatibility
uniform sampler2D previous;
uniform sampler2D edges;
uniform vec2 texelSize;
uniform int step;
out vec4 result;
###EDGE_DISTANCE###
void main() {
	ivec2 pixel = ivec2(gl_FragCoord.xy);
	ivec2 size = textureSize(previous, 0);
	vec2 pos = gl_FragCoord.xy * texelSize;
	float nearest = 1e30;
	result = vec4(0.0);
	for (int k = 0; k < 9; k++) {
		ivec2 other = pixel + step*ivec2(k % 3 - 1, k / 3 - 1);
		if (any(lessThan(other, ivec2(0))) || any(greaterThanEqual(other, size))) continue;
		vec4 seed = texelFetch(previous, other, 0);
		if (seed.x < 0.5) continue;
		float d = SegmentDistance(edges, int(seed.y + 0.5) - 1, int(seed.x + 0.5) - 1, pos);
		if (d < nearest) {
			nearest = d;
			result = seed;
		}
	}
}
