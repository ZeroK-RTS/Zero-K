function widget:GetInfo()
	return {
		name      = "Outline Shader GL4",
		desc      = "An interesting way of doing unit outlines",
		author    = "Beherith",
		date      = "2022.03.05",
		license   = "Lua: GNU GPL, v2 or later, GLSL code: (c) Beherith, mysterme@gmail.com ",
		layer     = -50,
		enabled   = true
	}
end

local myvisibleUnits = {} -- table of unitID : unitDefID

local resurrectionHalosVBO = nil
local resurrectionHalosShader = nil
local luaShaderDir = "LuaUI/Widgets/Include/"
--local texture = 'LuaUI/Images/halo.dds'

local unitConf = {}

for unitDefID, ud in pairs(UnitDefs) do
	local xsize, zsize = ud.xsize, ud.zsize
	local scale = math.max(xsize,zsize) * 16
	unitConf[unitDefID] = {
		drawRectX = (ud.customParams.outline_x and tonumber(ud.customParams.outline_x)) or scale,
		drawRectY = (ud.customParams.outline_y and tonumber(ud.customParams.outline_y)) or scale,
		height = (ud.customParams.outline_yoff and tonumber(ud.customParams.outline_yoff)) or (ud.height * 0.5)
	}
	if ud.customParams.outline_sea_x then
		unitConf[unitDefID].seaConfig = {
			drawRectX = (ud.customParams.outline_sea_x and tonumber(ud.customParams.outline_sea_x)) or unitConf[unitDefID].drawRectX,
			drawRectY = (ud.customParams.outline_sea_y and tonumber(ud.customParams.outline_sea_y)) or unitConf[unitDefID].drawRectY,
			height = (ud.customParams.outline_sea_yoff and tonumber(ud.customParams.outline_sea_yoff)) or unitConf[unitDefID].height
		}
	end
end

-----------------------------------------------------------------
-- Configuration Constants
-----------------------------------------------------------------

local STRENGTH_MULT_MIN = 0.1
local STRENGTH_MULT_MAX = 12
local DEFAULT_STRENGTH_MULT = 1
local STRENGTH_MAGIC_NUMBER = 2.4

local SUBTLE_MIN = 50
local SUBTLE_MAX = 4000

local shaderConfig = {
	TRANSPARENCY = 1, -- transparency of the stuff drawn
	HEIGHTOFFSET = 0, -- Additional height added to everything
	ANIMATION = 0, -- set to 0 if you dont want animation
	INITIALSIZE = 1, -- What size the stuff starts off at when spawned
	GROWTHRATE = 4, -- How fast it grows to full size
	BREATHERATE = 30.0, -- how fast it periodicly grows
	BREATHESIZE = 0, -- how much it periodicly grows
	TEAMCOLORIZATION = 1.0, -- not used yet
	CLIPTOLERANCE = 2, -- At 1.0 it wont draw at units just outside of view (may pop in), 1.1 is a good safe amount
	USETEXTURE = 0, -- 1 if you want to use textures (atlasses too!) , 0 if not
	BILLBOARD = 1, -- 1 if you want camera facing billboards, 0 is flat on ground
	POST_ANIM = " ", -- what you want to do in the animation post function (glsl snippet, see shader source)
	POST_VERTEX = "v_color = v_color;", -- noop
	POST_GEOMETRY = "gl_Position.z = (gl_Position.z) - 256.0 / (gl_Position.w);",	--"g_uv.zw = dataIn[0].v_parameters.xy;", -- noop
	POST_SHADING = "fragColor.rgba = texcolor;",
	MAXVERTICES = 4, -- The max number of vertices we can emit, make sure this is consistent with what you are trying to draw (tris 3, quads 4, corneredrect 8, circle 64
	--USE_CIRCLES = 1, -- set to nil if you dont want circles
	--USE_CORNERRECT = 1, -- set to nil if you dont want cornerrect
	--USE_TRIANGLES = 1,
	FULL_ROTATION = 0, -- the primitive is fully rotated in the units plane
	DISCARD = 0, -- Enable alpha threshold to discard fragments below 0.01
	--DEBUGEDGES = 1, -- set to non-nil to debug the size of the rectangles
}

-----------------------------------------------------------------
-- Configuration
-----------------------------------------------------------------

local configStrengthMult = DEFAULT_STRENGTH_MULT
local scaleWithHeight = true
local functionScaleWithHeight = true
local zoomScaleRange = 0.4
local overrideDrawBoxes = false

local function PrintDrawBox()
	if overrideDrawBoxes then
		Spring.Echo("=== New Draw Box ===")
		Spring.Echo("outline_x = " .. options.overrideDrawBox_x.value .. ",")
		Spring.Echo("outline_y = " .. options.overrideDrawBox_y.value .. ",")
		Spring.Echo("outline_yoff = " .. options.overrideDrawBox_yoff.value .. ",")
		Spring.SetClipboard("\n\n    outline_x = " .. options.overrideDrawBox_x.value .. [[,
    outline_y = ]] .. options.overrideDrawBox_y.value .. [[,
    outline_yoff = ]] .. options.overrideDrawBox_yoff.value .. [[,]])
	end
end

options_path = 'Settings/Graphics/Unit Visibility/Outline'
options_order = {'thickness', 'scaleRange', 'scaleWithHeight', 'functionScaleWithHeight', 'overrideDrawBox', 'overrideDrawBox_x', 'overrideDrawBox_y', 'overrideDrawBox_yoff'}
options = {
	thickness = {
		name = 'Outline Thickness',
		desc = 'How thick the outline appears around objects',
		type = 'number',
		min = 0.2, max = 5, step = 0.05,
		value = DEFAULT_STRENGTH_MULT,
		OnChange = function (self)
			configStrengthMult = self.value
		end,
	},
	scaleRange = {
		name = 'Zoom Scale Minimum',
		desc = 'Minimum outline thickness muliplier when zoomed out.',
		type = 'number',
		min = 0, max = 1, step = 0.01,
		value = zoomScaleRange,
		OnChange = function (self)
			zoomScaleRange = self.value
		end,
	},
	scaleWithHeight = {
		name = 'Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out.',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function (self)
			scaleWithHeight = self.value
		end,
	},
	functionScaleWithHeight = {
		name = 'Subtle Scale With Distance',
		desc = 'Reduces the screen space width of outlines when zoomed out, in a subtle way.',
		type = 'bool',
		value = true,
		noHotkey = true,
		OnChange = function (self)
			functionScaleWithHeight = self.value
		end,
	},
	
	-- Debug
	overrideDrawBox = {
		name = 'Override draw box',
		desc = 'Debug enabling below.',
		type = 'bool',
		value = false,
		advanced = true,
		OnChange = function (self)
			overrideDrawBoxes = self.value
			local selUnits = Spring.GetSelectedUnits()
			if selUnits and selUnits[1] and Spring.GetUnitDefID(selUnits[1]) then
				local unitDefID = Spring.GetUnitDefID(selUnits[1])
				options.overrideDrawBox_x.value = unitConf[unitDefID].drawRectX
				options.overrideDrawBox_y.value = unitConf[unitDefID].drawRectY
				options.overrideDrawBox_yoff.value = unitConf[unitDefID].height
				PrintDrawBox()
			end
			WG.unittrackerapi.initializeAllUnits()
		end,
	},
	overrideDrawBox_x = {
		name = 'Override X',
		type = 'number',
		min = 0, max = 300, step = 5,
		value = 100,
		OnChange = function (self)
			WG.unittrackerapi.initializeAllUnits()
			PrintDrawBox()
		end,
	},
	overrideDrawBox_y = {
		name = 'Override Y',
		type = 'number',
		min = 0, max = 300, step = 5,
		value = 100,
		OnChange = function (self)
			WG.unittrackerapi.initializeAllUnits()
			PrintDrawBox()
		end,
	},
	overrideDrawBox_yoff = {
		name = 'Override Y Offset',
		type = 'number',
		min = -200, max = 200, step = 5,
		value = 0,
		OnChange = function (self)
			WG.unittrackerapi.initializeAllUnits()
			PrintDrawBox()
		end,
	},
}

-----------------------------------------------------------------
-- Zoom Scale Functions
-----------------------------------------------------------------

local function GetZoomScale()
	if not (scaleWithHeight or functionScaleWithHeight) then
		return 1
	end
	local cs = Spring.GetCameraState()
	local gy = Spring.GetGroundHeight(cs.px, cs.pz)
	local cameraHeight
	if cs.name == "ta" then
		cameraHeight = cs.height - gy
	else
		cameraHeight = cs.py - gy
	end
	cameraHeight = math.max(1.0, cameraHeight)
	--Spring.Echo("cameraHeight", cameraHeight, zoomScaleRange)

	if functionScaleWithHeight then
		if cameraHeight < SUBTLE_MIN then
			return 1
		end
		if cameraHeight > SUBTLE_MAX then
			return zoomScaleRange
		end
		
		local zoomScale = (math.cos(math.pi*((cameraHeight - SUBTLE_MIN)/(SUBTLE_MAX - SUBTLE_MIN))^0.75) + 1)/2
		--Spring.Echo("zoomScale", zoomScale)
		return zoomScale*(1 - zoomScaleRange) + zoomScaleRange
	end

	local scaleFactor = 250.0 / cameraHeight
	scaleFactor = math.min(math.max(zoomScaleRange, scaleFactor), 1.0)
	--Spring.Echo("cameraHeight", cameraHeight, "scaleFactor", scaleFactor)
	return scaleFactor
end

local function GetThicknessWithZoomScale()
	local strengthMult = configStrengthMult*GetZoomScale()*STRENGTH_MAGIC_NUMBER
	strengthMult = math.max(STRENGTH_MULT_MIN, math.min(STRENGTH_MULT_MAX, strengthMult))
	return strengthMult
end

-----------------------------------------------------------------
-- GL4 Backend Stuff
-----------------------------------------------------------------
local DrawPrimitiveAtUnitVBO = nil
local DrawPrimitiveAtUnitShader = nil

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir.."LuaShader.lua")
VFS.Include(luaShaderDir.."instancevbotable.lua")

local vsSrc =  [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 5000

layout (location = 0) in vec4 lengthwidthcornerheight;
layout (location = 1) in uint teamID;
layout (location = 2) in uint numvertices;
layout (location = 3) in vec4 parameters; // lifestart, ismine
layout (location = 4) in vec4 uvoffsets; // this is optional, for using an Atlas
layout (location = 5) in uvec4 instData;

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
    
    vec4 speed;    
    vec4[5] userDefined; //can't use float[20] because float in arrays occupies 4 * float space
};

layout(std140, binding=1) readonly buffer UniformsBuffer {
    SUniformsBuffer uni[];
}; 

#line 10000

uniform float addRadius;
uniform float iconDistance;

out DataVS {
	uint v_numvertices;
	float v_rotationY;
	vec4 v_color;
	vec4 v_lengthwidthcornerheight;
	vec4 v_centerpos;
	vec4 v_uvoffsets;
	vec4 v_parameters;
	float v_cameraDistance;
	#if (FULL_ROTATION == 1)
		mat3 v_fullrotation;
	#endif
};

layout(std140, binding=0) readonly buffer MatrixBuffer {
	mat4 UnitPieces[];
};


bool vertexClipped(vec4 clipspace, float tolerance) {
  return any(lessThan(clipspace.xyz, -clipspace.www * tolerance)) ||
         any(greaterThan(clipspace.xyz, clipspace.www * tolerance));
}

void main()
{
	uint baseIndex = instData.x; // this tells us which unit matrix to find
	mat4 modelMatrix = UnitPieces[baseIndex]; // This gives us the models  world pos and rot matrix

	gl_Position = cameraViewProj * vec4(modelMatrix[3].xyz, 1.0); // We transform this vertex into the center of the model
	v_rotationY = atan(modelMatrix[0][2], modelMatrix[0][0]); // we can get the euler Y rot of the model from the model matrix
	v_uvoffsets = uvoffsets;
	v_parameters = parameters;
	v_color = teamColor[teamID];  // We can lookup the teamcolor right here
	v_centerpos = vec4( modelMatrix[3].xyz, 1.0); // We are going to pass the centerpoint to the GS
	v_lengthwidthcornerheight = lengthwidthcornerheight;
	#if (ANIMATION == 1)
		float animation = clamp(((timeInfo.x + timeInfo.w) - parameters.x)/GROWTHRATE + INITIALSIZE, INITIALSIZE, 1.0) + sin((timeInfo.x)/BREATHERATE)*BREATHESIZE;
		v_lengthwidthcornerheight.xy *= animation; // modulate it with animation factor
	#endif
	POST_ANIM
	v_numvertices = numvertices;
	if (vertexClipped(gl_Position, CLIPTOLERANCE)) v_numvertices = 0; // Make no primitives on stuff outside of screen
	// TODO: take into account size of primitive before clipping

	// this sets the num prims to 0 for units further from cam than iconDistance
	v_cameraDistance = length((cameraViewInv[3]).xyz - v_centerpos.xyz);
	if (v_cameraDistance > iconDistance) v_numvertices = 0;

	if (dot(v_centerpos.xyz, v_centerpos.xyz) < 1.0) v_numvertices = 0; // if the center pos is at (0,0,0) then we probably dont have the matrix yet for this unit, because it entered LOS but has not been drawn yet.

	v_centerpos.y += HEIGHTOFFSET; // Add some height to ensure above groundness
	v_centerpos.y += lengthwidthcornerheight.w; // Add per-instance height offset
	#if (FULL_ROTATION == 1)
		v_fullrotation = mat3(modelMatrix);
	#endif
	if ((uni[instData.y].composite & 0x00000003u) < 1u ) v_numvertices = 0u; // this checks the drawFlag of wether the unit is actually being drawn (this is ==1 when then unit is both visible and drawn as a full model (not icon)) 
	// TODO: allow overriding this check, to draw things even if unit (like a building) is not drawn
	POST_VERTEX
}
]]

local gsSrc = [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__
layout(points) in;
layout(triangle_strip, max_vertices = MAXVERTICES) out;
#line 20000

uniform float addRadius;
uniform float iconDistance;

in DataVS {
	uint v_numvertices;
	float v_rotationY;
	vec4 v_color;
	vec4 v_lengthwidthcornerheight;
	vec4 v_centerpos;
	vec4 v_uvoffsets;
	vec4 v_parameters;
	float v_cameraDistance;
	#if (FULL_ROTATION == 1)
		mat3 v_fullrotation;
	#endif
} dataIn[];

out DataGS {
	vec4 g_color;
	vec4 g_uv;
	float g_cameraDistance;
};

mat3 rotY;
vec4 centerpos;
vec4 uvoffsets;

// This function takes in a set of UV coordinates [0,1] and tranforms it to correspond to the correct UV slice of an atlassed texture
vec2 transformUV(float u, float v){// this is needed for atlassing
	//return vec2(uvoffsets.p * u + uvoffsets.q, uvoffsets.s * v + uvoffsets.t); old
	float a = uvoffsets.t - uvoffsets.s;
	float b = uvoffsets.q - uvoffsets.p;
	return vec2(uvoffsets.s + a * u, uvoffsets.p + b * v);
}

void offsetVertex4( float x, float y, float z, float u, float v){
	g_uv.xy = transformUV(u,v);
	vec3 primitiveCoords = vec3(x,y,z);
	vec3 vecnorm = normalize(primitiveCoords);
	gl_Position = cameraViewProj * vec4(centerpos.xyz + rotY * ( addRadius * vecnorm + primitiveCoords ), 1.0);
	g_uv.zw = dataIn[0].v_parameters.zw;
	POST_GEOMETRY
	EmitVertex();
}
#line 22000
void main(){
	uint numVertices = dataIn[0].v_numvertices;
	centerpos = dataIn[0].v_centerpos;
	g_cameraDistance = dataIn[0].v_cameraDistance;
	#if (BILLBOARD == 1 )
		rotY = mat3(cameraViewInv[0].xyz,cameraViewInv[2].xyz, cameraViewInv[1].xyz); // swizzle cause we use xz
	#else
		#if (FULL_ROTATION == 1)
			rotY = dataIn[0].v_fullrotation; // Use the units true rotation
		#else
			rotY = rotation3dY(-1*dataIn[0].v_rotationY); // Create a rotation matrix around Y from the unit's rotation
		#endif
	#endif

	g_color = dataIn[0].v_color;

	uvoffsets = dataIn[0].v_uvoffsets; // if an atlas is used, then use this, otherwise dont

	float length = dataIn[0].v_lengthwidthcornerheight.x;
	float width = dataIn[0].v_lengthwidthcornerheight.y;
	float cs = dataIn[0].v_lengthwidthcornerheight.z;
	float height = dataIn[0].v_lengthwidthcornerheight.w;
	#ifdef USE_TRIANGLES
		if (numVertices == uint(3)){ // triangle pointing "forward"
			offsetVertex4(0.0, 0.0, length, 0.5, 1.0); // xyz uv
			offsetVertex4(-0.866 * width, 0.0, -0.5 * length, 0.0, 0.0);
			offsetVertex4(0.866* width, 0.0, -0.5 * length, 1.0, 0.0);
			EndPrimitive();
		}
	#endif
	if (numVertices == uint(4)){ // A quad
		offsetVertex4( width * 0.5, 0.0,  length * 0.5, 0.0, 1.0);
		offsetVertex4( width * 0.5, 0.0, -length * 0.5, 0.0, 0.0);
		offsetVertex4(-width * 0.5, 0.0,  length * 0.5, 1.0, 1.0);
		offsetVertex4(-width * 0.5, 0.0, -length * 0.5, 1.0, 0.0);
		EndPrimitive();
	}
	#ifdef USE_CORNERRECT
		if (numVertices == uint(2)){ // A quad with chopped off corners
			float csuv = (cs / (length + width))*2.0;
			offsetVertex4( - width * 0.5 , 0.0,  - length * 0.5 + cs, 0, csuv); // bottom left
			offsetVertex4( - width * 0.5 , 0.0,  + length * 0.5 - cs, 0, 1.0 - csuv); // top left
			offsetVertex4( - width * 0.5 + cs, 0.0,  - length * 0.5 , csuv, 0); // bottom left
			offsetVertex4( - width * 0.5 + cs, 0.0,  + length * 0.5, csuv, 1.0); // top left
			offsetVertex4( + width * 0.5 - cs, 0.0,  - length * 0.5 , 1.0 - csuv, 0.0); // bottom right
			offsetVertex4( + width * 0.5 - cs, 0.0,  + length * 0.5 ,1.0 - csuv, 1.0 ); // top right
			offsetVertex4( + width * 0.5 , 0.0,  - length * 0.5 + cs , 1.0 , csuv ); // bottom right
			offsetVertex4( + width * 0.5 , 0.0,  + length * 0.5 - cs , 1.0 -csuv , 1.0 ); // top right
			EndPrimitive();
		}
	#endif
	#ifdef USE_CIRCLES
		if (numVertices > uint(5)) { //A circle with even subdivisions
			numVertices = min(numVertices,62u); // to make sure that we dont emit more than 64 vertices
			//left most vertex
			offsetVertex4(- width * 0.5, 0.0,  0, 0.0, 0.5);
			int numSides = int(numVertices) / 2;
			//for each phi in (-PI/2, Pi/2) omit the first and last one
			for (int i = 1; i < numSides; i++){
				float phi = ((i * 3.141592) / numSides) -  1.5707963;
				float sinphi = sin(phi);
				float cosphi = cos(phi);
				offsetVertex4( width * 0.5 * sinphi, 0.0,  length * 0.5 * cosphi, sinphi*0.5 + 0.5, cosphi * 0.5 + 0.5);
				offsetVertex4( width * 0.5 * sinphi, 0.0,  -length * 0.5 * cosphi, sinphi*0.5 + 0.5, cosphi *(-0.5) + 0.5);
			}
			// add right most vertex
			offsetVertex4(width * 0.5, 0.0,  0, 1.0, 0.5);
			EndPrimitive();
		}
	#endif
}
]]

local fsSrc =
[[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

#line 30000
uniform float addRadius;
uniform float iconDistance;
uniform float outlineWidth;
in DataGS {
	vec4 g_color;
	vec4 g_uv;
	float g_cameraDistance; 
};

uniform sampler2D DrawPrimitiveAtUnitTexture;
uniform sampler2D mapDepths;
uniform sampler2D modelDepths;
uniform sampler2D modelMisc;

uniform float stencilPass = 0.0; // 1 if we are stenciling
out vec4 fragColor;

void main(void)
{
	vec4 texcolor = vec4(1.0);
	#if (USETEXTURE == 1)
		texcolor = texture(DrawPrimitiveAtUnitTexture, g_uv.xy);
	#endif
	fragColor.rgba = vec4(g_color.rgb * texcolor.rgb + addRadius, texcolor.a * TRANSPARENCY + addRadius);
	POST_SHADING
	//fragColor.rgba = vec4(1.0);
	#if (DISCARD == 1)
	//	if (fragColor.a < 0.01) discard;
	#endif
	
	int resolution = int(ceil(outlineWidth)) + 3;
	float sqrtdist = outlineWidth * 1.4241;
	
	vec2 screenUV = gl_FragCoord.xy/ viewGeometry.xy;
	float mapdepth = texture(mapDepths, screenUV).x;
	float modeldepth = texture(modelDepths, screenUV).x;
	
	float fulldepth = min(mapdepth, modeldepth); 
	
	float my_misctexvalue = texture(modelMisc, screenUV).r;
	float deltadepth = max(mapdepth - modeldepth, 0.0);
	
	//if (deltadepth > 0.0) discard; // we hit a model, bail!
	//if ((modeldepth < 1.0) && (mapdepth > modeldepth)) discard; // model occluded behind map
	
	if (stencilPass > 0.5){
		float nearest = (outlineWidth*20 + 1) * (outlineWidth*20 + 1) ;
		vec2 viewGeometryInv = 1.0 / viewGeometry.xy;
		
		if (deltadepth > 0.0 && my_misctexvalue > 0.5) {
			for (int x = -1; x <= 1; x++){
				vec2 pixeloffset = vec2(float(x), float(0));
				vec2 screendelta = pixeloffset * viewGeometryInv;
				
				float misctexvalue = texture(modelMisc, screenUV+ screendelta).r;
				float mapd = texture(mapDepths, screenUV+ screendelta).x;
				float modd = texture(modelDepths, screenUV + screendelta).x;
				float dd = max(mapd - modd, 0.0);
				if (misctexvalue > 0.5 && dd == 0) {
					nearest = min(nearest, abs(x)); 
				}
			}
			for (int y = -1; y <= 1; y++){
				vec2 pixeloffset = vec2(float(0), float(y));
				vec2 screendelta = pixeloffset * viewGeometryInv;
				
				float misctexvalue = texture(modelMisc, screenUV+ screendelta).r;
				float mapd = texture(mapDepths, screenUV+ screendelta).x;
				float modd = texture(modelDepths, screenUV + screendelta).x;
				float dd = max(mapd - modd, 0.0);
				if (misctexvalue > 0.5 && dd == 0) {
					nearest = min(nearest, abs(y)); 
				}
			}
			nearest = sqrt(nearest);
			
			fragColor.rgba = vec4(vec3(0.0), (1.0 - nearest * 1.5 / outlineWidth));
		} else {
			for (int x = -1 * resolution; x <= resolution; x++){
				for (int y = -1* resolution; y <= resolution; y++){
					vec2 pixeloffset = vec2(float(x), float(y));
					vec2 screendelta = pixeloffset * viewGeometryInv;
					
					float misctexvalue = texture(modelMisc, screenUV+ screendelta).r;
					float mapd = texture(mapDepths, screenUV+ screendelta).x;
					float modd = texture(modelDepths, screenUV + screendelta).x;
					float dd = max(mapd - modd, 0.0);
					if (misctexvalue > 0.5 && dd > 0){
						nearest = min(nearest, dot(pixeloffset, pixeloffset));
					}
				}
			}
			nearest = sqrt(nearest);

			fragColor.rgba = vec4(vec3(0.0), (1.0 - pow((nearest/(sqrtdist)), 1 + int(outlineWidth / 2))));
		}
		#ifdef DEBUGEDGES
			// For debuging draw size
			if (min(g_uv.x, g_uv.y) < 0.05 || max(g_uv.x, g_uv.y) > 0.95){ // we are on the edges
				fragColor.rgba = vec4(vec3(fract(nearest/16)), 1.0);
				fragColor.rgba = vec4(vec2(fract(gl_FragCoord.xy*0.1	)),0.0,  0.7);
			}
		#endif
	}else{
		//fragColor.rgba = vec4(vec2(fract(gl_FragCoord.xy*0.1	)),0.0,  0.3);
	}
	//fragColor.rgba = vec4(texture(modelMisc, screenUV).rgb, 1.0);
	
}
]]

local function goodbye(reason)
  Spring.Echo("DrawPrimitiveAtUnits GL4 widget exiting with reason: "..reason)
  widgetHandler:RemoveWidget()
end

local function InitDrawPrimitiveAtUnit(modifiedShaderConf, DPATname)
	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	vsSrc = vsSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	fsSrc = fsSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	gsSrc = gsSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	DrawPrimitiveAtUnitShader =  LuaShader(
		{
			vertex = vsSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(modifiedShaderConf)),
			fragment = fsSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(modifiedShaderConf)),
			geometry = gsSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(modifiedShaderConf)),
			uniformInt = {
				DrawPrimitiveAtUnitTexture = 0;
				mapDepths = 1,
				modelDepths = 2,
				modelMisc = 3, 
			},
			uniformFloat = {
				addRadius = 1,
				iconDistance = 1,
				outlineWidth = 1,
			},
		},
		DPATname .. "Shader GL4"
	  )
	local shaderCompiled = DrawPrimitiveAtUnitShader:Initialize()
	if not shaderCompiled then goodbye("Failed to compile ".. DPATname .." GL4 ") end

	DrawPrimitiveAtUnitVBO = makeInstanceVBOTable(
		{
			{id = 0, name = 'lengthwidthcorner', size = 4},
			{id = 1, name = 'teamID', size = 1, type = GL.UNSIGNED_INT},
			{id = 2, name = 'numvertices', size = 1, type = GL.UNSIGNED_INT},
			{id = 3, name = 'parameters', size = 4},
			{id = 4, name = 'uvoffsets', size = 4},
			{id = 5, name = 'instData', size = 4, type = GL.UNSIGNED_INT},
		},
		64, -- maxelements
		DPATname .. "VBO", -- name
		5  -- unitIDattribID (instData)
	)
	if DrawPrimitiveAtUnitVBO == nil then goodbye("Failed to create DrawPrimitiveAtUnitVBO") end

	local DrawPrimitiveAtUnitVAO = gl.GetVAO()
	DrawPrimitiveAtUnitVAO:AttachVertexBuffer(DrawPrimitiveAtUnitVBO.instanceVBO)
	DrawPrimitiveAtUnitVBO.VAO = DrawPrimitiveAtUnitVAO
	return  DrawPrimitiveAtUnitVBO, DrawPrimitiveAtUnitShader
end

function widget:VisibleUnitAdded(unitID, unitDefID, unitTeam)
	local gf = Spring.GetGameFrame()
	myvisibleUnits[unitID] = unitDefID
	local unitData = unitConf[unitDefID]
	if unitData.seaConfig then
		local x, z = Spring.GetUnitPosition(unitID)
		if Spring.GetGroundHeight(x, z) < 0 then
			unitData = unitData.seaConfig
		end
	end
	
	pushElementInstance(
		resurrectionHalosVBO, -- push into this Instance VBO Table
		{
			(overrideDrawBoxes and options.overrideDrawBox_y.value) or unitData.drawRectY,
			(overrideDrawBoxes and options.overrideDrawBox_x.value) or unitData.drawRectX,
			8,
			(overrideDrawBoxes and options.overrideDrawBox_yoff.value) or unitData.height,  -- lengthwidthcornerheight
			0, -- teamID
			4, -- how many trianges should we make (2 = cornerrect)
			gf, 0, 0, 0, -- the gameFrame (for animations), and any other parameters one might want to add
			0, 1, 0, 1, -- These are our default UV atlas tranformations
			0, 0, 0, 0 -- these are just padding zeros, that will get filled in
		},
		unitID, -- this is the key inside the VBO TAble,
		true, -- update existing element
		nil, -- noupload, dont use unless you know what you are doing
		unitID -- last one should be UNITID?
	)
end

function widget:VisibleUnitsChanged(extVisibleUnits, extNumVisibleUnits)
	clearInstanceTable(resurrectionHalosVBO)
	for unitID, unitDefID in pairs(extVisibleUnits) do 
		widget:VisibleUnitAdded(unitID, unitDefID, Spring.GetUnitTeam(unitID))
	end
end

function widget:VisibleUnitRemoved(unitID)
	if resurrectionHalosVBO.instanceIDtoIndex[unitID] then 
		popElementInstance(resurrectionHalosVBO, unitID)
		myvisibleUnits[unitID] = nil
	end
end

local GL_ALWAYS             = GL.ALWAYS
local GL_EQUAL              = GL.EQUAL
local GL_LINE_LOOP          = GL.LINE_LOOP
local GL_KEEP               = 0x1E00 --GL.KEEP
local GL_REPLACE            = GL.REPLACE
local GL_DECR               = 0x1E03

local useStencil = true
local STENCILOPPASS = GL_DECR -- KEEP OR DECR

function widget:DrawWorld()
	if Spring.IsGUIHidden() then
		return
	end

	if resurrectionHalosVBO.usedElements > 0 then
		--gl.Texture(0, texture)
		gl.Texture(1, "$map_gbuffer_zvaltex")-- Texture file
		gl.Texture(2, "$model_gbuffer_zvaltex")-- Texture file
		gl.Texture(3, "$model_gbuffer_misctex")-- Texture file
		resurrectionHalosShader:Activate()
			resurrectionHalosShader:SetUniform("iconDistance", 99999) -- pass
			resurrectionHalosShader:SetUniform("addRadius", 0)
			resurrectionHalosShader:SetUniform("outlineWidth", GetThicknessWithZoomScale())
		
		if useStencil then -- https://learnopengl.com/Advanced-OpenGL/Stencil-testing
			gl.DepthMask(false)
			
			-- FIRST PASS:
			gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
			gl.ColorMask(false, false, false, false) -- disable writing to all but stencil
			gl.StencilTest(true) -- enable stencil test
			gl.DepthTest(false) -- dont do depth testing either
			
			gl.StencilFunc(GL_ALWAYS, 1, 1) -- Always Passes, 1 Bit Plane, 1 As Mask
			gl.StencilOp(GL_KEEP, GL_KEEP, GL_REPLACE) -- Set The Stencil Buffer To 1 Where Draw Any Polygon
			--glStencilOp(GLenum sfail, GLenum dpfail, GLenum dppass) 
			
			resurrectionHalosShader:SetUniform("stencilPass", 0)
			resurrectionHalosVBO.VAO:DrawArrays(GL.POINTS, resurrectionHalosVBO.usedElements)
		
			-- SECOND PASS
			gl.ColorMask(true, true, true, true)
		
			gl.StencilFunc(GL_EQUAL, 1, 1)
			gl.StencilOp(GL_KEEP, STENCILOPPASS, STENCILOPPASS	)
			resurrectionHalosShader:SetUniform("stencilPass", 1.0)
			resurrectionHalosVBO.VAO:DrawArrays(GL.POINTS, resurrectionHalosVBO.usedElements)
		else
			gl.DepthTest(false) -- dont do depth testing either
			gl.DepthMask(false)
			resurrectionHalosShader:SetUniform("stencilPass", 1.0)
			resurrectionHalosVBO.VAO:DrawArrays(GL.POINTS, resurrectionHalosVBO.usedElements)
		end
		
		gl.Clear( GL.STENCIL_BUFFER_BIT)
		resurrectionHalosShader:Deactivate()
		gl.Texture(0, false)
		gl.Texture(1, false)-- Texture file
		gl.Texture(2, false)-- Texture file
		gl.Texture(3, false)-- Texture file
		
		gl.StencilTest(false)
	end
end

local function initGL4()
	resurrectionHalosVBO, resurrectionHalosShader = InitDrawPrimitiveAtUnit(shaderConfig, "ResurrectionHalos")
end

function widget:Initialize()
	initGL4()
	
	if WG['unittrackerapi'] and WG['unittrackerapi'].visibleUnits then 
		local visibleUnits =  WG['unittrackerapi'].visibleUnits
		for unitID, unitDefID in pairs(visibleUnits) do 
			widget:VisibleUnitAdded(unitID, unitDefID)
		end
	end
end
