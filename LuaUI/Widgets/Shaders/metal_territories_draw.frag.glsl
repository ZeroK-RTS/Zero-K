#version 420 compatibility
uniform sampler2D depthTex;
uniform mat4 inverseViewProjection;
uniform vec4 view; // width, height, viewport x, viewport y
uniform vec2 border; // gap and outer side of the border line, in elmos
uniform vec3 ring; // inner and outer radius of the line around the spot, 1/hatching fade distance
uniform vec3 tint; // beside the border, far from it, and 1/the distance between
uniform vec3 stripes; // the hatching lines' normal over their spacing, and half their width over the spacing
uniform float hatching; // 1 draws the hatching, 0 hides it
uniform float opacity;
uniform int clipZeroToOne;
out vec4 result;
###TERRITORY###
###GROUND###
void main() {
	vec2 uv = (gl_FragCoord.xy - view.zw) / view.xy;
	float d = texture(depthTex, uv).r;
	if (d >= 1.0) discard;
	float z = clipZeroToOne != 0 ? d : 2.0*d - 1.0;
	vec4 world = inverseViewProjection * vec4(2.0*uv - 1.0, z, 1.0);
	vec2 pos = world.xz / world.w;
	if (any(lessThan(pos, vec2(0.0))) || any(greaterThanEqual(pos, mapSize))) discard;
	int spot;
	float edge, r;
	vec4 color = Territory(pos, spot, edge, r);
	// World-space stripes, with a pixel-width antialiased edge.
	float stripe = dot(pos, stripes.xy);
	float aa = max(fwidth(stripe), 0.001);
	float hatch = 1.0 - smoothstep(stripes.z - aa, stripes.z + aa, abs(fract(stripe) - 0.5));
	// At subpixel stripe sizes use the mean coverage, avoiding distant shimmer.
	hatch = mix(hatch, min(2.0*stripes.z, 1.0), smoothstep(0.25, 1.0, aa));
	// Gap, solid border, then hatching that fades out; the same line around each
	// mex of the territory with hatching outside it; elsewhere a tint that fades away from both
	// lines. The edge distance can jump where the nearest edges change, so
	// antialias with the pixel size in elmos. With no gap neighbouring borders touch.
	float px = max(max(fwidth(pos.x), fwidth(pos.y)), 0.001);
	float fade = FadeDistance(pos, edge);
	float lines = borderMode != 0 ? 1.0 : 0.0;
	float inner = mix(1.0, smoothstep(border.x - px, border.x + px, edge), border.x > 0.0 ? lines : 0.0);
	float outer = smoothstep(border.y - px, border.y + px, edge);
	float ringInner = smoothstep(ring.x - px, ring.x + px, r);
	float ringOuter = smoothstep(ring.y - px, ring.y + px, r);
	float line = max(lines * (inner - outer), ringInner - ringOuter);
	float near = max(lines * outer * (1.0 - smoothstep(0.0, 1.0, (fade - border.y)*ring.z)),
		ringOuter * (1.0 - smoothstep(0.0, 1.0, (r - ring.y)*ring.z)));
	float shade = mix(tint.x, tint.y, smoothstep(0.0, 1.0, min(fade - border.y, r - ring.y)*tint.z));
	result = OnGround(vec4(color.rgb, opacity * color.a * inner * max(line, max(hatching * near * hatch, shade))), pos);
}
