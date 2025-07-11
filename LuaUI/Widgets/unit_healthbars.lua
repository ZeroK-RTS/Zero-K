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
		name      = "HealthBars",
		desc      = "Gives various information about units in form of bars.",
		author    = "jK",
		date      = "2009", --2013 May 12
		license   = "GNU GPL, v2 or later",
		layer     = -10, -- above gui_selectedunits_gl4, below gui_name_tags 
		enabled   = true  --  loaded by default?
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
local function OptionsChanged()
	drawFeatureHealth = options.drawFeatureHealth.value
	drawBarPercentages = options.drawBarPercentages.value
	barScale = options.barScale.value
	debugMode = options.debugMode.value
	
	healthbarDistSq    = options.unitMaxHeight.value*options.unitMaxHeight.value
	healthbarPercentSq = options.unitPercentHeight.value*options.unitPercentHeight.value
	healthbarTitleSq   = options.unitTitleHeight.value*options.unitTitleHeight.value
	
	featureDistSq      = options.featureMaxHeight.value*options.featureMaxHeight.value
	featurePercentSq   = options.featurePercentHeight.value*options.featurePercentHeight.value
	featureTitleSq     = options.featureTitleHeight.value*options.featureTitleHeight.value
end

options_path = 'Settings/Interface/Healthbars'
options_order = { 'showhealthbars', 'drawFeatureHealth', 'drawBarPercentages', 'flashJump',
	'barScale', 'debugMode', 'minReloadTime',
	'unitMaxHeight', 'unitPercentHeight', 'unitTitleHeight',
	'featureMaxHeight', 'featurePercentHeight', 'featureTitleHeight',
	'invert_shield', 'invert_health', 'invert_building', 'invert_morph',
	'invert_stockpile', 'invert_paralyze', 'invert_disarm', 'invert_capture',
	'invert_capture_reload', 'invert_teleport', 'invert_teleport_pw', 'invert_ability',
	'invert_heat', 'invert_speed', 'invert_reload', 'invert_reammo',
	'invert_slow', 'invert_goo', 'invert_jump', 'invert_reclaim', 'invert_resurrect',
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
	barScale = {
		name = 'Bar size scale',
		type = 'number',
		value = 1,
		min = 0.5,
		max = 6,
		step = 0.25,
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
		widgetHandler:UpdateCallIn('DrawWorld')
		deactivated = false
	else
		widgetHandler:RemoveCallIn('DrawWorld')
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
	local function DrawUnitBar(offsetY, percent, color)
		brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
		local progress_pos = -barWidth + barWidth*2*percent
		local bar_Height  = barHeight+offsetY
		if percent < 1 then
			glBeginEnd(GL_QUADS, DrawGradient, progress_pos, bar_Height, barWidth, offsetY, bkTop, bkBottom)
		end
		glBeginEnd(GL_QUADS, DrawGradient, -barWidth, bar_Height, progress_pos, offsetY, brightClr, color)
	end

	local function DrawFeatureBar(offsetY, percent, color)
		brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
		local progress_pos = -featureBarWidth+featureBarWidth*2*percent
		glBeginEnd(GL_QUADS, DrawGradient, progress_pos, featureBarHeight+offsetY, featureBarWidth, offsetY, fbkTop, fbkBottom)
		glBeginEnd(GL_QUADS, DrawGradient, -featureBarWidth, featureBarHeight+offsetY, progress_pos, offsetY, brightClr, color)
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

	function externalFunc.AddPercentBar(status, percent, color, textOverride)
		barsN = barsN + 1
		local barInfo = bars[barsN]
		local progress = percent
		if options["invert_" .. status].value then
			progress = 1 - progress
		end
		if barInfo then
			barInfo.title    = addTitle and messages[status]
			barInfo.progress = progress
			barInfo.color    = color or barColors[status]
			barInfo.text     = addPercent and (textOverride or floor(percent*100) .. '%')
		end
	end

	function externalFunc.AddDurationBar(status, duration)
		barsN = barsN + 1
		local barInfo = bars[barsN]
		if barInfo then
			barInfo.title    = addTitle and messages[status]
			barInfo.progress = 1
			barInfo.color    = barColors[(status .. ((blink and "_b") or "_p"))]
			barInfo.text     = addPercent and floor(duration) .. 's'
		end
	end

	function externalFunc.HasBars()
		return (barsN ~= 0)
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

	local ux, uy, uz
	local dx, dy, dz, dist
	local health, maxHealth, paralyzeDamage, capture, build
	local hp, hp100, emp, morph
	local reload, reloaded, reloadFrame
	local numStockpiled, numStockpileQued

	local customInfo = {}
	local ci

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

	function DrawUnitInfos(unitID, unitDefID)
		if (not customInfo[unitDefID]) then
			local ud = UnitDefs[unitDefID]
			customInfo[unitDefID] = {
				height        = Spring.Utilities.GetUnitHeight(ud) + 14,
				canJump       = (ud.customParams.canjump and true) or false,
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
		ci = customInfo[unitDefID]

		local ux, uy, uz = GetUnitViewPosition(unitID)
		if not ux then
			return
		end
		local dx, dy, dz = ux-cx, uy-cy, uz-cz
		local dist = dx*dx + dy*dy + dz*dz

		if (dist > healthbarDistSq) then
			return
		end
		addPercent = (dist < healthbarPercentSq)
		addTitle = (dist < healthbarTitleSq)

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

		if Spring.GetUnitIsDead(unitID) then
			health = false
		end

		if hp < 0 then
			hp = 0
		end

		morph = UnitMorphs[unitID]

		if (drawUnitsOnFire) and (GetUnitRulesParam(unitID, "on_fire") == 1) then
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
		local stunned = GetUnitIsStunned(unitID)
		if (emp > 0) and(emp < 1e8) then
			stunned = stunned and paralyzeDamage >= empHP
			if (stunned) then
				paraTime = (paralyzeDamage-empHP)/(maxHealth*empDecline)
				paraUnits[#paraUnits+1] = unitID
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
					barDrawer.AddPercentBar("disarm", disarmProp)
				end
			else
				local disarmTime = (disarmFrame - gameFrame - 1200)/gameSpeed
				if (not paraTime) or disarmTime > paraTime + 0.5 then
					barDrawer.AddDurationBar("disarm", disarmTime)
					if not stunned then
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
				barDrawer.AddPercentBar("capture_reload", capture)
			end
		end
		
		--// Teleport progress
		local TeleportEnd = GetUnitRulesParam(unitID, "teleportend")
		local TeleportCost = GetUnitRulesParam(unitID, "teleportcost")
		if TeleportEnd and TeleportCost and TeleportEnd >= 0 then
			local prog
			if TeleportEnd > 1 then
				-- End frame given
				prog = 1 - (TeleportEnd - gameFrame)/TeleportCost
			else
				-- Same parameters used to display a static progress
				prog = 1 - TeleportEnd
			end
			if prog < 1 then
				barDrawer.AddPercentBar("teleport", prog)
			end
		end
		
		--// Planetwars teleport progress
		if ci.isPwStructure then
			TeleportEnd = GetUnitRulesParam(unitID, "pw_teleport_frame")
			if TeleportEnd then
				local prog = 1 - (TeleportEnd - gameFrame)/TELEPORT_CHARGE_NEEDED
				if prog < 1 then
					barDrawer.AddPercentBar("teleport_pw", prog)
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
					barDrawer.AddPercentBar("ability", special)
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
			local reammoProgress = GetUnitRulesParam(unitID, "reammoProgress")
			if reammoProgress then
				barDrawer.AddPercentBar("reammo", reammoProgress)
			end
		end
		
		--// RELOAD
		if (not ci.scriptReload) and (ci.dyanmicComm or (ci.reloadTime >= options.minReloadTime.value)) and (not ci.canReammo) then
			local primaryWeapon = (ci.dyanmicComm and GetUnitRulesParam(unitID, "primary_weapon_override")) or ci.primaryWeapon
			_, reloaded, reloadFrame = GetUnitWeaponState(unitID, primaryWeapon)
			if (reloaded == false) then
				local reloadTime = Spring.GetUnitWeaponState(unitID, primaryWeapon, 'reloadTime')
				if (not ci.dyanmicComm) or (reloadTime >= options.minReloadTime.value) then
					ci.reloadTime = reloadTime
					-- When weapon is disabled the reload time is constantly set to be almost complete.
					-- It results in a bunch of units walking around with 99% reload bars.
					if (reloadFrame > gameFrame + 6) or (GetUnitRulesParam(unitID, "reloadPaused") ~= 1) then -- UPDATE_PERIOD in unit_attributes.lua.
						reload = 1 - ((reloadFrame-gameFrame)/gameSpeed) / ci.reloadTime;
						if (reload >= 0) then
							barDrawer.AddPercentBar("reload", reload)
						end
					end
				end
			end
		end
		
		if ci.scriptReload and (ci.scriptReload >= options.minReloadTime.value) then
			local reloadFrame = GetUnitRulesParam(unitID, "scriptReloadFrame")
			if reloadFrame and reloadFrame > gameFrame then
				local scriptLoaded = GetUnitRulesParam(unitID, "scriptLoaded") or ci.scriptBurst
				reload = Spring.GetUnitRulesParam(unitID, "scriptReloadPercentage") or (1 - ((reloadFrame - gameFrame)/gameSpeed) / ci.scriptReload)
				if (reload >= 0) then
					barDrawer.AddPercentBar("reload", reload)
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
				barDrawer.AddPercentBar("slow", slowState*2, false, floor(slowState*100) .. '%')
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
		if ci.canJump then
			local jumpReload = GetUnitRulesParam(unitID, "jumpReload")
			if (jumpReload and (jumpReload > 0) and (jumpReload < 1)) then
				barDrawer.AddPercentBar("jump", jumpReload)
			end
		end
		
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

end --// end do

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawFeatureInfos

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

	function DrawFeatureInfos(featureID, featureDefID, fx, fy, fz)
		if (not customInfo[featureDefID]) then
			local featureDef = FeatureDefs[featureDefID or -1] or {height = 0, name = ''}
			customInfo[featureDefID] = {
				height = featureDef.height+14,
			}
		end
		ci = customInfo[featureDefID]

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

function widget:Initialize()
	WG.InitializeTranslation(languageChanged, GetInfo().name)

	--// catch f9
	Spring.SendCommands({"showhealthbars 0"})
	Spring.SendCommands({"showrezbars 0"})
	widgetHandler:AddAction("showhealthbars", showhealthbars)
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
	widgetHandler:RegisterGlobal('MorphUpdate', MorphUpdate)
	widgetHandler:RegisterGlobal('MorphFinished', MorphFinished)
	widgetHandler:RegisterGlobal('MorphStart', MorphStart)
	widgetHandler:RegisterGlobal('MorphStop', MorphStop)

	--// deactivate cheesy progress text
	widgetHandler:RegisterGlobal('MorphDrawProgress', function() return true end)

	--// wow, using a buffered list can give 1-2 frames in extreme(!) situations :p
	for hp = 0, 100 do
		bfcolormap[hp] = {GetColor(hpcolormap, hp*0.01)}
	end
end

function widget:Shutdown()
	WG.ShutdownTranslation(GetInfo().name)

	--// catch f9
	widgetHandler:RemoveAction("showhealthbars", showhealthbars)
	Spring.SendCommands({"unbind f9 luaui"})
	Spring.SendCommands({"bind f9 showhealthbars"})
	Spring.SendCommands({"showhealthbars 1"})
	Spring.SendCommands({"showrezbars 1"})

	widgetHandler:DeregisterGlobal('MorphUpdate', MorphUpdate)
	widgetHandler:DeregisterGlobal('MorphFinished', MorphFinished)
	widgetHandler:DeregisterGlobal('MorphStart', MorphStart)
	widgetHandler:DeregisterGlobal('MorphStop', MorphStop)

	widgetHandler:DeregisterGlobal('MorphDrawProgress')
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local visibleFeatures = {}
local visibleUnits = {}

do
	local ALL_UNITS            = Spring.ALL_UNITS
	local GetCameraPosition    = Spring.GetCameraPosition
	local GetUnitDefID         = Spring.GetUnitDefID
	local glDepthMask          = gl.DepthMask
	local glMultiTexCoord      = gl.MultiTexCoord

	function widget:DrawWorld()
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
					if ((not Spring.GetUnitRulesParam(unitID, "no_healthbar")) and DrawUnitInfos(unitID, unitDefID)) or JustGetOverlayInfos(unitID, unitDefID) then
						local x, y, z = Spring.GetUnitPosition(unitID)
						if not (x and y and z) then
							Spring.Log("HealthBars", "error", "missing position and unitDef of unit " .. unitID)
						else
							Spring.MarkerAddPoint(x, y, z, "Missing unitDef")
						end
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
		else
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

		DrawOverlays()
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
			return false
		end
		
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

