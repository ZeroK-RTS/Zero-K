--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List",
    desc      = "v1.0000000 Chili Crude Player List.",
    author    = "CarRepairer",
    date      = "2011-01-06",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = false,
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
local lheight = 14

local green = '\255\0\255\0'
local red = '\255\0\255\0'

local x_name = 20
local x_cpu = 130
local x_ping = 170

pingCpuColors = {
	{0, 1, 0, 1},
	{0.7, 1, 0, 1},
	{1, 1, 0, 1},
	{1, 0.6, 0, 1},
	{1, 0, 0, 1}
}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local function AddAllyteamPlayers(row, allyTeam,players)
	local row = row
	window_cpl:AddChild(
		Label:New{
			y=lheight*row,
			caption = '[' .. (type(allyTeam) == 'number' and (allyTeam+1) or allyTeam) .. ']',
			textColor = {1,1,1,1},
		}
	)
	--row = row + 1
	for _, playerID in ipairs( players ) do
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
	
		
		
		local min_pingTime = math.min(pingTime, 1)
		
		local cpuCol = pingCpuColors[ math.ceil( cpuUsage * 5 ) ] 
		
		
		local pingCol = pingCpuColors[ math.ceil( min_pingTime * 5 ) ] 
	
		window_cpl:AddChild(
			Label:New{
				x=x_name,
				y=lheight*row,
				caption = (spectator and '' or ((teamID+1).. ') ') )  .. name,
				textColor = spectator and {1,1,1,1} or {Spring.GetTeamColor(teamID)},
			}
		)
		window_cpl:AddChild(
			Label:New{
				x=x_cpu,
				y=lheight*row,
				caption = math.round(cpuUsage*100) .. '%',
				textColor = cpuCol,
			}
		)
		window_cpl:AddChild(
			Label:New{
				x=x_ping,
				y=lheight*row,
				caption = math.round(pingTime*1000) .. 'ms',
				textColor = pingCol,
			}
		)
		
		row = row + 1
	end
	return row
end

local function SetupPlayerNames()
	window_cpl:ClearChildren()
	
	window_cpl:AddChild( Label:New{ x=0, caption = 'A', } )
	window_cpl:AddChild( Label:New{ x=x_name, caption = 'Name', } )
	window_cpl:AddChild( Label:New{ x=x_cpu, caption = 'CPU', } )
	window_cpl:AddChild( Label:New{ x=x_ping, caption = 'Ping', } )
	
	local playerroster = Spring.GetPlayerList()
	
	myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	
	local allyTeams = {}
	
	for i,v in ipairs(playerroster) do
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerroster[i])
		if not allyTeams[spectator and 'S' or allyTeamID] then
			allyTeams[spectator and 'S' or allyTeamID] = {}
		end
		table.insert( allyTeams[spectator and 'S' or allyTeamID], playerroster[i] )
	end
	
	
	local row = 1
	for allyTeam,players in pairs(allyTeams) do
		if allyTeam ~= 'S' then
			row = AddAllyteamPlayers(row, allyTeam,players)
		end
		
	end
	row = AddAllyteamPlayers(row,'S',allyTeams.S)
	
	
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
		tweakResizable = false,
		minimumSize = {MIN_WIDTH, MIN_HEIGHT},
		children = {
		},
	}
	
	SetupPlayerNames()

end
