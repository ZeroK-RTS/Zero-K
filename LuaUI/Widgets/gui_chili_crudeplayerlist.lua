--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List",
    desc      = "v1.00000 Chili Crude Player List.",
    author    = "CarRepairer",
    date      = "2011-01-06",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = true,
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spSendCommands			= Spring.SendCommands

local echo = Spring.Echo

local Chili
local Button
local Window
local ScrollPanel
local StackPanel
local Label
local screen0
local color2incolor
local incolor2color
local myName -- my console name

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window_cpl

local colorNames = {}
local colors = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function SetupPlayerNames()
	window_cpl:ClearChildren()
	
	local playerroster = Spring.GetPlayerList()
	
	myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	local lheight = 14
	local allyTeams = {}
	-- [[
	for i,v in ipairs(playerroster) do
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerroster[i])
		if not allyTeams[spectator and 's' or allyTeamID] then
			allyTeams[spectator and 's' or allyTeamID] = {}
		end
		table.insert( allyTeams[spectator and 's' or allyTeamID], playerroster[i] )
	end
	-- [[
	local row = 0
	for allyTeam,players in pairs(allyTeams) do
		window_cpl:AddChild(
			Label:New{
				y=lheight*row,
				caption = '[' .. allyTeam .. ']',
				textColor = {1,1,1,1},
			}
		)
		row = row + 1
		for _, playerID in ipairs( players ) do
			local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
		
			window_cpl:AddChild(
				Label:New{
					y=lheight*row,
					caption = (spectator and '-' or teamID) .. ') ' .. name,
					textColor = spectator and {1,1,1,1} or {Spring.GetTeamColor(teamID)},
				}
			)
			row = row + 1
		end
	end
	--]]
	
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



function widget:Shutdown()
end

local timer = 0
function widget:Update(s)
	timer = timer + s
	if timer > 5 then
		timer = 0
		SetupPlayerNames()
	end
end

-----------------------------------------------------------------------

function widget:Initialize()
	if (not WG.Chili) then
		widgetHandler:RemoveWidget()
		return
	end

	Chili = WG.Chili
	Button = Chili.Button
	Window = Chili.Window
	ScrollPanel = Chili.ScrollPanel
	StackPanel = Chili.StackPanel
	Label = Chili.Label
	screen0 = Chili.Screen0
	color2incolor = Chili.color2incolor
	incolor2color = Chili.incolor2color
	
	
	window_cpl = Window:New{  
		--margin = {2,2,2,2},
		--padding = {2,2,2,2},
		dockable = true,
		name = "crudeplayerlist",
		x = 300,  
		y = 0,
		width  = 350,
		height = 250,
		autosize   = true;
		parent = screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimumSize = {MIN_WIDTH, MIN_HEIGHT},
		children = {
		},
	}
	
	SetupPlayerNames()

end
