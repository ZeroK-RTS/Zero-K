#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// This file is going to be licensed under some sort of GPL-compatible license, but authors are dragging
// their feet. Avoid copying for now (unless this header rots for years on end), and check back later.
// See https://github.com/ZeroK-RTS/Zero-K/issues/5328

#line 5000

layout (location = 0) in vec4 height_timers;
#define unitHeight height_timers.x
#define sizeModifier height_timers.y
#define range height_timers.z
#define uvOffset height_timers.w
layout (location = 1) in uvec4 bartype_index_ssboloc;
layout (location = 2) in vec4 mincolor;
layout (location = 3) in vec4 maxcolor;
layout (location = 4) in uvec4 instData;

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

struct SUniformsBuffer {
    uint composite; //     u8 drawFlag; u8 unused1; u16 id;

    uint unused2;
    uint unused3;
    uint unused4;

    float maxHealth;
    float health;
    float unused5;
    float unused6;
	
    vec4 drawPos;
    vec4 speed;
    vec4[4] userDefined; //can't use float[16] because float in arrays occupies 4 * float space
};

layout(std140, binding=1) readonly buffer UniformsBuffer {
    SUniformsBuffer uni[];
};

#line 10000

uniform float iconDistance;
uniform float cameraDistanceMult;
uniform float cameraDistanceMultGlyph;

out DataVS {
	uint v_numvertices;
	vec4 v_mincolor;
	vec4 v_maxcolor;
	vec4 v_centerpos;
	vec4 v_uvoffsets;
	vec4 v_parameters;
	float v_sizeModifier;
	uvec4 v_bartype_index_ssboloc;
};

bool vertexClipped(vec4 clipspace, float tolerance) {
  return any(lessThan(clipspace.xyz, -clipspace.www * tolerance)) ||
         any(greaterThan(clipspace.xyz, clipspace.www * tolerance));
}
#define UNITUNIFORMS uni[instData.y]
#define UNIFORMLOC bartype_index_ssboloc.z
#define BARTYPE bartype_index_ssboloc.x

#define BITUSEOVERLAY 1u
#define BITSHOWGLYPH 2u
#define BITPERCENTAGE 4u
#define BITTIMELEFT 8u
#define BITINTEGERNUMBER 16u
#define BITINVERSE 32u
#define BITFRAMETIME 64u
#define BITCOLORCORRECT 128u

float valueForChannel(uint channel) {
	float value;
	if (channel == 20u) {
		value = 1 - UNITUNIFORMS.health / UNITUNIFORMS.maxHealth;
	} else if (channel > 15) {
		return 0;
	} else {
	        value = UNITUNIFORMS.userDefined[channel / 4][channel % 4];
	        if (value < 0) { // if value is < 0, it is in relationshiop to timeInfo or gameTime.
			value = -value - timeInfo.x;
			value = max(0, value);
		}

	        value = value.x / range;
	}

	return value;
}

bool isVarForChannelVisible(uint channel) {
	float value = valueForChannel(channel);
	return value > 0.01;
}

void main()
{
	vec4 drawPos = vec4(UNITUNIFORMS.drawPos.xyz, 1.0); // Models world pos and heading (.w) . Changed to use always available drawpos instead of model matrix.

	gl_Position = cameraViewProj * drawPos; // We transform this vertex into the center of the model

	v_centerpos = drawPos; // We are going to pass the centerpoint to the GS
	v_numvertices = 4u;
	if (vertexClipped(gl_Position, CLIPTOLERANCE) || !isVarForChannelVisible(UNIFORMLOC)) {
		v_numvertices = 0; // Make no primitives on stuff outside of screen
		return;
	}

	// this sets the num prims to 0 for units further from cam than iconDistance
	float cameraDistance = length((cameraViewInv[3]).xyz - v_centerpos.xyz);
	
	// Calculate bar alpha
	v_parameters.y = (clamp(cameraDistance * cameraDistanceMult, BARFADESTART, BARFADEEND) - BARFADESTART)/ ( BARFADEEND-BARFADESTART);
	v_parameters.y = 1.0 - clamp(v_parameters.y, 0.0, 1.0);
	
	// Calculate glyph alpha
	v_parameters.z = (clamp(cameraDistance * cameraDistanceMult * cameraDistanceMultGlyph, BARFADESTART, BARFADEEND) - BARFADESTART)/ ( BARFADEEND-BARFADESTART);
	v_parameters.z = 1.0 - clamp(v_parameters.z, 0.0, 1.0);

	#ifdef DEBUGSHOW
		v_parameters.y = 1.0;
		v_parameters.z = 1.0;
	#endif

	v_parameters.w = uvOffset;
	v_sizeModifier = sizeModifier;
	
	if (length((cameraViewInv[3]).xyz - v_centerpos.xyz) >  iconDistance){
		//v_parameters.yz = vec2(0.0); // No longer needed
	}


	if (dot(v_centerpos.xyz, v_centerpos.xyz) < 1.0) v_numvertices = 0; // if the center pos is at (0,0,0) then we probably dont have the matrix yet for this unit, because it entered LOS but has not been drawn yet.

	v_centerpos.y += HEIGHTOFFSET; // Add some height to ensure above groundness
	v_centerpos.y += unitHeight; // Add per-instance height offset

	// This is not needed since the switch to .drawPos
	//if ((UNITUNIFORMS.composite & 0x00000003u) < 1u ) v_numvertices = 0u; // this checks the drawFlag of wether the unit is actually being drawn (this is ==1 when then unit is both visible and drawn as a full model (not icon))


	v_bartype_index_ssboloc = bartype_index_ssboloc;

	v_bartype_index_ssboloc.y = 0;

	for(uint channel = 0; channel < UNIFORMLOC -1; channel++) {
		if (isVarForChannelVisible(channel)) {
			v_bartype_index_ssboloc.y += 1;
		}
	}

	v_parameters.x = valueForChannel(UNIFORMLOC);
	if ((BARTYPE & BITINVERSE) != 0u) {
		v_parameters.x = 1 - v_parameters.x;
	}

	v_mincolor = mincolor;
	v_maxcolor = maxcolor;
}
