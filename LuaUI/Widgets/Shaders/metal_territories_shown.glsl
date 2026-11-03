// The shown owner's identity at a spot (its palette alpha); neutral is 0.
float Shown(int spot) {
	return texelFetch(palette, ivec2(int(texelFetch(owners, ivec2(spot, 0), 0).r + 0.5), 0), 0).a;
}
