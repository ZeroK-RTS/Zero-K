#version 420 compatibility
// Merged territories: each pass gives a spot the lowest group of itself and its
// close spots with the same shown owner.
uniform sampler2D previous;
uniform sampler2D close; // a row per spot: its close spots as index + 1, then 0
uniform sampler2D owners;
uniform sampler2D palette;
out vec4 result;
###SHOWN###
void main() {
	int spot = int(gl_FragCoord.x);
	float shown = Shown(spot);
	float group = texelFetch(previous, ivec2(spot, 0), 0).r;
	for (int k = 0; k < textureSize(close, 0).x; k++) {
		int other = int(texelFetch(close, ivec2(k, spot), 0).r + 0.5) - 1;
		if (other < 0) break;
		if (Shown(other) == shown) group = min(group, texelFetch(previous, ivec2(other, 0), 0).r);
	}
	result = vec4(group, 0.0, 0.0, 1.0);
}
