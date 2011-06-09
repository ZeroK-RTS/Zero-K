--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List2",
    desc      = "v1.00000000 Chili Crude Player List.",
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
local Image
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

local green = '\255\0\255\0'
local red = '\255\0\255\0'

local x_name 	= 20
local x_share 	= x_name + 120 
local x_cpu 	= x_share + 20
local x_ping 	= x_cpu + 40

pingCpuColors = {
	{0, 1, 0, 1},
	{0.7, 1, 0, 1},
	{1, 1, 0, 1},
	{1, 0.6, 0, 1},
	{1, 0, 0, 1}
}

local sharePic        = ":n:"..LUAUI_DIRNAME.."Images/advplayerslist/units.png"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function SetupPlayerNames() end

options_path = 'Settings/Interface'
options = {
	text_height = {
		name = 'Playerlist Text Size',
		type = 'number',
		value = 14,
		min=8,max=18,step=1,
		OnChange = function() SetupPlayerNames() end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ShareUnits(playername, team)
	local selcnt = Spring.GetSelectedUnitsCount()
	if selcnt > 0 then
		Spring.SendCommands("say a: I gave "..selcnt.." units to "..playername..".")
		-- no point spam, thx
		--[[local su = Spring.GetSelectedUnits()
		for _,uid in ipairs(su) do
		local ux,uy,uz = Spring.GetUnitPosition(uid)
		Spring.MarkerAddPoint(ux,uy,uz)
		end]]
		Spring.ShareResources(team, "units")     
	else
		echo 'Player List: No units selected to share.'
	end
end

local function AddAllyteamPlayers(row, allyTeam,players)
	if not players then
		return
	end
	local row = row
	local localAlliance = Spring.GetLocalAllyTeamID()
	local localTeam = Spring.GetLocalTeamID()
	local aCol = {1,0,0,1}
	if allyTeam == 'S' then
		aCol = {1,1,1,1}
	elseif allyTeam == localAlliance then
		aCol = {0,1,1,1} 
	end
	window_cpl:AddChild(
		Label:New{
			y=options.text_height.value * row,
			caption = '[' .. (type(allyTeam) == 'number' and (allyTeam+1) or allyTeam) .. ']',
			textColor = aCol,
			fontsize = options.text_height.value,
			fontShadow = true,
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
				y=options.text_height.value * row,
				width=120,
				autosize=false,
				caption = (spectator and '' or ((teamID+1).. ') ') )  .. name,
				textColor = spectator and {1,1,1,1} or {Spring.GetTeamColor(teamID)},
				fontsize = options.text_height.value,
				fontShadow = true,
			}
		)
		if allyTeam == localAlliance and teamID ~= localTeam then
			window_cpl:AddChild(
				Button:New{
					x=x_share,
					y=options.text_height.value * row,
					height = options.text_height.value,
					width = options.text_height.value,
					tooltip = 'Double click to share selected units to ' .. name,
					caption = '',
					padding ={0,0,0,0},
					OnDblClick = { function(self) ShareUnits(name, teamID) end, },
					children = 	{
						Image:New{
							x=0,y=0,
							height='100%',
							width='100%',
							file = sharePic,
						},
					},
				}
			)
		end
		window_cpl:AddChild(
			Label:New{
				x=x_cpu,
				y=options.text_height.value * row,
				caption = math.round(cpuUsage*100) .. '%',
				textColor = cpuCol,
				fontsize = options.text_height.value,
				fontShadow = true,
			}
		)
		window_cpl:AddChild(
			Label:New{
				x=x_ping,
				y=options.text_height.value * row,
				caption = math.round(pingTime*1000) .. 'ms',
				textColor = pingCol,
				fontsize = options.text_height.value,
				fontShadow = true,
			}
		)
		
		row = row + 1
	end
	return row
end

SetupPlayerNames = function()
	window_cpl:ClearChildren()
	
	window_cpl:AddChild( Label:New{ x=0, 		caption = 'A', 		fontShadow = true, 	fontsize = options.text_height.value, } )
	window_cpl:AddChild( Label:New{ x=x_name, 	caption = 'ID / Name', 	fontShadow = true,  fontsize = options.text_height.value,} )
	window_cpl:AddChild( Label:New{ x=x_cpu, 	caption = 'CPU', 	fontShadow = true,  fontsize = options.text_height.value,} )
	window_cpl:AddChild( Label:New{ x=x_ping, 	caption = 'Ping', 	fontShadow = true,  fontsize = options.text_height.value,} )
	
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
	Image = Chili.Image
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
		x = 100,  
		bottom = 0,
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
