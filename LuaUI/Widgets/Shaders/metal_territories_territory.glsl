// The shown owner's colour and opacity at a map position, its spot, the exact
// distance to the nearest bordered edge, and the distance to the nearest mex of
// its territory. Neighbours are one territory, with no border between them,
// with the same shown owner when borders are between different owners, else
// when merged. With borders off every other edge counts, so the tint still
// fades from it. The texel's two nearest edges give the distance near them;
// the distance map, when on, gives it farther away. The opacity fades out
// beyond the reach from the spot and the spots across those two edges, or,
// with a border at the reach, the territory ends there at an edge.
uniform sampler2D atlas;
uniform sampler2D owners;
uniform sampler2D palette;
uniform sampler2D edges;
uniform sampler2D positions;
uniform sampler2D groups; // each spot's merged territory, as the lowest spot index in it
uniform sampler2D field; // the distance map: from each texel's centre to the nearest bordered edge, filtered
uniform vec2 mapSize;
uniform int borderMode; // 0 off, 1 every territory, 2 between different owners
uniform int useField;
uniform vec2 reach; // the distance from the metal spots where territories start to fade out, and 1/the fade distance
uniform vec2 reachBorder; // 1 to end territories at the reach instead, and how far in pixels beyond it they are drawn
uniform int opacityChannel; // the owners' opacity on the map (0) or on the minimap (1)
###EDGE_DISTANCE###
###SHOWN###
bool Joined(int spot, int other) {
	if (borderMode == 2) return Shown(other) == Shown(spot);
	return texelFetch(groups, ivec2(other, 0), 0).r == texelFetch(groups, ivec2(spot, 0), 0).r;
}
int Neighbour(int spot, int slot) {
	return int(texelFetch(edges, ivec2(2*slot, spot), 0).w + 0.5);
}
// The distance for fades: also from bordered edges beyond the texel's two
// nearest, with the distance map.
float FadeDistance(vec2 pos, float edge) {
	return useField != 0 ? min(edge, texture(field, pos / mapSize).r) : edge;
}
vec4 Territory(vec2 pos, out int spot, out float edge, out float mex) {
	vec4 territory = texture(atlas, pos / mapSize);
	spot = int(territory.r + 0.5);
	// Within half a texel of an edge the position can be across it from the
	// texel's centre: then use the texel a texel diagonal across the edge.
	for (int k = 0; k < 2; k++) {
		int slot = int(territory[k + 2] + 0.5) - 1;
		if (slot < 0) continue;
		vec4 line = texelFetch(edges, ivec2(2*slot, spot), 0);
		float d = dot(line.xy, pos) + line.z;
		if (d < 0.0) {
			float diagonal = length(mapSize / vec2(textureSize(atlas, 0)));
			territory = texture(atlas, (pos - (d + diagonal)*line.xy) / mapSize);
			spot = int(territory.r + 0.5);
			break;
		}
	}
	int owner = int(texelFetch(owners, ivec2(spot, 0), 0).r + 0.5);
	// Alpha identifies the shown owner.
	vec4 color = texelFetch(palette, ivec2(owner, 0), 0);
	edge = 1e6;
	mex = distance(pos, texelFetch(positions, ivec2(spot, 0), 0).rg);
	float nearest = mex;
	for (int k = 0; k < 2; k++) {
		int slot = int(territory[k + 2] + 0.5) - 1;
		if (slot < 0) continue;
		int other = Neighbour(spot, slot);
		float d = distance(pos, texelFetch(positions, ivec2(other, 0), 0).rg);
		nearest = min(nearest, d);
		if (Joined(spot, other)) {
			mex = min(mex, d);
		} else {
			edge = min(edge, EdgeDistance(edges, slot, spot, pos));
		}
	}
	float fade = 1.0 - smoothstep(0.0, 1.0, (nearest - reach.x)*reach.y);
	if (reachBorder.x != 0.0) {
		// The minimap draws half of its line beyond the edge, as between territories.
		float px = max(max(fwidth(pos.x), fwidth(pos.y)), 0.001);
		edge = min(edge, reach.x - nearest);
		fade = smoothstep(-px, px, reach.x - nearest + reachBorder.y*px);
	}
	return vec4(color.rgb, fade * texelFetch(palette, ivec2(owner, 1), 0)[opacityChannel]);
}
