local widget = widget ---@type Widget

function widget:GetInfo()
	return {
		name      = "Paralyze Effect",
		version   = "v0.2",
		desc      = "Faster gl.UnitShape, Use WG.UnitShapeGL4",
		author    = "Beherith",
		date      = "2021.11.04",
		license   = "GPL V2",
		layer     = 0,
	enabled   = true,
	}
end


-- Localized Spring API for performance
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitHealth = Spring.GetUnitHealth
local spGetGameFrame = Spring.GetGameFrame
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir.."LuaShader.lua")
local InstanceVBOTable = VFS.Include(luaShaderDir.."instancevboidtable.lua")

local pushElementInstance = InstanceVBOTable.pushElementInstance
local popElementInstance  = InstanceVBOTable.popElementInstance


-- for testing: /luarules fightertest corak armpw 100 10 3000

local paralyzedUnitShader, unitShapeShader


local vsSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 10000
//__DEFINES__

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec3 T;
layout (location = 3) in vec3 B;
layout (location = 4) in vec4 uv;

layout (location = 5) in uvec2 bonesInfo; //boneIDs, boneWeights
#define pieceIndex (bonesInfo.x & 0x000000FFu)

layout (location = 6) in vec4 startcolorpower;
layout (location = 7) in vec4 endcolor_endgameframe;
layout (location = 8) in uvec4 instData;

const float vertexDisplacement = 6.0; // MUST MATCH CUS vertex shader displacement

#define UNITID (uni[instData.y].composite >> 16)
#define UNITUNIFORMS uni[instData.y]

//__ENGINEUNIFORMBUFFERDEFS__

layout(std140, binding = 2) uniform FixedStateMatrices {
	mat4 modelViewMat;
	mat4 projectionMat;
	mat4 textureMat;
	mat4 modelViewProjectionMat;
};
#line 15000

#if USEQUATERNIONS == 0
	layout(std140, binding=0) buffer MatrixBuffer {
		mat4 mat[];
	};
#else
	//__QUATERNIONDEFS__
#endif

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

out vec3 v_modelPosOrig;
out vec4 v_startcolorpower;
out vec4 v_endcolor_alpha;

float Perlin3D( vec3 P ) { // MUST MATCH CUS vertex shader noise
	//return 0.5;
	//  https://github.com/BrianSharpe/Wombat/blob/master/Perlin3D.glsl

	// establish our grid cell and unit position
	vec3 Pi = floor(P);
	vec3 Pf = P - Pi;
	vec3 Pf_min1 = Pf - 1.0;

	// clamp the domain
	Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
	vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

	// calculate the hash
	vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
	Pt *= Pt;
	Pt = Pt.xzxz * Pt.yyww;
	const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
	const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );
	vec3 lowz_mod = vec3( 1.0 / ( SOMELARGEFLOATS + Pi.zzz * ZINC ) );
	vec3 highz_mod = vec3( 1.0 / ( SOMELARGEFLOATS + Pi_inc1.zzz * ZINC ) );
	vec4 hashx0 = fract( Pt * lowz_mod.xxxx );
	vec4 hashx1 = fract( Pt * highz_mod.xxxx );
	vec4 hashy0 = fract( Pt * lowz_mod.yyyy );
	vec4 hashy1 = fract( Pt * highz_mod.yyyy );
	vec4 hashz0 = fract( Pt * lowz_mod.zzzz );
	vec4 hashz1 = fract( Pt * highz_mod.zzzz );

	// calculate the gradients
	vec4 grad_x0 = hashx0 - 0.49999;
	vec4 grad_y0 = hashy0 - 0.49999;
	vec4 grad_z0 = hashz0 - 0.49999;
	vec4 grad_x1 = hashx1 - 0.49999;
	vec4 grad_y1 = hashy1 - 0.49999;
	vec4 grad_z1 = hashz1 - 0.49999;
	vec4 grad_results_0 = inversesqrt( grad_x0 * grad_x0 + grad_y0 * grad_y0 + grad_z0 * grad_z0 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x0 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y0 + Pf.zzzz * grad_z0 );
	vec4 grad_results_1 = inversesqrt( grad_x1 * grad_x1 + grad_y1 * grad_y1 + grad_z1 * grad_z1 ) * ( vec2( Pf.x, Pf_min1.x ).xyxy * grad_x1 + vec2( Pf.y, Pf_min1.y ).xxyy * grad_y1 + Pf_min1.zzzz * grad_z1 );

	// Classic Perlin Interpolation
	vec3 blend = Pf * Pf * Pf * (Pf * (Pf * 6.0 - 15.0) + 10.0);
	vec4 res0 = mix( grad_results_0, grad_results_1, blend.z );
	vec4 blend2 = vec4( blend.xy, vec2( 1.0 - blend.xy ) );
	float final = dot( res0, blend2.zxzx * blend2.wwyy );
	return ( final * 1.1547005383792515290182975610039 );  // scale things to a strict -1.0->1.0 range  *= 1.0/sqrt(0.75)
}

float hash11(float p) {
	const float HASHSCALE1 = 0.1031;
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
	p3 += dot(p3, p3.yzx + 19.19);
	return fract((p3.x + p3.y) * p3.z);
}

void main() {
	uint baseIndex = instData.x;
	vec4 piecePos = vec4(pos, 1.0);
	float healthFrac = clamp(UNITUNIFORMS.health / UNITUNIFORMS.maxHealth, 0.0, 1.0);
	
	if (healthFrac < 0.95){
		vec3 seedVec = 0.1 * piecePos.xyz;
		seedVec.y += 1024.0 * hash11(float(UNITID));
		float damageAmount = (1.0 - healthFrac) * 0.8;
		piecePos.xyz += damageAmount * vertexDisplacement * Perlin3D(seedVec) * normalize(piecePos.xyz);
	}
	
	#line 16000
	#if USEQUATERNIONS == 0
		mat4 modelMatrix = mat[baseIndex];

		uint isDynamic = 1u; //default dynamic model
		// dynamic models have one extra matrix, as their first matrix is their world pos/offset
		//mat4 pieceMatrix = mat4mix(mat4(1.0), mat[baseIndex + pieceIndex + isDynamic ], modelMatrix[3][3]);
		mat4 pieceMatrix = mat4mix(mat4(1.0), mat[baseIndex + pieceIndex + isDynamic ], 1.0);
		vec4 localModelPos = pieceMatrix * piecePos;

		v_modelPosOrig = localModelPos.xyz + (modelMatrix[3].xyz)*0.3;
		vec4 modelPos = modelMatrix * localModelPos;

	#else 
		Transform pieceModelTransform = GetPieceModelTransform(baseIndex, pieceIndex);
		Transform modelWorldTransform = GetModelWorldTransform(baseIndex);

		v_modelPosOrig = (ApplyTransform(pieceModelTransform, piecePos)).xyz;

		vec4 modelPos = ApplyTransform(modelWorldTransform, vec4(v_modelPosOrig.xyz, 1.0));
	#endif

	v_endcolor_alpha.rgba = endcolor_endgameframe.rgba;
	v_endcolor_alpha.a = uni[instData.y].userDefined[1].x;
	
	// this checks the drawFlag of wether the unit is actually being drawn (this is ==1 when then unit is both visible and drawn as a full model (not icon))
	if ((uni[instData.y].composite & 0x00000003u) < 1u ) {
		v_endcolor_alpha.a = 0.0; 
		v_endcolor_alpha.r = 0.0;
	}

	v_startcolorpower = startcolorpower;
	
	//v_endcolor_alpha.a = 0.99;
	gl_Position = cameraViewProj * modelPos;
}
]]

local fsSrc = [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#line 20000

// 4D NOISE:
//	Simplex 4D Noise 
//	by Ian McEwan, Ashima Arts
//
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
float permute(float x){return floor(mod(((x*34.0)+1.0)*x, 289.0));}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
float taylorInvSqrt(float r){return 1.79284291400159 - 0.85373472095314 * r;}

vec4 grad4(float j, vec4 ip){
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www; 

  return p;
}

float snoise(vec4 v){
  const vec2  C = vec2( 0.138196601125010504,  // (5 - sqrt(5))/20  G4
                        0.309016994374947451); // (sqrt(5) - 1)/4   F4
// First corner
  vec4 i  = floor(v + dot(v, C.yyyy) );
  vec4 x0 = v -   i + dot(i, C.xxxx);

// Other corners

// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
  vec4 i0;

  vec3 isX = step( x0.yzw, x0.xxx );
  vec3 isYZ = step( x0.zww, x0.yyz );
//  i0.x = dot( isX, vec3( 1.0 ) );
  i0.x = isX.x + isX.y + isX.z;
  i0.yzw = 1.0 - isX;

//  i0.y += dot( isYZ.xy, vec2( 1.0 ) );
  i0.y += isYZ.x + isYZ.y;
  i0.zw += 1.0 - isYZ.xy;

  i0.z += isYZ.z;
  i0.w += 1.0 - isYZ.z;

  // i0 now contains the unique values 0,1,2,3 in each channel
  vec4 i3 = clamp( i0, 0.0, 1.0 );
  vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
  vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

  //  x0 = x0 - 0.0 + 0.0 * C 
  vec4 x1 = x0 - i1 + 1.0 * C.xxxx;
  vec4 x2 = x0 - i2 + 2.0 * C.xxxx;
  vec4 x3 = x0 - i3 + 3.0 * C.xxxx;
  vec4 x4 = x0 - 1.0 + 4.0 * C.xxxx;

// Permutations
  i = mod(i, 289.0); 
  float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
  vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));
// Gradients
// ( 7*7*6 points uniformly over a cube, mapped onto a 4-octahedron.)
// 7*7*6 = 294, which is close to the ring size 17*17 = 289.

  vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  vec4 p0 = grad4(j0,   ip);
  vec4 p1 = grad4(j1.x, ip);
  vec4 p2 = grad4(j1.y, ip);
  vec4 p3 = grad4(j1.z, ip);
  vec4 p4 = grad4(j1.w, ip);

// Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= taylorInvSqrt(dot(p4,p4));

// Mix contributions from the five corners
  vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

}

//END 4D NOISE


//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

in vec3 v_modelPosOrig;
in vec4 v_startcolorpower;
in vec4 v_endcolor_alpha;

out vec4 fragColor;
#line 25000
void main() {
	float input_data = v_endcolor_alpha.a; // 1: para, 2: disarm, 4: fire, fraction: slow
	bool fire = (input_data > 7.95);
	if (fire) {
		input_data -= 7.0;
	}
	bool emp = (input_data > 3.95);
	float stunAmount = 1.0;
	if (emp) {
		input_data -= 4.0;
		stunAmount = fract(input_data) - 0.01;
		input_data -= 0.11;
	}
	bool disarm = (input_data > 1.95);
	if (disarm) {
		input_data -= 2.0;
		stunAmount = fract(input_data) - 0.01;
		input_data -= 0.11;
	}
	float slowed = 0.0;
	if (input_data > 0.95) {
		input_data -= 1.0;
		slowed = input_data;
		stunAmount -= slowed;
	}
	
	float noisescale;
	float persistance;
	float lacunarity;
	vec3 minlightningcolor;
	vec3 maxlightningcolor;
	vec4 wholeunitbasecolor;
	float lightningalpha;
	float lighting_sharpness; 
	float lighting_width; 
	float lightning_speed;
	float effect_level = 0.0;
	float alphaRange = 0.6;
	float alphaBase = 0.4;
	float lightningMult = 1.0;
	
	// ------------------ CONFIG START --------------------
	
	if (emp) {
		effect_level = 1.0;
		noisescale = 0.49;
		persistance = 0.45;
		lacunarity = 2.5;
		minlightningcolor = vec3(0.1, 0.1, 1.0); //blue
		maxlightningcolor = vec3(1.0, 1.0, 1.0); //white
		wholeunitbasecolor = vec4(0.49, 0.5, 1.0, 1.0); // light blue base tone
		alphaRange = 0.6;
		alphaBase = 0.4;
		lightningalpha = 1.2;
		lighting_sharpness = 4.8; 
		lighting_width = 3.8;
		lightning_speed = 0.95;
		lightningMult = 1.0;
	} else if (disarm) {
		effect_level = 0.9954;
		noisescale = 0.49;
		persistance = 0.45;
		lacunarity = 2.5;
		minlightningcolor = vec3(0.8, 0.8, 0.4); //white-yellow
		maxlightningcolor = vec3(1.0, 1.0, 1.0); //white
		wholeunitbasecolor = vec4(0.7, 0.7, 0.55, 0.85); // light blue base tone
		alphaRange = 0.9;
		alphaBase = 0.4;
		lightningalpha = 2.5;
		lighting_sharpness = 4.8; 
		lighting_width = 4.8;
		lightning_speed = 0.95;
		lightningMult = 1.8;
	}
	// ------------------ CONFIG END --------------------
	
	fragColor = vec4(1.0, 1.0, 1.0, 0.0);
	float flash = abs((2.0 * fract((timeInfo.x + timeInfo.w) * 0.07)) - 1.0);
	if (effect_level > 0.5) {
		stunAmount = stunAmount * 10.0;
		vec4 noiseposition = noisescale * vec4(v_modelPosOrig, (timeInfo.x + timeInfo.w) * lightning_speed);
		float noise4 = 0;
		noise4 += pow(persistance, 1.0) * snoise(noiseposition * 0.025 * pow(lacunarity, 1.0));
		noise4 += pow(persistance, 2.0) * snoise(noiseposition * 0.025 * pow(lacunarity, 2.0));
		noise4 += pow(persistance, 3.0) * snoise(noiseposition * 0.025 * pow(lacunarity, 3.0));
		noise4 += pow(persistance, 4.0) * snoise(noiseposition * 0.025 * pow(lacunarity, 4.0));
		noise4 = (1.0 * noise4 + 0.5);
		float electricity = clamp(1.0 - abs(noise4 - 0.5) * lighting_width, 0.0, 1.0);
		electricity = clamp(pow(electricity, lighting_sharpness), 0.0, 1.0);

		vec3 lightningcolor;
		float effectalpha;
		lightningcolor = mix(minlightningcolor, maxlightningcolor, electricity);
		effectalpha = clamp(effect_level * lightningalpha, 0.0, 1.0);
		
		fragColor = vec4(lightningcolor, electricity*effectalpha*lightningMult);
		float baseItensity = snoise(0.032 * vec4(v_modelPosOrig, 1.7*(timeInfo.x + timeInfo.w))) + 
		                     snoise(0.02 * vec4(v_modelPosOrig, 1.3*(timeInfo.x + timeInfo.w)));
		baseItensity = sqrt(abs(baseItensity) + 0.2) * (0.5 * flash + 0.2) + clamp(baseItensity * (flash - 0.5) * 0.5, -0.2, 1.0);
		wholeunitbasecolor.a = clamp((alphaBase + baseItensity * (0.1 + alphaRange)) * stunAmount * stunAmount + electricity, 0.0, 1.0);
		wholeunitbasecolor.r = wholeunitbasecolor.r + baseItensity * 0.33;
		wholeunitbasecolor.g = wholeunitbasecolor.g + baseItensity * 0.45;
		fragColor = max(wholeunitbasecolor, fragColor); // apply whole unit base color
		fragColor.a *= clamp((effect_level - 0.98) * 50.0 * stunAmount, 0.0, 1.0);
	}
	if (slowed > 0.001) {
		float baseItensity = snoise(0.032 * vec4(v_modelPosOrig, -1.7*(timeInfo.x + timeInfo.w))) + 
		                     snoise(0.02 * vec4(v_modelPosOrig, -1.3*(timeInfo.x + timeInfo.w)));
		baseItensity = sqrt(abs(baseItensity) + 0.25);
		vec4 slowcolor = vec4(1.0, 0.1, 1.0, clamp((baseItensity + 0.2), 0.0, 1.0)) * sqrt(1.6 * clamp(slowed, 0.0, 0.45));
		fragColor = mix(slowcolor, fragColor, 0.5 * (1.35 - baseItensity) - (0.5 - slowed) * clamp(effect_level * 0.8, 0.0, 1.0));
	}
	if (fire) {
		flash = 1.0 - flash;
		float baseItensity = snoise(0.039 * vec4(v_modelPosOrig, 1.1*(timeInfo.x + timeInfo.w)));
		float baseItensity2 = snoise(0.082 * vec4(v_modelPosOrig, 1.7*(timeInfo.x + timeInfo.w)));
		float alpha = clamp((0.6 - 0.2*flash) * (0.3 + 0.5 * baseItensity * baseItensity2) + 0.4 * baseItensity + 0.3 * baseItensity2 + 0.4*flash, 0.0, 1.0);
		vec4 firecolor = vec4(1.0, 0.45, 0.1, alpha);
		fragColor = mix(firecolor, fragColor, 0.55 + 0.4 * clamp(effect_level + slowed, 0.0, 1.0));
	}
}
]]


local paralyzeSourceShaderCache = {
	vsSrc = vsSrc,
	fsSrc = fsSrc,
	shaderName = "paralyzedUnitShader",
	uniformInt = {},
	uniformFloat = {},
	shaderConfig = {
		USEQUATERNIONS = Engine.FeatureSupport.transformsInGL4 and "1" or "0",
	},
	forceupdate = true  -- otherwise file-less defines are not updated
}

--holy hacks batman
if Spring.GetModOptions().emprework then
	fsSrc = string.gsub(fsSrc,'//empreworktagdonotremove','paralysis_level = paralysis_level*3; if (paralysis_level> 1) { paralysis_level = 1; }')
	fsSrc = string.gsub(fsSrc,'//empreworkherealsodonotremove','if (paralysis_level > 0.49) { wholeunitbasecolor = vec4(0.35, 0.43, 0.94, 0.18); }')
end

local paralyzedDrawUnitVBOTable

local function initGL4()
	local vertVBO = gl.GetVBO(GL.ARRAY_BUFFER, false) -- GL.ARRAY_BUFFER, false
	local indxVBO = gl.GetVBO(GL.ELEMENT_ARRAY_BUFFER, false) -- GL.ARRAY_BUFFER, false
	vertVBO:ModelsVBO()
	indxVBO:ModelsVBO()

	local VBOLayout = {
			{id = 6, name = "startcolorpower", size = 4},
			{id = 7, name = "endcolor" , size = 4},
			{id = 8, name = "instData", type = GL.UNSIGNED_INT, size = 4},
		}

	local maxElements = 32 -- start small for testing
	local unitIDAttributeIndex = 8
	paralyzedDrawUnitVBOTable         = InstanceVBOTable.makeInstanceVBOTable(VBOLayout, maxElements, "paralyzedDrawUnitVBOTable", unitIDAttributeIndex, "unitID")

	paralyzedDrawUnitVBOTable.VAO = InstanceVBOTable.makeVAOandAttach(vertVBO, paralyzedDrawUnitVBOTable.instanceVBO, indxVBO)
	paralyzedDrawUnitVBOTable.indexVBO = indxVBO
	paralyzedDrawUnitVBOTable.vertexVBO = vertVBO

	paralyzedUnitShader = LuaShader.CheckShaderUpdates(paralyzeSourceShaderCache)

	if not paralyzedUnitShader  then
		Spring.Echo("paralyzedUnitShaderCompiled shader compilation failed", paralyzedUnitShader)
		widgetHandler:RemoveWidget()
	end
end

local function DrawParalyzedUnitGL4(unitID, unitDefID, red_start,  green_start, blue_start,power_start, red_end, green_end, blue_end, time_end)
	-- Documentation for DrawParalyzedUnitGL4:
	--	unitID: the actual unitID that you want to draw
	--	unitDefID: which unitDef is it (leave nil for autocomplete)
	-- returns: a unique handler ID number that you should store and call StopDrawParalyzedUnitGL4(uniqueID) with to stop drawing it
	-- note that widgets are responsible for stopping the drawing of every unit that they submit!

	--Spring.Echo("DrawParalyzedUnitGL4",unitID, unitDefID, UnitDefs[unitDefID].name)
	if paralyzedDrawUnitVBOTable.instanceIDtoIndex[unitID] then return end -- already got this unit
	if Spring.ValidUnitID(unitID) ~= true or Spring.GetUnitIsDead(unitID) == true then return end
	red_start = red_start or 1.0
	green_start = green_start or 1.0
	blue_start = blue_start or 1.0
	power_start = power_start or 4.0 
	red_end = red_end or 0
	green_end = green_end or 0
	blue_end = blue_end or 1.0
	time_end = 500000 --time_end or spGetGameFrame()
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	
	pushElementInstance(paralyzedDrawUnitVBOTable , {
			red_start, green_start,blue_start, power_start,
			red_end, green_end, blue_end, time_end,
			0,0,0,0
		},
		unitID,
		true,
		nil,
		unitID,
		"unitID")
	--Spring.Echo("Pushed",  unitID, elementID)
	return unitID
end

local function StopDrawParalyzedUnitGL4(unitID)
	if paralyzedDrawUnitVBOTable.instanceIDtoIndex[unitID] then
		popElementInstance(paralyzedDrawUnitVBOTable, unitID)
	end
end

---  All the stuff from the old paralyze effect widget to make this shit work!
local unitIDtoUniqueID = {}
local TESTMODE = false

local gameFrame = spGetGameFrame()
local prevGameFrame = gameFrame
local numParaUnits = 0
local myTeamID
local spec, fullview

local function init()
	InstanceVBOTable.clearInstanceTable(paralyzedDrawUnitVBOTable)
	local allUnits = Spring.GetAllUnits()
	for i=1, #allUnits do
		local unitID = allUnits[i]
		widget:UnitCreated(unitID, spGetUnitDefID(unitID))
	end
end

function widget:PlayerChanged(playerID)
	spec, fullview = Spring.GetSpectatingState()
	local prevMyTeamID = myTeamID
	myTeamID = Spring.GetMyTeamID()
	if myTeamID ~= prevMyTeamID then -- TODO only really needed if onlyShowOwnTeam, or if allyteam changed?
		--Spring.Echo("Initializing Paralyze Effect")
		init()
	end
end

local uniformcache = {0}
local toremove = {}
local empLinger = {}
local disarmLinger = {}
local LINGER_FRAMES = 9
local UPDATE_RATE = 2

function widget:GameFrame(n)
	if not TESTMODE then
		if n % UPDATE_RATE == 0 then
			for unitID, index in pairs(paralyzedDrawUnitVBOTable.instanceIDtoIndex) do
				local health, maxHealth, paralyzeDamage, capture, build = spGetUnitHealth(unitID)
				local para = (paralyzeDamage or 0) / (maxHealth > 0.1 and maxHealth or 1) > 1 and 1
				local disarmed = (spGetUnitRulesParam(unitID, "disarmed") == 1) and 1
				local slow = spGetUnitRulesParam(unitID, "slowState")
				local fire = (spGetUnitRulesParam(unitID, "on_fire") == 1)
				
				local wantRemove = (not para) and (not disarmed) and (slow or 0) <= 0 and (not fire)
				if (not para) and (not disarmed) then
					if empLinger[unitID] then
						empLinger[unitID] = empLinger[unitID] - UPDATE_RATE
						if empLinger[unitID] > 0 then
							para = empLinger[unitID] / LINGER_FRAMES
							wantRemove = false
						else
							empLinger[unitID] = nil
						end
					elseif disarmLinger[unitID] then
						disarmLinger[unitID] = disarmLinger[unitID] - UPDATE_RATE
						if disarmLinger[unitID] > 0 then
							disarmed = disarmLinger[unitID] / LINGER_FRAMES
							wantRemove = false
						else
							disarmLinger[unitID] = nil
						end
					end
				end
				
				if wantRemove then
					toremove[unitID] = true
				else
					if para == 1 then
						empLinger[unitID] = LINGER_FRAMES
					end
					if disarmed == 1 then
						disarmLinger[unitID] = LINGER_FRAMES
					end
					local val = 0
					if (slow or 0) > 0 then
						val = val + 1 + slow
					end
					if para then
						val = val + 4.01 + 0.1 * para
					elseif disarmed then
						val = val + 2.01 + 0.1 * disarmed
					end
					val = val + ((fire and 8) or 0)
					uniformcache[1] = val
					gl.SetUnitBufferUniforms(unitID, uniformcache, 4)
				end
			end
		end
		for unitID, _ in pairs(toremove) do
			StopDrawParalyzedUnitGL4(unitID)
			toremove[unitID] = nil
		end
	end
end

function widget:UnitCreated(unitID, unitDefID)
	if TESTMODE then
		DrawParalyzedUnitGL4(unitID, unitDefID)
	end
	-- Enemy units might die offscreen
	empLinger[unitID] = nil
	disarmLinger[unitID] = nil
	local health,maxHealth,paralyzeDamage,capture,build = spGetUnitHealth(unitID)
	local disarmed = spGetUnitRulesParam(unitID, "disarmed")
	local slow = spGetUnitRulesParam(unitID, "slowState")
	local fire = (spGetUnitRulesParam(unitID, "on_fire") == 1)
	if (paralyzeDamage and paralyzeDamage > 0) or (disarmed == 1) or (slow or 0) > 0 or fire then
		DrawParalyzedUnitGL4(unitID, unitDefID)
	end
end

function widget:RenderUnitDestroyed(unitID)
	StopDrawParalyzedUnitGL4(unitID)
	empLinger[unitID] = nil
	disarmLinger[unitID] = nil
end

-- Breaks spectators and is irrelevant for everyone else?
--function widget:UnitLeftLos(unitID)
--	StopDrawParalyzedUnitGL4(unitID)
--end

function widget:UnitEnteredLos(unitID)
	if fullview then return end
	widget:UnitCreated(unitID, spGetUnitDefID(unitID))
end

local function UnitStatusDamageEffect(unitID, unitDefID) -- called from Healthbars Widget Forwarding GADGET!!!
	widget:UnitCreated(unitID, unitDefID)
end

function widget:Initialize()
	if not gl.CreateShader then -- no shader support, so just remove the widget itself, especially for headless
		widgetHandler:RemoveWidget()
		return
	end
	initGL4()
	init()
	if TESTMODE then
		for i, unitID in ipairs(Spring.GetAllUnits()) do
			widget:UnitCreated(unitID)
			gl.SetUnitBufferUniforms(unitID, {1.01}, 4)
		end
	end
	WG['DrawParalyzedUnitGL4'] = DrawParalyzedUnitGL4
	WG['StopDrawParalyzedUnitGL4'] = StopDrawParalyzedUnitGL4
	widgetHandler:RegisterGlobal("UnitParalyzeDamageEffect", UnitStatusDamageEffect)
	widgetHandler:RegisterGlobal("UnitDisarmDamageEffect",   UnitStatusDamageEffect)
	widgetHandler:RegisterGlobal("UnitSlowDamageEffect",     UnitStatusDamageEffect)
	widgetHandler:RegisterGlobal("UnitFireDamageEffect",     UnitStatusDamageEffect)
end

function widget:Shutdown()
	WG['DrawParalyzedUnitGL4'] = nil
	WG['StopDrawParalyzedUnitGL4'] = nil
	widgetHandler:DeregisterGlobal("UnitParalyzeDamageEffect")
	widgetHandler:DeregisterGlobal("UnitDisarmDamageEffect")
	widgetHandler:DeregisterGlobal("UnitSlowDamageEffect")
	widgetHandler:DeregisterGlobal("UnitFireDamageEffect")
end

function widget:DrawWorld()
	if paralyzedDrawUnitVBOTable.usedElements > 0 then
		--if spGetGameFrame() % 90 == 0 then Spring.Echo("Drawing paralyzed units #", paralyzedDrawUnitVBOTable.usedElements) end
		gl.Culling(GL.BACK)
		gl.DepthMask(false) --"BK OpenGL state resets", default is already false, could remove
		gl.DepthTest(true)
		gl.PolygonOffset( -2 ,-2)
		paralyzedUnitShader:Activate()
		--gl.Texture(0, "luaui/images/noisetextures/rgba_noise_256.tga")
		paralyzedDrawUnitVBOTable.VAO:Submit()
		paralyzedUnitShader:Deactivate()
		--gl.Texture(0, false)
		gl.PolygonOffset( false )
		--gl.DepthMask(true) --"BK OpenGL state resets", was true but now commented out (redundant set of false states)
		gl.Culling(false)
	end
end
