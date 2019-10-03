-- $Id: ShieldSphereColorHQ.lua 3171 2008-11-06 09:06:29Z det $
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local ShieldSphereColorHQParticle = {}
ShieldSphereColorHQParticle.__index = ShieldSphereColorHQParticle

local sphereList = {}
local shieldShader

local methodUniform
local timerUniform
local color1Uniform
local color2Uniform
local colorMultUniform
local colorMixUniform
local shieldPosUniform
local shieldRechargingNoiseUniform
local shieldSizeUniform
local shieldSizeDriftUniform
local marginUniform
local uvMulUniform

local viewInvUniform

local hitPointCountUniform
local hitPointsUniform


-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldSphereColorHQParticle.GetInfo()
	return {
		name		= "ShieldSphereColorHQ",
		backup		= "ShieldSphereColor", --// backup class, if this class doesn't work (old cards,ati's,etc.)
		desc		= "",

		layer		= -23, --// extreme simply z-ordering :x

		--// gfx requirement
		fbo			= false,
		shader		= true,
		rtt			= false,
		ctt			= false,
	}
end

ShieldSphereColorHQParticle.Default = {
	pos				= {0, 0, 0}, -- start pos
	layer			= -23,

	life			= math.huge,

	size			= 10,
	margin			= 1,
	onHitTransitionTime = 10,
	rechargeSpinupTime = 20,
	startOfRechargeDelay = -999999,

	colormap1	= { {0, 0, 0, 0} },
	colormap2	= { {0, 0, 0, 0} },

	repeatEffect = false,
	shieldSize = "large",
}

-- (dx, dy, dz, mag, AoE) x 8
local MAX_POINTS = 8

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local glCallList = gl.CallList

function ShieldSphereColorHQParticle:Visible()
	return self.visibleToMyAllyTeam
end

local PACE = 400

local lastTexture = ""

function ShieldSphereColorHQParticle:BeginDraw()
	--gl.Clear(GL.STENCIL_BUFFER_BIT, 0)
	gl.DepthMask(false)
	gl.UseShader(shieldShader)

	local gf = Spring.GetGameFrame()
	gl.Uniform(timerUniform,	gf / PACE)
	gl.UniformMatrix(viewInvUniform, "viewinverse")
end

function ShieldSphereColorHQParticle:EndDraw()
	gl.DepthMask(false)
	gl.UseShader(0)

	gl.Texture(0, false)
	lastTexture = ""

	gl.Culling(false)
end

function ShieldSphereColorHQParticle:Draw()

	gl.Culling(GL.FRONT)
	-- Noise should only vary from 0.0 to 1.0
	local noiseLevel = 0
	if self.rechargeDelay > 0 then
		gl.UniformInt(methodUniform, 2)
		local hitTime = Spring.GetUnitRulesParam(self.unit, "shieldHitFrame") or -999999
		local currTime = Spring.GetGameFrame()
		local cooldown = hitTime + self.rechargeDelay * 30 - currTime
		if cooldown > 0 then
			local rampDown = 1.0
			if cooldown < self.rechargeSpinupTime then
				rampDown = cooldown / self.rechargeSpinupTime
			end
			local timeSinceRegenDisabled = currTime - self.startOfRechargeDelay
			local rampUp = 1.0
			if timeSinceRegenDisabled < self.onHitTransitionTime then
				rampUp = timeSinceRegenDisabled / self.onHitTransitionTime
			end
			noiseLevel = rampDown * rampUp
		else
			self.startOfRechargeDelay = currTime
		end
	else
		if not self.texture then
			gl.UniformInt(methodUniform, 0)
		else
			gl.UniformInt(methodUniform, 1)
			if (lastTexture ~= self.texture) then
				gl.Texture(0, self.texture)
				lastTexture = self.texture
			end
		end
	end
	gl.Uniform(shieldRechargingNoiseUniform, noiseLevel)

	local col1, col2 = GetShieldColor(self.unit, self)

	local hitTable
	if (GG and GG.GetShieldHitPositions) then --means high quality shield rendering is in place
		hitTable = GG.GetShieldHitPositions(self.unit)
	end
	
	gl.Uniform(color1Uniform, col1[1], col1[2], col1[3], col1[4])
	gl.Uniform(color2Uniform, col2[1], col2[2], col2[3], col2[4])
	gl.Uniform(colorMultUniform, 1, 1, 1, 1)

	local mix = self.mix
	gl.Uniform(colorMixUniform, mix[1], mix[2], mix[3], mix[4])

	local pos = self.pos
	gl.Uniform(shieldPosUniform, pos[1], pos[2], pos[3], 0)

	gl.Uniform(shieldSizeUniform, self.size)
	gl.Uniform(shieldSizeDriftUniform, self.sizeDrift)
	gl.Uniform(marginUniform, self.marginHQ)
	gl.Uniform(uvMulUniform, self.uvMul)
	gl.UniformInt(unitIdUniform, self.unit)

	if hitTable then
		local hitPointCount = math.min(#hitTable, MAX_POINTS)
		gl.UniformInt(hitPointCountUniform, hitPointCount)

		local hitArray = {}
		if hitPointCount > 0 then
			--Spring.Echo("hitPointCount", hitPointCount)
			for i = 1, hitPointCount do
				table.insert(hitArray, hitTable[i].dx)
				table.insert(hitArray, hitTable[i].dy)
				table.insert(hitArray, hitTable[i].dz)
				table.insert(hitArray, hitTable[i].mag)
				table.insert(hitArray, hitTable[i].aoe)
			end
		end
		gl.UniformArray(hitPointsUniform, 2, hitArray)
	end

	glCallList(sphereList[self.shieldSize])

	if self.drawBackHQ then
		gl.Culling(GL.BACK)

		gl.Uniform(colorMultUniform, self.drawBackHQ[1], self.drawBackHQ[2], self.drawBackHQ[3], self.drawBackHQ[4])

		if self.drawBackMargin then
			gl.Uniform(marginUniform, self.drawBackMargin)
		end

		glCallList(sphereList[self.shieldSize])
	end
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local vsCode = [[
____VS_CODE_DEFS_____
	uniform vec4 pos;
	uniform float margin;
	uniform float size;

	uniform float uvMul;

	uniform float timer;

	uniform float sizeDrift;

	varying float opac;

	varying vec3 normal;

	#define DRIFT_FREQ 25.0

	#define PI 3.141592653589793

	#define nsin(x) (0.5 * sin(x) + 0.5)

	void main()
	{
		gl_TexCoord[0] = gl_MultiTexCoord0;

		float r = length(gl_Vertex.xyz);
		float theta = acos(gl_Vertex.z / r);
		float phi = atan(gl_Vertex.y, gl_Vertex.x);

		r += sizeDrift * r * nsin(theta + phi + timer * DRIFT_FREQ);

		vec4 myVertex;
		myVertex = vec4(r * sin(theta) * cos(phi), r * sin(theta) * sin(phi), r * cos(theta), 1.0f);

		vec4 size4 = vec4(size, size, size, 1.0f);
		gl_Position = gl_ModelViewProjectionMatrix * (myVertex * size4 + pos);

		normal = normalize(gl_NormalMatrix * gl_Normal);

		vec3 vertex = vec3(gl_ModelViewMatrix * myVertex);
		float angle = dot(normal, vertex) * inversesqrt( dot(normal, normal) * dot(vertex, vertex) ); //dot(norm(n), norm(v))
		opac = pow( abs( angle ) , margin);
	}
]]

local fsCode = [[
____FS_CODE_DEFS_____
	varying float opac;
	varying vec3 normal;

	uniform float timer;

	uniform mat4 viewMatrixI;

	uniform vec4 color1;
	uniform vec4 color2;
	uniform vec4 colorMult;
	uniform vec4 colorMix;

	uniform float uvMul;
	
	uniform float noiseLevel;

	uniform float sizeDrift;

	uniform int shieldVariant;
	uniform int unitId; // Used as a seed to make shield appearances unique

	uniform int hitPointCount;
	uniform float hitPoints[5 * MAX_POINTS];

	uniform sampler2D tex0;

	uniform int method;

	#define PI 3.141592653589793
	#define HEXSCALE 90.0
	#define SZDRIFTTOUV 7.0
	#define nsin(x) (0.5 * sin(x) + 0.5)
	#define HASHSCALE1 443.8975
	
	float hex(vec2 p, float width, float coreSize)
	{
		p.x *= 0.57735 * 2.0;
		p.y += mod(floor(p.x), 2.0)*0.5;
		p = abs((mod(p, 1.0) - 0.5));
		float val = abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
		return smoothstep(coreSize, width, val);
	}
	
	float hash11(float p) {
		vec3 p3  = fract(vec3(p) * HASHSCALE1);
		p3 += dot(p3, p3.yzx + 19.19);
		return fract((p3.x + p3.y) * p3.z);
	}
	
	vec2 GetRippleLinearFallOffCoord(vec2 uv, vec2 point, float mag, float waveFreq, float waveSpeed, float waveDist, float time)
	{
		vec2 dir = uv - point;
		float dist = distance(uv, point);
		float magMult = (1.0 - smoothstep(0.0, waveDist, dist));
		vec2 offset = dir * (nsin(dist * waveFreq - time * waveSpeed)) * mag * magMult;
		return offset;
	}

	vec2 GetRippleCoord(vec2 uv, vec2 point, float mag, float waveFreq, float waveSpeed, float time)
	{
		vec2 dir = uv - point;
		float dist = distance(uv, point);
		vec2 offset = dir * (nsin(dist * waveFreq - time * waveSpeed)) * mag;
		return offset;
	}

			//
			// Description : Array and textureless GLSL 2D/3D/4D simplex
			//               noise functions.
			//      Author : Ian McEwan, Ashima Arts.
			//  Maintainer : stegu
			//     Lastmod : 20110822 (ijm)
			//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
			//               Distributed under the MIT License. See LICENSE file.
			//               https://github.com/ashima/webgl-noise
			//               https://github.com/stegu/webgl-noise
			//

			vec3 mod289(vec3 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			vec4 mod289(vec4 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			vec4 permute(vec4 x) {
					 return mod289(((x*34.0)+1.0)*x);
			}

			vec4 taylorInvSqrt(vec4 r)
			{
				return 1.79284291400159 - 0.85373472095314 * r;
			}

			float snoise(vec3 v)
				{
				const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
				const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

			// First corner
				vec3 i  = floor(v + dot(v, C.yyy) );
				vec3 x0 =   v - i + dot(i, C.xxx) ;

			// Other corners
				vec3 g = step(x0.yzx, x0.xyz);
				vec3 l = 1.0 - g;
				vec3 i1 = min( g.xyz, l.zxy );
				vec3 i2 = max( g.xyz, l.zxy );

				//   x0 = x0 - 0.0 + 0.0 * C.xxx;
				//   x1 = x0 - i1  + 1.0 * C.xxx;
				//   x2 = x0 - i2  + 2.0 * C.xxx;
				//   x3 = x0 - 1.0 + 3.0 * C.xxx;
				vec3 x1 = x0 - i1 + C.xxx;
				vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
				vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

			// Permutations
				i = mod289(i);
				vec4 p = permute( permute( permute(
									 i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
								 + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
								 + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

			// Gradients: 7x7 points over a square, mapped onto an octahedron.
			// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
				float n_ = 0.142857142857; // 1.0/7.0
				vec3  ns = n_ * D.wyz - D.xzx;

				vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

				vec4 x_ = floor(j * ns.z);
				vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

				vec4 x = x_ *ns.x + ns.yyyy;
				vec4 y = y_ *ns.x + ns.yyyy;
				vec4 h = 1.0 - abs(x) - abs(y);

				vec4 b0 = vec4( x.xy, y.xy );
				vec4 b1 = vec4( x.zw, y.zw );

				//vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
				//vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
				vec4 s0 = floor(b0)*2.0 + 1.0;
				vec4 s1 = floor(b1)*2.0 + 1.0;
				vec4 sh = -step(h, vec4(0.0));

				vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
				vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

				vec3 p0 = vec3(a0.xy,h.x);
				vec3 p1 = vec3(a0.zw,h.y);
				vec3 p2 = vec3(a1.xy,h.z);
				vec3 p3 = vec3(a1.zw,h.w);

			//Normalise gradients
				vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
				p0 *= norm.x;
				p1 *= norm.y;
				p2 *= norm.z;
				p3 *= norm.w;

			// Mix final noise value
				vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
				m = m * m;
				return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
																			dot(p2,x2), dot(p3,x3) ) );
			}

	vec3 RectToPolar(vec3 rect) {
		float len = length(rect);
		return vec3(len, acos(rect.z/len), atan(rect.x, rect.y));
	}

	vec3 PolarToRect(vec3 p) {
		return vec3(p.x*sin(p.y)*cos(p.z), p.x*sin(p.y)*sin(p.z), p.x*cos(p.y));
	}

	vec2 RadialCoords(vec3 a_coords)
	{
		vec3 a_coords_n = normalize(a_coords);
		float lon = atan(a_coords_n.z, a_coords_n.x);
		float lat = acos(a_coords_n.y);
		vec2 sphereCoords = vec2(lon, lat) / PI;
		return vec2(sphereCoords.x * 0.5 + 0.5, 1.0 - sphereCoords.y);
	}

	void main(void)
	{
		vec2 uvMulS = vec2(1.0, 0.5) * uvMul;
		vec2 uv = RadialCoords(normal) * uvMulS;

		vec2 offset = vec2(0.0);

		//offset += GetRippleCoord(uv, vec2(0.75, 0.5) * uvMulS, sizeDrift * SZDRIFTTOUV, 80.0, 15.0, timer);
		offset += GetRippleCoord(uv, vec2(0.25 + 0.5 * float(!gl_FrontFacing), 0.5) * uvMulS, sizeDrift * SZDRIFTTOUV, 80.0, 15.0, timer);

		vec2 offset2 = vec2(0.0);
		
		float hitRadiusMulti = 1;
		if (method == 2) {
			hitRadiusMulti = 0.7;
		}

		for (int hitPointIdx = 0; hitPointIdx < MAX_POINTS; ++hitPointIdx) {
			if (hitPointIdx < hitPointCount) {
				vec3 impactPoint = vec3(hitPoints[5 * hitPointIdx + 0], hitPoints[5 * hitPointIdx + 1], hitPoints[5 * hitPointIdx + 2]);
				vec3 impactPointAdj = (vec4(impactPoint, 1.0) * viewMatrixI).xyz;
				vec2 impactPointUV = RadialCoords(impactPointAdj) * uvMulS;
				float mag = hitPoints[5 * hitPointIdx + 3];
				float aoe = hitPoints[5 * hitPointIdx + 4];
				offset2 += GetRippleLinearFallOffCoord(uv, impactPointUV, mag, 100.0 / hitRadiusMulti, -120.0, aoe * hitRadiusMulti, timer);
			}
		}

		vec2 uvo = uv + offset + offset2; //this is to trick GLSL compiler, otherwise shot-induced ripple is not drawn. Silly....

		vec4 texel;
		float alphaAdd = 0.0;
		float noiseMult = 1;
		if (method == 0)
			texel = vec4(1.0 - hex(uvo * HEXSCALE, 0.2, 0.01));
		else if (method == 1)
			texel = texture2D(tex0, uvo);
		else if (method == 2) {
			vec3 adjustedOffset = vec3(0.0);
			if (length(offset2) > 0) {
				vec3 pOffset2 = RectToPolar(vec3(offset2, 0));
				vec3 pNormal = RectToPolar(normal);
				pOffset2.y += pNormal.y;
				pOffset2.z += pNormal.z;
				adjustedOffset = PolarToRect(pOffset2) * 10.0;
				alphaAdd = smoothstep(0.0, 0.04, length(offset2));
			}
			vec3 offsetNormal = normal + adjustedOffset;
			vec3 standardVec = offsetNormal * 2;
			float seed = hash11(float(unitId));
			standardVec.z -= timer * 3 + seed;
			vec3 noiseVec = offsetNormal * 5;
			noiseVec.z -= timer * 6 + seed;
			noiseMult = 0.5 + (1 - abs(snoise(standardVec))) + (snoise(noiseVec)) * noiseLevel / 2.0;
		}
		else
			texel = vec4(0.0);
		
		vec4 colorMultAdj = colorMult * (1.0 + length(offset2) * 50.0) * noiseMult;
		//float colorMultAdj = colorMult;
		//vec4 color1M = color1 * colorMultAdj;
		vec4 color2M = color2 * colorMultAdj;

		vec4 color1Tex = mix(color1, texel, colorMix);
		vec4 color1TexM = color1Tex * colorMultAdj;

		gl_FragColor = mix(color1TexM, color2M, opac);
		//gl_FragColor = mix(color1Tex, color2M, opac);
		//gl_FragColor = texel;
		gl_FragColor.a += alphaAdd;
	}
]]

commonCodeDefs = {
	"#version 120",
}

vsCodeDefs = {
}

fsCodeDefs = {
	string.format("#define MAX_POINTS %d\n", MAX_POINTS),
}

local function ListToString(defs)
	local result = ""
	for _, line in ipairs(defs) do
		result = result .. "\t" .. line .. "\n"
	end
	return result
end

function ShieldSphereColorHQParticle:Initialize()
	local vsCodeEff = string.gsub(vsCode, "____VS_CODE_DEFS_____", ListToString(commonCodeDefs) .. ListToString(vsCodeDefs))
	local fsCodeEff = string.gsub(fsCode, "____FS_CODE_DEFS_____", ListToString(commonCodeDefs) .. ListToString(fsCodeDefs))
	shieldShader = gl.CreateShader({
		vertex = vsCodeEff,
		fragment = fsCodeEff,
		uniformInt = {
			tex0 = 0,
		},
	})

	local shLog = gl.GetShaderLog()

	if (string.len(shLog or "") > 0) then
		print(PRIO_MAJOR, "LUPS->Shield: shader warnings & errors:\n"..shLog)
		print(PRIO_MAJOR, "LUPS->Shield: Vertex Shader Code:\n"..vsCodeEff)
		print(PRIO_MAJOR, "LUPS->Shield: Fragment Shader Code:\n"..fsCodeEff)
	end
	if (shieldShader == nil) then
		return false
	end

	timerUniform = gl.GetUniformLocation(shieldShader, 'timer')
	viewInvUniform = gl.GetUniformLocation(shieldShader, 'viewMatrixI')

	methodUniform = gl.GetUniformLocation(shieldShader, 'method')

	color1Uniform = gl.GetUniformLocation(shieldShader, 'color1')
	color2Uniform = gl.GetUniformLocation(shieldShader, 'color2')
	colorMultUniform = gl.GetUniformLocation(shieldShader, 'colorMult')
	colorMixUniform = gl.GetUniformLocation(shieldShader, 'colorMix')
	shieldPosUniform = gl.GetUniformLocation(shieldShader, 'pos')
	shieldSizeUniform = gl.GetUniformLocation(shieldShader, 'size')
	shieldRechargingNoiseUniform = gl.GetUniformLocation(shieldShader, 'noiseLevel')
	shieldSizeDriftUniform = gl.GetUniformLocation(shieldShader, 'sizeDrift')
	marginUniform = gl.GetUniformLocation(shieldShader, 'margin')
	uvMulUniform = gl.GetUniformLocation(shieldShader, 'uvMul')
	unitIdUniform = gl.GetUniformLocation(shieldShader, 'unitId')

	hitPointCountUniform = gl.GetUniformLocation(shieldShader, 'hitPointCount')
	hitPointsUniform = gl.GetUniformLocation(shieldShader, 'hitPoints')

	sphereList = {
		huge = gl.CreateList(DrawSphere, 0, 0, 0, 1, 140),
		large = gl.CreateList(DrawSphere, 0, 0, 0, 1, 60),
		medium = gl.CreateList(DrawSphere, 0, 0, 0, 1, 50),
		small = gl.CreateList(DrawSphere, 0, 0, 0, 1, 40),
	}
end

function ShieldSphereColorHQParticle:Finalize()
	if shieldShader then
		gl.DeleteShader(shieldShader)
	end
	for _, list in pairs(sphereList) do
		gl.DeleteList(list)
	end
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldSphereColorHQParticle:CreateParticle()
	self.dieGameFrame = Spring.GetGameFrame() + self.life
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldSphereColorHQParticle:Update()
end

-- used if repeatEffect=true;
function ShieldSphereColorHQParticle:ReInitialize()
	self.dieGameFrame = self.dieGameFrame + self.life
end

function ShieldSphereColorHQParticle.Create(Options)
	local newObject = MergeTable(Options, ShieldSphereColorHQParticle.Default)
	setmetatable(newObject, ShieldSphereColorHQParticle)	-- make handle lookup
	newObject:CreateParticle()
	return newObject
end

function ShieldSphereColorHQParticle:Destroy()
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

return ShieldSphereColorHQParticle
