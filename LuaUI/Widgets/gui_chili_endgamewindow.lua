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
local spSendCommands			= Spring.SendCommands

local echo = Spring.Echo

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

local window_endgame
local awardPanel
local awardSubPanel
local statsPanel
local statsSubPanel
local addedStatsSubPanel = false
local awardButton = false
local statsButton = false
local showingTab = 'awards'
local teamNames = {}
local teamColors = {}

local awardPanelHeight = 50

local white_table 	= {1,1,1, 1}
local magenta_table = {0.8, 0, 0, 1}

local awardDescs =
{
	pwn     = 'Complete Annihilation Award',
	navy    = 'Fleet Admiral',
	air     = 'Airforce General',
	nux     = 'Apocalyptic Achievement Award',
	friend  = 'Friendly Fire Award',
	shell   = 'Turtle Shell Award',
	fire    = 'Master Grill-Chef',
	emp     = 'EMP Wizard',
	slow    = 'Traffic Cop',
	t3      = 'Experimental Engineer',
	cap     = 'Capture Award',
	share   = 'Share Bear',
	terra   = 'Legendary Landscaper',
	reclaim = 'Spoils of War',
	rezz    = 'Necromancy Award',
	vet     = 'Decorated Veteran',
	ouch    = 'Big Purple Heart',
	kam     = 'Kamikaze Award',
	comm    = 'Master and Commander',
	mex     = 'Mineral Prospector',
	mexkill = 'Loot & Pillage',
	rage    = 'Rage Inducer',
	head    = 'Head Hunter',
	dragon  = 'Dragon Slayer',
	heart   = 'Queen Heart Breaker',
	sweeper = 'Land Sweeper',
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--functions

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

-- returns true if tab is already showing, shows tab
local function ShowTab(tabName)
	if showingTab == tabName then
		return true
	end
	showingTab = tabName
	return false
end


local function AddStatsSubPanel()
	if addedStatsSubPanel then
		return
	end
	addedStatsSubPanel = true
	statsPanel:AddChild(statsSubPanel)
end

local function SetButtonColor(button, color)
	button.backgroundColor = color
	button:Invalidate()
end

local function ShowAwards()
	if ShowTab('awards') then return end
	
	window_endgame:RemoveChild(statsPanel)
	window_endgame:AddChild(awardPanel)
	
	SetButtonColor( awardButton, magenta_table )
	SetButtonColor( statsButton, white_table )
end
local function ShowStats()
	statsSubPanel = WG.statsPanel
	if not statsSubPanel then
		echo 'Stats Panel not ready yet.'
		return
	end
	
	if ShowTab('stats') then return end
	
	AddStatsSubPanel()
	
	window_endgame:RemoveChild(awardPanel)
	window_endgame:AddChild(statsPanel)
	
	SetButtonColor( statsButton, magenta_table )
	SetButtonColor( awardButton, white_table )
end



local function SetupAwardsPanel()
	awardSubPanel:ClearChildren()
	for teamID,awards in pairs(WG.awardList) do
		--echo(k, v)
		
		local playerHasAward
		for awardType, record in pairs(awards) do
			playerHasAward = true
		end
		if playerHasAward then
			Label:New{ caption = teamNames[teamID], width=120; fontShadow = true; valign='center'; autosize=false, height=awardPanelHeight; textColor=teamColors[teamID]; 	parent=awardSubPanel }
		
			for awardType, record in pairs(awards) do
				
				awardSubPanel:AddChild( MakeAwardPanel(awardType, record) )
			end
			
			Label:New{ caption = string.rep('-', 300), textColor = {0.4,0.4,0.4,0.4}; autosize=false; width='100%'; height=5; parent=awardSubPanel } --spacer label to force a "line break"
		end
	end
end


function SetAwardList(awardList)
	WG.awardList = awardList
	SetupAwardsPanel()
	ShowAwards()
end

local function ShowEndGameWindow()
	local awardList = WG.awardList
	
	if WG.awardList then
		ShowAwards()
	else
		ShowStats()
	end
	
	screen0:AddChild(window_endgame)
	
end

local function SetupControls()
	window_endgame = Window:New{  
		name = "GameOver",
		caption = "Game Over",
		color = {1,1,1,1},
		x = '20%',
		y = '20%',
		width  = '60%',
		height = '60%',
		padding = {8, 8, 8, 8};
		--autosize   = true;
		--parent = screen0,
		draggable = true,
		resizable = true,
		minWidth=500;
		minHeight=400;
	}
	
	
	
	awardPanel = ScrollPanel:New{
		parent = window_endgame,
		x=10;y=40;
		bottom=10;right=10;
		backgroundColor  = {1,1,1,1},
		borderColor = {1,1,1,1},
		autosize = true,
		scrollbarSize = 6,
		horizontalScrollbar = false,
		hitTestAllowEmpty = true;
	}
	statsPanel = StackPanel:New{
		x=10;y=40;
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
		autosize = true,
		
		resizeItems = false,
		centerItems = false,
		orientation = 'horizontal';
	}
	
	local B_HEIGHT = 40
	awardButton = Button:New{
		x=0, y=0,
		height=B_HEIGHT;
		caption="Awards",
		backgroundColor = magenta_table;
		OnMouseUp = {
			ShowAwards
		};
		parent = window_endgame;
	}
	statsButton = Button:New{
		x=80, y=0,
		height=B_HEIGHT;
		caption="Statistics",
		OnMouseUp = {
			ShowStats
		};
		parent = window_endgame;
	}
	
	Button:New{
		y=0;
		width='80';
		right=0;
		height=B_HEIGHT;
		caption="Exit",
		OnMouseUp = {
			function() Spring.SendCommands("quit","quitforce") end
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
	
	SetupControls()

	Spring.SendCommands("endgraph 0")
	
	widgetHandler:RegisterGlobal("SetAwardList", SetAwardList)
end

function widget:GameOver()
	SetTeamNamesAndColors()
	ShowEndGameWindow()
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("SetAwardList")
end


