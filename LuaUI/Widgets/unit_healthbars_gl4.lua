-- $Id: unit_healthbars.lua 4481 2009-04-25 18:38:05Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007, 2008, 2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "HealthBars GL4",
		desc      = "Gives various information about units in form of bars. Draws them with GL4; enables HealthBars when GL4 is not available.",
		author    = "jK",
		date      = "2009", --2013 May 12
		license   = "GNU GPL, v2 or later",
		layer     = -11, -- above gui_selectedunits_gl4, below gui_name_tags 
		enabled   = true, --  loaded by default?
		handler   = true, -- to enable and disable HealthBars while widgets load
	}
end

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local barHeight = 3
local barWidth  = 14  --// (barWidth)x2 total width!!!
local barAlpha  = 0.9

local featureBarHeight = 3
local featureBarWidth  = 10
local featureBarAlpha  = 0.6

local drawBarTitles = true
local drawBarPercentages = true
local titlesAlpha   = 0.3*barAlpha

local drawFullHealthBars = false

local drawFeatureHealth  = false
local featureTitlesAlpha = featureBarAlpha * titlesAlpha/barAlpha
local featureHpThreshold = 0.85

local barScale = 1

local drawStunnedOverlay = true
local drawUnitsOnFire    = Spring.GetGameRulesParam("unitsOnFire")

local gameSpeed = Game.gameSpeed

local TELEPORT_CHARGE_NEEDED = Spring.GetGameRulesParam("pw_teleport_time") or gameSpeed*60

local stockpileH = 24
local stockpileW = 12

local DISARM_DECAY_FRAMES = 1200

local destructableFeature = {}
local drawnFeature = {}
for i = 1, #FeatureDefs do
	destructableFeature[i] = FeatureDefs[i].destructable
	drawnFeature[i] = (FeatureDefs[i].drawTypeString == "model")
end

local addPercent
local addTitle

local myAllyTeamID = Spring.GetLocalAllyTeamID()
local spectating = Spring.GetSpectatingState()

--------------------------------------------------------------------------------
-- LOCALISATION
--------------------------------------------------------------------------------

-- messages are populated by localization.
local messages = {
	-- Units
	shield = "",
	health = "",
	building = "",
	morph = "",
	stockpile = "",
	paralyze = "",
	disarm = "",
	capture = "",
	capture_reload = "",
	teleport = "",
	teleport_pw = "",
	ability = "",
	heat = "",
	speed = "",
	reload = "",
	reammo = "",
	slow = "",
	goo = "",
	jump = "",
	jump_charge = "",

	-- Features
	reclaim = "",
	resurrect = "",
}

local function languageChanged ()
	for key, value in pairs(messages) do
		messages[key] = WG.Translate("interface", key .. "_bar")
	end
end

--------------------------------------------------------------------------------
-- OPTIONS
--------------------------------------------------------------------------------
-- GL4 path: re-gather the bars of every tracked unit/feature in the next pass
-- (options, player or tracking state changed).
local gl4ForceFullUnits = true
local gl4ForceFullFeatures = true

local function OptionsChanged()
	gl4ForceFullUnits = true
	gl4ForceFullFeatures = true
	drawFeatureHealth = options.drawFeatureHealth.value
	drawBarPercentages = options.drawBarPercentages.value
	barScale = options.barScale.value
	debugMode = options.debugMode.value


	barWidth = options.barWidth.value
	barHeight = options.barHeight.value
	healthbarDistSq    = options.unitMaxHeight.value*options.unitMaxHeight.value
	healthbarPercentSq = options.unitPercentHeight.value*options.unitPercentHeight.value
	healthbarTitleSq   = options.unitTitleHeight.value*options.unitTitleHeight.value
	
	featureDistSq      = options.featureMaxHeight.value*options.featureMaxHeight.value
	featurePercentSq   = options.featurePercentHeight.value*options.featurePercentHeight.value
	featureTitleSq     = options.featureTitleHeight.value*options.featureTitleHeight.value
end

options_path = 'Settings/Interface/Healthbars'
options_order = { 'showhealthbars', 'drawFeatureHealth', 'drawBarPercentages', 'flashJump', 'showEnemyStatus',
	'barScale','barWidth','barHeight','debugMode', 'minReloadTime',
	'unitMaxHeight', 'unitPercentHeight', 'unitTitleHeight',
	'featureMaxHeight', 'featurePercentHeight', 'featureTitleHeight',
	'invert_shield', 'invert_health', 'invert_building', 'invert_morph',
	'invert_stockpile', 'invert_paralyze', 'invert_disarm', 'invert_capture',
	'invert_capture_reload', 'invert_teleport', 'invert_teleport_pw', 'invert_ability',
	'invert_heat', 'invert_speed', 'invert_reload', 'invert_reammo',
	'invert_slow', 'invert_goo', 'invert_jump', 'invert_jump_charge', 'invert_reclaim', 'invert_resurrect',
}
options = {

	showhealthbars = {
		name = 'Show Healthbars',
		type = 'bool',
		value = true,
		--OnChange = function() Spring.SendCommands{'showhealthbars'} end,
	},
	drawFeatureHealth = {
		name = 'Draw health of features (corpses)',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Shows healthbars on corpses',
		OnChange = OptionsChanged,
	},
	drawBarPercentages = {
		name = 'Draw percentages',
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Shows percentages next to bars',
		OnChange = OptionsChanged,
	},
	flashJump = {
		name = 'Jump reload flash',
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Set jump reload to flash when issuing the jump command',
	},
	showEnemyStatus = {
		name = 'Show enemy status',
		type = 'bool',
		value = false,
		desc = 'A few rare units (eg Detriment jump charge) show their status to enemies.',
		OnChange = OptionsChanged,
	},
	barScale = {
		name = 'Bar size scale',
		type = 'number',
		value = 1,
		min = 0.5,
		max = 6,
		step = 0.25,
		OnChange = OptionsChanged,
	},
	barWidth = {
		name = 'Bar width',
		type = 'number',
		value = 14,
		min  = 2.5,
		step = 0.25,
		max = 30,
		OnChange = OptionsChanged,
	},	
	barHeight = {
		name = 'Bar Height',
		type = 'number',
		value= 3,
		min  = 1,
		step = 0.1,
		max = 5,
		OnChange = OptionsChanged,
	},
	minReloadTime = {
		name = 'Min reload time',
		type = 'number',
		value = 3,
		min = 1,
		max = 10,
		step = 1,
		desc = 'Min reload time (sec)',
		OnChange = OptionsChanged,
	},
	debugMode = {
		name = 'Debug Mode',
		type = 'bool',
		value = false,
		advanced = true,
		noHotkey = true,
		desc = 'Pings units with debug information',
		OnChange = OptionsChanged,
	},
	unitMaxHeight = {
		name = 'Unit Bar Fade Height',
		desc = 'If the camera is above this height, health bars will not be drawn.',
		type = 'number',
		min = 0, max = 10000, step = 50,
		value = 3000,
		OnChange = OptionsChanged,
	},
	unitPercentHeight = {
		name = 'Unit Bar Percentage Height',
		desc = 'If the camera is above this height, health bar percentages will not be drawn.',
		type = 'number',
		min = 0, max = 7000, step = 50,
		value = 700,
		OnChange = OptionsChanged,
	},
	unitTitleHeight = {
		name = 'Unit Bar Title Heightt',
		desc = 'If the camera is above this height, health bar titles will not be drawn.',
		type = 'number',
		min = 0, max = 7000, step = 50,
		value = 500,
		OnChange = OptionsChanged,
	},
	featureMaxHeight = {
		name = 'Wreckage Bar Fade Height',
		desc = 'If the camera is above this height, health bars will not be drawn.',
		type = 'number',
		min = 0, max = 7000, step = 50,
		value = 2200,
		OnChange = OptionsChanged,
	},
	featurePercentHeight = {
		name = 'Wreckage Bar Percentage Height',
		desc = 'If the camera is above this height, health bar percentages will not be drawn.',
		type = 'number',
		min = 0, max = 7000, step = 50,
		value = 500,
		OnChange = OptionsChanged,
	},
	featureTitleHeight = {
		name = 'Wreckage Bar Title Heightt',
		desc = 'If the camera is above this height, health bar titles will not be drawn.',
		type = 'number',
		min = 0, max = 7000, step = 50,
		value = 500,
		OnChange = OptionsChanged,
	},
	invert_shield = {
		name = 'Invert shield bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert shield bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_health = {
		name = 'Invert health bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert health bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_building = {
		name = 'Invert building bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert building bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_morph = {
		name = 'Invert morph bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert morph bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_stockpile = {
		name = 'Invert stockpile bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert stockpile bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_paralyze = {
		name = 'Invert paralyze bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert paralyze bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_disarm = {
		name = 'Invert disarm bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert disarm bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_capture = {
		name = 'Invert capture bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert capture bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_capture_reload = {
		name = 'Invert capture_reload bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert capture_reload bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_teleport = {
		name = 'Invert teleport bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert teleport bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_teleport_pw = {
		name = 'Invert teleport_pw bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert teleport_pw bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_ability = {
		name = 'Invert ability bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert ability bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_heat = {
		name = 'Invert heat bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert heat bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_speed = {
		name = 'Invert speed bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert speed bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_reload = {
		name = 'Invert reload bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert reload bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_reammo = {
		name = 'Invert reammo bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert reammo bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_slow = {
		name = 'Invert slow bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert slow bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_goo = {
		name = 'Invert goo bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert goo bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_jump = {
		name = 'Invert jump bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert jump bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_jump_charge = {
		name = 'Invert jump charge bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert jump bar for additional charges',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_reclaim = {
		name = 'Invert reclaim bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert reclaim bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
	invert_resurrect = {
		name = 'Invert resurrect bar',
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Invert resurrect bar',
		OnChange = OptionsChanged,
		path = 'Settings/Interface/Healthbars/Invert'
	},
}
OptionsChanged()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function lowerkeys(t)
	local tn = {}
	for i, v in pairs(t) do
		local typ = type(i)
		if type(v) == "table" then
			v = lowerkeys(v)
		end
		if typ == "string" then
			tn[i:lower()] = v
		else
			tn[i] = v
		end
	end
	return tn
end

local paralyzeOnMaxHealth = Game.paralyzeOnMaxHealth
local empDecline = 1 / Game.paralyzeDeclineRate

local spGetGroundHeight = Spring.GetGroundHeight
local function IsCameraBelowMaxHeight()
	local cs = Spring.GetCameraState()
	if cs.name == "ta" then
		return cs.height < options.unitMaxHeight.value
	elseif cs.name == "ov" then
		return false
	else
		return (cs.py - spGetGroundHeight(cs.px, cs.pz)) < options.unitMaxHeight.value
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// colors
local bkBottom   = { 0.40, 0.40, 0.40, barAlpha }
local bkTop      = { 0.10, 0.10, 0.10, barAlpha }
local hpcolormap = { {0.8, 0.0, 0.0, barAlpha},  {0.8, 0.6, 0.0, barAlpha}, {0.0, 0.70, 0.0, barAlpha} }
local bfcolormap = {}

local fbkBottom   = { 0.40, 0.40, 0.40, featureBarAlpha }
local fbkTop      = { 0.06, 0.06, 0.06, featureBarAlpha }
local fhpcolormap = { {0.8, 0.0, 0.0, featureBarAlpha},  {0.8, 0.6, 0.0, featureBarAlpha}, {0.0, 0.70, 0.0, featureBarAlpha} }

-- durations flash _p and _b colors.
local barColors = {
	-- Units
	shield         = { 0.30, 0.00, 0.90, barAlpha },
	-- healtas colores are in bfcolormap 
        building       = { 0.75, 0.75, 0.75, barAlpha },
        morph          = { 0.60, 0.60, 0.60, barAlpha },
	stockpile      = { 0.50, 0.50, 0.50, barAlpha },
	paralyze       = { 0.50, 0.50, 1.00, barAlpha },
	paralyze_p     = { 0.40, 0.40, 0.80, barAlpha },
	paralyze_b     = { 0.60, 0.60, 0.90, barAlpha },
	disarm         = { 0.50, 0.50, 0.50, barAlpha },
	disarm_p       = { 0.40, 0.40, 0.40, barAlpha },
	disarm_b       = { 0.60, 0.60, 0.60, barAlpha },
	capture        = { 1.00, 0.50, 0.00, barAlpha },
	capture_reload = { 0.00, 0.60, 0.60, barAlpha },
	teleport       = { 0.00, 0.60, 0.60, barAlpha },
	teleport_pw    = { 0.00, 0.60, 0.60, barAlpha },
	ability        = { 0.80, 0.60, 0.00, barAlpha },
	heat           = { 0.80, 0.60, 0.00, barAlpha },
	speed          = { 0.80, 0.60, 0.00, barAlpha },
	reammo         = { 0.00, 0.60, 0.60, barAlpha },
	reload         = { 0.00, 0.60, 0.60, barAlpha },
	slow           = { 0.50, 0.10, 0.70, barAlpha },
	slow_p         = { 0.50, 0.10, 0.70, barAlpha },
	slow_b         = { 0.50, 0.10, 0.70, barAlpha },
	goo            = { 0.40, 0.40, 0.40, barAlpha },
	jump           = { 0.00, 0.80, 0.00, barAlpha },
	jump_charge    = { 0.10, 0.50, 0.20, barAlpha },
	jump_p         = { 0.80, 0.50, 0.00, barAlpha },
	jump_b         = { 0.00, 0.80, 0.00, barAlpha },

	-- Features
	resurrect = { 1.00, 0.50, 0.00, featureBarAlpha },
	reclaim   = { 0.75, 0.75, 0.75, featureBarAlpha },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local blink = false
local blink_j = false
local gameFrame = 0

local cx, cy, cz = 0, 0, 0 --// camera pos

local paraUnits   = {}
local disarmUnits = {}
local onFireUnits = {}
local UnitMorphs  = {}
-- The three lists above are only consumed by DrawOverlays, which is skipped while the
-- GL4 paralyze effect (WG.DrawParalyzedUnitGL4) draws these overlays. Set in DrawWorld.
local gatherOverlays = true

-- True while bars are gathered for the instanced (GL4) path instead of being drawn
-- right away: the bar drawer then also records what the GPU needs (colour kind, the
-- alternate blink colour and frame-linear progress) and skips the text strings.
local gl4Gather = false

-- GL4 path state, see "GL4 (instanced) path" below.
local gl4Ready = false          -- GL4 resources exist
local gl4Active = false         -- the GL4 path draws this frame (set in Update)
local gl4DrawStarted = false    -- a failed draw may already have emitted bars
local initialized = false       -- Initialize got past the GL4 check
local camBelowMaxHeight = false -- IsCameraBelowMaxHeight() of this frame's Update
local InitGL4, ShutdownGL4, ResetGL4, UpdateGL4, DrawWorldGL4, UntrackUnitGL4

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// speedup (there are a lot more localizations, but they are in limited scope cos we are running out of upvalues)
local glColor         = gl.Color
local glMyText        = gl.FogCoord
local floor           = math.floor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local deactivated = false
local function showhealthbars(cmd, line, words)
	if ((words[1])and(words[1] ~= "0"))or(deactivated) then
		widgetHandler:UpdateWidgetCallIn('DrawWorld', widget)
		deactivated = false
	else
		widgetHandler:RemoveWidgetCallIn('DrawWorld', widget)
		deactivated = true
	end
end
options.showhealthbars.OnChange = function(self) showhealthbars(_, _, {self.value and '1' or '0'}) end

function GetColor(colormap, slider)
	local coln = #colormap
	if (slider >= 1) then
		local col = colormap[coln]
		return col[1], col[2], col[3], col[4]
	end
	if (slider < 0) then slider = 0 elseif(slider > 1) then
		slider = 1
	end
	local posn  = 1+(coln-1) * slider
	local iposn = floor(posn)
	local aa    = posn - iposn
	local ia    = 1-aa

	local col1, col2 = colormap[iposn], colormap[iposn+1]

	return col1[1]*ia + col2[1]*aa, col1[2]*ia + col2[2]*aa,
	       col1[3]*ia + col2[3]*aa, col1[4]*ia + col2[4]*aa
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetBarDrawer()
	--//speedup
	local glColor      = gl.Color
	local glText       = gl.Text

	local barsN = 0
	local maxBars = 20
	local bars    = {}
	local barHeightL = barHeight + 2
	local barStart   = -(barWidth + 1)
	local fBarHeightL = featureBarHeight + 2
	local fBarStart   = -(featureBarWidth + 1)

	for i = 1, maxBars do
		bars[i] = {}
	end

	--//speedup
	local GL_QUADS        = GL.QUADS
	local glVertex        = gl.Vertex
	local glBeginEnd      = gl.BeginEnd
	local glMultiTexCoord = gl.MultiTexCoord
	local glTexRect       = gl.TexRect
	local glTexture       = gl.Texture
	local glCallList      = gl.CallList
	local glText          = gl.Text

	local function DrawGradient(left, top, right, bottom, topclr, bottomclr)
		glColor(bottomclr)
		glVertex(left, bottom)
		glVertex(right, bottom)
		glColor(topclr)
		glVertex(right, top)
		glVertex(left, top)
	end

	local brightClr = {}
	-- Background + progress quads of one bar in a single glBeginEnd (same vertices, same order).
	local function DrawBarQuads(drawBackground, progress_pos, top, offsetY, width, bgTop, bgBottom, color)
		if drawBackground then
			DrawGradient(progress_pos, top, width, offsetY, bgTop, bgBottom)
		end
		DrawGradient(-width, top, progress_pos, offsetY, brightClr, color)
	end

	local function DrawUnitBar(offsetY, percent, color)
		brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
		local progress_pos = -barWidth + barWidth*2*percent
		local bar_Height  = barHeight+offsetY
		glBeginEnd(GL_QUADS, DrawBarQuads, percent < 1, progress_pos, bar_Height, offsetY, barWidth, bkTop, bkBottom, color)
	end

	local function DrawFeatureBar(offsetY, percent, color)
		brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
		local progress_pos = -featureBarWidth+featureBarWidth*2*percent
		glBeginEnd(GL_QUADS, DrawBarQuads, true, progress_pos, featureBarHeight+offsetY, offsetY, featureBarWidth, fbkTop, fbkBottom, color)
	end

	local externalFunc = {}

	function externalFunc.DrawStockpile(numStockpiled, numStockpileQued, freeStockpile)
		--// DRAW STOCKPILED MISSLES
		glColor(1, 1, 1, 1)
		glTexture("LuaUI/Images/nuke.png")
		local xoffset = barWidth+16
		for i = 1, ((numStockpiled > 3) and 3) or numStockpiled do
			glTexRect(xoffset, -(11*barHeight-2)-stockpileH, xoffset-stockpileW, -(11*barHeight-2))
			xoffset = xoffset-8
		end
		glTexture(false)
		if freeStockpile then
			glText(numStockpiled, barWidth + 1.7, -(11*barHeight - 2) - 16, 7.5, "cno")
		else
			glText(numStockpiled .. '/' .. (numStockpiled + numStockpileQued), barWidth + 1.7, -(11*barHeight-2)-16, 7.5, "cno")
		end
	end

	local invertKey   = {} -- status -> "invert_" .. status
	local percentText = {} -- floor(percent*100) -> "NN%"
	local durationColors = {} -- status -> {status_p colour, status_b colour}

	-- GL4 extras (only while gl4Gather): barInfo.kind selects the colour on the GPU
	-- (0: c1, 1: duration bar blinking c1 = "_p" / c2 = "_b", 2: jump flash c1 = jump_b / c2 = jump_p)
	-- and progress = pa + pb*(pend - gameFrame). Bars whose value is a linear function of
	-- the game frame pass percent == timerBase + timerSlope*(timerEnd - gameFrame), so the
	-- GPU can advance them every frame without uploads. Everything else has pb = 0.
	function externalFunc.AddPercentBar(status, percent, color, textOverride, timerEnd, timerBase, timerSlope)
		barsN = barsN + 1
		local barInfo = bars[barsN]
		local progress = percent
		local key = invertKey[status]
		if not key then
			key = "invert_" .. status
			invertKey[status] = key
		end
		local inverted = options[key].value
		if inverted then
			progress = 1 - progress
		end
		if barInfo then
			barInfo.title    = addTitle and messages[status]
			barInfo.progress = progress
			barInfo.color    = color or barColors[status]
			if gl4Gather then
				barInfo.text   = false
				barInfo.status = status
				if (status == "jump") and not color then
					barInfo.kind, barInfo.c1, barInfo.c2 = 2, barColors.jump_b, barColors.jump_p
				else
					barInfo.kind, barInfo.c1, barInfo.c2 = 0, barInfo.color, barInfo.color
				end
				if timerEnd then
					if inverted then
						barInfo.pa, barInfo.pb = 1 - timerBase, -timerSlope
					else
						barInfo.pa, barInfo.pb = timerBase, timerSlope
					end
					barInfo.pend = timerEnd
				else
					barInfo.pa, barInfo.pb, barInfo.pend = progress, 0, 0
				end
				return
			end
			local text = addPercent
			if addPercent then
				text = textOverride
				if not text then
					local p = floor(percent*100)
					text = percentText[p]
					if not text then
						text = p .. '%'
						if p > 0 and p <= 100 then -- Bound the cache; preserve signed zero and unusual values.
							percentText[p] = text
						end
					end
				end
			end
			barInfo.text     = text
		end
	end

	function externalFunc.AddDurationBar(status, duration)
		barsN = barsN + 1
		local barInfo = bars[barsN]
		if barInfo then
			barInfo.title    = addTitle and messages[status]
			barInfo.progress = 1
			if gl4Gather then
				local dc = durationColors[status]
				if not dc then
					dc = {barColors[status .. "_p"], barColors[status .. "_b"]}
					durationColors[status] = dc
				end
				barInfo.color  = dc[1]
				barInfo.text   = false
				barInfo.status = status
				barInfo.kind, barInfo.c1, barInfo.c2 = 1, dc[1], dc[2]
				barInfo.pa, barInfo.pb, barInfo.pend = 1, 0, 0
				return
			end
			barInfo.color    = barColors[(status .. ((blink and "_b") or "_p"))]
			barInfo.text     = addPercent and floor(duration) .. 's'
		end
	end

	function externalFunc.HasBars()
		return (barsN ~= 0)
	end

	-- Hands the gathered bars to the GL4 path instead of drawing them.
	function externalFunc.TakeBars()
		local n = barsN
		barsN = 0
		if n > maxBars then
			n = maxBars
		end
		return bars, n
	end

	-- Row spacing as used by DrawBars/DrawBarsFeature (fixed when the drawer is created).
	function externalFunc.GetRowSteps()
		return barHeightL, fBarHeightL
	end

	function externalFunc.DrawBars()
		local yoffset = 0
		for i = 1, barsN do
			local barInfo = bars[i]
			DrawUnitBar(yoffset, barInfo.progress, barInfo.color)
			if (drawBarPercentages and barInfo.text) then
				glColor(1, 1, 1, barAlpha)
				glText(barInfo.text, barStart, yoffset, 4, "r")
			end
			if (drawBarTitles and barInfo.title) then
				glColor(1, 1, 1, titlesAlpha)
				glText(barInfo.title, 0, yoffset, 2.5, "cd")
			end
			yoffset = yoffset - barHeightL
		end

		barsN = 0 --//reset!
	end

	function externalFunc.DrawBarsFeature()
		local yoffset = 0
		for i = 1, barsN do
			local barInfo = bars[i]
			DrawFeatureBar(yoffset, barInfo.progress, barInfo.color)
			if (drawBarPercentages and barInfo.text) then
				glColor(1, 1, 1, featureBarAlpha)
				glText(barInfo.text, fBarStart, yoffset, 4, "r")
			end
			if (drawBarTitles and barInfo.title) then
				glColor(1, 1, 1, featureTitlesAlpha)
				glText(barInfo.title, 0, yoffset, 2.5, "cd")
			end
			yoffset = yoffset - fBarHeightL
		end

		barsN = 0 --//reset!
	end
	
	return externalFunc
end --//end GetBarDrawer

local barDrawer = GetBarDrawer()

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawUnitInfos
local JustGetOverlayInfos
local GetUnitCustomInfo
local GatherUnitBarsGL4

do
	--//speedup
	local glTranslate     = gl.Translate
	local glPushMatrix    = gl.PushMatrix
	local glPopMatrix     = gl.PopMatrix
	local glBillboard     = gl.Billboard
	local GetUnitIsStunned     = Spring.GetUnitIsStunned
	local GetUnitHealth        = Spring.GetUnitHealth
	local GetUnitWeaponState   = Spring.GetUnitWeaponState
	local GetUnitShieldState   = Spring.GetUnitShieldState
	local GetUnitViewPosition  = Spring.GetUnitViewPosition
	local GetUnitStockpile     = Spring.GetUnitStockpile
	local GetUnitRulesParam    = Spring.GetUnitRulesParam
	local GetUnitIsDead        = Spring.GetUnitIsDead

	local ux, uy, uz
	local dx, dy, dz, dist
	local health, maxHealth, paralyzeDamage, capture, build
	local hp, hp100, emp, morph
	local reload, reloaded, reloadFrame
	local numStockpiled, numStockpileQued

	local customInfo = {}
	local ci

	local function AllyOrShouldShowEnemyStatus(unitID)
		if spectating or options.showEnemyStatus.value then
			return true
		end
		return unitID and myAllyTeamID == Spring.GetUnitAllyTeam(unitID)
	end

	function JustGetOverlayInfos(unitID, unitDefID)
		ux, uy, uz = GetUnitViewPosition(unitID)
		if not ux then
			return
		end
		dx, dy, dz = ux-cx, uy-cy, uz-cz
		dist = dx*dx + dy*dy + dz*dz

		if (dist > 9000000) then
			return
		end
		--// GET UNIT INFORMATION
		health, maxHealth, paralyzeDamage = GetUnitHealth(unitID)
		paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage
		if not maxHealth then
			return
		end
		paralyzeDamage = (paralyzeDamage or 0)
		health = (health or 0)

		local empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
		emp = paralyzeDamage/empHP
		hp  = health/maxHealth
		morph = UnitMorphs[unitID]

		if (drawUnitsOnFire)and(GetUnitRulesParam(unitID, "on_fire") == 1) then
			onFireUnits[#onFireUnits+1] = unitID
		end

		--// PARALYZE
		local stunned, _, inbuild = GetUnitIsStunned(unitID)
		if (emp > 0) and ((not morph) or morph.combatMorph) and (emp < 1e8) and (paralyzeDamage >= empHP) then
			if (stunned) then
				paraUnits[#paraUnits+1] = unitID
			end
		end

		--// DISARM
		if not stunned then
			local disarmed = GetUnitRulesParam(unitID, "disarmed")
			if disarmed and disarmed == 1 then
				disarmUnits[#disarmUnits+1] = unitID
			end
		end
	end

	function GetUnitCustomInfo(unitDefID)
		if (not customInfo[unitDefID]) then
			local ud = UnitDefs[unitDefID]
			customInfo[unitDefID] = {
				height        = Spring.Utilities.GetUnitHeight(ud) + 14 + (tonumber(ud.customParams.health_bar_height) or 0),
				canJump       = (ud.customParams.canjump and true) or false,
				jumpCharges   = tonumber(ud.customParams.jump_charges),
				canGoo        = (ud.customParams.grey_goo and true) or false,
				canReammo     = (ud.customParams.reammoseconds and true) or false,
				isPwStructure = (ud.customParams.planetwars_structure and true) or false,
				canCapture    = (ud.customParams.post_capture_reload and true) or false,
				maxShield     = ud.shieldPower - 10,
				canStockpile  = ud.canStockpile,
				gadgetStock   = ud.customParams.stockpiletime,
				scriptReload  = tonumber(ud.customParams.script_reload),
				scriptBurst    = tonumber(ud.customParams.script_burst),
				reloadTime    = ud.reloadTime,
				primaryWeapon = ud.primaryWeapon,
				dyanmicComm   = ud.customParams.dynamic_comm,
				freeStockpile = (ud.customParams.freestockpile and true) or nil,
				specialReload = ud.customParams.specialreloadtime,
				specialRate   = ud.customParams.specialreload_userate,
				heat          = ud.customParams.heat_per_shot,
				speed         = ud.customParams.speed_bar,
			}
			if customInfo[unitDefID].canCapture then
				customInfo[unitDefID].captureReload = tonumber(ud.customParams.post_capture_reload)
			end
		end
		return customInfo[unitDefID]
	end

	-- Adds all bars of one unit to barDrawer (uses the upvalue ci of that unit's def).
	local function GatherUnitBars(unitID)
		--// GET UNIT INFORMATION
		local health, maxHealth, paralyzeDamage, capture, build = GetUnitHealth(unitID)
		paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage
		--if (not health)    then health = -1   elseif(health < 1)    then health = 1    end
		if (not maxHealth)or(maxHealth < 1) then
			maxHealth = 1
		end
		if (not build) then
			build = 1
		end

		local empHP = (not paralyzeOnMaxHealth) and health or maxHealth
		local emp = (paralyzeDamage or 0)/empHP
		local hp  = (health or 0)/maxHealth

		-- health is only read by the health bar, which needs hp < 1 (or drawFullHealthBars)
		if ((hp < 1) or drawFullHealthBars) and GetUnitIsDead(unitID) then
			health = false
		end

		if hp < 0 then
			hp = 0
		end

		morph = UnitMorphs[unitID]

		if gatherOverlays and (drawUnitsOnFire) and (GetUnitRulesParam(unitID, "on_fire") == 1) then
			onFireUnits[#onFireUnits+1] = unitID
		end

		--// BARS //-----------------------------------------------------------------------------
		--// Shield
		if (ci.maxShield > 0) then
			local commShield = GetUnitRulesParam(unitID, "comm_shield_max")
			if commShield then
				if commShield ~= 0 then
					local shieldOn, shieldPower = GetUnitShieldState(unitID, GetUnitRulesParam(unitID, "comm_shield_num"))
					if (shieldOn)and(build == 1)and(shieldPower < commShield) then
						shieldPower = shieldPower / commShield
						barDrawer.AddPercentBar("shield", shieldPower)
					end
				end
			else
				local shieldOn, shieldPower = GetUnitShieldState(unitID)
				if (shieldOn)and(build == 1)and(shieldPower < ci.maxShield) then
					shieldPower = shieldPower / ci.maxShield
					barDrawer.AddPercentBar("shield", shieldPower)
				end
			end
		end

		--// HEALTH
		if (health) and ((drawFullHealthBars)or(hp < 1)) and ((build == 1)or(hp < 0.99 and (build > hp+0.01 or hp > build+0.01)) or (drawFullHealthBars)) then
			hp100 = hp*100; hp100 = hp100 - hp100%1; --//same as floor(hp*100), but 10% faster
			if (hp100 < 0) then hp100 = 0 elseif (hp100 > 100) then
				hp100 = 100
			end
			if (drawFullHealthBars)or(hp100 < 100) then
				barDrawer.AddPercentBar("health", hp, bfcolormap[hp100])
			end
		end

		--// BUILDING
		if (build < 1) then
			barDrawer.AddPercentBar("building", build)
		end

		--// MORPH
		if (morph) then
			barDrawer.AddPercentBar("morph", morph.progress)
		end
		
		--// STOCKPILE
		if (ci.canStockpile) then
			local stockpileBuild
			numStockpiled, numStockpileQued, stockpileBuild = GetUnitStockpile(unitID)
			if ci.gadgetStock then
				stockpileBuild = GetUnitRulesParam(unitID, "gadgetStockpile")
			end
			if numStockpiled and stockpileBuild and (numStockpileQued ~= 0) then
				barDrawer.AddPercentBar("stockpile", stockpileBuild)
			end
		else
			numStockpiled = false
		end
		
		--// PARALYZE
		local paraTime = false
		-- stunned is only read with paralyze damage or for the disarm overlay list
		local stunned = false
		if ((emp > 0) and (emp < 1e8)) or gatherOverlays then
			stunned = GetUnitIsStunned(unitID)
		end
		if (emp > 0) and(emp < 1e8) then
			stunned = stunned and paralyzeDamage >= empHP
			if (stunned) then
				paraTime = (paralyzeDamage-empHP)/(maxHealth*empDecline)
				if gatherOverlays then
					paraUnits[#paraUnits+1] = unitID
				end
				barDrawer.AddDurationBar("paralyze", paraTime)
			else
				if (emp > 1) then
					emp = 1
				end
				barDrawer.AddPercentBar("paralyze", emp)
			end
		end
		
		 --// DISARM
		local disarmFrame = GetUnitRulesParam(unitID, "disarmframe")
		if disarmFrame and disarmFrame ~= -1 and disarmFrame > gameFrame then
			local disarmProp = (disarmFrame - gameFrame)/1200
			if disarmProp < 1 then
				if (not paraTime) and disarmProp > emp + 0.014 then -- 16 gameframes of emp time
					barDrawer.AddPercentBar("disarm", disarmProp, nil, nil, disarmFrame, 0, 1/1200)
				end
			else
				local disarmTime = (disarmFrame - gameFrame - 1200)/gameSpeed
				if (not paraTime) or disarmTime > paraTime + 0.5 then
					barDrawer.AddDurationBar("disarm", disarmTime)
					if gatherOverlays and not stunned then
						disarmUnits[#disarmUnits+1] = unitID
					end
				end
			end
		end
		
		--// CAPTURE (set by capture gadget)
		if ((capture or -1) > 0) then
			barDrawer.AddPercentBar("capture", capture)
		end
		
		--// CAPTURE RECHARGE
		if ci.canCapture then
			local captureReloadState = GetUnitRulesParam(unitID, "captureRechargeFrame")
			if (captureReloadState and captureReloadState > 0) then
				local capture = 1-(captureReloadState-gameFrame)/ci.captureReload
				barDrawer.AddPercentBar("capture_reload", capture, nil, nil, captureReloadState, 1, -1/ci.captureReload)
			end
		end
		
		--// Teleport progress
		local TeleportEnd = GetUnitRulesParam(unitID, "teleportend")
		local TeleportCost = TeleportEnd and GetUnitRulesParam(unitID, "teleportcost")
		if TeleportEnd and TeleportCost and TeleportEnd >= 0 then
			local prog, timerEnd
			if TeleportEnd > 1 then
				-- End frame given
				prog = 1 - (TeleportEnd - gameFrame)/TeleportCost
				timerEnd = TeleportEnd
			else
				-- Same parameters used to display a static progress
				prog = 1 - TeleportEnd
			end
			if prog < 1 then
				barDrawer.AddPercentBar("teleport", prog, nil, nil, timerEnd, 1, timerEnd and -1/TeleportCost)
			end
		end
		
		--// Planetwars teleport progress
		if ci.isPwStructure then
			TeleportEnd = GetUnitRulesParam(unitID, "pw_teleport_frame")
			if TeleportEnd then
				local prog = 1 - (TeleportEnd - gameFrame)/TELEPORT_CHARGE_NEEDED
				if prog < 1 then
					barDrawer.AddPercentBar("teleport_pw", prog, nil, nil, TeleportEnd, 1, -1/TELEPORT_CHARGE_NEEDED)
				end
			end
		end
		
		--// SPECIAL WEAPON / ABILITY
		if ci.specialReload then
			if ci.specialRate then
				local specialReloadProp = GetUnitRulesParam(unitID, "specialReloadRemaining") or 0
				if (specialReloadProp > 0) and (specialReloadProp < 1) then
					local special = 1-specialReloadProp
					barDrawer.AddPercentBar("ability", special)
				end
			
			else
				local specialReloadState = GetUnitRulesParam(unitID, "specialReloadFrame")
				if (specialReloadState and specialReloadState > gameFrame) then
					local special = 1-(specialReloadState-gameFrame)/ci.specialReload -- don't divide by gamespeed, since specialReload is also in gameframes
					barDrawer.AddPercentBar("ability", special, nil, nil, specialReloadState, 1, -1/ci.specialReload)
				end
			end
		end
		
		--// HEAT
		if ci.heat and build == 1 then
			local heatState = GetUnitRulesParam(unitID, "heat_bar")
			if (heatState and heatState > 0) then
				barDrawer.AddPercentBar("heat", heatState)
			end
		end
		
		--// DRP Speed
		if ci.speed and build == 1 then
			local speedState = GetUnitRulesParam(unitID, "speed_bar")
			if (speedState and speedState < 1) then
				barDrawer.AddPercentBar("speed", speedState)
			end
		end
		
		--// REAMMO
		if ci.canReammo then
			local reammoProgress = GetUnitRulesParam(unitID, "ammoFraction") or GetUnitRulesParam(unitID, "reammoProgress")
			if reammoProgress then
				barDrawer.AddPercentBar("reammo", reammoProgress)
			end
		end
		
		--// RELOAD
		if (not ci.scriptReload) and (ci.dyanmicComm or (ci.reloadTime >= options.minReloadTime.value)) and (not ci.canReammo) then
			local primaryWeapon = (ci.dyanmicComm and GetUnitRulesParam(unitID, "primary_weapon_override")) or ci.primaryWeapon
			_, reloaded, reloadFrame = GetUnitWeaponState(unitID, primaryWeapon)
			if (reloaded == false) then
				local reloadTime = GetUnitWeaponState(unitID, primaryWeapon, 'reloadTime')
				if (not ci.dyanmicComm) or (reloadTime >= options.minReloadTime.value) then
					ci.reloadTime = reloadTime
					-- When weapon is disabled the reload time is constantly set to be almost complete.
					-- It results in a bunch of units walking around with 99% reload bars.
					if (reloadFrame > gameFrame + 6) or (GetUnitRulesParam(unitID, "reloadPaused") ~= 1) then -- UPDATE_PERIOD in unit_attributes.lua.
						reload = 1 - ((reloadFrame-gameFrame)/gameSpeed) / ci.reloadTime;
						if (reload >= 0) then
							barDrawer.AddPercentBar("reload", reload, nil, nil, reloadFrame, 1, -1/(gameSpeed*ci.reloadTime))
						end
					end
				end
			end
		end
		
		if ci.scriptReload and (ci.scriptReload >= options.minReloadTime.value) then
			local reloadFrame = GetUnitRulesParam(unitID, "scriptReloadFrame")
			if reloadFrame and reloadFrame > gameFrame then
				local scriptLoaded = GetUnitRulesParam(unitID, "scriptLoaded") or ci.scriptBurst
				local reloadPercentage = GetUnitRulesParam(unitID, "scriptReloadPercentage")
				reload = reloadPercentage or (1 - ((reloadFrame - gameFrame)/gameSpeed) / ci.scriptReload)
				local barText = addPercent and string.format("%i/%i", scriptLoaded, ci.scriptBurst) -- .. ' | ' .. floor(reload*100) .. '%'
				if (reload >= 0) then
					if reloadPercentage then
						barDrawer.AddPercentBar("reload", reload, false, barText)
					else
						barDrawer.AddPercentBar("reload", reload, false, barText, reloadFrame, 1, -1/(gameSpeed*ci.scriptReload))
					end
				end
			end
		end
		
		--// SHEATH
		--local sheathState = GetUnitRulesParam(unitID, "sheathState")
		--if sheathState and (sheathState < 1) then
		--	barDrawer.AddPercentBar("sheath", sheathState)
		--end
		
		--// SLOW
		local slowState = GetUnitRulesParam(unitID, "slowState")
		if (slowState and (slowState > 0)) then
			if slowState > 0.5 then
				barDrawer.AddDurationBar("slow", (slowState - 0.5)*25)
			else
				barDrawer.AddPercentBar("slow", slowState*2, false, addPercent and (floor(slowState*100) .. '%'))
			end
		end
		
		--// GOO
		if ci.canGoo then
			local gooState = GetUnitRulesParam(unitID, "gooState")
			if (gooState and (gooState > 0)) then
				barDrawer.AddPercentBar("goo", gooState)
			end
		end
		
		--// JUMPJET
		if ci.canJump and AllyOrShouldShowEnemyStatus(unitID) then
			local jumpReload = GetUnitRulesParam(unitID, "jumpReload")
			if (jumpReload and (jumpReload > 0) and (jumpReload < 1)) then
				barDrawer.AddPercentBar("jump", jumpReload)
			elseif ci.jumpCharges and jumpReload and (jumpReload < ci.jumpCharges) and (jumpReload >= 1) then
				local barText = addPercent and string.format("%i/%i", math.floor(jumpReload), ci.jumpCharges)
				barDrawer.AddPercentBar("jump_charge", (jumpReload - 1) / (ci.jumpCharges - 1), false, barText)
			end
		end
	end

	function DrawUnitInfos(unitID, unitDefID)
		ci = GetUnitCustomInfo(unitDefID)

		local ux, uy, uz = GetUnitViewPosition(unitID)
		if not ux then
			return
		end
		local dx, dy, dz = ux-cx, uy-cy, uz-cz
		local dist = dx*dx + dy*dy + dz*dz

		if (dist > healthbarDistSq) then
			if gatherOverlays then
				JustGetOverlayInfos(unitID, unitDefID)
			end
			return
		end
		addPercent = (dist < healthbarPercentSq)
		addTitle = (dist < healthbarTitleSq)

		GatherUnitBars(unitID)

		if debugMode then
			local x, y, z = Spring.GetUnitPosition(unitID)
			--Spring.MarkerAddPoint(x, y, z, "N" .. barsN)
		end

		if ((barDrawer.HasBars()) or (numStockpiled)) then
			local heightMult = Spring.GetUnitRulesParam(unitID, "currentModelScale") or 1
			glPushMatrix()
			glTranslate(ux, uy+ci.height*heightMult, uz )
			gl.Scale(barScale, barScale, barScale)
			glBillboard()

			--// STOCKPILE ICON
			if (numStockpiled) then
				barDrawer.DrawStockpile(numStockpiled, numStockpileQued, ci.freeStockpile)
			end

			--// DRAW BARS
			barDrawer.DrawBars()

			glPopMatrix()
		end
	end

	-- Gathers the bars of one unit for the GL4 path (no position, distance or text).
	-- Returns the bar array, the bar count, the height of the bar stack above the unit
	-- base and the unit def's custom info (unitCI: GetUnitCustomInfo(unitDefID), if known).
	function GatherUnitBarsGL4(unitID, unitDefID, unitCI)
		ci = unitCI or GetUnitCustomInfo(unitDefID)
		addPercent = false
		addTitle = false
		gl4Gather = true
		GatherUnitBars(unitID)
		gl4Gather = false
		local bars, n = barDrawer.TakeBars()
		local height = 0
		if n > 0 then
			height = ci.height*(GetUnitRulesParam(unitID, "currentModelScale") or 1)
		end
		return bars, n, height, ci
	end

end --// end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawFeatureInfos
local GatherFeatureBarsGL4

do
	--//speedup
	local glTranslate     = gl.Translate
	local glPushMatrix    = gl.PushMatrix
	local glPopMatrix     = gl.PopMatrix
	local glBillboard     = gl.Billboard
	local GetFeatureHealth     = Spring.GetFeatureHealth
	local GetFeatureResources  = Spring.GetFeatureResources

	local featureDefID
	local health, maxHealth, resurrect, reclaimLeft
	local hp

	local customInfo = {}
	local ci

	local function GetFeatureCustomInfo(featureDefID)
		if (not customInfo[featureDefID]) then
			local featureDef = FeatureDefs[featureDefID or -1] or {height = 0, name = ''}
			customInfo[featureDefID] = {
				height = featureDef.height+14,
			}
		end
		return customInfo[featureDefID]
	end

	-- Adds all bars of one feature to barDrawer.
	local function GatherFeatureBars(featureID)
		health, maxHealth, resurrect = GetFeatureHealth(featureID)
		_, _, _, _, reclaimLeft      = GetFeatureResources(featureID) -- NB: the two resources' progresses are actually separate (goo can drain just M while keeping E)
		if (not resurrect) then
			resurrect = 0
		end
		if (not reclaimLeft) then
			reclaimLeft = 1
		end

		hp = (health or 0)/(maxHealth or 1)

		--// filter all intact features
		if (resurrect == 0) and
			 (reclaimLeft == 1) and
			 (hp > featureHpThreshold) then
			return
		end

		--// BARS //-----------------------------------------------------------------------------
		--// HEALTH
		if (hp < featureHpThreshold)and(drawFeatureHealth) then
			hp100 = hp*100; hp100 = hp100 - hp100%1; --//same as floor(hp*100), but 10% faster
			barDrawer.AddPercentBar("health", hp, bfcolormap[hp100])
		end

		--// RESURRECT
		if (resurrect > 0) then
			barDrawer.AddPercentBar("resurrect", resurrect)
		end

		--// RECLAIMING
		if (reclaimLeft > 0 and reclaimLeft < 1) then
			barDrawer.AddPercentBar("reclaim", reclaimLeft)
		end
	end

	function DrawFeatureInfos(featureID, featureDefID, fx, fy, fz)
		ci = GetFeatureCustomInfo(featureDefID)

		GatherFeatureBars(featureID)

		if barDrawer.HasBars() then
			glPushMatrix()
			glTranslate(fx, fy+ci.height, fz)
			local scale = options.barScale.value or 1
			gl.Scale(barScale, barScale, barScale)
			glBillboard()

			--// DRAW BARS
			barDrawer.DrawBarsFeature()

			glPopMatrix()
		end
	end

	-- Gathers the bars of one feature for the GL4 path. Returns the bar array, the bar
	-- count and the height of the bar stack above the feature position.
	function GatherFeatureBarsGL4(featureID, featureDefID)
		ci = GetFeatureCustomInfo(featureDefID)
		addPercent = false
		addTitle = false
		gl4Gather = true
		GatherFeatureBars(featureID)
		gl4Gather = false
		local bars, n = barDrawer.TakeBars()
		return bars, n, ci.height
	end

end --// end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawOverlays

do
	local GL_TEXTURE_GEN_MODE    = GL.TEXTURE_GEN_MODE
	local GL_EYE_PLANE           = GL.EYE_PLANE
	local GL_EYE_LINEAR          = GL.EYE_LINEAR
	local GL_T                   = GL.T
	local GL_S                   = GL.S
	local GL_ONE                 = GL.ONE
	local GL_SRC_ALPHA           = GL.SRC_ALPHA
	local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
	local glUnit                 = gl.Unit
	local glTexGen               = gl.TexGen
	local glTexCoord             = gl.TexCoord
	local glPolygonOffset        = gl.PolygonOffset
	local glBlending             = gl.Blending
	local glDepthTest            = gl.DepthTest
	local glTexture              = gl.Texture
	local GetCameraVectors       = Spring.GetCameraVectors
	local abs                    = math.abs

	function DrawOverlays()
		--// draw an overlay for stunned or disarmed units
		if (drawStunnedOverlay) and ((#paraUnits > 0) or (#disarmUnits > 0)) then
			glDepthTest(true)
			glPolygonOffset(-2, -2)
			glBlending(GL_SRC_ALPHA, GL_ONE)

			local alpha = ((5.5 * widgetHandler:GetHourTimer()) % 2) - 0.7
			if (#paraUnits > 0) then
				glColor(0, 0.7, 1, alpha/4)
				for i = 1, #paraUnits do
					glUnit(paraUnits[i], true)
				end
			end
			if (#disarmUnits > 0) then
				glColor(0.8, 0.8, 0.5, alpha/6)
				for i = 1, #disarmUnits do
					glUnit(disarmUnits[i], true)
				end
			end
			local shift = widgetHandler:GetHourTimer() / 20

			glTexCoord(0, 0)
			glTexGen(GL_T, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR)
			local cvs = GetCameraVectors()
			local v = cvs.right
			glTexGen(GL_T, GL_EYE_PLANE, v[1]*0.008, v[2]*0.008, v[3]*0.008, shift)
			glTexGen(GL_S, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR)
			v = cvs.forward
			glTexGen(GL_S, GL_EYE_PLANE, v[1]*0.008, v[2]*0.008, v[3]*0.008, shift)

			if (#paraUnits > 0) then
				glTexture("LuaUI/Images/paralyzed.png")
				glColor(0, 1, 1, alpha*1.1)
				for i = 1, #paraUnits do
					glUnit(paraUnits[i], true)
				end
			end
			if (#disarmUnits > 0) then
				glTexture("LuaUI/Images/disarmed.png")
				glColor(0.6, 0.6, 0.2, alpha*0.9)
				for i = 1, #disarmUnits do
					glUnit(disarmUnits[i], true)
				end
			end

			glTexture(false)
			glTexGen(GL_T, false)
			glTexGen(GL_S, false)
			glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
			glPolygonOffset(false)
			glDepthTest(false)

			paraUnits = {}
			disarmUnits = {}
		end

		--// overlay for units on fire
		if (drawUnitsOnFire)and(onFireUnits) then
			glDepthTest(true)
			glPolygonOffset(-2, -2)
			glBlending(GL_SRC_ALPHA, GL_ONE)

			local alpha = abs((widgetHandler:GetHourTimer() % 2)-1)
			glColor(1, 0.3, 0, alpha/4)
			for i = 1, #onFireUnits do
				glUnit(onFireUnits[i], true)
			end

			glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
			glPolygonOffset(false)
			glDepthTest(false)

			onFireUnits = {}
		end
	end

end --//end do


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:PlayerChanged()
	myAllyTeamID = Spring.GetLocalAllyTeamID()
	spectating = Spring.GetSpectatingState()
	gl4ForceFullUnits = true
end

function widget:Initialize()
	if not InitGL4() then
		-- Without GL4 the HealthBars widget draws the bars.
		widgetHandler:EnableWidget("HealthBars")
		widgetHandler:RemoveWidget(widget)
		return
	end
	gl4Ready = true
	initialized = true
	-- Players who had HealthBars enabled would see two sets of bars. Done before the
	-- setup below, because its Shutdown resets the F9 binding and the Morph globals.
	widgetHandler:DisableWidget("HealthBars")

	WG.InitializeTranslation(languageChanged, GetInfo().name)

	--// catch f9
	Spring.SendCommands({"showhealthbars 0"})
	Spring.SendCommands({"showrezbars 0"})
	widgetHandler.actionHandler:AddAction(widget, "showhealthbars", showhealthbars)
	Spring.SendCommands({"unbind f9 showhealthbars"})
	Spring.SendCommands({"bind f9 luaui showhealthbars"})

	--// find real primary weapon and its reloadtime
	for _, ud in pairs(UnitDefs) do
		ud.reloadTime    = 0
		ud.primaryWeapon = 1
		ud.shieldPower   = 0
		local numOverride = ud.customParams.draw_reload_num and tonumber(ud.customParams.draw_reload_num)

		local weapons = ud.weapons
		for i = 1, #weapons do
			local WeaponDefID = weapons[i].weaponDef;
			local WeaponDef   = WeaponDefs[ WeaponDefID ];
			if (WeaponDef.reload > ud.reloadTime) or numOverride == i then
				ud.reloadTime    = WeaponDef.reload
				ud.primaryWeapon = i
				if numOverride == i then
					break
				end
			end
		end
		local shieldDefID = ud.shieldWeaponDef
		ud.shieldPower = ((shieldDefID)and(WeaponDefs[shieldDefID].shieldPower))or(-1)
	end

	--// link morph callins
	widgetHandler:RegisterGlobal(widget, 'MorphUpdate', MorphUpdate)
	widgetHandler:RegisterGlobal(widget, 'MorphFinished', MorphFinished)
	widgetHandler:RegisterGlobal(widget, 'MorphStart', MorphStart)
	widgetHandler:RegisterGlobal(widget, 'MorphStop', MorphStop)

	--// deactivate cheesy progress text
	widgetHandler:RegisterGlobal(widget, 'MorphDrawProgress', function() return true end)

	--// wow, using a buffered list can give 1-2 frames in extreme(!) situations :p
	for hp = 0, 100 do
		bfcolormap[hp] = {GetColor(hpcolormap, hp*0.01)}
	end
end

function widget:Shutdown()
	if not initialized then
		return
	end
	WG.ShutdownTranslation(GetInfo().name)

	--// catch f9
	widgetHandler.actionHandler:RemoveAction(widget, "showhealthbars", showhealthbars)
	Spring.SendCommands({"unbind f9 luaui"})
	Spring.SendCommands({"bind f9 showhealthbars"})
	Spring.SendCommands({"showhealthbars 1"})
	Spring.SendCommands({"showrezbars 1"})

	widgetHandler:DeregisterGlobal(widget, 'MorphUpdate', MorphUpdate)
	widgetHandler:DeregisterGlobal(widget, 'MorphFinished', MorphFinished)
	widgetHandler:DeregisterGlobal(widget, 'MorphStart', MorphStart)
	widgetHandler:DeregisterGlobal(widget, 'MorphStop', MorphStop)

	widgetHandler:DeregisterGlobal(widget, 'MorphDrawProgress')

	if gl4Ready then
		ShutdownGL4()
		gl4Ready = false
		gl4Active = false
	end
end

function widget:UnitCreated(unitID)
	-- A new unit can get the ID of a unit that is still tracked; fetch its engine data again.
	if gl4Active then
		UntrackUnitGL4(unitID)
	end
end

function widget:UnitEnteredLos(unitID)
	-- The unit may have died and its ID been reused while it was out of view.
	if gl4Active then
		UntrackUnitGL4(unitID)
	end
end

function widget:RenderUnitDestroyed(unitID)
	-- The engine frees the unit's uniform slot; another unit may get it. (LuaUI only
	-- gets this for its own allyteam's units unless it has full read; other units
	-- leave the visible list in the same sim frame and are dropped by the next pass,
	-- which runs before the next DrawWorld.)
	if gl4Active then
		UntrackUnitGL4(unitID)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local visibleFeatures = {}
local visibleUnits = {}

--------------------------------------------------------------------------------
-- GL4 (instanced) path
--------------------------------------------------------------------------------
-- Every bar is one point in a VBO (one VBO for units, one for features). A geometry
-- shader expands it into the background and progress quads of the immediate mode
-- path, billboarded at the unit's draw position, which the vertex shader reads from
-- the engine's per-unit uniform buffer (no GetUnitViewPosition calls). Bars are
-- gathered once per simulation frame (their inputs only change then) and only the
-- elements that changed are uploaded. Draw-frame dependent things are evaluated on
-- the GPU: visibility (engine draw flag), distance fading, the blink and jump flash
-- colours and the progress of bars that advance linearly with the game frame
-- (reload & co, see AddPercentBar).
-- Units/features close enough to show text (percentages, titles) and units with a
-- stockpile (icon + count) use immediate mode. Ordered GPU ranges stop around them
-- so overlapping bars keep the original alpha-blending order.
-- Without engine GL4 support, or if the shader fails, the widget enables HealthBars and
-- removes itself (Initialize). If a GL4 update or draw fails later, the immediate mode path draws.
-- The GL4 path is only used while the GL4 paralyze effect draws the stun/disarm/fire
-- overlays (WG.DrawParalyzedUnitGL4); the old overlays need the immediate mode path.
-- (state variables and forward declarations are near the top of the file)

do
	local LuaShader -- loaded on first use (InitGL4)

	local spGetUnitDefID       = Spring.GetUnitDefID
	local spGetUnitRulesParam  = Spring.GetUnitRulesParam
	local spValidFeatureID     = Spring.ValidFeatureID
	local spGetCameraPosition  = Spring.GetCameraPosition
	local glUniform            = gl.Uniform
	local glDepthMask          = gl.DepthMask
	local glMultiTexCoord      = gl.MultiTexCoord
	local GL_POINTS            = GL.POINTS
	local tsort                = table.sort

	local STEP = 20 -- floats per bar element (see BAR_LAYOUT)
	local BAR_LAYOUT = {
		{id = 0, name = "posHeight", size = 4},                      -- xyz: feature position, w: stack height above it
		{id = 1, name = "barInfo",   size = 4},                      -- x: row*4 + colour kind, progress = y + z*(w - gameFrame)
		{id = 2, name = "color1",    size = 4},
		{id = 3, name = "color2",    size = 4},                      -- blink / flash colour
		{id = 4, name = "instData",  size = 4, type = GL.UNSIGNED_INT}, -- units: engine instance data (y: uniform index)
	}
	local INSTDATA_LAYOUT = {
		{id = 0, name = "instData", size = 4, type = GL.UNSIGNED_INT},
	}

	local vsSrc = [==[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 5000

layout (location = 0) in vec4 posHeight;
layout (location = 1) in vec4 barInfo;
layout (location = 2) in vec4 color1;
layout (location = 3) in vec4 color2;
layout (location = 4) in uvec4 instData;

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

struct SUniformsBuffer {
	uint composite; //     u8 drawFlag; u8 unused1; u16 id;

	uint unused2;
	uint unused3;
	uint unused4;

	float maxHealth;
	float health;
	float unused5;
	float unused6;

	vec4 drawPos;
	vec4 speed;
	vec4[4] userDefined; //can't use float[16] because float in arrays occupies 4 * float space
};

layout(std140, binding=1) readonly buffer UniformsBuffer {
	SUniformsBuffer uni[];
};

#line 10000

uniform vec4 distParams;  // x: max dist sq, z: 1 = position from posHeight (features), w: 1 = always draw the background
uniform vec4 blinkParams; // x: duration bar blink, y: jump reload flash

out DataVS {
	vec4 v_anchor; // xyz: origin of the bar stack, w: 1 = draw
	vec4 v_bar;    // x: row, y: progress
	vec4 v_color;
};

void main()
{
	vec3 basePos = posHeight.xyz;
	float drawn = 1.0;
	if (distParams.z < 0.5) {
		basePos = uni[instData.y].drawPos.xyz;
		// drawFlag: only units drawn as a model (not as an icon) in the main view, like Spring.GetVisibleUnits(-1, nil, false)
		if ((uni[instData.y].composite & 0x00000003u) == 0u) {
			drawn = 0.0;
		}
	}

	vec3 toCamera = basePos - cameraViewInv[3].xyz;
	float distSq = dot(toCamera, toCamera);
	if (distSq > distParams.x) {
		drawn = 0.0;
	}

	float row = floor((barInfo.x + 0.5) * 0.25);
	float kind = barInfo.x - row * 4.0;
	float progress = barInfo.y + barInfo.z * (barInfo.w - timeInfo.x);

	vec4 color = color1;
	if (kind > 0.5) {
		float flash = (kind > 1.5) ? blinkParams.y : blinkParams.x;
		if (flash > 0.5) {
			color = color2;
		}
	}

	v_anchor = vec4(basePos.x, basePos.y + posHeight.w, basePos.z, drawn);
	v_bar = vec4(row, progress, 0.0, 0.0);
	v_color = color;
	gl_Position = vec4(basePos, 1.0);
}
]==]

	local gsSrc = [==[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__
layout(points) in;
layout(triangle_strip, max_vertices = 8) out;
#line 20000

uniform vec4 barDims;    // x: half bar width, y: bar height, z: row step, w: bar scale
uniform vec4 bgTop;
uniform vec4 bgBottom;
uniform vec4 distParams; // w: 1 = always draw the background

in DataVS {
	vec4 v_anchor;
	vec4 v_bar;
	vec4 v_color;
} dataIn[];

out DataGS {
	vec4 g_color;
	float g_fogFactor;
};

vec3 anchorPos;
vec3 rightVec;
vec3 upVec;
float fogFactor;

// x, y as in the immediate mode path: in the billboarded, barScale scaled frame
void EmitCorner(float x, float y, vec4 color)
{
	g_color = color;
	g_fogFactor = fogFactor;
	gl_Position = cameraViewProj * vec4(anchorPos + rightVec * x + upVec * y, 1.0);
	EmitVertex();
}

void main()
{
	if (dataIn[0].v_anchor.w < 0.5) {
		return;
	}
	anchorPos = dataIn[0].v_anchor.xyz;
	// DrawWorld enables GL_LINEAR fog for the immediate bars. Its default
	// GL_FRAGMENT_DEPTH source uses absolute eye-space Z, not window depth
	// or radial distance. Billboard corners all have the anchor's eye-space Z.
	float fogDist = abs((cameraView * vec4(anchorPos, 1.0)).z);
	fogFactor = clamp((fogParams.y - fogDist) * fogParams.w, 0.0, 1.0);
	// gl.Billboard: camera right/up axes
	rightVec = cameraViewInv[0].xyz * barDims.w;
	upVec = cameraViewInv[1].xyz * barDims.w;

	float halfWidth = barDims.x;
	float bottom = -dataIn[0].v_bar.x * barDims.z;
	float top = bottom + barDims.y;
	float progress = dataIn[0].v_bar.y;
	float progressPos = -halfWidth + halfWidth * 2.0 * progress;

	// Background first, then the progress gradient (bright top). Fixed function
	// clamps vertex colours, so clamp before interpolation as well.
	if ((distParams.w > 0.5) || (progress < 1.0)) {
		vec4 bgB = clamp(bgBottom, 0.0, 1.0);
		vec4 bgT = clamp(bgTop, 0.0, 1.0);
		EmitCorner(halfWidth, bottom, bgB);
		EmitCorner(halfWidth, top, bgT);
		EmitCorner(progressPos, bottom, bgB);
		EmitCorner(progressPos, top, bgT);
		EndPrimitive();
	}

	vec4 barColor = clamp(dataIn[0].v_color, 0.0, 1.0);
	vec4 brightColor = vec4(clamp(dataIn[0].v_color.rgb * 1.5, 0.0, 1.0), barColor.a);
	EmitCorner(progressPos, bottom, barColor);
	EmitCorner(progressPos, top, brightColor);
	EmitCorner(-halfWidth, bottom, barColor);
	EmitCorner(-halfWidth, top, brightColor);
	EndPrimitive();
}
]==]

	local fsSrc = [==[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

//__ENGINEUNIFORMBUFFERDEFS__
#line 30000

in DataGS {
	vec4 g_color;
	float g_fogFactor;
};

out vec4 fragColor;

void main(void)
{
	fragColor = g_color;
	// Fixed-function fog mixes RGB only; retain bar alpha for source-alpha blending.
	fragColor.rgb = mix(clamp(fogColor.rgb, 0.0, 1.0), g_color.rgb, g_fogFactor);
}
]==]

	local shaderCache = {
		vsSrc = vsSrc,
		gsSrc = gsSrc,
		fsSrc = fsSrc,
		shaderName = "HealthBars GL4",
		uniformInt = {},
		uniformFloat = {},
		shaderConfig = {},
		forceupdate = true,
	}

	local shader
	local locBarDims, locBgTop, locBgBottom, locDist, locBlink
	local unitBuf, featBuf
	local scratchVBO
	local scratchCap = 0
	local unitRowStep, featureRowStep = barDrawer.GetRowSteps()
	-- One dummy vertex (and index): the bar VBO is the instance buffer and every
	-- instance draws that single point. (LuaVAOImpl only keeps its GL VAO between
	-- draws when vertex, index and instance buffers are all attached.)
	local dummyVertVBO, dummyIndexVBO

	----------------------------------------------------------------------------
	-- Bar buffers: a VBO, its VAO and a Lua copy of the contents. Elements are
	-- packed (0 .. used-1); removing one moves the last element into the hole.

	local function NewBarVAO(vbo)
		local vao = gl.GetVAO()
		if not vao then
			return nil
		end
		vao:AttachVertexBuffer(dummyVertVBO)
		vao:AttachInstanceBuffer(vbo)
		vao:AttachIndexBuffer(dummyIndexVBO)
		return vao
	end

	local function NewBarBuffer(cap)
		local vbo = gl.GetVBO(GL.ARRAY_BUFFER, true)
		if not vbo then
			return nil
		end
		vbo:Define(cap, BAR_LAYOUT)
		local vao = NewBarVAO(vbo)
		if not vao then
			vbo:Delete()
			return nil
		end
		local data = {}
		for i = 1, cap*STEP do
			data[i] = 0
		end
		return {
			vbo = vbo,
			vao = vao,
			cap = cap,
			used = 0,
			data = data,   -- copy of the VBO contents, no holes (Upload needs #data)
			owner = {},    -- element -> unitID / featureID
			ownerBar = {}, -- element -> bar index within its owner
			-- element -> colour tables its colour floats were copied from. The colour tables
			-- (barColors, bfcolormap, ...) are never modified, so while the bar still uses the
			-- same table its floats in data are still equal and need no comparison.
			c1ref = {},
			c2ref = {},
			inst = {},     -- owner -> {element of bar 1, element of bar 2, ...}
			count = {},    -- owner -> number of bars
			dirty = {},    -- elements to upload
			dirtyN = 0,
		}
	end

	local function ClearDirty(buf)
		local dirty = buf.dirty
		for i = 1, buf.dirtyN do
			dirty[i] = nil
		end
		buf.dirtyN = 0
	end

	local function ClearBarBuffer(buf)
		buf.used = 0
		buf.owner = {}
		buf.ownerBar = {}
		buf.c1ref = {}
		buf.c2ref = {}
		buf.inst = {}
		buf.count = {}
		ClearDirty(buf)
	end

	local function DeleteBarBuffer(buf)
		if buf.vao then
			buf.vao:Delete()
		end
		if buf.vbo then
			buf.vbo:Delete()
		end
		buf.vao, buf.vbo = nil, nil
	end

	local function GrowBarBuffer(buf, need)
		local cap = buf.cap
		while cap < need do
			cap = cap*2
		end
		local vbo = gl.GetVBO(GL.ARRAY_BUFFER, true)
		if not vbo then
			error("HealthBars GL4: could not create a larger bar buffer")
		end
		vbo:Define(cap, BAR_LAYOUT)
		local vao = NewBarVAO(vbo)
		if not vao then
			vbo:Delete()
			error("HealthBars GL4: could not create a larger bar VAO")
		end
		local data = buf.data
		for i = buf.cap*STEP + 1, cap*STEP do
			data[i] = 0
		end
		if buf.used > 0 then
			vbo:Upload(data, nil, 0, 1, buf.used*STEP)
		end
		DeleteBarBuffer(buf)
		buf.vbo, buf.vao, buf.cap = vbo, vao, cap
		ClearDirty(buf) -- all used elements were just uploaded
	end

	local function MarkDirty(buf, e)
		local n = buf.dirtyN + 1
		buf.dirtyN = n
		buf.dirty[n] = e
	end

	local function RemoveElement(buf, e)
		local last = buf.used - 1
		if e ~= last then
			local data = buf.data
			local dst, src = e*STEP, last*STEP
			for i = 1, STEP do
				data[dst + i] = data[src + i]
			end
			local key, bar = buf.owner[last], buf.ownerBar[last]
			buf.owner[e] = key
			buf.ownerBar[e] = bar
			buf.c1ref[e] = buf.c1ref[last]
			buf.c2ref[e] = buf.c2ref[last]
			buf.inst[key][bar] = e
			MarkDirty(buf, e)
		end
		buf.owner[last] = nil
		buf.ownerBar[last] = nil
		buf.c1ref[last] = nil
		buf.c2ref[last] = nil
		buf.used = last
	end

	-- Writes the n gathered bars of one owner (unit or feature) into its elements,
	-- adding/removing elements when the bar count changed, and marks the elements
	-- whose contents changed for upload. px == nil: the position floats are always 0
	-- (unit buffer), nothing to compare.
	local function CommitBars(buf, key, bars, n, px, py, pz, height, idata)
		local inst = buf.inst[key]
		local old = buf.count[key] or 0
		if n > 0 and not inst then
			inst = {}
			buf.inst[key] = inst
		end
		local data = buf.data
		local c1ref, c2ref = buf.c1ref, buf.c2ref
		for i = 1, n do
			local b = bars[i]
			local e = inst[i]
			local changed = false
			local o
			if not e then
				e = buf.used
				if e >= buf.cap then
					GrowBarBuffer(buf, e + 1)
				end
				buf.used = e + 1
				buf.owner[e] = key
				buf.ownerBar[e] = i
				inst[i] = e
				o = e*STEP
				if idata then
					data[o + 17], data[o + 18], data[o + 19], data[o + 20] = idata[1], idata[2], idata[3], idata[4]
				else
					data[o + 17], data[o + 18], data[o + 19], data[o + 20] = 0, 0, 0, 0
				end
				changed = true
			else
				o = e*STEP
			end

			if px then
				if data[o + 1] ~= px then data[o + 1] = px; changed = true end
				if data[o + 2] ~= py then data[o + 2] = py; changed = true end
				if data[o + 3] ~= pz then data[o + 3] = pz; changed = true end
			end
			if data[o + 4] ~= height then data[o + 4] = height; changed = true end
			local v = (i - 1)*4 + b.kind
			if data[o + 5] ~= v then data[o + 5] = v; changed = true end
			v = b.pa
			if data[o + 6] ~= v then data[o + 6] = v; changed = true end
			v = b.pb
			if data[o + 7] ~= v then data[o + 7] = v; changed = true end
			v = b.pend
			if data[o + 8] ~= v then data[o + 8] = v; changed = true end
			local c = b.c1
			if c1ref[e] ~= c then
				c1ref[e] = c
				if data[o + 9]  ~= c[1] then data[o + 9]  = c[1]; changed = true end
				if data[o + 10] ~= c[2] then data[o + 10] = c[2]; changed = true end
				if data[o + 11] ~= c[3] then data[o + 11] = c[3]; changed = true end
				if data[o + 12] ~= c[4] then data[o + 12] = c[4]; changed = true end
			end
			c = b.c2
			if c2ref[e] ~= c then
				c2ref[e] = c
				if data[o + 13] ~= c[1] then data[o + 13] = c[1]; changed = true end
				if data[o + 14] ~= c[2] then data[o + 14] = c[2]; changed = true end
				if data[o + 15] ~= c[3] then data[o + 15] = c[3]; changed = true end
				if data[o + 16] ~= c[4] then data[o + 16] = c[4]; changed = true end
			end

			if changed then
				MarkDirty(buf, e)
			end
		end
		for i = old, n + 1, -1 do
			RemoveElement(buf, inst[i])
			inst[i] = nil
		end
		if n > 0 then
			buf.count[key] = n
		else
			buf.inst[key] = nil
			buf.count[key] = nil
		end
	end

	-- Uploads the changed elements, merging nearby ones into one call.
	local function FlushBarBuffer(buf)
		local n = buf.dirtyN
		if n == 0 then
			return
		end
		local dirty, used, vbo, data = buf.dirty, buf.used, buf.vbo, buf.data
		if n > 1 then
			tsort(dirty)
		end
		local runStart, runEnd = -1, -1
		for i = 1, n do
			local e = dirty[i]
			dirty[i] = nil
			if e < used then
				if runStart >= 0 and e <= runEnd + 4 then
					if e > runEnd then
						runEnd = e
					end
				else
					if runStart >= 0 then
						vbo:Upload(data, nil, runStart, runStart*STEP + 1, (runEnd + 1)*STEP)
					end
					runStart, runEnd = e, e
				end
			end
		end
		if runStart >= 0 then
			vbo:Upload(data, nil, runStart, runStart*STEP + 1, (runEnd + 1)*STEP)
		end
		buf.dirtyN = 0
	end

	----------------------------------------------------------------------------
	-- Units

	local trackStamp   = {} -- unitID -> stamp of the last visible unit list that contained it
	local trackedCount = 0  -- number of keys in trackStamp
	local unitInstData = {} -- unitID -> engine instance data {matrix offset, uniform index, info, bpose offset}
	local legacyUnits  = {} -- unitID -> unitDefID: drawn by the immediate mode path (stockpile icon)
	local lastEval     = {} -- unitID -> unitPass of its last evaluation
	local newUnits     = {}
	local unitStamp    = 0
	local unitPass     = 0
	local lastUnitList, lastUnitFrame

	local fetchArg
	local function ScratchInstanceData()
		scratchVBO:InstanceDataFromUnitIDs(fetchArg, 0, 0)
	end

	-- Fetches the engine instance data (uniform index etc.) of new units: one
	-- InstanceDataFromUnitIDs into a scratch VBO and one Download for all of them.
	local function FetchInstData(ids, n)
		if n > scratchCap then
			local cap = (scratchCap > 0 and scratchCap) or 64
			while cap < n do
				cap = cap*2
			end
			local vbo = gl.GetVBO(GL.ARRAY_BUFFER, false)
			if not vbo then
				error("could not allocate HealthBars instance-data buffer")
			end
			vbo:Define(cap, INSTDATA_LAYOUT)
			if scratchVBO then
				scratchVBO:Delete()
			end
			scratchVBO, scratchCap = vbo, cap
		end
		fetchArg = ids
		if pcall(ScratchInstanceData) then
			local t = scratchVBO:Download(0, 0, n)
			for i = 1, n do
				local o = (i - 1)*4
				unitInstData[ids[i]] = {t[o + 1], t[o + 2], t[o + 3], t[o + 4]}
			end
		else
			-- a unit is gone already: one at a time
			for i = 1, n do
				local unitID = ids[i]
				fetchArg = unitID
				if pcall(ScratchInstanceData) then
					local t = scratchVBO:Download(0, 0, 1)
					unitInstData[unitID] = {t[1], t[2], t[3], t[4]}
				end
			end
		end
		fetchArg = nil
	end

	function UntrackUnitGL4(unitID)
		if unitBuf and unitBuf.count[unitID] then
			CommitBars(unitBuf, unitID, nil, 0)
		end
		if trackStamp[unitID] then
			trackStamp[unitID] = nil
			trackedCount = trackedCount - 1
		end
		unitInstData[unitID] = nil
		legacyUnits[unitID] = nil
		lastEval[unitID] = nil
	end

	local function EvalUnit(unitID)
		lastEval[unitID] = unitPass
		local unitDefID = spGetUnitDefID(unitID)
		if not unitDefID then
			UntrackUnitGL4(unitID)
			return
		end
		local bars, n, height
		local ci
		if spGetUnitRulesParam(unitID, "no_healthbar") then
			legacyUnits[unitID] = nil
			n = 0
		else
			ci = GetUnitCustomInfo(unitDefID)
			if ci.canStockpile then
				-- stockpile icon and count: drawn by the immediate mode path every frame
				legacyUnits[unitID] = unitDefID
				n = 0
			else
				legacyUnits[unitID] = nil
				bars, n, height = GatherUnitBarsGL4(unitID, unitDefID, ci)
			end
		end
		if n > 0 or unitBuf.count[unitID] then
			CommitBars(unitBuf, unitID, bars, n, nil, nil, nil, height, unitInstData[unitID])
		end
	end

	-- list: Spring.GetVisibleUnits(-1, nil, false) of this frame (a new table whenever
	-- it was refreshed, see LuaUI/cache.lua)
	local EMPTY = {}

	local function UnitPass(list, frame)
		list = list or EMPTY
		local listChanged = (list ~= lastUnitList)
		local frameAdvanced = (frame ~= lastUnitFrame)
		local full = gl4ForceFullUnits
		if not (listChanged or frameAdvanced or full) then
			return
		end
		lastUnitList, lastUnitFrame = list, frame
		gl4ForceFullUnits = false
		unitPass = unitPass + 1

		local doEval = frameAdvanced or full

		if listChanged or full then
			-- New list: stamp it, gather tracked units on the way, collect new ones.
			unitStamp = unitStamp + 1
			local stamp = unitStamp
			local nNew = 0
			for i = 1, #list do
				local unitID = list[i]
				if trackStamp[unitID] then
					trackStamp[unitID] = stamp
					if doEval and lastEval[unitID] ~= unitPass then
						EvalUnit(unitID)
					end
				else
					trackStamp[unitID] = stamp
					trackedCount = trackedCount + 1
					nNew = nNew + 1
					newUnits[nNew] = unitID
				end
			end
			-- Units that left the list (only possible if more are tracked than listed).
			if trackedCount > #list then
				for unitID, s in pairs(trackStamp) do
					if s ~= stamp then
						UntrackUnitGL4(unitID)
					end
				end
			end
			if nNew > 0 then
				FetchInstData(newUnits, nNew)
				for i = 1, nNew do
					local unitID = newUnits[i]
					newUnits[i] = nil
					if unitInstData[unitID] then
						EvalUnit(unitID)
					else
						UntrackUnitGL4(unitID) -- retried with the next list
					end
				end
			end
		elseif doEval then
			for i = 1, #list do
				local unitID = list[i]
				if trackStamp[unitID] and lastEval[unitID] ~= unitPass then
					EvalUnit(unitID)
				end
			end
		end

		FlushBarBuffer(unitBuf)
	end

	----------------------------------------------------------------------------
	-- Features

	local featStamp    = {} -- featureID -> stamp of the last feature list that contained it
	local featEntry    = {} -- featureID -> its {x, y, z, featureID, featureDefID} entry in that list
	local featLastEval = {} -- featureID -> featurePass of its last evaluation
	local newFeatures  = {}
	local featureStamp = 0
	local featurePass  = 0
	local lastFeatureList, lastFeatureFrame

	local function UntrackFeature(featureID)
		if featBuf.count[featureID] then
			CommitBars(featBuf, featureID, nil, 0)
		end
		featStamp[featureID] = nil
		featEntry[featureID] = nil
		featLastEval[featureID] = nil
	end

	local function EvalFeature(featureID)
		featLastEval[featureID] = featurePass
		if not spValidFeatureID(featureID) then
			UntrackFeature(featureID)
			return
		end
		local entry = featEntry[featureID]
		local bars, n, height = GatherFeatureBarsGL4(featureID, entry[5])
		if n > 0 or featBuf.count[featureID] then
			CommitBars(featBuf, featureID, bars, n, entry[1], entry[2], entry[3], height, nil)
		end
	end

	-- list: visibleFeatures, refreshed (as a new table) every 1/3 s by widget:Update
	local function FeaturePass(list, frame)
		list = list or EMPTY
		local listChanged = (list ~= lastFeatureList)
		local frameAdvanced = (frame ~= lastFeatureFrame)
		local full = gl4ForceFullFeatures
		if not (listChanged or frameAdvanced or full) then
			return
		end
		lastFeatureList, lastFeatureFrame = list, frame
		gl4ForceFullFeatures = false
		featurePass = featurePass + 1

		if listChanged or full then
			featureStamp = featureStamp + 1
			local stamp = featureStamp
			local nNew = 0
			for i = 1, #list do
				local entry = list[i]
				local featureID = entry[4]
				if not featStamp[featureID] then
					nNew = nNew + 1
					newFeatures[nNew] = featureID
				end
				featStamp[featureID] = stamp
				featEntry[featureID] = entry
			end
			for featureID, s in pairs(featStamp) do
				if s ~= stamp then
					UntrackFeature(featureID)
				end
			end
			for i = 1, nNew do
				local featureID = newFeatures[i]
				newFeatures[i] = nil
				EvalFeature(featureID)
			end
		end

		-- a refreshed list can move features with bars (new positions)
		local evalAll = frameAdvanced or full
		if evalAll or listChanged then
			local count = featBuf.count
			for i = 1, #list do
				local featureID = list[i][4]
				if featStamp[featureID] and featLastEval[featureID] ~= featurePass and (evalAll or count[featureID]) then
					EvalFeature(featureID)
				end
			end
		end

		FlushBarBuffer(featBuf)
	end

	----------------------------------------------------------------------------
	-- Drawing

	-- Squared distance below which units/features show text and are therefore drawn
	-- by the immediate mode path.
	local function UnitNearSq()
		local sq = healthbarTitleSq
		if drawBarPercentages and healthbarPercentSq > sq then
			sq = healthbarPercentSq
		end
		return sq
	end

	local function FeatureNearSq()
		local sq = featureTitleSq
		if drawBarPercentages and featurePercentSq > sq then
			sq = featurePercentSq
		end
		return sq
	end

	-- The packed buffer changes order when bars disappear. Restore visible-list
	-- order before drawing: alpha blending makes overlapping bars order-sensitive.
	local function OrderBarBuffer(buf, list, features)
		local nextElement = 0
		for i = 1, #list do
			local id = features and list[i][4] or list[i]
			local inst = buf.inst[id]
			for bar = 1, buf.count[id] or 0 do
				local old = inst[bar]
				if old ~= nextElement then
					local otherID, otherBar = buf.owner[nextElement], buf.ownerBar[nextElement]
					local a, b = old*STEP, nextElement*STEP
					for k = 1, STEP do
						buf.data[a+k], buf.data[b+k] = buf.data[b+k], buf.data[a+k]
					end
					buf.owner[old], buf.ownerBar[old] = otherID, otherBar
					buf.owner[nextElement], buf.ownerBar[nextElement] = id, bar
					buf.inst[otherID][otherBar], inst[bar] = old, nextElement
					buf.c1ref[old], buf.c1ref[nextElement] = buf.c1ref[nextElement], buf.c1ref[old]
					buf.c2ref[old], buf.c2ref[nextElement] = buf.c2ref[nextElement], buf.c2ref[old]
					MarkDirty(buf, old)
					MarkDirty(buf, nextElement)
				end
				nextElement = nextElement + 1
			end
		end
	end

	local function DrawRange(buf, first, count, features)
		if count == 0 then return end
		shader:Activate()
		glUniform(locBlink, (blink and 1) or 0, (blink_j and 1) or 0, 0, 0)
		if features then
			glUniform(locBarDims, featureBarWidth, featureBarHeight, featureRowStep, barScale)
			glUniform(locBgTop, fbkTop[1], fbkTop[2], fbkTop[3], fbkTop[4])
			glUniform(locBgBottom, fbkBottom[1], fbkBottom[2], fbkBottom[3], fbkBottom[4])
			glUniform(locDist, featureDistSq, 0, 1, 1)
		else
			glUniform(locBarDims, barWidth, barHeight, unitRowStep, barScale)
			glUniform(locBgTop, bkTop[1], bkTop[2], bkTop[3], bkTop[4])
			glUniform(locBgBottom, bkBottom[1], bkBottom[2], bkBottom[3], bkBottom[4])
			glUniform(locDist, healthbarDistSq, 0, 0, 0)
		end
		gl4DrawStarted = true
		buf.vao:DrawArrays(GL_POINTS, 1, 0, count, first)
		shader:Deactivate()
	end

	function DrawWorldGL4()
		gl4DrawStarted = false
		if not Spring.IsGUIHidden() then
			if (#visibleUnits + #visibleFeatures == 0) or not camBelowMaxHeight then return end
			if WG.Cutscene and WG.Cutscene.IsInCutscene() then return end
			glDepthMask(true)
			cx, cy, cz = spGetCameraPosition()
			OrderBarBuffer(unitBuf, visibleUnits, false)
			OrderBarBuffer(featBuf, visibleFeatures, true)
			FlushBarBuffer(unitBuf)
			FlushBarBuffer(featBuf)

			local nearSq = UnitNearSq()
			local first, count = 0, 0
			for i = 1, #visibleUnits do
				local id = visibleUnits[i]
				local x, y, z = Spring.GetUnitViewPosition(id)
				local n = unitBuf.count[id] or 0
				local immediate = legacyUnits[id]
				if x then
					local dx, dy, dz = x-cx, y-cy, z-cz
					if dx*dx+dy*dy+dz*dz < nearSq then immediate = true end
				end
				if x and not immediate and n > 0 then
					local offset = unitBuf.inst[id][1]
					if count > 0 and offset ~= first+count then
						DrawRange(unitBuf, first, count, false); count = 0
					end
					if count == 0 then first = offset end
					count = count + n
				elseif immediate and x then
					DrawRange(unitBuf, first, count, false); count = 0
					local defID = spGetUnitDefID(id)
					if defID and not spGetUnitRulesParam(id, "no_healthbar") then
						gl4DrawStarted = true
						DrawUnitInfos(id, defID)
					end
				end
			end
			DrawRange(unitBuf, first, count, false)

			nearSq = FeatureNearSq()
			first, count = 0, 0
			for i = 1, #visibleFeatures do
				local entry = visibleFeatures[i]
				local id = entry[4]
				local dx, dy, dz = entry[1]-cx, entry[2]-cy, entry[3]-cz
				local dist = dx*dx+dy*dy+dz*dz
				local n = featBuf.count[id] or 0
				if spValidFeatureID(id) and dist < featureDistSq then
					if dist < nearSq then
						DrawRange(featBuf, first, count, true); count = 0
						addTitle = dist < featureTitleSq
						addPercent = dist < featurePercentSq
						gl4DrawStarted = true
						DrawFeatureInfos(id, entry[5], entry[1], entry[2], entry[3])
					elseif n > 0 then
						local offset = featBuf.inst[id][1]
						if count > 0 and offset ~= first+count then
							DrawRange(featBuf, first, count, true); count = 0
						end
						if count == 0 then first = offset end
						count = count + n
					end
				end
			end
			DrawRange(featBuf, first, count, true)
		end
		glDepthMask(false)
		glMultiTexCoord(1, 1, 1, 1)
		glColor(1, 1, 1, 1)
	end

	----------------------------------------------------------------------------
	-- Setup

	function ResetGL4()
		gl4Gather = false
		barDrawer.TakeBars()
		trackStamp, unitInstData, legacyUnits, lastEval = {}, {}, {}, {}
		trackedCount = 0
		featStamp, featEntry, featLastEval = {}, {}, {}
		if unitBuf then
			ClearBarBuffer(unitBuf)
		end
		if featBuf then
			ClearBarBuffer(featBuf)
		end
		lastUnitList, lastUnitFrame = nil, nil
		lastFeatureList, lastFeatureFrame = nil, nil
		gl4ForceFullUnits = true
		gl4ForceFullFeatures = true
	end

	function ShutdownGL4()
		ResetGL4()
		if unitBuf then
			DeleteBarBuffer(unitBuf)
			unitBuf = nil
		end
		if featBuf then
			DeleteBarBuffer(featBuf)
			featBuf = nil
		end
		if scratchVBO then
			scratchVBO:Delete()
			scratchVBO = nil
			scratchCap = 0
		end
		if dummyVertVBO then
			dummyVertVBO:Delete()
			dummyVertVBO = nil
		end
		if dummyIndexVBO then
			dummyIndexVBO:Delete()
			dummyIndexVBO = nil
		end
		if shader then
			shader:Delete()
			shader = nil
		end
	end

	local function InitGL4Resources()
		-- Without engine GL4 (e.g. ForceDisableGL4, safe mode) the per-unit uniform
		-- buffer the shader reads unit positions from is never bound.
		if not (Platform and Platform.glHaveGL4) then
			return false
		end
		if not (gl.CreateShader and gl.GetVBO and gl.GetVAO and gl.Uniform and gl.GetUniformLocation) then
			return false
		end
		LuaShader = LuaShader or VFS.Include("LuaUI/Widgets/Include/LuaShader.lua")
		shaderCache.forceupdate = true
		shader = LuaShader.CheckShaderUpdates(shaderCache)
		if not shader then
			return false
		end
		local shaderObj = shader:GetHandle()
		locBarDims  = gl.GetUniformLocation(shaderObj, "barDims") or -1
		locBgTop    = gl.GetUniformLocation(shaderObj, "bgTop") or -1
		locBgBottom = gl.GetUniformLocation(shaderObj, "bgBottom") or -1
		locDist     = gl.GetUniformLocation(shaderObj, "distParams") or -1
		locBlink    = gl.GetUniformLocation(shaderObj, "blinkParams") or -1
		dummyVertVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
		dummyIndexVBO = gl.GetVBO(GL.ELEMENT_ARRAY_BUFFER, false)
		if not (dummyVertVBO and dummyIndexVBO) then
			return false
		end
		dummyVertVBO:Define(1, {{id = 5, name = "unused", size = 1}})
		dummyVertVBO:Upload({0})
		dummyIndexVBO:Define(1)
		dummyIndexVBO:Upload({0})
		unitBuf = NewBarBuffer(512)
		featBuf = NewBarBuffer(128)
		return (unitBuf and featBuf) and true or false
	end

	function InitGL4()
		local ok, res = pcall(InitGL4Resources)
		if ok and res then
			ResetGL4()
			Spring.Echo("HealthBars GL4: renderer initialized")
			return true
		end
		Spring.Echo("HealthBars GL4: GL4 not available, enabling HealthBars", (not ok) and tostring(res) or "")
		pcall(ShutdownGL4)
		return false
	end

	function UpdateGL4()
		UnitPass(visibleUnits, gameFrame)
		FeaturePass(visibleFeatures, gameFrame)
	end
end


do
	local ALL_UNITS            = Spring.ALL_UNITS
	local GetCameraPosition    = Spring.GetCameraPosition
	local GetUnitDefID         = Spring.GetUnitDefID
	local glDepthMask          = gl.DepthMask
	local glMultiTexCoord      = gl.MultiTexCoord

	function widget:DrawWorld()
		gatherOverlays = not WG.DrawParalyzedUnitGL4
		if gl4Active and not gatherOverlays then
			local ok, err = pcall(DrawWorldGL4)
			if ok then
				return
			end
			-- Restore state and fall back immediately unless a draw may have emitted bars.
			Spring.Echo("HealthBars GL4: draw failed, using immediate mode", tostring(err))
			gl.UseShader(0)
			gl.Texture(false)
			glDepthMask(false)
			glMultiTexCoord(1, 1, 1, 1)
			glColor(1, 1, 1, 1)
			pcall(ShutdownGL4)
			gl4Ready, gl4Active = false, false
			if gl4DrawStarted then return end
		end
		if not Spring.IsGUIHidden() then
			if (#visibleUnits + #visibleFeatures == 0) then
				return
			end

			-- Test camera height before processing
			if not IsCameraBelowMaxHeight() then
				return false
			end

			-- Processing
			if WG.Cutscene and WG.Cutscene.IsInCutscene() then
				return
			end
			--gl.Fog(false)
			--gl.DepthTest(true)
			glDepthMask(true)

			cx, cy, cz = GetCameraPosition()

			--// draw bars of units
			local unitID, unitDefID, unitDef
			for i = 1, #visibleUnits do
				unitID    = visibleUnits[i]
				unitDefID = GetUnitDefID(unitID)
				if (unitDefID) then
					-- DrawUnitInfos also collects the overlay infos; collect them separately only without a bar
					if Spring.GetUnitRulesParam(unitID, "no_healthbar") then
						if gatherOverlays then
							JustGetOverlayInfos(unitID, unitDefID)
						end
					else
						DrawUnitInfos(unitID, unitDefID)
					end
				elseif debugMode then
					local x, y, z = Spring.GetUnitPosition(unitID)
					if not (x and y and z) then
						Spring.Log("HealthBars", "error", "missing position and unitDefID of unit " .. unitID)
					else
						Spring.MarkerAddPoint(x, y, z, "Missing unitDef")
					end
				end
			end

			--// draw bars for features
			local wx, wy, wz, dx, dy, dz, dist, featureID, valid
			local featureInfo
			for i = 1, #visibleFeatures do
				featureInfo = visibleFeatures[i]
				featureID = featureInfo[4]
				valid = Spring.ValidFeatureID(featureID)
				if (valid) then
					wx, wy, wz = featureInfo[1], featureInfo[2], featureInfo[3]
					dx, dy, dz = wx-cx, wy-cy, wz-cz
					dist = dx*dx + dy*dy + dz*dz
					if (dist < featureDistSq) then
						addTitle = dist < featureTitleSq
						addPercent = dist < featurePercentSq
						DrawFeatureInfos(featureInfo[4], featureInfo[5], wx, wy, wz)
					end
				end
			end
		elseif gatherOverlays then
			local unitID, unitDefID
			for i = 1, #visibleUnits do
				unitID    = visibleUnits[i]
				unitDefID = GetUnitDefID(unitID)
				if (unitDefID) then
					JustGetOverlayInfos(unitID, unitDefID)
				end
			end
		end

		glDepthMask(false)

		if gatherOverlays then
			DrawOverlays()
		elseif (#paraUnits > 0) or (#disarmUnits > 0) or (#onFireUnits > 0) then
			-- Nothing reads these while the GL4 effect is active; previously they grew forever.
			paraUnits = {}
			disarmUnits = {}
			onFireUnits = {}
		end
		glMultiTexCoord(1, 1, 1, 1)
		glColor(1, 1, 1, 1)

		--gl.DepthTest(false)
	end
end --//end do

do
	local GetGameFrame         = Spring.GetGameFrame
	local GetVisibleUnits      = Spring.GetVisibleUnits
	local GetVisibleFeatures   = Spring.GetVisibleFeatures
	local GetFeatureDefID      = Spring.GetFeatureDefID
	local GetFeaturePosition   = Spring.GetFeaturePosition
	local GetFeatureResources  = Spring.GetFeatureResources
	local select = select

	local sec = 0
	local sec2 = 0

	function widget:Update(dt)
		-- Test camera height before processing
		if not IsCameraBelowMaxHeight() then
			camBelowMaxHeight = false
			-- no GL4 passes meanwhile: gather everything when coming back
			gl4ForceFullUnits = true
			gl4ForceFullFeatures = true
			return false
		end
		camBelowMaxHeight = true
		
		local _, activeCmdID = Spring.GetActiveCommand()
		-- Processing
		sec = sec+dt
		blink = (sec%1) < 0.5
		blink_j = options.flashJump.value and (activeCmdID == CMD_JUMP) and ((sec%0.5) < 0.25)
                barColors.jump = (blink_j and barColors.jump_p) or barColors.jump_b

		gameFrame = GetGameFrame()
		visibleUnits = GetVisibleUnits(-1, nil, false) --this don't need any delayed update or caching or optimization since its already done in "LUAUI/cache.lua"

		sec2 = sec2+dt
		if (sec2 > 1/3) then
			sec2 = 0
			visibleFeatures = GetVisibleFeatures(-1, nil, false, false)
			local cnt = #visibleFeatures
			local featureID, featureDefID, featureDef
			for i = cnt, 1, -1 do
				featureID    = visibleFeatures[i]
				featureDefID = GetFeatureDefID(featureID) or -1
				--// filter trees and none destructable features
				if destructableFeature[featureDefID] and (drawnFeature[featureDefID] or (select(5, GetFeatureResources(featureID)) < 1)) then
					local fx, fy, fz = GetFeaturePosition(featureID)
					visibleFeatures[i] = {fx, fy, fz, featureID, featureDefID}
				else
					visibleFeatures[i] = visibleFeatures[cnt]
					visibleFeatures[cnt] = nil
					cnt = cnt-1
				end
			end
		end

		if gl4Ready then
			gatherOverlays = not WG.DrawParalyzedUnitGL4
			if (not gatherOverlays) and (not deactivated) then
				if not gl4Active then Spring.Echo("HealthBars GL4: renderer active") end
				gl4Active = true
				local ok, err = pcall(UpdateGL4)
				if not ok then
					Spring.Echo("HealthBars GL4: update failed, using immediate mode", tostring(err))
					pcall(ShutdownGL4)
					gl4Ready, gl4Active = false, false
				end
			elseif gl4Active then
				-- the immediate mode path draws; start from scratch when coming back
				gl4Active = false
				ResetGL4()
			end
		end
	end

end --//end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// not 100% finished!

function MorphUpdate(morphTable)
	UnitMorphs = morphTable
end

function MorphStart(unitID, morphDef)
	--return false
end

function MorphStop(unitID)
	UnitMorphs[unitID] = nil
end

function MorphFinished(unitID)
	UnitMorphs[unitID] = nil
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

