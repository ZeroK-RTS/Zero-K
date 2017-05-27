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
local spSendCommands	= Spring.SendCommands
local echo 		= Spring.Echo
local GetGameSeconds	= Spring.GetGameSeconds

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
local awardButton = false
local statsButton = false
local exitButton = false
local toggleButton = false

-- Flags and timers
local spec
local showingTab
local showingEndgameWindow
local gameEnded
local showEndgameWindowTimer

-- Constants and parameters
local endgameWindowDelay = 2
local awardPanelHeight = 50
local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR

local awardDescs = VFS.Include("LuaRules/Configs/award_names.lua")

local teamNames = {}
local teamColors = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--options

options_path = 'Settings/HUD Panels/Stats Graph'
options_order = {'togglestatsgraph', 'toggleendgamewindow'}
options = { 
	togglestatsgraph = { type = 'button',
		name = 'Toggle stats graph',
		desc = 'Shows and hides the statistics graph.',
		action = 'togglestatsgraph',
		dontRegisterAction = true,
	},
	toggleendgamewindow = {
		name = 'Toggle endgame window',
		type = 'bool',
		value = false,
		desc = "Allows the endgame window to be toggled on and off",
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--utilities

local function SetTeamNamesAndColors()
	for _,teamID in ipairs(Spring.GetTeamList()) do
		local _,leader,isDead,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID)
		if isAI then
			local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
			teamNames[teamID] = name
		else
			local name = Spring.GetPlayerInfo(leader)
			teamNames[teamID] = name
		end
	local r,g,b = Spring.GetTeamColor(teamID)
	teamColors[teamID] = {r,g,b,1}
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
			Image:New{ file='LuaRules/Images/awards/trophy_'.. awardType ..'.png'; 		parent=awardPanel; x=0;y=0; width=30; height=40; };
			Label:New{ caption = desc; 		autosize=true, height=L_HEIGHT, parent=awardPanel; x=35; y=0;	textColor={1,1,0,1}; fontsize=fontsize; };
			Label:New{ caption = record, 	autosize=true, height=L_HEIGHT, parent=awardPanel; x=35; y=20 };
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
				caption = teamNames[teamID],
				width=120; fontShadow = true; valign='center';
				autosize=false, height=awardPanelHeight; textColor=teamColors[teamID];
				parent=awardSubPanel
			}
		
			for awardType, record in pairs(awards) do
				awardSubPanel:AddChild( MakeAwardPanel(awardType, record) )
			end
			
			Label:New{
				caption = string.rep('-', 300), textColor = {0.4,0.4,0.4,0.4};
				autosize=false; width='100%'; height=5;
				parent=awardSubPanel
			} --spacer label to force a "line break"
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
--show, hide, and toggle

local function PrepEndgameWindow()
	-- Determines whether or not to show the toggle button
	-- Then updates the window to position the appropriate buttons in the appropriate places
	-- Also updates the hotkey label on the toggle button
	--	There's no hook in epicmenu for when the hotkey is changed
	--	So instead we'll do it here, every time the window is displayed

	local toggleendgamewindow = options.toggleendgamewindow.value
	local toggleKey = WG.crude.GetHotkey("togglestatsgraph") or ""
	local showToggleButton = (toggleKey ~= "") and (not gameEnded or toggleendgamewindow)

--[[
	-- Put the toggle button leftmost, move the awards and stats buttons right
	local abx = showToggleButton and 159 or 9
	local sbx = showToggleButton and 236 or 86
	awardButton:SetPos(abx)
	statsButton:SetPos(sbx)
--]]	
---[[
	-- Put the toggle button rightmost, move the exit button left
	local ebr = showToggleButton and 259 or 109
	local we_w = window_endgame.width
	exitButton:SetPos(we_w - ebr)
--]]

	if showToggleButton then
		toggleButton.caption="Toggle ("..toggleKey..")"
		toggleButton:Invalidate()
		toggleButton:Show()
	else
		toggleButton:Hide()
	end
end

local function ToggleStatsGraph()
	local toggleendgamewindow = options.toggleendgamewindow.value
	local togglewindow = (not gameEnded or toggleendgamewindow)
	if not togglewindow then return end

	if showingEndgameWindow then
		-- toggle off
		window_endgame:Hide()
	else
		-- toggle on
		PrepEndgameWindow()
		window_endgame:Show()
	end
	showingEndgameWindow = not showingEndgameWindow
end

local function ShowAwards()
	statsPanel:Hide()
	awardPanel:Show()
	SetButtonSelected(awardButton, true)
	SetButtonSelected(statsButton, false)
	showingTab = 'awards'
end

local function ShowStats()
	if not statsSubPanel then
		echo 'Stats Panel not ready yet.'
		return
	end
	
	local button = WG.statsPanelEngineButtonClicked or 1
	statsSubPanel.engineButtons[button].OnClick[1](statsSubPanel.engineButtons[button])

	awardPanel:Hide()
	statsPanel:Show()
	SetButtonSelected(statsButton, true)
	SetButtonSelected(awardButton, false)
	showingTab = 'stats'
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--setup

local function SetupControls()
	window_endgame = Window:New{  
		name = "GameOver",
		caption = "Game in Progress",
		textColor = {0.5,0.5,0.5,1}, 
		fontSize = 50,
		x = '20%',
		y = '20%',
		width  = '60%',
		height = '60%',
		classname = "main_window",
		--autosize   = true;
		parent = screen0,
		draggable = true,
		resizable = true,
		minWidth=500;
		minHeight=400;
	}
	window_endgame:Hide()

	awardPanel = ScrollPanel:New{
		parent = window_endgame,
		x=10;y=50;
		bottom=10;right=10;
		autosize = true,
		scrollbarSize = 6,
		horizontalScrollbar = false,
		hitTestAllowEmpty = true;
		tooltip = "",
	}

	statsPanel = ScrollPanel:New{
		parent = window_endgame,
		x=10;y=50;
		bottom=10;right=10;
		backgroundColor  = {1,1,1,1},
		borderColor = {1,1,1,1},
	}
	
	awardSubPanel = StackPanel:New{
		parent = awardPanel,
		x=0;y=0;
		bottom=10;right=10;
		backgroundColor  = {1,1,1,1},
		borderColor = {1,1,1,1},
		padding = {10, 10, 10, 10},
		itemMargin = {1, 1, 1, 1},
		tooltip = "",
		autosize = true,
		
		resizeItems = false,
		centerItems = false,
		orientation = 'horizontal';
	}
	
	local B_HEIGHT = 40
	
	toggleButton = Button:New{
--		y=7, x=9,	-- leftmost
		y=7; right=9;	-- rightmost
		width=145;
		height=B_HEIGHT;
		parent = window_endgame;
		OnClick = {
			ToggleStatsGraph
		};
	}

	awardButton = Button:New{
		x=9, y=7,
		height=B_HEIGHT;
		caption="Awards",
		OnClick = {
			ShowAwards
		};
		parent = window_endgame;
	}

	BUTTON_COLOR = awardButton.backgroundColor
	BUTTON_FOCUS_COLOR = awardButton.focusColor
	SetButtonSelected(awardButton, true)
	
	statsButton = Button:New{
		x=86, y=7,
		height=B_HEIGHT;
		caption="Statistics",
		OnClick = {
			ShowStats
		};
		parent = window_endgame;
	}
	
	exitButton = Button:New{
		y=7;
		width=80;
		right=9;
		height=B_HEIGHT;
		caption="Exit",
		OnClick = {
			function() 
				if Spring.GetMenuName and Spring.GetMenuName() ~= "" then
					Spring.Reload("")
				else
					Spring.SendCommands("quit","quitforce")
				end
			 end
		};
		parent = window_endgame;
	}
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--callins

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
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	SetTeamNamesAndColors()
	spec = Spring.GetSpectatingState()
	Spring.SendCommands("endgraph 0")
	
	-- Create the window and configure it to display mid-game stats
	-- but don't display it yet; wait until toggled on or game over
	SetupControls()
	WG.MakeStatsPanel()
	statsSubPanel = WG.statsPanel
	statsPanel:AddChild(statsSubPanel)
	awardButton:Hide()
	statsButton:Hide()
	exitButton:Hide()
	ShowStats()
	
	if Spring.IsGameOver() then
		gameEnded = true
		window_endgame.caption = "Game aborted"
		showEndgameWindowTimer = 1
	end
	
	widgetHandler:RegisterGlobal("SetAwardList", SetAwardList)
	widgetHandler:AddAction("togglestatsgraph", ToggleStatsGraph, nil, 'tp')
end

function widget:GameOver (winners)
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
	if #winners > 1 then
		if spec then
			window_endgame.caption = "Game over!"
			window_endgame.font.color = {1,1,1,1}
		else
			local i_win = false
			for i = 1, #winners do
				if (winners[i] == Spring.GetMyAllyTeamID()) then
					i_win = true
				end
			end

			if i_win then
				window_endgame.caption = "Victory!"
				window_endgame.font.color = {0,1,0,1}
			else
				window_endgame.caption = "Defeat!"
				window_endgame.font.color = {1,0,0,1}
			end
		end
	elseif #winners == 1 then
		local winnerTeamName = Spring.GetGameRulesParam("allyteam_long_name_"  .. winners[1]) or "Team " .. winners[1]
		if string.len(winnerTeamName) > 10 then
			winnerTeamName = Spring.GetGameRulesParam("allyteam_short_name_" .. winners[1]) or "Team " .. winners[1]
		end
		if spec then
			if (winners[1] == gaiaAllyTeamID) then
				window_endgame.caption = "Draw!"
				window_endgame.font.color = {1,1,1,1}
			else
				window_endgame.caption = (winnerTeamName .. " wins!")
				window_endgame.font.color = {1,1,1,1}
			end
		elseif (winners[1] == Spring.GetMyAllyTeamID()) then
			window_endgame.caption = "Victory!"
			window_endgame.font.color = {0,1,0,1}
		elseif (winners[1] == gaiaAllyTeamID) then
			window_endgame.caption = "Draw!"
			window_endgame.font.color = {1,1,0,1}
		else
			window_endgame.caption = "Defeat!" -- could somehow add info on who won (eg. for FFA) but as-is it won't fit
			window_endgame.font.color = {1,0,0,1}
		end
	end
	window_endgame.tooltip = ""
	window_endgame:Invalidate()
	showEndgameWindowTimer = endgameWindowDelay
	gameEnded = true
end

function widget:Update(dt)
	-- Redraw the currently-displayed stats graph every fifteen seconds
	local gameSeconds = GetGameSeconds()
	if (gameSeconds % 15) == 1 then
		if showingTab == 'stats' then
			local button = WG.statsPanelEngineButtonClicked or 1
			statsSubPanel.engineButtons[button].OnClick[1](statsSubPanel.engineButtons[button])
		end
	end

	-- If the post-endgame countdown timer has not yet started, don't do anything else
	-- If the post-endgame countdown has started but not elapsed, decrement it and do nothing else
	if not showEndgameWindowTimer then
		return
	end
	showEndgameWindowTimer = showEndgameWindowTimer - dt
	if showEndgameWindowTimer > 0 then
		return
	end

	-- Otherwise, it's time to show the endgame screen
	local screenWidth, screenHeight = Spring.GetWindowGeometry()
	window_endgame:SetPos(screenWidth*0.2,screenHeight*0.2,screenWidth*0.6,screenHeight*0.6)
	statsSubPanel.engineButtons[1].OnClick[1](statsSubPanel.engineButtons[1])
	awardButton:Show()
	statsButton:Show()
	exitButton:Show()
	PrepEndgameWindow()

	if WG.awardList then
		ShowAwards()
	else
		ShowStats()
	end
	window_endgame:Show()

	showEndgameWindowTimer = nil
	showingEndgameWindow = true
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("SetAwardList")
	widgetHandler:RemoveAction("togglestatsgraph")
end

