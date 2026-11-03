#version 420 compatibility
// The distance map starts from each texel's nearest bordered edge of its two
// nearest, if any, as spot + 1 and slot + 1. Each jump flooding pass keeps the
// nearest of the edges of the texel and of the eight texels a step away. The
// last pass gives the distance to the edge found, 1e6 if none.
uniform vec2 texelSize;
out vec4 result;
###TERRITORY###
void main() {
	vec2 pos = gl_FragCoord.xy * texelSize;
	vec4 territory = texture(atlas, pos / mapSize);
	int spot = int(territory.r + 0.5);
	float nearest = 1e30;
	result = vec4(0.0);
	for (int k = 0; k < 2; k++) {
		int slot = int(territory[k + 2] + 0.5) - 1;
		if (slot < 0 || Joined(spot, Neighbour(spot, slot))) continue;
		float d = SegmentDistance(edges, slot, spot, pos);
		if (d < nearest) {
			nearest = d;
			result = vec4(float(spot + 1), float(slot + 1), 0.0, 1.0);
		}
	}
}
