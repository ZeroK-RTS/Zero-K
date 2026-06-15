#version 430
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#extension GL_ARB_shader_storage_buffer_object : require

// Pass-through VS: each cable is a single GL_LINES primitive (2 vertices,
// both carrying the same per-edge attributes). The geometry shader expands
// the line into a wiggly noisy ribbon with N segments. All the expensive
// per-vertex math that used to live on the CPU now lives on the GPU.

layout (location = 0) in vec2 vertPos;     // (x, z) world coords
layout (location = 1) in vec3 vertData;    // (capacity, appearTime, witherTime)
layout (location = 2) in vec4 vertGrid;    // (gridEfficiency, flow, bubblePhase, isOwnAlly)
layout (location = 3) in float vertSlot;   // coverage SSBO slot (-1 = disabled)

out gl_PerVertex {
	vec4 gl_Position;
};

out DataVS {
	vec2 vsWorldXZ;
	vec3 vsCableData;
	vec4 vsGridData;
	flat int vsSlot;
};

void main() {
	vsWorldXZ   = vertPos;
	vsCableData = vertData;
	vsGridData  = vertGrid;
	vsSlot      = int(vertSlot);
	gl_Position = vec4(0.0);
}
