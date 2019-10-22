// by aeonios, based on the original circular blur shader by Kleber Garcia aka "Kecho"
// https://github.com/kecho/CircularDofFilterGenerator

#version 120

uniform sampler2D downscaleTex;
uniform float inverseRX;

const vec4 kernelValues[] = vec4[](
	vec4(0.054439, -0.087507, 0.000443, 0.035207),
	vec4(0.050267, 0.193969, 0.141716, 0.058179),
	vec4(0.250092, 0.000000, 0.250092, 0.000000),
	vec4(0.050267, 0.193969, 0.141716, 0.058179),
	vec4(0.054439, -0.087507, 0.000443, 0.035207)
);

const int KERNEL_RADIUS = 2;
const float MAX_RADIUS = 1.0;

void main(void) {
	vec2 uv = gl_TexCoord[0].st;
	float filterRadius = max(0.0, 2.0 * (texture2D(downscaleTex, uv).a - 0.5)) * MAX_RADIUS;
	
	vec4 valR = vec4(0,0,0,0);
	vec4 valG = vec4(0,0,0,0);
	vec4 valB = vec4(0,0,0,0);
	
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; i++)
    {
        vec2 coords = uv + inverseRX * vec2(float(i), 0.0) * filterRadius;
        vec3 imageTexel = texture2D(downscaleTex, coords).rgb;
		imageTexel *= imageTexel; // squaring the original color seemed like a trivial extra thing in the shadertoy example, but it's necessary to keep the colors correct.
        vec4 kernel = kernelValues[i+KERNEL_RADIUS];
        valR += imageTexel.r * kernel;
		valG += imageTexel.g * kernel;
		valB += imageTexel.b * kernel;
    }
	
	gl_FragData[0] = valR;
	gl_FragData[1] = valG;
	gl_FragData[2] = valB;
}