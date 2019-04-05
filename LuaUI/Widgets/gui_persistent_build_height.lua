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

include("keysym.h.lua")
local _, ToKeysyms = include("Configs/integral_menu_special_keys.lua")

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

local toggleHeight   = KEYSYMS.B
local heightIncrease = KEYSYMS.C
local heightDecrease = KEYSYMS.V

local function HotkeyChangeNotification()
	local key = WG.crude.GetHotkeyRaw("epic_persistent_build_height_hotkey_toggle")
	toggleHeight = ToKeysyms(key and key[1])
	key = WG.crude.GetHotkeyRaw("epic_persistent_build_height_hotkey_raise")
	heightIncrease = ToKeysyms(key and key[1])
	key = WG.crude.GetHotkeyRaw("epic_persistent_build_height_hotkey_lower")
	heightDecrease = ToKeysyms(key and key[1])
end

---------------------------------
-- Epic Menu
---------------------------------
local hotkeyPath = "Hotkeys/Construction"
options_path = 'Settings/Interface/Building Placement'
options_order = { 'enterSetHeightWithB', 'altMouseToSetHeight', 'hotkey_toggle', 'hotkey_raise', 'hotkey_lower'}
options = {
	enterSetHeightWithB = {
		name = "Toggle set height",
		type = "bool",
		value = true,
		noHotkey = true,
		desc = "Press a hotkey (default B) while placing a structure to set the height of the structure. Keys C and V increase or decrease height."
	},
	altMouseToSetHeight = {
		name = "Alt mouse wheel to set height",
		type = "bool",
		value = true,
		noHotkey = true,
		desc = "Hold Alt and mouse wheel to set height."
	},
	hotkey_toggle = {
		name = 'Toggle Structure Terraform',
		desc = 'Press during structure placement to make a strucutre on a spire or a hold. Alt + MMB also toggles this mode.',
		type = 'button',
		hotkey = "B",
		bindWithAny = true,
		dontRegisterAction = true,
		OnHotkeyChange = HotkeyChangeNotification,
		path = hotkeyPath,
	},
	hotkey_raise = {
		name = 'Raise Structure Teraform',
		desc = 'Increase the height of structure terraform. Also possible with Alt + Scrollwheel.',
		type = 'button',
		hotkey = "C",
		bindWithAny = true,
		dontRegisterAction = true,
		OnHotkeyChange = HotkeyChangeNotification,
		path = hotkeyPath,
	},
	hotkey_lower = {
		name = 'Lower Structure Terraform',
		desc = 'Decrease the height of structure terraform. Also possible with Alt + Scrollwheel.',
		type = 'button',
		hotkey = "V",
		bindWithAny = true,
		dontRegisterAction = true,
		OnHotkeyChange = HotkeyChangeNotification,
		path = hotkeyPath,
	},
}

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local mexDefID = UnitDefNames["staticmex"].id

local INCREMENT_SIZE = 20

-- Colours used during height choosing for level and raise
local negVolume   = {1, 0, 0, 0.1} -- negative volume
local posVolume   = {0, 1, 0, 0.1} -- posisive volume
local groundGridColor  = {0.3, 0.2, 1, 0.8} -- grid representing new ground height

-- colour of lasso during drawing
local lassoColor = {0.2, 1.0, 0.2, 0.8}
local edgeColor = {0.2, 1.0, 0.2, 0.4}

local SQUARE_BUILDABLE = 2 -- magic constant returned by TestBuildOrder

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

local corner = {
	[1] = {[1] = 0, [-1] = 0},
	[-1] = {[1] = 0, [-1] = 0},
}

--------------------------------------------------------------------------------
-- Height Handling
--------------------------------------------------------------------------------

local function CheckEnabled()
	if options.enterSetHeightWithB.value then
		return toggleEnabled
	end
	return true
end

local function SendCommand()
	local constructor = spGetSelectedUnits()

	if #constructor == 0 then 
		return
	end
	
	-- Snap mex to metal spots
	if buildingPlacementID == mexDefID and WG.GetClosestMetalSpot then
		local pos = WG.GetClosestMetalSpot(pointX, pointZ)
		if pos then
			pointX, pointZ = pos.x, pos.z
			
			local height = spGetGroundHeight(pointX, pointZ)
			if height < 0 then
				height = 0
				if buildingPlacementHeight == 0 then
					pointY = 2
				else
					pointY = height + buildingPlacementHeight
				end	
			else
				pointY = height + buildingPlacementHeight	
			end
		end
	end
	
	-- Setup parameters for terraform command
	local team = Spring.GetUnitTeam(constructor[1]) or Spring.GetMyTeamID()
	local commandTag = WG.Terraform_GetNextTag()
	
	local params = {}
	params[1] = 1            -- terraform type = level
	params[2] = team
	params[3] = pointX
	params[4] = pointZ
	params[5] = commandTag
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
	
	local a,c,m,s = spGetModKeyState()

	Spring.GiveOrderToUnit(constructor[1], CMD_TERRAFORM_INTERNAL, params, 0)
	
	-- if global build command is active, check if it wants to handle the orders before giving units any commands.
	if not WG.GlobalBuildCommand or not WG.GlobalBuildCommand.CommandNotifyRaiseAndBuild(constructor, -buildingPlacementID, pointX, pointY, pointZ, facing, s) then
		if not s then
			spSetActiveCommand(-1)
		end

		local cmdOpts = {coded = 0}
		if s then
			cmdOpts.shift = true
			cmdOpts.coded = cmdOpts.coded + CMD.OPT_SHIFT
		end
		if m then
			cmdOpts.meta = true
			cmdOpts.coded = cmdOpts.coded + CMD.OPT_META
		end

		local height = Spring.GetGroundHeight(pointX, pointZ)

		WG.CommandInsert(CMD_LEVEL, {pointX, height, pointZ, commandTag}, cmdOpts)
		WG.CommandInsert(-buildingPlacementID, {pointX, height, pointZ, facing}, cmdOpts, 1)
	end
end

function widget:KeyPress(key, mods)
	local _,activeCommand = spGetActiveCommand()
	if (not activeCommand) or (activeCommand >= 0) then
		return false
	end
	
	if key == toggleHeight and options.enterSetHeightWithB.value then
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
	if (not activeCommand) or (activeCommand >= 0) then
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
	local _, pos = spTraceScreenRay(mx, my, true, false, false, not ud.floatOnWater)
	
	if pos then
		pointX = floor((pos[1] + 8 - oddX)/16)*16 + oddX
		pointZ = floor((pos[3] + 8 - oddZ)/16)*16 + oddZ
		local height = spGetGroundHeight(pointX, pointZ)
		if ud.floatOnWater and height < 0 then
			if buildingPlacementHeight == 0 and not floating then
				-- Callin may have been removed
				widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
			end
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
		
		for i = -1, 1, 2 do
			for j = -1, 1, 2 do
				corner[i][j] = spGetGroundHeight(pointX + sizeX*i, pointZ + sizeZ*j)
			end
		end
	else 
		pointX = false
	end
end

function widget:MouseWheel(up, value)
	if not options.altMouseToSetHeight.value then
		return
	end
	local _,activeCommand = spGetActiveCommand()
	if (not activeCommand) or (activeCommand > 0) then
		return false
	end
	local alt, ctrl, meta, shift = Spring.GetModKeyState()
	if not alt then
		return
	end
	toggleEnabled = true
	buildingPlacementHeight = (buildingPlacementHeight or 0) + INCREMENT_SIZE*value
	
	buildHeight[buildingPlacementID] = buildingPlacementHeight
	widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
	
	return true
end

function widget:MousePress(mx, my, button)
	if button == 2 and options.altMouseToSetHeight.value then
		local alt, ctrl, meta, shift = Spring.GetModKeyState()
		if not alt then
			return
		end
		local _,activeCommand = spGetActiveCommand()
		if (not activeCommand) or (activeCommand > 0) then
			return
		end
		toggleEnabled = not toggleEnabled
		if toggleEnabled then
			widgetHandler:UpdateWidgetCallIn("DrawWorld", self)
		else
			buildingPlacementID = false
		end
		return true
	end

	if not buildingPlacementID then
		return
	end

	local unbuildableTerrain = (Spring.TestBuildOrder(buildingPlacementID, pointX, 0, pointZ, Spring.GetBuildFacing()) ~= SQUARE_BUILDABLE)

	if not ((floating or buildingPlacementHeight ~= 0 or (buildingPlacementHeight == 0 and unbuildableTerrain)) and button == 1 and pointX) then
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

local function DrawRectangleCorners()
	glVertex(pointX + sizeX, pointY, pointZ + sizeZ)
	glVertex(pointX + sizeX, corner[1][1], pointZ + sizeZ)
	
	glVertex(pointX + sizeX, pointY, pointZ - sizeZ)
	glVertex(pointX + sizeX, corner[1][-1], pointZ - sizeZ)
	
	glVertex(pointX - sizeX, pointY, pointZ - sizeZ)
	glVertex(pointX - sizeX, corner[-1][-1], pointZ - sizeZ)
	
	glVertex(pointX - sizeX, pointY, pointZ + sizeZ)
	glVertex(pointX - sizeX, corner[-1][1], pointZ + sizeZ)
end

function widget:DrawWorld()
	if not buildingPlacementID then
		widgetHandler:RemoveWidgetCallIn("DrawWorld", self)
		return
	end

	if pointX then
		--// draw the lines
		
		glLineWidth(2.0)
		glColor(edgeColor)
		glBeginEnd(GL_LINES, DrawRectangleCorners)
		
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

function widget:Initialize()
	HotkeyChangeNotification()
end
