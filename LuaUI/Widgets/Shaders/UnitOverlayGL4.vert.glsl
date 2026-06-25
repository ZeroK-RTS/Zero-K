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
	float v_range;
	float v_aboveBars;  // count of visible "above" bars, so the row instances sit above the top bar
	float v_rowSlot;    // combined centered slot in the row above the bars (states + status badges)
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
#define BITVERTICAL 256u
#define BITLEFT 512u
#define BITRIGHT 1024u
#define BITICON 4096u
#define BITALWAYSSHOW 8192u
#define BITICONROW 16384u
#define BITPULSE 32768u
#define BITCONSTRUCTION 65536u
#define BITGAUGE 131072u
#define BITJUMPCHARGE 1048576u
#define BITICONCORNER 262144u

// Bit-pack descriptor (generated from channelPack in gl_uniform_channels.lua). width 0 = whole float.
const int PACK_FLOAT [16] = int[16](PACK_FLOAT_INIT);
const int PACK_OFFSET[16] = int[16](PACK_OFFSET_INIT);
const int PACK_WIDTH [16] = int[16](PACK_WIDTH_INIT);
const int PACK_TYPE  [16] = int[16](PACK_TYPE_INIT);

// Every by-number channel read routes through this so packing stays consistent across value /
// visibility / centering. width 0 returns the whole float (passthrough); else extracts the sub-field
// and applies the type decode (type 1 = status -> old <=1 magnitude / >1 = 1+seconds semantics).
float readField(uint c) {
	int ci = int(c);
	int f = PACK_FLOAT[ci];
	float raw = UNITUNIFORMS.userDefined[f / 4][f % 4];
	int w = PACK_WIDTH[ci];
	float field = (w == 0) ? raw : mod(floor(raw / exp2(float(PACK_OFFSET[ci]))), exp2(float(w)));
	if (PACK_TYPE[ci] == 1) field = (field <= 100.0) ? field * 0.01 : field - 99.0; // status
	else if (PACK_TYPE[ci] == 2) field = field * 0.01;                              // percent (0-100 -> 0-1)
	return field;
}

float valueForChannel(uint channel) {
	float value;
	if (channel == 20u) {
		value = 1 - UNITUNIFORMS.health / UNITUNIFORMS.maxHealth;
	} else if (channel > 15) {
		return 0;
	} else {
	        value = readField(channel);
	        if (value < 0) { // if value is < 0, it is in relationshiop to timeInfo or gameTime.
			value = -value - timeInfo.x;
			value = max(0, value);
		}

	        value = value / range;
	}

	return value;
}

bool isVarForChannelVisible(uint channel) {
	float value = valueForChannel(channel);
	return value > 0.01;
}

#define BITMODULAR 524288u
// Bar value honoring BITMODULAR: the slot holds target-frame mod 4096 (0 = ready); decode to a 0..1
// fraction of `range` frames remaining. Non-modular falls through to the normal channel value.
float barValue(uint channel, uint bartype) {
	if ((bartype & BITMODULAR) != 0u) {
		float f = readField(channel);
		float rem = (f < 0.5) ? 0.0 : mod(f - timeInfo.x, 4096.0);
		return rem / range;
	}
	return valueForChannel(channel);
}
// Visibility honoring BITMODULAR: reloading iff the slot is nonzero (ready encodes 0).
bool barVisible(uint channel, uint bartype) {
	// Jump charges store a (scaled, modular) frame; 0 = fully charged. A non-always-show single-charge
	// badge hides when ready (like a reload); multi-charge units carry BITALWAYSSHOW so all stay visible.
	if ((bartype & BITJUMPCHARGE) != 0u) return readField(channel) > 0.5;
	if ((bartype & BITMODULAR) != 0u) return readField(channel) > 0.5;
	return isVarForChannelVisible(channel);
}

// Jump charges: the slot holds the (1/8-scaled, mod 4096) frame the LAST charge finishes (0 = fully
// charged). Reconstruct the continuous jumpReload (0..charges); each badge subtracts its own charge index
// in the GS. charges is packed into uvOffset (base 16) alongside the per-badge charge index. The /8 scale
// must match JUMP_FRAME_SCALE in unit_gl_uniform_updater.
float jumpChargeReload() {
	float stored = readField(UNIFORMLOC);
	float charges = floor(uvOffset / 16.0);
	if (stored < 0.5) return charges; // sentinel: fully charged
	float reloadFrames = max(range, 1.0);
	float framesUntilFull = mod(stored - floor(timeInfo.x / 8.0), 4096.0) * 8.0;
	return charges - framesUntilFull / reloadFrames;
}

// Range-independent "does this channel currently render a bar" check. valueForChannel divides by the
// *current instance's* range, which is meaningless when called from the icon-row instances (their
// range encodes a layout slot, so the centre icon divides by zero). The row counts the bars it must
// clear with this instead. Mirror the bars' own visibility threshold (value/range > 0.01) so the count
// matches what actually draws -- the above-bars are all range 1, so a flat 0.01 is exact for them.
bool isChannelActive(uint channel) {
	if (channel == 20u) {
		return UNITUNIFORMS.maxHealth > 0.0 && (1.0 - UNITUNIFORMS.health / UNITUNIFORMS.maxHealth) > 0.01;
	}
	if (channel > 15u) return false;
	float value = readField(channel);
	if (value < 0.0) {
		return (-value - timeInfo.x) > 0.0; // time-based: still in the future
	}
	return value > 0.01;
}

// Goo/Morph (8) and Movement (14) stack below the unit; everything else (incl. build) stacks above.
bool isChannelBelow(uint channel) {
	return channel == 8u || channel == 14u;
}

// Number of visible "above" bars (the damage group that stacks above the unit). Mirrors the
// stacking filter below; used to lift the icon/status row clear of the topmost bar.
float countAboveBars() {
	float n = 0.0;
	for (uint channel = 0u; channel <= 20u; channel++) {
		// Skip gadget-owned floats that aren't overlay bars: 0 = build/data, 4 = gfx-paralyze, 6 =
		// selectedness, 15 = unit height (always > 0 -> would phantom-count on every unit, lifting the row).
		if ((channel < 9u || channel > 12u) && channel != 4u && channel != 6u && channel != 0u && channel != 15u &&
			!isChannelBelow(channel) && isChannelActive(channel)) {
			n += 1.0;
		}
	}
	return n;
}

// The top-band status badges (paralyze/disarm/slow durations + build/reclaim ETA) live in the same row
// as the hovering-icon states. They ride fixed channels, so the GPU can count which are currently drawn
// and assign each a centered slot -- exactly what the CPU does for the states -- so both halves repack
// together. Raw channel value (no range division) keeps this valid when read from any instance.
float rawChannelValue(uint channel) {
	if (channel > 15u) return 0.0;
	float value = readField(channel);
	if (value < 0.0) value = max(0.0, -value - timeInfo.x); // time-based encoding -> seconds remaining
	return value;
}

// Slot->channel order matches the layoutSlot values baked in Lua: paralyze=0, disarm=1, slow=2.
// Mirrors the geom's actual draw test: duration badges show only once locked at max (value > 1).
bool statusBadgeDrawn(uint slot) {
	if (slot == 0u) return rawChannelValue(1u) > 1.0; // paralyze
	if (slot == 1u) return rawChannelValue(2u) > 1.0; // disarm
	return rawChannelValue(3u) > 1.0;                  // slow (slot 2)
}

float countActiveStatuses() {
	float n = 0.0;
	for (uint slot = 0u; slot < 3u; slot++) { if (statusBadgeDrawn(slot)) n += 1.0; }
	return n;
}

// Index of the status with the given layoutSlot among the currently-drawn status badges (for repacking).
float statusActiveIndex(uint slot) {
	float idx = 0.0;
	for (uint s = 0u; s < slot; s++) { if (statusBadgeDrawn(s)) idx += 1.0; }
	return idx;
}

void main()
{
#ifdef SCREENSPACE
	// In screen-space mode height_timers.xy carries screen pixel coordinates.
	// The unit SSBO is still used for bar value lookup via instData.y.
	if ((BARTYPE & BITALWAYSSHOW) == 0u && !barVisible(UNIFORMLOC, BARTYPE)) { v_numvertices = 0u; return; }
	v_numvertices = 4u;
	v_centerpos   = vec4(unitHeight, sizeModifier, 0.0, 1.0); // xy = screen pixel pos
	gl_Position   = vec4(0.0, 0.0, 0.0, 1.0);
	v_sizeModifier = 1.0;
	v_aboveBars = 0.0;
	v_rowSlot = 0.0;
	v_parameters.y = 1.0; // always fully opaque in screen space
	v_parameters.z = 1.0;
	v_parameters.w = uvOffset;
	v_bartype_index_ssboloc = bartype_index_ssboloc;
	v_parameters.x = barValue(UNIFORMLOC, BARTYPE);
	if ((BARTYPE & BITINVERSE) != 0u) v_parameters.x = 1.0 - v_parameters.x;
	v_uvoffsets = vec4(0.0);
	v_range = range;
	v_mincolor = mincolor;
	v_maxcolor = maxcolor;
	return;
#endif

	vec4 drawPos = vec4(UNITUNIFORMS.drawPos.xyz, 1.0); // Models world pos and heading (.w) . Changed to use always available drawpos instead of model matrix.

	gl_Position = cameraViewProj * drawPos; // We transform this vertex into the center of the model

	v_centerpos = drawPos; // We are going to pass the centerpoint to the GS
	v_numvertices = 4u;
	// Always-show bars (commander reload badges) must survive even at 0 channel value so the geom
	// can render their "ready" state; only off-screen clipping still culls them.
	bool alwaysShow = (BARTYPE & BITALWAYSSHOW) != 0u;
	if (vertexClipped(gl_Position, CLIPTOLERANCE) || ((BARTYPE & BITICON) == 0u && !alwaysShow && !barVisible(UNIFORMLOC, BARTYPE))) {
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

	if ((BARTYPE & BITICON) != 0u) {
		v_parameters.z = v_parameters.y; // icons fade with bars, not at glyph rate
		v_parameters.x = 0.0;
	}

	v_parameters.w = uvOffset;
	v_sizeModifier = sizeModifier;

	if (length((cameraViewInv[3]).xyz - v_centerpos.xyz) >  iconDistance){
		//v_parameters.yz = vec2(0.0); // No longer needed
	}


	if (dot(v_centerpos.xyz, v_centerpos.xyz) < 1.0) v_numvertices = 0; // if the center pos is at (0,0,0) then we probably dont have the matrix yet for this unit, because it entered LOS but has not been drawn yet.

	v_centerpos.y += HEIGHTOFFSET; // Add some height to ensure above groundness
	// Per-instance baseline, applied in WORLD space so the cluster sits at the unit's actual mid-body
	// height (not drifting in screen space as the camera tilts). Every overlay element on a unit shares
	// this same value, so they stay coplanar with each other; the in-cluster layout (bar stacking, the
	// bar/row offsets) is done in billboard space by the GS.
	v_centerpos.y += unitHeight;

	// This is not needed since the switch to .drawPos
	//if ((UNITUNIFORMS.composite & 0x00000003u) < 1u ) v_numvertices = 0u; // this checks the drawFlag of wether the unit is actually being drawn (this is ==1 when then unit is both visible and drawn as a full model (not icon))


	v_bartype_index_ssboloc = bartype_index_ssboloc;

	v_bartype_index_ssboloc.y = 0;

	if ((BARTYPE & BITICON) == 0u) {
		bool isWeaponBar = (BARTYPE & (BITLEFT | BITRIGHT)) != 0u;
		if (isWeaponBar) {
			// Weapon bars (left/right): count only bars within their channel group below current channel.
			uint groupStart = ((BARTYPE & BITLEFT) != 0u) ? 9u : 11u;
			for(uint channel = groupStart; channel < UNIFORMLOC; channel++) {
				if (isVarForChannelVisible(channel)) {
					v_bartype_index_ssboloc.y += 1;
				}
			}
		} else {
			// Horizontal bars: count visible channels above current one within the same
			// above/below group (damage bars stack above the unit, build/goo/movement stack below).
			bool isBelow = isChannelBelow(UNIFORMLOC);
			for(uint channel = UNIFORMLOC + 1u; channel <= 20u; channel++) {
				if ((channel < 9u || channel > 12u) && channel != 4u && channel != 6u && channel != 0u && channel != 15u &&
					isChannelBelow(channel) == isBelow && isVarForChannelVisible(channel)) {
					v_bartype_index_ssboloc.y += 1;
				}
			}
		}

		v_parameters.x = barValue(UNIFORMLOC, BARTYPE);
		if ((BARTYPE & BITINVERSE) != 0u) {
			v_parameters.x = 1 - v_parameters.x;
		}
		// Jump charges carry the reconstructed jumpReload (0..charges); the GS subtracts each badge's index.
		if ((BARTYPE & BITJUMPCHARGE) != 0u) v_parameters.x = jumpChargeReload();
	}

	v_uvoffsets = vec4(0.0);
	if (UNIFORMLOC == 20u) {
		float rawParalyze = valueForChannel(1u);
		float rawDisarm   = valueForChannel(2u);
		v_uvoffsets.x = min(1.0, rawParalyze); // paralyze overlay fraction (clamped)
		v_uvoffsets.y = min(1.0, rawDisarm);   // disarm overlay fraction (clamped)
		v_uvoffsets.z = rawParalyze;            // raw paralyze (can exceed 1.0 when stunned)
		v_uvoffsets.w = rawDisarm;              // raw disarm (>1 = long disarm)
	}

	v_range = range;
	v_mincolor = mincolor;
	v_maxcolor = maxcolor;

	// Center unit icon: show white when the unit is selected (bit 23 of userDefined[0][2]).
	if ((BARTYPE & BITICON) != 0u && (BARTYPE & BITICONROW) == 0u) {
		float isSelected = mod(floor(UNITUNIFORMS.userDefined[0][2] / 8388608.0), 2.0);
		if (isSelected > 0.5) v_mincolor.rgb = vec3(1.0);
	}

	// The row above the bars (hovering-icon row + top-band status badges) needs to clear the whole
	// bar stack, so those instances carry the above-bar count; everyone else ignores it.
	v_aboveBars = 0.0;
	v_rowSlot = 0.0;
	if ((BARTYPE & BITICONROW) != 0u ||
		((BARTYPE & BITVERTICAL) != 0u && (BARTYPE & (BITTIMELEFT | BITCONSTRUCTION)) != 0u)) {
		v_aboveBars = countAboveBars();
		// Combined centered slot for the row above the bars. The hovering-icon states come first (their
		// count is computed on the CPU and delivered in userDefined[3][3]), then the GPU-counted status
		// badges; everything is centered as one run so the two halves repack together. (Features ignore
		// this in the geom -- their channels mean something else.)
		// float 2 (userDefined[0][2]) packs slow+capture+state-count(bits 19-22)+isSelected(23); extract count.
		float nStates = mod(floor(UNITUNIFORMS.userDefined[0][2] / 524288.0), 16.0);
		float nStatus = countActiveStatuses();
		float total = nStates + nStatus;
		if ((BARTYPE & BITICONROW) != 0u) {
			// range carries this icon's raw 0-based index within the state group (baked in Lua).
			v_rowSlot = range - (total - 1.0) * 0.5;
		} else {
			float combinedIndex = nStates + statusActiveIndex(bartype_index_ssboloc.w);
			v_rowSlot = combinedIndex - (total - 1.0) * 0.5;
		}
	} else if ((BARTYPE & BITVERTICAL) != 0u && (BARTYPE & (BITLEFT | BITRIGHT | BITTIMELEFT | BITCONSTRUCTION)) == 0u) {
		// Below-zone radial badges (jump charges, sprint, teleport, + the transient morph badge). They
		// reflow as one centered run so a recon comm (morph + jump) splits left/right and a Detriment's 3
		// jump charges sit -1/0/+1. The persistent badges bake (index, count) in .w; morph rides the fixed
		// channel 8, so it's detected live and slots in at the left without re-pushing the others.
		uint slotPack = bartype_index_ssboloc.w;
		float idx = float(slotPack & 15u);          // index among the persistent below badges
		float P   = float((slotPack >> 4) & 15u);   // count of persistent below badges (morph excluded)
		bool morphActive = rawChannelValue(8u) > 0.0;
		if (UNIFORMLOC == 8u) {
			// morph: index 0 of the VISIBLE below run. The persistent below count P is baked, but those
			// badges can HIDE (e.g. a single-charge jump once it's charged), so centering on P would leave
			// the morph offset for a hidden neighbour. Count how many are actually shown from the baked
			// channel mask (slotPack >> 8): a below badge is visible iff its slot is nonzero (uniform across
			// modular / jump-charge / rate-ETA), so the morph re-centers as neighbours appear/disappear.
			uint mask = slotPack >> 8u;
			float visibleBelow = 0.0;
			for (uint c = 0u; c < 16u; c++) {
				if (((mask >> c) & 1u) != 0u && readField(c) > 0.5) visibleBelow += 1.0;
			}
			v_rowSlot = -visibleBelow * 0.5;
		} else {
			v_rowSlot = morphActive ? ((idx + 1.0) - P * 0.5) : (idx - (P - 1.0) * 0.5);
		}
	}
}
