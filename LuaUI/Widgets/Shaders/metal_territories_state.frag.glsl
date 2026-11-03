#version 420 compatibility
uniform sampler2D previousState;
uniform sampler2D observations;
uniform sampler2D positions;
uniform sampler2D los;
uniform vec2 mapSize;
uniform int fullView;
out vec4 result;
void main() {
	ivec2 pixel = ivec2(gl_FragCoord.xy);
	vec4 old = texelFetch(previousState, pixel, 0);
	vec4 seen = texelFetch(observations, pixel, 0);
	vec2 pos = texelFetch(positions, pixel, 0).rg;
	ivec2 size = textureSize(los, 0);
	ivec2 cell = clamp(ivec2(pos / mapSize * vec2(size)), ivec2(0), size - 1);
	// Fetch the binary base level, never filtered or mipmapped LOS.
	bool visible = fullView != 0 || texelFetch(los, cell, 0).r > 0.5;
	float owner = old.r;
	if (seen.b != old.b || seen.g > 0.5) owner = seen.r;
	if (seen.g < 0.5 && visible) owner = 0.0;
	result = vec4(owner, 0.0, seen.b, 1.0);
}
