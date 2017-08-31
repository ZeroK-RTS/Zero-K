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
local iconsize = 25
local iconoffset = 0

-- Flags and switches
local waiting_on_double
local current_mode
local target_mode
local showing_icons

-- Variables
local kp_timer
local testHeight = 0

-- Constants
local clearing_table = {
	name = 'radaricon',
	texture = nil
}

-- Initialized arrays
local iconTypeCache = {}
local iconUnitTexture = {}
local textureData = {}
local textureColors = {}
local textureSizes = {}
local unitHeights = {}

-- Forward function declarations
local GotHotkeypress = function() end
local UpdateDynamic = function() end
local UpdateUnitIcon = function() end
local SetUnitIcon = function() end

-- Localized Spring functions
local echo = Spring.Echo

local spGetSpectatingState = Spring.GetSpectatingState
local spSendCommands	= Spring.SendCommands
local spGetTimer	= Spring.GetTimer
local spIsGUIHidden	= Spring.IsGUIHidden
local spDiffTimers	= Spring.DiffTimers

local spGetAllUnits	= Spring.GetAllUnits
local spGetVisibleUnits	= Spring.GetVisibleUnits
local spGetUnitDefID	= Spring.GetUnitDefID
local spIsUnitInView	= Spring.IsUnitInView
local spGetUnitViewPosition = Spring.GetUnitViewPosition
local spIsUnitSelected	= Spring.IsUnitSelected
local spGetUnitTeam	= Spring.GetUnitTeam
local spGetTeamColor	= Spring.GetTeamColor

local spGetUnitHeight	= Spring.GetUnitHeight

local spGetCameraState	= Spring.GetCameraState
local spGetGroundHeight	= Spring.GetGroundHeight

local glDepthTest	= gl.DepthTest
local glDepthMask	= gl.DepthMask
local glAlphaTest	= gl.AlphaTest
local glTexture		= gl.Texture
local glTexRect		= gl.TexRect
local glTranslate	= gl.Translate
local glBillboard	= gl.Billboard
local glDrawFuncAtUnit	= gl.DrawFuncAtUnit
local glPushMatrix	= gl.PushMatrix
local glPopMatrix	= gl.PopMatrix

local GL_GREATER = GL.GREATER

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Includes
--

include("keysym.h.lua")
local iconTypesPath = LUAUI_DIRNAME .. "Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)
local _, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Options
--

options_path = 'Settings/Graphics/Unit Visibility'

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

	lblIconTransition = {name='Icon Transition Widget', type='label'},
	icontransitiontop = {
		name = 'Icon Transition Top',
		desc = 'If the camera is above this height, units will be icons only.\n\nOnly applies when the icon display mode is set to Dynamic.\n\nThis setting overrides Icon Distance.',
		type = 'number',
		min = 0, max = 10000,
		value = 2500,
	},
	icontransitionbottom = {
		name = 'Icon Transition Bottom',
		desc = 'If the camera is below this height, units will be models only.\n\nOnly applies when the icon display mode is set to Dynamic.\n\nThis setting overrides Icon Distance.',
		type = 'number',
		min = 0, max = 10000,
		value = 500,
	},
	icontransitionmaxsize = {
		name = 'Icon Transition Max Size',
		desc = 'Size of the icons when the transition begins.',
		type = 'number',
		min = 1, max = 250,
		value = 100,
	},
	icontransitionminsize = {
		name = 'Icon Transition Min Size',
		desc = 'Size of the icons when the transition ends.',
		type = 'number',
		min = 1, max = 250,
		value = 20,
	},
	icontransitionmaxopacity = {
		name = 'Icon Transition Max Opacity',
		desc = 'Opacity of the icons when the transition begins.',
		type = 'number',
		min = 0, max = 100,
		value = 70,
	},
	icontransitionminopacity = {
		name = 'Icon Transition Min Opacity',
		desc = 'Opacity of the icons when the transition ends.',
		type = 'number',
		min = 0, max = 100,
		value = 20,
	},
	iconmodehotkey = {
		name = "Icon Mode Hotkey",
		desc = "Define a hotkey to switch between icon display modes (On/Off/Dynamic).\n\nSingle-press to switch between On/Off.\n\nDouble-press to switch to Dynamic.",
		type = 'button',
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
		if current_mode == "On" then target_mode = "Off"
		elseif current_mode == "Off" then target_mode = "On"
		elseif showing_icons then target_mode = "Off"
		else target_mode = "On"
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
	if showing_icons and testHeight < options.icontransitiontop.value - tolerance then
		spSendCommands("disticon " .. 100000)
		showing_icons = false
	elseif not showing_icons and testHeight > options.icontransitiontop.value + tolerance then
		spSendCommands("disticon " .. 0)
		showing_icons = true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Loading the icon data from config files
-- Setting icon data per unit
--

local function GetUnitIcon(unitDefID)
	if unitDefID and iconTypeCache[unitDefID] then
		return iconTypeCache[unitDefID]
	end
	local ud = UnitDefs[unitDefID]
	if not ud then 
		return 
	end
	iconTypeCache[unitDefID] = {}
	iconTypeCache[unitDefID].bitmap = icontypes[(ud and ud.iconType or "default")].bitmap or 'icons/' .. ud.iconType .. iconFormat
	iconTypeCache[unitDefID].size = icontypes[(ud and ud.iconType or "default")].size or 1.8
	return iconTypeCache[unitDefID]
end

function UpdateUnitIcon (unitID)
	local team, teamcolor, uniticon, bitmap, size, udid
	team = unitID and spGetUnitTeam(unitID)
	teamcolor = team and {spGetTeamColor(team)}
	udid = unitID and spGetUnitDefID(unitID)
	uniticon = GetUnitIcon(udid)
	bitmap = uniticon and uniticon.bitmap or 'icons/default.dds'
	size = uniticon and uniticon.size or 1.8
	SetUnitIcon (unitID, {
		name = 'radaricon',
		texture = bitmap,
		size = size,
		color = teamcolor,
	})
end

function SetUnitIcon( unitID, data )
	local iconName = data.name
	local texture = data.texture
	local color = data.color
	local size = data.size
	
	local oldTexture = iconUnitTexture[iconName] and iconUnitTexture[iconName][unitID]
	if oldTexture then
		textureData[oldTexture][iconName][unitID] = nil
		iconUnitTexture[iconName][unitID] = nil
	end
	if not texture then
		return
	end
	
	if not textureData[texture] then
		textureData[texture] = {}
	end
	if not textureData[texture][iconName] then
		textureData[texture][iconName] = {}
	end
	textureData[texture][iconName][unitID] = 0
	
	if color then
		if not textureColors[unitID] then
			textureColors[unitID] = {}
		end
		textureColors[unitID][iconName] = color
	end
	
	if size then
		if not textureSizes[unitID] then
			textureSizes[unitID] = {}
		end
		textureSizes[unitID][iconName] = size
	end
	
	if not iconUnitTexture[iconName] then
		iconUnitTexture[iconName] = {}
	end
	iconUnitTexture[iconName][unitID] = texture
	
	if not unitHeights[unitID] then
		local ud = UnitDefs[spGetUnitDefID(unitID)]
		if (ud == nil) then
			unitHeights[unitID] = nil
		else
			unitHeights[unitID] = spGetUnitHeight(unitID) + iconoffset
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Drawing
--

local function DrawUnitFunc(xshift, yshift, size)
	size = size or 1
	glTranslate(0,yshift,0)
	glBillboard()
	glTexRect(xshift - iconsize*size*0.5, -iconsize*size*0.5, xshift + iconsize*size*0.5, iconsize*size*0.5)
end

local function DrawWorldFunc()
	if spIsGUIHidden() then return end
	if showing_icons then return end
	if current_mode ~= "Dynamic" then return end
	if testHeight < options.icontransitionbottom.value then return end
	
	iconsize = options.icontransitionminsize.value + (options.icontransitionmaxsize.value - options.icontransitionminsize.value) * (testHeight - options.icontransitionbottom.value) / (options.icontransitiontop.value - options.icontransitionbottom.value)
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
	for k,v in pairs(unitsInView) do
		unitIsInView[v] = true
	end
	
	for texture, curTextureData in pairs(textureData) do
		for iconName, units in pairs(curTextureData) do
			glTexture(texture)
			for unitID,xshift in pairs(units) do
--				local unitInView = spIsUnitInView(unitID)
--				if unitInView and xshift and unitHeights and unitHeights[unitID] then
				if unitIsInView[unitID] and xshift and unitHeights and unitHeights[unitID] then
					local textureColor = textureColors[unitID] and textureColors[unitID][iconName]
					local size = textureSizes[unitID] and textureSizes[unitID][iconName]
					if spIsUnitSelected(unitID) then
						gl.Color(1,1,1,opacity)
					elseif textureColor then
						gl.Color( textureColor[1], textureColor[2], textureColor[3], textureColor[4] * opacity )
					else
						gl.Color(1,1,1,opacity)
					end
					glDrawFuncAtUnit(unitID, false, DrawUnitFunc,xshift,unitHeights[unitID]/2,size)
						-- try making this ^ true (boolean midPos) and see what happens
					gl.Color(1,1,1,1)
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

	WG.icons.SetOrder ('radaricon', 100000)

	local allUnits = spGetAllUnits()
	for _,unitID in pairs (allUnits) do
		UpdateUnitIcon (unitID)
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
				spSendCommands("disticon " .. 100000)
				showing_icons = false
				current_mode = "Off"
			end
			target_mode = nil
			kp_timer = nil
			waiting_on_double = nil
		end
	end
	
	-- If the current mode (potentially after toggling to On or Off above) is dynamic,
	-- check and set the current height so the draw functions have the right height, and
	-- check to see if disticon should be changed because of the height
	if current_mode == "Dynamic" then
		UpdateDynamic()
	end
end

function widget:UnitCreated(unitID)
	UpdateUnitIcon(unitID)
end

function widget:UnitEnteredLos(unitID)
	UpdateUnitIcon(unitID)
end

function widget:UnitLeftLos(unitID)
	if not spGetSpectatingState() then
		SetUnitIcon(unitID, clearing_table)
	end
end

function widget:UnitDestroyed(unitID)
	SetUnitIcon(unitID, clearing_table)
end

function widget:DrawWorld()
	DrawWorldFunc()
end

function widget:DrawWorldRefraction()
	DrawWorldFunc()
end

