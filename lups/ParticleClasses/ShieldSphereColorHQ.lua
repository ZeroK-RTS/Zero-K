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
	if not self.texture then
		gl.UniformInt(methodUniform, 0)
	else
		gl.UniformInt(methodUniform, 1)
		if (lastTexture ~= self.texture) then
			gl.Texture(0, self.texture)
			lastTexture = self.texture
		end
	end

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

	uniform float sizeDrift;

	uniform int hitPointCount;
	uniform float hitPoints[5 * MAX_POINTS];

	uniform sampler2D tex0;

	uniform int method;

	#define PI 3.141592653589793

	#define HEXSCALE 90.0

	#define SZDRIFTTOUV 7.0

	#define nsin(x) (0.5 * sin(x) + 0.5)

	float hex(vec2 p, float width, float coreSize)
	{
		p.x *= 0.57735 * 2.0;
		p.y += mod(floor(p.x), 2.0)*0.5;
		p = abs((mod(p, 1.0) - 0.5));
		float val = abs(max(p.x*1.5 + p.y, p.y*2.0) - 1.0);
		return smoothstep(coreSize, width, val);
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

		for (int hitPointIdx = 0; hitPointIdx < MAX_POINTS; ++hitPointIdx) {
			if (hitPointIdx < hitPointCount) {
				vec3 impactPoint = vec3(hitPoints[5 * hitPointIdx + 0], hitPoints[5 * hitPointIdx + 1], hitPoints[5 * hitPointIdx + 2]);
				vec3 impactPointAdj = (vec4(impactPoint, 1.0) * viewMatrixI).xyz;
				vec2 impactPointUV = RadialCoords(impactPointAdj) * uvMulS;
				float mag = hitPoints[5 * hitPointIdx + 3];
				float aoe = hitPoints[5 * hitPointIdx + 4];
				offset2 += GetRippleLinearFallOffCoord(uv, impactPointUV, mag, 100.0, -120.0, aoe, timer);
			}
		}

		vec2 uvo = uv + offset + offset2; //this is to trick GLSL compiler, otherwise shot-induced ripple is not drawn. Silly....

		vec4 texel;
		if (method == 0)
			texel = vec4(1.0 - hex(uvo * HEXSCALE, 0.2, 0.01));
		else if (method == 1)
			texel = texture2D(tex0, uvo);
		else
			texel = vec4(0.0);

		vec4 colorMultAdj = colorMult * (1.0 + length(offset2) * 50.0);
		//float colorMultAdj = colorMult;
		//vec4 color1M = color1 * colorMultAdj;
		vec4 color2M = color2 * colorMultAdj;

		vec4 color1Tex = mix(color1, texel, colorMix);
		vec4 color1TexM = color1Tex * colorMultAdj;

		gl_FragColor = mix(color1TexM, color2M, opac);
		//gl_FragColor = mix(color1Tex, color2M, opac);
		//gl_FragColor = texel;
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
	shieldSizeDriftUniform = gl.GetUniformLocation(shieldShader, 'sizeDrift')
	marginUniform = gl.GetUniformLocation(shieldShader, 'margin')
	uvMulUniform = gl.GetUniformLocation(shieldShader, 'uvMul')

	hitPointCountUniform = gl.GetUniformLocation(shieldShader, 'hitPointCount')
	hitPointsUniform = gl.GetUniformLocation(shieldShader, 'hitPoints')

	sphereList = {
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