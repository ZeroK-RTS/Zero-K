
function widget:GetInfo()
	return {
		name      = "Chili Selections & CursorTip New",
		desc      = "Chili Selection Window and Cursor Tooltip remake.",
		author    = "GoogleFrog (CarRepairer and jK orginal)",
		date      = "9 February 2017",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = false,
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

local spGetMouseState = Spring.GetMouseState
local spTraceScreenRay = Spring.TraceScreenRay
local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitHealth = Spring.GetUnitHealth
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetGameRulesParam = Spring.GetGameRulesParam

local strFormat = string.format
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local screen0

local screenWidth, screenHeight = Spring.GetWindowGeometry()

local tooltipWindow
local selectionWindow

local ICON_SIZE = 20
local BAR_SIZE = 22
local BAR_FONT = 13
local BAR_SPACING = 24
local IMAGE_FONT = 10
local DESC_FONT = 10
local TOOLTIP_FONT = 12
local NAME_FONT = 14
local LEFT_SPACE = 24
local LEFT_LABEL_HEIGHT = 16

local LEFT_WIDTH = 55
local PIC_HEIGHT = LEFT_WIDTH*4/5
local RIGHT_WIDTH = 235

local green = '\255\1\255\1'
local red = '\255\255\1\1'
local cyan = '\255\1\255\255'
local white = '\255\255\255\255'
local yellow = '\255\255\255\1'

local HEALTH_IMAGE = 'LuaUI/images/commands/bold/health.png'
local SHIELD_IMAGE = 'LuaUI/Images/commands/Bold/guard.png'
local BUILD_IMAGE = 'LuaUI/Images/commands/Bold/buildsmall.png'
local COST_IMAGE = 'LuaUI/images/cost.png'
local TIME_IMAGE = 'LuaUI/images/clock.png'
local METAL_IMAGE = 'LuaUI/images/ibeam.png'
local ENERGY_IMAGE = 'LuaUI/images/energy.png'
local METAL_RECLAIM_IMAGE = 'LuaUI/images/ibeamReclaim.png'
local ENERGY_RECLAIM_IMAGE = 'LuaUI/images/energyReclaim.png'

local CURSOR_ERASE = 'eraser'
local CURSOR_POINT = 'flagtext'
local CURSOR_DRAW = 'pencil'
local CURSOR_ERASE_NAME = "map_erase"
local CURSOR_POINT_NAME = "map_point"
local CURSOR_DRAW_NAME = "map_draw"

local iconTypesPath = LUAUI_DIRNAME .. "Configs/icontypes.lua"
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)
local _, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFS.RAW_FIRST)

local terraformGeneralTip = 
	green.. 'Click&Drag'..white..': Free draw terraform. \n'..
	green.. 'Alt+Click&Drag'..white..': Box terraform. \n'..
	green.. 'Alt+Ctrl+Click&Drag'..white..': Hollow box terraform. \n'..
	green.. 'Ctrl+Click on unit' ..white..': Terraform around unit. \n'..
	'\n'

local terraCmdTip = {
	[CMD_RAMP] = 
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
		green.. 'Red'..white..': Only all-terrain / spiders can traverse.',
	[CMD_LEVEL] = terraformGeneralTip ..
		yellow..'[During Terraform Draw]\n'..
		green.. 'Ctrl'..white..': Draw straight line segment. \n'..
		'\n'..
		yellow..'[After Terraform Draw]\n'..
		green.. 'Alt'..white..': Snap to starting height / below water level (prevent ships) / below water level (prevent land units). \n'..
		green.. 'Ctrl'..white..': Hold and point at terrain to level to height pointed at.\n'..
		'\n'..
		yellow..'[Any Time]\n'..
		green.. 'Space'..white..': Cycle through only raise/lower',
	[CMD_RAISE] = terraformGeneralTip ..
		yellow..'[During Terraform Draw]\n'..
		green.. 'Ctrl'..white..': Draw straight line segment. \n'..
		'\n'..
		yellow..'[After Terraform Draw]\n'..
		green.. 'Alt'..white..': Snap to steps of 15 height. \n'..
		green.. 'Ctrl'..white..': Snap to 0 height.',
	[CMD_SMOOTH] = terraformGeneralTip ..
		yellow..'[During Terraform Draw]\n'..
		green.. 'Ctrl'..white..': Draw straight line segment.',
	[CMD_RESTORE] = terraformGeneralTip ..
		yellow..'[Any Time]\n'..
		green.. 'Space'..white..': Limit to only raise/lower',
}

local DRAWING_TOOLTIP = 
	green.. 'Left click'..white..': Draw on map. \n' ..
	green.. 'Right click'..white..': Erase. \n' ..
	green.. 'Middle click'..white..': Place marker. \n' ..
	green.. 'Double click'..white..': Place marker with label.'

-- TODO, autogenerate
local energyStructureDefs = {
	[UnitDefNames["energywind"].id] = {cost = 35, income = 1.25, isWind = true},
	[UnitDefNames["energysolar"].id] = {cost = 70, income = 2},
	[UnitDefNames["energygeo"].id] = {cost = 500, income = 25},
	[UnitDefNames["energyheavygeo"].id] = {cost = 1000, income = 75},
	[UnitDefNames["energyfusion"].id] = {cost = 1000, income = 35},
	[UnitDefNames["energysingu"].id] = {cost = 4000, income = 225},
}

local WIND_TITAL_HEIGHT = -10
local windMin = 0
local windMax = 2.5
local windGroundMin = 0
local windGroundExtreme = 1
local windGroundSlope = 1
local windTidalThreashold = -10

local mexDefID = UnitDefNames["staticmex"] and UnitDefNames["staticmex"].id
local mexCost = UnitDefNames["staticmex"] and UnitDefNames["staticmex"].cost or 4

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local drawHotkeyBytes = {}
local drawHotkeyBytesCount = 0
local oldMouseX, oldMouseY = 0, 0
local stillCursorTime = 0

local sameObjectID
local sameObjectIDTime = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

options_path = 'Settings/HUD Panels/Tooltip'
local selPath = 'Settings/HUD Panels/Selected Units Panel'

options_order = {
	--tooltip
	'tooltip_delay', 'independant_world_tooltip_delay',
	'show_for_units', 'show_for_wreckage', 'show_for_unreclaimable', 'showdrawtooltip','showterratooltip',
	'showDrawTools',
	
	--selected units
	'selection_opacity', 'groupbehaviour', 'showgroupinfo', 'squarepics','uniticon_size','unitCommand', 'manualWeaponReloadBar',
	'fancySkinning', 'leftPadding',
}

options = {
	tooltip_delay = {
		name = 'Tooltip display delay (0 - 4s)',
		desc = 'Determines how long you can leave the mouse idle until the tooltip is displayed.',
		type = 'number',
		min=0,max=4,step=0.05,
		value = 0,
	},
	independant_world_tooltip_delay = { -- Done
		name = 'Unit and Feature tooltip delay (0 - 4s)',
		--desc = 'Determines how long you can leave the mouse over a unit or feature until the tooltip is displayed.',
		type = 'number',
		min=0,max=4,step=0.05,
		value = 0.2,
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
		desc = 'Show pencil or eraser when drawing or erasing.'
	},

	--selection_opacity = {
	selection_opacity = {
		name = "Opacity",
		type = "number",
		value = 0.8, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			selectionWindow.SetOpacity(self.value)
		end,
		path = selPath,
	},
	groupbehaviour = {name='Unit Grouping Behaviour', type='radioButton', 
		value='overflow', 
		items = {
			{key = 'overflow',	name = 'On window overflow'},
			{key = 'multitype',	name = 'With multiple unit types'},
			{key = 'always',		name = 'Always'},
		},
		OnChange = option_Deselect,
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
			selectionWindow.SetSkin(self.value)
		end,
		hidden = true,
		noHotkey = true,
	},
	leftPadding = {
		name = "Left Padding",
		type = "number",
		value = 0, min = 0, max = 500, step = 1,
		OnChange = function(self)
			selectionWindow.SetLeftPadding(self.value)
		end,
		hidden = true,
		path = selPath,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

function Round(num, idp)
	if (not idp) then
		return math.floor(num+.5)
	else
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end
end

local function Format(amount, displaySign)
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

local function FormatPlusMinus(num)
	if num > 0.04 then
		return green .. Format(num, true)
	elseif num < -0.04 then
		return red .. Format(num, true)
	end
	return Format(num)
end

local function SecondsToMinutesSeconds(seconds)
	if seconds%60 < 10 then
		return math.floor(seconds/60) ..":0" .. math.floor(seconds%60)
	else
		return math.floor(seconds/60) ..":" .. math.floor(seconds%60)
	end
end

local function GetHealthColor(fraction, returnString)
	local midpt = (fraction > 0.5)
	local r, g
	if midpt then 
		r = (1 - fraction)*2
		g = 1
	else
		r = 1
		g = fraction*2
	end
	if returnString then
		return string.char(255, math.floor(255*r), math.floor(255*g), 0)
	end
	return {r, g, 0, 1}
end

local function SetPanelSkin(targetPanel, className)
	local currentSkin = Chili.theme.skin.general.skinName
	local skin = Chili.SkinHandler.GetSkin(currentSkin)
	local newClass = skin.panel
	if skin[className] then
		newClass = skin[className]
	end
	
	targetPanel.tiles = newClass.tiles
	targetPanel.TileImageFG = newClass.TileImageFG
	--targetPanel.backgroundColor = newClass.backgroundColor
	targetPanel.TileImageBK = newClass.TileImageBK
	if newClass.padding then
		targetPanel.padding = newClass.padding
		targetPanel:UpdateClientArea()
	end
	targetPanel:Invalidate()
end

local iconTypeCache = {}
local function GetUnitIcon(unitDefID)
	if unitDefID and iconTypeCache[unitDefID] then
		return iconTypeCache[unitDefID]
	end
	local ud = UnitDefs[unitDefID]
	if not ud then 
		return 
	end
	iconTypeCache[unitDefID] = icontypes[(ud and ud.iconType or "default")].bitmap or 'icons/' .. ud.iconType .. iconFormat
	return iconTypeCache[unitDefID]
end

local unitBorderCache = {}
local function GetUnitBorder(unitDefID)
	if unitDefID and unitBorderCache[unitDefID] then
		return unitBorderCache[unitDefID]
	end
	local ud = UnitDefs[unitDefID]
	if not ud then 
		return 
	end
	unitBorderCache[unitDefID] = WG.GetBuildIconFrame and WG.GetBuildIconFrame(ud)
	return unitBorderCache[unitDefID]
end

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

local function GetUnitRegenString(unitID, ud)
	if unitID and (not select(3, spGetUnitIsStunned(unitID))) then
		local regen_timer = Spring.GetUnitRulesParam(unitID, "idleRegenTimer")
		if regen_timer and ud then
			if ((ud.idleTime <= 300) and (regen_timer > 0)) then
				return "  (" .. math.ceil(regen_timer / 30) .. "s)"
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
					return "  (+" .. math.ceil(regen) .. ")"
				end
			end
		end
	end
end

local function GetUnitShieldRegenString(unitID, ud)
	-- TODO: Surely actual rate should be used, taking into account energy stalling and stun state.
	local wd = WeaponDefs[ud.shieldWeaponDef]
	return " (+" .. (wd.customParams.shield_rate or wd.shieldPowerRegen) .. ")"
end

local function GetExtraBuildTooltipAndHealthOverride(unitDefID, mousePlaceX, mousePlaceY)
	if mousePlaceX and mexDefID == unitDefID and WG.mouseoverMexIncome then
		local extraText = ", ".. WG.Translate("interface", "income") .. " +" .. string.format("%.2f", WG.mouseoverMexIncome)
		if WG.mouseoverMexIncome > 0 then
			return extraText .. "\n" .. WG.Translate("interface", "base_payback") .. ": " .. SecondsToMinutesSeconds(mexCost/WG.mouseoverMexIncome)
		else
			return extraText .. "\n" .. WG.Translate("interface", "base_payback") .. ": " .. WG.Translate("interface", "never")
		end
	end
	
	local energyDef = energyStructureDefs[unitDefID]
	if energyDef then
		local income = energyDef.income
		local cost = energyDef.cost
		local extraText = ""
		local healthOverride = false
		if energyDef.isWind and mousePlaceX and mousePlaceY then
			local _, pos = spTraceScreenRay(mousePlaceX, mousePlaceY, true)
			if pos and pos[1] and pos[3] then
				local x,z = math.floor(pos[1]/16)*16,  math.floor(pos[3]/16)*16
				local y = Spring.GetGroundHeight(x,z)

				if y then
					if y <= WIND_TITAL_HEIGHT then
						extraText = ", " .. WG.Translate("interface", "tidal_income") .. " +1.2"
						income = 1.2
						healthOverride = 400
					else
						local minWindIncome = windMin + (windMax - windMin)*windGroundSlope*(y - windGroundMin)/windGroundExtreme
						extraText = ", " .. WG.Translate("interface", "wind_range") .. " " .. string.format("%.1f", minWindIncome ) .. " - " .. string.format("%.1f", windMax)
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
			return extraText .. "\n" .. WG.Translate("interface", "od_payback") .. ": " .. SecondsToMinutesSeconds(worstCasePayback), healthOverride
		end
		return extraText .. "\n" .. WG.Translate("interface", "od_payback") .. ": " ..  WG.Translate("interface", "unknown"), healthOverride
	end
end

local function GetPlayerCaption(teamID)
	local _, player,_,isAI = Spring.GetTeamInfo(teamID)
	local playerName
	if isAI then
		local _, aiName, _, shortName = Spring.GetAIInfo(teamID)
		playerName = aiName ..' ('.. shortName .. ')'
	else
		playerName = player and Spring.GetPlayerInfo(player)
		if not playerName then
			return false
		end
	end
	local teamColor = Chili.color2incolor(Spring.GetTeamColor(teamID))
	return WG.Translate("interface", "player") .. ': ' .. teamColor .. playerName
end

local function GetIsHoldingDrawKey()
	if drawHotkeyBytesCount == 0 then
	WG.drawtoolKeyPressed = false
		return false
	end
	for i = 1, drawHotkeyBytesCount do
		local key = drawHotkeyBytes[i]
		if Spring.GetKeyState(key) then
			WG.drawtoolKeyPressed = true
			return true
		end
	end
	WG.drawtoolKeyPressed = false
	return false
end

local function UpdateMouseCursor(holdingDrawKey)
	if not (holdingDrawKey and options.showDrawTools.value) then
		return
	end
	local x, y, drawing, addingPoint, erasing = Spring.GetMouseState()
	if addingPoint then
		Spring.SetMouseCursor(CURSOR_POINT_NAME)
	elseif erasing then
		Spring.SetMouseCursor(CURSOR_ERASE_NAME)
	else
		Spring.SetMouseCursor(CURSOR_DRAW_NAME)
	end
end

local UnitDefIDByHumanName_cache = {}
local function GetUnitDefByHumanName(humanName)
	local cached_unitDefID = UnitDefIDByHumanName_cache[humanName]
	if (cached_udef ~= nil) then
		return cached_udef
	end
	
	for i = 1, #UnitDefs do
		local ud = UnitDefs[i]
		if (ud.humanName == humanName) then
			UnitDefIDByHumanName_cache[humanName] = i
			return i
		end
	end
	
	UnitDefIDByHumanName_cache[humanName] = false
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit tooltip window components

local function GetBar(parentControl, initY, imageFile, color, colorFunc)
	local image = Chili.Image:New{
		x = 0,
		y = initY,
		width = ICON_SIZE,
		height = ICON_SIZE,
		file = imageFile,
		parent = parentControl,
	}
	
	local bar = Chili.Progressbar:New {
		x = ICON_SIZE + 1,
		y = initY,
		right = 0,
		height = BAR_SIZE,
		max = 1,
		color = color,
		itemMargin  = {0,0,0,0},
		itemPadding = {0,0,0,0},
		padding     = {0,0,0,0},
		caption = '',
		font = {size = BAR_FONT},
		parent = parentControl
	}
	
	local function UpdateBar(visible, yPos, currentValue, maxValue, extraCaption, newCaption)
		image:SetVisibility(visible)
		bar:SetVisibility(visible)
		if not visible then
			return
		end
		if yPos then
			image:SetPos(nil, yPos)
			bar:SetPos(nil, yPos)
		end
		if not newCaption then
			newCaption = Format(currentValue) .. ' / ' .. Format(maxValue)
			if extraCaption then
				newCaption = newCaption .. extraCaption
			end
		end
		bar:SetCaption(newCaption)
		if colorFunc then
			color = colorFunc(currentValue/maxValue)
			bar.color = color
		end
		bar:SetValue(currentValue/maxValue)
	end
	
	return UpdateBar
end

local function GetImageWithText(parentControl, initY, imageFile, caption, fontSize, iconSize, textOffset)
	fontSize = fontSize or IMAGE_FONT
	iconSize = iconSize or ICON_SIZE
	
	local image = Chili.Image:New{
		x = 0,
		y = initY,
		width = iconSize,
		height = iconSize,
		file = imageFile,
		parent = parentControl,
	}
	local label = Chili.Label:New{
		x = iconSize + 2,
		y = initY + (textOffset or 0),
		right = 0,
		height = LEFT_LABEL_HEIGHT,
		caption = IMAGE_FONT,
		fontSize = fontSize,
		parent = parentControl,
	}
	
	local function Update(visible, newCaption, newImage, yPos)
		image:SetVisibility(visible)
		label:SetVisibility(visible)
		if not visible then
			return
		end
		if yPos then
			image:SetPos(nil, yPos)
			label:SetPos(nil, yPos + textOffset)
		end
		label:SetCaption(newCaption)
		if newImage ~= imageFile then
			if imageFile == nil then
				label:SetPos(iconSize + 2)
			elseif newImage == nil then
				label:SetPos(2)
			end
			imageFile = newImage
			image.file = imageFile
			image:Invalidate()
		end
	end
	
	return Update
end

local function GetMorphInfo(parentControl, yPos)
	local holder = Chili.Control:New{
		x = 0,
		y = yPos,
		right = 0,
		height = ICON_SIZE,
		padding = {0,0,0,0},
		parent = parentControl,
	}
	
	local morphLabel = Chili.Label:New{
		x = 4,
		y = 0,
		height = ICON_SIZE, 
		width = 50,
		valign = 'center', 
		caption = cyan .. 'Morph:',
		fontSize = BAR_FONT,
		parent = holder,
	}
	local timeImage = Chili.Image:New{
		x = 54,
		y = 0,
		width = ICON_SIZE,
		height = ICON_SIZE,
		file = TIME_IMAGE,
		parent = holder,
	}
	local timeLabel = Chili.Label:New{
		x = 54 + ICON_SIZE + 4,
		y = 4,
		right = 0,
		height = BAR_SIZE,
		caption = BAR_FONT,
		fontSize = fontSize,
		parent = holder,
	}
	local costImage = Chili.Image:New{
		x = 114,
		y = 0,
		width = ICON_SIZE,
		height = ICON_SIZE,
		file = COST_IMAGE,
		parent = holder,
	}
	local costLabel = Chili.Label:New{
		x = 113 + ICON_SIZE + 4,
		y = 4,
		right = 0,
		height = BAR_SIZE,
		caption = BAR_FONT,
		fontSize = fontSize,
		parent = holder,
	}
	
	local function Update(visible, newTime, newCost, yPos)
		holder:SetVisibility(visible)
		if not visible then
			return
		end
		if yPos then
			holder:SetPos(nil, yPos)
		end
		timeLabel:SetCaption(cyan .. newTime)
		costLabel:SetCaption(cyan .. newCost)
	end
	
	return Update
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit tooltip window

local function GetSingleUnitInfoPanel(parentControl, isTooltipVersion)
	
	local leftPanel = Chili.Control:New{
		x = 0,
		y = 0,
		width = LEFT_WIDTH,
		minWidth = LEFT_WIDTH,
		autosize = true,
		padding = {0,0,0,0},
		parent = parentControl,
	}
	local rightPanel = Chili.Control:New{
		x = LEFT_WIDTH,
		y = 0,
		width = RIGHT_WIDTH,
		minWidth = RIGHT_WIDTH,
		autosize = true,
		padding = {2,0,0,0},
		parent = parentControl,
	}
	
	local unitImage = Chili.Image:New{
		x = 0,
		y = 0,
		right = 0,
		height = PIC_HEIGHT,
		keepAspect = false,
		file = imageFile,
		parent = leftPanel,
	}
	
	local unitNameUpdate = GetImageWithText(rightPanel, 1, nil, nil, NAME_FONT, nil, 3)
	
	local unitDesc = Chili.TextBox:New{
		x = 4,
		y = 25,
		right = 0,
		height = BAR_SIZE,
		fontSize = DESC_FONT,
		parent = rightPanel,
	}
	
	local costInfoUpdate = GetImageWithText(leftPanel, PIC_HEIGHT + 4, COST_IMAGE, nil, nil, ICON_SIZE, 5)
	local metalInfoUpdate = GetImageWithText(leftPanel, PIC_HEIGHT + LEFT_SPACE + 4, METAL_IMAGE, nil, nil, ICON_SIZE, 5)
	local energyInfoUpdate = GetImageWithText(leftPanel, PIC_HEIGHT + 2*LEFT_SPACE + 4, ENERGY_IMAGE, nil, nil, ICON_SIZE, 5)
	
	local healthBarUpdate = GetBar(rightPanel, PIC_HEIGHT + 4, HEALTH_IMAGE, {0, 1, 0, 1}, GetHealthColor)
	
	local metalInfo
	local energyInfo
	
	local spaceClickLabel, shieldBarUpdate, buildBarUpdate, morphInfo, playerNameLabel, maxHealthLabel, morphInfo
	if isTooltipVersion then
		playerNameLabel = Chili.Label:New{
			name = "playerNameLabel",
			x = 4,
			y = PIC_HEIGHT + 31,
			right = 0,
			height = BAR_FONT,
			fontSize = BAR_FONT,
			parent = rightPanel,
		}
		spaceClickLabel = Chili.Label:New{
			x = 4,
			y = PIC_HEIGHT + 55,
			right = 0,
			height = 18,
			fontSize = DESC_FONT,
			caption = green .. WG.Translate("interface", "space_click_show_stats"),
			parent = rightPanel,
		}
		maxHealthLabel = GetImageWithText(rightPanel, PIC_HEIGHT + 4, HEALTH_IMAGE, nil, NAME_FONT, ICON_SIZE, 3)
		morphInfo = GetMorphInfo(rightPanel, PIC_HEIGHT + LEFT_SPACE + 3)
	else
		shieldBarUpdate = GetBar(rightPanel, PIC_HEIGHT + 4, SHIELD_IMAGE, {0.3,0,0.9,1})
		buildBarUpdate = GetBar(rightPanel, PIC_HEIGHT + 58, BUILD_IMAGE, {0.8,0.8,0.2,1})
	end

	local prevUnitID, prevUnitDefID, prevFeatureID, prevFeatureDefID, prevMorphTime, prevMorphCost, prevMousePlace
	local externalFunctions = {}
	
	local function UpdateDynamicUnitAttributes(unitID, unitDefID, ud)
		local mm, mu, em, eu = GetUnitResources(unitID)
		local showMetalInfo = false
		if mm then
			metalInfoUpdate(true, FormatPlusMinus(mm - mu), METAL_IMAGE, PIC_HEIGHT + LEFT_SPACE + 4)
			energyInfoUpdate(true, FormatPlusMinus(em - eu), ENERGY_IMAGE, PIC_HEIGHT + 2*LEFT_SPACE + 4)
			showMetalInfo = true
		end
		
		local healthPos
		if shieldBarUpdate then
			if ud and (ud.shieldPower > 0 or ud.level) then
				local shieldPower = Spring.GetUnitRulesParam(unitID, "comm_shield_max") or ud.shieldPower
				local _, shieldCurrentPower = Spring.GetUnitShieldState(unitID, -1)
				shieldBarUpdate(true, nil, shieldCurrentPower, shieldPower, (shieldCurrentPower < shieldPower) and GetUnitShieldRegenString(unitID, ud))
				healthPos = PIC_HEIGHT + 4 + BAR_SPACING
			else
				shieldBarUpdate(false)
				healthPos = PIC_HEIGHT + 4
			end
		end
		
		local health, maxHealth = spGetUnitHealth(unitID)
		healthBarUpdate(true, healthPos, health, maxHealth, (health < maxHealth) and GetUnitRegenString(unitID, ud))
		
		if buildBarUpdate then
			if ud and ud.buildSpeed > 0 then
				local metalMake, metalUse, energyMake,energyUse = Spring.GetUnitResources(unitID)
				
				local buildSpeed = ud.buildSpeed
				if ud.level then
					buildSpeed = buildSpeed*(Spring.GetUnitRulesParam(unitID, "buildpower_mult") or 1)
				end
				buildBarUpdate(true, (healthPos or (PIC_HEIGHT + 4)) + BAR_SPACING, metalUse or 0, buildSpeed)
			else
				buildBarUpdate(false)
			end
		end
		
		return showMetalInfo
	end
	
	local function UpdateDynamicFeatureAttributes(featureID, unitDefID)
		local metal, _, energy, _, _ = Spring.GetFeatureResources(featureID)
		local leftOffset = 1
		if unitDefID then
			leftOffset = PIC_HEIGHT + LEFT_SPACE
		end
		metalInfoUpdate(true, Format(metal), METAL_RECLAIM_IMAGE, leftOffset + 4)
		energyInfoUpdate(true, Format(energy), ENERGY_RECLAIM_IMAGE, leftOffset + LEFT_SPACE + 4)
	end
	
	function externalFunctions.SetDisplay(unitID, unitDefID, featureID, featureDefID, morphTime, morphCost, mousePlaceX, mousePlaceY)
		local teamID
		local addedName
		local ud
		local metalInfoShown = false
		local maxHealthShown = false
		local morphShown = false
		
		if prevUnitID == unitID and prevUnitDefID == unitDefID and prevFeatureID == featureID and prevFeatureDefID == featureDefID and 
				prevMorphTime == morphTime and prevMorphCost == morphCost and prevMousePlace == ((mousePlaceX and true) or false) then
			
			if unitID and unitDefID then
				UpdateDynamicUnitAttributes(unitID, unitDefID, UnitDefs[unitDefID])
			end
			if featureID then
				UpdateDynamicFeatureAttributes(featureID, prevUnitDefID)
			end
			return
		end
		
		if featureID then
			teamID = Spring.GetFeatureTeam(featureID)
			
			local fd = FeatureDefs[featureDefID]
			
			local featureName = fd and fd.name
			local unitName
			if fd and fd.customParams and fd.customParams.unit then
				unitName = fd.customParams.unit
			else
				unitName = featureName:gsub('(.*)_.*', '%1') --filter out _dead or _dead2 or _anything
			end
			
			if unitName and UnitDefNames[unitName] then
				unitDefID = UnitDefNames[unitName].id
			end
			
			if featureName:find("dead2") or featureName:find("heap") then
				addedName = " (" .. WG.Translate("interface", "debris") .. ")"
			elseif featureName:find("dead") then
				addedName = " (" .. WG.Translate("interface", "wreckage") .. ")"
			end
			
			healthBarUpdate(false)
			if unitDefID then
				if playerNameLabel then
					playerNameLabel:SetPos(nil, PIC_HEIGHT + 10)
					spaceClickLabel:SetPos(nil, PIC_HEIGHT + 34)
				end
			else
				costInfoUpdate(false)
				unitNameUpdate(true, fd.tooltip, nil)
				if playerNameLabel then
					playerNameLabel:SetPos(nil, PIC_HEIGHT - 10)
					spaceClickLabel:SetPos(nil, PIC_HEIGHT + 14)
				end
			end
			
			UpdateDynamicFeatureAttributes(featureID, unitDefID)
			metalInfoShown = true
		end
		
		if unitDefID then
			ud = UnitDefs[unitDefID]
			
			unitImage.file = "#" .. unitDefID
			unitImage.file2 = GetUnitBorder(unitDefID)
			unitImage:Invalidate()
			
			costInfoUpdate(true, cyan .. Spring.Utilities.GetUnitCost(unitID, unitDefID), COST_IMAGE, PIC_HEIGHT + 4)
			
			local extraTooltip, healthOverride
			if not unitID then
				extraTooltip, healthOverride = GetExtraBuildTooltipAndHealthOverride(unitDefID, mousePlaceX, mousePlaceY)
			end
			if extraTooltip then
				unitDesc:SetText(Spring.Utilities.GetDescription(ud, unitID) .. extraTooltip)
			else
				unitDesc:SetText(Spring.Utilities.GetDescription(ud, unitID))
			end
			unitDesc:Invalidate()
			
			local unitName = Spring.Utilities.GetHumanName(ud, unitID)
			if addedName then
				unitName = unitName .. addedName
			end
			unitNameUpdate(true, unitName, GetUnitIcon(unitDefID))
			
			if unitID then
				if playerNameLabel then
					playerNameLabel:SetPos(nil, PIC_HEIGHT + 31)
					spaceClickLabel:SetPos(nil, PIC_HEIGHT + 55)
				end
			elseif not featureDefID then
				healthBarUpdate(false)
				maxHealthLabel(true, healthOverride or ud.health, HEALTH_IMAGE)
				maxHealthShown = true
				if morphTime then
					morphInfo(true, morphTime, morphCost)
					morphShown = true
					if spaceClickLabel then
						spaceClickLabel:SetPos(nil, PIC_HEIGHT + LEFT_SPACE + 31)
					end
				elseif spaceClickLabel then
					spaceClickLabel:SetPos(nil, PIC_HEIGHT + 30)
				end
			end
		end
		
		if unitID then
			teamID = Spring.GetUnitTeam(unitID)
			if UpdateDynamicUnitAttributes(unitID, unitDefID, ud) then
				metalInfoShown = true
			end
		end
		
		if not metalInfoShown then
			metalInfoUpdate(false)
			energyInfoUpdate(false)
		end
		
		if playerNameLabel then
			local playerName = teamID and GetPlayerCaption(teamID)
			if playerName then
				playerNameLabel:SetCaption()
			end
			playerNameLabel:SetVisibility((playerName and true) or false)
		end
		
		local visibleUnitDefID = (unitDefID and true) or false
		unitImage:SetVisibility(visibleUnitDefID)
		unitDesc:SetVisibility(visibleUnitDefID)
		
		if spaceClickLabel then
			spaceClickLabel:SetVisibility(visibleUnitDefID)
		end
		
		if maxHealthLabel and not maxHealthShown then
			maxHealthLabel(false)
		end
		if morphInfo and not morphShown then
			morphInfo(false)
		end
		
		prevUnitID, prevUnitDefID, prevFeatureID, prevFeatureDefID = unitID, unitDefID, featureID, featureDefID
		prevMorphTime, prevMorphCost, prevMousePlace = morphTime, morphCost, ((mousePlaceX and true) or false)
	end
	
	function externalFunctions.SetVisible(newVisible)
		leftPanel:SetVisibility(newVisible)
		rightPanel:SetVisibility(newVisible)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tooltip window handler

local function GetTooltipWindow()
	local window = Chili.Window:New{
		name = "tooltipWindow",
		x = 300,
		y = 250,
		savespace = true,
		resizable = false,
		draggable = false,
		autosize  = true,
		minWidth = RIGHT_WIDTH,
		padding = {8,8,8,5},
		parent = screen0
	}
	window:Hide()
	
	local textTooltip = Chili.TextBox:New{
		name = "textTooltip",
		x = 0,
		y = 0,
		width = RIGHT_WIDTH - 10,
		height = 5,
		valign = "ascender", 
		autoHeight = true,
		font = {size = TOOLTIP_FONT},
		parent = window,
	}
	textTooltip:SetVisibility(false)
	
	local unitDisplay = GetSingleUnitInfoPanel(window, true)
	
	local externalFunctions = {}
	
	function externalFunctions.SetVisible(newVisible)
		window:SetVisibility(newVisible)
	end
	
	function externalFunctions.SetPosition(x, y)
		y = screenHeight - y
		window:SetPos(x, y)
		window:BringToFront()
	end
	
	function externalFunctions.SetTextTooltip(text)
		textTooltip:SetText(text)
		textTooltip:Invalidate()
		textTooltip:SetVisibility(true)
		unitDisplay.SetVisible(false)
	end
	
	function externalFunctions.SetUnitishTooltip(unitID, unitDefID, featureID, featureDefID, morphTime, morphCost, mousePlaceX, mousePlaceY)
		unitDisplay.SetDisplay(unitID, unitDefID, featureID, featureDefID, morphTime, morphCost, mousePlaceX, mousePlaceY)
		textTooltip:SetVisibility(false)
		unitDisplay.SetVisible(true)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Tooltip updates

local function GetUnitTooltip()
	local externalFunctions
	
	return externalFunctions
end

local function ShowUnitCheck(holdingSpace)
	if holdingSpace or options.show_for_units.value then
		return true
	end
end

local function ShowFeatureCheck(holdingSpace, featureDefID)
	if holdingSpace then
		return true
	end
	if options.show_for_wreckage.value then
		if options.show_for_unreclaimable.value then
			local fd = FeatureDefs[thingDefID]
			if not fd.reclaimable  then
				return false
			end
		end
		return true
	end
end

local function UpdateTooltipContent(mx, my, dt)
	local holdingDrawKey = GetIsHoldingDrawKey()
	local holdingSpace = select(3, Spring.GetModKeyState())
	UpdateMouseCursor(holdingDrawKey)
	
	if not (holdingSpace or (options.tooltip_delay.value == 0)) then
		local mouseMoved = (mx ~= oldMouseX or my ~= oldMouseY)
		if not mouseMoved then
			stillCursorTime = stillCursorTime + dt
			if stillCursorTime < options.tooltip_delay.value then
				return false
			end
		else
			stillCursorTime = 0
			oldMouseX = mx
			oldMouseY = my
			return false
		end
	end
	
	-- Mouseover build option tooltip (screen0.currentTooltip)
	local chiliTooltip = screen0.currentTooltip
	if chiliTooltip and string.find(chiliTooltip, "BuildUnit") then
		local name = string.sub(chiliTooltip, 10)
		local ud = name and UnitDefNames[name]
		if ud then
			tooltipWindow.SetUnitishTooltip(nil, ud.id)
			return true
		end
	elseif chiliTooltip and string.find(chiliTooltip, "Build") then
		local name = string.sub(chiliTooltip, 6)
		local ud = name and UnitDefNames[name]
		if ud then
			tooltipWindow.SetUnitishTooltip(nil, ud.id)
			return true
		end
	end
	
	-- Mouseover morph tooltip (screen0.currentTooltip)
	if chiliTooltip and string.find(chiliTooltip, "Morph") then
		local unitHumanName = chiliTooltip:gsub('Morph into a (.*)(time).*', '%1'):gsub('[^%a \-]', '')
		local morphTime = chiliTooltip:gsub('.*time:(.*)metal.*', '%1'):gsub('[^%d]', '')
		local morphCost = chiliTooltip:gsub('.*metal: (.*)energy.*', '%1'):gsub('[^%d]', '')
		local unitDefID = GetUnitDefByHumanName(unitHumanName)
		if unitDefID and morphTime and morphCost then
			tooltipWindow.SetUnitishTooltip(nil, unitDefID, nil, nil, morphTime, morphCost)
		end
		return true
	end
	
	-- Generic chili text tooltip
	if chiliTooltip then
		tooltipWindow.SetTextTooltip(chiliTooltip)
		return true
	end
	
	-- Map drawing tooltip
	if holdingDrawKey and (holdingSpace or options.showdrawtooltip.value) then
		tooltipWindow.SetTextTooltip(DRAWING_TOOLTIP)
		return true
	end
	
	-- Terraform tooltip (spring.GetActiveCommand)
	local index, cmdID, cmdType, cmdName = Spring.GetActiveCommand()
	if cmdID and terraCmdTip[cmdID] and (holdingSpace or options.showterratooltip.value) then
		tooltipWindow.SetTextTooltip(terraCmdTip[cmdID])
		return true
	end
	
	-- Placing structure tooltip (spring.GetActiveCommand)
	if cmdID and cmdID < 0 then
		tooltipWindow.SetUnitishTooltip(nil, -cmdID, nil, nil, nil, nil, mx, my)
		return true
	end
	
	-- Unit or feature tooltip 
	local mx, my = spGetMouseState()
	local thingType, thingID = spTraceScreenRay(mx,my)
	local thingIsUnit = (thingType == "unit")
	if thingIsUnit or (thingType == "feature") then
		local ignoreDelay = holdingSpace or (options.independant_world_tooltip_delay.value == 0)
		if ignoreDelay or (thingID == sameObjectID) then
			if ignoreDelay or (sameObjectIDTime > options.independant_world_tooltip_delay.value) then
				local thingDefID = (thingIsUnit and Spring.GetUnitDefID(thingID)) or Spring.GetFeatureDefID(thingID)
				if thingIsUnit then
					if ShowUnitCheck(holdingSpace) then
						tooltipWindow.SetUnitishTooltip(thingID, thingDefID)
						return true
					end
				else
					if ShowFeatureCheck(holdingSpace, thingDefID) then
						tooltipWindow.SetUnitishTooltip(nil, nil, thingID, thingDefID)
						return true
					end
				end
			else
				sameObjectIDTime = sameObjectIDTime + dt
			end
		else
			sameObjectID = thingID
			sameObjectIDTime = 0
		end
	end
	
	-- Ground position tooltip (spGetCurrentTooltip())
	if holdingSpace then
		tooltipWindow.SetTextTooltip(Spring.GetCurrentTooltip())
		return true
	end
	
	-- Start position tooltip (really bad widget interface)
	-- Don't want to implement this as is (pairs over positions registered in WG).
	
	-- Geothermal tooltip (WG.mouseAboveGeo)
	if WG.mouseAboveGeo then
		tooltipWindow.SetTextTooltip(WG.Translate("interface", "geospot"))
		return true
	end
	
	return false
end

local function UpdateTooltip(dt)
	local mx, my = spGetMouseState()
	local visible = UpdateTooltipContent(mx, my, dt)
	tooltipWindow.SetVisible(visible)
	if visible then
		tooltipWindow.SetPosition(mx + 20, my - 20)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selection window handler

local function GetSelectionWindow()
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	local integralWidth = math.max(350, math.min(450, screenWidth*screenHeight*0.0004))
	local integralHeight = math.min(screenHeight/4.5, 200*integralWidth/450)  + 8
	local x = integralWidth
	local height = integralHeight*0.84

	local holderWindow = Chili.Window:New{
		name      = 'selections2',
		x         = x, 
		bottom    = 0,
		width     = 450,
		height    = height,
        minWidth  = 450, 
		minHeight = 120,
		dockable  = true,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		padding = {0, 0, 0, -1},
		color = {0, 0, 0, 0},
		parent = screen0,
	}
	holderWindow:SendToBack()
	
	local mainPanel = Chili.Panel:New{
		classname = options.fancySkinning.value,
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding = {8 + options.leftPadding.value, 6, 4, 4},
		backgroundColor = {1, 1, 1, options.selection_opacity.value},
		OnMouseDown = {
			function(self)
				local _,_, meta,_ = spGetModKeyState()
				if not meta then 
					return false 
				end
				WG.crude.OpenPath('Settings/HUD Panels/Selected Units Window')
				WG.crude.ShowMenu() 
				return true --skip button function, else clicking on build pic will also select the unit.
			end 
		},
		parent = holderWindow
	}
	mainPanel:Hide()
	
	local singleUnitDisplay = GetSingleUnitInfoPanel(mainPanel, false)
	
	local externalFunctions = {}
	
	function externalFunctions.ShowSingleUnit(unitID)
		singleUnitDisplay.SetDisplay(unitID, Spring.GetUnitDefID(unitID))
		singleUnitDisplay.SetVisible(true)
	end
	
	function externalFunctions.SetVisible(newVisible)
		mainPanel:SetVisibility(newVisible)
	end
	
	function externalFunctions.SetOpacity(opacity)
		mainPanel.backgroundColor = {1,1,1,opacity}
		mainPanel:Invalidate()
	end
	
	function externalFunctions.SetSkin(className)
		SetPanelSkin(mainPanel, className)
	end
	
	function externalFunctions.SetLeftPadding(padding)
		mainPanel.padding[1] = 8 + padding
		mainPanel:UpdateClientArea()
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Selection update

local function UpdateSelection(newSelection)
	-- Check if selection is 0, hide window. Return
	-- Check if selection is 1, get unit tooltip
	-- Check if selection is many, get unit list tooltip
	-- Update group info.
	if (not newSelection) or (#newSelection == 0) then
		selectionWindow.SetVisible(false)
		return
	end
	
	selectionWindow.SetVisible(true)
	if #newSelection == 1 then
		selectionWindow.ShowSingleUnit(newSelection[1])
		return
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

local function InitializeWindParameters()
	windMin = spGetGameRulesParam("WindMin")
	windMax = spGetGameRulesParam("WindMax")
	windGroundMin = spGetGameRulesParam("WindGroundMin")
	windGroundExtreme = spGetGameRulesParam("WindGroundExtreme")
	windGroundSlope = spGetGameRulesParam("WindSlope")
end

function widget:Update(dt)
	UpdateTooltip(dt)
end

function widget:SelectionChanged(newSelection)
	UpdateSelection(newSelection)
end

function widget:ViewResize(vsx, vsy)
	screenWidth = vsx
	screenHeight = vsy
end

function widget:Initialize()
	Chili = WG.Chili
	screen0 = Chili.Screen0
	
	Spring.AssignMouseCursor(CURSOR_ERASE_NAME, CURSOR_ERASE, true, false) -- Hotspot center.
	Spring.AssignMouseCursor(CURSOR_POINT_NAME, CURSOR_POINT, true, true)
	Spring.AssignMouseCursor(CURSOR_DRAW_NAME, CURSOR_DRAW, true, true)
	
	local hotkeys = WG.crude.GetHotkeys("drawinmap")
	for k,v in pairs(hotkeys) do
		drawHotkeyBytesCount = drawHotkeyBytesCount + 1
		drawHotkeyBytes[drawHotkeyBytesCount] = v:byte(-1)
	end
	
	selectionWindow = GetSelectionWindow()
	tooltipWindow = GetTooltipWindow()
	InitializeWindParameters()
end