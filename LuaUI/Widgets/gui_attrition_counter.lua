function widget:GetInfo() return {
	name      = "Attrition Counter",
	desc      = "Shows a counter that keeps track of player/team kills/losses",
	author    = "Anarchid, Klon",
	date      = "Dec 2012, Aug 2015",
	license   = "GPL",
	layer     = -10,
	enabled   = true
} end

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")

-- flags; all of those must be enabled for widget::Update to run
local MAIN_WINDOW_VISIBILITY = 1
local SPEC_TEAM_UPDATE = 2
local updateSources = {
	[MAIN_WINDOW_VISIBILITY] = true,
	[SPEC_TEAM_UPDATE] = true,
}
local function SetUpdate(updateSource, updateValue)
	updateSources[updateSource] = updateValue
	for i = 1, #updateSources do
		if not updateSources[i] then
			widgetHandler:RemoveCallIn('Update')
			return
		end
	end
	widgetHandler:UpdateCallIn('Update')
end

options_path = 'Settings/HUD Panels/Attrition Counter'
options = {
	show_for_spectated = {
		name = "Show for spectated team",
		type = 'bool',
		value = true,
		noHotkey = true,
		desc = 'If enabled, shows attrition for the currently spectated team.\nIf disabled, consistently shows for the initial team.',
		OnChange = function (self)
			SetUpdate(SPEC_TEAM_UPDATE, self.value)
		end,
	},
	--[[ WIP
	show_extra_stats = {
		name = "Show extra stats",
		type = 'bool',
		value = false,
		noHotkey = true,
		desc = 'If enabled, additionally shows damaged value and killed units.\nIf disabled, only shows killed value.',
		OnChange = function (self)
			-- extend window downwards
			panel_extras:Show()
		end,
	},
	]]
}

local floor = math.floor
local min = math.min
local max = math.max -- fury road
local function cap (x) return max(min(x,1),0) end

local window_main
local panel_main
local label_name
local label_rate
local label_pwn
local label_ded
local icon_pwn
local icon_ded
local global_command_button
local font

local GRAY = {0.5, 0.5, 0.5, 1}
local BLUE = {0, 0, 1, 1}
local CYAN = {0, 1, 1, 1}

local ICON_KILLS_FILE = 'anims/cursorattack_2.png'
local ICON_LOST_FILE = 'luaui/images/AttritionCounter/skull.png'

local myAllyTeamID
local myAllyTeamMembers = {}

local WINDOW_WIDTH = 200
local NAME_LABEL_SIZE = 20
local MAIN_PANEL_SIZE = 70

local strings = {
	attrition_individual_stats = "",
	attrition_pwn = "",
	attrition_na = "",
}

local UpdateCounter

local wasSpectating = true
local function ShowNameLabel()

	local isSpectating = Spring.GetSpectatingState()
	if isSpectating == true then
		if not wasSpectating then
			label_name:Show()
			panel_main:SetPos(0, NAME_LABEL_SIZE)
			window_main:SetPos(nil, nil, window_main.w, NAME_LABEL_SIZE + MAIN_PANEL_SIZE)
		end
	else
		if wasSpectating then
			label_name:Hide()
			panel_main:SetPos(0, 0)
			window_main:SetPos(nil, nil, window_main.w, MAIN_PANEL_SIZE)
		end
	end
	wasSpectating = isSpectating
end

function widget:TeamChanged()
	ShowNameLabel()
end
function widget:PlayerChanged()
	ShowNameLabel()
end

local function languageChanged ()
	if global_command_button then
		global_command_button.tooltip = WG.Translate("interface", "toggle_attrition_counter_name") .. "\n\n" .. WG.Translate("interface", "toggle_attrition_counter_desc")
		global_command_button:Invalidate()
	end

	local value_killed = WG.Translate("interface", "attrition_value_killed")
	if icon_pwn then
		icon_pwn.tooltip = value_killed
		icon_pwn:Invalidate()
	end
	if label_pwn then
		label_pwn.tooltip = value_killed
		label_pwn:Invalidate()
	end
	
	local value_lost = WG.Translate("interface", "attrition_value_lost")
	if icon_ded then
		icon_ded.tooltip = value_lost
		icon_ded:Invalidate()
	end
	if label_ded then
		label_ded.tooltip = value_lost
		label_ded:Invalidate()
	end

	for k, v in pairs(strings) do
		strings[k] = WG.Translate("interface", k)
	end

	UpdateCounter()
end

local GetHiddenTeamRulesParam = Spring.Utilities.GetHiddenTeamRulesParam
local spGetTeamRulesParam = Spring.GetTeamRulesParam
UpdateCounter = function ()
	local kills, losses = 0, 0
	local tooltip = strings.attrition_individual_stats .. ":\n"
	for i = 1, #myAllyTeamMembers do
		local team = myAllyTeamMembers[i]
		local teamID = team.teamID

		local pwn = floor(GetHiddenTeamRulesParam(teamID, "stats_history_unit_value_killed_current") or 0)
		local ded = floor(spGetTeamRulesParam(teamID, "stats_history_unit_value_lost_current") or 0)
		kills  = kills  + pwn
		losses = losses + ded

		local name = team.name or "nobody"
		local colour = team.colour
		tooltip = tooltip .. "\n" .. colour .. name .. "\255\255\255\255: " .. pwn .. " / " .. ded
	end

	local caption, colour
	if losses == 0 then
		if kills > 0 then
			caption = strings.attrition_pwn -- flawless victory
			colour = BLUE
		else
			caption = strings.attrition_na
			colour = GRAY
		end
	else
		local rate = kills / losses
		if rate >= 10 then
			caption = strings.attrition_pwn
			colour = CYAN
		else
			caption = tostring(floor(rate * 100))..'%'
			colour = {
				cap(3-rate*2),
				cap(2*rate-1),
				cap((rate-2) / 2),
				1,

				--[[
				  0 -  50% red
				 50 - 100% gradually moves red -> yellow
				100 - 150% gradually moves yellow -> green
				150 - 200% green
				200 - 400% gradually moves green -> cyan
				400 - inf% cyan
				      inf% blue (0 losses flawless play)
				]]
			}
		end
	end

	label_rate.font.color = colour
	label_rate.tooltip = tooltip
	label_rate.x = (window_main.width / 2) - (font:GetTextWidth(caption, 30) / 2)
	label_rate:SetCaption(caption)

	label_pwn:SetCaption(kills)
	label_ded:SetCaption(losses)
end

local function updateTeamName()

	local caption = Spring.GetGameRulesParam("allyteam_long_name_" .. myAllyTeamID)
	if not caption then
		return
	end
	if string.len(caption) > 10 then
		caption = Spring.GetGameRulesParam("allyteam_short_name_" .. myAllyTeamID)
	end

	label_name.x = (window_main.width - font:GetTextWidth(caption, label_name.font.size)) / 2
	local r, g, b = Spring.GetTeamColor(Spring.GetTeamList(myAllyTeamID)[1])
	label_name.font.color[1] = r
	label_name.font.color[2] = g
	label_name.font.color[3] = b
	label_name:SetCaption(caption)
	label_name:Invalidate()
end

local spGetTeamColor = Spring.GetTeamColor
local function updateTeamColors()
	for i = 1, #myAllyTeamMembers do
		local team = myAllyTeamMembers[i]
		local teamID = team.teamID
		local r, g, b = Spring.GetTeamColor(teamID)
		local colourString = '\255'..string.char(floor(r*255))..string.char(floor(g*255))..string.char(floor(b*255))
		team.colour = colourString
	end

	updateTeamName()
end

local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetTeamList = Spring.GetTeamList
function widget:Update()
	local currentAllyTeamID = spGetMyAllyTeamID()
	if currentAllyTeamID == myAllyTeamID then
		return
	end

	myAllyTeamID = currentAllyTeamID
	myAllyTeamMembers = {}
	local teams = spGetTeamList(myAllyTeamID)
	for i = 1, #teams do
		local teamID = teams[i]

		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID)
		local name
		if isAI then
			local _, botNick, _, botType = Spring.GetAIInfo(teamID)
			name = (botType or "AI") .." - " .. (botNick or "")
		else
			name = Spring.GetPlayerInfo(playerID)
		end

		myAllyTeamMembers[i] = {
			teamID = teamID,
			name = name
		}
	end

	updateTeamColors()

	UpdateCounter()
end

function widget:Initialize()

	Chili = WG.Chili
	Window = Chili.Window
	font = Chili.Font:New{} -- cargo culted, apparently "need this to call GetTextWidth without looking up an instance"

	CreateWindow()

	WG.InitializeTranslation (languageChanged, GetInfo().name)
	if WG.LocalColor and WG.LocalColor.RegisterListener then
		WG.LocalColor.RegisterListener(widget:GetInfo().name, updateTeamColors)
	end
end

function widget:Shutdown()
	if window_main then
		window_main:Dispose()
	end
	if WG.LocalColor and WG.LocalColor.UnregisterListener then
		WG.LocalColor.UnregisterListener(widget:GetInfo().name)
	end
end

function widget:GameFrame(n)
	if n % 30 ~= 0 then
		return
	end

	UpdateCounter()
end

local function ToggleWindow(value)
	if not window_main then
		return
	end

	if value == nil then
		value = not window_main.visible
	end

	window_main:SetVisibility(value)
	SetUpdate(MAIN_WINDOW_VISIBILITY, value)
	if value then
		widgetHandler:UpdateCallIn('GameFrame')
	else
		widgetHandler:RemoveCallIn('GameFrame')
	end
end

function CreateWindow()
	local Chili = WG.Chili

	window_main = Chili.Window:New{
		color = {1,1,1,0.8},
		parent = Chili.Screen0,
		dockable = true,
		dockableSavePositionOnly = true,
		name = "AttritionCounter",
		classname = "main_window_small_very_flat",
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		right = 0,
		y = "10%",
		height = NAME_LABEL_SIZE + MAIN_PANEL_SIZE,
		clientWidth  = WINDOW_WIDTH,
		clientHeight = NAME_LABEL_SIZE + MAIN_PANEL_SIZE,
		minHeight = MAIN_PANEL_SIZE,
		maxHeight = MAIN_PANEL_SIZE + NAME_LABEL_SIZE,
		minWidth = WINDOW_WIDTH,
		maxWidth = WINDOW_WIDTH,
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = false,

		OnMouseDown = { function(self) -- space click
			if not select(3, Spring.GetModKeyState()) then
				return false
			end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}

	label_name = Chili.Label:New {
		y = 8,
		parent = window_main,
		fontSize = 20,
	}

	panel_main = Chili.Panel:New {
		backgroundColor = {0,0,0,0},
		parent = window_main,
		y      = NAME_LABEL_SIZE,
		x      = 0,
		w      = WINDOW_WIDTH,
		h      = MAIN_PANEL_SIZE,
		minHeight = MAIN_PANEL_SIZE,
		maxHeight = MAIN_PANEL_SIZE,
		minWidth = WINDOW_WIDTH,
		maxWidth = WINDOW_WIDTH,
	}

	local function ReturnSelf(self, x, y) return self end
	label_rate = Chili.Label:New {
		parent = panel_main,
		x = 0,
		y = 8,
		fontSize = 30,
		textColor = GRAY,
		caption = "",
		HitTest = ReturnSelf,
	}

	local x, y = 35, 42
	local fontsize = 12

	label_pwn = Chili.Label:New{
		parent = panel_main,
		x = x,
		y = y,
		fontSize = fontsize,
		align = 'left',
		caption = '0',
		tooltip = "",
		HitTest = ReturnSelf,
	}
	label_ded = Chili.Label:New{
		parent = panel_main,
		right = x,
		y = y,
		fontSize = fontsize,
		align = 'right',
		caption = '0',
		tooltip = "",
		HitTest = ReturnSelf,
	}

	local w, h = 16, 16
	x, y = 13, 40
	icon_pwn = Chili.Image:New{
		parent = panel_main,
		file = ICON_KILLS_FILE,
		width = w,
		height = h,
		x = x,
		y = y,
		tooltip = "",
		HitTest = ReturnSelf,
	}
	icon_ded = Chili.Image:New{
		parent = panel_main,
		file = ICON_LOST_FILE,
		width = w,
		height = h,
		right = x,
		y = y,
		tooltip = "",
		HitTest = ReturnSelf,
	}


	ToggleWindow(false)
	widgetHandler:RemoveCallIn('Update')
	widgetHandler:RemoveCallIn('GameFrame')

	if WG.GlobalCommandBar then -- GBC should be enabled all the time to catch events like this, and just not be drawn for the shittier presets
		global_command_button = WG.GlobalCommandBar.AddCommand(ICON_LOST_FILE, "", ToggleWindow)
	end

	ShowNameLabel()
	widget:Update()
	updateTeamName()
end
