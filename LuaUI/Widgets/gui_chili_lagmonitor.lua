function widget:GetInfo() return {
	name      = "Lag monitor popup",
	desc      = "Allows to /take droppers and AFKers",
	author    = "Sprung",
	license   = "GNU GPL v2 or later",
	layer     = 0,
	enabled   = true
} end

local mainWindow
local labelText

local takeables = { }
local isSpectator = Spring.GetSpectatingState()
local doNotDisturb = false

local function SetupWindow()
	local Chili = WG.Chili

	local newMainWindow = Chili.Window:New{
		parent = Chili.Screen0,
		name  = 'afkPopupWindow';
		width = 280;
		height = 160;
		classname = "main_window_small",
		y = 245,
		right = 60;
		dockable = false;
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,
		padding = {0, 0, 0, 0},
	}

	labelText = Chili.TextBox:New{
		x = 24,
		right = 10,
		y = 24,
		parent = newMainWindow,
		autosize = false;
		align  = "center";
		valign = "top";
		text   = "foo";
		font   = {size = 16, color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, outlineWidth = 2},
	}

	local button_take = Chili.Button:New {
		width = 60,
		x = 15,
		height = 20,
		bottom = 15,
		classname = "action_button",
		parent = newMainWindow;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		caption = "Take";
		font   = {size = 16, color = {1,1,1,1}, outlineColor = {0,0,0,0.7}, outlineWidth = 2},
		tooltip = "Take those players' units.";
		OnClick = { function()
			Spring.SendLuaRulesMsg("afk_take")
		end }
	}

	local chbox_gtfo = Chili.Checkbox:New{
		width = 120,
		bottom = 15,
		right = 15,
		caption = "Don't bother me",
		checked = false,
		OnChange = { function(self)
			doNotDisturb = not self.checked
		end },
		tooltip = "The popup won't reappear this battle again.",
		parent = newMainWindow,
	}

	local button_close = Chili.Button:New {
		classname = "action_button",
		caption = "X";
		width = 15,
		right = 15,
		height = 15,
		y = 12,
		parent = newMainWindow;
		padding = {0, 0, 0,0},
		margin = {0, 0, 0, 0},
		font   = {size = 12, color = {1,0,0,1}, outlineColor = {0,0,0,0.7}, outlineWidth = 2},
		tooltip = "Close the popup.",
		OnClick = { function()
			if doNotDisturb then
				widgetHandler:RemoveCallIn("TeamAfked")
				widgetHandler:RemoveCallIn("TeamUnafked")
				widgetHandler:RemoveCallIn("TeamTaken")
				mainWindow:Dispose()
			else
				mainWindow:Hide()
			end
		end }
	}

	return newMainWindow
end

local teamNames = {}
function widget:Initialize()
	isSpectator = Spring.GetSpectatingState()
	local teamList = Spring.GetTeamList()
	for i = 1, #teamList do
		local teamID = teamList[i]
		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)
		if isAI then
			teamNames[teamID] = select(2, Spring.GetAIInfo(teamID))
		else
			teamNames[teamID] = Spring.GetPlayerInfo(playerID)
		end
	end

	if isSpectator then
		widgetHandler:RemoveCallIn("TeamAfked")
		widgetHandler:RemoveCallIn("TeamUnafked")
		widgetHandler:RemoveCallIn("TeamTaken")
	end
end

local function GetColoredName(teamID)
	local r, g, b = Spring.GetTeamColor(teamID)
	r, g, b = math.floor(255*r), math.floor(255*g), math.floor(255*b)
	return string.char(255) .. string.char(r) .. string.char(g) .. string.char(b) .. (teamNames[teamID] or "?")
end

local function RefreshWindow(forceShow)
	if not forceShow and (not mainWindow or not mainWindow.visible) then
		return
	end

	if not next(takeables) then
		if mainWindow then
			mainWindow:Hide()
		end
		return
	end

	mainWindow = mainWindow or SetupWindow()

	local newStr = "Eligible for take: "
	local first = true
	for teamID in pairs(takeables) do
		if not first then
			newStr = newStr .. ", "
		end
		first = false -- pop this cherry
		newStr = newStr .. GetColoredName(teamID) .. "\255\255\255\255" -- cant use \008 to reset because chili textbox caches only "true" colorcodes and would still use the old one after line break
	end
	labelText:SetText(newStr)

	mainWindow:Show()
	mainWindow:BringToFront()
end

function widget:TeamAfked(teamID)
	if teamID == Spring.GetMyTeamID()
	or select(6, Spring.GetTeamInfo(teamID)) ~= Spring.GetLocalAllyTeamID()
	then
		return
	end

	takeables[teamID] = true
	RefreshWindow(true)
end

function widget:TeamUnafked(teamID)
	if not takeables[teamID] then
		return
	end

	takeables[teamID] = nil
	RefreshWindow(false)
end

function widget:TeamTaken(giveTeamID, receiveTeamID)
	if not takeables[giveTeamID] then
		return
	end

	takeables[giveTeamID] = nil
	RefreshWindow(false)
end

function widget:PlayerChanged(playerID)
	local newSpectator = Spring.GetSpectatingState()
	if isSpectator ~= newSpectator then
		if newSpectator then
			widgetHandler:RemoveCallIn("TeamAfked")
			widgetHandler:RemoveCallIn("TeamUnafked")
			widgetHandler:RemoveCallIn("TeamTaken")
			mainWindow:Dispose()
		else
			widgetHandler:UpdateCallIn("TeamAfked")
			widgetHandler:UpdateCallIn("TeamUnafked")
			widgetHandler:UpdateCallIn("TeamTaken")
		end
		return
	end

	local _, _, isSpec, teamID, allyTeamID = Spring.GetPlayerInfo(playerID)
	if not isSpec
	or allyTeamID ~= Spring.GetLocalAllyTeamID()
	or select(2, Spring.GetTeamInfo(teamID)) ~= -1 then
		return
	end

	takeables[teamID] = true
	RefreshWindow(true)
end
