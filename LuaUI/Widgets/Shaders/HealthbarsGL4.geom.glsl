#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// This file is going to be licensed under some sort of GPL-compatible license, but authors are dragging
// their feet. Avoid copying for now (unless this header rots for years on end), and check back later.
// See https://github.com/ZeroK-RTS/Zero-K/issues/5328

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__
layout(points) in;
layout(triangle_strip, max_vertices = MAXVERTICES) out;
#line 20000

uniform float iconDistance;
uniform float skipGlyphsNumbers; // <0.5 means none, <1.5 means percent only, >1.5 means nothing, just bars

in DataVS { // I recall the sane limit for cache coherence is like 48 floats per vertex? try to stay under that!
	uint v_numvertices;
	vec4 v_mincolor;
	vec4 v_maxcolor;
	vec4 v_centerpos;
	vec4 v_uvoffsets;
	vec4 v_parameters;
	float v_sizeModifier;
	uvec4 v_bartype_index_ssboloc;
} dataIn[];

out DataGS {
	vec4 g_color; // pure rgba
	vec4 g_uv; // xy is trivially uv coords, z is texture blend factor, w means nothing yet
        vec4 g_rect;
        vec2 g_loc;
        float g_corner_radius;
};

mat3 rotY;
vec4 centerpos;
vec4 uvoffsets;
float zoffset;
float depthbuffermod;
float sizeMultiplier = dataIn[0].v_sizeModifier;
float duration = -1;

#define HALFPIXEL 0.0019765625

#define BARTYPE dataIn[0].v_bartype_index_ssboloc.x
#define BARALPHA dataIn[0].v_parameters.y
#define GLYPHALPHA dataIn[0].v_parameters.z
#define UVOFFSET dataIn[0].v_parameters.w
#define UNIFORMLOC dataIn[0].v_bartype_index_ssboloc.z

#define BITUSEOVERLAY 1u
#define BITSHOWGLYPH 2u
#define BITPERCENTAGE 4u
#define BITTIMELEFT 8u
#define BITINTEGERNUMBER 16u
#define BITGETPROGRESS 32u
#define BITFRAMETIME 64u
#define BITCOLORCORRECT 128u

void emitRectangleVertex(vec2 pos, vec4 corners, float corner_radius, float useTexture, vec2 uv, vec4 color) {
       g_uv.xy = vec2(uv.x, 1.0 - uv.y);
       vec3 primitiveCoords = vec3(pos.x, 0.0, pos.y - zoffset) * BARSCALE * sizeMultiplier;
       gl_Position = cameraViewProj * vec4(centerpos.xyz + rotY * ( primitiveCoords ), 1.0);
	gl_Position.z += depthbuffermod;
       g_uv.z = useTexture; // this tells us to use texture
       g_color = color;
       g_color.a *= dataIn[0].v_parameters.z; // blend with text/icon fade alpha
       vec3 primitiveCorner = vec3(corners.x, 0.0, corners.y - zoffset) * BARSCALE * sizeMultiplier;
       g_rect = corners;
       g_loc = pos;
       g_corner_radius = corner_radius;

       EmitVertex();
}

void emitRectangle(vec4 destination, vec4 corners, float corner_radius, float useTexture, vec4 texture, vec4 topColor, vec4 bottomColor) {
       // bottom = .x
       // left = .y
       // height = .z
       // width = .w

       float dl = destination.x;
       float db = destination.y;
       float dr = destination.x + destination.z;
       float dt = destination.y + destination.w;

       float tl = texture.x;
       float tb = texture.y;
       float tr = texture.x + texture.z;
       float tt = texture.y + texture.w;

       emitRectangleVertex(vec2(dl, db), corners, corner_radius, useTexture, vec2(tl, tb), bottomColor);
       emitRectangleVertex(vec2(dl, dt), corners, corner_radius, useTexture, vec2(tl, tt), topColor);
       emitRectangleVertex(vec2(dr, db), corners, corner_radius, useTexture, vec2(tr, tb), bottomColor);
       emitRectangleVertex(vec2(dr, dt), corners, corner_radius, useTexture, vec2(tr, tt), topColor);

       EndPrimitive();
}

#line 22000
void main(){
	zoffset =  -1.15 * BARHEIGHT *  float(dataIn[0].v_bartype_index_ssboloc.y);

	centerpos = dataIn[0].v_centerpos;

	rotY = mat3(cameraViewInv[0].xyz,cameraViewInv[2].xyz, cameraViewInv[1].xyz); // swizzle cause we use xz,
        vec4 g_rect;
        float g_corner_radius;

	g_color = vec4(1.0, 0.0, 1.0, 1.0); // a very noticeable default color

	uvoffsets = dataIn[0].v_uvoffsets; // if an atlas is used, then use this, otherwise dont

	float health = min(1, dataIn[0].v_parameters.x);
        if (dataIn[0].v_parameters.x > 1.5) duration = floor(dataIn[0].v_parameters.x - 1);
	if (BARALPHA < MINALPHA) return; // Dont draw below 50% transparency

	// All the early bail conditions to not draw full/empty bars
	if (dataIn[0].v_numvertices == 0u) return; // for hiding the build bar when full health

	// STOCKPILE BAR:  128*numStockpileQued + numStockpiled + stockpileBuild
	uint numStockpiled = 0u;
	uint numStockpileQueued = 0u;
	if ((BARTYPE & BITINTEGERNUMBER) > 0u){
		float oldhealth = health;
		health = fract(oldhealth);
		oldhealth = floor(oldhealth);
		numStockpiled = uint(floor( mod (oldhealth, 128)));
		numStockpileQueued = uint(floor(oldhealth/128));
	}

	depthbuffermod = 0.001;
	float extraColor = 0.0;
	if ((duration != -1) && (mod(timeInfo.x, 10.0) > 4.0)){
		extraColor = 0.5;
	}

	emitRectangle(
		vec4(-BARWIDTH, 0, BARWIDTH * 2, BARHEIGHT),
		vec4(-BARWIDTH, 0, BARWIDTH * 2, BARHEIGHT),
		BARCORNER,
		0.0,
		vec4(1.0, 1.0, 1.0, 1.0),
		BGTOPCOLOR + extraColor,
		BGBOTTOMCOLOR + extraColor
	);

	// EMIT THE COLORED BACKGROUND
	// for this to work, we need the true color of the bar?

	vec4 topcolor = BGTOPCOLOR;
	vec4 botcolor = BGBOTTOMCOLOR;
	vec4 truecolor = mix(dataIn[0].v_mincolor, dataIn[0].v_maxcolor, health);

	truecolor.a = 0.2;
	topcolor = truecolor;

	topcolor.rgb *= BOTTOMDARKENFACTOR;
	depthbuffermod = 0.000;

	emitRectangle(
		vec4(-BARWIDTH + BARCORNER, BARCORNER, (BARWIDTH - BARCORNER) * 2, BARHEIGHT - 2 * BARCORNER),
		vec4(-BARWIDTH + BARCORNER, BARCORNER, (BARWIDTH - BARCORNER) * 2, BARHEIGHT - 2 * BARCORNER),
		SMALLERCORNER,
		0.0,
		vec4(1.0, 1.0, 1.0, 1.0),
		truecolor,
		topcolor
	);

	// EMIT BAR FOREGROUND

	depthbuffermod = -0.001;
	emitRectangle(
		vec4(-BARWIDTH + BARCORNER, BARCORNER, (BARWIDTH - BARCORNER) * 2 * health, BARHEIGHT - 2 * BARCORNER ),
		vec4(-BARWIDTH + BARCORNER, BARCORNER, (BARWIDTH - BARCORNER) * 2, BARHEIGHT - 2 * BARCORNER),
		SMALLERCORNER,
		1.0,
		vec4(
			(672.0 * floor(mod(UVOFFSET, 3)) + 96) / 2048.0,
			(96.0 + floor(UVOFFSET / 3) * 80) / 1024.0,
			576.0 / 2048.0 * health,
			64.0 / 1024.0),
		vec4(1,1,1,1),
		topcolor
	);

	// EMIT GLYPH
	depthbuffermod = -0.002;
	float drawPos = -BARWIDTH - BARCORNER;
	emitRectangle(
		vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
		vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
		0.0,
		1.0,
		vec4(
			(672.0 * floor(mod(UVOFFSET, 3)) + 16) / 2048.0,
			(96.0 + floor(UVOFFSET / 3) * 80) / 1024.0,
			64.0 / 2048.0,
			64.0 / 1024.0),
		vec4(1,1,1,1),
		vec4(1,1,1,1)
	);
	drawPos -= BARHEIGHT;
	float ones;
	float tens;
	float hundrends;
	float glyphpctsecatlas;
	if (duration != -1){ //display time
		ones = abs(floor(mod(duration, 10.0)));
		tens = abs(floor(mod(duration*0.1, 10.0)));
		hundrends = abs(floor(mod(duration*0.01, 10.0)));
		glyphpctsecatlas = 0.0; // seconds
	} else {
		ones = floor(mod(health*100.0, 10.0));
		tens = floor(mod(health*10.0, 10.0));
		hundrends = floor(mod(health, 10.0));
		glyphpctsecatlas = 1.0; // percent
	}

	emitRectangle(
		vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
		vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
		0.0,
		1.0,
		vec4(
			(64.0 * glyphpctsecatlas) / 2048.0,
			16 / 1024.0,
			64.0 / 2048.0,
			64.0 / 1024.0),
		vec4(1,1,1,1),
		vec4(1,1,1,1)
	);
	drawPos -= BARHEIGHT * 0.8;
	emitRectangle(
		vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
		vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
		0.0,
		1.0,
		vec4(
			(64.0 * (11 - ones)) / 2048.0,
			16 / 1024.0,
			64.0 / 2048.0,
			64.0 / 1024.0),
		vec4(1,1,1,1),
		vec4(1,1,1,1)
	);
	drawPos -= BARHEIGHT * 0.8;
	if (tens != 0 || hundrends != 0) {
		emitRectangle(
			vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
			vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
			0.0,
			1.0,
			vec4(
				(64.0 * (11 - tens)) / 2048.0,
				16 / 1024.0,
				64.0 / 2048.0,
				64.0 / 1024.0),
			vec4(1,1,1,1),
			vec4(1,1,1,1)
		);
	}
	drawPos -= BARHEIGHT * 0.8;
	if (hundrends != 0) {
		emitRectangle(
			vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
			vec4(drawPos - BARHEIGHT, 0, BARHEIGHT, BARHEIGHT),
			0.0,
			1.0,
			vec4(
				(64.0 * (11 - hundrends)) / 2048.0,
				16 / 1024.0,
				64.0 / 2048.0,
				64.0 / 1024.0),
			vec4(1,1,1,1),
			vec4(1,1,1,1)
		);
	}

}
