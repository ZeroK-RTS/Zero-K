-- $Id: Ribbons.lua 3171 2008-11-06 09:06:29Z det $
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local Ribbon = {}
Ribbon.__index = Ribbon

local RibbonShader
local widthLoc, quadsLoc
local oldPosUniform = {}
local lastTexture

local DLists = {}

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function Ribbon.GetInfo()
	return {
		name      = "Ribbon",
		backup    = "", --// backup class, if this class doesn't work (old cards,ati's,etc.)
		desc      = "",

		layer     = 1, --// extreme simply z-ordering :x

		--// gfx requirement
		fbo       = false,
		shader    = true,
		rtt       = false,
		ctt       = false,
	}
end

Ribbon.Default = {
	layer = 1,

	life     = math.huge,
	unit     = nil,
	projectile=nil,
	piece    = 0,
	width    = 1,
	size     = 24, --//max 256
	color    = {0.9,0.9,1,1},
	texture  = "bitmaps/GPL/Lups/jet.bmp",
	decayRate = 0.01,

	worldspace = true,
	repeatEffect = true,
	dieGameFrame = math.huge,
	
	isvalid = true,
}

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local spGetUnitDefID         = Spring.GetUnitDefID
local spGetUnitIsDead        = Spring.GetUnitIsDead
local spIsUnitValid          = Spring.IsUnitValid
local spIsSphereInView       = Spring.IsSphereInView
local spGetUnitVelocity      = Spring.GetUnitVelocity
local spGetUnitPiecePosition = Spring.GetUnitPiecePosition
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitPiecePosDir   = Spring.GetUnitPiecePosDir
local spGetUnitVectors       = Spring.GetUnitVectors
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileVelocity = Spring.GetProjectileVelocity
local spGetDrawFrame         = Spring.GetDrawFrame
local glUniform    = gl.Uniform
local glUniformInt = gl.UniformInt
local glUseShader  = gl.UseShader
local glColor      = gl.Color
local glCallList   = gl.CallList
local glTexture    = gl.Texture
local glBlending   = gl.Blending
local GL_ONE = GL.ONE
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

local function GetPiecePos(unit,piece)
	local x,y,z = spGetUnitViewPosition(unit,false)
	local front,up,right = spGetUnitVectors(unit)
	local px,py,pz = spGetUnitPiecePosition(unit,piece)
	return x + (pz*front[1] + py*up[1] + px*right[1]),
				 y + (pz*front[2] + py*up[2] + px*right[2]),
				 z + (pz*front[3] + py*up[3] + px*right[3])
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local MAX_POINTS = 256
local HISTORY_BINDING = 8
local WRITES_BINDING = 9
local INSTANCE_FLOATS = 12

local gl4Shader, gl4PausedLoc
local historyShader, historyWriteCountLoc
local ribbonVAO, ribbonVertices, ribbonIndices
local instanceVBO, instanceCapacity = nil, 0
local historyVBO, historyCapacity = nil, 0
local writesVBO, writesCapacity = nil, 0

local historyRibbons = {}
local freeSlots = {}
local slotCount = 0
local writes, writeCount = {}, 0

local batchRibbons, batchSize = {}, 0
local batchTextures = {}
local batchData = {}
local batchCount = {}
local batchMaxQuads = 0
local drawPaused, drawInterpolated
local unitOffsets, unitOffsetsFrame = {}, nil

local gl4VertexShader = [[
	#version 430 compatibility

	layout(std430, binding = 8) readonly buffer RibbonHistory {
		vec4 history[];
	};

	layout(location = 0) in vec2 pointAndSide;
	layout(location = 1) in vec4 headAndLatest;
	layout(location = 2) in vec4 ringBaseQuadsWidth;
	layout(location = 3) in vec4 ribbonColor;

	uniform int paused;

	out vec2 texCoord;
	out vec4 color;

	vec3 RingPoint(int index)
	{
		int size = int(ringBaseQuadsWidth.y) + 1;
		int slot = int(headAndLatest.w) + 1 + index;
		if (slot >= size) {
			slot -= size;
		}
		return history[int(ringBaseQuadsWidth.x) + slot].xyz;
	}

	vec3 TrailPoint(int index, int quads)
	{
		if (paused != 0) {
			if (index == quads - 1) {
				return (RingPoint(index - 1) + RingPoint(index)) / 2.0;
			}
			if (index == quads) {
				return RingPoint(quads - 1);
			}
		} else if (index == quads) {
			return headAndLatest.xyz;
		}
		return RingPoint(index);
	}

	void main()
	{
		int quads = int(ringBaseQuadsWidth.y);
		if (gl_VertexID / 4 >= quads) {
			gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
			texCoord = vec2(0.0);
			color = vec4(0.0);
			return;
		}

		int index = int(pointAndSide.x);
		float side = pointAndSide.y;
		vec4 position = gl_ModelViewMatrix * vec4(TrailPoint(index, quads), 1.0);
		vec3 updir;
		if (index == quads) {
			updir = position.xyz - (gl_ModelViewMatrix * vec4(TrailPoint(index - 1, quads), 1.0)).xyz;
		} else {
			updir = (gl_ModelViewMatrix * vec4(TrailPoint(index + 1, quads), 1.0)).xyz - position.xyz;
		}
		vec3 right = normalize(cross(updir, position.xyz));
		position.xyz += right * side * ringBaseQuadsWidth.z;
		gl_Position = gl_ProjectionMatrix * position;

		texCoord = vec2((side + 1.0) * 0.5, float(index) / float(quads));
		color = ribbonColor;
	}
]]

local gl4FragmentShader = [[
	#version 430 compatibility

	uniform sampler2D ribbonTex;

	in vec2 texCoord;
	in vec4 color;

	void main()
	{
		gl_FragColor = texture2D(ribbonTex, texCoord) * color;
	}
]]

local historyComputeShader = [[
	#version 430

	layout(local_size_x = 64) in;

	layout(std430, binding = 8) writeonly buffer RibbonHistory {
		vec4 history[];
	};

	layout(std430, binding = 9) readonly buffer RibbonWrites {
		vec4 writes[];
	};

	uniform int writeCount;

	void main()
	{
		uint i = gl_GlobalInvocationID.x;
		if (i < uint(writeCount)) {
			history[uint(writes[i].w)] = vec4(writes[i].xyz, 0.0);
		}
	}
]]

local function DeleteGL4Renderer()
	local buffers = {ribbonVAO, ribbonVertices, ribbonIndices, instanceVBO, historyVBO, writesVBO}
	for i = 1, 6 do
		if buffers[i] then
			buffers[i]:Delete()
		end
	end
	if gl4Shader then
		gl.DeleteShader(gl4Shader)
	end
	if historyShader then
		gl.DeleteShader(historyShader)
	end
	gl4Shader, historyShader = nil, nil
	ribbonVAO, ribbonVertices, ribbonIndices = nil, nil, nil
	instanceVBO, historyVBO, writesVBO = nil, nil, nil
end

local function CreateGL4Renderer()
	if not (Platform.glHaveGL4 and gl.DispatchCompute and gl.GetVAO and gl.GetVBO) then
		return
	end

	gl4Shader = gl.CreateShader({
		vertex = gl4VertexShader,
		fragment = gl4FragmentShader,
		uniformInt = {
			ribbonTex = 0,
		},
	})
	historyShader = gl.CreateShader({compute = historyComputeShader})
	ribbonVertices = gl.GetVBO(GL.ARRAY_BUFFER, false)
	ribbonIndices = gl.GetVBO(GL.ELEMENT_ARRAY_BUFFER, false)
	if not (gl4Shader and historyShader and ribbonVertices and ribbonIndices) then
		print(PRIO_MAJOR, "LUPS->Ribbon: GL4 renderer not available, using display lists: " .. gl.GetShaderLog())
		DeleteGL4Renderer()
		return
	end
	gl4PausedLoc = gl.GetUniformLocation(gl4Shader, "paused")
	historyWriteCountLoc = gl.GetUniformLocation(historyShader, "writeCount")

	local vertices, indices = {}, {}
	for quad = 0, MAX_POINTS - 2 do
		local v = 8*quad
		vertices[v + 1], vertices[v + 2] = quad + 1, -1
		vertices[v + 3], vertices[v + 4] = quad + 1, 1
		vertices[v + 5], vertices[v + 6] = quad, 1
		vertices[v + 7], vertices[v + 8] = quad, -1
		local i, first = 6*quad, 4*quad
		indices[i + 1], indices[i + 2], indices[i + 3] = first, first + 1, first + 2
		indices[i + 4], indices[i + 5], indices[i + 6] = first, first + 2, first + 3
	end
	ribbonVertices:Define(4*(MAX_POINTS - 1), {{id = 0, name = "pointAndSide", size = 2}})
	ribbonVertices:Upload(vertices)
	ribbonIndices:Define(6*(MAX_POINTS - 1), GL.UNSIGNED_SHORT)
	ribbonIndices:Upload(indices)
end

local function AddToHistory(fx)
	local slot = table.remove(freeSlots)
	if not slot then
		slotCount = slotCount + 1
		slot = slotCount
	end
	historyRibbons[slot] = fx
	fx.historySlot = slot
	fx.historyBase = (slot - 1)*MAX_POINTS
	fx.uploadedPoints = nil
end

local function RemoveFromHistory(fx)
	historyRibbons[fx.historySlot] = nil
	freeSlots[#freeSlots + 1] = fx.historySlot
	fx.historySlot = nil
end

local function StagePoints(fx, first, count)
	local oldPos, size, base = fx.oldPos, fx.size, fx.historyBase
	local j = first
	for _ = 1, count do
		local pos = oldPos[j]
		local w = 4*writeCount
		writes[w + 1], writes[w + 2], writes[w + 3], writes[w + 4] = pos[1], pos[2], pos[3], base + j - 1
		writeCount = writeCount + 1
		j = (j % size) + 1
	end
end

local function UploadHistory()
	if historyCapacity < slotCount then
		if historyVBO then
			historyVBO:Delete()
		end
		historyCapacity = math.max(2*historyCapacity, slotCount)
		historyVBO = gl.GetVBO(GL.SHADER_STORAGE_BUFFER, true)
		historyVBO:Define(historyCapacity*MAX_POINTS, 1)
		for slot = 1, slotCount do
			if historyRibbons[slot] then
				historyRibbons[slot].uploadedPoints = nil
			end
		end
	end

	for i = 1, batchSize do
		local fx = batchRibbons[i]
		local uploaded = fx.uploadedPoints
		if not uploaded then
			StagePoints(fx, 1, fx.size)
		elseif uploaded < fx.writtenPoints then
			local count = math.min(fx.writtenPoints - uploaded, fx.size)
			StagePoints(fx, (fx.posIdx - count) % fx.size + 1, count)
		end
		fx.uploadedPoints = fx.writtenPoints
	end

	if writeCount == 0 then
		return
	end
	if writesCapacity < writeCount then
		if writesVBO then
			writesVBO:Delete()
		end
		writesCapacity = math.max(2*writesCapacity, writeCount)
		writesVBO = gl.GetVBO(GL.SHADER_STORAGE_BUFFER, true)
		writesVBO:Define(writesCapacity, 1)
	end
	writesVBO:Upload(writes, nil, 0, 1, 4*writeCount)
	historyVBO:BindBufferRange(HISTORY_BINDING)
	writesVBO:BindBufferRange(WRITES_BINDING)
	glUseShader(historyShader)
	glUniformInt(historyWriteCountLoc, writeCount)
	gl.DispatchCompute(math.ceil(writeCount/64), 1, 1, GL.SHADER_STORAGE_BARRIER_BIT)
	writesVBO:UnbindBufferRange(WRITES_BINDING)
	historyVBO:UnbindBufferRange(HISTORY_BINDING)
	writeCount = 0
end

local function GetInterpolatedHead(fx)
	if fx.unit then
		local x, y, z = spGetUnitPiecePosDir(fx.unit, fx.piecenum)
		local offset = unitOffsets[fx.unit]
		if offset == nil then
			local ux, uy, uz = spGetUnitViewPosition(fx.unit, true)
			local _, _, _, mx, my, mz = spGetUnitPosition(fx.unit, true)
			offset = uz and mz and {ux - mx, uy - my, uz - mz} or false
			unitOffsets[fx.unit] = offset
		end
		if z and offset then
			return x + offset[1], y + offset[2], z + offset[3]
		end
		return x, y, z
	elseif fx.projectile then
		return spGetProjectilePosition(fx.projectile)
	end
end

local function AddToBatch(fx)
	local texture = fx.texture
	local count = batchCount[texture]
	if not count then
		batchTextures[#batchTextures + 1] = texture
		batchData[texture] = {}
		count = 0
	end

	local x, y, z
	if drawInterpolated and fx.isvalid then
		x, y, z = GetInterpolatedHead(fx)
	end
	if not (x and y and z) then
		local pos = fx.oldPos[fx.posIdx]
		x, y, z = pos[1], pos[2], pos[3]
	end
	local color = fx.color
	local alpha = color[4] or 1
	if fx.blendfactor < 1 then
		alpha = alpha*fx.blendfactor
	end

	local data = batchData[texture]
	local i = INSTANCE_FLOATS*count
	data[i + 1], data[i + 2], data[i + 3], data[i + 4] = x, y, z, fx.posIdx - 1
	data[i + 5], data[i + 6], data[i + 7], data[i + 8] = fx.historyBase, fx.quads0, fx.width, 0
	data[i + 9], data[i + 10], data[i + 11], data[i + 12] = color[1], color[2], color[3], alpha
	batchCount[texture] = count + 1
	batchMaxQuads = math.max(batchMaxQuads, fx.quads0)
	batchSize = batchSize + 1
	batchRibbons[batchSize] = fx
end

local function DrawBatch()
	if batchSize == 0 then
		return
	end

	UploadHistory()
	if instanceCapacity < batchSize then
		if instanceVBO then
			ribbonVAO:Delete()
			instanceVBO:Delete()
		end
		instanceCapacity = math.max(2*instanceCapacity, batchSize)
		instanceVBO = gl.GetVBO(GL.ARRAY_BUFFER, true)
		instanceVBO:Define(instanceCapacity, {
			{id = 1, name = "headAndLatest", size = 4},
			{id = 2, name = "ringBaseQuadsWidth", size = 4},
			{id = 3, name = "ribbonColor", size = 4},
		})
		ribbonVAO = gl.GetVAO()
		ribbonVAO:AttachVertexBuffer(ribbonVertices)
		ribbonVAO:AttachIndexBuffer(ribbonIndices)
		ribbonVAO:AttachInstanceBuffer(instanceVBO)
	end

	glUseShader(gl4Shader)
	glUniformInt(gl4PausedLoc, drawPaused and 1 or 0)
	historyVBO:BindBufferRange(HISTORY_BINDING)
	local first = 0
	for i = 1, #batchTextures do
		local texture = batchTextures[i]
		local count = batchCount[texture]
		if count > 0 then
			instanceVBO:Upload(batchData[texture], nil, first, 1, INSTANCE_FLOATS*count)
			glTexture(0, ":c:" .. texture)
			ribbonVAO:DrawElements(GL.TRIANGLES, 6*batchMaxQuads, 0, count, 0, first)
			batchCount[texture] = 0
			first = first + count
		end
	end
	historyVBO:UnbindBufferRange(HISTORY_BINDING)
	batchMaxQuads = 0
	batchSize = 0
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function Ribbon:BeginDraw()
	glUseShader(RibbonShader)
	glBlending(GL_SRC_ALPHA,GL_ONE)
	if gl4Shader then
		local _, _, paused = Spring.GetGameSpeed()
		drawPaused = paused
		drawInterpolated = not paused and Spring.GetFrameTimeOffset() > 0
		local drawFrame = spGetDrawFrame()
		if drawFrame ~= unitOffsetsFrame then
			unitOffsets = {}
			unitOffsetsFrame = drawFrame
		end
	end
end


function Ribbon:EndDraw()
	if gl4Shader then
		DrawBatch()
	end
	glUseShader(0)
	glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
	glTexture(0,false)
	lastTexture = nil
	glColor(1,1,1,1)
end


function Ribbon:Draw()
	if gl4Shader and self.worldspace then
		AddToBatch(self)
		return
	end
	
	local quads0 = self.quads0
	if self.texture ~= lastTexture then
	glTexture(0,":c:"..self.texture)
	lastTexture = self.texture
	end
	glUniform(widthLoc, self.width )
	glUniformInt(quadsLoc, quads0 )
	
	-- Paused drawing involves a bunch of nonsense because Update() happens, causing the latest position
	-- to be put in the table. However, it looks like units in paused games are drawn in the position
	-- they were in at the start of the previous frame. So the latest position in the table has to be
	-- discarded.
	local _, _, paused = Spring.GetGameSpeed()

	--// insert old pos
	local j = ((self.posIdx==self.size) and 1) or (self.posIdx+1)
	for i = 1,quads0 - (paused and 1 or 0) do
		local dir = self.oldPos[j]
		j = ((j==self.size) and 1) or (j+1)
		glUniform( oldPosUniform[i] , dir[1], dir[2], dir[3] )
	end
	
	if paused then
		local dir = self.oldPos[j]
		local prev = self.oldPos[(j == 1 and self.size) or j - 1]
		glUniform( oldPosUniform[quads0] , (prev[1] + dir[1])/2, (prev[2] + dir[2])/2, (prev[3] + dir[3])/2 )
		glUniform( oldPosUniform[quads0 + 1] , dir[1], dir[2], dir[3] )
	else
		--// insert interpolated current unit pos
		if (self.isvalid) then
			--local x,y,z = GetPiecePos(self.unit,self.piecenum)
			local x,y,z
			if Spring.GetFrameTimeOffset() > 0 then
				if self.unit then
					x,y,z = spGetUnitPiecePosDir(self.unit,self.piecenum)
					local ux, uy, uz = Spring.GetUnitViewPosition(self.unit, true)
					local _, _, _, mx, my, mz = Spring.GetUnitPosition(self.unit, true)
					if z and uz and mz then
						x = x + (ux - mx)
						y = y + (uy - my)
						z = z + (uz - mz)
					end
				elseif self.projectile then
					x,y,z = spGetProjectilePosition(self.projectile)
				end
			end
			if x and y and z then
				glUniform( oldPosUniform[quads0+1] , x,y,z )
			else
				local dir = self.oldPos[j]
				glUniform( oldPosUniform[quads0+1] , dir[1], dir[2], dir[3] )
			end
		else
			local dir = self.oldPos[j]
			glUniform( oldPosUniform[quads0+1] , dir[1], dir[2], dir[3] )
		end
	end


	--// define color and add speed blending (don't show ribbon for slow/landing units!)
	if (self.blendfactor<1) then
		local clr = self.color
		glColor(clr[1],clr[2],clr[3],clr[4]*self.blendfactor)
	else
		glColor(self.color)
	end
	glCallList(DLists[quads0])
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function Ribbon.Initialize()
	RibbonShader = gl.CreateShader({
		vertex = [[
			uniform float width;
			uniform int   quads;
			uniform vec3  oldPos[256];

			varying vec2 texCoord;

			void main()
			{
				 vec3 updir,right;
				 vec3 vertex = oldPos[int(gl_MultiTexCoord0.w)];
				 gl_Position = gl_ModelViewMatrix * vec4(vertex,1.0);

				 vec3 vertex2,pos2;
				 if (int(gl_MultiTexCoord0.w) == quads) {
					 vertex2 = oldPos[int(gl_MultiTexCoord0.w)-1];
					 pos2   = (gl_ModelViewMatrix * vec4(vertex2,1.0)).xyz;
					 updir = gl_Position.xyz - pos2.xyz;
				 }else{
					 vertex2 = oldPos[int(gl_MultiTexCoord0.w)+1];
					 pos2   = (gl_ModelViewMatrix * vec4(vertex2,1.0)).xyz;
					 updir = pos2.xyz - gl_Position.xyz;
				 }

				 right = normalize( cross(updir,gl_Position.xyz) );

				 gl_Position.xyz += right * gl_MultiTexCoord0.x * width;
				 gl_Position    = gl_ProjectionMatrix * gl_Position;

				 texCoord      = gl_MultiTexCoord0.pt;
				 gl_FrontColor = gl_Color;
			}
		]],
		fragment = [[
			uniform sampler2D ribbonTex;

			varying vec2 texCoord;

			void main()
			{
				 gl_FragColor = texture2D(ribbonTex, texCoord )*gl_Color;
			}
		]],
		uniformInt={
			ribbonTex = 0,
		},
	})

	if (RibbonShader == nil) then
		print(PRIO_MAJOR,"LUPS->Ribbon: critical shader error: "..gl.GetShaderLog())
		return false
	end

	widthLoc = gl.GetUniformLocation(RibbonShader, 'width')
	quadsLoc = gl.GetUniformLocation(RibbonShader, 'quads')

	for i=1,256 do
		oldPosUniform[i] = gl.GetUniformLocation(RibbonShader,"oldPos["..(i-1).."]")
	end

	CreateGL4Renderer()
end


function Ribbon.Finalize()
	DeleteGL4Renderer()
	if (gl.DeleteShader) then
		gl.DeleteShader(RibbonShader)
	end

	while (next(DLists)) do
		local i,v = next(DLists)
		DLists[i] = nil
		gl.DeleteList(v)
	end
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

function Ribbon:Update(n)
	self.isvalid = (self.unit and spGetUnitIsDead(self.unit) == false) or (self.projectile and Spring.GetProjectileDefID(self.projectile))
	if (self.isvalid) then
		local x,y,z
		if self.unit then
			x, y, z = spGetUnitPiecePosDir(self.unit, self.piecenum)
		elseif self.projectile then
			x, y, z = spGetProjectilePosition(self.projectile)
		end
		if x and y and z then
			self.posIdx = (self.posIdx % self.size)+1
			self.oldPos[self.posIdx] = {x, y, z}
			self.writtenPoints = self.writtenPoints + 1

			local vx, vy, vz
			if self.unit then
				vx, vy, vz = spGetUnitVelocity(self.unit)
			elseif self.projectile then
				vx, vy, vz = spGetProjectileVelocity(self.projectile)
			end
			if vx and vy and vz then
				self.blendfactor = (vx*vx+vy*vy+vz*vz)/30
			end
		end
	else
		local lastIndex = self.posIdx
		self.posIdx = (self.posIdx % self.size)+1
		self.oldPos[self.posIdx] = self.oldPos[lastIndex]
		self.writtenPoints = self.writtenPoints + 1
		
		self.blendfactor = self.blendfactor - n * self.decayRate
	end
end


function Ribbon:Visible()
	self.isvalid = (self.unit and spGetUnitIsDead(self.unit) == false) or (self.projectile and Spring.GetProjectileDefID(self.projectile))
		
	if self.noIconDraw then
		if not Spring.IsUnitVisible(self.unit, radius, self.noIconDraw) then
			return false
		end
	end
	local pos = self.oldPos[self.posIdx]
	return (self.blendfactor>0) and (spIsSphereInView(pos[1],pos[2],pos[3], self.radius))
end


function Ribbon:Valid()
	return self.isvalid or (self.blendfactor>0)
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local function CreateDList(quads0)
	for i=0,quads0-1 do
		local tex_t      = i/quads0
		local tex_t_next = (i+1)/quads0

		gl.TexCoord(-1,tex_t_next,0,i+1)
		gl.Vertex(0,0,0)
		gl.TexCoord(1,tex_t_next,1,i+1)
		gl.Vertex(0,0,0)
		gl.TexCoord(1,tex_t,1,i)
		gl.Vertex(0,0,0)
		gl.TexCoord(-1,tex_t,0,i)
		gl.Vertex(0,0,0)
	end
end


-- used if repeatEffect=true;
function Ribbon:ReInitialize()
	self.dieGameFrame = self.dieGameFrame + self.life
end


function Ribbon:CreateParticle()
	if (self.size>256) then self.size=256
	elseif (self.size<2) then self.size=2 end

	self.posIdx = 1
	self.writtenPoints = 0
	self.quads0 = self.size-1
	self.blendfactor = 1

	local x,y,z
	if self.unit then
		x,y,z = spGetUnitPiecePosDir(self.unit,self.piecenum)
	elseif self.projectile then
		x,y,z = spGetProjectilePosition(self.projectile)
	end
	local curpos = {x,y,z}

	self.oldPos = {}
	for i=1,self.size do
		self.oldPos[i] = curpos
	end

	local udid  = self.unit and spGetUnitDefID(self.unit)
	local weapon = self.weapon
	local speed = self.speed or (UnitDefs[udid] and UnitDefs[udid].speed) or (weapon and WeaponDefs[weapon] and WeaponDefs[weapon].projectilespeed*30) or 100
	self.radius = (speed/30.0)*self.size

	if (not DLists[self.quads0]) then
		DLists[self.quads0] = gl.CreateList(gl.BeginEnd,GL.QUADS,CreateDList,self.quads0)
	end

	self.startGameFrame = thisGameFrame
	self.dieGameFrame   = self.startGameFrame + self.life
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

local MergeTable   = MergeTable
local setmetatable = setmetatable

function Ribbon.Create(Options)
	local newObject = MergeTable(Options, Ribbon.Default)
	setmetatable(newObject,Ribbon)  -- make handle lookup
	newObject:CreateParticle()
	if gl4Shader and newObject.worldspace then
		AddToHistory(newObject)
	end
	return newObject
end

function Ribbon:Destroy()
	if self.historySlot then
		RemoveFromHistory(self)
	end
end

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

return Ribbon
