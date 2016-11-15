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

local toggleEnabled = false
local floating = false

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
	
	local commandRadius = sizeX + math.random()
	
	local params = {}
	params[1] = 1            -- terraform type = level
	params[2] = Spring.GetMyTeamID()
	params[3] = pointX
	params[4] = pointZ
	params[5] = commandRadius
	params[6] = 1            -- Loop parameter
	params[7] = pointY       -- Height parameter of terraform 
	params[8] = 5            -- Five points in the terraform
	params[9] = #constructor -- Number of constructors with the command
	params[10] = 0            -- Ordinary volume selection
	
	-- Rectangle of terraform
	params[11]  = pointX + sizeX
	params[12] = pointZ + sizeZ
	params[13] = pointX + sizeX
	params[14] = pointZ - sizeZ
	params[15] = pointX - sizeX
	params[16] = pointZ - sizeZ
	params[17] = pointX - sizeX
	params[18] = pointZ + sizeZ
	params[19] = pointX + sizeX
	params[20] = pointZ + sizeZ
	
	-- Set constructors
	local i = 21
	for j = 1, #constructor do
		params[i] = constructor[j]
		i = i + 1
	end
	
	params[#params + 1] = WG.Terraform_GetNextTag()
	
	local a,c,m,s = spGetModKeyState()
	
	-- check whether some other widget wants to handle the commands before sending them to the units.
	if not WG.GobalBuildCommand or not WG.GobalBuildCommand.CommandNotifyRaiseAndBuild(constructor, -buildingPlacementID, pointX, pointY, pointZ, facing, params, s) then
		Spring.GiveOrderToUnit(constructor[1], CMD_TERRAFORM_INTERNAL, params, {})
		if not s then
			spSetActiveCommand(-1)
		end
	
		local cmdOpts = {}
		if s then
			cmdOpts[#cmdOpts + 1] = "shift"
		end
	
		local height = Spring.GetGroundHeight(pointX, pointZ)
		for i = 1, #constructor do
			Spring.GiveOrderToUnit(constructor[i], CMD_LEVEL, {pointX, height, pointZ, commandRadius}, cmdOpts)
			Spring.GiveOrderToUnit(constructor[i], -buildingPlacementID, {pointX, 0, pointZ, facing}, {"shift"})
		end
	end
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
		
		facing = Spring.GetBuildFacing()
		local offFacing = (facing == 1 or facing == 3)
		
		local ud = UnitDefs[buildingPlacementID]
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
		
	local ud = buildingPlacementID and UnitDefs[buildingPlacementID]
	if not ud then
		return
	end
	
	local mx,my = spGetMouseState()
	-- Should not ignore water if the structure can float. See https://springrts.com/mantis/view.php?id=5390
	local _, pos = spTraceScreenRay(mx, my, true, false, false, true)
	
	if pos then
		pointX = floor((pos[1] + 8 - oddX)/16)*16 + oddX
		pointZ = floor((pos[3] + 8 - oddZ)/16)*16 + oddZ
		local height = spGetGroundHeight(pointX, pointZ)
		if ud.floatOnWater and height < 0 then
			height = 0
			floating = true
			if buildingPlacementHeight == 0 then
				pointY = 2
			else
				pointY = height + buildingPlacementHeight
			end	
		else
			floating = false
			pointY = height + buildingPlacementHeight	
		end
	else 
		pointX = false
	end
end

function widget:MousePress(mx, my, button)
	if not (buildingPlacementID and (buildingPlacementHeight ~= 0 or floating) and button == 1 and pointX) then
		return
	end
	
	SendCommand()
	return true
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