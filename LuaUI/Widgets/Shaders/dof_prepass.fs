#version 120

uniform sampler2D origTex;
uniform sampler2D depthTex;
uniform mat4 projection;

const vec2 autofocusTestCoordOffsets[] = vec2[](
	vec2(0.45, 0.45),
	vec2(0.5, 0.475),
	vec2(0.55, 0.45),
	vec2(0.475, 0.5),
	vec2(0.525, 0.5),
	vec2(0.45, 0.55),
	vec2(0.5, 0.525),
	vec2(0.55, 0.55)
);

float getDistance(vec2 pos){
	float ndcDepth = texture2D(depthTex, pos).x * 2.0 - 1.0;
	return (projection[3][2] / (projection[2][2] + ndcDepth));
}

void main(void) {
	vec2 uv = gl_TexCoord[0].st;
	vec4 color = texture2D(origTex, uv);
	
	float refDist = getDistance(vec2(0.5, 0.5));
	for (int i = 0; i < 8; i++){
		refDist = min(refDist, getDistance(autofocusTestCoordOffsets[i]));
	}
	float dist = getDistance(uv);
	
	float depthFactor = ((dist/refDist) - 1.0);
	
	if (depthFactor < 0.0){
		depthFactor = sqrt(-depthFactor);
	}else{
		depthFactor /= depthFactor + 1.0;
	}
	
	float centerfactor = max(abs((uv.s / 0.5) - 1.0), abs((uv.t / 0.5) - 1.0)); // blur more as you move away from the screen center.
	centerfactor *= centerfactor * 0.5;
	depthFactor += centerfactor;
	depthFactor = min(1.0, depthFactor);
	color.a = depthFactor;
	
	gl_FragColor = color;
}