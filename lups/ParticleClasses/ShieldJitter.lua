-- $Id: ShieldJitter.lua 3171 2008-11-06 09:06:29Z det $
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local ShieldJitter = {}
ShieldJitter.__index = ShieldJitter

local warpShader
local timerUniform,strengthUniform
local sphereList

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldJitter.GetInfo()
	return {
		name      = "ShieldJitter",
		backup    = "", --// backup class, if this class doesn't work (old cards,ati's,etc.)
		desc      = "",

		layer     = 16, --// extreme simply z-ordering :x

		--// gfx requirement
		fbo       = true,
		shader    = true,
		distortion= true,
		rtt       = false,
		ctt       = true,
		intel     = 0,
	}
end

ShieldJitter.Default = {
	layer = 16,

	pos        = {0,0,0}, --// start pos
	life       = math.huge,

	size       = 600,
	--precision  = 26, --// bias the used polies for a sphere

	strength   = 0.015,
	texture    = 'bitmaps/GPL/Lups/grass5.png',
	--texture    = 'bitmaps/GPL/Lups/perlin_noise.jpg',

	repeatEffect = false,
	dieGameFrame = math.huge
}

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldJitter:BeginDrawDistortion()
	gl.UseShader(warpShader)
	gl.Uniform(timerUniform,  Spring.GetGameSeconds()*0.1)

	gl.Culling(GL.FRONT) --FIXME: check if camera is in the sphere
end

function ShieldJitter:EndDrawDistortion()
	gl.UseShader(0)
	gl.Texture(0,false)

	gl.Culling(false)
end

function ShieldJitter:DrawDistortion()
	local pos  = self.pos
	local size = self.size
	gl.Uniform(strengthUniform,  self.strength )

	gl.Texture(0,self.texture)
	gl.MultiTexCoord(1, pos[1], pos[2], pos[3], size)
	gl.CallList(sphereList)
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldJitter.Initialize()
	warpShader = gl.CreateShader({
		vertex = [[
			uniform float timer;
			uniform float strength;

			varying float scale;
			varying vec2 texCoord;

			#define pos vec4(gl_MultiTexCoord1.xyz, 0.0)
			#define size vec4(gl_MultiTexCoord1.www, 1.0)

	void main()
	{
					gl_Position = gl_ModelViewProjectionMatrix * (gl_Vertex * size + pos);
					texCoord       = gl_MultiTexCoord0.st + timer;

					vec3 normal  = normalize(gl_NormalMatrix * gl_Normal);
					vec3 nvertex = normalize(vec3(gl_ModelViewMatrix * gl_Vertex));
					scale = strength*abs(dot( normal,nvertex ));
	}
		]],
		fragment = [[
			uniform sampler2D noiseMap;

			varying float scale;
			varying vec2 texCoord;

			void main(void)
			{
					vec2 noiseVec;
					noiseVec = texture2D(noiseMap, texCoord).yz - 0.5;
					noiseVec *= scale;

					gl_FragColor = vec4(noiseVec,0.0,gl_FragCoord.z);
			}

		]],
		uniformInt = {
			noiseMap = 0,
		},
		uniformFloat = {
			timer = 0,
			strength = 0.015,
		}
	})

	local shLog = gl.GetShaderLog()
	if (warpShader == nil or string.len(shLog or "") > 0) then
		print(PRIO_MAJOR,"LUPS->ShieldJitter: shader error: "..shLog)
		return false
	end

	timerUniform    = gl.GetUniformLocation(warpShader, 'timer')
	strengthUniform = gl.GetUniformLocation(warpShader, 'strength')

	sphereList = gl.CreateList(DrawSphere,0,0,0,1,22)
end

function ShieldJitter.Finalize()
	gl.DeleteShader(warpShader)
	gl.DeleteList(sphereList)
	gl.DeleteTexture(tex)
end

function ShieldJitter.ViewResize(viewSizeX, viewSizeY)
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldJitter:Update()
end

-- used if repeatEffect=true;
function ShieldJitter:ReInitialize()
	self.dieGameFrame = self.dieGameFrame + self.life
end

function ShieldJitter:CreateParticle()
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function ShieldJitter.Create(Options)
	local newObject = MergeTable(Options, ShieldJitter.Default)
	setmetatable(newObject,ShieldJitter)  -- make handle lookup
	newObject:CreateParticle()
	return newObject
end

function ShieldJitter:Destroy()
	gl.DeleteTexture(self.texture)
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

return ShieldJitter