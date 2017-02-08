--TODO investigate Chili-Error in `Chili Selections & CursorTip`:2435 : [string "LuaUI/Widgets/chili/controls/control.lua"]:897: attempt to index field 'parent' (a nil value). (This bug is many months old. This TODO is written on 18 October 2013). See end of file for longer stacktrace.
--------------------------------------------------------------------------------
function widget:GetInfo()
  return {
    name      = "Chili Selections & CursorTip",
    desc      = "v0.098 Chili Selection Window and Cursor Tooltip.",
    author    = "CarRepairer, jK",
    date      = "2009-06-02", --22 December 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    experimental = false,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetCommandQueue 		= Spring.GetCommandQueue
local spGetCurrentTooltip		= Spring.GetCurrentTooltip
local spGetUnitDefID			= Spring.GetUnitDefID
local spGetFeatureDefID			= Spring.GetFeatureDefID
local spGetFeatureTeam			= Spring.GetFeatureTeam
--local spGetUnitAllyTeam			= Spring.GetUnitAllyTeam
local spGetUnitTeam				= Spring.GetUnitTeam
local spGetUnitHealth			= Spring.GetUnitHealth
local spTraceScreenRay			= Spring.TraceScreenRay
local spGetTeamInfo				= Spring.GetTeamInfo
local spGetPlayerInfo			= Spring.GetPlayerInfo
local spGetTeamColor			= Spring.GetTeamColor
local spGetUnitTooltip			= Spring.GetUnitTooltip
local spGetModKeyState			= Spring.GetModKeyState
local spGetMouseState			= Spring.GetMouseState
local spSendCommands			= Spring.SendCommands
local spGetUnitIsStunned		= Spring.GetUnitIsStunned
local spGetSelectedUnits                = Spring.GetSelectedUnits
local spGetSelectedUnitsCounts          = Spring.GetSelectedUnitsCounts
local spGetSelectedUnitsCount           = Spring.GetSelectedUnitsCount
local spGetSelectedUnitsByDef           = Spring.GetSelectedUnitsSorted
local spGetUnitWeaponState 				= Spring.GetUnitWeaponState
local spGetGameFrame 					= Spring.GetGameFrame
local spGetUnitRulesParam 				= Spring.GetUnitRulesParam
local spSelectUnitArray 				= Spring.SelectUnitArray
local spGetUnitPosition 			= Spring.GetUnitPosition
local spGetGameRulesParam 			= Spring.GetGameRulesParam
local spGetGroundHeight			= Spring.GetGroundHeight

local echo = Spring.Echo

local glColor		= gl.Color
--local glAlphaTest	= gl.AlphaTest
local glTexture 	= gl.Texture
local glTexRect 	= gl.TexRect


--local abs						= math.abs
local strFormat 				= string.format

include("keysym.h.lua")
include("Widgets/COFCTools/ExportUtilities.lua")
VFS.Include("LuaRules/Configs/customcmds.h.lua")
VFS.Include("LuaRules/Utilities/numberfunctions.lua")
VFS.Include("LuaRules/Utilities/unitDefReplacements.lua")
local GetUnitBuildSpeed = Spring.Utilities.GetUnitBuildSpeed
local GetHumanName = Spring.Utilities.GetHumanName
local GetUnitCost = Spring.Utilities.GetUnitCost
local GetDescription = Spring.Utilities.GetDescription

local transkey = include("Configs/transkey.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local Button
local Label
local Window
local StackPanel
local Panel
local Grid
local Image
local Progressbar
local LayoutPanel
local Grid

local screen0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local icon_size = 20
local unitIcon_size = 50
local stillCursorTime = 0

local makeTooltipGap = 0
local oldObjectID = 0
local sameObjectIDTime = 0

local scrH, scrW = 0,0
local old_ttstr, old_data
local old_mx, old_my = -1,-1
local mx, my = -1,-1
local showExtendedTip = false
local changeNow = false
local forceAnUpdate = true -- Makes widget:Update update things like healthbars.

local window_tooltip2
local windows = {}
local tt_healthbar, tt_unitID, tt_fid, tt_ud, tt_fd
local stt_ud, stt_unitID
local controls = {}
local controls_icons = {}

local stack_main, stack_leftbar
local globalitems = {} --remember reference to various chili element that need to be accessed/updated globally.

local ttFontSize = 10
local leftbar_width = 96
local mainsection_width = 230
local buildpic_size = 55
local morph_text_width = 25

local green = '\255\1\255\1'
local red = '\255\255\1\1'
local cyan = '\255\1\255\255'
local white = '\255\255\255\255'
local yellow = '\255\255\255\1'

local windMin = 0
local windMax = 2.5
local windGroundMin = 0
local windGroundExtreme = 1
local windGroundSlope = 1
local windTidalThreashold = -10

local updateFrequency = 0.25
local updateFrequency2 = 1.0 --//update frequency for checking unit's command, for showing unit status in its picture.

local timer = 0
local timer2 = 0
local tweakShow = false

local window_height = 130
local real_window_corner
local window_corner
local selectedUnitsByDefCounts = {}
local selectedUnitsByDef = {}
local selectedUnits = {}
local selectionSortOrder = {}

local secondPerGameFrame = 1/30 --this constant is used for calculating weapon reload time.

local cursor_size = 24	-- pencil and eraser
local iconFormat = ''

local iconTypesPath = LUAUI_DIRNAME.."Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)

local drawing, erasing, addingPoint
local drawHotkeyBytes = {}
local drawHotkeyBytesCount = 0
local drawtoolKeyPressed

WG.drawtoolKeyPressed = nil
WG.customToolTip = {}

local windTooltips = {
	["armwin"] = true,
}

local mexDefID = UnitDefNames["cormex"] and UnitDefNames["cormex"].id or ''
local windgenDefID = UnitDefNames["armwin"] and UnitDefNames["armwin"].id or ''

local energyStructureDefs = {
	[UnitDefNames["armwin"].id] = {cost = 35, income = 1.25},
	[UnitDefNames["armsolar"].id] = {cost = 70, income = 2},
	[UnitDefNames["geo"].id] = {cost = 500, income = 25},
	[UnitDefNames["amgeo"].id] = {cost = 1000, income = 75},
	[UnitDefNames["armfus"].id] = {cost = 1000, income = 35},
	[UnitDefNames["cafus"].id] = {cost = 4000, income = 225},
}

local metalStructureDefs = {
	[UnitDefNames["cormex"].id] = {cost = 75},
}

local terraCmds = {
	Ramp=1,
	Level=1,
	Raise=1,
	Smooth=1,
	Restore=1,
}
local terraTips = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Multiple units selected controls and data

local multiSelect = {
	barGrid = nil,
	unitSquare = {data = {}, count = 0},
	healthbarByUnitID = {},
	healthbarByDefID = {},
}
--[[
multiSelect = {
	barGrid = layout panel which is the parent of the structure
	unitSquare = {
		data = {
			[1] = {
				defid
			    unitid
			    unitids
				panel
				image
				label
				labelIsChild
				healthbar
				isChild
			}
			...
		},
		count
	},
	healthbarByUnitID = {},
	healthbarByDefID = {},
}
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- group info

local numSelectedUnits = 0
local maxPicFit = 10

local unitInfoSum = {
	count = 0,
	cost = 0,
	finishedcost = 0,
	hp = 0,
	maxhp = 0,
	metalincome = 0,
	metaldrain = 0,
	energyincome = 0,
	energydrain = 0,
	usedbp = 0,
	totalbp = 0,
}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- UI elements

local label_unitInfo


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

options_path = 'Settings/HUD Panels/Tooltip'
options_order = {
	--tooltip
	
	'tooltip_delay', 'independant_world_tooltip_delay',
	'large','hpshort', 'featurehp', 
	'show_for_units', 'show_for_wreckage', 'show_for_unreclaimable', 'show_position', 'show_unit_text', 'showdrawtooltip','showterratooltip',
	
	--mouse
	'showDrawTools',
	
	--selected units
	'selection_opacity', 'groupalways', 'showgroupinfo', 'squarepics','uniticon_size','unitCommand', 'manualWeaponReloadBar', 'alwaysShowSelectionWin',
	'fancySkinning', 'leftPadding',
}

local function option_Deselect()
	-- unselect to prevent errors
	Spring.SelectUnitMap({}, false)
	window_height = options.squarepics.value and 140 or 115
	multiSelect = {
		barGrid = nil,
		unitSquare = {data = {}, count = 0},
		indexByUnitID = {},
		healthbarByDefID = {},
	}
end

local function Show(param) end

local function clearControls()
	--[[
	for k,controls_cur in pairs(controls) do
		for _,controls in pairs(controls_cur) do
			controls:Dispose();
		end
	end
	--]]
	
	for _,tt in ipairs({ 'unit2', 'feature2', 'corpse2', 'drawing2', 'terra', 'morph2', 'ud2',
		'selunit2', 'tt_text2'	,
		}) do
		if controls[tt] then
			for _,controls in pairs(controls[tt]) do
				controls:Dispose();
			end
		end
		controls[tt]=nil
	end
	
	for _,gi in ipairs({ 'buildpic_unit', 'buildpic_feature', 'buildpic_selunit', 'buildpic_morph', 'buildpic_ud', 'morphs' }) do
		
		if globalitems[gi] then
			globalitems[gi]:Dispose()
		end
		globalitems[gi] = nil
	end
end

local function CreateHpBar() end
local function CreateBpBar() end
local function CreateShieldBar() end


local selPath = 'Settings/HUD Panels/Selected Units Panel'
options = {
	large = {
		name = 'Large Tooltip',
		desc = 'For high-resolution screens',
		type = 'bool',
		value = false,
		noHotkey = true,
		OnChange = function(self)
			option_Deselect()
			if self.value then
				ttFontSize 			= 16 
				leftbar_width 		= 130
				mainsection_width 	= 300
				buildpic_size 		= 90
				morph_text_width	= 40
				icon_size			= 30
				unitIcon_size		= 70
			else
				ttFontSize 			= 10
				leftbar_width 		= 96
				mainsection_width 	= 230
				buildpic_size 		= 55
				morph_text_width 	= 25
				icon_size			= 20
				unitIcon_size		= 50
			end
			clearControls()
			
			CreateHpBar('hp_unit')
			CreateHpBar('hp_selunit')
			CreateHpBar('hp_feature')
			CreateHpBar('hp_corpse')
			
			CreateBpBar('bp_selunit')
		
			CreateShieldBar('shield_unit')
			CreateShieldBar('shield_selunit')
	--]]
		end,
	},
	tooltip_delay = {
		name = 'Tooltip display delay (0 - 4s)',
		desc = 'Determines how long you can leave the mouse idle until the tooltip is displayed.',
		type = 'number',
		min=0,max=4,step=0.05,
		value = 0,
	},
	independant_world_tooltip_delay = {
		name = 'Unit and Feature tooltip delay (0 - 4s)',
		--desc = 'Determines how long you can leave the mouse over a unit or feature until the tooltip is displayed.',
		type = 'number',
		min=0,max=4,step=0.05,
		value = 0.2,
	},
	--[[ This is causing it so playername is not always visible, too difficult to maintain.
	fontsize = {
		name = 'Font Size (10-20)',
		desc = 'Resizes the font of the tip',
		type = 'number',
		min=10,max=20,step=1,
		value = 10,
		OnChange = FontChanged,
	},
	--]]
	hpshort = {
		name = "Short Number Notation",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'Shows short number notation for HP and other values.',
	},
	featurehp = {
		name = "Show HP on Features",
		type = 'bool',
		advanced = true,
		noHotkey = true,
		value = false,
		desc = 'Shows healthbar for features.',
		OnChange = function() 
			if controls['feature2'] then
				for _,controls in pairs(controls['feature2']) do
					controls:Dispose();
				end
			end
			if controls['corpse2'] then
				for _,controls in pairs(controls['corpse2']) do
					controls:Dispose();
				end
			end
			controls['feature2']=nil; 
			controls['corpse2']=nil; 
		end,
	},
	show_for_units = {
		name = "Show Tooltip for Units",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Show the tooltip for units.',
	},
	show_for_wreckage = {
		name = "Show Tooltip for Wreckage",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Show the tooltip for wreckage and map features.',
	},
	show_for_unreclaimable = {
		name = "Show Tooltip for Unreclaimables",
		type = 'bool',
		advanced = true,
		value = false,
		noHotkey = true,
		desc = 'Show the tooltip for unreclaimable features.',
	},
	show_position = {
		name = "Show Position Tooltip",
		type = 'bool',
		advanced = true,
		value = true,
		noHotkey = true,
		desc = 'Show the position tooltip, even when showing extended tooltips.',
	},
	show_unit_text = {
		name = "Show Unit Text Tooltips",
		type = 'bool',
		advanced = true,
		value = true,
		noHotkey = true,
		desc = 'Show the text-only tooltips for units selected but not pointed at, even when showing extended tooltips.',
	},
	showdrawtooltip = {
		name = "Show Map-drawing Tooltip",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Show map-drawing tooltip when holding down the tilde (~).',
	},

	showterratooltip = {
		name = "Show Terraform Tooltip",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'Show terraform tooltip when performing terraform commands.',
	},
	
	showDrawTools = {
		name = "Show Drawing Tools When Drawing",
		type = 'bool',
		value = true,
		noHotkey = true,
		path = 'Settings/Interface/Mouse Cursor',
		desc = 'Show pencil or eraser when drawing or erasing.',
		OnChange = function(self)
			widget:UpdateCallIns(self.value)
		end
	},

	selection_opacity = {
		name = "Opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			window_corner.backgroundColor = {1,1,1,self.value}
			window_corner:Invalidate()
		end,
		path = selPath,
	},
	groupalways = {name='Always Group Units', type='bool', value=false, OnChange = option_Deselect,
		path = selPath,
	},
	showgroupinfo = {name='Show Group Info', type='bool', value=true, OnChange = option_Deselect,
		path = selPath,
	},
	squarepics = {name='Square Buildpics', type='bool', value=false, OnChange = option_Deselect,
		path = selPath,
	},
	unitCommand = {
		name="Show Unit's Command",
		type='bool',
		value= false,
		noHotkey = true,
		desc = "Display current command on unit's icon (only for ungrouped unit selection)",
		path = selPath,
	},
	uniticon_size = {
		name = 'Icon size on selection list',
		--desc = 'Determines how small the icon in selection list need to be.',
		type = 'number',
		OnChange = function(self) 
			option_Deselect()
			unitIcon_size = math.modf(self.value)
		end,
		min=30,max=50,step=1,
		value = 50,
		path = selPath,
	},
	manualWeaponReloadBar = {
		name="Show Unit's Special Weapon Status",
		type='bool',
		value= true,
		noHotkey = true,
		desc = "Show reload progress for weapon that use manual trigger (only for ungrouped unit selection)",
		path = selPath,
		OnChange = option_Deselect,
	},
	alwaysShowSelectionWin = {
		name="Always Show Selection Window",
		type='bool',
		value= false,
		noHotkey = true,
		desc = "Always show the selection window even if nothing is selected.",
		path = selPath,
		OnChange = function(self)
			if self.value and real_window_corner then
				Show(real_window_corner)
			end
			widget:SelectionChanged(Spring.GetSelectedUnits())
		end,
	},
	fancySkinning = {
		name = 'Fancy Skinning',
		type = 'radioButton',
		value = 'panel',
		path = selPath,
		items = {
			{key = 'panel', name = 'None'},
			{key = 'panel_1120', name = 'Bottom Left Flush',},
			{key = 'panel_0120', name = 'Bot Mid Left Flush',},
			{key = 'panel_2120', name = 'Bot Mid Both Flush',},
		},
		OnChange = function (self)
			local currentSkin = Chili.theme.skin.general.skinName
			local skin = Chili.SkinHandler.GetSkin(currentSkin)
			
			local className = self.value
			local newClass = skin.panel
			if skin[className] then
				newClass = skin[className]
			end
			
			window_corner.tiles = newClass.tiles
			window_corner.TileImageFG = newClass.TileImageFG
			--window_corner.backgroundColor = newClass.backgroundColor
			window_corner.TileImageBK = newClass.TileImageBK
			if newClass.padding then
				window_corner.padding = newClass.padding
				window_corner:UpdateClientArea()
			end
			window_corner:Invalidate()
		end,
		advanced = true,
		noHotkey = true,
	},
	leftPadding = {
		name = "Left Padding",
		type = "number",
		value = 0, min = 0, max = 500, step = 1,
		OnChange = function(self)
			window_corner.padding[1] = 8 + self.value
			window_corner:UpdateClientArea()
		end,
		path = selPath,
	},
}


--[[
local function FontChanged() 
	controls = {}
	controls_icons = {}
	ttFontSize = options.fontsize.value
end
--]]

--options.fontsize.OnChange = FontChanged


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--helper functions

local function GetHealthColor(fraction, returnType)
	local midpt = (fraction > .5)
	local r, g
	if midpt then 
		r = ((1-fraction)/0.5)
		g = 1
	else
		r = 1
		g = (fraction)/0.5
	end
	if returnType == "char" then
		return string.char(255,math.floor(255*r),math.floor(255*g),0)
	end
	return {r, g, 0, 1}
end

function round(num, idp)
	if (not idp) then
		return math.floor(num+.5)
	else
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
end


local function numformat(num, displaySign)
	return options.hpshort.value and ToSI(num, displaySign) or numformat2(num, displaySign)
end

function numformat2(amount, displaySign)
	local formatted

	if type(amount) == "number" then
		if (amount ==0) then formatted = "0" else 
			if (amount < 20 and (amount * 10)%10 ~=0) then 
				if displaySign then formatted = strFormat("%+.1f", amount)
				else formatted = strFormat("%.1f", amount) end 
			else 
				if displaySign then formatted = strFormat("%+d", amount)
				else formatted = strFormat("%d", amount) end 
			end 
		end
	else
		formatted = amount .. ""
	end
	return formatted
end

--[[
function comma_value(amount, displaySign)
	local formatted

	local k
	while true do  
		formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	
  	return formatted
end
--]]

local function GetUnitResources(unitID)		
	local mm, mu, em, eu = Spring.GetUnitResources(unitID)
	
	mm = (mm or 0) + (spGetUnitRulesParam(unitID, "current_metalIncome") or 0)
	em = (em or 0) + (spGetUnitRulesParam(unitID, "current_energyIncome") or 0)
	eu = (eu or 0) + (spGetUnitRulesParam(unitID, "overdrive_energyDrain") or 0)
	
	if mm ~= 0 or mu ~= 0 or em ~= 0 or eu ~= 0 then
		return mm, (mu or 0), em, eu
	else
		return
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--functions

local function DrawScreenDrawTools()
	
	if not drawtoolKeyPressed then return end
	
	local x, y, lmb, mmb, rmb = Spring.GetMouseState()
	drawing = lmb
	erasing = rmb
	addingPoint = mmb
	
	local filefound

	if erasing then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/eraser.png')
	elseif addingPoint then
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/Crystal_Clear_action_flag.png')
	else
		filefound = glTexture(LUAUI_DIRNAME .. 'Images/drawingcursors/pencil.png')
	end
	
	if filefound then
		--do teamcolor?
		glColor(1,1,1,1) 
		Spring.SetMouseCursor('none')
		glTexRect(x, y-cursor_size, x+cursor_size, y)
		glTexture(false)
		--glColor(1,1,1,1)
	end
end

--get reload status for selected weapon
local function GetWeaponReloadStatus(unitID, weapNum)
	local unitDefID = spGetUnitDefID(unitID)
	local unitDef = UnitDefs[unitDefID]
	local weaponNoX = (unitDef and unitDef.weapons and unitDef.weapons[weapNum]) --Note: weapon no.3 is by ZK convention is usually used for user controlled weapon
	if (weaponNoX ~= nil) and WeaponDefs[weaponNoX.weaponDef].manualFire then
		local reloadTime = WeaponDefs[weaponNoX.weaponDef].reload
		local _, _, weaponReloadFrame, _, _ = spGetUnitWeaponState(unitID, weapNum) --select weapon no.X
		if weaponReloadFrame then
			local currentFrame, _ = spGetGameFrame() 
			local remainingTime = (weaponReloadFrame - currentFrame)*secondPerGameFrame
			local reloadFraction =1 - remainingTime/reloadTime
			return reloadFraction, remainingTime
		end
	end
	return nil --Note: this mean unit doesn't have weapon number 'weapNum'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- group selection functions

--updates cost, HP, and resourcing info for group info
local function UpdateDynamicGroupInfo()
	local total_cost = 0
	local total_hp = 0
	local total_metalincome = 0
	local total_metaldrain = 0
	local total_energyincome = 0
	local total_energydrain = 0
	local total_usedbp = 0
	
	local id,defID,ud --micro optimization, avoiding repeated localization.
	local name,hp,paradam,cap,build,mm,mu,em,eu
	local stunned_or_inbuld
	local tooltip,baseMetal,s,od
	for i = 1, numSelectedUnits do
		id = selectedUnits[i][1]
		defID = selectedUnits[i][2]
		ud = UnitDefs[defID]
		if ud then
			name = ud.name 
			hp, _, paradam, cap, build = spGetUnitHealth(id)
			mm, mu, em, eu = GetUnitResources(id)

			if name ~= "terraunit" then
				if hp then--failsafe when switching spectator view.
					total_cost = total_cost + GetUnitCost(id, defID)*build
					total_hp = total_hp + hp
				end
				
				stunned_or_inbuld = spGetUnitIsStunned(id)
				if not stunned_or_inbuld then 
					if mm then --failsafe when switching spectator view.
						total_metalincome = total_metalincome + mm
						total_metaldrain = total_metaldrain + mu
						total_energyincome = total_energyincome + em
						total_energydrain = total_energydrain + eu
					end
					
					if ud.buildSpeed ~= 0 and mm then
						total_usedbp = total_usedbp + mu
					end
				end
			end
		end
		
	end
	
	unitInfoSum.count = numSelectedUnits
	unitInfoSum.cost = total_cost
	unitInfoSum.hp = total_hp
	unitInfoSum.metalincome = total_metalincome
	unitInfoSum.metaldrain = total_metaldrain
	unitInfoSum.energyincome = total_energyincome
	unitInfoSum.energydrain = total_energydrain
	unitInfoSum.usedbp = total_usedbp
end

--updates values that don't change over time for group info
local function UpdateStaticGroupInfo()
	local total_count = numSelectedUnits
	local total_finishedcost = 0
	local total_totalbp = 0
	local total_maxhp = 0
	
	local defID, unitID, ud
	for i = 1, numSelectedUnits do
		unitID = selectedUnits[i][1]
		defID = selectedUnits[i][2]
		ud = UnitDefs[defID]
		if ud then
			if ud.name ~= "terraunit" then
				total_totalbp = total_totalbp + GetUnitBuildSpeed(unitID, defID)
				total_maxhp = total_maxhp + (select(2, Spring.GetUnitHealth(unitID)) or 0)
				total_finishedcost = total_finishedcost + GetUnitCost(unitID, defID)
			end
		end
	end
	unitInfoSum.finishedcost = total_finishedcost
	unitInfoSum.totalbp = total_totalbp
	unitInfoSum.maxhp = total_maxhp
end

--this is a separate function to allow group info to be regenerated without reloading the whole tooltip
local function WriteGroupInfo()
	if label_unitInfo then
		label_unitInfo:Dispose(); --delete chili element
		label_unitInfo=nil;
	end
	
	if not options.showgroupinfo.value or numSelectedUnits==0 then
		return 
	end
	
	local dgunStatus = ''
	if stt_unitID and numSelectedUnits == 1 and options.manualWeaponReloadBar.value then
		local reloadFraction, remainingTime = GetWeaponReloadStatus(stt_unitID,3)  --select weapon no.3 (slot 3 is by ZK convention is usually used for user controlled weapon)
		if reloadFraction then
			if reloadFraction < 0.99 then
				remainingTime = math.floor(remainingTime)
				if remainingTime > 1000 then
					remainingTime = WG.Translate("interface", "never")
				else
					remainingTime = remainingTime .. "s"
				end
				dgunStatus = "\n" .. WG.Translate("interface", "special") .. "\255\255\90\90 " .. WG.Translate("interface", "reloading") .. "\255\255\255\255 (" .. remainingTime .. ")"  --red and white
			else
				dgunStatus = "\n" .. WG.Translate("interface", "special") .. "\255\90\255\90 " .. WG.Translate("interface", "ready") .. "\255\255\255\255"
			end
		end
	end
	local metal = (tonumber(unitInfoSum.metalincome)>0 or tonumber(unitInfoSum.metaldrain)>0) and ("\n" .. WG.Translate("interface", "metal") .. " \255\0\255\0" .. numformat(unitInfoSum.metalincome, true) .. "\255\255\255\255 / \255\255\0\0" ..  numformat(-unitInfoSum.metaldrain, true)  .. "\255\255\255\255") or '' --have metal or ''
	local energy = (tonumber(unitInfoSum.energyincome)>0 or tonumber(unitInfoSum.energydrain)>0) and ("\n" .. WG.Translate("interface", "energy") .. " \255\0\255\0" .. numformat(unitInfoSum.energyincome, true) .. "\255\255\255\255 / \255\255\0\0" .. numformat(-unitInfoSum.energydrain, true) .. "\255\255\255\255") or '' --have energy or ''
	local buildpower = (tonumber(unitInfoSum.totalbp)>0) and ("\n" .. WG.Translate("interface", "buildpower") .. " " .. numformat(unitInfoSum.usedbp) .. " / " ..  numformat(unitInfoSum.totalbp)) or ''  --have buildpower or ''
	local unitInfoString = 
		WG.Translate("interface", "selected_units") .. ": " .. numformat(unitInfoSum.count) ..
		"\n" .. WG.Translate("interface", "health") .. ": " .. numformat(unitInfoSum.hp) .. " / " ..  numformat(unitInfoSum.maxhp) ..
		"\n" .. WG.Translate("interface", "value") .. ": " .. numformat(unitInfoSum.cost) .. " / " ..  numformat(unitInfoSum.finishedcost) ..
		metal .. energy ..	buildpower .. dgunStatus
	
	label_unitInfo = Label:New{ --recreate chili element (rather than just updating caption) to avoid color bug
		parent = window_corner;
		y=5,
		right=5,
		x=window_corner.width-150-(options.large.value and 30 or 0),
		height  = '100%';
		width = options.large.value and 150 or 120,
		caption = unitInfoString;
		valign  = 'top';
		fontSize = ttFontSize+2;
		fontShadow = true;
	}
	
end

-- group selection functions
----------------------------------------------------------------
----------------------------------------------------------------

Show = function(obj)
	if (not obj:IsDescendantOf(screen0)) then
		screen0:AddChild(obj)
	end
end

local function DisposeSelectionDisplay()
	local windowCornerData = globalitems["window_corner_direct_child"]
	if windowCornerData then
		if windowCornerData.disposable then
			windowCornerData[1]:Dispose()
			if windowCornerData[2] then
				windowCornerData[2]:Dispose()
			end
		else
			window_corner:RemoveChild(windowCornerData[1])
			if windowCornerData[2] then
				window_corner:RemoveChild(windowCornerData[2])
			end
		end
		globalitems["window_corner_direct_child"]=nil
	end
end

local function SelectionTooltips()
	return "\n\255\0\255\0" .. WG.Translate("interface", "lmb") .. ": " .. WG.Translate("interface", "select") .. "\n" .. WG.Translate("interface", "rmb") .. ": " .. WG.Translate("interface", "deselect") .. "\n" .. WG.Translate("interface", "shift") .. "+" .. WG.Translate("interface", "lmb") .. ": " .. WG.Translate("interface", "select_type") .. "\n" .. WG.Translate("interface", "shift") .. "+" .. WG.Translate("interface", "rmb") .. ": " .. WG.Translate("interface", "deselect_type") .. "\n" .. WG.Translate("interface", "mmb") .. ": " .. WG.Translate("interface", "go_to")
end

local function AddSelectionIcon(index,unitid,defid,unitids,counts)
	counts = counts or 1
	local ud = UnitDefs[defid]
	
	if multiSelect.unitSquare.data[index] then
		local squareData = multiSelect.unitSquare.data[index]
		squareData.defid = defid
		squareData.unitid = unitid
		squareData.unitids = unitids
		
		squareData.image.tooltip = GetHumanName(ud, unitid) .. " - " .. GetDescription(ud, unitid) .. SelectionTooltips()
		squareData.image.file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(UnitDefs[defid]))
		squareData.image.file = "#" .. defid
		
		if counts > 1 then
			if squareData.label then
				if not squareData.labelIsChild then
					squareData.image:AddChild(squareData.label)
					squareData.labelIsChild = true
				end
				squareData.label:SetCaption(counts)
			else
				squareData.labelIsChild = true
				squareData.label = Label:New{
					name = "selLabel";
					parent = squareData.image;
					align  = "right";
					valign = "top";
					x =  unitIcon_size*0.16;
					--y = 30;
					y = unitIcon_size*0.4;
					width = unitIcon_size*0.8;
					fontsize   = 20;
					fontshadow = true;
					fontOutline = true;
					caption    = counts;
				};
			end
		else
			if squareData.label and squareData.labelIsChild then
				squareData.image:RemoveChild(squareData.label)
				squareData.labelIsChild = false
			end
		end
		
		if unitid then
			multiSelect.indexByUnitID[unitid] = index
		end
		if defid then
			multiSelect.healthbarByDefID[defid] = squareData.healthbar
		end
		
		if squareData.reloadbarIsChild then
			squareData.panel:RemoveChild(squareData.reloadbar)
			squareData.reloadbarIsChild = false
		end
		
		squareData.image:Invalidate()
	else
		multiSelect.unitSquare.count = multiSelect.unitSquare.count + 1
		multiSelect.unitSquare.data[index] = {
			defid = defid,
			unitid = unitid,
			unitids = unitids,
			isChild = true,
		}
		local squareData = multiSelect.unitSquare.data[index]
		
		squareData.panel = LayoutPanel:New{
			name    = index;
			parent  = multiSelect.barGrid;
			width   = unitIcon_size;
			height  = unitIcon_size*1.24;
			columns = 1;
			padding     = {0,0,0,0};
			itemPadding = {0,0,0,0};
			itemMargin  = {0,0,0,1};
			resizeItems = false;
			centerItems = false;
			autosize    = true;		
		}
		squareData.image = Image:New{
			name = "selImage";
			parent  = squareData.panel;
			tooltip = GetHumanName(ud, unitid) .. " - " .. GetDescription(ud, unitid) .. SelectionTooltips();
			file2   = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(UnitDefs[defid]));
			file    = "#" .. defid;
			keepAspect = false;
			height  = unitIcon_size * (options.squarepics.value and 1 or (4/5));
			--height  = 50;
			width   = unitIcon_size;
			padding = {0,0,0,0}; --FIXME something overrides the default in image.lua!!!!
			OnClick = {function(_,_,_,button)
				
				local alt, ctrl, meta, shift = spGetModKeyState()
				
				if (button==3) then
					if shift then
						--// deselect a whole unitdef block
						for i = numSelectedUnits,1,-1 do
							if (selectedUnits[i][2] == squareData.defid) then
								table.remove(selectedUnits,i)
								if not shift then
									break
								end
							end
						end
					else
						--// deselect a single unit
						local removed = false
						if squareData.unitid then
							for i = numSelectedUnits, 1, -1 do
								if (selectedUnits[i][1] == squareData.unitid) then
									table.remove(selectedUnits,i)
									removed = true
									break
								end
							end
						end
						if not removed then
							for i = numSelectedUnits, 1, -1 do
								if (selectedUnits[i][2] == squareData.defid) then
									table.remove(selectedUnits,i)
									break
								end
							end
						end
					end
					local selectedIds = {}
					for i = 1, #selectedUnits do
						selectedIds[i] = selectedUnits[i][1]
					end
					spSelectUnitArray(selectedIds)
					--update selected units right now
					local sel = spGetSelectedUnits()
					widget:SelectionChanged(sel)
				elseif button == 1 then
					if shift then
						spSelectUnitArray(selectedUnitsByDef[squareData.defid]) -- select all
					else
						if squareData.unitid then
							spSelectUnitArray({squareData.unitid})
						else						
							spSelectUnitArray({ selectedUnitsByDef[squareData.defid][1] })  -- only 1	
						end
					end
				else --button2 (middle)
					local x,y,z = spGetUnitPosition( squareData.unitids[1] )
					SetCameraTarget(x,y,z, 1)
				end
			end}
		};
		if counts > 1 then
			squareData.labelIsChild = true
			squareData.label = Label:New{
				name = "selLabel";
				parent = squareData.image;
				align  = "right";
				valign = "top";
				x =  unitIcon_size*0.16;
				--y = 30;
				y = unitIcon_size*0.4;
				width = unitIcon_size*0.8;
				fontsize   = 20;
				fontshadow = true;
				fontOutline = true;
				caption    = counts;
			};
		end
		squareData.healthbar = Progressbar:New{
			parent  = squareData.panel;
			name    = 'health';
			width   = unitIcon_size;
			height  = unitIcon_size*0.2;
			max     = 1;
			color   = {0.0,0.99,0.0,1};
		};
		
		if unitid then
			multiSelect.indexByUnitID[unitid] = index
		end
		if defid then
			multiSelect.healthbarByDefID[defid] = squareData.healthbar
		end
		
		if squareData.reloadbarIsChild then
			squareData.panel:RemoveChild(squareData.reloadbar)
			squareData.reloadbarIsChild = false
		end
	end
end

local function MakeUnitGroupSelectionToolTip()
	local infoSection_size = 131
	if not multiSelect.barGrid then
		multiSelect.barGrid = LayoutPanel:New{
			name     = 'Bars';
			resizeItems = false;
			centerItems = false;
			height  = "100%";
			x=0,
			--width   = "100%";
			right = options.showgroupinfo.value and infoSection_size or 0, --expand to right
			--columns = 5;
			padding     = {0,0,0,0},
			itemPadding = {0,0,0,0};
			itemMargin  = {0,0,2,2};
			tooltip = "Left Click: Select unit(s)\nRight Click: Deselect unit(s)\nMid Click: Focus camera to unit";
		}
	end
	
	--estimate how many picture can fit into the selection grid
	local maxRight = window_corner.width - (options.showgroupinfo.value and infoSection_size or 0) - 20
	local horizontalFit =  math.modf(maxRight/(unitIcon_size+2))
	local verticalFit = math.modf((window_corner.height  - 20)/(unitIcon_size+2))
	maxPicFit = horizontalFit*verticalFit
	local pictureWithinCapacity = (numSelectedUnits <= maxPicFit)

	WriteGroupInfo() --write selection summary text on right side of the panel

	local index = 1
	multiSelect.indexByUnitID = {}
	multiSelect.healthbarByDefID = {}
	
	if ( pictureWithinCapacity and (not options.groupalways.value)) then
		local unitid,defid,unitids
		while index <= numSelectedUnits do
			unitid = selectedUnits[index][1]
			defid  = selectedUnits[index][2]
			unitids = {unitid}

			AddSelectionIcon(index,unitid,defid,unitids)
			local squareData = multiSelect.unitSquare.data[index]
			if not squareData.isChild then
				multiSelect.barGrid:AddChild(squareData.panel)
				squareData.isChild = true
			end
			index = index + 1
		end
	else
		local defid,unitids,counts
		maxPicFit = math.min(#selectionSortOrder,maxPicFit)
		while index <= maxPicFit do
			defid   = selectionSortOrder[index]
			unitids = selectedUnitsByDef[defid]
			counts  = selectedUnitsByDefCounts[defid]
			AddSelectionIcon(index,nil,defid,unitids,counts)
			local squareData = multiSelect.unitSquare.data[index]
			if not squareData.isChild then
				multiSelect.barGrid:AddChild(squareData.panel)
				squareData.isChild = true
			end
			index = index + 1
		end
	end
	
	-- Remove the unneeded children
	while index <= multiSelect.unitSquare.count do
		local squareData = multiSelect.unitSquare.data[index]
		if squareData.isChild then
			multiSelect.barGrid:RemoveChild(squareData.panel)
			squareData.isChild = false
		end
		index = index + 1
	end
	
	return multiSelect.barGrid
end


local function UpdateSelectedUnitsTooltip()
	if (numSelectedUnits>1) then
		local barsContainer = window_corner.childrenByName['Bars']

		if ((numSelectedUnits <= maxPicFit) and (not options.groupalways.value)) then
			for i=1,numSelectedUnits do
				local unitid = selectedUnits[i][1]
				--Spring.Echo(unitid)
				local index = multiSelect.indexByUnitID[unitid]
				local squareData = multiSelect.unitSquare.data[index]
				local healthbar = squareData.healthbar
				local health, maxhealth = spGetUnitHealth(unitid)
				if health and healthbar then --safety against spectating in limited LOS
					healthbar.tooltip = numformat(health) .. ' / ' .. numformat(maxhealth)
					healthbar.color = GetHealthColor(health/maxhealth)
					healthbar:SetValue(health/maxhealth) --update the healthbar value
				end
				
				if options.manualWeaponReloadBar.value then
					local reloadFraction,remainingTime = GetWeaponReloadStatus(unitid, 3)
					if squareData.reloadbar then
						if reloadFraction and reloadFraction < 0.99 then
							if not squareData.reloadbarIsChild then
								squareData.panel:AddChild(squareData.reloadbar)
								squareData.reloadbarIsChild = true
							end
							squareData.reloadbar:SetValue(reloadFraction)
						else
							if squareData.reloadbarIsChild then
								squareData.panel:RemoveChild(squareData.reloadbar)
								squareData.reloadbarIsChild = false
							end
						end	
					else
						if reloadFraction and reloadFraction < 0.99 then
							squareData.reloadbarIsChild = true
							squareData.reloadbar = Progressbar:New{
								parent  = squareData.panel;
								name    = 'reloadMiniBar';
								width   = unitIcon_size*0.98;
								height  = unitIcon_size*0.04;
								minHeight = unitIcon_size*0.04;
								max     = 1;
								value = reloadFraction;
								color   = {013, 245, 243,1}; --? 
							};
						end
					end
				end
			end
		else
			for defid,unitids in pairs(selectedUnitsByDef) do --when grouped by unitDef
				local health = 0
				local maxhealth = 0
				for i=1,#unitids do
					local uhealth, umaxhealth = spGetUnitHealth(unitids[i])
					if (health) then
						health = health + (uhealth or 0)
						maxhealth = maxhealth + (umaxhealth or 0)
					end
				end
				local healthbar = multiSelect.healthbarByDefID[defid]
				if healthbar then
					healthbar.tooltip = numformat(health) .. ' / ' .. numformat(maxhealth)
					healthbar.color = GetHealthColor(health/maxhealth)
					healthbar:SetValue(health/maxhealth)
				end
			end
		end
	end
end

local function AdjustWindow(window)
	local nx
	if (0 > window.x) then
		nx = 0
	elseif (window.x + window.width > screen0.width) then
		nx = screen0.width - window.width
	end

	local ny
	if (0 > window.y) then
		ny = 0
	elseif (window.y + window.height > screen0.height) then
		ny = screen0.height - window.height
	end

	if (nx or ny) then
		window:SetPos(nx,ny)		
	end

	--//FIXME If we don't do this the stencil mask of stack_rightside doesn't get updated, when we move the mouse (affects only if type(stack_rightside) == StackPanel)
	stack_main:Invalidate()
	stack_leftbar:Invalidate()
	
	if window_tooltip2:GetChildByName('leftbar') then
		window_tooltip2:GetChildByName('leftbar'):Invalidate()
	end
	window_tooltip2:GetChildByName('main'):Invalidate()
	
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--tooltip functions

local UnitDefByHumanName_cache = {}
local UnitDefByHumanNameCommander_cache = {}
local function GetUnitDefByHumanName(humanName, findCommander)
	local cache
	if findCommander then
		cache = UnitDefByHumanNameCommander_cache
	else
		cache = UnitDefByHumanName_cache
	end
	local cached_udef = cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end
	
	for _,ud in pairs(UnitDefs) do
		if ud.humanName == humanName and (((ud.customParams and ud.customParams.dynamic_comm and (not ud.customParams.not_starter) and true) or false) == findCommander) then
			cache[humanName] = ud
			return ud
		end
	end
	cache[humanName] = false
	return false
end

local function tooltipBreakdown(tooltip)
	local unitname = nil
	tooltip = tooltip:gsub('\r', '\n')
	tooltip = tooltip:gsub('\n+', '\n')
	
	local requires, provides, consumes, unitDef, buildType, morph_data
	if tooltip:find('Requires', 5, true) == 5 then
		requires, tooltip = tooltip:match('....Requires([^\n]*)\n....(.*)')
	end
	
	if tooltip:find('Provides', 1, true) == 1 then
		provides, tooltip = tooltip:match('Provides([^\n]*)\n(.*)')
	end
	
	if tooltip:find('Consumes', 5, true) == 5 then
		--consumes, tooltip = tooltip:match('....Consumes([^\n]*)\n....(.*)')
	end
	
	if tooltip:find('Build', 1, true) == 1 then
		local start,fin = tooltip:find([[ - ]], 1, true)
		if start and fin then
			
			local unitHumanName
			
			if (tooltip:find('Build Unit:', 1, true) == 1) then
				buildType = 'buildunit'
				unitHumanName = tooltip:sub(13,start-1)
			else
				buildType = 'build'
				unitHumanName = tooltip:sub(8,start-1)
			end
			unitDef = GetUnitDefByHumanName(unitHumanName, tooltip:find('BuildCo', 1, true) == 1)
			
			tooltip = tooltip:sub(fin+1)
		end
		
	elseif tooltip:find('Morph', 1, true) == 1 then
		
		local unitHumanName = tooltip:gsub('Morph into a (.*)(time).*', '%1'):gsub('[^%a \-]', '')
		unitDef = GetUnitDefByHumanName(unitHumanName, false)
		
		local needunit
		if tooltip:find('needs unit', 1, true) then
  			needunit = tooltip:gsub('.*needs unit: (.*)', '%1'):gsub('[^%a \-]', '')
		end
		morph_data = {
			morph_time 		= tooltip:gsub('.*time:(.*)metal.*', '%1'):gsub('[^%d]', ''),
			morph_cost 		= tooltip:gsub('.*metal: (.*)energy.*', '%1'):gsub('[^%d]', ''),
			morph_prereq 	= needunit,
		}
	end
	
	return {
		tooltip		= tooltip, 
		unitDef		= unitDef, 
		buildType	= buildType, 
		morph_data	= morph_data,
		requires	= requires,
		provides	= provides,
		consumes	= consumes,
	}
end

--tooltip functions
----------------------------------------------------------------

local function SetHealthbar(tt_healthbar,health, maxhealth, unitID)
	if health and maxhealth and (maxhealth > 0) then
		tt_health_fraction = health/maxhealth
		tt_healthbar.color = GetHealthColor(tt_health_fraction)
		tt_healthbar:SetValue(tt_health_fraction)

		local regenStr = ""
		if unitID and (health < maxhealth) and (not select(3, spGetUnitIsStunned(unitID))) then
			local ud = UnitDefs[Spring.GetUnitDefID(unitID)]
			local regen_timer = Spring.GetUnitRulesParam(unitID, "idleRegenTimer")
			if regen_timer then
				if ((ud.idleTime <= 300) and (regen_timer > 0)) then
					regenStr = "  (" .. math.ceil(regen_timer / 30) .. "s)"
				else
					local regen = 0
					if (regen_timer <= 0) then
						regen = regen + (spGetUnitRulesParam(unitID, "comm_autorepair_rate") or ud.customParams.idle_regen)
					end
					if ud.customParams.amph_regen then
						local x,y,z = Spring.GetUnitPosition(unitID)
						local h = Spring.GetGroundHeight(x,z) or y
						if (h < 0) then
							regen = regen + math.min(ud.customParams.amph_regen, ud.customParams.amph_regen*(-h / ud.customParams.amph_submerged_at))
						end
					end
					if ud.customParams.armored_regen and Spring.GetUnitArmored(unitID) then
						regen = regen + ud.customParams.armored_regen
					end
					if (regen > 0) then
						regenStr = "  (+" .. math.ceil(regen) .. ")"
					end
				end
			end
		end

		if options.hpshort.value then
			tt_healthbar:SetCaption(numformat(health) .. ' / ' .. numformat(maxhealth) .. regenStr)
		else
			tt_healthbar:SetCaption(math.ceil(health) .. ' / ' .. math.ceil(maxhealth) .. regenStr)
		end
		
	else
		tt_healthbar.color = {0,0,0.5, 1}
		local maxhealth = (tt_fd and tt_fd.health) or (tt_ud and tt_ud.health) or 0
		tt_healthbar:SetValue(1)
		if options.hpshort.value then
			tt_healthbar:SetCaption('??? / ' .. numformat(maxhealth))
		else
			tt_healthbar:SetCaption('??? / ' .. math.ceil(maxhealth))
		end
	end
end

local function SetHealthbars()
	if 
		not ( tt_unitID or tt_fid or stt_unitID )
		then
		return
	end
	local tt_healthbar_stack, tt_healthbar
	
	local health, maxhealth
	if tt_unitID then
		health, maxhealth = spGetUnitHealth(tt_unitID)
		tt_healthbar = globalitems.hp_unit:GetChildByName('bar')
		SetHealthbar(tt_healthbar,health, maxhealth, tt_unitID)
	elseif tt_fid then
		health, maxhealth = Spring.GetFeatureHealth(tt_fid)
		tt_healthbar_stack = tt_ud and globalitems.hp_corpse or globalitems.hp_feature
		tt_healthbar = tt_healthbar_stack:GetChildByName('bar')
		SetHealthbar(tt_healthbar,health, maxhealth)
	end
	
	if stt_unitID then
		health, maxhealth = spGetUnitHealth(stt_unitID)
		tt_healthbar = globalitems.hp_selunit:GetChildByName('bar')
		SetHealthbar(tt_healthbar,health, maxhealth, stt_unitID)
	end
end

local function KillTooltip(force)
	old_ttstr = ''
	tt_unitID = nil
	
	if window_tooltip2 then --and window_tooltip2:IsDescendantOf(screen0) then --does IsDescendantOf() check needed? doesn't appear to have visual difference.
		screen0:RemoveChild(window_tooltip2)
	end
end


local function GetResources(tooltip_type, unitID, ud)
	local metal, energy = 0,0
	local color_m = white
	local color_e = white
	
	if tooltip_type == 'feature' or tooltip_type == 'corpse' then
		metal = ud.metal
		energy = ud.energy
		if unitID then
			local m, _, e, _, _ = Spring.GetFeatureResources(unitID)
			metal = m or metal
			if (metal < 1) then metal = 0 end
			energy =  e or energy
		end
	else --tooltip_type == 'unit' or 'selunit'
		local metalMake, metalUse, energyMake, energyUse = GetUnitResources(unitID)
		
		if metalMake then
			metal = metalMake - metalUse
		end
		if energyMake then
			energy = energyMake - energyUse
		end
	end
	
	--Skip metal/energy rendering for unit selection bar when unit has no metal and energy
	--if tooltip_type == 'selunit' and metal==0 and energy==0 then
	if metal==0 and energy==0 then
		return '',''
	end	
	
	if tooltip_type ~= 'feature' and tooltip_type ~= 'corpse' then
		if metal > 0 then
			color_m = green
		elseif metal < 0 then
			color_m = red
		end
		if energy > 0 then
			color_e = green
		elseif energy < 0 then
			color_e = red
		end
	end
	local displayPlusMinus = tooltip_type ~= 'feature' and tooltip_type ~= 'corpse' 
	
	return color_m .. numformat(metal, displayPlusMinus), color_e .. numformat(energy, displayPlusMinus)	
end

local function PlaceToolTipWindow2(x,y)
	if not window_tooltip2 then return end
	
	if not window_tooltip2:IsDescendantOf(screen0) then
		screen0:AddChild(window_tooltip2)
	end
	
	local x = x
	local y = scrH-y
	window_tooltip2:SetPos(x,y)
	AdjustWindow(window_tooltip2)

	window_tooltip2:BringToFront()
end

local function UpdateMorphControl(morph_data)
	
	local morph_controls = {}
	
	local height = 0
	
	local morph_time 	= ''
	local morph_cost 	= ''
	local morph_prereq 	= ''
	if morph_data then
		morph_time 	= morph_data.morph_time
		morph_cost 	= morph_data.morph_cost
		morph_prereq 	= morph_data.morph_prereq
		height = icon_size+1
		
	end	
	if globalitems.morphs then
		globalitems.morphs.height=height
		
		globalitems.morphs:GetChildByName('time'):SetCaption(morph_time)
		globalitems.morphs:GetChildByName('cost'):SetCaption(morph_cost)
		globalitems.morphs:GetChildByName('prereq'):SetCaption(morph_prereq and ('Need Unit: '..morph_prereq) or '')
		
		return
	end
	height = icon_size+1
	
	local cyan = {0,1,1,1}
	
	morph_controls[#morph_controls + 1] = Label:New{ caption = 'Morph: ', height= icon_size, valign='center', textColor=cyan , autosize=false, width=morph_text_width+20, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Image:New{file='LuaUI/images/clock.png',height= icon_size,width= icon_size, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Label:New{ name='time', caption = morph_time, valign='center', textColor=cyan , autosize=false, width=morph_text_width, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Image:New{file='LuaUI/images/cost.png',height= icon_size,width= icon_size, fontSize=ttFontSize,}
	morph_controls[#morph_controls + 1] = Label:New{ name='cost', caption = morph_cost, valign='center', textColor=cyan , autosize=false, width=morph_text_width, fontSize=ttFontSize,}
	
	--if morph_prereq then
		--morph_controls[#morph_controls + 1] = Label:New{ 'prereq' caption = 'Need Unit: '..morph_prereq, valign='center', textColor=cyan , autosize=false, width=180, fontSize=ttFontSize,}
		morph_controls[#morph_controls + 1] = Label:New{ name='prereq', caption = morph_prereq and ('Need Unit: '..morph_prereq) or '', valign='center', textColor=cyan , autosize=false, width=80, fontSize=ttFontSize,}
	--end
	
	
	globalitems.morphs = StackPanel:New {
		name = "morphs stackpanel",
		centerItems = false,
		autoArrangeV = true,
		orientation='horizontal',
		resizeItems=false,
		width = '100%',
		height = height,
		padding = {0,0,0,0},
		itemPadding = {0,0,0,0},
		itemMargin = {0,0,0,0},
		children = morph_controls,
	}
end


local function GetHelpText(tooltip_type)
	local _,_,_,buildUnitName = Spring.GetActiveCommand()
	if buildUnitName then
		return ''
	end

	local sc_caption = ''
	if tooltip_type == 'build' then
		sc_caption = WG.Translate("interface", "space_click_show_stats")
	elseif tooltip_type == 'buildunit' then
			if showExtendedTip then
			
				sc_caption = 
					WG.Translate("interface", "fac_modifier_keys_instruction") ..
					WG.Translate("interface", "space_click_show_stats")
			else
				sc_caption = WG.Translate("interface", "hold_space_for_help")
			end
	
	elseif tooltip_type == 'morph' then
		sc_caption = WG.Translate("interface", "space_click_show_stats")
	else
		sc_caption = WG.Translate("interface", "space_click_show_stats")
	end
	
	return sc_caption
	
end

local function MakeStack(ttname, ttstackdata, leftbar)
	local children = {}
	local height = 0
	
	for i, item in ipairs( ttstackdata ) do
		local stack_children = {}
		local empty = false
		
		if item.directcontrol then
			local directitem = globalitems[item.directcontrol] --copy new chili element from this global table (is updated everywhere around this widget)
			stack_children[#stack_children+1] = directitem

		elseif item.text or item.icon then
			local curFontSize = ttFontSize + (item.fontSize or 0)
			if ttname == 'tt_text2' then
				curFontSize = curFontSize +2
			end
			
			local itemtext =  item.text or ''
			local stackchildren = {}

			if item.icon then
				controls_icons[ttname][item.name] = Image:New{ 
					file = item.icon,
					height = icon_size+6,
					width= icon_size, 
					fontSize = curFontSize,
					valign='center',
				}
				stack_children[#stack_children+1] = controls_icons[ttname][item.name]
			end
			
			if item.wrap then
				controls[ttname][item.name] = TextBox:New{
					name=item.name, 				
					autosize=false,
					text = itemtext , 
					width='100%',
					valign="ascender", 
					font= { size=curFontSize },
					--fontShadow=true,
				}
				stack_children[#stack_children+1] = controls[ttname][item.name]
			else
				if item.description then
					controls[ttname][item.name] = Label:New{
						name=item.name, 				
						autosize=false,
						caption = itemtext , 
						width='100%',
						valign="ascender", 
						font= { size=curFontSize },
						--fontShadow=true,
					}
				else
					controls[ttname][item.name] = Label:New{
						margin = {(leftbar and 1) or 4, 1, 1, 1},
						fontShadow=true,
						defaultHeight=0,
						autosize=false,
						name=item.name,
						caption = itemtext,
						fontSize=curFontSize,
						align= item.center and 'center' or 'left',
						valign='center',
						height=icon_size+6,
						x=icon_size+50,
						right=1,
					}
				
				end
				stack_children[#stack_children+1] = controls[ttname][item.name]
			end
			
			if (not item.icon) and itemtext == '' then
				controls[ttname][item.name]:Resize('100%',0)
			end
			
			
		else
			empty = true
		end
		
		if not empty then
			children[#children+1] = StackPanel:New{
				name = "children stackpanel " .. #children+1,
				centerItems = false,
				autoArrangeV = true,
				orientation='horizontal',
				resizeItems=false,
				width = '100%',
				autosize=true,
				--padding = {1,1,1,1},
				padding = {0,0,0,0},
				--itemPadding = {1,1,0,0},
				itemPadding = {0,0,0,0},
				itemMargin = {0,0,0,0},
				children = stack_children,
			}
		end
	end
	return children
end

local function UpdateStack(ttname, stack)
	for i, item in ipairs( stack ) do
		local name = item.name
		
			if item.directcontrol then
				--local directitem = (type( item.directcontrol ) == 'string') and globalitems[item.directcontrol] or item.directcontrol
				local directitem = globalitems[item.directcontrol]
				--[[
				if hideitems[item.directcontrol] then
					directitem:Resize('100%',0)
				else
					directitem:Resize('100%',globalitemheights[item.directcontrol])
				end
				--]]
			end
			if controls[ttname][name] then			
				if item.wrap then	
					controls[ttname][name]:SetText( item.text )
					controls[ttname][name]:Invalidate()
				else
					controls[ttname][name]:SetCaption( item.text )
				end
			end
			if controls_icons[ttname][name] then
				if item.icon then
					controls_icons[ttname][name].file = item.icon
					controls_icons[ttname][name]:Invalidate()
				end
			end
		
	end
	
end

local function SetTooltip(tt_window)
	if not window_tooltip2 or window_tooltip2 ~= tt_window then
		KillTooltip(true)
		window_tooltip2 = tt_window
	end
	PlaceToolTipWindow2(mx+20,my-20)
end

local function BuildTooltip2(ttname, ttdata, sel)
	if not ttdata.main then
		echo '<Cursortip> Missing ttdata.main'
		return
	end
	if controls[ttname] and not sel then
		UpdateStack(ttname, ttdata.main)
		if ttdata.leftbar then
			UpdateStack(ttname, ttdata.leftbar)
		end
	else
		controls[ttname] = {}
		controls_icons[ttname] = {}
		local stack_leftbar_temp, stack_main_temp
		local children_main  = MakeStack(ttname, ttdata.main)
		local leftside = false
		if ttdata.leftbar then
			children_leftbar  = MakeStack(ttname, ttdata.leftbar)
			
			stack_leftbar_temp = 
				StackPanel:New{
					name = 'leftbar',
					orientation='vertical',
					padding = {0,0,0,0},
					itemPadding = {1,0,0,0},
					itemMargin = {0,0,0,0},
					resizeItems=false,
					autosize=true,
					width = leftbar_width,
					children = children_leftbar,
				}
			leftside = true
		else
			stack_leftbar_temp = StackPanel:New{ width=10, }
		end
		
		stack_main_temp = StackPanel:New{
			name = 'main',
			autosize=true,
			--x = leftside and 60 or 0,
			x = leftside and (leftbar_width-36) or 0,
			y = 0,
			orientation='vertical',
			centerItems = false,
			width = mainsection_width,
			padding = {0,0,0,0},
			itemPadding = {0,0,0,0},
			itemMargin = {0,0,0,0},
			--itemMargin = {1,1,1,1},
			resizeItems=false,
			children = children_main,
		}
		if not sel then
			windows[ttname] = Window:New{
				name = ttname,
				--skinName = 'default',
				useDList = false,
				resizable = false,
				draggable = false,
				autosize  = true,
				--tweakDraggable = true,
				children = { stack_leftbar_temp, stack_main_temp, },
				savespace = true
			}
		end
		if sel then
			return stack_main_temp, stack_leftbar_temp
		end
	end
	SetTooltip(windows[ttname])
end

local function GetUnitIcon(ud)
	if not ud then return false end
	return icontypes 
		and	icontypes[(ud and ud.iconType or "default")].bitmap
		or 	'icons/'.. ud.iconType ..iconFormat
end


local function MakeToolTip_Text(text)
	BuildTooltip2('tt_text2',{
		main = {
			{ name='text', text = text, wrap=true },
		}
	})
end

local function UpdateBuildpic( ud, globalitem_name, unitID )
	if not ud then return end
	
	if not globalitems[globalitem_name] then
		globalitems[globalitem_name] = Image:New{
			file = "#" .. ud.id,
			file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud)),
			tooltip = WG.Translate("interface", "mmb") .. ": " .. WG.Translate("interface", "go_to"),
			keepAspect = false,
			height  = buildpic_size*(4/5),
			width   = buildpic_size,
			unitID = unitID,
			
		}
		if globalitem_name == 'buildpic_selunit' then
			globalitems[globalitem_name].OnClick = {function(self,_,_,button)
				if (button==2) then
					--button2 (middle)
					local x,y,z = Spring.GetUnitPosition( self.unitID )
					if x then
						SetCameraTarget(x,y,z, 1)
					end
				end
			end}
		end
		return
	end
	
	globalitems[globalitem_name].unitID = unitID
	globalitems[globalitem_name].file = "#" .. ud.id
	globalitems[globalitem_name].file2 = (WG.GetBuildIconFrame)and(WG.GetBuildIconFrame(ud))
	globalitems[globalitem_name]:Invalidate()
end

local function SecondsToMinutesSeconds(seconds)
	if seconds%60 < 10 then
		return math.floor(seconds/60) ..":0" .. math.floor(seconds%60)
	else
		return math.floor(seconds/60) ..":" .. math.floor(seconds%60)
	end
end

local function MakeToolTip_UD(tt_table)
	
	local helptext = GetHelpText(tt_table.buildType)
	local iconPath = GetUnitIcon(tt_table.unitDef)
	
	local extraText = ""
	if mexDefID == tt_table.unitDef.id and WG.mouseoverMexIncome then
		extraText = ", ".. WG.Translate("interface", "income") .. " +" .. strFormat("%.2f", WG.mouseoverMexIncome)
		if WG.mouseoverMexIncome > 0 then
			local cost = metalStructureDefs[tt_table.unitDef.id].cost
			extraText = extraText .. "\n" .. WG.Translate("interface", "base_payback") .. ": " .. SecondsToMinutesSeconds(cost/WG.mouseoverMexIncome)
		else
			extraText = extraText .. "\n" .. WG.Translate("interface", "base_payback") .. ": " .. WG.Translate("interface", "never")
		end
	end

	local health = tt_table.unitDef.health
	if energyStructureDefs[tt_table.unitDef.id] then
		local income = energyStructureDefs[tt_table.unitDef.id].income
		local cost = energyStructureDefs[tt_table.unitDef.id].cost
		if windgenDefID == tt_table.unitDef.id and mx and my then
			local _, pos = spTraceScreenRay(mx,my, true)
			if pos and pos[1] and pos[3] then
				local x,z = math.floor(pos[1]/16)*16,  math.floor(pos[3]/16)*16
				local y = spGetGroundHeight(x,z)

				if y then
					if y <= windTidalThreashold then
						extraText = ", " .. WG.Translate("interface", "tidal_income") .. " +1.2"
						income = 1.2
						health = 400
					else
						local minWindIncome = windMin+(windMax-windMin)*windGroundSlope*(y - windGroundMin)/windGroundExtreme
						extraText = ", " .. WG.Translate("interface", "wind_range") .. " " .. string.format("%.1f", minWindIncome ) .. " - " .. string.format("%.1f", windMax )
						income = (minWindIncome+2.5)/2
					end
				end
			end
		end
		
		local teamID = Spring.GetLocalTeamID()
		local metalOD = Spring.GetTeamRulesParam(teamID, "OD_team_metalOverdrive") or 0
		local energyOD = Spring.GetTeamRulesParam(teamID, "OD_team_energyOverdrive") or 0
		
		if metalOD and metalOD > 0 and energyOD and energyOD > 0 then 
			-- Best case payback assumes that extra energy will make
			-- metal at the current energy:metal ratio. Note that if
			-- grids are linked better then better payback may be
			-- achieved.
			--local bestCasePayback = cost/(income*metalOD/energyOD)
			
			-- Uniform case payback assumes that all mexes are being
			-- overdriven equally and figures out their multiplier
			-- from the base mex income. It then figures out how many
			-- mexes there are and adds a portion of the new enginer to
			-- them.
			--local totalMexIncome = WG.mexIncome
			--if not totalMexIncome then
			--	local singleMexMult = math.sqrt(energyOD)/4
			--	totalMexIncome = metalOD/singleMexMult
			--end
			--local overdriveMult = metalOD/totalMexIncome
			--local energyPerMex = 16*overdriveMult^2
			--local mexCount = energyOD/energyPerMex
			--local incomePerMex = income/mexCount
			--local overdrivePerMex = metalOD/mexCount
			--local extraMetalPerMex = totalMexIncome/mexCount*math.sqrt(energyPerMex+incomePerMex)/4 - overdrivePerMex
			--local extraMetal = extraMetalPerMex*mexCount
			--local unitformCasePayback = cost/extraMetal
			
			-- Worst case payback assumes that all your OD metal is from
			-- a single mex and you are going to link your new energy to it.
			-- It seems to be equal to Uniform case payback and quite accurate.
			local singleMexMult = math.sqrt(energyOD)/4
			local mexIncome = metalOD/singleMexMult
			local worstCasePayback = cost/(mexIncome*math.sqrt(energyOD+income)/4 - metalOD)
			
			--extraText = extraText 
			--.. "\n overdriveMult: " .. overdriveMult 
			--.. "\n energyPerMex: " .. energyPerMex 
			--.. "\n mexCount: " .. mexCount 
			--.. "\n incomePerMex: " .. incomePerMex 
			--.. "\n overdrivePerMex: " .. overdrivePerMex 
			--.. "\n extraMetalPerMex: " .. extraMetalPerMex
			--.. "\n extraMetal: " .. extraMetalza
			--.. "\n unitformCasePayback: " .. unitformCasePayback 
			--.. "\n worstCasePayback: " .. worstCasePayback 
			extraText = extraText .. "\n" .. WG.Translate("interface", "od_payback") .. ": " .. SecondsToMinutesSeconds(worstCasePayback)
		else
			extraText = extraText .. "\n" .. WG.Translate("interface", "od_payback") .. ": " ..  WG.Translate("interface", "unknown")
		end
	end

	local tt_structure = {
		leftbar = {
			tt_table.morph_data 
				and { name= 'bp', directcontrol = 'buildpic_morph' }
				or { name= 'bp', directcontrol = 'buildpic_ud' },
			{ name = 'cost', icon = 'LuaUI/images/cost.png', text = cyan .. numformat(tt_table.unitDef.metalCost), },
		},
		main = {
			{ name = 'udname', icon = iconPath, text = GetHumanName(tt_table.unitDef), fontSize=6 },
			{ name = 'tt', text = GetDescription(tt_table.unitDef) .. extraText, wrap=true },
			{ name='health', icon = 'LuaUI/images/commands/Bold/health.png',  text = numformat(health),  fontSize=4, },
			--[[
			{ name = 'requires', text = tt_table.requires and ('REQUIRES' .. tt_table.requires) or '', },
			{ name = 'provides', text = tt_table.provides and ('PROVIDES' .. tt_table.provides) or '', },
			{ name = 'consumes', text = tt_table.consumes and ('CONSUMES' .. tt_table.consumes) or '', },
			--]]
			tt_table.morph_data and { name='morph', directcontrol = 'morphs' } or {},
			{ name='helptext', text = green .. helptext, wrap=true},
			
		},
	}
	
	if tt_table.morph_data then
		UpdateBuildpic( tt_table.unitDef, 'buildpic_morph' )
		UpdateMorphControl( tt_table.morph_data )
		
		BuildTooltip2('morph2', tt_structure)
	else
		UpdateBuildpic( tt_table.unitDef, 'buildpic_ud' )
		BuildTooltip2('ud2', tt_structure)
	end
	
end


local function MakeToolTip_Unit(data)
	
	
	local unitID = data
	local team, fullname
	tt_unitID = unitID
	team = spGetUnitTeam(tt_unitID) 
	local unitDefID = spGetUnitDefID(tt_unitID)
	tt_ud = UnitDefs[ unitDefID or -1]
	
	if not (tt_ud) then
		--fixme
		return false
	end
	--local alliance       = spGetUnitAllyTeam(tt_unitID)
	local _, player,_,isAI = spGetTeamInfo(team)
	
	local playerName
	
	if isAI then
	  local _, aiName, _, shortName = Spring.GetAIInfo(team)
	  playerName = aiName ..' ('.. shortName .. ')'
	else
	  playerName = player and spGetPlayerInfo(player) or 'noname'
	end

	local teamColor		= Chili.color2incolor(spGetTeamColor(team))
	local iconPath		= GetUnitIcon(tt_ud)
	
	local m, e = GetResources( 'unit', unitID, tt_ud)
	
	local tt_structure = {
		leftbar = {
			{ name= 'bp', directcontrol = 'buildpic_unit' },
			{ name= 'cost', icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat((GetUnitCost(tt_unitID, unitDefID)) or '0') },
			
			{ name='res_m', icon = 'LuaUI/images/metalplus.png', text = m },
			{ name='res_e', icon = 'LuaUI/images/energy.png', text = e },
		},
		main = {
			{ name='uname', icon = iconPath, text = GetHumanName(tt_ud, tt_unitID), fontSize=4, },
			{ name='utt', text = GetDescription(tt_ud, tt_unitID) .. '\n', wrap=true },
			{ name='hp', directcontrol = 'hp_unit', },
			{ name='ttplayer', text = WG.Translate("interface", "player") .. ': ' .. teamColor .. playerName .. white ..'', fontSize=2, center=false },
			{ name='help', text = green .. WG.Translate("interface", "space_click_show_stats"), },
		},
	}
	
	UpdateBuildpic( tt_ud, 'buildpic_unit' )
	BuildTooltip2('unit2', tt_structure)
	
	forceAnUpdate = true -- Update healthbars
end


local function MakeToolTip_SelUnit(data)
	local unitID = data
	local uDefID = spGetUnitDefID(unitID)
	
	if not uDefID then --unit out of LOS
		stt_unitID = nil
		return false
	end
	
	stt_unitID = unitID
	stt_ud = UnitDefs[uDefID]
	
	if not (stt_ud) then
		--fixme
		return false
	end

	local iconPath		= GetUnitIcon(stt_ud)
	
	local m, e = GetResources( 'selunit', unitID, stt_ud)
	
	local hasShield = Spring.GetUnitRulesParam(unitID, "comm_shield_max") ~= 0 and stt_ud.shieldWeaponDef

	local tt_structure = {
		leftbar = {
			{ name= 'bp', directcontrol = 'buildpic_selunit' },
			{ name= 'cost', icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat((GetUnitCost(stt_unitID, uDefID)) or '0') },
			
			{ name='res_m', icon = 'LuaUI/images/metalplus.png', text = m },
			{ name='res_e', icon = 'LuaUI/images/energy.png', text = e },
		},
		main = {
			{ name='uname', icon = iconPath, text = GetHumanName(stt_ud, stt_unitID), fontSize=4, }, --name in window
			{ name='utt', text = GetDescription(stt_ud, stt_unitID) .. '\n', wrap=false, description = true },
			hasShield and { name='shield', directcontrol = 'shield_selunit', } or {},
			{ name='hp', directcontrol = 'hp_selunit', },
			stt_ud.isBuilder and { name='bp', directcontrol = 'bp_selunit', } or {},
			
		},
	}
	
	forceAnUpdate = true -- Update healthbars
	
	UpdateBuildpic( stt_ud, 'buildpic_selunit', stt_unitID )
	return BuildTooltip2('selunit2', tt_structure, true)
end

local function MakeToolTip_Feature(data)
	local featureID = data
	local tt_fd
	local team, fullname
	
	tt_fid = featureID
	team = spGetFeatureTeam(featureID)
	local fdid = spGetFeatureDefID(featureID)
	tt_fd = fdid and FeatureDefs[fdid or -1]
	local feature_name = tt_fd and tt_fd.name
	
	local live_name
	
	if tt_fd and tt_fd.customParams and tt_fd.customParams.unit then
		live_name = tt_fd.customParams.unit
	else
		live_name = feature_name:gsub('(.*)_.*', '%1') --filter out _dead or _dead2 or _anything
	end
	
	local desc = ''
	if feature_name:find('dead2') or feature_name:find('heap') then
		desc = ' (' .. WG.Translate("interface", "debris") .. ')'
	elseif feature_name:find('dead') then
		desc = ' (' .. WG.Translate("interface", "wreckage") .. ')'
	end
	tt_ud = UnitDefNames[live_name]
	fullname = ((tt_ud and GetHumanName(tt_ud) .. desc) or tt_fd.tooltip or "")
	
	if not (tt_fd) then
		--fixme
		return false
	end
	
	if (not options.show_for_unreclaimable.value) and (not tt_fd.reclaimable) then
		return false
	end
	
	--local alliance       = spGetUnitAllyTeam(tt_unitID)
	local _, player		= spGetTeamInfo(team)
	local playerName	= player and spGetPlayerInfo(player) or 'noname'
	local teamColor		= Chili.color2incolor(spGetTeamColor(team))
	local unittooltip	= tt_ud and GetDescription(tt_ud) or ""
	local iconPath		= GetUnitIcon(tt_ud)
	
	local m,e = GetResources( tt_ud and 'corpse' or 'feature', featureID, tt_ud or tt_fd )
	
	local leftbar = tt_ud and {
		{ name= 'bp', directcontrol = 'buildpic_feature' },
		{ name='cost', icon = 'LuaUI/images/ibeam.png', text = cyan .. numformat((tt_ud and tt_ud.metalCost) or '0'), },
		
		{ name='res_m', icon = 'LuaUI/images/metalplus.png', text = m },
		{ name='res_e', icon = 'LuaUI/images/energy.png', text = e },
	}
	or {
		
		{ name='res_1', icon = 'LuaUI/images/metalplus.png', text = m },
		{ name='res_2', icon = 'LuaUI/images/energy.png', text = e },
	}
	
	local tt_structure = {
		leftbar = leftbar,
			
		main = {
			{ name='uname', icon = iconPath, text = fullname, fontSize=6, },
			{ name='utt', text = unittooltip .. '\n', wrap=true },
			(	options.featurehp.value
					and { name='hp', directcontrol = (tt_ud and 'hp_corpse' or 'hp_feature'), } 
					or {}),
			
			{ name='ttplayer', text = WG.Translate("interface", "player") .. ': ' .. teamColor .. playerName .. white ..'', fontSize=2, center=false, },
			{ name='help', text = tt_ud and (green .. WG.Translate("interface", "space_click_show_stats")) or '', },
		},
	}
	
	if tt_ud then
		UpdateBuildpic( tt_ud, 'buildpic_feature' )
		BuildTooltip2('corpse2', tt_structure)
	else
		BuildTooltip2('feature2', tt_structure)
	end
	return true
end

CreateHpBar = function(name)
	globalitems[name] = Panel:New {
		orientation='horizontal',
		name = name,
		width = '100%',
		height = icon_size*1.1,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},	
		padding = {0,0,0,0},
		backgroundColor = {0,0,0,0},
		
		children = {
			Image:New{file='LuaUI/images/commands/bold/health.png',height= icon_size,width= icon_size,  x=0,y=0},
			Progressbar:New {
				name = 'bar',
				x=icon_size,
				right=0,
				--width = '100%',
				height = icon_size*1.1,
				itemMargin    = {0,0,0,0},
				itemPadding   = {0,0,0,0},	
				padding = {0,0,0,0},
				color = {0,1,0,1},
				max=1,
				caption = '',
				font= { size=ttFontSize + 3},
			},
		},
		
	}
	
end

CreateBpBar = function(name)
	globalitems[name] = Panel:New {
		orientation='horizontal',
		name = name,
		width = '100%',
		height = icon_size*1.1,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},	
		padding = {0,0,0,0},
		backgroundColor = {0,0,0,0},
		
		children = {
			Image:New{file='LuaUI/Images/commands/Bold/buildsmall.png',height= icon_size,width= icon_size,  x=0,y=0},
			Progressbar:New {
				name = 'bar',
				x=icon_size,
				right=0,
				--width = '100%',
				height = icon_size*1.1,
				itemMargin    = {0,0,0,0},
				itemPadding   = {0,0,0,0},	
				padding = {0,0,0,0},
				color = {0.8,0.8,0.2,1};
				max=1,
				caption = '',
				font= { size=ttFontSize + 3},
			},
		},
	}
end

CreateShieldBar = function(name)
	globalitems[name] = Panel:New {
		orientation='horizontal',
		name = name,
		width = '100%',
		height = icon_size*1.1,
		itemMargin    = {0,0,0,0},
		itemPadding   = {0,0,0,0},	
		padding = {0,0,0,0},
		backgroundColor = {0,0,0,0},
		
		children = {
			Image:New{file='LuaUI/Images/commands/Bold/guard.png',height= icon_size,width= icon_size,  x=0,y=0},
			Progressbar:New {
				name = 'bar',
				x=icon_size,
				right=0,
				--width = '100%',
				height = icon_size*1.1,
				itemMargin    = {0,0,0,0},
				itemPadding   = {0,0,0,0},	
				padding = {0,0,0,0},
				color = {0.3,0,0.9,1};
				max=1,
				caption = '',
				font= { size=ttFontSize + 3},
			},
		},
	}
end

local function MakeToolTip_Draw()
	local tt_structure = {
		main = {
			{ name='lmb', 		icon = LUAUI_DIRNAME .. 'Images/drawingcursors/pencil.png', 		text = 'Left Mouse Button', },
			{ name='rmb', 		icon = LUAUI_DIRNAME .. 'Images/drawingcursors/eraser.png', 		text = 'Right Mouse Button', },
			{ name='mmb', 		icon = LUAUI_DIRNAME .. 'Images/Crystal_Clear_action_flag.png', 	text = 'Middle Mouse Button', },
			{ name='dblclick', 	icon = LUAUI_DIRNAME .. 'Images/drawingcursors/flagtext.png', 		text = 'Double Click', },
			
		},
	}
	BuildTooltip2('drawing2', tt_structure)
end

local function MakeToolTip_Terra(cmdName)
	
	local tt_structure = {
		main = {
			{ name='cmdName', text = cyan..cmdName, wrap=false},
			{ name='tips', text = terraTips[cmdName], wrap=true },
		},
	}
	
	BuildTooltip2('terra', tt_structure)
end

local function miscObjectTooltip()
	if WG.mouseoverMexIncome and WG.mouseoverMexIncome ~= 0 then
		MakeToolTip_Text(WG.Translate("interface", "mexspot") .. "\n" .. WG.Translate("interface", "income") .. " +" .. strFormat("%.2f", WG.mouseoverMexIncome))
		return true
	end

	if WG.mouseAboveGeo then
		MakeToolTip_Text(WG.Translate("interface", "geospot"))
		return true
	end
end

local function MakeTooltip(dt)
	if options.showdrawtooltip.value and drawtoolKeyPressed and not (drawing or erasing) then
		MakeToolTip_Draw()
		return
	end
	
	local index, cmd_id, cmd_type, cmd_name = Spring.GetActiveCommand()
	local cmdDesc = Spring.GetActiveCmdDesc( index )
	if options.showterratooltip.value and cmdDesc then
		if terraCmds[ cmdDesc.name ] then
			MakeToolTip_Terra(cmdDesc.name)
			return
		end
	end
	
	----------
	local groundTooltip
	if WG.customToolTip then
		local pos = select(2, spTraceScreenRay(mx,my, true))
		if pos then
			for _, data in pairs(WG.customToolTip) do
				if data.box and (pos[1]>= data.box.x1 and pos[1]<= data.box.x2) and (pos[3]>= data.box.z1 and pos[3]<= data.box.z2) then
					groundTooltip = data.tooltip
					break
				end
			end
		end
	end
	----------
	local cur_ttstr = screen0.currentTooltip or groundTooltip or spGetCurrentTooltip()
	local type, data = spTraceScreenRay(mx, my)
	if (not changeNow) and cur_ttstr ~= '' and old_ttstr == cur_ttstr and old_data == data then
		PlaceToolTipWindow2(mx+20,my-20)
		return
	end
	old_data = data
	old_ttstr = cur_ttstr
	
	tt_unitID = nil
	tt_ud = nil

	--chili control tooltip
	if screen0.currentTooltip ~= nil 
		and not screen0.currentTooltip:find('Build') --detect if chili control shows build option
		and not screen0.currentTooltip:find('Morph') --detect if chili control shows morph option
		then 
		if cur_ttstr ~= '' and cur_ttstr:gsub(' ',''):len() > 0 then
			MakeToolTip_Text(cur_ttstr)
		else
			KillTooltip() 
		end
		return
	end
	
	local tt_table = tooltipBreakdown(cur_ttstr)
	local tooltip, unitDef  = tt_table.tooltip, tt_table.unitDef
		
	if not tooltip then
		KillTooltip()
		return
	elseif unitDef then
		tt_ud = unitDef
		MakeToolTip_UD(tt_table)
		return
	end
	
	-- empty tooltip
	if (tooltip == '') or tooltip:gsub(' ',''):len() <= 0 then
		KillTooltip()
		return
	end	
	
	--unit(s) selected/pointed at 
	local unit_tooltip = tooltip:find('Experience %d+.%d+ Cost ')  --shows on your units, not enemy's
		or tooltip:find('TechLevel %d') --shows on units
		or tooltip:find('Metal.*Energy') --shows on features
		
	local alt,_,meta,_ = spGetModKeyState()
	
	--unit(s) selected/pointed at
	if unit_tooltip then
		if oldObjectID ~= data then
			sameObjectIDTime = 0
			oldObjectID = data
		else
			sameObjectIDTime = sameObjectIDTime + dt
		end
		
		-- pointing at unit/feature
		if type == 'unit' then
			if options.show_for_units.value and 
					(meta or options.independant_world_tooltip_delay.value == 0 or 
					sameObjectIDTime > options.independant_world_tooltip_delay.value) then
				MakeToolTip_Unit(data)
			else
				KillTooltip()
			end
			return
		elseif type == 'feature' then
			if options.show_for_wreckage.value and
					(meta or options.independant_world_tooltip_delay.value == 0 or 
					sameObjectIDTime > options.independant_world_tooltip_delay.value) then
				if MakeToolTip_Feature(data) then
					return
				end
			else
				KillTooltip()
				return
			end
		end
	
		--holding meta or static tip
		if (showExtendedTip and options.show_unit_text.value) then
			MakeToolTip_Text(tooltip)
		else
			KillTooltip()
		end

		miscObjectTooltip()
		return
	else
		oldObjectID = 0
	end
	
	--tooltip that shows position
	local pos_tooltip = tooltip:sub(1,4) == 'Pos '
	
	-- default tooltip
	if not pos_tooltip or (showExtendedTip and options.show_position.value) then
		MakeToolTip_Text(tooltip)
		return
	end

	if miscObjectTooltip() then
		return
	end

	KillTooltip()
	return
	
end --function MakeTooltip

local function SetupTerraTips()
	terraTips = {}
	
	for cmdName, _ in pairs( terraCmds ) do
		terraTips[cmdName] =
			green.. 'Click&Drag'..white..': Free draw terraform. \n'..
			green.. 'Alt+Click&Drag'..white..': Box terraform. \n'..
			green.. 'Alt+Ctrl+Click&Drag'..white..': Hollow box terraform. \n'..
			green.. 'Ctrl+Click on unit' ..white..': Terraform around unit. \n'..
			'\n'..
			''
	end
	
	terraTips.Smooth = terraTips.Smooth ..
		yellow..'[During Terraform Draw]\n'..
		green.. 'Ctrl'..white..': Draw straight line segment. \n'..
		''
	
	terraTips.Ramp =
		green.. 'Step 1'..white..': Click to start ramp \n    OR click&drag to start a ramp at desired height. \n'..
		green.. 'Step 2'..white..': Click to set end of ramp \n    OR click&drag to set end of ramp at desired height. \n    Hold '..green..'Alt'..white..' to snap to certain levels of pathability. \n'..
		green.. 'Step 3'..white..': Move mouse to set ramp width, click to complete. \n'..
		'\n'..
		yellow..'[Any Time]\n'..
		green.. 'Space'..white..': Cycle through only raise/lower \n'..
		'\n'..
		yellow..'[Wireframe indicator colors]\n'..
		green.. 'Green'..white..': All units can traverse. \n'..
		green.. 'Yellow'..white..': Vehicles cannot traverse. \n'..
		green.. 'Red'..white..': Only all-terrain / spiders can traverse. \n'..
		''
		
	terraTips.Level = terraTips.Level ..
		yellow..'[During Terraform Draw]\n'..
		green.. 'Ctrl'..white..': Draw straight line segment. \n'..
		'\n'..
		yellow..'[After Terraform Draw]\n'..
		green.. 'Alt'..white..': Snap to starting height / below water level (prevent ships) / below water level (prevent land units). \n'..
		green.. 'Ctrl'..white..': Hold and point at terrain to level to height pointed at.\n'..
		'\n'..
		yellow..'[Any Time]\n'..
		green.. 'Space'..white..': Cycle through only raise/lower \n'..
		''
	
	terraTips.Raise = terraTips.Raise ..
		yellow..'[During Terraform Draw]\n'..
		green.. 'Ctrl'..white..': Draw straight line segment. \n'..
		'\n'..
		yellow..'[After Terraform Draw]\n'..
		green.. 'Alt'..white..': Snap to steps of 15 height. \n'..
		green.. 'Ctrl'..white..': Snap to 0 height. \n'..
		''
	
	terraTips.Restore = terraTips.Restore ..
		'\n'..
		yellow..'[Any Time]\n'..
		green.. 'Space'..white..': Limit to only raise/lower \n'..
		''
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--callins

function widget:Update(dt)
	if widgetHandler:InTweakMode() then
		tweakShow = true
		Show(real_window_corner)
	elseif tweakShow then
		tweakShow = false
		widget:SelectionChanged(Spring.GetSelectedUnits())
	end
	
	timer = timer + dt
	if timer >= updateFrequency or forceAnUpdate then
		forceAnUpdate = false
		
		local hotkeys = WG.crude.GetHotkeys("drawinmap")
		drawHotkeyBytes = {}
		drawHotkeyBytesCount = 0
		for k,v in pairs(hotkeys) do
			drawHotkeyBytes[v:byte(-1)] = true
			drawHotkeyBytesCount = drawHotkeyBytesCount+1
		end
		
		
		UpdateSelectedUnitsTooltip() --this has numSelectedUnits check. Will only run with numSelectedUnits > 1
		UpdateDynamicGroupInfo()
		WriteGroupInfo()
		
		SetHealthbars()
		if stt_unitID then
			local tt_table = tooltipBreakdown( spGetCurrentTooltip() )
			local tooltip, unitDef  = tt_table.tooltip, tt_table.unitDef
			
			local ctrlm = controls['selunit2']['res_m']
			if ctrlm then
				local ctrle = controls['selunit2']['res_e']
				local m, e = GetResources( 'selunit', stt_unitID, stt_ud)
				ctrlm:SetCaption(m)
				ctrle:SetCaption(e)
			end
			
			local ud = UnitDefs[Spring.GetUnitDefID(stt_unitID)]
			controls['selunit2']['utt']:SetCaption(GetDescription(ud, stt_unitID))
			
			local nanobar_stack = globalitems['bp_selunit']
			local nanobar = nanobar_stack:GetChildByName('bar')
			if nanobar then
				local metalMake, metalUse, energyMake,energyUse = Spring.GetUnitResources(stt_unitID)
				
				local buildSpeed = stt_ud.buildSpeed*(Spring.GetUnitRulesParam(stt_unitID, "buildpower_mult") or 1)
				if metalUse and buildSpeed and (buildSpeed > 0) then
					nanobar:SetValue(metalUse/buildSpeed,true)
					nanobar:SetCaption(round(100*metalUse/buildSpeed)..'%')
				else
					nanobar:SetValue(1)
					nanobar:SetCaption('??? / ' .. numformat(buildSpeed))
				end
			end
			
			local shieldbar_stack = globalitems['shield_selunit']
			local shieldbar = shieldbar_stack:GetChildByName('bar')
			local shieldPower = Spring.GetUnitRulesParam(stt_unitID, "comm_shield_max") or stt_ud.shieldPower
			if shieldbar and shieldPower and (shieldPower > 0) then
				local shieldEnabled, shieldCurrentPower = Spring.GetUnitShieldState(stt_unitID, Spring.GetUnitRulesParam(stt_unitID, "comm_shield_num") or -1)
				if shieldCurrentPower then
					local wd = WeaponDefs[UnitDefs[Spring.GetUnitDefID(stt_unitID)].shieldWeaponDef]
					local regen = ""
					if shieldCurrentPower < shieldPower then
						regen = " (+" .. (wd.customParams.shield_rate or wd.shieldPowerRegen) .. ")"
					end

					shieldbar:SetValue(shieldCurrentPower / shieldPower,true)
					if shieldEnabled then
						shieldbar:SetCaption( numformat(math.floor(shieldCurrentPower)) .. ' / ' .. numformat(shieldPower) .. regen)
					else
						shieldbar:SetCaption('Shield offline')
					end
				end
			end
		end
		changeNow = true
		timer = 0
	end
	
	drawtoolKeyPressed = false
	if drawHotkeyBytesCount ~= 0 then
		for k,v in pairs(drawHotkeyBytes) do
			if Spring.GetKeyState(k) then
				drawtoolKeyPressed = true
				break
			end
		end
	end
	WG.drawtoolKeyPressed = drawtoolKeyPressed
	
	
	--UNIT.STATUS start (by msafwan), function: add/show units task whenever individual pic is shown.
	timer2 = timer2 + dt
	if timer2 >= updateFrequency2  then
		if options.unitCommand.value and numSelectedUnits >= 2 then
			local barGrid = window_corner.childrenByName['Bars'] --//find chili element that we want to modify. REFERENCE: gui_chili_facbar.lua, by CarRepairer
			for i=1,numSelectedUnits do --//iterate over all selected unit *this variable is updated by 'widget:SelectionChanged()'
				local unitID = selectedUnits[i][1]
				local barGridItem = nil
				local itemImg =nil
				if barGrid then	barGridItem = barGrid.childrenByName[unitID] end --only ungrouped icon will be named by unitID & thus return barGridItem
				if barGridItem then itemImg = barGridItem.childrenByName['selImage'] end
				if itemImg then
					local cQueue = spGetCommandQueue(unitID, 1)
					local commandName
					local color = {1,1,1,1}
					if cQueue and cQueue[1] ~= nil then
						local commandID = cQueue[1].id				
						commandName = ":" .. commandID --"unrecognized" 
						if commandID < 0 then
							commandName = "Build"
						else
							local commandList = {
													{{CMD.WAIT}, "Wait"},
													{{CMD.MOVE}, "Move", {0.2,0.8,0.2,1}},
													{{CMD.PATROL}, "Patrol",{0.4,0,1,1}},
													{{CMD.FIGHT}, "Fight", {0.4,0,0.8,1}},
													{{CMD.ATTACK, CMD.AREA_ATTACK}, "Attack",{0.6,0,0,1}}, 
													{{CMD.GUARD}, "Guard", {0.2,0,0.8,1}},
													{{CMD.REPAIR}, "Repair",{0.2,0.8,1,1}},
													--{{CMD.SELFD},  "Suicide"},
													{{CMD.LOAD_UNITS, CMD_EXTENDED_LOAD},  "Load",{0,0.6,0.6,1}},
													{{CMD.LOAD_ONTO}, "Load",{0,0.6,0.6,1}},
													{{CMD.UNLOAD_UNITS, CMD.UNLOAD_UNIT}, "Unload", {0.6,0.6,0,1}},
													{{CMD.RECLAIM}, "Reclaim",{0.6,0,0.4,1}},
													{{CMD.RESURRECT},"Resurrect",{0.2,0,0.8,1}},
													{{CMD.MANUALFIRE},"DGun",{1,1,1,1}},
													{{CMD_ONECLICK_WEAPON},"Special",{0.8,0.6,0.0,1}},
													{{CMD_JUMP},"Jump",{0,0.8,0,1}},
													{{CMD_REARM},"Re-Arm",{0.2,0.8,1,1}},
													{{CMD_PLACE_BEACON},"Bridge",{0.6,0.6,0,1}},
													{{CMD_WAIT_AT_BEACON},"Teleport",{0,0.6,0.6,1}},
												}										
							for i=1, #commandList, 1 do --iterate over the commandList so we could find a match with unit's current command.
								if #commandList[i][1] == 1 then --if commandList don't have sub-table at first row
									if commandList[i][1][1] == commandID then
										commandName = commandList[i][2]
										color = commandList[i][3]
										break
									end
								else
									if commandList[i][1][1] == commandID or commandList[i][1][2] == commandID then --if commandList has sub-table with 2 content at first row
										commandName = commandList[i][2]
										color = commandList[i][3]
										break
									end
								end
							end
						end
					end
					local cmdLabel = itemImg.childrenByName['commandLabel']
					if cmdLabel and cmdLabel.caption ~= commandName then --is differing label?
						cmdLabel:Dispose(); --remove existing label and recreate chili element (to eliminate color bug)
						cmdLabel = nil;
					end
					if not cmdLabel and commandName then
						Label:New{ --create new chili element
							parent = itemImg;
							name = "commandLabel";
							align  = "left";
							valign = "top";
							fontsize   = 14;
							fontshadow = true;
							fontOutline = true;
							textColor = color; --//Reference: gui_chili_crudeplayerlist.lua by KingRaptor
							caption    = commandName;
						};
					end
				end
			end
		end
		timer2 = 0
	end	
	--UNIT.STATUS end
	--TOOLTIP start
	old_mx, old_my = mx,my
	alt,_,meta,_ = spGetModKeyState()
	mx,my = spGetMouseState()
	local mousemoved = (mx ~= old_mx or my ~= old_my)
	
	local show_cursortip = true
	if meta then
		if not showExtendedTip then 
			changeNow = true 
		end
		showExtendedTip = true
	
	else
		if not drawtoolKeyPressed then
			if not mousemoved then
				stillCursorTime = stillCursorTime + dt
			else
				stillCursorTime = 0 
			end
			show_cursortip = (options.tooltip_delay.value == 0 or stillCursorTime > options.tooltip_delay.value)
		end
		
		if showExtendedTip then 
			changeNow = true 
		end
		showExtendedTip = false
	
	end

	if mousemoved or changeNow then
		if not show_cursortip and not drawtoolKeyPressed then
			KillTooltip()
			return
		end
		MakeTooltip(makeTooltipGap)
		changeNow = false
		makeTooltipGap = dt
	else
		makeTooltipGap = makeTooltipGap + dt
	end
	--TOOLTIP end
end

function widget:ViewResize(vsx, vsy)
	scrW = vsx
	scrH = vsy
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget(widget)
		return
	end
	
	widget:UpdateCallIns(options.showDrawTools.value)
	
	SetupTerraTips()
	
	Spring.SetDrawSelectionInfo(false)
	
	local VFSMODE      = VFS.RAW_FIRST
	_, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
	
	-- setup Chili
	Chili = WG.Chili
	Button = Chili.Button
	Label = Chili.Label
	Window = Chili.Window
	Panel = Chili.Panel
	StackPanel = Chili.StackPanel
	Grid = Chili.Grid
	TextBox = Chili.TextBox
	Image = Chili.Image
	Progressbar = Chili.Progressbar
	LayoutPanel = Chili.LayoutPanel
	screen0 = Chili.Screen0

	widget:ViewResize(Spring.GetViewGeometry())

	CreateHpBar('hp_unit')
	CreateHpBar('hp_selunit')
	CreateHpBar('hp_feature')
	CreateHpBar('hp_corpse')
	
	CreateBpBar('bp_selunit')

	CreateShieldBar('shield_unit')
	CreateShieldBar('shield_selunit')
	
	stack_main = StackPanel:New{
		name = "stack_main",
		width=300, -- needed for initial tooltip
	}
	stack_leftbar = StackPanel:New{
		name = "stack_leftbar",
		width=10, -- needed for initial tooltip
	}
	
	window_tooltip2 = Window:New{
		useDList = false,
		resizable = false,
		draggable = false,
		autosize  = true,
		children = { stack_leftbar, stack_main, },
		minHeight = 32,
		minWidth = 32,
		savespace = true,
	}
	--FontChanged()
	spSendCommands({"tooltip 0"})
	
	-- Set the size for the default settings.
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local integralWidth = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)  + 8
	local x = integralWidth
	local height = integralHeight*0.84
	
    real_window_corner = Window:New{
		name  = 'selections',
		color = {0, 0, 0, 0},
		x = x,
		y = screenHeight - height,
        width = 450,
		height = height,
		dockable = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		padding = {0, 0, 0, -1},
        minWidth = 450, 
		minHeight = 120,
	}
    
	window_corner = Panel:New{
		classname = options.fancySkinning.value,
		parent = real_window_corner,
        name   = 'unitinfo2';
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {8 + options.leftPadding.value, 6, 4, 4},
		backgroundColor = {1, 1, 1, options.selection_opacity.value},
		dockable = false,
		resizable   = false;
		draggable = false,
		OnMouseDown={ function(self)
			local _,_, meta,_ = spGetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath('Settings/HUD Panels/Selected Units Window')
			WG.crude.ShowMenu()
			return true --skip button function, else clicking on build pic will also select the unit.
		end },
	}

	windMin = spGetGameRulesParam("WindMin")
	windMax = spGetGameRulesParam("WindMax")
	windGroundMin = spGetGameRulesParam("WindGroundMin")
	windGroundExtreme = spGetGameRulesParam("WindGroundExtreme")
	windGroundSlope = spGetGameRulesParam("WindSlope")

	for i=1,#UnitDefs do
		local ud = UnitDefs[i]
		if (ud.customParams.level)           --// engine overrides commanders tooltips with playernames
		  or (ud.customParams.ismex)   --// the Overdrive gadgets adds additional information to the tooltip, but the visualize it a different way
		then
			ud.chili_selections_useStaticTooltip = true
		end

		local shieldDefID = ud.shieldWeaponDef
		ud.shieldPower = ((shieldDefID)and(WeaponDefs[shieldDefID].shieldPower))or(-1)
	end

	WG.drawtoolKeyPressed = false
	
	option_Deselect()
end

function widget:Shutdown()
	spSendCommands({"tooltip 1"})
	if (window_tooltip2) then
		window_tooltip2:Dispose()
	end
	Spring.SetDrawSelectionInfo(true)
	WG.drawtoolKeyPressed = nil
end

--lags like a brick due to being spammed constantly for unknown reason, moved all its behavior to SelectionChanged
--function widget:CommandsChanged()
--end
--
function widget:SelectionChanged(newSelection)
	selectedUnits = {}
	numSelectedUnits = 0
	--store selected unitID list in a table with unitDefID. This prevent NIL error if selecting using limited LOS spectator
	if (spGetSelectedUnitsCount() > 0) then 
		local count = 0
		local unitID, defID
		for i=1, #newSelection do
			unitID = newSelection[i]
			defID = spGetUnitDefID(unitID)
			if defID then --in LOS/not enemy
				count = count+1
				selectedUnits[count] = {unitID,defID}
			end
		end
		numSelectedUnits = count 
	end
	if (numSelectedUnits>0) then
		UpdateStaticGroupInfo()
		UpdateDynamicGroupInfo()
		selectedUnitsByDef       = spGetSelectedUnitsByDef()
		selectedUnitsByDef.n     = nil -- REMOVE IN 0.83
		selectedUnitsByDefCounts = {}
		for i,v in pairs(selectedUnitsByDef) do
			selectedUnitsByDefCounts[i] = #v
		end

		--// spGetSelectedUnitsByDef() doesn't save the order for the different defids, so we reconstruct it from spGetSelectedUnits()
		--// else the sort order would change each time we select a new unit or deselect one!
		selectionSortOrder = {}
		local alreadyInList = {}
		local defid
		local count = 1
		for i=1,#selectedUnits do
			defid = selectedUnits[i][2]
			if (not alreadyInList[defid]) then
				alreadyInList[defid] = true
				selectionSortOrder[count] = defid
				count = count + 1
			end
		end

		if (numSelectedUnits == 1) then
			local tt_table = tooltipBreakdown( spGetCurrentTooltip() )
			local tooltip, unitDef  = tt_table.tooltip, tt_table.unitDef
			
			local cur1, cur2 = MakeToolTip_SelUnit(selectedUnits[1][1]) --healthbar/resource consumption/ect chili element
			if cur1 then
				DisposeSelectionDisplay()
				window_corner:AddChild(cur1)
				window_corner:AddChild(cur2)
				globalitems["window_corner_direct_child"]= {cur1,cur2, disposable = true}
			end
		else
			stt_unitID = nil
			DisposeSelectionDisplay()
			local cur1 = MakeUnitGroupSelectionToolTip()
			globalitems["window_corner_direct_child"]= {cur1}
			window_corner:AddChild(cur1)
		end
		real_window_corner.caption = nil
		real_window_corner:Invalidate()
		Show(real_window_corner)
	else
		stt_unitID = nil
		DisposeSelectionDisplay()
		if not options.alwaysShowSelectionWin.value then
			screen0:RemoveChild(real_window_corner)
		else
			--real_window_corner.caption = 'No Units Selected'
			real_window_corner:Invalidate()
		end
	end
end


--ToggleDrawTools = function(enable)
function widget:UpdateCallIns(enable)
	if enable then
		self.DrawScreen = DrawScreenDrawTools
	else
		self.DrawScreen = function() end
	end
	
	widgetHandler:UpdateCallIn("DrawScreen")
	widgetHandler:UpdateCallIn("DrawScreen")
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
