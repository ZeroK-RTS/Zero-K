--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili EndGame Window",
    desc      = "v0.005 Chili EndGame Window. Creates award control and receives stats control from another widget.",
    author    = "CarRepairer",
    date      = "2013-09-05",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Spring aliases
local spSendCommands   = Spring.SendCommands
local echo             = Spring.Echo
local GetGameSeconds   = Spring.GetGameSeconds
local spGetTeamInfo    = Spring.GetTeamInfo
local spGetGameseconds = Spring.GetGameSeconds
local spGetPlayerInfo  = Spring.GetPlayerInfo
local floor = math.floor

-- Chili classes
local Chili
local Image
local Button
local Checkbox
local Window
local Panel
local ScrollPanel
local StackPanel
local Label
local Line
local screen0
local color2incolor
local incolor2color

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Chili objects
local window_endgame
local awardPanel
local awardSubPanel
local statsPanel
local statsSubPanel
local apmPanel
local apmSubPanel
local awardButton
local statsButton
local exitButton
local apmButton

local global_command_button

-- Flags and timers
local spec
local showingTab
local endgame_caption
local endgame_fontcolor
local gameEnded
local showEndgameWindowTimer
local myPlayerID = Spring.GetMyPlayerID()
local updateFlag = true

-- Constants and parameters
local endgameWindowDelay = 2
local awardPanelHeight = 50
local apmPanelHeight = 30
local B_HEIGHT = 40
local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR

local awardDescs = VFS.Include("LuaRules/Configs/award_names.lua")

local teamNames = {}
local teamColors = {}
local teamApmStatsLabels = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--options

options_path = 'Settings/HUD Panels/Stats Graph'
options_order = {'togglestatsgraph'}
options = {
	togglestatsgraph = { type = 'button',
		name = 'Toggle stats graph',
		desc = 'Shows and hides the statistics graph.',
		action = 'togglestatsgraph',
		dontRegisterAction = true,
	},
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--utilities

local function SetTeamNamesAndColors()
	for _,teamID in ipairs(Spring.GetTeamList()) do
		local _,leader,isDead,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID, false)
		if isAI then
			local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
			teamNames[teamID] = name
		else
			local name = Spring.GetPlayerInfo(leader, false)
			teamNames[teamID] = name
		end
		teamColors[teamID] = Chili.color2incolor(Spring.GetTeamColor(teamID))
	end
end

local function SetButtonSelected(button, isSelected)
	if isSelected then
		button.backgroundColor = SELECT_BUTTON_COLOR
		button.focusColor = SELECT_BUTTON_FOCUS_COLOR
	else
		button.backgroundColor = BUTTON_COLOR
		button.focusColor = BUTTON_FOCUS_COLOR
	end
	button:Invalidate()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--awards

local function MakeAwardPanel(awardType, record)
	local desc = awardDescs[awardType]
	local fontsize = desc:len() > 25 and 12 or 16
	return Panel:New{
		width=230;
		height=awardPanelHeight;
		children = {
			Image:New{ file='LuaRules/Images/awards/trophy_'.. awardType ..'.png'; 		parent=awardPanel; x=0;y=0; width=30; height=40; objectOverrideFont = WG.GetFont(), };
			Label:New{ caption = desc; 		autosize=true, height=L_HEIGHT, parent=awardPanel; x=35; y=0;	textColor={1,1,0,1}; objectOverrideFont = WG.GetFont(fontsize), };
			Label:New{ caption = record, 	autosize=true, height=L_HEIGHT, parent=awardPanel; x=35; y=20, objectOverrideFont = WG.GetFont(), };
		}
	}
end

local function SetupAwardsPanel()
	awardSubPanel:ClearChildren()
	for teamID,awards in pairs(WG.awardList) do
		local playerHasAward
		for awardType, record in pairs(awards) do
			playerHasAward = true
		end
		if playerHasAward then
			Label:New{
				parent=awardSubPanel,
				width=120,
				height=awardPanelHeight,
				caption = teamColors[teamID] .. teamNames[teamID],
				valign='center',
				autosize=false,
				objectOverrideFont = WG.GetFont(),
			}
			for awardType, record in pairs(awards) do
				awardSubPanel:AddChild(MakeAwardPanel(awardType, record) )
			end
			Line:New{ width='100%', parent=awardSubPanel } --spacer to force a "line break"
		end
	end
end

function SetAwardList(awardList)
	-- Registered as a global
	-- Called from awards.lua gadget
	WG.awardList = awardList
	SetupAwardsPanel()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--APM Window

local function SetupAPMPanel()
	Label:New{
		parent=apmSubPanel,
		width=200,
		y=200,
		height=awardPanelHeight,
		caption = "",
		valign='center',
		autosize=false,
		objectOverrideFont = WG.GetFont(),
		}
	Label:New{
		parent=apmSubPanel,
		width=200,
		y=200,
		height=awardPanelHeight,
		caption = "Mouse Speed\n(Pixels/s)",
		valign='center',
		autosize=false,
		objectOverrideFont = WG.GetFont(),
		}
	Label:New{
		parent=apmSubPanel,
		width=200,
		--y = 120,
		height=awardPanelHeight,
		caption = "Click Rate\n(Mouse Clicks/m)",
		valign='center',
		autosize=false,
		objectOverrideFont = WG.GetFont(),
		}
	Label:New{
		parent=apmSubPanel,
		width=200,
		height=awardPanelHeight,
		caption = "Key Press Rate\n(Keys Pressed/m)",
		valign='center',
		autosize=false,
		objectOverrideFont = WG.GetFont(),
		}
	Label:New{
		parent=apmSubPanel,
		width=200,
		height=awardPanelHeight,
		caption = "APM\n(Cmds/m)",
		valign='center',
		autosize=false,
		objectOverrideFont = WG.GetFont(),
		}
	Line:New{ width='100%', parent=apmSubPanel} --spacer to force a "line break"
end

function AddPlayerStatsToPanel(stats)
	if not (stats and apmSubPanel) then
		return
	end
	local teamID = stats.teamID
	if not teamNames[teamID] then
		return
	end
	if not teamApmStatsLabels[teamID] then
		local data = {}
		Label:New{
			parent=apmSubPanel,
			width=200,
			height=apmPanelHeight,
			caption = teamColors[teamID] .. teamNames[teamID],
			valign='center',
			autosize=false,
			objectOverrideFont = WG.GetFont(),
		}
		data.mps = Label:New{
			parent=apmSubPanel,
			width=200,
			height=apmPanelHeight,
			caption = teamColors[teamID] .. stats.MPS,
			valign='center',
			autosize=false,
			objectOverrideFont = WG.GetFont(),
		}
		data.mcm = Label:New{
			parent=apmSubPanel,
			width=200,
			height=apmPanelHeight,
			caption = teamColors[teamID] .. stats.MCM,
			valign='center',
			autosize=false,
			objectOverrideFont = WG.GetFont(),
		}
		data.kpm = Label:New{
			parent=apmSubPanel,
			width=200,
			height=apmPanelHeight,
			caption = teamColors[teamID] .. stats.KPM,
			valign='center',
			autosize=false,
			objectOverrideFont = WG.GetFont(),
		}
		data.apm = Label:New{
			parent=apmSubPanel,
			width=200,
			height=apmPanelHeight,
			caption = teamColors[teamID] .. stats.APM,
			valign='center',
			autosize=false,
			objectOverrideFont = WG.GetFont(),
		}
		Line:New{height = 1, width='100%', parent=apmSubPanel}
		teamApmStatsLabels[teamID] = data
	end
	
	local teamData = teamApmStatsLabels[teamID]
	teamData.mps:SetCaption(teamColors[teamID] .. stats.MPS)
	teamData.mcm:SetCaption(teamColors[teamID] .. stats.MCM)
	teamData.kpm:SetCaption(teamColors[teamID] .. stats.KPM)
	teamData.apm:SetCaption(teamColors[teamID] .. stats.APM)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--show, hide, and toggle

local function ToggleStatsGraph(wantedState)
	local currentState = window_endgame.visible
	if wantedState == nil then
		wantedState = not currentState
	end

	if currentState == wantedState then
		return
	end

	if currentState == true then
		window_endgame:Hide()
		widgetHandler:RemoveCallIn("GameFrame")
	else
		local button = statsSubPanel.buttonPressed or 1
		if statsSubPanel then statsSubPanel.graphButtons[button].OnClick[1](statsSubPanel.graphButtons[button]) end
		window_endgame:Show()
		widgetHandler:UpdateCallIn("GameFrame")
	end
end

local function ShowAwards()
	apmPanel:Hide()
	statsPanel:Hide()
	awardPanel:Show()
	SetButtonSelected(awardButton, true)
	SetButtonSelected(statsButton, false)
	SetButtonSelected(apmButton, false)
	showingTab = 'awards'
end

local function ShowStats()
	if not statsSubPanel then
		echo 'Stats Panel not ready yet.'
		return
	end

	local button = statsSubPanel.buttonPressed or 1
	statsSubPanel.graphButtons[button].OnClick[1](statsSubPanel.graphButtons[button])

	apmPanel:Hide()
	awardPanel:Hide()
	statsPanel:Show()
	SetButtonSelected(statsButton, true)
	SetButtonSelected(awardButton, false)
	SetButtonSelected(apmButton, false)
	showingTab = 'stats'
end

local function ShowAPM()

	statsPanel:Hide()
	awardPanel:Hide()
	apmPanel:Show()
	SetButtonSelected(apmButton, true)
	SetButtonSelected(awardButton, false)
	SetButtonSelected(statsButton, false)
	showingTab = 'apm'
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--setup

local function SetupControls()
	window_endgame = Window:New{
		parent = screen0,
		classname = "main_window",
		name = "GameOver",
		caption = "",
		textColor = {0.5,0.5,0.5,1},
		objectOverrideFont = WG.GetFont(50),
		x = '20%',
		y = '20%',
		width  = '60%',
		height = '60%',
		--autosize   = true;
		draggable = true,
		resizable = true,
		minWidth=500;
		minHeight=400;
	}
	ToggleStatsGraph(false)

	awardPanel = ScrollPanel:New{
		parent = window_endgame,
		x=10;y=50;
		bottom=10;right=10;
		autosize = true,
		noFont = true,
		scrollbarSize = 6,
		horizontalScrollbar = false,
		hitTestAllowEmpty = true;
		tooltip = "",
	}

	statsPanel = ScrollPanel:New{
		parent = window_endgame,
		x = 10; y = 10;
		noFont = true,
		height = -20; width = -20;
		backgroundColor  = {1,1,1,1},
		borderColor = {1,1,1,1},
	}

	apmPanel = ScrollPanel:New{
		parent = window_endgame,
		x=10;y=50;
		bottom=10;right=10;
		autosize = true,
		noFont = true,
		scrollbarSize = 6,
		horizontalScrollbar = false,
		hitTestAllowEmpty = true;
		tooltip = "",
	}

	awardSubPanel = StackPanel:New{
		parent = awardPanel,
		x=0;y=0;
		bottom=10;right=10;
		autosize = true,
		backgroundColor  = {1,1,1,1},
		borderColor = {1,1,1,1},
		padding = {10, 10, 10, 10},
		itemMargin = {0, 0, 0, 0},
		itemPadding = {1, 1, 1, 1},
		tooltip = "",

		resizeItems = false,
		centerItems = false,
		orientation = 'horizontal';
	}

	apmSubPanel = StackPanel:New{
		parent = apmPanel,
		x=0;y=0;
		bottom=10;right=10;
		autosize = true,
		backgroundColor  = {1,1,1,1},
		borderColor = {1,1,1,1},
		padding = {10, 10, 10, 10},
		itemMargin = {0, 0, 0, 0},
		itemPadding = {1, 1, 1, 1},
		tooltip = "",

		resizeItems = false,
		centerItems = false,
		orientation = 'horizontal';
	}
	SetupAPMPanel()

	awardButton = Button:New{
		parent = window_endgame;
		caption="Awards",
		objectOverrideFont = WG.GetFont(),
		x=9, y=7,
		height=B_HEIGHT;
		OnClick = {
			ShowAwards
		};
	}

	BUTTON_COLOR = awardButton.backgroundColor
	BUTTON_FOCUS_COLOR = awardButton.focusColor

	statsButton = Button:New{
		parent = window_endgame;
		caption="Statistics",
		x=86, y=7,
		objectOverrideFont = WG.GetFont(),
		height=B_HEIGHT;
		OnClick = {
			ShowStats
		};
	}
	BUTTON_COLOR = awardButton.backgroundColor
	BUTTON_FOCUS_COLOR = awardButton.focusColor

	apmButton = Button:New{
		parent = window_endgame;
		caption="APM",
		x=86+77, y=7,
		objectOverrideFont = WG.GetFont(),
		height=B_HEIGHT;
		OnClick = {
			ShowAPM
		};
	}
	exitButton = Button:New{
		x = -169, -- This is is a high class nonsense here
		y = 7,
		width = 160,
		height = B_HEIGHT,
		caption = "Exit to Lobby",
		objectOverrideFont = WG.GetFont(18),
		OnClick = {
			function()
				if Spring.GetMenuName and Spring.GetMenuName() ~= "" then
					Spring.Reload("")
				else
					Spring.SendCommands("quit","quitforce")
				end
			 end
		},
		parent   = window_endgame,
	}
end

local function SetEndgameCaption(winners)
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
	if #winners > 1 then
		if spec then
			endgame_caption = "Game over!"
			endgame_fontcolor = {1,1,1,1}
		else
			local i_win = false
			for i = 1, #winners do
				if (winners[i] == Spring.GetMyAllyTeamID()) then
					i_win = true
				end
			end

			if i_win then
				endgame_caption = "Victory!"
				endgame_fontcolor = {0,1,0,1}
			else
				endgame_caption = "Defeat!"
				endgame_fontcolor = {1,0,0,1}
			end
		end
	elseif #winners == 1 then
		local winnerTeamName = Spring.GetGameRulesParam("allyteam_long_name_"  .. winners[1]) or "Team " .. winners[1]
		if string.len(winnerTeamName) > 10 then
			winnerTeamName = Spring.GetGameRulesParam("allyteam_short_name_" .. winners[1]) or "Team " .. winners[1]
		end
		if spec then
			if (winners[1] == gaiaAllyTeamID) then
				endgame_caption = "Draw!"
				endgame_fontcolor = {1,1,1,1}
			else
				endgame_caption = (winnerTeamName .. " wins!")
				endgame_fontcolor = {1,1,1,1}
			end
		elseif (winners[1] == Spring.GetMyAllyTeamID()) then
			endgame_caption = "Victory!"
			endgame_fontcolor = {0,1,0,1}
		elseif (winners[1] == gaiaAllyTeamID) then
			endgame_caption = "Draw!"
			endgame_fontcolor = {1,1,0,1}
		else
			endgame_caption = "Defeat!" -- could somehow add info on who won (eg. for FFA) but as-is it won't fit
			endgame_fontcolor = {1,0,0,1}
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--callins

local function StartEndgameTimer (delay)
	if Spring.GetModOptions().singleplayercampaignbattleid then
		-- SP has its own endgame thing
		return
	end

	gameEnded = true
	showEndgameWindowTimer = endgameWindowDelay
	widgetHandler:UpdateCallIn("Update")
end

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end
	Chili = WG.Chili
	Image = Chili.Image
	Button = Chili.Button
	Checkbox = Chili.Checkbox
	Window = Chili.Window
	Panel = Chili.Panel
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	Label = Chili.Label
	Line = Chili.Line
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color

	SetTeamNamesAndColors()
	spec = Spring.GetSpectatingState()
	Spring.SendCommands("endgraph 0")

	-- Create the window and configure it to display mid-game stats
	-- but don't display it yet; wait until toggled on or game over
	SetupControls()
	statsSubPanel = WG.MakeStatsPanel()
	if statsSubPanel then
		statsPanel:AddChild(statsSubPanel)
	end
	
	--apm stats setup
	WG.AddPlayerStatsToPanel = AddPlayerStatsToPanel

	awardButton:Hide()
	apmButton:Hide()
	statsButton:Hide()
	exitButton:Hide()
	ShowStats()

	widgetHandler:RemoveCallIn("Update")
	widgetHandler:RemoveCallIn("GameFrame")
	if Spring.IsGameOver() then
		window_endgame.caption = "Game aborted"
		StartEndgameTimer(1)
	end

	widgetHandler:RegisterGlobal("SetAwardList", SetAwardList)
	widgetHandler:AddAction("togglestatsgraph", ToggleStatsGraph, nil, 'tp')

	if WG.GlobalCommandBar then
		local toggleKey = WG.crude.GetHotkey("togglestatsgraph") or ""
		if toggleKey ~= "" then
			toggleKey = " (\255\0\255\0"..toggleKey.."\255\255\255\255)"
		end
		global_command_button = WG.GlobalCommandBar.AddCommand("LuaUI/Images/graphs_icon.png", "Toggle graphs" .. toggleKey, ToggleStatsGraph)
	end
end

function widget:GameOver(winners)
	SetEndgameCaption(winners)
	StartEndgameTimer(endgameWindowDelay)
end

function widget:Update(dt)
	showEndgameWindowTimer = showEndgameWindowTimer - dt
	if showEndgameWindowTimer > 0 then
		return
	end
	local screenWidth, screenHeight = Spring.GetViewGeometry()
	window_endgame:SetPos(screenWidth*0.2,screenHeight*0.2,screenWidth*0.6,screenHeight*0.6)
	statsPanel:SetPosRelative(10, 50, -(10+10), -(50+10))
	statsSubPanel.graphButtons[1].OnClick[1](statsSubPanel.graphButtons[1])
	awardButton:Show()
	statsButton:Show()
	apmButton:Show()
	exitButton:Show()

	window_endgame.tooltip = ""
	window_endgame.caption = endgame_caption
	window_endgame.font.color = endgame_fontcolor

	if WG.awardList then
		ShowAwards()
	else
		ShowStats()
	end
	ToggleStatsGraph(true)
	widgetHandler:RemoveCallIn("Update")
end

function widget:GameFrame(f)
	-- Redraw the currently-displayed stats graph every fifteen seconds
	if f%450 == 1 and showingTab == 'stats' then
		local button = statsSubPanel.buttonPressed or 1
		statsSubPanel.graphButtons[button].OnClick[1](statsSubPanel.graphButtons[button])
	end
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("SetAwardList")
	widgetHandler:RemoveAction("togglestatsgraph")
end
