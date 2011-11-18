--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List v1.2",
    desc      = "v1.2 Chili Crude Player List.",
    author    = "CarRepairer",
    date      = "2011-01-06",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = true,
	detailsDefault = 1
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

local window_cpl, scroll_cpl

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
local x_buffer	= x_ping + 40

local x_bound	= x_buffer + 40 + (cf and 0 or 20)

local UPDATE_FREQUENCY = 0.5	-- seconds

local wantsNameRefresh = {}
local aiTeams = {}

-- keeps track of labels
local nameLabels = {}
local pingLabels = {}
local cpuLabels = {}

pingCpuColors = {
	{0, 1, 0, 1},
	{0.7, 1, 0, 1},
	{1, 1, 0, 1},
	{1, 0.6, 0, 1},
	{1, 0, 0, 1}
}

local sharePic        = ":n:"..LUAUI_DIRNAME.."Images/playerlist/share.png"

--local show_spec = false
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
	alignToTop = {
		name = "Align to top",
		type = 'bool',
		value = false,
		desc = "Align list entries to top (i.e. don't push to bottom)",
		OnChange = function() SetupPlayerNames() end,
	},
	showSpecs = {
		name = "Show spectators",
		type = 'bool',
		value = false,
		desc = "Show spectators in main window (rather than confining them to tooltip)",
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


local function PingTimeOut(pingTime)
	if pingTime < 1 then
		return (math.floor(pingTime*1000) ..'ms')
	elseif pingTime > 999 then
		return ('' .. (math.floor(pingTime*100/60)/100)):sub(1,4) .. 'min'
	end
	--return (math.floor(pingTime*100))/100
	return ('' .. (math.floor(pingTime*100)/100)):sub(1,4) .. 's' --needed due to rounding errors.
end

-- makes a color char from a color table
-- explanation for string.char: http://springrts.com/phpbb/viewtopic.php?f=23&t=24952
local function GetColorChar(colorTable)
	if colorTable == nil then return string.char(255,255,255,255) end
	local col = {}
	for i=1,4 do
		col[i] = math.ceil(colorTable[i]*255)
	end
	return string.char(col[4],col[1],col[2],col[3])
end

--[[
local function GetColorStr(colorTable)
	if colorTable == nil then return "\255\255\255\255" end
end
]]--

-- ceasefire button tooltip
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

-- spectator tooltip
-- not shown if they're in playerlist as well
local function MakeSpecTooltip()
	local players = Spring.GetPlayerList()
	local specsSorted = {}
	for i=1,#players do
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage = Spring.GetPlayerInfo(players[i])
		if spectator and active then
			specsSorted[#specsSorted + 1] = {name = name, ping = pingTime, cpu = cpuUsage}
			--specsSorted[#specsSorted + 1] = {name = name, ping = pingTime, cpu = cpuUsage}
		end
	end
	table.sort(specsSorted, function(a,b)
		return a.name:lower() < b.name:lower()
	end)
	local windowTooltip = "SPECTATORS"
	for i=1,#specsSorted do
		local cpuCol = pingCpuColors[ math.ceil( specsSorted[i].cpu * 5 ) ]
		cpuCol = GetColorChar(cpuCol)
		local pingCol = pingCpuColors[ math.ceil( math.min(specsSorted[i].ping,1) * 5 ) ]
		pingCol = GetColorChar(pingCol)
		local cpu = math.round(specsSorted[i].cpu*100)
		windowTooltip = windowTooltip .. "\n\t"..specsSorted[i].name.."\t"..cpuCol..(cpu)..'%\008' .. "\t"..pingCol..PingTimeOut(specsSorted[i].ping).."\008"
	end
	scroll_cpl.tooltip = windowTooltip
end

-- updates ping and CPU for all players; name if needed
local function UpdatePlayerInfo()
	local players = Spring.GetPlayerList()
	for i=1,#players do
		local playerID = players[i]
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage = Spring.GetPlayerInfo(playerID)
		
		if not(aiTeams[teamID]) and ((not spectator) or options.showSpecs.value) then
			-- update ping and CPU
			pingTime = pingTime or 0
			cpuUsage = cpuUsage or 0
			local min_pingTime = math.min(pingTime, 1)
			local cpuCol = pingCpuColors[ math.ceil( cpuUsage * 5 ) ] 
			local pingCol = pingCpuColors[ math.ceil( min_pingTime * 5 ) ]
			local pingTime_readable = PingTimeOut(pingTime)
			
			cpuLabels[playerID].font.color = cpuCol
			cpuLabels[playerID]:SetCaption(math.round(cpuUsage*100) .. '%')
			cpuLabels[playerID]:Invalidate()
			pingLabels[playerID].font.color = pingCol
			pingLabels[playerID]:SetCaption(pingTime_readable)
			pingLabels[playerID]:Invalidate()
		end
		-- for <Waiting> bug at start, may be a FIXME
		if nameLabels[teamID] and (not active) then
			local name_out = ''
			name_out = name or ''
			if	name_out == ''
				or #(Spring.GetPlayerList(teamID,true)) == 0
				or spectator
			then
				if Spring.GetGameSeconds() < 0.1 then
					name_out = "<Waiting> " ..(name or '')
					wantsNameRefresh[playerID] = true
				elseif Spring.GetTeamUnitCount(teamID) > 0  then
					name_out = "<Aband. units> " ..(name or '')
				else
					name_out = "<Dead> " ..(name or '')
				end
			end
			nameLabels[teamID]:SetCaption(name_out)
		end
	end
	if not options.showSpecs.value then MakeSpecTooltip() end
end

-- adds:	ally team number, ceasefire button if applicable
--			details of all players in allyteam (icons, name, CPU, ping)

local function AddAllyteamPlayers(row, allyTeam, players)
	local fontsize = options.text_height.value
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
	
	-- allyteam number
	scroll_cpl:AddChild(
		Label:New{
			y=options.text_height.value * row,
			caption = (type(allyTeam) == 'number' and (allyTeam+1) or allyTeam),
			textColor = aCol,
			fontsize = fontsize,
			fontShadow = true,
		}
	)
	-- ceasefire button
	if cf and allyTeam ~= 'S' and allyTeam ~= localAlliance then
		scroll_cpl:AddChild( Checkbox:New{
			x=x_cf,y=fontsize * row + 3,width=20,
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
		local icRank = nil 
		local icCountry = country and country ~= '' and "LuaUI/Images/flags/" .. (country) .. ".png" or nil
		
		-- clan/faction emblems, level, country
		if (not pdata.isAI and customKeys ~= nil) then 
			if (customKeys.clan~=nil and customKeys.clan~="") then 
				icon = "LuaUI/Configs/Clans/" .. customKeys.clan ..".png"
			elseif (customKeys.faction~=nil and customKeys.faction~="") then
				icon = "LuaUI/Configs/Factions/" .. customKeys.faction ..".png"
			end 
			if customKeys.level ~= nil and customKeys.level~="" then 
				icRank = "LuaUI/Images/Ranks/" .. (1+math.ceil((customKeys.level or 0)/10)) .. ".png"
			end
		end 
	
		local min_pingTime = math.min(pingTime, 1)
		local cpuCol = pingCpuColors[ math.ceil( cpuUsage * 5 ) ] 
		local pingCol = pingCpuColors[ math.ceil( min_pingTime * 5 ) ]
		local pingTime_readable = PingTimeOut(pingTime)

		if not pdata.isAI then 
			-- flag
			if icCountry ~= nil  then 
				scroll_cpl:AddChild(
					Chili.Image:New{
						file=icCountry;
						width= fontsize + 3;
						height=fontsize + 3;
						x=x_icon_country,
						y=fontsize * row,
					}
				)
			end 
			-- level-based rank
			if icRank ~= nil then 
				scroll_cpl:AddChild(
					Chili.Image:New{
						file=icRank;
						width= fontsize + 3;
						height=fontsize + 3;
						x=x_icon_rank,
						y=fontsize * row,
					}
				)
			end 
			-- clan icon
			if icon ~= nil then 
				scroll_cpl:AddChild(
					Chili.Image:New{
						file=icon;
						width= fontsize + 3;
						height=fontsize + 3;
						x=x_icon_clan,
						y=fontsize * row,
					}
				)
			end

		end 
		
		-- name
		local nameLabel = Label:New{
			x=x_name,
			y=fontsize * row,
			width=150,
			autosize=false,
			--caption = (spectator and '' or ((teamID+1).. ') ') )  .. name, --do not remove, will add later as option
			caption = name_out,
			textColor = teamID and {Spring.GetTeamColor(teamID)} or {1,1,1,1},
			fontsize = fontsize,
			fontShadow = true,
		}
		if teamID then nameLabels[teamID] = nameLabel end
		scroll_cpl:AddChild(nameLabel)
		-- because for some goddamn stupid reason the names won't show otherwise
		nameLabel:UpdateLayout()
		nameLabel:Invalidate()
		
		-- share button
		if active and allyTeam == localAlliance and teamID ~= localTeam then
			scroll_cpl:AddChild(
				Button:New{
					x=x_share,
					y=fontsize * (row+0.5),
					height = fontsize,
					width = fontsize,
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
		-- CPU, ping
		if not pdata.isAI then
			local cpuLabel = Label:New{
				x=x_cpu,
				y=fontsize * row,
				caption = math.round(cpuUsage*100) .. '%',
				--textColor = cpuCol,
				fontsize = fontsize,
				fontShadow = true,
			}
			cpuLabels[playerID] = cpuLabel
			scroll_cpl:AddChild(cpuLabel)
			local pingLabel = Label:New{
				x=x_ping,
				y=fontsize * row,
				caption = pingTime_readable ,
				--textColor = pingCol,
				fontsize = fontsize,
				fontShadow = true,
			}
			pingLabels[playerID] = pingLabel
			scroll_cpl:AddChild(pingLabel)
		end
		row = row + 1
	end
	return row
end

SetupPlayerNames = function()
	local fontsize = options.text_height.value
	scroll_cpl:ClearChildren()
	
	scroll_cpl:AddChild( Label:New{ x=0, 		caption = 'T', 		fontShadow = true, 	fontsize = fontsize, } )
	if cf then
		scroll_cpl:AddChild( Label:New{ x=x_cf,		caption = 'CF',		fontShadow = true, 	fontsize = fontsize, } )
	end
	scroll_cpl:AddChild( Label:New{ x=x_name, 	caption = 'Name', 	fontShadow = true,  fontsize = fontsize,} )
	scroll_cpl:AddChild( Label:New{ x=x_cpu, 	caption = 'CPU', 	fontShadow = true,  fontsize = fontsize,} )
	scroll_cpl:AddChild( Label:New{ x=x_ping, 	caption = 'Ping', 	fontShadow = true,  fontsize = fontsize,} )
	
	local playerroster	= Spring.GetPlayerList()
	local teams 		= Spring.GetTeamList()
	
	myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
	
	local allyTeams = {}
	
	local specNames = {}
	
	--Specs
	for i,v in ipairs(playerroster) do
		local playerID = playerroster[i]
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
		if spectator and active then
			if not allyTeams.S then
				allyTeams.S = {}
			end
			table.insert( allyTeams.S, {name=name,team=nil,player=playerID} )
			specNames[name]=playerID
		end
	end
	
	for i,teamID in ipairs(teams) do
		if teamID ~= Spring.GetGaiaTeamID() then
			-- process names
			local _,playerID,_,isAI,_,allyTeamID_out = Spring.GetTeamInfo(teamID)
			local name_out = ''
			if isAI then
				local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
				name_out = '<'.. name ..'> '.. shortName
				aiTeams[teamID] = true
			else
				--local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
				local name,active,spectator,_,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID)
				
				if allyTeamID then
					allyTeamID_out = allyTeamID
				end
				
				name_out = name or ''
				if name_out == ''
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

	if options.showSpecs.value then
		row = AddAllyteamPlayers(row,'S',allyTeams.S)
	else
		MakeSpecTooltip()
	end
	
	--[[
	scroll_cpl:AddChild( Checkbox:New{
		x=5, y=fontsize * (row + 0.5),
		height=fontsize * 1.5, width=160,
		caption = 'Show Spectators',
		checked = show_spec,
		OnChange = { function(self) show_spec = not self.checked; SetupPlayerNames(); end },
	} )
	row = row + 1
	]]--
	
	-- ceasefire: restricted zones button
	if cf then
		scroll_cpl:AddChild( Checkbox:New{
			x=5, y=fontsize * (row + 0.5),
			height=fontsize * 1.5, width=160,
			caption = 'Place Restricted Zones',
			checked = WG.rzones.rZonePlaceMode,
			OnChange = { function(self) WG.rzones.rZonePlaceMode = not WG.rzones.rZonePlaceMode; end },
		} )
		row = row + 1
	end
	
	--push things to bottom of window if needed
	--scroll_cpl.width = x_bound --window_cpl.width - window_cpl.padding[1] - window_cpl.padding[3]
	local height = row * (fontsize+2)
	--window_cpl.minimumSize = {x_bound, height}
	scroll_cpl.height = math.min(height, window_cpl.height)
	if not (options.alignToTop.value) then 
		scroll_cpl.y = (window_cpl.height) - scroll_cpl.height
	else
		scroll_cpl.y = 0
	end
	window_cpl:Invalidate()
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function widget:Shutdown()
	Spring.SendCommands({"info 1"})
end

local timer = 0
local lastSizeX
local lastSizeY
function widget:Update(s)
	timer = timer + s
	if timer > UPDATE_FREQUENCY then
		timer = 0
		if lastSizeX ~= window_cpl.width or lastSizeY ~= window_cpl.height then
			SetupPlayerNames()	-- size changed; regen everything
			lastSizeX = window_cpl.width
			lastSizeY = window_cpl.height
		else
			UpdatePlayerInfo()
		end
	end
end

function widget:PlayerChanged(playerID)
	SetupPlayerNames()
end

function widget:PlayerAdded(playerID)
	SetupPlayerNames()
end

function widget:PlayerRemoved(playerID)
	SetupPlayerNames()
end

function widget:TeamDied(teamID)
	SetupPlayerNames()
end

function widget:TeamChanged(teamID)
	SetupPlayerNames()
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
		dockable = true,
		name = "Player List",
		color = {1,1,1,options.backgroundOpacity.value},
		right = 0,  
		bottom = 0,
		width  = x_bound,
		height = 150,
		padding = {8, 2, 8, 2};
		--autosize   = true;
		parent = screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = true,
		minimumSize = {x_bound, 1},

	}
	scroll_cpl = ScrollPanel:New{
		parent = window_cpl,	
		width = "100%",
		height = "100%",
		--padding = {2,2,2,2},
		backgroundColor  = {0,0,0,0},
		padding = {0, 0, 0, 0},
		--autosize = true,
		hitTestAllowEmpty = true
	}

	SetupPlayerNames()
	
	Spring.SendCommands({"info 0"})
	lastSizeX = window_cpl.width
	lastSizeY = window_cpl_height
end
