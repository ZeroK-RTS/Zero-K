// The shown owner at a spot (palette row 1, z): neutral 0, otherwise the colour team + 1.
float Shown(int spot) {
	return texelFetch(palette, ivec2(int(texelFetch(owners, ivec2(spot, 0), 0).r + 0.5), 1), 0).z;
}
