--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Icon Zoom Transition",
    desc      = "Smoothly transitions between icon view and model view",
    author    = "CrazyEddie",
    date      = "2017-08-28",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    handler   = true,
    enabled   = false,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Parameters
local tolerance = 25

-- Flags and switches
local waiting_on_double
local current_mode
local target_mode
local showing_icons
local drawIcons = false

-- Variables
local kp_timer
local testHeight = 0

-- Initialized arrays
local unitDefsToRender = {}
local unitsToRender = {}
local renderOrders = { {}, {}, {} }
local renderAtPos = {}

-- Forward function declarations
local GotHotkeypress = function() end
local UpdateDynamic = function() end

-- Localized Spring functions
local echo = Spring.Echo

local spGetSpectatingState = Spring.GetSpectatingState
local spSendCommands       = Spring.SendCommands
local spGetTimer           = Spring.GetTimer
local spIsGUIHidden        = Spring.IsGUIHidden
local spDiffTimers         = Spring.DiffTimers

local spGetAllUnits         = Spring.GetAllUnits
local spGetVisibleUnits     = Spring.GetVisibleUnits
local spGetUnitDefID        = Spring.GetUnitDefID
local spIsUnitInView        = Spring.IsUnitInView
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spIsUnitSelected      = Spring.IsUnitSelected
local spGetUnitTeam         = Spring.GetUnitTeam
local spGetTeamColor        = Spring.GetTeamColor

local spGetCameraState      = Spring.GetCameraState
local spGetGroundHeight     = Spring.GetGroundHeight

local glDepthTest      = gl.DepthTest
local glDepthMask      = gl.DepthMask
local glAlphaTest      = gl.AlphaTest
local glTexture        = gl.Texture
local glTexRect        = gl.TexRect
local glTranslate      = gl.Translate
local glBillboard      = gl.Billboard
local glDrawFuncAtUnit = gl.DrawFuncAtUnit
local glPushMatrix     = gl.PushMatrix
local glPopMatrix      = gl.PopMatrix

local GL_GREATER = GL.GREATER

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Includes and initializations
--

include("keysym.h.lua")
local iconTypesPath = LUAUI_DIRNAME .. "Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)
local _, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFS.RAW_FIRST)

renderAtPos = {
	[UnitDefNames["staticmex"].id] = true,
	[UnitDefNames["energywind"].id] = true,
	[UnitDefNames["energysolar"].id] = true,
	[UnitDefNames["staticradar"].id] = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options
--

options_path = 'Settings/Graphics/Unit Visibility/Icon Transition'

options_order = {
	'lblIconTransition',
	'icontransitiontop',
	'icontransitionbottom',
	'icontransitionmaxsize',
	'icontransitionminsize',
	'icontransitionmaxopacity',
	'icontransitionminopacity',
	'iconmodehotkey',
}

options = {
	lblIconTransition = {name = 'Icon Transition Widget', type = 'label'},
	icontransitiontop = {
		name = 'Icon Transition Top',
		desc = 'If the camera is above this height, units will be icons only.\n\nOnly applies when the icon display mode is set to Dynamic.\n\nThis setting overrides Icon Distance.',
		type = 'number',
		min = 0, max = 10000,
		step = 50,
		value = 5500,
	},
	icontransitionbottom = {
		name = 'Icon Transition Bottom',
		desc = 'If the camera is below this height, units will be models only.\n\nOnly applies when the icon display mode is set to Dynamic.\n\nThis setting overrides Icon Distance.',
		type = 'number',
		min = 0, max = 10000,
		step = 50,
		value = 2400,
	},
	icontransitionmaxsize = {
		name = 'Icon Transition Max Size',
		desc = 'Size of the icons when the transition begins.',
		type = 'number',
		min = 1, max = 250,
		step = 1,
		value = 62,
	},
	icontransitionminsize = {
		name = 'Icon Transition Min Size',
		desc = 'Size of the icons when the transition ends.',
		type = 'number',
		min = 1, max = 250,
		step = 1,
		value = 11,
	},
	icontransitionmaxopacity = {
		name = 'Icon Transition Max Opacity',
		desc = 'Opacity of the icons when the transition begins.',
		type = 'number',
		min = 0, max = 100,
		value = 100,
	},
	icontransitionminopacity = {
		name = 'Icon Transition Min Opacity',
		desc = 'Opacity of the icons when the transition ends.',
		type = 'number',
		min = 0, max = 100,
		value = 100,
	},
	iconmodehotkey = {
		name = "Icon Mode Hotkey",
		desc = "Define a hotkey to switch between icon display modes (On/Off/Dynamic).\n\nSingle-press to switch between On/Off.\n\nDouble-press to switch to Dynamic.",
		type = 'button',
		hotkey = 'Alt+I',
		OnChange = function(self) GotHotkeypress() end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Controlling the icon view
--

function GotHotkeypress()
	if waiting_on_double then
		waiting_on_double = false
		target_mode = nil
		kp_timer = nil
		current_mode = "Dynamic"
		UpdateDynamic()
	else
		waiting_on_double = true
		kp_timer = spGetTimer()
		if current_mode == "On" then
			target_mode = "Off"
		elseif current_mode == "Off" then
			target_mode = "On"
		elseif showing_icons then
			target_mode = "Off"
		else
			target_mode = "On"
		end
	end
end

function UpdateDynamic()
	local cs = spGetCameraState()
	local gy = spGetGroundHeight(cs.px, cs.pz)
	testHeight = cs.py - gy
	if cs.name == "ov" then
		testHeight = options.icontransitiontop.value * 2
	elseif cs.name == "ta" then
		testHeight = cs.height - gy
	end
	
	-- Leave a one update gap between enabling engine icons and disabling widget drawing.
	if showing_icons and drawIcons then
		drawIcons = false
	end
	
	if showing_icons and testHeight < options.icontransitiontop.value - tolerance then
		spSendCommands("disticon " .. 100000)
		showing_icons = false
		drawIcons = true
	elseif not showing_icons and testHeight > options.icontransitiontop.value + tolerance then
		spSendCommands("disticon " .. 0)
		showing_icons = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Adding and removing units from the list of units to draw icons for
--

local function addUnitIcon(unitID, unitDefID)
	if not unitID or not unitDefID then return end
	if unitsToRender[unitID] and unitsToRender[unitID].udid
			and unitsToRender[unitID].udid ~= unitDefID
			and unitDefsToRender[unitsToRender[unitID].udid]
			and unitDefsToRender[unitsToRender[unitID].udid].units then
		unitDefsToRender[unitsToRender[unitID].udid].units[unitID] = nil
	end
	local team = unitID and spGetUnitTeam(unitID)
	local teamcolor = team and {spGetTeamColor(team)}
	if not unitDefsToRender[unitDefID] then
		local ud = UnitDefs[unitDefID]
		local texture = icontypes[(ud and ud.iconType or "default")].bitmap or 'icons/' .. ud.iconType .. iconFormat
		local size = icontypes[(ud and ud.iconType or "default")].size or 1.8
		local render_order
		local midPos
		if ud and ud.isFactory then
			render_order = 1
		elseif ud and ud.isAirUnit then
			render_order = 3
		else
			render_order = 2
		end
		if renderAtPos[unitDefID] then
			midPos = false
		else
			midPos = true
		end
		unitDefsToRender[unitDefID] = {
			texture = texture,
			size = size,
			render_order = render_order,
			midPos = midPos,
		}
		renderOrders[render_order][unitDefID] = unitDefsToRender[unitDefID]
	end
	if not unitDefsToRender[unitDefID].units then
		unitDefsToRender[unitDefID].units = {}
	end
	unitDefsToRender[unitDefID].units[unitID] = {color = teamcolor}
	unitsToRender[unitID] = {udid = unitDefID}
end

local function removeUnitIcon(unitID)
	if not unitID then return end
	if unitsToRender[unitID] and unitsToRender[unitID].udid
			and unitsToRender[unitID].udid ~= unitDefID
			and unitDefsToRender[unitsToRender[unitID].udid]
			and unitDefsToRender[unitsToRender[unitID].udid].units then
		unitDefsToRender[unitsToRender[unitID].udid].units[unitID] = nil
	end
	unitsToRender[unitID] = nil
end

local function UpdateUnitIconTeam(unitID, unitDefID, newTeamID)
	if not (unitID and unitDefID and unitDefsToRender[unitDefID]) then
		return
	end
	if not unitDefsToRender[unitDefID].units[unitID] then
		return
	end
	newTeamID = newTeamID or spGetUnitTeam(unitID)
	if newTeamID then
		local teamcolor = {spGetTeamColor(newTeamID)}
		unitDefsToRender[unitDefID].units[unitID].color = teamcolor
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Drawing
--

local function DrawUnitFunc(size)
	size = size or 1
	--glTranslate(0, 50, 0) Some translation is sometimes required.
	glBillboard()
	glTexRect(-size*0.5, -size*0.5, size*0.5, size*0.5)
end

local function DrawWorldFunc()
	if (not drawIcons) or (testHeight < options.icontransitionbottom.value) then
		return
	end
	
	local scale, opacity
	scale = options.icontransitionminsize.value + (options.icontransitionmaxsize.value - options.icontransitionminsize.value) * (testHeight - options.icontransitionbottom.value) / (options.icontransitiontop.value - options.icontransitionbottom.value)
	opacity = options.icontransitionminopacity.value + (options.icontransitionmaxopacity.value - options.icontransitionminopacity.value) * (testHeight - options.icontransitionbottom.value) / (options.icontransitiontop.value - options.icontransitionbottom.value)
	opacity = opacity / 100

	gl.Color(1,1,1,1)
	glDepthMask(true)
	glDepthTest(false)
	glAlphaTest(GL_GREATER, 0.001)
	
	-- this is probably faster than spIsUnitInView() for all the units
	-- but that's probably worth testing to confirm
	local unitsInView = spGetVisibleUnits()
	local unitIsInView = {}
	for k, v in pairs(unitsInView) do
		unitIsInView[v] = true
	end
	
	if scale > options.icontransitionmaxsize.value then
		scale = options.icontransitionmaxsize.value
	end
	
	for i, unitDefIDs in ipairs(renderOrders) do
		for unitDefID, iconDef in pairs(unitDefIDs) do
			if iconDef then
				glTexture(iconDef.texture)
				for unitID, unitIconDef in pairs(iconDef.units) do
					local color = unitIconDef and unitIconDef.color
					if unitIsInView[unitID] then
						if spIsUnitSelected(unitID) then
							gl.Color(1,1,1,opacity)
						elseif color then
							gl.Color( color[1], color[2], color[3], color[4] * opacity )
						else
							gl.Color(1,1,1,opacity)
						end
						glDrawFuncAtUnit(unitID, iconDef.midPos, DrawUnitFunc, scale*iconDef.size)
						gl.Color(1,1,1,1)
					end
				end
			end
		end
	end
	
	glTexture(false)
	glAlphaTest(false)
	glDepthTest(false)
	glDepthMask(false)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Event Call-ins
--

function widget:Initialize()
	waiting_on_double = false
	target_mode = nil
	kp_timer = nil
	current_mode = "Dynamic"
	UpdateDynamic()

	local allUnits = spGetAllUnits()
	for _,unitID in pairs (allUnits) do
		local unitDefID = spGetUnitDefID(unitID)
		addUnitIcon(unitID, unitDefID)
	end
end

function widget:Update()
	
	if not waiting_on_double and current_mode ~= "Dynamic" then
		-- We're not waiting, so there wasn't an earlier single keypress, so don't switch modes
		-- And the current mode isn't dynamic, so don't check camera height
		return
	end
	
	-- We're either waiting, or in dynamic mode, or both
	
	-- If we're waiting, check to see if the time is up, and if so, then act on the earlier single keypress,
	-- which means changing the mode to either On or Off (depending on the state when the key was pressed)
	if waiting_on_double then
		local now_timer = spGetTimer()
		if kp_timer and spDiffTimers(now_timer, kp_timer) > 0.2 then
			if target_mode == "On" then
				spSendCommands("disticon " .. 0)
				showing_icons = true
				current_mode = "On"
			else
				spSendCommands("disticon " .. 50000)
				showing_icons = false
				current_mode = "Off"
			end
			target_mode = nil
			kp_timer = nil
			waiting_on_double = nil
			drawIcons = false
		end
	end
	
	-- If the current mode (potentially after toggling to On or Off above) is dynamic,
	-- check and set the current height so the draw functions have the right height, and
	-- check to see if disticon should be changed because of the height
	if current_mode == "Dynamic" then
		UpdateDynamic()
	end
end

function widget:UnitCreated(unitID, unitDefID)
	addUnitIcon(unitID, unitDefID)
end

function widget:UnitTaken(unitID, unitDefID, oldTeamID, teamID)
	UpdateUnitIconTeam(unitID, unitDefID, teamID)
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	UpdateUnitIconTeam(unitID, unitDefID, newTeamID)
end

function widget:UnitEnteredLos(unitID)
	-- The unsynced version doesn't provide unitDefID so we have to fetch it
	-- Maybe later add caching for unitID -> unitDefID to save an engine call
	-- (but note that the cached value can be wrong under rare circumstances)
	local unitDefID = unitID and spGetUnitDefID(unitID)
	addUnitIcon(unitID, unitDefID)
end

function widget:UnitLeftLos(unitID)
	if not spGetSpectatingState() then
		removeUnitIcon(unitID)
	end
end

function widget:UnitDestroyed(unitID)
	removeUnitIcon(unitID)
end

function widget:DrawWorld()
	DrawWorldFunc()
end

function widget:DrawWorldRefraction()
	DrawWorldFunc()
end
