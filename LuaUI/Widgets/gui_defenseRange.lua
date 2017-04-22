include("colors.h.lua")
include("keysym.h.lua")

local versionNumber = "6.2.6"

function widget:GetInfo()
	return {
		name      = "Defense Range Zero-K",
		desc      = "[v" .. string.format("%s", versionNumber ) .. "] Displays range of defenses (enemy and ally)",
		author    = "very_bad_soldier / versus666",
		date      = "October 21, 2007 / September 08, 2010",
		license   = "GNU GPL v2",
		layer     = 0,
		enabled   = true
	}
end

--[[
-- to do : include chicken buildings.

---- CHANGELOG -----
-- versus666,			V6.3	(17fev2012) :	corrected min range due to Outlaw fake weapon, merged with Unit Ranges by Niobium. Very basic range, no gravity compensation as it would cost many CPU cycles time with many units, it should be fine given the dynamic nature of units, disabled by default
-- versus666,			v6.2.6	(16dec2011)	:	comply with F5 (hide gui->hide ranges) for clean screenshots.
-- Google Frog          v6.2.5  (11dec2010) :	moved all range display config to chilli menu. Removed extraneous configs
-- versus666,			v6.2.4	(04nov2010)	:	added widget name over buttons when in tweak mode, clearer than a plain box + widget name in tooltips when hovering over buttons.
-- versus666,			v6.2.3	(04nov2010)	:	added hacksaw to unit list + defRangeNoButtons var & checks due to licho's request, need to add var to option menu.
												made defRangeNoButtons = true & all ranges visible by default until there is a decent (chili?)gui to enable/disable ranges or buttons. Change at will but use the damn changelog to show who, when, what and how. Thanks.
-- versus666, 			v6.2.2	(28oct2010)	:	Cleaned some bits of code.
--		?,				v6.2.1	(17oct2010)	:	Added compatibilty to CA1F ->will need update when CA1F->ZK.
--		?,				v6.2	(17oct2010)	:	Speed-up by cpu culling.
--		?,				v6.12	(17oct2010)	:	Bugfix (BA Ambusher working).
--		?,				v6.11	(17oct2010)	:	Added missing water units to BA. (torpLauncher/FHLT/FRocketTower)
--	very_bad_soldier,	v6.1	(17oct2010)	:	XTA-support added (thx to manolo_).
												tweak mode and load/save fixed.
 --]]

-- CONFIGURATION
local debug = false --generates debug messages when set to true.

local modConfig = {}
-- ZK
modConfig["ZK"] = {}
modConfig["ZK"]["unitList"] =
{
	--1FACTION
	armamd = { weapons = { 3 }, differentInbuildDraw = true },		--antinuke
	armartic = { weapons = { 1 } },		--faraday
	armdeva = { weapons = { 1 } },		--stardust
	armpb = { weapons = { 1 } },		--pitbull
	mahlazer = { weapons = { 1 } },		--starlight
	armartic = { weapons = { 1 } },		--faraday
	armanni = { weapons = { 1 } },		--annihilator
	armbrtha = { weapons = { 1 } },		--bertha
	tacnuke = { weapons = { 1 } },		--tacnuke
	armarch = { weapons = { 2 } },		--packo (unused)
	armcir = { weapons = { 2 } },		--chainsaw
	armdl = { weapons = { 1 } },		--anemone (unused)
	corrl = { weapons = { 4 } },		--defender
	corllt = { weapons = { 1 } },		--LLT
	corhlt = { weapons = { 1 } },		--HLT
	corvipe = { weapons = { 1 } },		--viper (unused)
	cordoom = { weapons = { 1 } },		--doomsday
	cordl = { weapons = { 1 } },		--jellyfish (unused)
	corrazor = { weapons = { 2 } },		--razorkiss
	corflak = { weapons = { 2 } },		--flak
	screamer = { weapons = { 2 } },		--screamer
	missiletower = { weapons = { 2 } },	--hacksaw
	corbhmth = { weapons = { 1 } },		--behemoth
	turrettorp = { weapons = { 1 } },	--torpedo launcher
	coratl = { weapons = { 1 } },		--adv torpedo launcher (unused)
	corgrav = { weapons = { 1 } },		--newton
	corjamt = { },
}

local shieldDefID = UnitDefNames["corjamt"].id

local unitDefIDRemap = {
	[UnitDefNames["missilesilo"].id] = UnitDefNames["tacnuke"].id,
	[UnitDefNames["tacnuke"].id] = -1,
}

--uncomment this if you want dps-depending ring-colors
--colors will be interpolated by dps scores between min and max values. values outside range will be set to nearest value in range -> min or max
modConfig["ZK"]["armorTags"] = {}
modConfig["ZK"]["armorTags"]["air"] = "planes"
modConfig["ZK"]["armorTags"]["ground"] = "else"
modConfig["ZK"]["dps"] = {}
modConfig["ZK"]["dps"]["ground"] = {}
modConfig["ZK"]["dps"]["air"] = {}
modConfig["ZK"]["dps"]["ground"]["min"] = 90
modConfig["ZK"]["dps"]["ground"]["max"] = 750 --doomsday does 450 and 750
modConfig["ZK"]["dps"]["air"]["min"] = 90
modConfig["ZK"]["dps"]["air"]["max"] = 400 --core flak
--end of dps-colors
--end of ZK

--DEFAULT COLOR CONFIG
--is used when no game-specfic color config is found in current game-definition
local colorConfig = {}
colorConfig["enemy"] = {}
colorConfig["enemy"]["ground"]= {}
colorConfig["enemy"]["ground"]["min"]= {}
colorConfig["enemy"]["ground"]["max"]= {}
colorConfig["enemy"]["air"]= {}
colorConfig["enemy"]["air"]["min"]= {}
colorConfig["enemy"]["air"]["max"]= {}
colorConfig["enemy"]["nuke"]= {}
colorConfig["enemy"]["ground"]["min"] = { 1.0, 0.0, 0.0 }
colorConfig["enemy"]["ground"]["max"] = { 1.0, 1.0, 0.0 }
colorConfig["enemy"]["air"]["min"] = { 0.0, 1.0, 0.0 }
colorConfig["enemy"]["air"]["max"] = { 0.0, 0.0, 1.0 }
colorConfig["enemy"]["nuke"]["complete"] =  { 1.0, 1.0, 1.0 }
colorConfig["enemy"]["nuke"]["nanoframe"] =  { 0.0, 0.6, 0.8 }
local shieldColor = {1, 0, 1}

colorConfig["ally"] = colorConfig["enemy"]
--end of DEFAULT COLOR CONFIG
--Button display configuration
--position only relevant if no saved config data found

local defences = {}

local currentModConfig = {}
local buttons = {}

local firstUpddateCount = 0

local needRedraw = false
local defenseRangeDrawList = false

local REDRAW_TIME = 0.1 -- Time in seconds to batch redraws within

local updateTimes = {}
updateTimes["remove"] = 0
updateTimes["line"] = 0
updateTimes["removeInterval"] = 1 --configurable: seconds for the ::update loop

local state = {}
state["curModID"] = nil

local lineConfig = {}
lineConfig["lineWidth"] = 1.0
lineConfig["alphaValue"] = 0.35
lineConfig["circleDivs"] = 40.0

-- active range vars
local spGetSelUnitsSorted	= Spring.GetSelectedUnitsSorted
local spGetUnitViewPosition	= Spring.GetUnitViewPosition
local uDefs					= UnitDefs
local wDefs					= WeaponDefs
local wepRanges				= {}
--local buildRange			= {}
local sqrt					= math.sqrt

local weapNamTab			= WeaponDefNames
local weapTab				= WeaponDefs
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local GL_LINE_LOOP          = GL.LINE_LOOP -- GL_LINE_LOOP + glLineStipple breaks Licho's ATI
local GL_LINE_STRIP         = GL.LINE_STRIP
local glTexEnv				= gl.TexEnv
local glBeginEnd            = gl.BeginEnd
local glBillboard           = gl.Billboard
local glCallList            = gl.CallList 
local glColor               = gl.Color
local glCreateList          = gl.CreateList
local glDepthTest           = gl.DepthTest
local glDrawGroundCircle    = gl.DrawGroundCircle
local glDrawGroundQuad      = gl.DrawGroundQuad
local glLineWidth           = gl.LineWidth
local glPopMatrix           = gl.PopMatrix
local glPushMatrix          = gl.PushMatrix
local glTexRect             = gl.TexRect
local glText                = gl.Text
local glTexture             = gl.Texture
local glTranslate           = gl.Translate
local glVertex              = gl.Vertex
local glAlphaTest			= gl.AlphaTest
local glBlending			= gl.Blending
local glRect				= gl.Rect
local glLineStipple         = gl.LineStipple

local huge                  = math.huge
local max					= math.max
local min					= math.min
local sqrt					= math.sqrt
local abs					= math.abs
local lower                 = string.lower
local sub                   = string.sub
local upper                 = string.upper
local floor                 = math.floor
local format                = string.format
local PI                    = math.pi
local cos                   = math.cos
local sin                   = math.sin

local spEcho                = Spring.Echo
local spGetGameSeconds      = Spring.GetGameSeconds
local spGetSpectatingState  = Spring.GetSpectatingState
local spGetPositionLosState = Spring.GetPositionLosState
local spGetUnitDefID        = Spring.GetUnitDefID
local spGetUnitPosition     = Spring.GetUnitPosition
local spGetUnitIsDead       = Spring.GetUnitIsDead
local spTraceScreenRay      = Spring.TraceScreenRay
local spGetCameraPosition   = Spring.GetCameraPosition
local spGetMyTeamID			= Spring.GetMyTeamID
local spGetGroundHeight 	= Spring.GetGroundHeight
local spIsGUIHidden 		= Spring.IsGUIHidden
local spGetLocalTeamID	 	= Spring.GetLocalTeamID
local spGetActiveCommand 	= Spring.GetActiveCommand
local spGetActiveCmdDesc 	= Spring.GetActiveCmdDesc
local spIsSphereInView  	= Spring.IsSphereInView

local udefTab				= UnitDefs
local weapTab				= WeaponDefs


local spectating = spGetSpectatingState()
local myPlayerID = Spring.GetLocalPlayerID()

--functions
local printDebug
local AddButton
local DetectMod
local SetButtonOrigin
local DrawButtonGL
local ResetGl
local GetButton
local GetColorsByTypeAndDps
local UnitDetected
local GetColorByDps
local RedoUnitList

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
options_path = 'Settings/Interface/Defense Ranges'

options = { 
	showselectedunitrange = {
		name = 'Show selected unit(s) range(s)', 
		type = 'bool', 
		value = false,
	},
	allyground = {
		name = 'Show Ally Ground Defence', 
		type = 'bool', 
		value = false,
		OnChange = function() RedoUnitList() end,
	},
	allyair = {
		name = 'Show Ally Air Defence', 
		type = 'bool', 
		value = false,
		OnChange = function() RedoUnitList() end,
	},
	allynuke = {
		name = 'Show Ally Nuke Defence', 
		type = 'bool',
		value = true,
		OnChange = function() RedoUnitList() end,
	},
	enemyground = {
		name = 'Show Enemy Ground Defence', 
		type = 'bool', 
		value = true,
		OnChange = function() RedoUnitList() end,
	},
	enemyair = {
		name = 'Show Enemy Air Defence', 
		type = 'bool', 
		value = true,
		OnChange = function() RedoUnitList() end,
	},
	enemynuke = {
		name = 'Show Enemy Nuke Defence', 
		type = 'bool',
		value = true,
		OnChange = function() RedoUnitList() end,
	},
	enemyshield = {
		name = 'Show Enemy Shields', 
		type = 'bool',
		value = true,
		OnChange = function() RedoUnitList() end,
	},
	specground = {
		name = 'Show Ground Defence as Spectator', 
		type = 'bool', 
		value = false,
		OnChange = function() RedoUnitList() end,
	},
	specair = {
		name = 'Show Air Defence as Spectator', 
		type = 'bool', 
		value = false,
		OnChange = function() RedoUnitList() end,
	},
	specnuke = {
		name = 'Show Nuke Defence as Spectator', 
		type = 'bool',
		value = true,
		OnChange = function() RedoUnitList() end,
	},
}

options_order = {
	'showselectedunitrange',
	'allyground',
	'allyair',
	'allynuke',
	'enemyground',
	'enemyair',
	'enemynuke',
	'enemyshield',
	'specground',
	'specair',
	'specnuke',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckWeaponInclusion(weaponType, isAlly )
	if ( weaponType == 1 or weaponType == 4 ) then
		if spectating then
			return options.specground.value
		else
			if ( (not isAlly) and options.enemyground.value ) then
				return true
			elseif ( isAlly and options.allyground.value ) then
				return true
			end
		end
	end

	if ( weaponType == 2 or weaponType == 4 ) then
		if spectating then
			return options.specair.value
		else
			if ( (not isAlly) and options.enemyair.value ) then
				return true
			elseif ( isAlly and options.allyair.value ) then
				return true
			end
		end
	end

	if ( weaponType == 3 ) then
		if spectating then
			return options.specnuke.value
		else
			if ( (not isAlly) and options.enemynuke.value ) then
				return true
			elseif ( isAlly and options.allynuke.value ) then
				return true
			end
		end
	end

	return false
end

local function BuildVertexList(verts)
	local count =  #verts
	for i = 1, count do
		glVertex(verts[i])
	end
	if count > 0 then
		glVertex(verts[1])
	end
end

local function CheckAirWithGround(isAlly, wantGround)
	if spectating then 
		return options.specair.value and (options.specground.value == wantGround)
	else
		if isAlly then
			return options.allyair.value and (options.allyground.value == wantGround)
		else
			return options.enemyair.value and (options.enemyground.value == wantGround)
		end
	end
end

local function CreateDrawList(isAlly, weapons)
	
	for i, weapon in pairs(weapons) do
			
		color = weapon["color1"]
		range = weapon["range"]
		if weapon["type"] == 4 and CheckAirWithGround(isAlly, false) then
			-- check if unit is combo unit, get secondary color if so
			--if air only is selected
			color = weapon["color2"]
		end
		printDebug("Drawing range circle.")
		glColor( color[1], color[2], color[3], lineConfig["alphaValue"])
		glLineWidth(lineConfig["lineWidth"])
		glBeginEnd(GL_LINE_STRIP, BuildVertexList, weapon["rangeLines"] )
		--printDebug( "Drawing defence: range: " .. range .. " Color: " .. color[1] .. "/" .. color[2] .. "/" .. color[3] .. " a:" .. lineConfig["alphaValue"] )
		if weapon["type"] == 4 and CheckAirWithGround(isAlly, true) then
			--air and ground: draw 2nd circle
			printDebug("Drawing second range circle.")
			glColor( weapon["color2"][1], weapon["color2"][2], weapon["color2"][3], lineConfig["alphaValue"])
			glBeginEnd(GL_LINE_STRIP, BuildVertexList, weapon["rangeLinesEx"] )
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitDetected( unitID, isAlly )
	local unitDefID = spGetUnitDefID(unitID)

	if unitDefID and unitDefIDRemap[unitDefID] then
		unitDefID = unitDefIDRemap[unitDefID]
		if unitDefID == -1 then
			return
		end
	end

	local udef = unitDefID and UnitDefs[unitDefID]
	if not udef then
		return
	end
	local configData = currentModConfig["unitList"][UnitDefs[unitDefID].name]
	if not configData then
		return
	end
	if defences[unitID] then
		local defenceData = defences[unitID]
		if configData.differentInbuildDraw then
			local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
			if inBuild == defenceData.isBuild then
				return
			end
		else
			return
		end
	end
	
	isAlly = isAlly or spectating
	
	if (not udef) or (#udef.weapons == 0) then
		--not interesting, has no weapons, lame
		--printDebug("Unit ignored: weaponCount is 0")
		return
	end

	local x, y, z = spGetUnitPosition(unitID)
	local longestRange = 0
	local weaponDef

	if unitDefID == shieldDefID then
		if isAlly or (not options.enemyshield.value) then return end
		weaponDef = WeaponDefs[udef.weapons[1].weaponDef]
		local rangeLines = CalcBallisticCircle(x,y,z, weaponDef.shieldRadius, weaponDef )
		defences[unitID] = {
			drawList = glCreateList(CreateDrawList, isAlly, {{
					type = type,
					rangeLines = rangeLines,
					rangeLinesEx = rangeLines,
					color1 = shieldColor,
					color2 = shieldColor,
				}}),
			pos = {x, y, z},
			drawRange = weaponDef.shieldRadius,
			inBuild = inBuild,
			checkCompleteness = false,
		}
		needRedraw = needRedraw or REDRAW_TIME
		return
	end

	printDebug( udef.name )
	local foundWeapons = {}
	
	local _,_,inBuild = Spring.GetUnitIsStunned(unitID)
	
	local tag

	for i=1, #udef.weapons do
		if ( configData == nil or configData["weapons"][i] == nil ) then
			printDebug("Weapon skipped! Name: "..  udef.name .. " weaponidx: " .. i )
		else
			--get definition from weapon table
			weaponDef = weapTab[ udef.weapons[i].weaponDef ]

			printDebug("Weapon #" .. i .. " Type: " .. weaponDef.type )
			
			local dam = weaponDef.damages
			local type = configData["weapons"][i]
			
			if CheckWeaponInclusion(type, isAlly) then
			
				local dps
				local damage
				local color1
				local color2
				
				local range = weaponDef.range --get normal weapon range
			
				--check if dps-depending colors should be used
				if ( currentModConfig["armorTags"] ~= nil ) then
					printDebug("DPS colors!")
					if ( type == 1 or type == 4 ) then	 -- show combo units with ground-dps-colors
						tag = currentModConfig["armorTags"] ["ground"]
					elseif ( type == 2 ) then
						tag = currentModConfig["armorTags"] ["air"]
					elseif ( type == 3 ) then -- antinuke
						range = tonumber(weaponDef.customParams and weaponDef.customParams.nuke_coverage or 2500)
						dps = nil
						tag = nil
					end

					if ( tag ~= nil ) then
						--printDebug("Salvo: " .. weaponDef.salvoSize 	)
						damage = dam[Game.armorTypes[tag]]
						dps = damage * weaponDef.salvoSize / weaponDef.reload
						--printDebug("DPS: " .. dps 	)
					end

					color1, color2 = GetColorsByTypeAndDps( dps, type, isAlly, inBuild)
				else
					printDebug("Default colors!")
					local team = "ally"
					if ( isAlly ) then
						team = "enemy"
					end

					if ( type == 1 or type == 4 ) then	 -- show combo units with ground-dps-colors
						color1 = colorConfig[team]["ground"]["min"]
						color2 = colorConfig[team]["air"]["min"]
					elseif ( type == 2 ) then
						color1 = colorConfig[team]["air"]["min"]
					elseif ( type == 3 ) then -- antinuke
						if inBuild then
							color1 = colorConfig[team]["nuke"]["nanoframe"]
						else
							color1 = colorConfig[team]["nuke"]["complete"]
						end
					end
				end
				
				--add weapon to list
				local rangeLines = CalcBallisticCircle(x,y,z,range, weaponDef )
				local rangeLinesEx = CalcBallisticCircle(x,y,z,range + 3, weaponDef ) --calc a little bigger circle to display for combo-weapons (air and ground) to display both circles together (without overlapping)
				
				if longestRange < range then
					longestRange = range
				end
				
				foundWeapons[i] = {
					type = type,
					rangeLines = rangeLines,
					rangeLinesEx = rangeLinesEx,
					color1 = color1,
					color2 = color2,
				}
				printDebug("Detected Weapon - Type: " .. type .. " Range: " .. range )
			end
		end
	end

	if longestRange > 0 then
		printDebug("Adding UnitID " .. unitID .. " WeaponCount: " .. #foundWeapons ) --.. "W1: " .. foundWeapons[1]["type"])
		
		defences[unitID] = { 
			drawList = glCreateList(CreateDrawList, isAlly, foundWeapons),
			pos = {x, y, z},
			drawRange = longestRange,
			inBuild = inBuild,
			checkCompleteness = (not isAlly) and inBuild and configData.differentInbuildDraw,
		}
		needRedraw = needRedraw or REDRAW_TIME
	end
end

function widget:Initialize()
	DetectMod()
	
	for uDefID, uDef in pairs(uDefs) do
		wepRanges[uDefID] = {}
		local weapons = uDef.weapons
		local entryIndex = 0
		for weaponIndex=1, #weapons do
			local weaponRange = wDefs[weapons[weaponIndex].weaponDef].range -- take the value of 'range' in each 'weapons' in 'weaponDefs'
			if (weaponRange > 32) then -- many 'fake' weapons have <= 16 range. ->Up to 32 for outlaw.
				entryIndex = entryIndex + 1
				wepRanges[uDefID][entryIndex] = weaponRange
			end
		end
		--[[if ( weapNamTab[lower(udef["deathExplosion"])] == nil ) then
			return
		end
		
		local udef = uDefs[unitDefID]
		if ( weapNamTab[lower(udef["deathExplosion"])] == nil ) then
			return
		end
		local deathBlasId = weapNamTab[lower(udef["deathExplosion"])].id
		local blastRadius = weapTab[deathBlasId].damageAreaOfEffect
		local defaultDamage = weapTab[deathBlasId].customParams.shield_damage	--get default damage]]--
	end
end

function RedoUnitList()
	defences = {}
	needRedraw = needRedraw or REDRAW_TIME
	
	local myAllyTeam = Spring.GetMyAllyTeamID()
	local units = Spring.GetAllUnits()
	for i=1,#units do
		local unitID = units[i]
		local unitAllyTeam = Spring.GetUnitAllyTeam(unitID)
		UnitDetected(unitID, unitAllyTeam == myAllyTeam)
	end
end

function widget:UnitFinished( unitID,  unitDefID,  unitTeam)
	UnitDetected( unitID, true )
end

function widget:UnitCreated( unitID,  unitDefID,  unitTeam)
	UnitDetected( unitID, true )
end

function widget:UnitDestroyed(unitID)
	if defences[unitID] then
		defences[unitID] = nil
		needRedraw = needRedraw or REDRAW_TIME
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	UnitDetected( unitID, false )
end

function GetColorsByTypeAndDps( dps, type, isAlly, inBuild)
	--BEWARE: dps can be nil here! when antinuke for example
 -- get alternative color for weapons ground AND air
	local color1 = nil
	local color2 = nil
	if ( type == 4 ) then -- show combo units with "ground"-colors
		color2 = GetColorByDps( dps, isAlly, "air")
	end

  --get standard colors
	if ( type == 1 or type == 4 ) then
		color1 = GetColorByDps( dps, isAlly, "ground" )
	elseif ( type == 2 ) then
		color1 = GetColorByDps( dps, isAlly, "air" )
	elseif ( type == 3 ) then
		if ( isAlly ) then
			if inBuild then
				color1 = colorConfig["ally"]["nuke"]["nanoframe"]
			else
				color1 = colorConfig["ally"]["nuke"]["complete"]
			end
		else
			if inBuild then
				color1 = colorConfig["enemy"]["nuke"]["nanoframe"]
			else
				color1 = colorConfig["enemy"]["nuke"]["complete"]
			end
		end
	end

	return color1, color2
end

--linear interpolates between min and max color
function GetColorByDps( dps, isAlly, typeStr )
	local color = { 0.0, 0.0, 0.0 }
	local team = "ally"
	if ( not isAlly ) then team = "enemy" end

	printDebug("GetColor typeStr : " .. typeStr  .. "Team: " .. team )
	--printDebug( colorConfig[team][typeStr]["min"] )
	local ldps = max( dps, currentModConfig["dps"][typeStr]["min"] )
	ldps = min( ldps, currentModConfig["dps"][typeStr]["max"])

	ldps = ldps - currentModConfig["dps"][typeStr]["min"]
	local factor = ldps / ( currentModConfig["dps"][typeStr]["max"] - currentModConfig["dps"][typeStr]["min"] )
--	printDebug( "Dps: " .. dps .. " Factor: " .. factor .. " ldps: " .. ldps )
	for i=1,3 do
		color[i] =  ( ( ( 1.0 -  factor ) * colorConfig[team][typeStr]["min"][i] ) + ( factor * colorConfig[team][typeStr]["max"][i] ) )
	--	printDebug( "#" .. i .. ":" .. "min: " .. colorConfig[team][typeStr]["min"]["color"][i] .. " max: " .. colorConfig[team][typeStr]["max"]["color"][i] .. " calc: " .. color[i] )
	end
	return color
end

function ResetGl()
	glColor( { 1.0, 1.0, 1.0, 1.0 } )
	glLineWidth( 1.0 )
end

local function RedrawDrawRanges()
	for _, def in pairs(defences) do
		glCallList(def.drawList)
	end
end

function widget:Update(dt)
	local timef = spGetGameSeconds()
	local time = floor(timef)
	
	if firstUpddateCount then
		firstUpddateCount = firstUpddateCount + 1
		if firstUpddateCount == 2 then
			RedoUnitList()
			firstUpddateCount = nil
		end
	end
	
	if needRedraw then
		needRedraw = needRedraw - dt
		if needRedraw < 0 then
			printDebug("Redrawing Ranges.")
			defenseRangeDrawList = glCreateList(RedrawDrawRanges)
			needRedraw = false
		end
	end
	
	-- Does not make sense with the draw list.
	--if ((timef - updateTimes["line"]) > 0.2 and timef ~= updateTimes["line"] ) then
	--	updateTimes["line"] = timef
	--	--adjust line width and alpha by camera height
	--	_, camy, _ = spGetCameraPosition()
	--	if ( camy < 700 ) then
	--		lineConfig["lineWidth"] = 2.0
	--		lineConfig["alphaValue"] = 0.25
	--	elseif ( camy < 1800 ) then
	--		lineConfig["lineWidth"] = 1.5
	--		lineConfig["alphaValue"] = 0.3
	--	else
	--		lineConfig["lineWidth"] = 1.0
	--		lineConfig["alphaValue"] = 0.35
	--	end
	--end

	-- update timers once every <updateInt> seconds
	if (time % updateTimes["removeInterval"] == 0 and time ~= updateTimes["remove"] ) then
		updateTimes["remove"] = time

		--remove dead units
		for unitID, def in pairs(defences) do
			local x, y, z = def.pos[1], def.pos[2], def.pos[3]
			local a, b, c = spGetPositionLosState(x, y, z)
			local losState = b
			
			if spGetUnitDefID(unitID) then
				if defences[unitID].checkCompleteness then
					-- Not allied because this check is only required for enemies.
					-- Allied units are detected in UnitFinished.
					UnitDetected( unitID, false )
				end
			else
				if losState then
					printDebug("Unit killed.")
					defences[unitID] = nil
					needRedraw = needRedraw or REDRAW_TIME
				end
			end
		end
	end
end

function widget:PlayerChanged(playerID) 
	if myPlayerID == playerID then
		local newSpectating = spGetSpectatingState()
		if spectating ~= newSpectating then
			spectating = newSpectating
			RedoUnitList()
		end
	end
end

function DetectMod()
	state["curModID"] = upper(Game.modShortName or "")

	if ( modConfig[state["curModID"]] == nil ) then
		spEcho("<DefenseRange>: Unsupported Game, shutting down...")
		widgetHandler:RemoveWidget()
		return
	end

	currentModConfig = modConfig[state["curModID"]]

	--load mod specific color config if existent
	if ( currentModConfig["color"] ~= nil ) then
		colorConfig = currentModConfig["color"]
		printDebug("Game-specfic color configuration loaded")
	end
	printDebug( "<DefenseRange>: ModName: " .. Game.modName .. " Detected Mod: " .. state["curModID"] )
end

function GetRange2DWeapon( range, yDiff)
	local root1 = range * range - yDiff * yDiff
	if ( root1 < 0 ) then
		return 0
	else
		return sqrt( root1 )
	end
end

function GetRange2DCannon( range, yDiff, projectileSpeed, rangeFactor, myGravity )
	local factor = 0.7071067
	local smoothHeight = 100.0
	local speed2d = projectileSpeed*factor
	local speed2dSq = speed2d*speed2d
	local curGravity = Game.gravity
	if ( myGravity ~= nil and myGravity ~= 0 ) then
		gravity = myGravity   -- i have never seen a stationary weapon using myGravity tag, so its untested :D
	end
	local gravity = - ( curGravity / 900 )		-- -0.13333333

	--printDebug("rangeFactor: " .. rangeFactor)
	--printDebug("ProjSpeed: " .. projectileSpeed)
	local heightBoostFactor = (2.0 - rangeFactor) / sqrt(rangeFactor)

	if ( yDiff < -smoothHeight ) then
		yDiff = yDiff * heightBoostFactor
	elseif ( yDiff < 0.0 ) then
	  yDiff = yDiff * ( 1.0 + ( heightBoostFactor - 1.0 ) * ( -yDiff)/smoothHeight )
	end

	local root1 = speed2dSq + 2 * gravity * yDiff
	if ( root1 < 0 ) then
		--printDebug("Cann return 0")
		return 0
	else
	--	printDebug("Cann return: " .. rangeFactor * ( speed2dSq + speed2d * sqrt( root1 ) ) / (-gravity) )
		return rangeFactor * ( speed2dSq + speed2d * sqrt( root1 ) ) / (-gravity)
	end
end

--hopefully acurate reimplementation of the spring engine's ballistic circle code
function CalcBallisticCircle( x, y, z, range, weaponDef )
	local rangeLineStrip = {}
	local slope = 0.0

	local rangeFunc = GetRange2DWeapon
	local rangeFactor = 1.0 --used by range2dCannon
	if ( weaponDef.type == "Cannon" ) then
		rangeFunc = GetRange2DCannon
		rangeFactor = range / GetRange2DCannon( range, 0.0, weaponDef.projectilespeed, rangeFactor )
		if ( rangeFactor > 1.0 or rangeFactor <= 0.0 ) then
			rangeFactor = 1.0
		end
	end

	local yGround = spGetGroundHeight( x,z)
	for i = 1, lineConfig["circleDivs"] do
		local radians = 2.0 * PI * i / lineConfig["circleDivs"]
		local rad = range

		local sinR = sin( radians )
		local cosR = cos( radians )

		local posx = x + sinR * rad
		local posz = z + cosR * rad
		local posy = spGetGroundHeight( posx, posz )

		local heightDiff = ( posy - yGround) / 2.0	-- maybe y has to be getGroundHeight(x,z) cause y is unit center and not aligned to ground

		rad = rad - heightDiff * slope
		local adjRadius = rangeFunc( range, heightDiff * weaponDef.heightMod, weaponDef.projectilespeed, rangeFactor )
		local adjustment = rad / 2.0
		local yDiff = 0.0

		for j = 0, 49 do
			if ( abs( adjRadius - rad ) + yDiff <= 0.01 * rad ) then
				break
			end

			if ( adjRadius > rad ) then
				rad = rad + adjustment
			else
				rad = rad - adjustment
				adjustment = adjustment / 2.0
			end
			posx = x + ( sinR * rad )
			posz = z + ( cosR * rad )
			local newY = spGetGroundHeight( posx, posz )
			yDiff = abs( posy - newY )
			posy = newY
			posy = max( posy, 0.0 )  --hack
			heightDiff = ( posy - yGround )	--maybe y has to be Ground(x,z)
			adjRadius = rangeFunc( range, heightDiff * weaponDef.heightMod, weaponDef.projectilespeed, rangeFactor, weaponDef.myGravity )
		end

		posx = x + ( sinR * adjRadius )
		posz = z + ( cosR * adjRadius )
		posy = spGetGroundHeight( posx, posz ) + 5.0
		posy = max( posy, 0.0 )   --hack

		table.insert( rangeLineStrip, { posx, posy, posz } )
	end
	return rangeLineStrip
end

local function DrawRanges()
	if defenseRangeDrawList then
		glCallList(defenseRangeDrawList)
	end
end

local function DrawRangeCircle(ux,uy,uz,range,r)
	glLineWidth(lineConfig["lineWidth"])
	glColor(1-(r/5), 0, 0, lineConfig["alphaValue"])
	glDrawGroundCircle(ux, uy, uz, range, lineConfig["circleDivs"])
end

local function DrawComRanges(unitDefID,unitIDs)
	for i=1,#unitIDs do
		local unitID=unitIDs[i]
		local ux, uy, uz = spGetUnitViewPosition(unitID)
		local weap1 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_1")
		if weap1 then
			local weapRange=Spring.GetUnitWeaponState(unitID,weap1,"range")
			if weapRange then
				DrawRangeCircle(ux,uy,uz,weapRange,1)
			end
		end
		
		local weap2 = Spring.GetUnitRulesParam(unitID, "comm_weapon_num_2")
		if weap2 then
			local weapRange=Spring.GetUnitWeaponState(unitID,weap2,"range")
			if weapRange then
				DrawRangeCircle(ux,uy,uz,weapRange,2)
			end
		end
		
	end
end

local function DrawUnitsRanges(uDefID,uIDs)
	local uWepRanges = wepRanges[uDefID]
	if uWepRanges then
		for i = 1, #uIDs do
			local ux, uy, uz = spGetUnitViewPosition(uIDs[i])
			for r = 1, #uWepRanges do
				DrawRangeCircle(ux,uy,uz,uWepRanges[r],r)
			end
		end
	end
end

function DrawSelectedRanges()
	if ( options.showselectedunitrange.value == true ) then
		-- range OpenGL stuff
		glLineWidth(1.49)
			-- Get selected units, sorted for efficiency
		local selUnits = spGetSelUnitsSorted()
		selUnits.n = nil -- So our loop works
		-- Set the color
		-- Do the loop
		for uDefID, uIDs in pairs(selUnits) do
			-- Dynamic comm have different ranges and different weapons activated
			if UnitDefs[uDefID].customParams.dynamic_comm then
				DrawComRanges(uDefID,uIDs)
			else
				DrawUnitsRanges(uDefID,uIDs)
			end
		end
	end
end

function widget:DrawWorldPreUnit()
	if WG.Cutscene and WG.Cutscene.IsInCutscene() then
		return
	end
	if not spIsGUIHidden() then
		-- def range routine
		DrawRanges()
		DrawSelectedRanges()
		ResetGl()
	end
end

function printDebug( value )
	if ( debug ) then
		if ( type( value ) == "boolean" ) then
			if ( value == true ) then spEcho( "true" )
				else spEcho("false") end
		elseif ( type(value ) == "table" ) then
			spEcho("Dumping table:")
			for key,val in pairs(value) do
				spEcho(key,val)
			end
		else
			spEcho( value )
		end
	end
end
