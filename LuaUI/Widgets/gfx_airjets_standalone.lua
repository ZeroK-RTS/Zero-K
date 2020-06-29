--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Lups Airjets Standalone",
		desc      = "Non-LUPS copy of airjets.",
		author    = "GoogleFrog, jK",
		date      = "9 May 2020",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- 'Speedups'

local spGetUnitDefID         = Spring.GetUnitDefID
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetUnitPieceMap      = Spring.GetUnitPieceMap

local glUseShader            = gl.UseShader
local glUniform              = gl.Uniform
local glBlending             = gl.Blending
local glTexture              = gl.Texture
local glCallList             = gl.CallList

local GL_GREATER             = GL.GREATER
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local GL_ONE                 = GL.ONE

local glMultiTexCoord        = gl.MultiTexCoord
local glVertex               = gl.Vertex
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glBeginEnd             = gl.BeginEnd
local GL_QUADS               = GL.QUADS

local glAlphaTest            = gl.AlphaTest
local glDepthTest            = gl.DepthTest
local glDepthMask            = gl.DepthMask

local glPushMatrix           = gl.PushMatrix
local glPopMatrix            = gl.PopMatrix
local glScale                = gl.Scale
local glUnitMultMatrix       = gl.UnitMultMatrix
local glUnitPieceMultMatrix  = gl.UnitPieceMultMatrix

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Configuration
 
local effectDefs = {
	[UnitDefNames["planefighter"].id] = {
		fxList = {
			{
				emitVector        = {0, 0, -1},
				width             = 3.5,
				length            = 55,
				color             = {0.6, 0.1, 0.0},
				distortion        = 0.02,
				jitterWidthScale  = 3,
				jitterLengthScale = 3,
				animSpeed         = 1,

				piece             = "nozzle1",
				texture1          = "bitmaps/GPL/Lups/perlin_noise.jpg", --// noise texture
				texture2          = ":c:bitmaps/gpl/lups/jet2.bmp",       --// shape
				texture3          = ":c:bitmaps/GPL/Lups/jet.bmp",       --// jitter shape
			},
			{
				emitVector        = {0, 0, -1},
				width             = 3.5,
				length            = 55,
				color             = {0.6, 0.1, 0.0},
				distortion        = 0.02,
				jitterWidthScale  = 3,
				jitterLengthScale = 3,
				animSpeed         = 1,

				piece             = "nozzle2",
				texture1          = "bitmaps/GPL/Lups/perlin_noise.jpg", --// noise texture
				texture2          = ":c:bitmaps/gpl/lups/jet2.bmp",       --// shape
				texture3          = ":c:bitmaps/GPL/Lups/jet.bmp",       --// jitter shape
			},
		}
	}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local planes = IterableMap.New()

local shaders
local lastTexture1,lastTexture2 = false, false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Drawing

function AirJet_BeginDraw()
	glUseShader(shaders.jet)
		glUniform(shaders.timerUniform, spGetGameSeconds())
	glBlending(GL_ONE,GL_ONE)
end

function AirJet_EndDraw()
	glUseShader(0)
	glTexture(1, false)
	glTexture(2, false)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	lastTexture1, lastTexture2 = false, false
end

function AirJet_Draw(self)
	if (lastTexture1 ~= self.texture1) then
		glTexture(1, self.texture1)
		lastTexture1 = self.texture1
	end
	if (lastTexture2 ~= self.texture2) then
		glTexture(2, self.texture2)
		lastTexture2 = self.texture2
	end
	glCallList(self.dList)
end

function AirJet_BeginDrawDistortion()
	glUseShader(shaders.jitter)
		glUniform(shaders.timer2Uniform, spGetGameSeconds())
end

function AirJet_EndDrawDistortion()
	glUseShader(0)
	glTexture(1, false)
	glTexture(2, false)
	lastTexture1, lastTexture2 = false, false
end

function AirJet_DrawDistortion(self)
	if (lastTexture1 ~= self.texture1) then
		glTexture(1, self.texture1)
		lastTexture1 = self.texture1
	end
	if (lastTexture2 ~= self.texture3) then
		glTexture(2, self.texture3)
		lastTexture2 = self.texture3
	end
	glCallList(self.dList)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Draw Iteration

local function Draw(unitID, unitDefID, index, DoDraw)
	local unitEffects = effectDefs[unitDefID].fxList

	glPushMatrix()
	glUnitMultMatrix(unitID)
	for i = 1, #unitEffects do
		local fx = unitEffects[i]
		--// enter piece space
		glPushMatrix()
			glUnitPieceMultMatrix(unitID, fx.piecenum)
			glScale(1,1,-1)
			DoDraw(fx)
		glPopMatrix()
		--// leave piece space
	end

	--// leave unit space
	glPopMatrix()
end

--local function DrawDistortionLayers()
--	glBlending(GL_ONE,GL_ONE)
--
--	for i=-50,50 do
--		Draw("Distortion",i)
--	end
--
--	glBlending(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
--end

local function DrawParticles()
	glDepthTest(true)
	glAlphaTest(false)

	--// DrawDistortion()
	--if (anyDistortionsVisible)and(DistortionClass) then
	--	DistortionClass.BeginDraw()
	--	gl.ActiveFBO(DistortionClass.fbo,DrawDistortionLayers)
	--	DistortionClass.EndDraw()
	--end

	--// Draw() (layers: 1 upto 50)
	glAlphaTest(GL_GREATER, 0)
	
	AirJet_BeginDraw()
	--local indexMax, keyByIndex, dataByKey = IterableMap.GetBarbarianData(planes)
	--for i = 1, indexMax do
	--	local unitID = keyByIndex[i]
	--	local unitDefID = dataByKey[unitID]
	--	Draw(unitID, unitDefID, i, AirJet_BeginDraw, AirJet_Draw, AirJet_EndDraw)
	--end
	IterableMap.Apply(planes, Draw, AirJet_Draw)
	AirJet_EndDraw()

	glAlphaTest(false)
	glDepthTest(false)
end

local function DrawParticlesWater()
	glDepthTest(true)
	glDepthMask(false)

	glAlphaTest(GL_GREATER, 0)
	
	AirJet_BeginDraw()
	--local indexMax, keyByIndex, dataByKey = IterableMap.GetBarbarianData(planes)
	--for i = 1, indexMax do
	--	local unitID = keyByIndex[i]
	--	local unitDefID = dataByKey[unitID]
	--	Draw(unitID, unitDefID, i, AirJet_BeginDraw, AirJet_Draw, AirJet_EndDraw)
	--end
	IterableMap.Apply(planes, Draw, AirJet_BeginDraw, AirJet_Draw, AirJet_EndDraw)
	AirJet_EndDraw()
	
	glAlphaTest(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

local function FinishInitialization(unitID, effectDef)
	local pieceMap = spGetUnitPieceMap(unitID)
	for i = 1, #effectDef.fxList do
		local fx = effectDef.fxList[i]
		if fx.piece then
			fx.piecenum = pieceMap[fx.piece]
		end
	end
	effectDef.finishedInit = true
end

local function AddUnit(unitID, unitDefID)
	unitDefID = unitDefID or spGetUnitDefID(unitID)
	if not (unitDefID and effectDefs[unitDefID]) then
		return false
	end
	if not effectDefs[unitDefID].finishedInit then
		FinishInitialization(unitID, effectDefs[unitDefID])
	end
	IterableMap.Add(planes, unitID, unitDefID)
end

local function RemoveUnit(unitID, unitDefID)
	if not (unitDefID and effectDefs[unitDefID]) then
		return false
	end
	IterableMap.Remove(planes, unitID)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:UnitEnteredLos(unitID, unitTeam)
	AddUnit(unitID)
end

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	RemoveUnit(unitID, unitDefID)
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
	AddUnit(unitID, unitDefID)
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	RemoveUnit(unitID, unitDefID)
end

widget.DrawWorld           = DrawParticles
widget.DrawWorldReflection = DrawParticlesWater
widget.DrawWorldRefraction = DrawParticlesWater

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Initialization

local function CreateShader()
	local jetShader = gl.CreateShader({
		vertex = [[
			uniform float timer;

			varying float distortion;
			varying vec4 texCoords;

			const vec4 centerPos = vec4(0.0,0.0,0.0,1.0);

			#define WIDTH  gl_Vertex.x
			#define LENGTH gl_Vertex.y
			#define TEXCOORD gl_Vertex.zw
			// gl_MultiTexCoord0.xy := jitter width/length scale (i.e jitter quad length = gl_vertex.x * gl_MultiTexCoord0.x)
			// gl_MultiTexCoord0.z  := (quad_width) / (quad_length) (used to normalize the texcoord dimensions)
			#define DISTORTION_STRENGTH gl_MultiTexCoord0.w
			#define EMITDIR gl_MultiTexCoord1
			#define COLOR gl_MultiTexCoord2.rgb
			#define ANIMATION_SPEED gl_MultiTexCoord2.w

			void main()
			{
				texCoords.st = TEXCOORD;
				texCoords.pq = TEXCOORD;
				texCoords.q += timer * ANIMATION_SPEED;

				gl_Position = gl_ModelViewMatrix * centerPos ;
				vec3 dir3   = vec3(gl_ModelViewMatrix * EMITDIR) - gl_Position.xyz;
				vec3 v = normalize( dir3 );
				vec3 w = normalize( -vec3(gl_Position) );
				vec3 u = normalize( cross(w,v) );
				gl_Position.xyz += WIDTH*v + LENGTH*u;
				gl_Position      = gl_ProjectionMatrix * gl_Position;

				gl_FrontColor.rgb = COLOR;

				distortion = DISTORTION_STRENGTH;
			}
		]],
		fragment = [[
			uniform sampler2D noiseMap;
			uniform sampler2D mask;

			varying float distortion;
			varying vec4 texCoords;

			void main(void)
			{
					vec2 displacement = texCoords.pq;

					vec2 txCoord = texCoords.st;
					txCoord.s += (texture2D(noiseMap, displacement * distortion * 20.0).y - 0.5) * 40.0 * distortion;
					txCoord.t +=  texture2D(noiseMap, displacement).x * (1.0-texCoords.t)        * 15.0 * distortion;
					float opac = texture2D(mask,txCoord.st).r;

					gl_FragColor.rgb  = opac * gl_Color.rgb; //color
					gl_FragColor.rgb += pow(opac, 5.0 );     //white flame
					gl_FragColor.a    = opac*1.5;
			}

		]],
		uniformInt = {
			noiseMap = 1,
			mask = 2,
		},
		uniform = {
			timer = 0,
		}
	})

	if (jetShader == nil) then
		print(PRIO_MAJOR,"LUPS->airjet: (color-)shader error: "..gl.GetShaderLog())
		return false
	end

	local jitterShader = gl.CreateShader({
		vertex = [[
			uniform float timer;

			varying float distortion;
			varying vec4 texCoords;

			const vec4 centerPos = vec4(0.0,0.0,0.0,1.0);

			#define WIDTH  gl_Vertex.x
			#define LENGTH gl_Vertex.y
			#define TEXCOORD gl_Vertex.zw
			// gl_MultiTexCoord0.xy := jitter width/length scale (i.e jitter quad length = gl_vertex.x * gl_MultiTexCoord0.x)
			// gl_MultiTexCoord0.z  := (quad_width) / (quad_length) (used to normalize the texcoord dimensions)
			#define DISTORTION_STRENGTH gl_MultiTexCoord0.w
			#define EMITDIR gl_MultiTexCoord1
			#define COLOR gl_MultiTexCoord2.rgb
			#define ANIMATION_SPEED gl_MultiTexCoord2.w

			void main()
			{
				texCoords.st  = TEXCOORD;
				texCoords.pq  = TEXCOORD*0.8;
				texCoords.p  *= gl_MultiTexCoord0.z;
				texCoords.pq += 0.2*timer*ANIMATION_SPEED;

				gl_Position = gl_ModelViewMatrix * centerPos;
				vec3 dir3   = vec3(gl_ModelViewMatrix * EMITDIR) - gl_Position.xyz;
				vec3 v = normalize( dir3 );
				vec3 w = normalize( -vec3(gl_Position) );
				vec3 u = normalize( cross(w,v) );
				float length = LENGTH * gl_MultiTexCoord0.x;
				float width  = WIDTH * gl_MultiTexCoord0.y;
				gl_Position.xyz += width*v + length*u;
				gl_Position      = gl_ProjectionMatrix * gl_Position;

				distortion = DISTORTION_STRENGTH;
			}
		]],
		fragment = [[
			uniform sampler2D noiseMap;
			uniform sampler2D mask;

			varying float distortion;
			varying vec4 texCoords;

			void main(void)
			{
					float opac    = texture2D(mask,texCoords.st).r;
					vec2 noiseVec = (texture2D(noiseMap, texCoords.pq).st - 0.5) * distortion * opac;
					gl_FragColor  = vec4(noiseVec.xy,0.0,gl_FragCoord.z);
			}

		]],
		uniformInt = {
			noiseMap = 1,
			mask = 2,
		},
		uniform = {
			timer = 0,
		}
	})


	if (jitterShader == nil) then
		print(PRIO_MAJOR,"LUPS->airjet: (jitter-)shader error: "..gl.GetShaderLog())
		return false
	end

	local timerUniform  = gl.GetUniformLocation(jetShader, 'timer')
	local timer2Uniform = gl.GetUniformLocation(jitterShader, 'timer')
	
	return {
		jet = jetShader,
		jitter = jitterShader,
		timerUniform = timerUniform,
		timer2Uniform = timer2Uniform,
	}
end

local function BeginEndDrawList(self)
	local color = self.color
	local ev    = self.emitVector
	glMultiTexCoord(0, self.jitterWidthScale, self.jitterLengthScale, self.width/self.length, self.distortion)
	glMultiTexCoord(1, ev[1], ev[2], ev[3], 1)
	glMultiTexCoord(2, color[1], color[2], color[3], self.animSpeed)

	--// xy = width/length ; zw = texcoord
	local w = self.width
	local l = self.length
	glVertex(-l,-w, 1,0)
	glVertex(0, -w, 1,1)
	glVertex(0,  w, 0,1)
	glVertex(-l, w, 0,0)
end

local function InitializeParticleLists()
	for unitDefID, data in pairs(effectDefs) do
		for i = 1, #data.fxList do
			data.fxList[i].dList = glCreateList(glBeginEnd, GL_QUADS, BeginEndDrawList, data.fxList[i])
		end
	end
end

function widget:Initialize()
	shaders = CreateShader()
	InitializeParticleLists()
	
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		widget:UnitCreated(unitID, unitDefID, myTeamID)
	end
end
