function widget:GetInfo()
	return {
		name      = "Field Factory Selector",
		desc      = "Selects construction option from a factory",
		author    = "GoogleFrog",
		date      = "2 April 2024",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true  --  loaded by default?
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local CMD_FIELD_FAC_SELECT    = Spring.Utilities.CMD.FIELD_FAC_SELECT
local CMD_FIELD_FAC_UNIT_TYPE = Spring.Utilities.CMD.FIELD_FAC_UNIT_TYPE

local screenWidth, screenHeight = Spring.GetViewGeometry()

local OPT_WIDTH = 380
local OPT_HEIGHT = 142

local ROWS = 2
local COLUMNS = 6

local Chili
local optionsWindow

local _, factoryUnitPosDef = include("Configs/integral_menu_commands.lua", nil, VFS.RAW_FIRST)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function GetOptionsPosition(width, height)
	local x, y = Spring.ScaledGetMouseState()
	y = screenHeight - y
	x = x - OPT_WIDTH / 2
	y = y - OPT_HEIGHT - 20
	
	if x + width > screenWidth - 2 then
		x = screenWidth - width - 2
	end
	if y + height > screenHeight - 2 then
		y = screenHeight - height - 2
	end
	
	local map = WG.MinimapPosition
	if map then
		-- Only move tooltip up and/or left if it overlaps the minimap. This is because the
		-- minimap does not have tooltips.
		if x < map[1] + map[3] and y < map[2] + map[4] then
			local inX = x + width - map[1] + 2
			local inY = y + height - map[2] + 2
			if inX > 0 and inY > 0 then
				if inX > inY then
					y = y - inY
				else
					x = x - inX
				end
			end
		end
		
		if x + width > screenWidth - 2 then
			x = screenWidth - width - 2
		end
		if y + height > screenHeight - 2 then
			y = screenHeight - height - 2
		end
	end
	
	return math.floor(x), math.floor(y)
end

local function GetButton(parent, x, y, unitDefID, ud, unitName)
	local xStr = tostring((x - 1)*100/COLUMNS) .. "%"
	local yStr = tostring((y - 1)*100/ROWS) .. "%"
	
	local function DoClick()
		if unitDefID then
			Spring.GiveOrder(CMD_FIELD_FAC_UNIT_TYPE, {unitDefID}, 0)
		else
			Spring.GiveOrder(CMD_FIELD_FAC_UNIT_TYPE, {-1}, 0)
		end
		optionsWindow:Dispose()
		optionsWindow = false
	end
	
	local button = Chili.Button:New {
		name = name,
		x = xStr,
		y = yStr,
		width = "16.7%",
		height = "50%",
		caption = false,
		noFont = true,
		padding = {0, 0, 0, 0},
		parent = parent,
		preserveChildrenOrder = true,
		tooltip = (unitName and "BuildUnit" .. unitName) or "Cancel",
		OnClick = {DoClick},
	}
	if unitDefID then
		Chili.Label:New {
			name = "bottomLeft",
			x = "15%",
			right = 0,
			bottom = 2,
			height = 12,
			fontsize = 12,
			parent = button,
			caption = ud.metalCost,
		}
		Chili.Image:New {
			x = "5%",
			y = "4%",
			right = "5%",
			bottom = 12,
			keepAspect = false,
			file = "#" .. unitDefID,
			file2 = WG.GetBuildIconFrame(ud),
			parent = button,
		}
	else
		Chili.Image:New {
			x = "7%",
			y = "10%",
			right = "7%",
			bottom = "10%",
			keepAspect = true,
			file = "LuaUI/Images/commands/Bold/cancel.png",
			parent = button,
		}
	end
end

local function GenerateOptionsSelector(factoryID)
	if optionsWindow then
		optionsWindow:Dispose()
		optionsWindow = false
	end
	
	local unitDefID = Spring.ValidUnitID(factoryID) and Spring.GetUnitDefID(factoryID)
	if not unitDefID then
		return
	end
	local ud = UnitDefs[unitDefID]
	if not ud then
		return
	end
	local name = ud.name
	local buildList = ud.buildOptions
	local layoutData = factoryUnitPosDef[name]
	if not buildList then
		return
	end
	
	local x, y = GetOptionsPosition(OPT_WIDTH, OPT_HEIGHT)
	
	optionsWindow = Chili.Window:New{
		x = x,
		y = y,
		width = OPT_WIDTH,
		height = OPT_HEIGHT,
		padding = {14, 20, 14, 8},
		classname = "main_window_small_tall",
		textColor = {1,1,1,0.55},
		parent = Chili.Screen0,
		dockable  = false,
		resizable = false,
		caption = "Select blueprint to copy:",
	}
	optionsWindow:BringToFront()
	
	for i = 1, #buildList do
		local buildDefID = buildList[i]
		local bud = UnitDefs[buildDefID]
		local buildName = bud.name
		local position = buildName and layoutData and layoutData[buildName]
		if position then
			GetButton(optionsWindow, position.col, position.row, buildDefID, bud, buildName)
		else
			local row = (i > 6) and 2 or 1
			local col = (i - 1)%6 + row
			GetButton(optionsWindow, col, row, buildDefID, bud, buildName)
		end
	end
	
	GetButton(optionsWindow, 1, 2)
end

function widget:CommandNotify(cmdID, params, options)
	if (cmdID == CMD_FIELD_FAC_SELECT) and params and params[1] then
		GenerateOptionsSelector(params[1])
		return false
	end
	if optionsWindow then
		optionsWindow:Dispose()
		optionsWindow = false
	end
end

function widget:ViewResize(vsx, vsy)
	screenWidth = vsx/(WG.uiScale or 1)
	screenHeight = vsy/(WG.uiScale or 1)
end

function widget:Initialize()
	Chili = WG.Chili
end
