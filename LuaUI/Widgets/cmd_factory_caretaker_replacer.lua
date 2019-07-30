--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Factory Caretaker Replacer",
		desc      = "Replaces factory placement with caretaker when placing near a factory of the same type.",
		author    = "GoogleFrog",
		date      = "20 July 2019",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedup

VFS.Include("LuaRules/Utilities/glVolumes.lua")

local spGetActiveCommand = Spring.GetActiveCommand
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetMouseState    = Spring.GetMouseState
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetGroundHeight  = Spring.GetGroundHeight
local spGetCameraState   = Spring.GetCameraState


local floor = math.floor
local cos = math.cos
local sin = math.sin
local mapX = Game.mapSizeX
local mapZ = Game.mapSizeZ

local glColor               = gl.Color
local glLineWidth           = gl.LineWidth
local glDepthTest           = gl.DepthTest
local glTexture             = gl.Texture
local glDrawCircle          = gl.Utilities.DrawCircle
local glDrawGroundCircle    = gl.DrawGroundCircle
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTranslate           = gl.Translate
local glBillboard           = gl.Billboard
local glText                = gl.Text
local glScale               = gl.Scale
local glRotate              = gl.Rotate
local glLoadIdentity        = gl.LoadIdentity
local glLineStipple         = gl.LineStipple

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local FACTORY_RANGE_SQ = 450^2

local outCircle = {
	range = math.sqrt(FACTORY_RANGE_SQ),
	color = {0.8, 0.8, 0.8, 0.4},
	width = 2.5,
	miniWidth = 1.5,
	circleDivs = 128
}

local inCircle = {
	range = math.sqrt(FACTORY_RANGE_SQ),
	color = {0.1, 1, 0.3, 0.6},
	width = 2.5,
	miniWidth = 1.5,
	circleDivs = 128
}

local oddX = {}
local oddZ = {}
local factoryBuildAction = {}
for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local cp = ud.customParams
	if (ud.isFactory or (cp.isfakefactory and ud.speed == 0)) and not cp.notreallyafactory then
		factoryBuildAction[i] = "buildunit_" .. ud.name
		oddX[i] = (ud.xsize % 4)*4
		oddZ[i] = (ud.zsize % 4)*4
	end
end

local nanoBuildAction = "buildunit_staticcon"
local nanoUnitDefID = UnitDefNames["staticcon"].id
oddX[nanoUnitDefID] = (UnitDefNames["staticcon"].xsize % 4)*4
oddZ[nanoUnitDefID] = (UnitDefNames["staticcon"].zsize % 4)*4

local myPlayerID = Spring.GetLocalPlayerID()
local myTeamID = Spring.GetMyTeamID()

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local factories = IterableMap.New()

local currentFactoryDefID
local closestFactoryData

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DistSq(x1, z1, x2, z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

local function GetClosestFactory(x, z, unitDefID)
	local nearID, nearDistSq, nearData
	for unitID, data in factories.Iterator() do
		if data.unitDefID == unitDefID then
			local dSq = DistSq(x, z, data.x, data.z)
			if (not nearDistSq) or (dSq < nearDistSq) then
				nearID = unitID
				nearDistSq = dSq
				nearData = data
			end
		end
	end
	return nearID, nearDistSq, nearData
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetMousePos()
	local mouseX, mouseY = spGetMouseState()
	local _, mouse = spTraceScreenRay(mouseX, mouseY, true, true)
	if not mouse then
		return
	end
	
	return mouse[1], mouse[3]
end

local function CheckFactoryTransformRange(unitDefID)
	local alt, ctrl = Spring.GetModKeyState()
	if alt and ctrl then
		return
	end
	
	local mx, mz = GetMousePos()
	if not mx then
		return
	end
	
	local unitID, distSq, factoryData = GetClosestFactory(mx, mz, unitDefID)
	if not unitID then
		return
	end
	
	-- Check whether any selected units can build nano turrets.
	-- Nano turrets could be disabled by modoptions or otherwise unavailible.
	local cmdDescID = Spring.GetCmdDescIndex(-nanoUnitDefID)
	if not cmdDescID then
		return
	end
	
	closestFactoryData = factoryData
	if distSq < FACTORY_RANGE_SQ then
		Spring.SetActiveCommand(nanoBuildAction)
	end
	
	currentFactoryDefID = unitDefID
	return true
end

local function CheckNanoTransformRange()
	local alt, ctrl = Spring.GetModKeyState()
	if alt and ctrl then
		return
	end
	
	local mx, mz = GetMousePos()
	if not mx then
		return
	end
	
	local unitID, distSq, factoryData = GetClosestFactory(mx, mz, currentFactoryDefID)
	if not unitID then
		return
	end
	
	closestFactoryData = factoryData
	if distSq >= FACTORY_RANGE_SQ then
		Spring.SetActiveCommand(factoryBuildAction[currentFactoryDefID])
	end
	
	return true
end

function widget:Update()
	local _, cmdID = spGetActiveCommand()
	if cmdID then
		local unitDefID = -cmdID
		if factoryBuildAction[unitDefID] and CheckFactoryTransformRange(unitDefID) then
			return
		end
		
		if currentFactoryDefID and unitDefID == nanoUnitDefID then
			if CheckNanoTransformRange() then
				return
			end
			Spring.SetActiveCommand(factoryBuildAction[currentFactoryDefID])
		end
	end
	
	if currentFactoryDefID then
		currentFactoryDefID = nil
		closestFactoryData = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID, teamID)
	if not (factoryBuildAction[unitDefID] and teamID == myTeamID) then
		return
	end
	local x,y,z = Spring.GetUnitPosition(unitID)
	factories.Add(unitID, {
		unitDefID = unitDefID,
		x = x,
		y = y,
		z = z,
	})
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if not factoryBuildAction[unitDefID] then
		return
	end
	factories.Remove(unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitDestroyed(unitID, unitDefID, teamID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, teamID)
end

function widget:Initialize()
	factories.Clear()
	
	local units = Spring.GetTeamUnits(myTeamID)
	for i = 1, #units do
		local unitID = units[i]
		widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID), myTeamID)
	end
end

function widget:PlayerChanged(playerID)
	if myPlayerID ~= playerID then
		return
	end
	myTeamID = Spring.GetMyTeamID()
	widget:Initialize()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function DoLine(x1, y1, z1, x2, y2, z2)
	gl.Vertex(x1, y1, z1)
	gl.Vertex(x2, y2, z2)
end

local function DrawFactoryLine(x, y, z)
	local mx, mz = GetMousePos()
	if not mx then
		return
	end
	
	local _, cmdID = spGetActiveCommand()
	if not (cmdID and oddX[-cmdID]) then
		return
	end
	
	local facing = Spring.GetBuildFacing()
	local offFacing = (facing == 1 or facing == 3)
	if offFacing then
		mx = math.floor((mx + 8 - oddZ[-cmdID])/16)*16 + oddZ[-cmdID]
		mz = math.floor((mz + 8 - oddX[-cmdID])/16)*16 + oddX[-cmdID]
	else
		mx = math.floor((mx + 8 - oddX[-cmdID])/16)*16 + oddX[-cmdID]
		mz = math.floor((mz + 8 - oddZ[-cmdID])/16)*16 + oddZ[-cmdID]
	end

	local my = spGetGroundHeight(mx, mz)

	glLineWidth(inCircle.width)
	glColor(inCircle.color[1], inCircle.color[2], inCircle.color[3], inCircle.color[4])
	gl.BeginEnd(GL.LINE_STRIP, DoLine, x, y, z, mx, my, mz)

	glLineStipple(false)
	glLineWidth(1)
	glColor(1, 1, 1, 1)
end

local function GetDrawDef(mx, mz, data)
	if DistSq(mx, mz, data.x, data.z) < FACTORY_RANGE_SQ then
		return inCircle
	end
	return outCircle
end

function widget:DrawInMiniMap(minimapX, minimapY)
	if not currentFactoryDefID then
		return
	end
	local mx, mz = GetMousePos()
	if not mx then
		return
	end
	
	local drawn = false
	for unitID, data in factories.Iterator() do
		if data.unitDefID == currentFactoryDefID then
			drawn = true
			local drawDef = GetDrawDef(mx, mz, data)
			
			glTranslate(0,minimapY,0)
			glScale(minimapX/mapX, -minimapY/mapZ, 1)
			
			glLineWidth(drawDef.miniWidth)
			glColor(drawDef.color[1], drawDef.color[2], drawDef.color[3], drawDef.color[4])
			
			glDrawCircle(data.x, data.z, drawDef.range)
		end
	end
	
	if drawn then
		glScale(1, 1, 1)
		glLineStipple(false)
		glLineWidth(1)
		glColor(1, 1, 1, 1)
	end
end

function widget:DrawWorld()
	if not currentFactoryDefID then
		return
	end
	local mx, mz = GetMousePos()
	if not mx then
		return
	end
	
	local drawn = false
	for unitID, data in factories.Iterator() do
		if data.unitDefID == currentFactoryDefID then
			drawn = true
			local drawDef = GetDrawDef(mx, mz, data)
			
			gl.DepthTest(false)
			glLineWidth(drawDef.width)
			glColor(drawDef.color[1], drawDef.color[2], drawDef.color[3], drawDef.color[4])
			
			glDrawGroundCircle(data.x, data.y, data.z, drawDef.range, drawDef.circleDivs)
		end
	end
	
	if drawn then
		glLineStipple(false)
		glLineWidth(1)
		glColor(1, 1, 1, 1)
	end
	
	if closestFactoryData then
		DrawFactoryLine(closestFactoryData.x, closestFactoryData.y, closestFactoryData.z)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
