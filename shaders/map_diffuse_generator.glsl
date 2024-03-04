uniform sampler2D tex0; // unqualified heightfield
uniform sampler2D tex1; // 2d normals
uniform sampler2D tex2; // hard rock texture
uniform sampler2D tex3; // flats texture (tier0)
uniform sampler2D tex4; // beach texture (tier-1)
uniform sampler2D tex5; // mid-altitude flats (tier1, grassland)
uniform sampler2D tex6; // high-altitude flats (tier2)
uniform sampler2D tex7; // hillside texture
uniform sampler2D tex8; // ramp texture
uniform sampler2D tex9; // cloud grass
uniform sampler2D tex10; // cloud grassdark
uniform sampler2D tex11; // cloud sand

uniform float minHeight;
uniform float maxHeight;

// should these be uniforms?
const float hardCliffMax = 1.0; // sharpest bot-blocking cliff
const float hardCliffMin = 0.58778525229; // least sharp bot-blocking cliff

const float vehCliff = 0.4546;
const float botCliff = 0.8065;

const float softCliffMax = hardCliffMin;
const float bandingMin = 0.12;
const float vehCliffMinus = 0.24;
const float vehCliffEpsilon = 0.492;
const float vehCliffPlus = 0.62;
const float botCliffMinus = botCliff - 0.06;
const float botCliffMinusMinus = 0.65;

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

void main()
{
	vec2 coord = vec2(gl_TexCoord[0].s,gl_TexCoord[0].t);
	vec4 norm = texture2D(tex1, coord);
	vec2 norm2d = vec2(norm.x, norm.a);
	float slope = length(norm2d);
	float factor = 0.0;
	float height = texture2D(tex0,coord).r;

	// tile somewhat
	coord = 8.0*coord;

	// base texture
	gl_FragColor = texture2D(tex11,coord*min(3.1, 3.0 + 0.1*slope));
	gl_FragColor = mix(gl_FragColor,texture2D(tex11,coord*min(1.8, 1.7 + 0.1*slope)), 0.5 + 0.4*sin(height*0.7));

	// ---- altitude textures ----

	// admix beaches
	factor = clamp(0.1*(13.0 - abs(height) - 0.55*height),0.0,1.0);
	gl_FragColor = mix(gl_FragColor,texture2D(tex4,coord*8.0),factor);

	// admix cracks
	factor = smoothstep(60.0,85.0,height) * (1.0-slope);
	gl_FragColor = mix(gl_FragColor,texture2D(tex2,coord*min(1.3, 1.15 + 0.005*slope)),factor);

	// admix low grass
	factor = smoothstep(110.0,145.0,height) * (1.0-slope);
	gl_FragColor = mix(mix(gl_FragColor,texture2D(tex10,coord*min(0.8, 0.785 + 2.5*slope)),factor),texture2D(tex5,coord*0.9),0.18*factor);

	// admix high grass
	factor = smoothstep(180.0,210.0,height) * (1.0-slope);
	gl_FragColor = mix(mix(gl_FragColor,texture2D(tex9,coord*min(0.8, 0.785 + 2.5*slope)),factor),texture2D(tex5,coord*0.65),0.1*factor);

	// admix highlands
	factor = smoothstep(255.0,380.0,height) * (1.0-slope);
	gl_FragColor = mix(gl_FragColor,texture2D(tex6,coord*min(1.02, 1.0 + 0.001*slope)),factor);

	// ---- slope textures ----

	// admix ramps
	if (slope < vehCliff) {
		if (slope > bandingMin) {
			factor = 0.5*smoothstep(bandingMin, vehCliff, slope)*(1.0 - (1.0 - smoothstep(vehCliffMinus, vehCliffPlus, slope))*(sin(height/1.6) + 1.0)*0.5);
			gl_FragColor = mix(gl_FragColor,texture2D(tex2,coord*4.2), 0.7*smoothstep(bandingMin, vehCliff, slope));
			gl_FragColor = mix(gl_FragColor,texture2D(tex8,coord*2.7), factor);
		}
	}
	else if (slope < vehCliffEpsilon) {
		factor = 0.6*(1.0 - (1.0 - smoothstep(vehCliffMinus, vehCliffPlus, vehCliff))*(sin(height/1.6) + 1.0)*0.5);
		factor = factor*(vehCliffEpsilon - slope)/(vehCliffEpsilon - vehCliff) + (1.0 - (vehCliffEpsilon - slope)/(vehCliffEpsilon - vehCliff));
		gl_FragColor = mix(gl_FragColor,texture2D(tex2,coord*4.2), 0.7);
		gl_FragColor = mix(gl_FragColor,texture2D(tex8,coord*2.7), 0.8);
	}
	else if (slope < botCliff) {
		gl_FragColor = mix(gl_FragColor,texture2D(tex2,coord*4.2), 0.7);
		gl_FragColor = mix(gl_FragColor,texture2D(tex8,coord*2.7), 0.8 + 0.2*smoothstep(vehCliffEpsilon, botCliff, slope));
		if (slope > botCliffMinus) {
			factor = smoothstep(botCliffMinus, botCliff, slope);
			gl_FragColor = mix(gl_FragColor,texture2D(tex3,1.0*coord),factor*0.6);
		}
		if (slope > botCliffMinusMinus) {
			factor = smoothstep(botCliffMinusMinus, botCliff, slope)*0.3;
			gl_FragColor = mix(gl_FragColor,texture2D(tex7,2.0*coord*(1.0 + slope*0.01)),factor);
		}
	}
	else {
		// admix cliffsides
		factor = (1.0 - smoothstep(botCliff, 1.0, slope));
		gl_FragColor = mix(gl_FragColor,texture2D(tex3,1.0*coord),factor);
		gl_FragColor = mix(gl_FragColor,texture2D(tex8,coord*1.5), factor*0.5);
		gl_FragColor = mix(gl_FragColor,texture2D(tex3,1.0*coord),0.6);
		gl_FragColor = mix(gl_FragColor,texture2D(tex2,5.0*coord),factor*0.22);
	}

	// Show mountains over cliffs
	if (height > 255.0) {
		factor = smoothstep(255.0,380.0,height)*max(0.0, 1.0 - slope*2.0 + 0.05);
		gl_FragColor = mix(gl_FragColor,texture2D(tex6,coord*min(0.82, 0.8 + 0.001*slope)),factor);
	}
}