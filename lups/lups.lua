-- $Id: lups.lua 4099 2009-03-16 05:18:45Z jk $
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--
--  file:    api_gfx_lups.lua
--  brief:   Lua Particle System
--  authors: jK
--  last updated: Jan. 2008
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------


local function GetInfo()
	return {
		name      = "Lups",
		desc      = "Lua Particle System",
		author    = "jK",
		date      = "2008-2014",
		license   = "GNU GPL, v2 or later",
		layer     = 1000,
		api       = true,
		enabled   = true
	}
end


--// FIXME
-- 1. add los handling (inRadar,alwaysVisible, etc.)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// Error Log Handling

PRIO_MAJOR = 0
PRIO_ERROR = 1
PRIO_LESS  = 2

local errorLog = {}
local printErrorsAbove = PRIO_MAJOR
function print(priority,...)
	local errorMsg = ""
	for i=1,select('#',...) do
		errorMsg = errorMsg .. select(i,...)
	end
	errorLog[#errorLog+1] = {priority=priority,message=errorMsg}

	if (priority<=printErrorsAbove) then
		Spring.Echo(...)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// locals

local push = table.insert
local pop  = table.remove
local StrToLower = string.lower

local pairs  = pairs
local ipairs = ipairs
local next   = next

local spGetUnitRadius         = Spring.GetUnitRadius
local spIsUnitVisible         = Spring.IsUnitVisible
local spIsSphereInView        = Spring.IsSphereInView
local spGetUnitLosState       = Spring.GetUnitLosState
local spGetUnitViewPosition   = Spring.GetUnitViewPosition
local spGetUnitDirection      = Spring.GetUnitDirection
local spGetHeadingFromVector  = Spring.GetHeadingFromVector
local spGetUnitIsActive       = Spring.GetUnitIsActive
local spGetUnitRulesParam     = Spring.GetUnitRulesParam
local spGetGameFrame          = Spring.GetGameFrame
local spGetFrameTimeOffset    = Spring.GetFrameTimeOffset
local spGetUnitPieceList      = Spring.GetUnitPieceList
local spGetSpectatingState    = Spring.GetSpectatingState
local spGetLocalAllyTeamID    = Spring.GetLocalAllyTeamID
local scGetReadAllyTeam       = Script.GetReadAllyTeam
local spGetUnitPieceMap       = Spring.GetUnitPieceMap
local spValidUnitID           = Spring.ValidUnitID
local spGetUnitIsStunned      = Spring.GetUnitIsStunned
local spGetProjectilePosition = Spring.GetProjectilePosition

local GetMovetypeUnitDefID    = Spring.Utilities.GetMovetypeUnitDefID

local glUnitPieceMatrix = gl.UnitPieceMatrix
local glPushMatrix      = gl.PushMatrix
local glPopMatrix       = gl.PopMatrix
local glTranslate       = gl.Translate
local glRotate          = gl.Rotate
local glScale           = gl.Scale
local glBlending        = gl.Blending
local glAlphaTest       = gl.AlphaTest
local glDepthTest       = gl.DepthTest
local glDepthMask       = gl.DepthMask
local glUnitMultMatrix  = gl.UnitMultMatrix
local glUnitPieceMultMatrix = gl.UnitPieceMultMatrix

local GL_GREATER = GL.GREATER
local GL_ONE     = GL.ONE
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

local isWidget = (widgetHandler and true) or false

-- Off-screen effects of the classes below can skip their per-frame Update and catch up on the
-- frames they missed (at most MAX_CATCHUP_FRAMES) when they become visible again. This saves the
-- update cost of every off-screen effect, but it is not exact: an effect that comes back on screen
-- after more than MAX_CATCHUP_FRAMES frames shows a different animation phase/size, a repeating
-- effect may show the phase it would have had without its restart, and the overdrive glow
-- re-blends towards its current strength over about a second instead of already being there.
-- Ribbons (trail history) and nano particles (spawn logic) need every frame and are never deferred.
local DEFER_OFFSCREEN_UPDATES = false
local MAX_CATCHUP_FRAMES = 90
local waterPassesEnabled = true -- reflection/refraction callins kept (see Initialize)
local deferrableClass = {bursts = true, staticparticles = true, overdriveparticles = true, shieldsphere = true}
-- The visibility pass is skipped on drawn frames where nothing it depends on changed: no new sim
-- frame, same camera, same viewing ally team, and no effects added since the last pass.
local lastVisFrame, lastVisAllyTeam, lastCamX, lastCamY, lastCamZ, lastCamDX, lastCamDY, lastCamDZ = -1
local visDirty = true
-- Per-unit coarse view test, shared by all unit-space effects of a unit within one visibility
-- pass. The margin covers the largest unit-attached effects (shield spheres, long jets).
local COARSE_VIEW_MARGIN = 800
local unitNearView = {}

-- Incremented once per Update: a per-drawn-frame stamp for caches shared by the draw passes
-- of one frame (reflection, world). Particle classes read LupsDrawStamp.
LupsDrawStamp = 0
-- Incremented per visibility pass: stamp for per-pass caches.
local passStamp = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// hardware capabilities
local GL_VENDOR   = 0x1F00
local GL_RENDERER = 0x1F01
local GL_VERSION  = 0x1F02

local glVendor   = gl.GetString(GL_VENDOR)
local glRenderer = (gl.GetString(GL_RENDERER)):lower()

isNvidia  = (glVendor:find("NVIDIA"))
isATI     = (glVendor:find("ATI "))
isMS      = (glVendor:find("Microsoft"))
isIntel   = (glVendor:find("Intel"))
canCTT    = (gl.CopyToTexture    ~= nil)
canFBO    = (gl.DeleteTextureFBO ~= nil)
canRTT    = (gl.RenderToTexture  ~= nil)
canShader = (gl.CreateShader     ~= nil)
canDistortions = false --// check Initialize()

hardDisableDistortion = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// widget/gadget handling
local handler = (widget and widgetHandler)or(gadgetHandler)
local GG      = (widget and WG)or(GG)
local VFSMODE = (widget and VFS.RAW_FIRST)or(VFS.ZIP_ONLY)

--// locations
local LUPS_LOCATION    = 'lups/'
local PCLASSES_DIRNAME = LUPS_LOCATION .. 'ParticleClasses/'
local HEADERS_DIRNAME  = LUPS_LOCATION .. 'headers/'

--// helpers
VFS.Include(LUPS_LOCATION .. 'loadconfig.lua',nil,VFSMODE)

--// load some headers
VFS.Include(HEADERS_DIRNAME .. 'general.lua',nil,VFSMODE)
VFS.Include(HEADERS_DIRNAME .. 'mathenv.lua',nil,VFSMODE)
VFS.Include(HEADERS_DIRNAME .. 'figures.lua',nil,VFSMODE)
VFS.Include(HEADERS_DIRNAME .. 'vectors.lua',nil,VFSMODE)
VFS.Include(HEADERS_DIRNAME .. 'hsl.lua',nil,VFSMODE)
VFS.Include(HEADERS_DIRNAME .. 'nanoupdate.lua',nil,VFSMODE)

--// load binary insert library
VFS.Include(HEADERS_DIRNAME .. 'tablebin.lua')
local flayer_comp = function( partA,partB )
	return ( partA==partB )or
				 ( (partA.layer==partB.layer)and((partA.unit or -1)<(partB.unit or -1)) )or
				 ( partA.layer<partB.layer )
end

--// workaround for broken UnitDraw() callin
local nilDispList


--// global function (fx classes can use it) for easier access to Lups.cfg
function GetLupsSetting(key, default)
	local value = LupsConfig[key]
	if (value~=nil) then
		return value
	else
		return default
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// some global vars (so the effects can use them)
vsx, vsy, vpx, vpy = Spring.Orig.GetViewGeometry() --// screen pos & view pos (view pos only unequal zero if dualscreen+minimapOnTheLeft)
LocalAllyTeamID = 0
thisGameFrame   = 0
frameOffset     = 0
LupsConfig      = {}

local noDrawUnits = {}
function SetUnitLuaDraw(unitID,nodraw)
	if (nodraw) then
		noDrawUnits[unitID] = (noDrawUnits[unitID] or 0) + 1
		if (noDrawUnits[unitID]==1) then
			Spring.UnitRendering.ActivateMaterial(unitID,1)
			--Spring.UnitRendering.SetLODLength(unitID,1,-1000)
			for pieceID in ipairs(Spring.GetUnitPieceList(unitID) or {}) do
				Spring.UnitRendering.SetPieceList(unitID,1,pieceID,nilDispList)
			end
		end
	else
		noDrawUnits[unitID] = (noDrawUnits[unitID] or 0) - 1
		if (noDrawUnits[unitID]==0) then
			Spring.UnitRendering.DeactivateMaterial(unitID,1)
			noDrawUnits[unitID] = nil
		end
	end
end

local function DrawUnit(_,unitID,drawMode)
--[[
 drawMode:
	notDrawing     = 0,
	normalDraw     = 1,
	shadowDraw     = 2,
	reflectionDraw = 3,
	refractionDraw = 4
--]]

	if (drawMode==1)and(noDrawUnits[unitID]) then
		return true
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local oldVsx,oldVsy = vsx-1,vsy-1

--// load particle classes
local fxClasses = {}
local DistortionClass

local files = VFS.DirList(PCLASSES_DIRNAME, "*.lua",VFSMODE)
for _,filename in ipairs(files) do
	local Class = VFS.Include(filename,nil,VFSMODE)
	if (Class) then
		if (Class.GetInfo) then
			Class.pi = Class.GetInfo()
			local sClassName = string.lower(Class.pi.name)
			-- cached so GameFrame does not lower-case the class name per effect per frame
			Class.pi.deferrable = deferrableClass[sClassName] or false
			if (fxClasses[sClassName]) then
				print(PRIO_LESS,'LUPS: duplicated particle class name "' .. sClassName .. '"')
			else
				fxClasses[sClassName] = Class
			end
		else
			print(PRIO_ERROR,'LUPS: "' .. Class .. '" is missing GetInfo() ')
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// saves all particles
-- An IterableMap version has already had some testing and found to have little
-- effect. Run a benchmark on that old version before reapplying it.
local particles = {}
local particlesCount = 0

local RenderSequence = {}  --// mult-dim table with: [layer][partClass][unitID][fx]
local effectsInDelay = {}  --// fxs which use the delay tag, and waiting for their spawn
local partIDCount = 0  --// increasing ID used to identify the particles

--// Sorted list of the layers the draw loops visit (integers in [-50,50], like the old
--// "for i=-50,50" scans), so a pass does not probe 101 mostly empty layers.
local activeLayers = {}
local activeLayerCount = 0
local knownLayer = {}

local function RegisterLayer(layer)
	if knownLayer[layer] ~= nil then
		return
	end
	if type(layer) ~= "number" or layer ~= math.floor(layer) or layer < -50 or layer > 50 then
		knownLayer[layer] = false
		return
	end
	knownLayer[layer] = true
	local pos = activeLayerCount + 1
	for i = 1, activeLayerCount do
		if activeLayers[i] > layer then
			pos = i
			break
		end
	end
	table.insert(activeLayers, pos, layer)
	activeLayerCount = activeLayerCount + 1
end

--[[
local function DebugPieces(unit,piecenum,level)
	local piece = Spring.GetUnitPieceInfo(unit,piecenum)
	Spring.Echo( string.rep(" ", level) .. "->" .. piece.name .. " (" .. piecenum .. ")")
	for _,pieceChildName in ipairs(piece.children) do
		local pieceNum = spGetUnitPieceMap(unit)[pieceChildName]
		DebugPieces(unit,pieceNum,level+1)
	end
end
--]]


--// the id param is internal don't use it!
function AddParticles(Class,Options   ,__id)
	if (not Options) then
		print(PRIO_LESS,'LUPS->AddFX: no options given');
		return -1;
	end

	if Options.quality and Options.quality > GetLupsSetting("quality", 3) then
		return -1;
	end

	if Options.disable_with_gl4 and GG.widget_enabled_deferred_rendering_gl4 then
		return -1
	end

	if (Options.delay and Options.delay~=0) then
		partIDCount = partIDCount+1
		newOptions = {}; CopyTable(newOptions,Options); newOptions.delay=nil
		effectsInDelay[#effectsInDelay+1] = {frame=thisGameFrame+Options.delay, class=Class, options=newOptions, id=partIDCount};
		return partIDCount
	end

	Class = StrToLower(Class)
	local particleClass = fxClasses[Class]

	if (not particleClass) then
		print(PRIO_LESS,'LUPS->AddFX: couldn\'t find a particle class named "' .. Class .. '"');
		return -1;
	end

	if (Options.unit)and(not spValidUnitID(Options.unit)) then
		print(PRIO_LESS,'LUPS->AddFX: unit is already dead/invalid "' .. Class .. '"');
		return -1;
	end

	--// piecename to piecenum conversion (spring >=76b1 only!)
	if (Options.unit and Options.piece) then
		local pieceMap = spGetUnitPieceMap(Options.unit)
		Options.piecenum = pieceMap and pieceMap[Options.piece] --added check. switching spectator view can cause "attempt to index a nil value"
		if (not Options.piecenum) then
			local udid = Spring.GetUnitDefID(Options.unit)
			if (not udid) then
				print(PRIO_LESS,"LUPS->AddFX:wrong unitID")
			else
				print(PRIO_ERROR,"LUPS->AddFX:wrong unitpiece " .. Options.piece .. "(" .. UnitDefs[udid].name .. ")")
			end
			return -1;
		end
	end

	--Spring.Echo("-------------")
	--DebugPieces(Options.unit,1,0)


	local newParticles,reusedFxID = particleClass.Create(Options)
	if (newParticles) then
		particlesCount = particlesCount + 1
		if (__id) then
			newParticles.id = __id
		else
			partIDCount = partIDCount+1
			newParticles.id = partIDCount
		end
		particles[ newParticles.id ] = newParticles
		visDirty = true

		local space = ((not newParticles.worldspace) and newParticles.unit) or (-1)
		local fxTable = CreateSubTables(RenderSequence,{newParticles.layer,particleClass,space})
		newParticles.fxTable = fxTable
		fxTable[#fxTable+1] = newParticles
		local layer = newParticles.layer
		if layer ~= nil and not knownLayer[layer] then
			RegisterLayer(layer)
		end

		return newParticles.id;
	else
		if (reusedFxID) then
			return reusedFxID;
		else
			if (newParticles~=false) then
				print(PRIO_LESS,"LUPS->AddFX:FX creation failed");
			end
			return -1;
		end
	end
end


function AddParticlesArray(array)
	local class = ""
	for i=1,#array do
		local fxSettings = array[i]
		class = fxSettings.class
		fxSettings.class = nil
		AddParticles(class,fxSettings)
	end
end

function GetParticles(particlesID)
	return particles[particlesID]
end

function RemoveParticles(particlesID)
	local fx = particles[particlesID]
	if (fx) then
		local fxTable = fx.fxTable
		if (type(fxTable)=="table") then
			-- ids are unique within a render list: stop at the match instead of scanning on
			-- (nano spray lists hold hundreds of effects). table.remove keeps the draw order.
			for j = 1, #fxTable do
				if (fxTable[j].id == particlesID) then
					pop(fxTable, j)
					break
				end
			end
		end
		fx:Destroy()
		particles[particlesID] = nil
		particlesCount = particlesCount-1;
		return
	else
		local status,err = pcall(function()
--//FIXME
			for i=1,#effectsInDelay do
				if (effectsInDelay[i].id==particlesID) then
					table.remove(effectsInDelay,i)
					return
				end
			end
--//
		end)

		if (not status) then
			Spring.Echo("Error (Lups) - "..(#effectsInDelay).." :"..err)
			for i=1,#effectsInDelay do
				Spring.Echo("->",effectsInDelay[i],type(effectsInDelay[i]))
			end
			effectsInDelay = {}
		end
	end
end

function GetStats()
	local count   = particlesCount
	local effects = {}
	local layers  = 0

	for i=-50,50 do
		if (RenderSequence[i]) then
			local layer = RenderSequence[i];

			if (next(layer or {})) then layers=layers+1 end

			for partClass,Units in pairs(layer) do
				if (not effects[partClass.pi.name]) then
					effects[partClass.pi.name] = {0,0} --//[1]:=fx count  [2]:=part count
				end
				for unitID,UnitEffects in pairs(Units) do
					for _,fx in pairs(UnitEffects) do
						effects[partClass.pi.name][1] = effects[partClass.pi.name][1] + 1
						effects[partClass.pi.name][2] = effects[partClass.pi.name][2] + (fx.count or 0)
						--count = count+1
					end
				end
			end
		end
	end

	return count,layers,effects
end


function HasParticleClass(ClassName)
	local Class = StrToLower(ClassName)
	return (fxClasses[Class] and true)or(false)
end


function GetErrorLog(minPriority)
	if (minPriority) then
		local log = ""
		for i=1,#errorLog do
			if (errorLog[i].priority<=minPriority) then
				log = log .. errorLog[i].message .. "\n"
			end
		end
		if (log~="") then
			local sysinfo = "Vendor:" .. glVendor ..
											"\nRenderer:" .. glRenderer ..
											(((isATI)and("\nisATI: true"))or("")) ..
											(((isMS)and("\nisMS: true"))or("")) ..
											(((isIntel)and("\nisIntel: true"))or("")) ..
											"\ncanFBO:" .. tostring(canFBO) ..
											"\ncanRTT:" .. tostring(canRTT) ..
											"\ncanCTT:" .. tostring(canCTT) ..
											"\ncanShader:" .. tostring(canShader) .. "\n"
			log = sysinfo..log
		end
		return log
	else
		if (errorlog~="") then
			local sysinfo = "Vendor:" .. glVendor ..
											"\nRenderer:" .. glRenderer ..
											"\nisATI:" .. tostring(isATI) ..
											"\nisMS:" .. tostring(isMS) ..
											"\nisIntel:" .. tostring(isIntel) ..
											"\ncanFBO:" .. tostring(canFBO) ..
											"\ncanRTT:" .. tostring(canRTT) ..
											"\ncanCTT:" .. tostring(canCTT) ..
											"\ncanShader:" .. tostring(canShader) .. "\n"
			return sysinfo..errorLog
		else
			return errorLog
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local anyFXVisible = false
local anyWaterFXVisible = false
local anyDistortionsVisible = false

local function IsUnitPositionKnown(unitID)
	if LocalAllyTeamID < 0 then
		return true
	end
	local targetVisiblityState = Spring.GetUnitLosState(unitID, LocalAllyTeamID, true)
	if not targetVisiblityState then
		return false
	end
	local inLos = (targetVisiblityState == 15)
	if inLos then
		return true
	end
	local identified = (targetVisiblityState > 2)
	
	if not identified then
		return false
	end
	local unitDefID = Spring.GetUnitDefID(unitID)
	if not (unitDefID) then
		return false
	end
	return not GetMovetypeUnitDefID(unitDefID)
end

local function RadarDotCheck(unitID)
	return true
end

-- Draw passes. Unit render lists none of whose effects is drawn in this pass do not enter
-- unit space (a balanced Push/UnitMultMatrix/Pop changes no GL state, but used to be done for
-- every unit with effects on the map, on screen or not, in every pass). World-space effects of
-- classes whose Draw leaves the matrix untouched (Class.drawIsMatrixNeutral) skip the
-- surrounding PushMatrix/PopMatrix pair.
local PASS_STRINGS = {}
local function PassStrings(extension)
	local s = PASS_STRINGS[extension]
	if not s then
		s = {"BeginDraw"..extension, "Draw"..extension, "EndDraw"..extension}
		PASS_STRINGS[extension] = s
	end
	return s
end

-- The gadget's unit-position check, cached per drawn frame (LOS only changes in sim frames).
local posKnownStamp = {}
local posKnownValue = {}
local function IsUnitPositionKnownCached(unitID)
	if LocalAllyTeamID < 0 then
		return true
	end
	if posKnownStamp[unitID] == LupsDrawStamp then
		return posKnownValue[unitID]
	end
	local known = IsUnitPositionKnown(unitID)
	posKnownStamp[unitID] = LupsDrawStamp
	posKnownValue[unitID] = known
	return known
end

local function Draw(extension,layer,water,waterPass)
	local FxLayer = RenderSequence[layer];
	if (not FxLayer) then return end

	-- the reflection/refraction passes use the visibility without main view culling
	local visKey = (waterPass and "waterVisible") or "visible"
	local passStrings   = PassStrings(extension)
	local BeginDrawPass = passStrings[1]
	local DrawPass      = passStrings[2]
	local EndDrawPass   = passStrings[3]
	local normalPass    = (extension == "")
	LupsInPushedMatrix = false

	for partClass,Units in pairs(FxLayer) do
		local beginDraw = partClass[BeginDrawPass]
		if (beginDraw) then

			beginDraw()
			local drawfunc = partClass[DrawPass]
			local matrixNeutral = normalPass and partClass.drawIsMatrixNeutral

			if (not next(Units)) then
				FxLayer[partClass]=nil
			else
				for unitID,UnitEffects in pairs(Units) do
					if (not UnitEffects[1]) then
						Units[unitID]=nil
					elseif (unitID>-1) then

						------------------------------------------------------------------------------------
						-- render in unit/piece space, only if something is drawn --------------------------
						------------------------------------------------------------------------------------
						local nfx = #UnitEffects
						local first
						for i=1,nfx do
							local fx = UnitEffects[i]
							if (fx.alwaysVisible or fx[visKey]) and (not water or not fx.nowater) then
								first = i
								break
							end
						end
						if first then
							glPushMatrix()
							if gadget and not IsUnitPositionKnownCached(unitID) then
								local x, y, z = Spring.GetUnitPosition(unitID)
								local a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, a41, a42, a43, a44 = Spring.GetUnitTransformMatrix(unitID)
								if a11 then
									gl.MultMatrix(a11, a12, a13, a14, a21, a22, a23, a24, a31, a32, a33, a34, x, y, z , a44)
								else
									glUnitMultMatrix(unitID)
								end
							else
								glUnitMultMatrix(unitID)
							end

							--// render effects
							for i=first,nfx do
								local fx = UnitEffects[i]
								if (fx.alwaysVisible or fx[visKey]) and (not water or not fx.nowater) then
									if (fx.piecenum) then
										--// enter piece space
										glPushMatrix()
											glUnitPieceMultMatrix(unitID,fx.piecenum)
											glScale(1,1,-1)
											-- the matrix is restored right after: classes may skip their own Push/Pop
											LupsInPushedMatrix = true
											drawfunc(fx)
											LupsInPushedMatrix = false
										glPopMatrix()
										--// leave piece space
									else
										fx[DrawPass](fx)
									end
								end
							end

							--// leave unit space
							glPopMatrix()
						end

					else

						------------------------------------------------------------------------------------
						-- render in world space -----------------------------------------------------------
						------------------------------------------------------------------------------------
						for i=1,#UnitEffects do
							local fx = UnitEffects[i]
							if (fx.alwaysVisible or fx[visKey]) and (not water or not fx.nowater) then
								if fx.projectile and not fx.worldspace then
									glPushMatrix()
									local x,y,z = spGetProjectilePosition(fx.projectile)
									glTranslate(x,y,z)
									drawfunc(fx)
									glPopMatrix()
								elseif matrixNeutral then
									drawfunc(fx)
								else
									glPushMatrix()
									drawfunc(fx)
									glPopMatrix()
								end
							end
						end -- for
					end -- if
				end  --for
			end

			partClass[EndDrawPass]()

		end
	end
end

local function DrawDistortionLayers()
	glBlending(GL_ONE,GL_ONE)

	for li=1,activeLayerCount do
		Draw("Distortion",activeLayers[li])
	end

	glBlending(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
end

local function DrawParticlesOpaque()
	if ( not anyFXVisible ) then return end

	vsx, vsy, vpx, vpy = Spring.Orig.GetViewGeometry()
	if (vsx~=oldVsx)or(vsy~=oldVsy) then
		for _,partClass in pairs(fxClasses) do
			if partClass and partClass.ViewResize then
				partClass.ViewResize(vsx, vsy)
			end
		end
		oldVsx, oldVsy = vsx, vsy
	end

	glDepthTest(true)
	glDepthMask(true)
	for li=1,activeLayerCount do
		Draw("Opaque",activeLayers[li])
	end
	glDepthMask(false)
	glDepthTest(false)
end

local function DrawParticles()
	if ( not anyFXVisible ) then return end

	glDepthTest(true)

	--// Draw() (layers: -50 upto 0)
	glAlphaTest(GL_GREATER, 0)
	for li=1,activeLayerCount do
		local layer = activeLayers[li]
		if layer > 0 then break end
		Draw("",layer)
	end
	glAlphaTest(false)

	--// DrawDistortion()
	if (anyDistortionsVisible)and(DistortionClass) then
		DistortionClass.BeginDraw()
		gl.ActiveFBO(DistortionClass.fbo,DrawDistortionLayers)
		DistortionClass.EndDraw()
	end

	--// Draw() (layers: 1 upto 50)
	glAlphaTest(GL_GREATER, 0)
	for li=1,activeLayerCount do
		local layer = activeLayers[li]
		if layer > 0 then
			Draw("",layer)
		end
	end

	glAlphaTest(false)
	glDepthTest(false)
end


local function DrawParticlesWater()
	if ( not anyWaterFXVisible ) then return end

	glDepthTest(true)

	--// DrawOpaque()
	glDepthMask(true)
	for li=1,activeLayerCount do
		Draw("Opaque",activeLayers[li],nil,true)
	end
	glDepthMask(false)

	--// Draw() (layers: -50 upto 50)
	glAlphaTest(GL_GREATER, 0)
	for li=1,activeLayerCount do
		Draw("",activeLayers[li],true,true)
	end
	glAlphaTest(false)
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit activity
local activeUnit = {}
local activeUnitCheckTime = {}
local ACTIVE_CHECK_PERIOD = 10

local function GetUnitIsActive(unitID)
	if activeUnitCheckTime[unitID] and activeUnitCheckTime[unitID] > thisGameFrame then
		return activeUnit[unitID]
	end
	
	activeUnitCheckTime[unitID] = thisGameFrame + ACTIVE_CHECK_PERIOD
	activeUnit[unitID] = (spGetUnitIsActive(unitID) or spGetUnitRulesParam(unitID, "unitActiveOverride") == 1)
		and	(spGetUnitRulesParam(unitID, "disarmed") ~= 1)
		and	(spGetUnitRulesParam(unitID, "att_shieldDisabled") ~= 1)
		and (spGetUnitRulesParam(unitID, "morphDisable") ~= 1)
		and not spGetUnitIsStunned(unitID)
	
	return activeUnit[unitID]
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawWorldPreUnitVisibleFx
local DrawWorldVisibleFx
local DrawWorldReflectionVisibleFx
local DrawWorldRefractionVisibleFx
local DrawWorldShadowVisibleFx
local DrawScreenEffectsVisibleFx
local DrawInMiniMapVisibleFx

local function UpdateAllyTeamStatus()
	local spec, specFullView = spGetSpectatingState()
	if (specFullView) then
		LocalAllyTeamID = scGetReadAllyTeam() or 0
	else
		LocalAllyTeamID = spGetLocalAllyTeamID() or 0
	end
end

function IsPosInLos(x,y,z)
	if LocalAllyTeamID == 0 then
		UpdateAllyTeamStatus()
	end
	return LocalAllyTeamID == Script.ALL_ACCESS_TEAM or (LocalAllyTeamID ~= Script.NO_ACCESS_TEAM and Spring.IsPosInLos(x,y,z, LocalAllyTeamID))
end

function IsPosInRadar(x,y,z)
	if LocalAllyTeamID == 0 then
		UpdateAllyTeamStatus()
	end
	return LocalAllyTeamID == Script.ALL_ACCESS_TEAM or (LocalAllyTeamID ~= Script.NO_ACCESS_TEAM and Spring.IsPosInRadar(x,y,z, LocalAllyTeamID))
end

function IsPosInAirLos(x,y,z)
	if LocalAllyTeamID == 0 then
		UpdateAllyTeamStatus()
	end
	return LocalAllyTeamID == Script.ALL_ACCESS_TEAM or (LocalAllyTeamID ~= Script.NO_ACCESS_TEAM and Spring.IsPosInAirLos(x,y,z, LocalAllyTeamID))
end

local function GetUnitLosStateRaw(unitID)
	if LocalAllyTeamID == 0 then
		UpdateAllyTeamStatus()
	end
	return LocalAllyTeamID == Script.ALL_ACCESS_TEAM or (LocalAllyTeamID ~= Script.NO_ACCESS_TEAM and (Spring.GetUnitLosState(unitID, LocalAllyTeamID) or {}).los) or false
end

--// Per-visibility-pass caches of per-unit engine queries. Several effects of one unit ask the
--// same questions within a pass, and nothing they depend on changes inside a pass. Outside a
--// pass (inVisPass false) the queries go straight to the engine.
local inVisPass = false
local losStamp, losValue = {}, {}
local radStamp, radValue = {}, {}
local vposStamp, vposX, vposY, vposZ = {}, {}, {}, {}

function GetUnitLosState(unitID)
	if not inVisPass then
		return GetUnitLosStateRaw(unitID)
	end
	if losStamp[unitID] == passStamp then
		return losValue[unitID]
	end
	local v = GetUnitLosStateRaw(unitID)
	losStamp[unitID] = passStamp
	losValue[unitID] = v
	return v
end

local function UnitRadiusCached(unitID)
	if not inVisPass then
		return spGetUnitRadius(unitID)
	end
	if radStamp[unitID] == passStamp then
		return radValue[unitID]
	end
	local r = spGetUnitRadius(unitID)
	radStamp[unitID] = passStamp
	radValue[unitID] = r
	return r
end

local function UnitViewPositionCached(unitID)
	if not inVisPass then
		return spGetUnitViewPosition(unitID)
	end
	if vposStamp[unitID] == passStamp then
		return vposX[unitID], vposY[unitID], vposZ[unitID]
	end
	local x, y, z = spGetUnitViewPosition(unitID)
	vposStamp[unitID] = passStamp
	vposX[unitID], vposY[unitID], vposZ[unitID] = x, y, z
	return x, y, z
end

-- for particle classes' Visible()
LupsGetUnitRadius = UnitRadiusCached
LupsGetUnitViewPosition = UnitViewPositionCached

local sqrt = math.sqrt

-- Generous bounding radius of an effect around its unit-space origin.
local function FxExtent(fx)
	local r = 0
	local v = fx.radius
	if type(v) == "number" and v > r then r = v end
	v = fx.size
	if type(v) == "number" and v > r then r = v end
	v = fx.length
	if type(v) == "number" and v > r then r = v end
	local g, f = fx.sphereGrowth, fx.frame
	if type(g) == "number" and type(f) == "number" and g > 0 and f > 0 then
		r = r + g*f
	end
	g, f = fx.uMovCoeff, fx.maxSpeed
	if type(g) == "number" and type(f) == "number" and g > 0 and f > 0 then
		r = r + g*f
	end
	r = 1.1*r
	local p = fx.pos
	if type(p) == "table" then
		local a, b, c = p[1], p[2], p[3]
		if type(a) == "number" and type(b) == "number" and type(c) == "number" then
			r = r + sqrt(a*a + b*b + c*c)
		end
	end
	return r
end

-- Returns the visibility for the main view and for the water passes (reflection, refraction).
local function IsUnitFXVisible(fx)
	local unitActive = true
	local unitID = fx.unit
	if fx.onActive then
		unitActive = GetUnitIsActive(unitID)
	elseif fx.onUnitRulesParam then
		unitActive = (spGetUnitRulesParam(unitID, fx.onUnitRulesParam) == 1)
	end
	--Spring.Utilities.UnitEcho(unitID, "w")
	if (unitActive) then
		if fx.alwaysVisible then
			return true, true
		elseif (isWidget and not fx.noIconDraw) then
			-- The widget used to draw every such effect on the map in every pass, on screen or not.
			-- The main view now culls them by the class Visible() (where it has one) and the unit's
			-- view sphere; the water passes keep drawing all of them, since a mirror image can be
			-- on screen while the effect is not.
			if not fx.worldspace then
				local near = unitNearView[unitID]
				if near == nil then
					near = spIsUnitVisible(unitID, (UnitRadiusCached(unitID) or 0) + COARSE_VIEW_MARGIN, false)
					unitNearView[unitID] = near
				end
				if not near then
					return false, true
				end
			end
			if (fx.Visible) then
				if not fx:Visible() then
					return false, true
				end
				if fx.worldspace then
					-- World-space effects (e.g. nano lasers spanning builder -> target) cull themselves.
					return true, true
				end
			end
			local unitRadius = (UnitRadiusCached(unitID) or 0) + 40
			local r = fx.radius or fx.size or fx.length
			if type(r) ~= "number" then
				r = 0
			end
			return spIsUnitVisible(unitID, unitRadius + r, false), true
		elseif (fx.Visible) then
			local v = fx:Visible()
			if v and fx.cullByUnitSphere and not fx.worldspace then
				-- Shield spheres' Visible() only checks allyteam visibility, so the gadget drew every
				-- shield on the map in every pass. The main view culls them by the unit's sphere; the
				-- water passes keep the old answer.
				local r = (UnitRadiusCached(unitID) or 0) + 40 + FxExtent(fx)
				return spIsUnitVisible(unitID, r, fx.noIconDraw), v
			end
			return v, v
		else
			local unitRadius = (UnitRadiusCached(unitID) or 0) + 40
			local r = fx.radius or 0
			local v = spIsUnitVisible(unitID, unitRadius + r, fx.noIconDraw)
			return v, v
		end
	else
		local a = fx.alwaysVisible
		return a, a
	end
end

local function IsProjectileFXVisible(fx)
	if fx.alwaysVisible then
		return true
	elseif fx.Visible then
		return fx:Visible()
	else
		local proID = fx.projectile
		local x,y,z = Spring.GetProjectilePosition(proID)
		if (IsPosInLos(x,y,z)and (spIsSphereInView(x,y,z,(fx.radius or 200)+100)) ) then
			return true
		end
	end
end

local function IsWorldFXVisible(fx)
	if fx.alwaysVisible then
		return true
	elseif (fx.Visible) then
		return fx:Visible()
	elseif (fx.pos) then
		local pos = fx.pos
		if (IsPosInLos(pos[1],pos[2],pos[3]))and
			(spIsSphereInView(pos[1],pos[2],pos[3],(fx.radius or 200)+100))
		then
			return true
		end
	end
end


local function CreateVisibleFxList()
	local removeFX = {}
	local removeCnt = 1
	unitNearView = {}
	passStamp = (passStamp + 1) % 4194304 -- stays exact with float lua numbers
	inVisPass = true

	for _,fx in pairs(particles) do
		if ((fx.unit or -1) > -1) then
			fx.visible, fx.waterVisible = IsUnitFXVisible(fx)
			if (fx.visible) then
				if (not anyFXVisible) then anyFXVisible = true end
				if (not anyDistortionsVisible) then anyDistortionsVisible = fx.pi.distortion end
			end
			if (fx.waterVisible) then
				anyWaterFXVisible = true
			end
		elseif ((fx.projectile or -1) > -1) then
			fx.visible = IsProjectileFXVisible(fx)
			fx.waterVisible = fx.visible
			if (fx.visible) then
			if (not anyFXVisible) then anyFXVisible = true end
			if (not anyDistortionsVisible) then anyDistortionsVisible = fx.pi.distortion end
			anyWaterFXVisible = true
			end
		else
			fx.visible = IsWorldFXVisible(fx)
			fx.waterVisible = fx.visible
			if (fx.visible) then
				if (not anyFXVisible) then anyFXVisible = true end
				if (not anyDistortionsVisible) then anyDistortionsVisible = fx.pi.distortion end
				anyWaterFXVisible = true
			elseif (fx.Valid and (not fx:Valid())) then
				removeFX[removeCnt] = fx.id
				removeCnt = removeCnt + 1
			end
		end
	end
	--Spring.Echo("Lups fx cnt", particles.GetIndexMax())
	inVisPass = false

	for i=1,removeCnt-1 do
		RemoveParticles(removeFX[i])
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- A unit has render lists in several layers/classes: ask the engine once per unit and call
-- (nothing changes within the call).
local validStamp, validValue = {}, {}
local validCallStamp = 0

local function CleanInvalidUnitFX()
	local removeFX = {}
	local removeCnt = 1
	validCallStamp = (validCallStamp + 1) % 4194304
	local stamp = validCallStamp

	for layerID,layer in pairs(RenderSequence) do
		for partClass,Units in pairs(layer) do
			for unitID,UnitEffects in pairs(Units) do
				if (not UnitEffects[1]) then
					Units[unitID] = nil
				else
					if (unitID>-1) then
						local valid
						if validStamp[unitID] == stamp then
							valid = validValue[unitID]
						else
							valid = spValidUnitID(unitID)
							validStamp[unitID] = stamp
							validValue[unitID] = valid
						end
						if (not valid) then --// UnitID isn't valid anymore, remove all its effects
							for i=1,#UnitEffects do
								local fx = UnitEffects[i]
								removeFX[removeCnt] = fx.id
								removeCnt = removeCnt + 1
							end
							Units[unitID]=nil
						end
					end
				end
			end
		end
	end

	for i=1,removeCnt-1 do
		RemoveParticles(removeFX[i])
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// needed to allow to use RemoveParticles in :Update of the particleclasses
local fxRemoveList = {}
function BufferRemoveParticles(id)
	fxRemoveList[#fxRemoveList+1] = id
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lastGameFrame = 0

local function GameFrame(_,n)
	thisGameFrame = n
	if ((not next(particles)) and (not effectsInDelay[1])) then return end

	--// create delayed FXs
	if (effectsInDelay[1]) then
		local remaingFXs,cnt={},1
		for i=1,#effectsInDelay do
			local fx = effectsInDelay[i]
			if (fx.frame>thisGameFrame) then
				remaingFXs[cnt]=fx
				cnt=cnt+1
			else
				AddParticles(fx.class,fx.options, fx.id)
				if (fx.frame-thisGameFrame>0) then
					particles[fx.id]:Update(fx.frame-thisGameFrame)
				end
			end
		end
		effectsInDelay = remaingFXs
	end

	--// cleanup FX from dead/invalid units
	CleanInvalidUnitFX()

	--// update FXs
	local framesToUpdate = thisGameFrame - lastGameFrame
	for _,partFx in pairs(particles) do
		if (n>=partFx.dieGameFrame) then
			--// lifetime ended
			if (partFx.repeatEffect) then
				if (type(partFx.repeatEffect)=="number") then
					partFx.repeatEffect = partFx.repeatEffect - 1
					if (partFx.repeatEffect==1) then partFx.repeatEffect = nil end
				end
				if (partFx.ReInitialize) then
					partFx:ReInitialize()
				else
					partFx.dieGameFrame = partFx.dieGameFrame + partFx.life
				end
			else
				--// we can't remove items from a table we are iterating atm, so just buffer them and remove them later
				BufferRemoveParticles(partFx.id)
			end
		else
			--// update particles
			if (partFx.Update) then
				local pi = partFx.pi
				if DEFER_OFFSCREEN_UPDATES and not partFx.visible and not (waterPassesEnabled and partFx.waterVisible)
						and pi and pi.deferrable then
					partFx.pendingFrames = (partFx.pendingFrames or 0) + framesToUpdate
				else
					local pending = partFx.pendingFrames
					if pending then
						partFx.pendingFrames = nil
						-- Cap catch-up: some classes loop per frame in Update(n) (e.g. Bursts).
						partFx:Update(math.min(framesToUpdate + pending, MAX_CATCHUP_FRAMES))
					else
						partFx:Update(framesToUpdate)
					end
				end
			end
		end
	end

	--// now we can remove particles
	if (#fxRemoveList>0) then
		for i=1,#fxRemoveList do
			RemoveParticles(fxRemoveList[i])
		end
		fxRemoveList = {}
	end
end

local function Update(_,dt)
	LupsDrawStamp = (LupsDrawStamp + 1) % 4194304 -- stays exact with float lua numbers

	--// update frameoffset and self allyteam
	frameOffset = spGetFrameTimeOffset()
	UpdateAllyTeamStatus()

	--// Game Frame Update
	local x = spGetGameFrame()
	if ((x-lastGameFrame)>=1) then
		GameFrame(nil,x)
		lastGameFrame = x
	end

	--// check which fxs are visible
	-- Visibility only changes when the sim advances (units/effects move), the camera moves or new
	-- effects are added, so skip the full pass on drawn frames where none of that happened.
	local cx, cy, cz = Spring.GetCameraPosition()
	local dx, dy, dz = Spring.GetCameraDirection()
	if (not visDirty) and x == lastVisFrame and LocalAllyTeamID == lastVisAllyTeam
		and cx == lastCamX and cy == lastCamY and cz == lastCamZ
		and dx == lastCamDX and dy == lastCamDY and dz == lastCamDZ then
		return
	end
	visDirty = false
	lastVisFrame, lastVisAllyTeam = x, LocalAllyTeamID
	lastCamX, lastCamY, lastCamZ, lastCamDX, lastCamDY, lastCamDZ = cx, cy, cz, dx, dy, dz
	anyFXVisible = false
	anyWaterFXVisible = false
	anyDistortionsVisible = false
	if (next(particles)) then
		CreateVisibleFxList()
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckParticleClassReq(pi)
	return
		(canShader or (not pi.shader))and
		(canFBO or (not pi.fbo))and
		(canRTT or (not pi.rtt))and
		(canCTT or (not pi.ctt))and
		(canDistortions or (not pi.distortion))and
		((not isIntel) or (pi.intel~=0))and
		((not isMS)  or (pi.ms~=0))
end


local function Initialize()
	LupsConfig = LoadConfig("./lups.cfg")

	--// set verbose level
	local showWarnings = LupsConfig.showwarnings
	if showWarnings then
		local t = type(showWarnings)
		if (t=="number") then
			printErrorsAbove = showWarnings
		elseif (t=="boolean") then
			printErrorsAbove = PRIO_LESS
		end
	end


	--// is distortion is supported?
	DistortionClass = (not hardDisableDistortion) and fxClasses["postdistortion"]
	if DistortionClass then
		fxClasses["postdistortion"]=nil --// remove it from default classes
		local di = DistortionClass.pi
		if (di) and CheckParticleClassReq(di) then
			local fine = true
			if (DistortionClass.Initialize) then fine = DistortionClass.Initialize() end
			if (fine~=nil)and(fine==false) then
				print(PRIO_LESS,'LUPS: disabled Distortions');
				DistortionClass=nil
			end
		else
			print(PRIO_LESS,'LUPS: disabled Distortions');
			DistortionClass=nil
		end
	end
	canDistortions = (DistortionClass~=nil) and not hardDisableDistortion


	--// get list of user disabled fx classes
	local disableFX = {}
	for i,v in pairs(LupsConfig.disablefx or {}) do
		disableFX[i:lower()]=v;
	end
	
	--// Disable lups class if its replacement successfully loads.
	for fxName,fxClass in pairs(fxClasses) do
		local replacement = fxClass.GetInfo().replacement
		if replacement and GG[replacement] and GG[replacement]() then
			disableFX[fxName] = true
		end
	end

	local linkBackupFXClasses = {}

	--// initialize particle classes
	for fxName,fxClass in pairs(fxClasses) do
		local fi = fxClass.pi --// .fi = fxClass.GetInfo()
		if (not disableFX[fxName]) and (fi) and CheckParticleClassReq(fi) then
			local fine = true
			if (fxClass.Initialize) then fine = fxClass.Initialize() end
			if (fine~=nil)and(fine==false) then
				print(PRIO_LESS,'LUPS: "' .. fi.name .. '" FXClass removed (class requested it during initialization)');
				fxClasses[fxName]=nil
				if (fi.backup and fi.backup~="") then
					linkBackupFXClasses[fxName] = fi.backup:lower()
				end
				if (fxClass.Finalize) then fxClass.Finalize() end
			end
		else --// unload particle class (not supported by this computer)
			print(PRIO_LESS,'LUPS: "' .. fi.name .. '" FXClass removed (hardware doesn\'t support it)');
			fxClasses[fxName]=nil
			if (fi.backup and fi.backup~="") then
				linkBackupFXClasses[fxName] = fi.backup:lower()
			end
		end
	end

	if GetLupsSetting("enablerefraction", 0) ~= 1 then
		(gadgetHandler or widgetHandler):RemoveCallIn("DrawWorldRefraction")
	end
	if GetLupsSetting("enablereflection", 0) ~= 1 then
		(gadgetHandler or widgetHandler):RemoveCallIn("DrawWorldReflection")
	end
	waterPassesEnabled = (GetLupsSetting("enablerefraction", 0) == 1) or (GetLupsSetting("enablereflection", 0) == 1)

	--// link backup FXClasses
	for className,backupName in pairs(linkBackupFXClasses) do
		fxClasses[className]=fxClasses[backupName]
	end

	--// link Distortion Class
	fxClasses["postdistortion"]=DistortionClass

	--// update screen geometric
	--ViewResize(_,handler:GetViewSizes())

	--// make global
	GG.Lups = {}
	GG.Lups.GetStats          = GetStats
	GG.Lups.GetErrorLog       = GetErrorLog
	GG.Lups.AddParticles      = AddParticles
	GG.Lups.GetParticles      = GetParticles
	GG.Lups.RemoveParticles   = RemoveParticles
	GG.Lups.AddParticlesArray = AddParticlesArray
	GG.Lups.HasParticleClass  = HasParticleClass
	GG.Lups.IsPosInLos        = IsPosInLos

	for fncname,fnc in pairs(GG.Lups) do
		handler:RegisterGlobal('Lups_'..fncname,fnc)
	end

	GG.Lups.Config = LupsConfig

	nilDispList = gl.CreateList(function() end)
end

local function Shutdown()
	for fncname,fnc in pairs(GG.Lups) do
		handler:DeregisterGlobal('Lups_'..fncname)
	end
	GG.Lups = nil

	for _,fxClass in pairs(fxClasses) do
		if (fxClass.Finalize) then
			fxClass.Finalize()
		end
	end

	gl.DeleteList(nilDispList)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local this = widget or gadget

this.GetInfo    = GetInfo
this.Initialize = Initialize
this.Shutdown   = Shutdown
this.DrawWorldPreUnit    = DrawParticlesOpaque
this.DrawWorld           = DrawParticles
this.DrawWorldReflection = DrawParticlesWater
this.DrawWorldRefraction = DrawParticlesWater
this.ViewResize = ViewResize
this.Update     = Update
if gadget then
	this.DrawUnit = DrawUnit
	--this.GameFrame  = GameFrame; // doesn't work for unsynced parts >yet<
end
