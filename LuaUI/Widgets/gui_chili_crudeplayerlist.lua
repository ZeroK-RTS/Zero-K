--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List2",
    desc      = "v1.04 Chili Crude Player List.",
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
local Checkbox
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
local x_share 	= x_name + 140 
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

local show_spec = true
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function SetupPlayerNames() end

options_path = 'Settings/Interface/PlayerList'
options = {
	text_height = {
		name = 'Font Size',
		type = 'number',
		value = 14,
		min=8,max=18,step=1,
		OnChange = function() SetupPlayerNames() end,
	},
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			window_cpl.color = {1,1,1,self.value}
			window_cpl:Invalidate() 
		end,
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

local function PingTimeOut(pingTime)
	if pingTime < 1 then
		return (math.floor(pingTime*1000) ..'ms')
	elseif pingTime > 100 then
		return '>100s'
	end
	--return (math.floor(pingTime*100))/100
	return ('' .. (math.floor(pingTime*100)/100)):sub(1,4) .. 's' --needed due to rounding errors.
end

local function AddAllyteamPlayers(row, allyTeam,players)
	if not players then
		return row
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
	
	table.sort(players, function(a,b)
			return a.name:lower() < b.name:lower()
		end)
	
	--for _, playerID in ipairs( players ) do
	for _, pdata in ipairs( players ) do
		local name_out = pdata.name
		local teamID = pdata.team
		local playerID = pdata.player
		
		local name,active,spectator,_,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
	
		pingTime = pingTime or 0
		cpuUsage = cpuUsage or 0
	
		local min_pingTime = math.min(pingTime, 1)
		local cpuCol = pingCpuColors[ math.ceil( cpuUsage * 5 ) ] 
		local pingCol = pingCpuColors[ math.ceil( min_pingTime * 5 ) ]
		local pingTime_readable = PingTimeOut(pingTime)
	
		window_cpl:AddChild(
			Label:New{
				x=x_name,
				y=options.text_height.value * row,
				width=150,
				autosize=false,
				--caption = (spectator and '' or ((teamID+1).. ') ') )  .. name, --do not remove, will add later as option
				caption = name_out,
				textColor = teamID and {Spring.GetTeamColor(teamID)} or {1,1,1,1},
				fontsize = options.text_height.value,
				fontShadow = true,
			}
		)
		if active and allyTeam == localAlliance and teamID ~= localTeam then
			window_cpl:AddChild(
				Button:New{
					x=x_share,
					y=options.text_height.value * (row+0.5),
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
				caption = pingTime_readable ,
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
	window_cpl:AddChild( Label:New{ x=x_name, 	caption = 'Name', 	fontShadow = true,  fontsize = options.text_height.value,} )
	window_cpl:AddChild( Label:New{ x=x_cpu, 	caption = 'CPU', 	fontShadow = true,  fontsize = options.text_height.value,} )
	window_cpl:AddChild( Label:New{ x=x_ping, 	caption = 'Ping', 	fontShadow = true,  fontsize = options.text_height.value,} )
	
	local playerroster	= Spring.GetPlayerList()
	local teams 		= Spring.GetTeamList()
	
	myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	
	local allyTeams = {}
	
	local specNames = {}
	
	--Specs
	for i,v in ipairs(playerroster) do
		local playerID = playerroster[i]
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
		--if spectator then
		if spectator and active then
			if not allyTeams.S then
				allyTeams.S = {}
			end
			table.insert( allyTeams.S, {name=name,team=nil,player=playerID} )
			specNames[name]=true
		end
	end
	
	for i,teamID in ipairs(teams) do
		if teamID ~= Spring.GetGaiaTeamID() then
			local _,playerID,_,isAI,_,allyTeamID_out = Spring.GetTeamInfo(teamID)
			local name_out = ''
			if isAI then
				local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
				name_out = '<'.. name ..'> '.. shortName
			else
				--local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
				local name,active,spectator,_,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
			
				
				if allyTeamID then
					allyTeamID_out = allyTeamID
				end
				
				name_out = name or ''
				if
					name_out == ''
					or #(Spring.GetPlayerList(teamID,true)) == 0
					or specNames[name]
				then
				
					if Spring.GetGameSeconds() < 0.1 then
						name_out = "<Waiting> " ..(name or '')
					elseif Spring.GetTeamUnitCount(teamID) > 0  then
						name_out = "<Aband. units> " ..(name or '')
					else
						name_out = "<Dead> " ..(name or '')
					end
				end
			end
			
			if allyTeamID_out then
				if not allyTeams[allyTeamID_out] then
					allyTeams[allyTeamID_out] = {}
				end
				
				table.insert( allyTeams[allyTeamID_out], {name=name_out,team=teamID,player=playerID} )
			end
			
		end --if teamID ~= Spring.GetGaiaTeamID() 
	end --for each team
	
	
	local allyTeams_i = {}
	for allyTeam,players in pairs(allyTeams) do
		allyTeams_i[#allyTeams_i+1] = {allyTeam,players}
	end
	
	table.sort(allyTeams_i,
		function(a,b)
			local av = (type(a[1]) == 'string') and 999 or a[1]
			local bv = (type(b[1]) == 'string') and 999 or b[1]
			return av < bv
		end)
	
	local row = 1
	--for allyTeam,players in pairs(allyTeams) do
	for _,adata in ipairs(allyTeams_i) do
		local allyTeam,players = adata[1], adata[2]
		if allyTeam ~= 'S' then
			row = AddAllyteamPlayers(row, allyTeam,players)
		end
	end
	if show_spec then
		row = AddAllyteamPlayers(row,'S',allyTeams.S)
	end
	
	window_cpl:AddChild( Checkbox:New{
		x=5, y=options.text_height.value * (row + 0.5),
		height=options.text_height.value * 1.5, width=140,
		caption = 'Show Spectators',
		checked = show_spec,
		OnChange = { function(self) show_spec = not self.checked; SetupPlayerNames(); end },
	} )
	
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
	Checkbox = Chili.Checkbox
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
		color = {1,1,1,options.backgroundOpacity.value},
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
