// by aeonios, based on the original circular blur shader by Kleber Garcia aka "Kecho"
// https://github.com/kecho/CircularDofFilterGenerator

#version 120

uniform sampler2D downscaleTex;
uniform sampler2D Rtex;
uniform sampler2D Gtex;
uniform sampler2D Btex;
uniform float inverseRY;

const vec4 kernelValues[] = vec4[](
	vec4(0.054439, -0.087507, 0.000443, 0.035207),
	vec4(0.050267, 0.193969, 0.141716, 0.058179),
	vec4(0.250092, 0.000000, 0.250092, 0.000000),
	vec4(0.050267, 0.193969, 0.141716, 0.058179),
	vec4(0.054439, -0.087507, 0.000443, 0.035207)
);

const int KERNEL_RADIUS = 2;
const float MAX_RADIUS = 1.0;
const vec4 kernelWeights = vec4(0.411259, -0.548794, 0.513282, 4.561110);

vec4 multComplex(vec4 p, vec4 q)
{
    return vec4((p.x * q.x - p.y * q.y), (p.x * q.y + p.y * q.x), (p.z * q.z - p.w * q.w), (p.z * q.w + p.w * q.z));
}

void main(void) {
	vec2 uv = gl_TexCoord[0].st;
	float filterRadius = max(0.0, 2.0 * (texture2D(downscaleTex, uv).a - 0.5)) * MAX_RADIUS;
	
	vec4 valR = vec4(0,0,0,0);
	vec4 valG = vec4(0,0,0,0);
	vec4 valB = vec4(0,0,0,0);
	
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; i++)
    {
        vec2 coords = uv + inverseRY * vec2(0.0, float(i)) * filterRadius;
		
        vec4 imageTexelR = texture2D(Rtex, coords);
		vec4 imageTexelG = texture2D(Gtex, coords);
		vec4 imageTexelB = texture2D(Btex, coords);
		
        vec4 kernel = kernelValues[i+KERNEL_RADIUS];
        valR += multComplex(imageTexelR, kernel);
		valG += multComplex(imageTexelG, kernel);
		valB += multComplex(imageTexelB, kernel);
    }
	
	float redChannel   = dot(valR, kernelWeights);
    float greenChannel = dot(valG, kernelWeights);
    float blueChannel  = dot(valB, kernelWeights);
	
	gl_FragColor = vec4(sqrt(vec3(redChannel, greenChannel, blueChannel)), 1.0);
}