-- $Id: unit_healthbars.lua 4481 2009-04-25 18:38:05Z carrepairer $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007,2008,2009.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "HealthBars",
		desc      = "Gives various informations about units in form of bars.",
		author    = "jK",
		date      = "2009", --2013 May 12
		license   = "GNU GPL, v2 or later",
		layer     = -10,
		enabled   = true  --  loaded by default?
	}
end

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

--// this table is used to shows the hp of perimeter defence, and filter it for default wreckages
local walls = {dragonsteeth=true,dragonsteeth_core=true,fortification=true,fortification_core=true,spike=true,floatingteeth=true,floatingteeth_core=true,spike=true}

local stockpileH = 24
local stockpileW = 12

local captureReloadTime = tonumber(UnitDefNames["vehcapture"].customParams.post_capture_reload) -- Hackity hax
local DISARM_DECAY_FRAMES = 1200

local destructableFeature = {}
local drawnFeature = {}
for i = 1, #FeatureDefs do
	destructableFeature[i] = FeatureDefs[i].destructable
	drawnFeature[i] = (FeatureDefs[i].drawTypeString=="model")
end

--------------------------------------------------------------------------------
-- LOCALISATION
--------------------------------------------------------------------------------

local messages = {
	shield = "shield",
	health_bar = "health",
	building = "building",
	morph = "morph",
	stockpile = "stockpile",
	paralyze = "paralyze",
	disarm = "disarm",
	capture = "capture",
	capture_reload = "capture reload",
	water_tank = "water tank",
	teleport = "teleport",
	teleport_pw = "teleport",
	ability = "ability",
	reload = "reload",
	reammo = "reammo",
	slow = "slow",
	goo = "goo",
	jump = "jump",
	reclaim = "reclaim",
	resurrect = "resurrect",
}

local function languageChanged ()
	for key, value in pairs(messages) do
		messages[key] = WG.Translate ("interface", key)
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
end

options_path = 'Settings/Interface/Healthbars'
options_order = { 'showhealthbars', 'drawFeatureHealth', 'drawBarPercentages', 'barScale', 'debugMode', 'minReloadTime', 'drawMaxHeight', 'simpleHealthPercent'}
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
	drawMaxHeight = { -- Code for this is all from icon height widget
		name = 'Health Bar Fade Height',
		desc = 'If the camera is above this height, health bars will not be drawn. Setting this above 3000 may affect performance.',
		type = 'number',
		min = 0, max = 9000, step = 200,
		value = 3000,
	},
	simpleHealthPercent = { -- Code for this is all from icon height widget
		name = 'Simple Health Bar Distance',
		desc = 'Percentage of Health Bar Fade Height after which simple health bars are shown. Setting this above 50 may affect performance.',
		type = 'number',
		min = 10, max = 100, step = 5,
		value = 25,
	},
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function lowerkeys(t)
	local tn = {}
	for i,v in pairs(t) do
		local typ = type(i)
		if type(v)=="table" then
			v = lowerkeys(v)
		end
		if typ=="string" then
			tn[i:lower()] = v
		else
			tn[i] = v
		end
	end
	return tn
end

local paralyzeOnMaxHealth = ((lowerkeys(VFS.Include"gamedata/modrules.lua") or {}).paralyze or {}).paralyzeonmaxhealth

local spGetGroundHeight = Spring.GetGroundHeight
local function IsCameraBelowMaxHeight()
	local cs = Spring.GetCameraState()
	if cs.name == "ta" then
		return cs.height < options.drawMaxHeight.value
	elseif cs.name == "ov" then
		return false
	else
		return (cs.py - spGetGroundHeight(cs.px, cs.pz)) < options.drawMaxHeight.value
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// colors
local bkBottom   = { 0.40,0.40,0.40,barAlpha }
local bkTop      = { 0.10,0.10,0.10,barAlpha }
local hpcolormap = { {0.8, 0.0, 0.0, barAlpha},  {0.8, 0.6, 0.0, barAlpha}, {0.0,0.70,0.0,barAlpha} }
local bfcolormap = {}

local fbkBottom   = { 0.40,0.40,0.40,featureBarAlpha }
local fbkTop      = { 0.06,0.06,0.06,featureBarAlpha }
local fhpcolormap = { {0.8, 0.0, 0.0, featureBarAlpha},  {0.8, 0.6, 0.0, featureBarAlpha}, {0.0,0.70,0.0,featureBarAlpha} }

local barColors = {
	-- Units
	emp            = { 0.50,0.50,1.00,barAlpha },
	emp_p          = { 0.40,0.40,0.80,barAlpha },
	emp_b          = { 0.60,0.60,0.90,barAlpha },
	disarm         = { 0.50,0.50,0.50,barAlpha },
	disarm_p       = { 0.40,0.40,0.40,barAlpha },
	disarm_b       = { 0.60,0.60,0.60,barAlpha },
	capture        = { 1.00,0.50,0.00,barAlpha },
	capture_reload = { 0.00,0.60,0.60,barAlpha },
	build          = { 0.75,0.75,0.75,barAlpha },
	stock          = { 0.50,0.50,0.50,barAlpha },
	reload         = { 0.00,0.60,0.60,barAlpha },
	reload2        = { 0.80,0.60,0.00,barAlpha },
	reammo         = { 0.00,0.60,0.60,barAlpha },
	jump           = { 0.00,0.90,0.00,barAlpha },
	sheath         = { 0.00,0.20,1.00,barAlpha },
	fuel           = { 0.70,0.30,0.00,barAlpha },
	slow           = { 0.50,0.10,0.70,barAlpha },
	goo            = { 0.40,0.40,0.40,barAlpha },
	shield         = { 0.30,0.0,0.90,barAlpha },
	tank           = { 0.10,0.20,0.90,barAlpha },
	tele           = { 0.00,0.60,0.60,barAlpha },
	tele_pw        = { 0.00,0.60,0.60,barAlpha },

	-- Features
	resurrect = { 1.00,0.50,0.00,featureBarAlpha },
	reclaim   = { 0.75,0.75,0.75,featureBarAlpha },
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local blink = false;
local gameFrame = 0;

local empDecline = 1/40;

local cx, cy, cz = 0,0,0;  --// camera pos

local paraUnits   = {};
local disarmUnits = {};
local onFireUnits = {};
local UnitMorphs  = {};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// speedup (there are a lot more localizations, but they are in limited scope cos we are running out of upvalues)
local glColor         = gl.Color
local glMyText        = gl.FogCoord
local floor           = math.floor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

do
	local deactivated = false
	function showhealthbars(cmd, line, words)
		if ((words[1])and(words[1]~="0"))or(deactivated) then
			widgetHandler:UpdateCallIn('DrawWorld')
			deactivated = false
		else
			widgetHandler:RemoveCallIn('DrawWorld')
			deactivated = true
		end
	end
	options.showhealthbars.OnChange = function(self) showhealthbars(_,_,{self.value and '1' or '0'}) end
end --//end do

function widget:Initialize()

	WG.InitializeTranslation (languageChanged, GetInfo().name)

	--// catch f9
	Spring.SendCommands({"showhealthbars 0"})
	Spring.SendCommands({"showrezbars 0"})
	widgetHandler:AddAction("showhealthbars", showhealthbars)
	Spring.SendCommands({"unbind f9 showhealthbars"})
	Spring.SendCommands({"bind f9 luaui showhealthbars"})

	--// find real primary weapon and its reloadtime
	for _,ud in pairs(UnitDefs) do
		ud.reloadTime    = 0;
		ud.primaryWeapon = 1;
		ud.shieldPower   = 0;

		for i = 1, #ud.weapons do
			local WeaponDefID = ud.weapons[i].weaponDef;
			local WeaponDef   = WeaponDefs[ WeaponDefID ];
			if (WeaponDef.reload>ud.reloadTime) then
				ud.reloadTime    = WeaponDef.reload;
				ud.primaryWeapon = i;
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
	for hp=0,100 do
		bfcolormap[hp] = {GetColor(hpcolormap,hp*0.01)}
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

function GetColor(colormap,slider)
	local coln = #colormap
	if (slider >= 1) then
		local col = colormap[coln]
		return col[1],col[2],col[3],col[4]
	end
	if (slider<0) then slider=0 elseif(slider>1) then slider=1 end
	local posn  = 1+(coln-1) * slider
	local iposn = floor(posn)
	local aa    = posn - iposn
	local ia    = 1-aa

	local col1,col2 = colormap[iposn],colormap[iposn+1]

	return col1[1]*ia + col2[1]*aa, col1[2]*ia + col2[2]*aa,
				 col1[3]*ia + col2[3]*aa, col1[4]*ia + col2[4]*aa
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local DrawUnitBar
local DrawFeatureBar
local DrawStockpile

do
	--//speedup
	local GL_QUADS        = GL.QUADS
	local glVertex        = gl.Vertex
	local glBeginEnd      = gl.BeginEnd
	local glMultiTexCoord = gl.MultiTexCoord
	local glTexRect       = gl.TexRect
	local glTexture       = gl.Texture
	local glCallList      = gl.CallList
	local glText          = gl.Text

	local function DrawGradient(left,top,right,bottom,topclr,bottomclr)
		glColor(bottomclr)
		glVertex(left,bottom)
		glVertex(right,bottom)
		glColor(topclr)
		glVertex(right,top)
		glVertex(left,top)
	end

	local brightClr = {}
	function DrawUnitBar(offsetY,percent,color)
		brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
		local progress_pos= -barWidth+barWidth*2*percent-1
		local bar_Height  = barHeight+offsetY
		if percent<1 then glBeginEnd(GL_QUADS,DrawGradient,progress_pos, bar_Height, barWidth, offsetY, bkTop,bkBottom) end
		glBeginEnd(GL_QUADS,DrawGradient,-barWidth, bar_Height, progress_pos, offsetY,brightClr,color)
	end

	function DrawFeatureBar(offsetY,percent,color)
		brightClr[1] = color[1]*1.5; brightClr[2] = color[2]*1.5; brightClr[3] = color[3]*1.5; brightClr[4] = color[4]
		local progress_pos = -featureBarWidth+featureBarWidth*2*percent
		glBeginEnd(GL_QUADS,DrawGradient,progress_pos, featureBarHeight+offsetY, featureBarWidth, offsetY, fbkTop,fbkBottom)
		glBeginEnd(GL_QUADS,DrawGradient,-featureBarWidth, featureBarHeight+offsetY, progress_pos, offsetY, brightClr,color)
	end

	function DrawStockpile(numStockpiled,numStockpileQued, freeStockpile)
		--// DRAW STOCKPILED MISSLES
		glColor(1,1,1,1)
		glTexture("LuaUI/Images/nuke.png")
		local xoffset = barWidth+16
		for i=1,((numStockpiled>3) and 3) or numStockpiled do
			glTexRect(xoffset,-(11*barHeight-2)-stockpileH,xoffset-stockpileW,-(11*barHeight-2))
			xoffset = xoffset-8
		end
		glTexture(false)
	if freeStockpile then
			glText(numStockpiled,barWidth+1.7,-(11*barHeight-2)-16,7.5,"cno")
	else
		glText(numStockpiled..'/'..numStockpileQued,barWidth+1.7,-(11*barHeight-2)-16,7.5,"cno")
	end
	end

end --//end do


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local AddBar
local DrawBars
local barsN = 0

do
	--//speedup
	local glColor      = gl.Color
	local glText       = gl.Text

	local maxBars = 20
	local bars    = {}
	local barHeightL = barHeight + 2
	local barStart   = -(barWidth + 1)
	local fBarHeightL = featureBarHeight + 2
	local fBarStart   = -(featureBarWidth + 1)

	for i=1,maxBars do bars[i] = {} end

	function AddBar(title,progress,color_index,text,color)
		barsN = barsN + 1
		local barInfo    = bars[barsN]
		barInfo.title    = title
		barInfo.progress = progress
		barInfo.color    = color or barColors[color_index]
		barInfo.text     = text
	end

	function DrawBars(fullText)
		local yoffset = 0
		for i = 1, barsN do
			local barInfo = bars[i]
			DrawUnitBar(yoffset,barInfo.progress,barInfo.color)
			if (fullText) then
				if (drawBarPercentages) then
					glColor(1,1,1,barAlpha)
					glText(barInfo.text,barStart,yoffset,4,"r")
				end
				if (drawBarTitles) then
					glColor(1,1,1,titlesAlpha)
					glText(barInfo.title,0,yoffset,2.5,"cd")
				end
			end
			yoffset = yoffset - barHeightL
		end

		barsN = 0 --//reset!
	end

	function DrawBarsFeature(fullText)
		local yoffset = 0
		for i = 1, barsN do
			local barInfo = bars[i]
			DrawFeatureBar(yoffset,barInfo.progress,barInfo.color)
			if (fullText) then
				if (drawBarPercentages) then
					glColor(1,1,1,featureBarAlpha)
					glText(barInfo.text,fBarStart,yoffset,4,"r")
				end
				if (drawBarTitles) then
					glColor(1,1,1,featureTitlesAlpha)
					glText(barInfo.title,0,yoffset,2.5,"cd")
				end
			end
			yoffset = yoffset - fBarHeightL
		end

		barsN = 0 --//reset!
	end

end --//end do


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

	local fullText
	local ux, uy, uz
	local dx, dy, dz, dist
	local health,maxHealth,paralyzeDamage,capture,build
	local hp, hp100, emp, morph
	local reload,reloaded,reloadFrame
	local numStockpiled,numStockpileQued

	local customInfo = {}
	local ci

	function JustGetOverlayInfos(unitID,unitDefID)
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
		health,maxHealth,paralyzeDamage = GetUnitHealth(unitID)
		paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage

		local empHP = ((not paralyzeOnMaxHealth) and health) or maxHealth
		emp = (paralyzeDamage or 0)/empHP
		hp  = (health or 0)/maxHealth
		morph = UnitMorphs[unitID]

		if (drawUnitsOnFire)and(GetUnitRulesParam(unitID,"on_fire")==1) then
			onFireUnits[#onFireUnits+1]=unitID
		end

		--// PARALYZE
		local stunned, _, inbuild = GetUnitIsStunned(unitID)
		if (emp>0) and ((not morph) or morph.combatMorph) and (emp<1e8) and (paralyzeDamage >= empHP) then
			if (stunned) then
				paraUnits[#paraUnits+1]=unitID
			end
		end

		--// DISARM
		if not stunned then
			local disarmed = GetUnitRulesParam(unitID,"disarmed")
			if disarmed and disarmed == 1 then
				disarmUnits[#disarmUnits+1]=unitID
			end
		end
	end

	function DrawUnitInfos(unitID,unitDefID)
		if (not customInfo[unitDefID]) then
			local ud = UnitDefs[unitDefID]
			customInfo[unitDefID] = {
				height        = Spring.Utilities.GetUnitHeight(ud) + 14,
				canJump       = (ud.customParams.canjump and true) or false,
				canGoo        = (ud.customParams.grey_goo and true) or false,
				canReammo     = (ud.customParams.requireammo and true) or false,
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
				maxWaterTank  = ud.customParams.maxwatertank,
				freeStockpile = (ud.customParams.freestockpile and true) or nil,
				specialReload = ud.customParams.specialreloadtime,
			}
		end
		ci = customInfo[unitDefID]

		fullText = true
		local ux, uy, uz = GetUnitViewPosition(unitID)
		if not ux then
			return
		end
		local dx, dy, dz = ux-cx, uy-cy, uz-cz
		local dist = dx*dx + dy*dy + dz*dz
		local maxDist = math.pow(options.drawMaxHeight.value, 2)
		local simpleDist = maxDist * (options.simpleHealthPercent.value/100)

		if (dist > simpleDist) then
			if (dist > maxDist) then
				if debugMode then
					local x,y,z = Spring.GetUnitPosition(unitID)
					Spring.MarkerAddPoint(x,y,z,"High Distance")
				end
				return
			end
			fullText = false
		end

		--// GET UNIT INFORMATION
		local health,maxHealth,paralyzeDamage,capture,build = GetUnitHealth(unitID)
		paralyzeDamage = GetUnitRulesParam(unitID, "real_para") or paralyzeDamage
		--if (not health)    then health=-1   elseif(health<1)    then health=1    end
		if (not maxHealth)or(maxHealth<1) then
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

		if (drawUnitsOnFire)and(GetUnitRulesParam(unitID,"on_fire")==1) then
			onFireUnits[#onFireUnits+1]=unitID
		end

		--// BARS //-----------------------------------------------------------------------------
		--// Shield
		if (ci.maxShield>0) then
			local commShield = GetUnitRulesParam(unitID, "comm_shield_max")
			if commShield then
				if commShield ~= 0 then
					local shieldOn, shieldPower = GetUnitShieldState(unitID, GetUnitRulesParam(unitID, "comm_shield_num"))
					if (shieldOn)and(build==1)and(shieldPower < commShield) then
						shieldPower = shieldPower / commShield
						AddBar(messages.shield,shieldPower,"shield",(fullText and floor(shieldPower*100)..'%') or '')
					end
				end
			else
				local shieldOn,shieldPower = GetUnitShieldState(unitID)
				if (shieldOn)and(build==1)and(shieldPower<ci.maxShield) then
					shieldPower = shieldPower / ci.maxShield
					AddBar(messages.shield,shieldPower,"shield",(fullText and floor(shieldPower*100)..'%') or '')
				end
			end
		end

		--// HEALTH
		if (health) and ((drawFullHealthBars)or(hp<1)) and ((build==1)or(hp<0.99 and (build>hp+0.01 or hp>build+0.01))or(drawFullHealthBars)) then
			hp100 = hp*100; hp100 = hp100 - hp100%1; --//same as floor(hp*100), but 10% faster
			if (hp100<0) then hp100=0 elseif (hp100>100) then
				hp100 = 100
			end
			if (drawFullHealthBars)or(hp100<100) then
				AddBar(messages.health_bar,hp,nil,(fullText and hp100..'%') or '',bfcolormap[hp100])
			end
		end

		--// BUILD
		if (build<1) then
			AddBar(messages.building,build,"build",(fullText and floor(build*100)..'%') or '')
		end

		--// MORPHING
		if (morph) then
			local build = morph.progress
			AddBar(messages.morph,build,"build",(fullText and floor(build*100)..'%') or '')
		end

		--// STOCKPILE
		if (ci.canStockpile) then
			local stockpileBuild
			numStockpiled, numStockpileQued, stockpileBuild = GetUnitStockpile(unitID)
			if ci.gadgetStock then
				stockpileBuild = GetUnitRulesParam(unitID,"gadgetStockpile")
			end
			if numStockpiled and stockpileBuild and (numStockpileQued ~= 0) then
				AddBar(messages.stockpile,stockpileBuild,"stock",(fullText and floor(stockpileBuild*100)..'%') or '')
			end
		else
			numStockpiled = false
		end

			--// PARALYZE
		local paraTime = false
		local stunned = GetUnitIsStunned(unitID)
		if (emp>0) and(emp<1e8) then
			local infotext = ""
			stunned = stunned and paralyzeDamage >= empHP
			if (stunned) then
				paraTime = (paralyzeDamage-empHP)/(maxHealth*empDecline)
				paraUnits[#paraUnits+1]=unitID
				if (fullText) then
					infotext = floor(paraTime) .. 's'
				end
				emp = 1
			else
				if (emp > 1) then
					emp = 1
				end
				if (fullText) then
					infotext = floor(emp*100)..'%'
				end
			end
			local empcolor_index = (stunned and ((blink and "emp_b") or "emp_p")) or ("emp")
			AddBar(messages.paralyze,emp,empcolor_index,infotext)
		end

		 --// DISARM
		local disarmFrame = GetUnitRulesParam(unitID,"disarmframe")
		if disarmFrame and disarmFrame ~= -1 and disarmFrame > gameFrame then
			local disarmProp = (disarmFrame - gameFrame)/1200
			if disarmProp < 1 then
				if (not paraTime) and disarmProp > emp + 0.014 then -- 16 gameframes of emp time
					AddBar(messages.disarm,disarmProp,"disarm",(fullText and floor(disarmProp*100)..'%') or '')
				end
			else
				local disarmTime = (disarmFrame - gameFrame - 1200)/gameSpeed
				if (not paraTime) or disarmTime > paraTime + 0.5 then
					AddBar(messages.disarm,1,((blink and "disarm_b") or "disarm_p") or ("disarm"),floor(disarmTime) .. 's')
					if not stunned then
						disarmUnits[#disarmUnits+1]=unitID
					end
				end
			end
		end

		--// CAPTURE (set by capture gadget)
		if ((capture or -1)>0) then
			AddBar(messages.capture,capture,"capture",(fullText and floor(capture*100)..'%') or '')
		end

		--// CAPTURE RECHARGE
		if ci.canCapture then
			local captureReloadState = GetUnitRulesParam(unitID,"captureRechargeFrame")
			if (captureReloadState and captureReloadState > 0) then
				local capture = 1-(captureReloadState-gameFrame)/captureReloadTime
				AddBar(messages.capture_reload,capture,"reload",(fullText and floor(capture*100)..'%') or '')
			end
		end

		--// WATER TANK
		if ci.maxWaterTank then
			local waterTank = GetUnitRulesParam(unitID,"watertank")
			if waterTank then
				local prog = waterTank/ci.maxWaterTank
				if prog < 1 then
					AddBar(messages.water_tank,prog,"tank",(fullText and floor(prog*100)..'%') or '')
				end
			end
		end

		--// Teleport progress
		local TeleportEnd = GetUnitRulesParam(unitID,"teleportend")
		local TeleportCost = GetUnitRulesParam(unitID,"teleportcost")
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
				AddBar(messages.teleport,prog,"tele",(fullText and floor(prog*100)..'%') or '')
			end
		end

		--// Planetwars teleport progress
		if isPwStructure then
			TeleportEnd = GetUnitRulesParam(unitID, "pw_teleport_frame")
			if TeleportEnd then
				local prog = 1 - (TeleportEnd - gameFrame)/TELEPORT_CHARGE_NEEDED
				if prog < 1 then
					AddBar(messages.teleport, prog, "tele_pw", (fullText and floor(prog*100)..'%') or '')
				end
			end
		end

		--// SPECIAL WEAPON
		if ci.specialReload then
			local specialReloadState = GetUnitRulesParam(unitID,"specialReloadFrame")
			if (specialReloadState and specialReloadState > gameFrame) then
				local special = 1-(specialReloadState-gameFrame)/ci.specialReload	-- don't divide by gamespeed, since specialReload is also in gameframes
				AddBar(messages.ability,special,"reload2",(fullText and floor(special*100)..'%') or '')
			end
		end

		--// REAMMO
		if ci.canReammo then
			local reammoProgress = GetUnitRulesParam(unitID, "reammoProgress")
			if reammoProgress then
				AddBar(messages.reammo,reammoProgress,"reammo",(fullText and floor(reammoProgress*100)..'%') or '')
			end
		end

		--// RELOAD
		if (not ci.scriptReload) and (ci.dyanmicComm or (ci.reloadTime >= options.minReloadTime.value)) then
			local primaryWeapon = (ci.dyanmicComm and GetUnitRulesParam(unitID, "primary_weapon_override")) or ci.primaryWeapon
			_,reloaded,reloadFrame = GetUnitWeaponState(unitID,primaryWeapon)
			if (reloaded==false) then
				local reloadTime = Spring.GetUnitWeaponState(unitID, primaryWeapon, 'reloadTime')
				if (not ci.dyanmicComm) or (reloadTime >= options.minReloadTime.value) then
					ci.reloadTime = reloadTime
					-- When weapon is disabled the reload time is constantly set to be almost complete.
					-- It results in a bunch of units walking around with 99% reload bars.
					if (reloadFrame > gameFrame + 6) or (GetUnitRulesParam(unitID, "reloadPaused") ~= 1) then -- UPDATE_PERIOD in unit_attributes.lua.
						reload = 1 - ((reloadFrame-gameFrame)/gameSpeed) / ci.reloadTime;
						if (reload >= 0) then
							AddBar(messages.reload,reload,"reload",(fullText and floor(reload*100)..'%') or '')
						end
					end
				end
			end
		end

		if ci.scriptReload and (ci.scriptReload >= options.minReloadTime.value) then
			local reloadFrame = GetUnitRulesParam(unitID, "scriptReloadFrame")
			if reloadFrame and reloadFrame > gameFrame then
				local scriptLoaded = GetUnitRulesParam(unitID, "scriptLoaded") or ci.scriptBurst
				local barText = string.format("%i/%i", scriptLoaded, ci.scriptBurst) -- .. ' | ' .. floor(reload*100) .. '%'
				reload = Spring.GetUnitRulesParam(unitID, "scriptReloadPercentage") or (1 - ((reloadFrame - gameFrame)/gameSpeed) / ci.scriptReload)
				if (reload >= 0) then
					AddBar(messages.reload, reload,"reload",(fullText and barText) or '')
				end
			end
		end

		--// SHEATH
		--local sheathState = GetUnitRulesParam(unitID,"sheathState")
		--if sheathState and (sheathState < 1) then
		--	AddBar("sheath",sheathState,"sheath",(fullText and floor(sheathState*100)..'%') or '')
		--end

		--// SLOW
		local slowState = GetUnitRulesParam(unitID,"slowState")
		if (slowState and (slowState>0)) then
			if slowState > 0.5 then
				AddBar(messages.slow,1,"slow",(fullText and floor((slowState - 0.5)*25)..'s') or '')
			else
				AddBar(messages.slow,slowState*2,"slow",(fullText and floor(slowState*100)..'%') or '')
			end
		end

		--// GOO
		if ci.canGoo then
			local gooState = GetUnitRulesParam(unitID,"gooState")
			if (gooState and (gooState>0)) then
				AddBar(messages.goo,gooState,"goo",(fullText and floor(gooState*100)..'%') or '')
			end
		end

		--// JUMPJET
		if ci.canJump then
			local jumpReload = GetUnitRulesParam(unitID,"jumpReload")
			if (jumpReload and (jumpReload>0) and (jumpReload<1)) then
				AddBar(messages.jump,jumpReload,"jump",(fullText and floor(jumpReload*100)..'%') or '')
			end
		end

		if debugMode then
		local x,y,z = Spring.GetUnitPosition(unitID)
			Spring.MarkerAddPoint(x,y,z,"N" .. barsN)
		end

		if (barsN > 0) or (numStockpiled) then
			glPushMatrix()
			glTranslate(ux, uy+ci.height, uz )
			gl.Scale(barScale, barScale, barScale)
			glBillboard()

			--// STOCKPILE ICON
			if (numStockpiled) then
				DrawStockpile(numStockpiled,numStockpileQued, ci.freeStockpile)
			end

			--// DRAW BARS
			DrawBars(fullText)

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
	local health,maxHealth,resurrect,reclaimLeft
	local hp

	local customInfo = {}
	local ci

	function DrawFeatureInfos(featureID,featureDefID,fullText,fx,fy,fz)
		if (not customInfo[featureDefID]) then
			local featureDef = FeatureDefs[featureDefID or -1] or {height = 0, name = ''}
			customInfo[featureDefID] = {
				height = featureDef.height+14,
				wall   = walls[featureDef.name],
			}
		end
		ci = customInfo[featureDefID]

		health,maxHealth,resurrect = GetFeatureHealth(featureID)
		_,_,_,_,reclaimLeft        = GetFeatureResources(featureID)
		if (not resurrect) then
			resurrect = 0
		end
		if (not reclaimLeft) then
			reclaimLeft = 1
		end

		hp = (health or 0)/(maxHealth or 1)

		--// filter all walls and none resurrecting features
		if (resurrect == 0) and
			 (reclaimLeft == 1) and
			 (hp > featureHpThreshold) then
			return
		end

		--// BARS //-----------------------------------------------------------------------------
		--// HEALTH
		if (hp<featureHpThreshold)and(drawFeatureHealth) then
			local hpcolor = {GetColor(fhpcolormap,hp)}
			AddBar(messages.health_bar,hp,nil,(fullText and floor(hp*100)..'%') or '',hpcolor)
		end

		--// RESURRECT
		if (resurrect>0) then
			AddBar(messages.resurrect,resurrect,"resurrect",(fullText and floor(resurrect*100)..'%') or '')
		end

		--// RECLAIMING
		if (reclaimLeft>0 and reclaimLeft<1) then
			AddBar(messages.reclaim,reclaimLeft,"reclaim",(fullText and floor(reclaimLeft*100)..'%') or '')
		end

		if (barsN>0) then
			glPushMatrix()
			glTranslate(fx,fy+ci.height,fz)
			local scale = options.barScale.value or 1
			gl.Scale(barScale, barScale, barScale)
			glBillboard()

			--// DRAW BARS
			DrawBarsFeature(fullText)

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
		if (drawStunnedOverlay) and ((#paraUnits>0) or (#disarmUnits>0)) then
			glDepthTest(true)
			glPolygonOffset(-2, -2)
			glBlending(GL_SRC_ALPHA, GL_ONE)

			local alpha = ((5.5 * widgetHandler:GetHourTimer()) % 2) - 0.7
			if (#paraUnits>0) then
				glColor(0,0.7,1,alpha/4)
				for i=1,#paraUnits do
					glUnit(paraUnits[i],true)
				end
			end
			if (#disarmUnits>0) then
				glColor(0.8,0.8,0.5,alpha/6)
				for i=1,#disarmUnits do
					glUnit(disarmUnits[i],true)
				end
			end
			local shift = widgetHandler:GetHourTimer() / 20

			glTexCoord(0,0)
			glTexGen(GL_T, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR)
			local cvs = GetCameraVectors()
			local v = cvs.right
			glTexGen(GL_T, GL_EYE_PLANE, v[1]*0.008,v[2]*0.008,v[3]*0.008, shift)
			glTexGen(GL_S, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR)
			v = cvs.forward
			glTexGen(GL_S, GL_EYE_PLANE, v[1]*0.008,v[2]*0.008,v[3]*0.008, shift)

			if (#paraUnits>0) then
				glTexture("LuaUI/Images/paralyzed.png")
				glColor(0,1,1,alpha*1.1)
				for i=1,#paraUnits do
					glUnit(paraUnits[i],true)
				end
			end
			if (#disarmUnits>0) then
				glTexture("LuaUI/Images/disarmed.png")
				glColor(0.6,0.6,0.2,alpha*0.9)
				for i=1,#disarmUnits do
					glUnit(disarmUnits[i],true)
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
			glColor(1,0.3,0,alpha/4)
			for i=1,#onFireUnits do
				glUnit(onFireUnits[i],true)
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
			if (#visibleUnits+#visibleFeatures==0) then
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
			local unitID,unitDefID,unitDef
			for i = 1, #visibleUnits do
				unitID    = visibleUnits[i]
				unitDefID = GetUnitDefID(unitID)
				if (unitDefID) then
					if DrawUnitInfos(unitID, unitDefID) then
						local x,y,z = Spring.GetUnitPosition(unitID)
						if not (x and y and z) then
							Spring.Log("HealthBars", "error", "missing position and unitDef of unit " .. unitID)
						else
							Spring.MarkerAddPoint(x,y,z,"Missing unitDef")
						end
					end
				elseif debugMode then
					local x,y,z = Spring.GetUnitPosition(unitID)
					if not (x and y and z) then
						Spring.Log("HealthBars", "error", "missing position and unitDefID of unit " .. unitID)
					else
						Spring.MarkerAddPoint(x,y,z,"Missing unitDef")
					end
				end
			end

			--// draw bars for features
			local wx, wy, wz, dx, dy, dz, dist, featureID, valid
			local featureInfo
			local maxFeatureDist = math.pow(options.drawMaxHeight.value, 2) * (2/3)
			local simpleFeatureDist = maxFeatureDist*(options.simpleHealthPercent.value/100)
			for i=1,#visibleFeatures do
				featureInfo = visibleFeatures[i]
				featureID = featureInfo[4]
				valid = Spring.ValidFeatureID(featureID)
				if (valid) then
					wx, wy, wz = featureInfo[1],featureInfo[2],featureInfo[3]
					dx, dy, dz = wx-cx, wy-cy, wz-cz
					dist = dx*dx + dy*dy + dz*dz
					if (dist < maxFeatureDist) then
						if (dist < simpleFeatureDist) then
							DrawFeatureInfos(featureInfo[4], featureInfo[5], true, wx,wy,wz)
						else
							DrawFeatureInfos(featureInfo[4], featureInfo[5], false, wx,wy,wz)
						end
					end
				end
			end
		else
			local unitID,unitDefID
			for i = 1, #visibleUnits do
				unitID    = visibleUnits[i]
				unitDefID = GetUnitDefID(unitID)
				if (unitDefID) then
					unitDef   = UnitDefs[unitDefID]
					if (unitDef) then
						JustGetOverlayInfos(unitID, unitDefID)
					end
				end
			end
		end

		glDepthMask(false)

		DrawOverlays()
		glMultiTexCoord(1,1,1,1)
		glColor(1,1,1,1)

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

		-- Processing
		sec=sec+dt
		blink = (sec%1)<0.5

		gameFrame = GetGameFrame()
		visibleUnits = GetVisibleUnits(-1,nil,false) --this don't need any delayed update or caching or optimization since its already done in "LUAUI/cache.lua"

		sec2=sec2+dt
		if (sec2>1/3) then
			sec2 = 0
			visibleFeatures = GetVisibleFeatures(-1,nil,false,false)
			local cnt = #visibleFeatures
			local featureID,featureDefID,featureDef
			for i=cnt,1,-1 do
				featureID    = visibleFeatures[i]
				featureDefID = GetFeatureDefID(featureID) or -1
				--// filter trees and none destructable features
				if destructableFeature[featureDefID] and (drawnFeature[featureDefID] or (select(5,GetFeatureResources(featureID))<1)) then
					local fx,fy,fz = GetFeaturePosition(featureID)
					visibleFeatures[i] = {fx,fy,fz, featureID, featureDefID}
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

function MorphStart(unitID,morphDef)
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

