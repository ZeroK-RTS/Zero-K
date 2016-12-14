uniform sampler2D origTex;
uniform sampler2D blurTex;
uniform sampler2D mapdepths;

uniform vec3 eyePos;
uniform mat4 viewProjectionInv;

void main(void) {
	vec2 C0 = gl_TexCoord[0].st;
	vec4 orig = texture2D(origTex, C0);
	vec4 blur = texture2D(blurTex, C0);
	
	// use the depth from the terrain depth buffer because reading 2x 32 bit buffers is _insane_.
	vec4 worldPos = vec4(vec3(gl_TexCoord[0].st, texture2D(mapdepths, C0).x) * 2.0 - 1.0, 1.0);
	
	// then convert to worldspace coords
	worldPos = viewProjectionInv * worldPos;
	worldPos.xyz = worldPos.xyz / worldPos.w;
	
	float dist = length(eyePos.xz - worldPos.xz);
	float depthFactor = min(dist/(6000.0 + eyePos.y), 0.85);
	
	vec4 color = mix(orig, blur, depthFactor);
	gl_FragColor = vec4(color.rgb, 1.0);
}