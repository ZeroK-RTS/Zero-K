#version 120

uniform sampler2D downscaleTex;
uniform sampler2D depthTex;

uniform vec2 invResScale;

const vec2[] offsets = vec2[](
	vec2(-1.0, -1.0),
	vec2(0.0, -1.0),
	vec2(1.0, -1.0),
	vec2(-1.0, 0.0),
	vec2(1.0, 0.0),
	vec2(-1.0, 1.0),
	vec2(0.0, 1.0),
	vec2(1.0, 1.0)
);

void main(void) {
	vec2 uv = gl_TexCoord[0].st;
	vec4 color = texture2D(downscaleTex, uv);
	
	float blur = color.a;
	float mindepth = texture2D(depthTex, uv);
	
	for (int i = 0; i < 8; i++){
		vec2 coord = uv + offsets[i] * invResScale;
		float depth = texture2D(depthTex, coord);
		
		if (depth < mindepth){
			mindepth = depth;
			blur = texture2D(downscaleTex, coord).a;
		}
	}
	
	gl_FragColor = vec4(color.rgb, blur);
}