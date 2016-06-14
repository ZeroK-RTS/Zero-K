function widget:GetInfo()
	return {
		name      = "Persistent Build Height",
		desc      = "Persistent UI for setting Skydust height.",
		author    = "Google Frog",
		version   = "v1",
		date      = "7th June, 2016",
		license   = "GNU GPL, v2 or later",
		layer     = math.huge,
		enabled   = true,
		handler   = true,
	}
end

--------------------------------------------------------------------------------
-- Speedups
--------------------------------------------------------------------------------

local spGetActiveCommand = Spring.GetActiveCommand
local spSetActiveCommand = Spring.SetActiveCommand
local spGetMouseState    = Spring.GetMouseState
local spTraceScreenRay   = Spring.TraceScreenRay
local spGetGroundHeight  = Spring.GetGroundHeight
local spGetSelectedUnits = Spring.GetSelectedUnits
local spGetModKeyState   = Spring.GetModKeyState

local GL_LINE_STRIP		= GL.LINE_STRIP
local GL_LINES			= GL.LINES
local glVertex			= gl.Vertex
local glLineWidth   	= gl.LineWidth
local glColor       	= gl.Color
local glBeginEnd    	= gl.BeginEnd

local floor = math.floor
local ceil = math.ceil 

---------------------------------
-- Epic Menu
---------------------------------
options_path = 'Settings/Interface/Building Placement'
options_order = { 'setHeightWithAlt'}
options = {
	setHeightWithAlt = {
		name = "Require B to set height",
		type = "bool",
		value = true,
		desc = "Press B while placing a structure to set the height of the structure. Keys C and V increase or decrease height."
	},
}

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

include("keysym.h.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")

local INCREMENT_SIZE = 20
local heightIncrease = KEYSYMS.C
local heightDecrease = KEYSYMS.V
local toggleHeight   = KEYSYMS.B

-- Colours used during height choosing for level and raise
local negVolume   = {1, 0, 0, 0.1} -- negative volume
local posVolume   = {0, 1, 0, 0.1} -- posisive volume
local groundGridColor  = {0.3, 0.2, 1, 0.8} -- grid representing new ground height

-- colour of lasso during drawing
local lassoColor = {0.2, 1.0, 0.2, 1.0}

--------------------------------------------------------------------------------
-- Local Vars
--------------------------------------------------------------------------------

local defaultBuildHeight = 40
local buildHeight = {}
local buildingPlacementID = false
local buildingPlacementHeight = 0

local buildToGive = false
local toggleEnabled = false

local pointX = 0
local pointY = 0
local pointZ = 0

local sizeX = 0
local sizeZ = 0
local oddX = 0
local oddZ = 0

local facing = 0

--------------------------------------------------------------------------------
-- Height Handling
--------------------------------------------------------------------------------

local function CheckEnabled()
	if options.setHeightWithAlt.value then
		return toggleEnabled
	end
	return true
end

local function SendCommand()
	local constructor = spGetSelectedUnits()

	if #constructor == 0 then 
		return
	end
	
	local params = {}
	params[1] = 1            -- terraform type = level
	params[2] = Spring.GetMyTeamID()
	params[3] = 1            -- Loop parameter
	params[4] = pointY       -- Height parameter of terraform 
	params[5] = 5            -- Five points in the terraform
	params[6] = #constructor -- Number of constructors with the command
	params[7] = 0            -- Ordinary volume selection
	
	-- Rectangle of terraform
	params[8]  = pointX + sizeX
	params[9] = pointZ + sizeZ
	params[10] = pointX + sizeX
	params[11] = pointZ - sizeZ
	params[12] = pointX - sizeX
	params[13] = pointZ - sizeZ
	params[14] = pointX - sizeX
	params[15] = pointZ + sizeZ
	params[16] = pointX + sizeX
	params[17] = pointZ + sizeZ
	
	-- Set constructors
	local i = 18
	for j = 1, #constructor do
		params[i] = constructor[j]
		i = i + 1
	end
	
	params[#params + 1] = WG.Terraform_GetNextTag()
	
	local a,c,m,s = spGetModKeyState()
	
	if s then
		Spring.GiveOrderToUnit(constructor[1], CMD_TERRAFORM_INTERNAL, params, {"shift"})
	else
		Spring.GiveOrderToUnit(constructor[1], CMD_TERRAFORM_INTERNAL, params, {})
		spSetActiveCommand(-1)
	end
	
	local waitFrame = 30	
	local myPlayerID = Spring.GetMyPlayerID()
	if myPlayerID then
		-- ping is in seconds
		local myPing = select(6, Spring.GetPlayerInfo(myPlayerID))
		waitFrame = 30*ceil(myPing) + 5
	end
	
	buildToGive = {
		facing = facing,
		cmdID = -buildingPlacementID,
		x = pointX,
		z = pointZ,
		constructor = constructor,
		waitFrame = waitFrame,
		needGameFrame = true
	}
end

function widget:KeyPress(key, mods)
	local _,activeCommand = spGetActiveCommand()
	if (not activeCommand) or (activeCommand > 0) then
		return false
	end
	
	if key == toggleHeight and options.setHeightWithAlt.value then
		toggleEnabled = not toggleEnabled
		return true
	end
	
	if ((key ~= heightIncrease) and (key ~= heightDecrease)) then
		return false
	end
	
	-- Return true during structure placement to block C and V for integral menu.
	if (not buildingPlacementID) then
		return true
	end
	
	if key == heightIncrease then
		buildingPlacementHeight = (buildingPlacementHeight or 0) + INCREMENT_SIZE
	elseif key == heightDecrease then
		buildingPlacementHeight = (buildingPlacementHeight or 0) - INCREMENT_SIZE
	end
	
	buildHeight[buildingPlacementID] = buildingPlacementHeight
	widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
	return true
end

function widget:Update(dt)
	if buildToGive and buildToGive.needGameFrame then
		widgetHandler:UpdateWidgetCallIn("GameFrame", self)
		buildToGive.needGameFrame = false
	end 
	
	if not CheckEnabled() then
		buildingPlacementID = false
		return
	end
	
	local _,activeCommand = spGetActiveCommand()
	if (not activeCommand) or (activeCommand > 0) then
		if buildingPlacementID then
			buildingPlacementID = false
			toggleEnabled = false
		end
		return
	end
	
	if buildingPlacementID ~= -activeCommand then
		buildingPlacementID = -activeCommand
		buildingPlacementHeight = (buildHeight[buildingPlacementID] or defaultBuildHeight)
		
		local ud = UnitDefs[buildingPlacementID]
		
		facing = Spring.GetBuildFacing()
		local offFacing = (facing == 1 or facing == 3)
		
		local footX = ud.xsize/2
		local footZ = ud.zsize/2
		
		if offFacing then
			footX, footZ = footZ, footX
		end
		
		oddX = (footX%2)*8
		oddZ = (footZ%2)*8
		
		sizeX = footX * 8 - 0.1
		sizeZ = footZ * 8 - 0.1
		
		widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
	end
	
	local mx,my = spGetMouseState()
	local _, pos = spTraceScreenRay(mx, my, true)
	
	if pos then
		pointX = floor((pos[1] + 8 - oddX)/16)*16 + oddX
		pointZ = floor((pos[3] + 8 - oddZ)/16)*16 + oddZ
		pointY = spGetGroundHeight(pointX, pointZ) + buildingPlacementHeight	
	else 
		pointX = false
	end
end

function widget:MousePress(mx, my, button)
	if not (buildingPlacementID and buildingPlacementHeight ~= 0 and button == 1 and pointX) then
		return
	end
	
	SendCommand()
	return true
end

function widget:GameFrame(f)
	if not buildToGive then
		widgetHandler:RemoveWidgetCallIn("GameFrame", self)
		return
	end
	
	buildToGive.waitFrame = buildToGive.waitFrame - 1
	if buildToGive.waitFrame < 0 then
		local constructor = buildToGive.constructor
		for i = 1, #constructor do
			Spring.GiveOrderToUnit(constructor[i], buildToGive.cmdID, {buildToGive.x, 0, buildToGive.z, buildToGive.facing}, {"shift"})
			i = i + 1
		end
		buildToGive = false
		widgetHandler:RemoveWidgetCallIn("GameFrame", self)
	end
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

local function DrawRectangleLine()
	glVertex(pointX + sizeX, pointY, pointZ + sizeZ)
	glVertex(pointX + sizeX, pointY, pointZ - sizeZ)
	glVertex(pointX - sizeX, pointY, pointZ - sizeZ)
	glVertex(pointX - sizeX, pointY, pointZ + sizeZ)
	glVertex(pointX + sizeX, pointY, pointZ + sizeZ)
end

function widget:DrawWorld()
	if not (buildingPlacementID and buildingPlacementHeight ~= 0) then
		widgetHandler:RemoveWidgetCallIn("DrawWorld", self)
		return
	end

	if pointX then
		--// draw the lines
		glLineWidth(3.0)
		
		glColor(lassoColor)
		glBeginEnd(GL_LINE_STRIP, DrawRectangleLine)
		
		glColor(1, 1, 1, 1)
		glLineWidth(1.0)
	end
end

function widget:Shutdown()
	if (volumeDraw) then 
		gl.DeleteList(volumeDraw); volumeDraw=nil
		gl.DeleteList(mouseGridDraw); mouseGridDraw=nil
	end
	if (groundGridDraw) then 
		gl.DeleteList(groundGridDraw); groundGridDraw=nil 
	end
end

--------------------------------------------------------------------------------
-- Persistent Config
--------------------------------------------------------------------------------

function widget:GetConfigData()
    local heightByName = {}
	for unitDefID, spacing in pairs(buildHeight) do
		local name = UnitDefs[unitDefID] and UnitDefs[unitDefID].name
		if name then
			heightByName[name] = spacing
		end
	end
	return {buildHeight = heightByName}
end

function widget:SetConfigData(data)
    local heightByName = data.buildHeight or {}
	for name, spacing in pairs(heightByName) do
		local unitDefID = UnitDefNames[name] and UnitDefNames[name].id
		if unitDefID then
			buildHeight[unitDefID] = spacing
		end
	end
end