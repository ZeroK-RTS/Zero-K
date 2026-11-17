#version 420 compatibility
uniform sampler2D seeds;
uniform sampler2D edges;
uniform vec2 texelSize;
out vec4 result;
###EDGE_DISTANCE###
void main() {
	vec4 seed = texelFetch(seeds, ivec2(gl_FragCoord.xy), 0);
	vec2 pos = gl_FragCoord.xy * texelSize;
	float d = seed.x > 0.5 ? SegmentDistance(edges, int(seed.y + 0.5) - 1, int(seed.x + 0.5) - 1, pos) : 1e6;
	result = vec4(d, 0.0, 0.0, 1.0);
}
