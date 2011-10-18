--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List v1.2",
    desc      = "v1.052 Chili Crude Player List.",
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


local green		= ''
local red		= ''
local orange	= ''
local yellow	= ''
local cyan		= ''
local white		= ''
	

local cf = Spring.GetGameRulesParam('cf') == 1

local x_cf 		= cf and 20 or 0
local x_icon_country = x_cf + 30
local x_icon_rank = x_icon_country + 16
local x_icon_clan = x_icon_rank + 16
local x_name 	= x_icon_clan + 16
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

local show_spec = false
local localTeam = 0
local localAlliance = 0

include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function SetupPlayerNames() end

options_path = 'Settings/Interface/PlayerList'
options = {
	text_height = {
		name = 'Font Size',
		type = 'number',
		value = 13,
		min=10,max=18,step=1,
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

local function CfTooltip(allyTeam)
	local tooltip = ''
	
	tooltip = tooltip .. 'Check this box to vote for a ceasefire with '.. yellow ..'<Team ' .. (allyTeam+1) .. '>'..white..'. '
		..'If everyone votes Yes, an offer will be made. If there is a ceasefire, '
		..'unchecking the box will break it.\n\n'
	
	tooltip = tooltip .. 'Your team\'s votes: \n'
	local teamList = Spring.GetTeamList(localAlliance)
	for _,teamID in ipairs(teamList) do
		local _,playerID = Spring.GetTeamInfo(teamID)
		local name = Spring.GetPlayerInfo(playerID) or '-'
		local vote = Spring.GetTeamRulesParam(teamID, 'cf_vote_' ..allyTeam)==1 and green..'Y'..white or red..'N'..white
		local teamColor = color2incolor(Spring.GetTeamColor(teamID))
		tooltip = tooltip .. teamColor .. ' <' .. name .. '> ' .. white.. vote .. '\n'
	end
	
	if Spring.GetGameRulesParam('cf_' .. localAlliance .. '_' .. allyTeam) == 1 then
		tooltip = tooltip .. '\n\n' .. green .. 'Ceasefire in effect.' .. white
	else
		local theyOffer = Spring.GetGameRulesParam('cf_offer_' .. localAlliance .. '_' .. allyTeam) == 1
		local youOffer = Spring.GetGameRulesParam('cf_offer_' .. allyTeam.. '_' .. localAlliance) == 1
		if theyOffer then
			tooltip = tooltip .. '\n\n' .. yellow .. 'They have offered a ceasefire.' .. white
		end
		if youOffer then
			tooltip = tooltip .. '\n\n' .. cyan .. 'Your team has offered a ceasefire.' .. white
		end
		
		tooltip = tooltip .. '\n\n' .. red .. 'No ceasefire in effect.' .. white
		
	end
	
	return tooltip
end


local function AddAllyteamPlayers(row, allyTeam,players)
	if not players then
		return row
	end
	local row = row
	localAlliance = Spring.GetLocalAllyTeamID()
	localTeam = Spring.GetLocalTeamID()
	local aCol = {1,0,0,1}
	if allyTeam == 'S' then
		aCol = {1,1,1,1}
	elseif allyTeam == localAlliance then
		aCol = {0,1,1,1}
	elseif Spring.GetGameRulesParam('cf_' .. localAlliance .. '_' .. allyTeam) == 1 then
		aCol = {0,1,0,1}
	elseif Spring.GetGameRulesParam('cf_offer_' .. localAlliance .. '_' .. allyTeam) == 1 then
		aCol = {1,0.5,0,1}
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
	if cf and allyTeam ~= 'S' and allyTeam ~= localAlliance then
		window_cpl:AddChild( Checkbox:New{
			x=x_cf,y=options.text_height.value * row + 3,width=20,
			caption='',
			checked = Spring.GetTeamRulesParam(localTeam, 'cf_vote_' ..allyTeam)==1,
			tooltip = CfTooltip(allyTeam),
			OnChange = { function(self)
				Spring.SendLuaRulesMsg('ceasefire:'.. (self.checked and 'n' or 'y') .. allyTeam)
			end },
		} )
	end
	
	table.sort(players, function(a,b)
			return a.name:lower() < b.name:lower()
		end)
	
	--for _, playerID in ipairs( players ) do
	for _, pdata in ipairs( players ) do
		local name_out = pdata.name
		local teamID = pdata.team
		local playerID = pdata.player
		
		local name,active,spectator,_,allyTeamID,pingTime,cpuUsage,country,rank, customKeys = Spring.GetPlayerInfo(playerID)
			
		pingTime = pingTime or 0
		cpuUsage = cpuUsage or 0
		
		local icon = nil
		if (not pdata.isAI and customKeys ~= nil) then 
			if (customKeys.clan~=nil) then 
				icon = "LuaUI/Configs/Clans/" .. customKeys.clan ..".png"
			elseif (customKeys.faction~=nil) then
				icon = "LuaUI/Configs/Factions/" .. customKeys.faction ..".png"
			end 
		end 
	
		local min_pingTime = math.min(pingTime, 1)
		local cpuCol = pingCpuColors[ math.ceil( cpuUsage * 5 ) ] 
		local pingCol = pingCpuColors[ math.ceil( min_pingTime * 5 ) ]
		local pingTime_readable = PingTimeOut(pingTime)

		if not pdata.isAI then 
		
			window_cpl:AddChild(
				Chili.Image:New{
					file="LuaUI/Images/flags/" .. (country or '') .. ".png";
					width= options.text_height.value + 3;
					height=options.text_height.value + 3;
					x=x_icon_country,
					y=options.text_height.value * row,
				}
			)
			
			window_cpl:AddChild(
				Chili.Image:New{
					file="LuaUI/Images/Ranks/" .. (1+math.ceil((customKeys.level or 0)/10)) .. ".png";
					width= options.text_height.value + 3;
					height=options.text_height.value + 3;
					x=x_icon_rank,
					y=options.text_height.value * row,
				}
			)


			window_cpl:AddChild(
				Chili.Image:New{
					file=icon;
					width= options.text_height.value + 3;
					height=options.text_height.value + 3;
					x=x_icon_clan,
					y=options.text_height.value * row,
				}
			)

		end 
		
		
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
	
	window_cpl:AddChild( Label:New{ x=0, 		caption = 'T', 		fontShadow = true, 	fontsize = options.text_height.value, } )
	if cf then
		window_cpl:AddChild( Label:New{ x=x_cf,		caption = 'CF',		fontShadow = true, 	fontsize = options.text_height.value, } )
	end
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
				
				table.insert( allyTeams[allyTeamID_out], {name=name_out,team=teamID,player=playerID, isAI = isAI} )
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
		height=options.text_height.value * 1.5, width=160,
		caption = 'Show Spectators',
		checked = show_spec,
		OnChange = { function(self) show_spec = not self.checked; SetupPlayerNames(); end },
	} )
	row = row + 1
	
	if cf then
		window_cpl:AddChild( Checkbox:New{
			x=5, y=options.text_height.value * (row + 0.5),
			height=options.text_height.value * 1.5, width=160,
			caption = 'Place Restricted Zones',
			checked = WG.rzones.rZonePlaceMode,
			OnChange = { function(self) WG.rzones.rZonePlaceMode = not WG.rzones.rZonePlaceMode; end },
		} )	
	end
	
end


function widget:KeyPress(key, modifier, isRepeat)
	if key == KEYSYMS.ESCAPE and not modifier.alt and not modifier.ctrl and not modifier.shift and not modifier.meta then 
		if WG.crude.visible and visible then  -- HACK FIXME TODO this is just wrong, it should not rely on escape keypress + crudemenu, crudemenu can be rebinded. Also when this is executed crude visible state is not yet updated 
			screen0:RemoveChild(window_cpl)
			visible = false 
		elseif not visible then 
			screen0:AddChild(window_cpl)
			visible = true
		end 
	end 
end 

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------



function widget:Shutdown()
	Spring.SendCommands({"info 1"})
end

local timer = 0
function widget:Update(s)
	timer = timer + s
	if timer > 5 then
		timer = 0
		SetupPlayerNames()
		window_cpl:SetPos(screen0.width-window_cpl.width, screen0.height-window_cpl.height)
		
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
	
	green 	= color2incolor(0,1,0,1)
	red 	= color2incolor(1,0,0,1)
	orange 	= color2incolor(1,0.4,0,1)
	yellow 	= color2incolor(1,1,0,1)
	cyan 	= color2incolor(0,1,1,1)
	white 	= color2incolor(1,1,1,1)

	
	window_cpl = Window:New{  
		--margin = {2,2,2,2},
		--padding = {2,2,2,2},
		dockable = true,
		name = "crudeplayerlist",
		color = {1,1,1,options.backgroundOpacity.value},
		right = 0,  
		bottom = 0,
		width  = 320,
		height = 150,
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
	
	
	visible = WG.crude.visible -- HACK TODO FIXME this is wrong way to do it
	if not visible then 
		screen0:RemoveChild(window_cpl)
	end 
	
	SetupPlayerNames()
	
	Spring.SendCommands({"info 0"})
end
