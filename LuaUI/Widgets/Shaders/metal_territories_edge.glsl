// Distance to a neighbour edge: to its line beside the edge, else to its nearer
// end, so a border turning a corner is rounded. Negative on the far side;
// SegmentDistance is the same distance from either side.
float SegmentDistance(sampler2D edges, int slot, int cell, vec2 pos) {
	vec4 line = texelFetch(edges, ivec2(2*slot, cell), 0);
	vec2 extent = texelFetch(edges, ivec2(2*slot + 1, cell), 0).xy;
	float t = dot(vec2(-line.y, line.x), pos);
	return length(vec2(dot(line.xy, pos) + line.z, max(max(extent.x - t, t - extent.y), 0.0)));
}
float EdgeDistance(sampler2D edges, int slot, int cell, vec2 pos) {
	vec4 line = texelFetch(edges, ivec2(2*slot, cell), 0);
	float d = dot(line.xy, pos) + line.z;
	return d < 0.0 ? d : SegmentDistance(edges, slot, cell, pos);
}
