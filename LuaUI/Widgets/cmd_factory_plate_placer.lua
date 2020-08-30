--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Factory Plate Placer",
		desc      = "Replaces factory placement with plates of the appropriate type.",
		author    = "GoogleFrog",
		date      = "20 July 2019",
		license   = "GNU GPL, v2 or later",
		layer     = -1,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Speedup

include("keysym.lua")
VFS.Include("LuaRules/Utilities/glVolumes.lua")

local spGetActiveCommand = Spring.GetActiveCommand
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetMouseState    = Spring.GetMouseState
local spGetGroundHeight  = Spring.GetGroundHeight

local floor = math.floor
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

options_path = 'Settings/Interface/Building Placement'
options_order = { 'ctrl_toggle'}
options = {
	ctrl_toggle = {
		name = "Ctrl toggles Factory/Plate",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'When placing a factory or plate, press Ctrl to select whether a factory or construction plate is placed.',
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local FACTORY_RANGE_SQ = VFS.Include("gamedata/unitdefs_pre.lua", nil, VFS.GAME).FACTORY_PLATE_RANGE^2

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
local buildAction = {}
local childOfFactory = {}
local parentOfPlate = {}
local floatOnWater = {}

for i = 1, #UnitDefs do
	local ud = UnitDefs[i]
	local cp = ud.customParams
	if (cp.parent_of_plate or cp.child_of_factory) then
		buildAction[i] = "buildunit_" .. ud.name
		oddX[i] = (ud.xsize % 4)*4
		oddZ[i] = (ud.zsize % 4)*4
		floatOnWater[i] = ud.floatOnWater
		
		if cp.child_of_factory then
			childOfFactory[i] = UnitDefNames[cp.child_of_factory].id
		end
		if cp.parent_of_plate then
			parentOfPlate[i] = UnitDefNames[cp.parent_of_plate].id
		end
	end
end

local myPlayerID = Spring.GetLocalPlayerID()
local myAllyTeamID = Spring.GetMyAllyTeamID()

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")
local factories = IterableMap.New()

local currentFactoryDefID
local currentPlateDefID
local closestFactoryData
local activeCmdOverride

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DistSq(x1, z1, x2, z2)
	return (x1 - x2)*(x1 - x2) + (z1 - z2)*(z1 - z2)
end

local function GetClosestFactory(x, z, unitDefID)
	local nearID, nearDistSq, nearData
	for unitID, data in IterableMap.Iterator(factories) do
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

local function SnapBuildToGrid(mx, mz, unitDefID)
	local facing = Spring.GetBuildFacing()
	local offFacing = (facing == 1 or facing == 3)
	if offFacing then
		mx = math.floor((mx + 8 - oddZ[unitDefID])/16)*16 + oddZ[unitDefID]
		mz = math.floor((mz + 8 - oddX[unitDefID])/16)*16 + oddX[unitDefID]
	else
		mx = math.floor((mx + 8 - oddX[unitDefID])/16)*16 + oddX[unitDefID]
		mz = math.floor((mz + 8 - oddZ[unitDefID])/16)*16 + oddZ[unitDefID]
	end
	return mx, mz
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetMousePos(ignoreWater)
	local mouseX, mouseY = spGetMouseState()
	local _, mouse = spTraceScreenRay(mouseX, mouseY, true, true, false, ignoreWater)
	if not mouse then
		return
	end
	
	return mouse[1], mouse[3]
end

local function CheckTransformPlateIntoFactory(plateDefID)
	local mx, mz = GetMousePos(not floatOnWater[plateDefID])
	if not mx then
		return
	end
	
	local factoryDefID = childOfFactory[plateDefID]
	mx, mz = SnapBuildToGrid(mx, mz, plateDefID) -- Make sure the plate is in range when it is placed
	local unitID, distSq, factoryData = GetClosestFactory(mx, mz, factoryDefID)
	if not unitID then
		return
	end
	
	closestFactoryData = factoryData
	if distSq >= FACTORY_RANGE_SQ then
		Spring.SetActiveCommand(buildAction[factoryDefID])
	end
	return true
end

local function CheckTransformFactoryIntoPlate(factoryDefID)
	local mx, mz = GetMousePos(not floatOnWater[factoryDefID])
	if not mx then
		return
	end
	
	local plateDefID = parentOfPlate[factoryDefID]
	mx, mz = SnapBuildToGrid(mx, mz, plateDefID) -- Make sure the plate is in range when it is placed
	local unitID, distSq, factoryData = GetClosestFactory(mx, mz, factoryDefID)
	if not unitID then
		return
	end
	
	-- Plates could be disabled by modoptions or otherwise unavailible.
	local cmdDescID = Spring.GetCmdDescIndex(-plateDefID)
	if not cmdDescID then
		return
	end
	
	closestFactoryData = factoryData
	if distSq < FACTORY_RANGE_SQ then
		Spring.SetActiveCommand(buildAction[plateDefID])
	end
	return true
end

function widget:Update()
	local _, cmdID = spGetActiveCommand()
	if cmdID then
		local unitDefID = -cmdID
		if activeCmdOverride then
			if (unitDefID == currentFactoryDefID or unitDefID == currentPlateDefID) then
				return
			end
			activeCmdOverride = nil
		end
		if parentOfPlate[unitDefID] then
			currentFactoryDefID = unitDefID
			currentPlateDefID = parentOfPlate[unitDefID]
			if not CheckTransformFactoryIntoPlate(unitDefID) then
				closestFactoryData = false
			end
			return
		end
		if childOfFactory[unitDefID] then
			currentFactoryDefID = childOfFactory[unitDefID]
			currentPlateDefID = unitDefID
			if not CheckTransformPlateIntoFactory(unitDefID) then
				closestFactoryData = false
			end
			return
		end
	end
	
	if currentFactoryDefID then
		currentFactoryDefID = nil
		currentPlateDefID = nil
		closestFactoryData = nil
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:KeyPress(key, mods, isRepeat, label, unicode)
	if isRepeat then
		return
	end
	if not (currentFactoryDefID and currentPlateDefID) then
		return
	end
	if not (options.ctrl_toggle.value and (key == KEYSYMS.LCTRL or key == KEYSYMS.RCTRL)) then
		return
	end
	
	activeCmdOverride = true
	local _, cmdID = spGetActiveCommand()
	local unitDefID = -cmdID
	if unitDefID == currentFactoryDefID then
		Spring.SetActiveCommand(buildAction[currentPlateDefID])
	else
		Spring.SetActiveCommand(buildAction[currentFactoryDefID])
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID)
	if not (parentOfPlate[unitDefID] and Spring.GetUnitAllyTeam(unitID) == myAllyTeamID) then
		return
	end
	local x,y,z = Spring.GetUnitPosition(unitID)
	IterableMap.Add(factories, unitID, {
		unitDefID = unitDefID,
		x = x,
		y = y,
		z = z,
	})
end

function widget:UnitDestroyed(unitID, unitDefID, teamID)
	if not parentOfPlate[unitDefID] then
		return
	end
	IterableMap.Remove(factories, unitID)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	widget:UnitCreated(unitID, unitDefID, teamID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	widget:UnitDestroyed(unitID, unitDefID, teamID)
end

function widget:Initialize()
	IterableMap.Clear(factories)
	
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local unitID = units[i]
		widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
	end
end

function widget:PlayerChanged(playerID)
	if myPlayerID ~= playerID then
		return
	end
	if myAllyTeamID == Spring.GetMyAllyTeamID() then
		return
	end
	myAllyTeamID = Spring.GetMyAllyTeamID()
	widget:Initialize()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function DoLine(x1, y1, z1, x2, y2, z2)
	gl.Vertex(x1, y1, z1)
	gl.Vertex(x2, y2, z2)
end

local function GetDrawDef(mx, mz, data)
	if DistSq(mx, mz, data.x, data.z) < FACTORY_RANGE_SQ then
		return inCircle, true
	end
	return outCircle, false
end

local function DrawFactoryLine(x, y, z, drawDef)
	local mx, mz = GetMousePos(not floatOnWater[currentFactoryDefID])
	if not mx then
		return
	end
	
	local _, cmdID = spGetActiveCommand()
	if not (cmdID and oddX[-cmdID]) then
		return
	end
	
	mx, mz = SnapBuildToGrid(mx, mz, -cmdID)

	local my = spGetGroundHeight(mx, mz)

	glLineWidth(drawDef.width)
	glColor(drawDef.color[1], drawDef.color[2], drawDef.color[3], drawDef.color[4])
	gl.BeginEnd(GL.LINE_STRIP, DoLine, x, y, z, mx, my, mz)

	glLineStipple(false)
	glLineWidth(1)
	glColor(1, 1, 1, 1)
end

function widget:DrawInMiniMap(minimapX, minimapY)
	if not currentFactoryDefID then
		return
	end
	local mx, mz = GetMousePos(not floatOnWater[currentFactoryDefID])
	if not mx then
		return
	end
	mx, mz = SnapBuildToGrid(mx, mz, currentPlateDefID)
	
	local drawn = false
	for unitID, data in IterableMap.Iterator(factories) do
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
	local mx, mz = GetMousePos(not floatOnWater[currentFactoryDefID])
	if not mx then
		return
	end
	mx, mz = SnapBuildToGrid(mx, mz, currentPlateDefID)
	
	local drawn = false
	local drawInRange = false
	for unitID, data in IterableMap.Iterator(factories) do
		if data.unitDefID == currentFactoryDefID then
			drawn = true
			local drawDef, inRange = GetDrawDef(mx, mz, data)
			drawInRange = drawInRange or inRange
			
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
		DrawFactoryLine(closestFactoryData.x, closestFactoryData.y, closestFactoryData.z, drawInRange and inCircle or outCircle)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
