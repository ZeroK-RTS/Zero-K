uniform sampler2D origTex;
uniform sampler2D downscaleTex;
uniform sampler2D blurTex;
uniform sampler2D bloomTex;

uniform float bloomFactor;

void main(void) {
	vec2 C0 = gl_TexCoord[0].st;
	vec4 color;
	
	#if USE_DOF > 0
		float depthFactor = texture2D(downscaleTex, C0).a;
		#if USE_HQ > 0
			depthFactor = min(1.0, 2.0 * depthFactor);
			vec4 orig = texture2D(origTex, C0);
			vec4 blur = texture2D(blurTex, C0);
			color = mix(orig, blur, depthFactor);
		#else
			if (depthFactor <= 0.5){
				vec4 orig = texture2D(origTex, C0);
				vec4 downscale = texture2D(downscaleTex, C0);
				color = mix(orig, downscale, depthFactor * 2.0);
			}else{
				vec4 downscale = texture2D(downscaleTex, C0);
				vec4 blur = texture2D(blurTex, C0);
				color = mix(downscale, blur, (depthFactor - 0.5) * 2.0);
			}
		#endif
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
	
	gl_FragColor = vec4(color.rgb, 1.0);
}