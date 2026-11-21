#version 420 compatibility
uniform vec3 tint; // beside the border, far from it, and 1/the distance between
uniform float lineWidth; // in pixels
uniform float opacity;
in vec2 pos;
out vec4 result;
###TERRITORY###
###GROUND###
void main() {
	int spot;
	float edge, mex;
	vec4 color = Territory(pos, spot, edge, mex);
	float px = max(max(fwidth(pos.x), fwidth(pos.y)), 0.001);
	float line = (borderMode != 0 ? 1.0 : 0.0) * (1.0 - smoothstep((0.5*lineWidth - 0.5)*px, (0.5*lineWidth + 0.5)*px, edge));
	float shade = mix(tint.x, tint.y, smoothstep(0.0, 1.0, FadeDistance(pos, edge)*tint.z));
	result = OnGround(vec4(color.rgb, opacity * color.a * max(line, shade)), pos);
}
