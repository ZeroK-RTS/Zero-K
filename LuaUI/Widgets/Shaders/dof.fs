uniform sampler2D origTex;
uniform sampler2D downscaleTex;
uniform sampler2D blurTex;
uniform sampler2D bloomTex;
uniform sampler2D depthTex;

uniform mat4 projection;
uniform float bloomFactor;

float getDistance(vec2 pos){
	float ndcDepth = texture2D(depthTex, pos).x * 2.0 - 1.0;
	return -(projection[3][2] / (projection[2][2] + ndcDepth));
}

void main(void) {
	vec2 C0 = gl_TexCoord[0].st;
	vec4 color;
	
	#if USE_DOF > 0
		float refDist = getDistance(vec2(0.5, 0.5));
		float dist = getDistance(C0);
		float depthFactor = (dist/refDist) - 1.0;
		
		if (depthFactor < 0.0){
			depthFactor *= -3.0;
		}
		
		float centerfactor = max(abs((C0.s / 0.5) - 1.0), abs((C0.t / 0.5) - 1.0)); // blur more as you move away from the screen center.
		centerfactor *= centerfactor * 0.65;
		depthFactor += centerfactor;
		
		if (depthFactor <= 0.5){
			vec4 orig = texture2D(origTex, C0);
			vec4 downscale = texture2D(downscaleTex, C0);
			color = mix(orig, downscale, depthFactor * 2.0);
		}else{
			vec4 downscale = texture2D(downscaleTex, C0);
			vec4 blur = texture2D(blurTex, C0);
			color = mix(downscale, blur, min((depthFactor - 0.5) * 2.0, 1.0));
		}
	#else
		color = texture2D(origTex, C0);
	#endif
	
	#if USE_BLOOM > 0
		vec3 bloomColor = texture2D(bloomTex, C0).rgb;
		float lum = dot(bloomColor, vec3(0.299, 0.587, 0.114));
		bloomColor = mix(bloomColor * lum, bloomColor, lum);
		bloomColor = max(color.rgb, bloomColor);
		color.rgb = mix(color.rgb, bloomColor, bloomFactor);
	#endif
	
	//gl_FragColor = vec4(0.0, depthFactor, depthFactor, 1.0);
	
	gl_FragColor = vec4(color.rgb, 1.0);
}