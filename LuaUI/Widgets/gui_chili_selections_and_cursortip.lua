
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

local strFormat = string.format
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Chili
local screen0

local tooltipWindow

local ICON_SIZE = 20
local BAR_SIZE = 22
local BAR_FONT = 13
local IMAGE_FONT = 10
local DESC_FONT = 10
local TOOLTIP_FONT = 12
local NAME_FONT = 14
local LEFT_SPACE = 24

local LEFT_WIDTH = 55
local PIC_HEIGHT = LEFT_WIDTH*4/5
local RIGHT_WIDTH = 235

local green = '\255\1\255\1'
local red = '\255\255\1\1'
local cyan = '\255\1\255\255'
local white = '\255\255\255\255'
local yellow = '\255\255\255\1'

local HEALTH_IMAGE = 'LuaUI/images/commands/bold/health.png'
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables

local drawHotkeyBytes = {}
local drawHotkeyBytesCount = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

options_path = 'Settings/HUD Panels/Tooltip'
local selPath = 'Settings/HUD Panels/Selected Units Panel'

options_order = {
	--tooltip
	'tooltip_delay', 'independant_world_tooltip_delay',
	'show_for_units', 'show_for_wreckage', 'show_for_unreclaimable', 'show_position', 'show_unit_text', 'showdrawtooltip','showterratooltip',
	'showDrawTools',
	
	--selected units
	--'selection_opacity', 'groupalways', 'showgroupinfo', 'squarepics','uniticon_size','unitCommand', 'manualWeaponReloadBar', 'alwaysShowSelectionWin',
	--'fancySkinning', 'leftPadding',
}

options = {
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
		desc = 'Show pencil or eraser when drawing or erasing.'
	},

	--selection_opacity = {
	--	name = "Opacity",
	--	type = "number",
	--	value = 0.8, min = 0, max = 1, step = 0.01,
	--	OnChange = function(self)
	--		window_corner.backgroundColor = {1,1,1,self.value}
	--		window_corner:Invalidate()
	--	end,
	--	path = selPath,
	--},
	--groupalways = {name='Always Group Units', type='bool', value=false, OnChange = option_Deselect,
	--	path = selPath,
	--},
	--showgroupinfo = {name='Show Group Info', type='bool', value=true, OnChange = option_Deselect,
	--	path = selPath,
	--},
	--squarepics = {name='Square Buildpics', type='bool', value=false, OnChange = option_Deselect,
	--	path = selPath,
	--},
	--unitCommand = {
	--	name="Show Unit's Command",
	--	type='bool',
	--	value= false,
	--	noHotkey = true,
	--	desc = "Display current command on unit's icon (only for ungrouped unit selection)",
	--	path = selPath,
	--},
	--uniticon_size = {
	--	name = 'Icon size on selection list',
	--	--desc = 'Determines how small the icon in selection list need to be.',
	--	type = 'number',
	--	OnChange = function(self) 
	--		option_Deselect()
	--		unitIcon_size = math.modf(self.value)
	--	end,
	--	min=30,max=50,step=1,
	--	value = 50,
	--	path = selPath,
	--},
	--manualWeaponReloadBar = {
	--	name="Show Unit's Special Weapon Status",
	--	type='bool',
	--	value= true,
	--	noHotkey = true,
	--	desc = "Show reload progress for weapon that use manual trigger (only for ungrouped unit selection)",
	--	path = selPath,
	--	OnChange = option_Deselect,
	--},
	--fancySkinning = {
	--	name = 'Fancy Skinning',
	--	type = 'radioButton',
	--	value = 'panel',
	--	path = selPath,
	--	items = {
	--		{key = 'panel', name = 'None'},
	--		{key = 'panel_1120', name = 'Bottom Left Flush',},
	--		{key = 'panel_0120', name = 'Bot Mid Left Flush',},
	--		{key = 'panel_2120', name = 'Bot Mid Both Flush',},
	--	},
	--	OnChange = function (self)
	--		local currentSkin = Chili.theme.skin.general.skinName
	--		local skin = Chili.SkinHandler.GetSkin(currentSkin)
	--		
	--		local className = self.value
	--		local newClass = skin.panel
	--		if skin[className] then
	--			newClass = skin[className]
	--		end
	--		
	--		window_corner.tiles = newClass.tiles
	--		window_corner.TileImageFG = newClass.TileImageFG
	--		--window_corner.backgroundColor = newClass.backgroundColor
	--		window_corner.TileImageBK = newClass.TileImageBK
	--		if newClass.padding then
	--			window_corner.padding = newClass.padding
	--			window_corner:UpdateClientArea()
	--		end
	--		window_corner:Invalidate()
	--	end,
	--	advanced = true,
	--	noHotkey = true,
	--},
	--leftPadding = {
	--	name = "Left Padding",
	--	type = "number",
	--	value = 0, min = 0, max = 500, step = 1,
	--	OnChange = function(self)
	--		window_corner.padding[1] = 8 + self.value
	--		window_corner:UpdateClientArea()
	--	end,
	--	path = selPath,
	--},
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
		if regen_timer then
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

local function GetPlayerCaption(teamID)
	local _, player,_,isAI = Spring.GetTeamInfo(teamID)
	local playerName
	if isAI then
		local _, aiName, _, shortName = Spring.GetAIInfo(teamID)
		playerName = aiName ..' ('.. shortName .. ')'
	else
		playerName = player and Spring.GetPlayerInfo(player) or 'noname'
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
	if not holdingDrawKey then
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
		height = BAR_SIZE,
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
	
	local spaceClickLabel, shieldBar, buildBar, morphInfo, playerNameLabel, maxHealthLabel, morphInfo
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
			height = DESC_FONT,
			fontSize = DESC_FONT,
			caption = green .. WG.Translate("interface", "space_click_show_stats"),
			parent = rightPanel,
		}
		maxHealthLabel = GetImageWithText(rightPanel, PIC_HEIGHT + 4, HEALTH_IMAGE, nil, NAME_FONT, ICON_SIZE, 3)
		morphInfo = GetMorphInfo(rightPanel, PIC_HEIGHT + LEFT_SPACE + 3)
	else
		--shieldBar
		--buildBar
	end

	local externalFunctions = {}
	
	function externalFunctions.SetDisplay(unitID, unitDefID, featureID, featureDefID, morphTime, morphCost)
		local teamID
		local addedName
		local metalInfoShown = false
		local maxHealthShown = false
		local morphShown = false
		
		if featureID then
			teamID = Spring.GetFeatureTeam(featureID)
			local fd = FeatureDefs[featureDefID]
			
			local leftOffset = PIC_HEIGHT + LEFT_SPACE
			
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
				playerNameLabel:SetPos(nil, PIC_HEIGHT + 10)
				spaceClickLabel:SetPos(nil, PIC_HEIGHT + 34)
			else
				leftOffset = 1
				costInfoUpdate(false)
				unitNameUpdate(true, fd.tooltip, nil)
				playerNameLabel:SetPos(nil, PIC_HEIGHT - 10)
				spaceClickLabel:SetPos(nil, PIC_HEIGHT + 14)
			end
			
			local metal, _, energy, _, _ = Spring.GetFeatureResources(featureID)
			metalInfoUpdate(true, Format(metal), METAL_RECLAIM_IMAGE, leftOffset + 4)
			energyInfoUpdate(true, Format(energy), ENERGY_RECLAIM_IMAGE, leftOffset + LEFT_SPACE + 4)
			metalInfoShown = true
		end
		
		if unitDefID then
			local ud = UnitDefs[unitDefID]
			
			unitImage.file = "#" .. unitDefID
			unitImage.file2 = GetUnitBorder(unitDefID)
			unitImage:Invalidate()
			
			costInfoUpdate(true, cyan .. Spring.Utilities.GetUnitCost(unitID, unitDefID), COST_IMAGE, PIC_HEIGHT + 4)
			
			unitDesc:SetText(Spring.Utilities.GetDescription(ud, unitID))
			unitDesc:Invalidate()
			
			local unitName = Spring.Utilities.GetHumanName(ud, unitID)
			if addedName then
				unitName = unitName .. addedName
			end
			unitNameUpdate(true, unitName, GetUnitIcon(unitDefID))
			
			if unitID then
				playerNameLabel:SetPos(nil, PIC_HEIGHT + 31)
				spaceClickLabel:SetPos(nil, PIC_HEIGHT + 55)
			elseif not featureDefID then
				healthBarUpdate(false)
				maxHealthLabel(true, ud.health, HEALTH_IMAGE)
				maxHealthShown = true
				if morphTime then
					morphInfo(true, morphTime, morphCost)
					morphShown = true
					spaceClickLabel:SetPos(nil, PIC_HEIGHT + LEFT_SPACE + 31)
				else
					spaceClickLabel:SetPos(nil, PIC_HEIGHT + 30)
				end
			end
		end
		
		if unitID then
			teamID = Spring.GetUnitTeam(unitID)
			
			local mm, mu, em, eu = GetUnitResources(unitID)
			if mm then
				metalInfoUpdate(true, FormatPlusMinus(mm - mu), METAL_IMAGE, PIC_HEIGHT + LEFT_SPACE + 4)
				energyInfoUpdate(true, FormatPlusMinus(em - eu), ENERGY_IMAGE, PIC_HEIGHT + 2*LEFT_SPACE + 4)
				metalInfoShown = true
			end
			
			local health, maxHealth = spGetUnitHealth(unitID)
			healthBarUpdate(true, nil, health, maxHealth, (health < maxHealth) and GetUnitRegenString(unitID, ud))
		end
		
		if not metalInfoShown then
			metalInfoUpdate(false)
			energyInfoUpdate(false)
		end
		
		if playerNameLabel and teamID then
			playerNameLabel:SetCaption(GetPlayerCaption(teamID))
		end
		playerNameLabel:SetVisibility((playerNameLabel and teamID and true) or false)
		
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
	end
	
	function externalFunctions.SetVisible(newVisible)
		leftPanel:SetVisibility(newVisible)
		rightPanel:SetVisibility(newVisible)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
		parent = screen0
	}
	
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
	
	function externalFunctions.SetTextTooltip(text)
		textTooltip:SetText(text)
		textTooltip:Invalidate()
		textTooltip:SetVisibility(true)
		unitDisplay.SetVisible(false)
	end
	
	function externalFunctions.SetUnitishTooltip(unitID, unitDefID, featureID, featureDefID, morphTime, morphCost)
		unitDisplay.SetDisplay(unitID, unitDefID, featureID, featureDefID, morphTime, morphCost)
		textTooltip:SetVisibility(false)
		unitDisplay.SetVisible(true)
	end
	
	return externalFunctions
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetUnitTooltip()
	local externalFunctions
	
	return externalFunctions
end

local function UpdateTooltip()
	local holdingDrawKey = GetIsHoldingDrawKey()
	local holdingSpace = select(3, Spring.GetModKeyState())
	UpdateMouseCursor(holdingDrawKey)
	
	local mx, my = spGetMouseState()
	
	-- Mouseover build option tooltip (screen0.currentTooltip)
	local chiliTooltip = screen0.currentTooltip
	if chiliTooltip and string.find(chiliTooltip, "Build") then
		local name = string.sub(chiliTooltip, 6)
		local ud = name and UnitDefNames[name]
		if ud then
			tooltipWindow.SetUnitishTooltip(nil, ud.id)
			return
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
		return
	end
	
	-- Generic chili text tooltip
	if chiliTooltip then
		tooltipWindow.SetTextTooltip(chiliTooltip)
		return
	end
	
	-- Map drawing tooltip
	if holdingDrawKey then
		tooltipWindow.SetTextTooltip(DRAWING_TOOLTIP)
		return
	end
	
	
	-- Terraform tooltip (spring.GetActiveCommand)
	local index, cmdID, cmdType, cmdName = Spring.GetActiveCommand()
	if cmdID and terraCmdTip[cmdID] then -- options.showterratooltip.value and
		tooltipWindow.SetTextTooltip(terraCmdTip[cmdID])
		return
	end
	
	-- Placing structure tooltip (spring.GetActiveCommand)
	if cmdID and cmdID < 0 then
		tooltipWindow.SetUnitishTooltip(nil, -cmdID)
		return
	end
	
	-- Unit tooltip (trace screen ray (surely))
	local mx, my = spGetMouseState()
	local thingType, thingParam = spTraceScreenRay(mx,my)
	if thingType == "unit" then
		local unitDefID = Spring.GetUnitDefID(thingParam)
		tooltipWindow.SetUnitishTooltip(thingParam, unitDefID)
		return
	end
	
	-- Feature tooltip (trace screen ray (surely))
	if thingType == "feature" then
		local featureDefID = Spring.GetFeatureDefID(thingParam)
		tooltipWindow.SetUnitishTooltip(nil, nil, thingParam, featureDefID)
		return
	end
	
	-- Ground position tooltip (spGetCurrentTooltip())
	if holdingSpace then
		tooltipWindow.SetTextTooltip(Spring.GetCurrentTooltip())
		return
	end
	
	-- Start position tooltip (really bad widget interface)
	-- Don't want to implement this as is (pairs over positions registered in WG).
	
	-- Geothermal tooltip (WG.mouseAboveGeo)
	if WG.mouseAboveGeo then
		WG.Translate("interface", "geospot")
		return
	end
end

function widget:SelectionChanged(newSelection)
	-- Check if selection is 0, hide window. Return
	-- Check if selection is 1, get unit tooltip
	-- Check if selection is many, get unit list tooltip
	-- Update group info.
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Widget Interface

function widget:Update(dt)
	UpdateTooltip()
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
	
	tooltipWindow = GetTooltipWindow()
end