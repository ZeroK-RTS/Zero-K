#version 420 compatibility
uniform sampler2D edges;
uniform vec2 texelSize;
in vec4 data;
out vec4 result;
###EDGE_DISTANCE###
void main() {
	// Keep the texel's two nearest neighbour edges, as slot + 1 (0 is none).
	vec2 pos = gl_FragCoord.xy * texelSize;
	int cell = int(data.r + 0.5);
	vec2 nearest = vec2(1e30);
	vec2 slots = vec2(0.0);
	for (int i = 0; i < textureSize(edges, 0).x/2; i++) {
		if (texelFetch(edges, ivec2(2*i, cell), 0).xy == vec2(0.0)) break;
		float d = EdgeDistance(edges, i, cell, pos);
		if (d < nearest.x) {
			nearest = vec2(d, nearest.x);
			slots = vec2(float(i + 1), slots.x);
		} else if (d < nearest.y) {
			nearest.y = d;
			slots.y = float(i + 1);
		}
	}
	result = vec4(data.r, 0.0, slots);
}
