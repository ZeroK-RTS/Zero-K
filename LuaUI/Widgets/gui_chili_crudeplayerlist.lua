--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Crude Player List",
    desc      = "v1.327 Chili Crude Player List.",
    author    = "CarRepairer",
    date      = "2011-01-06",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = false,
  }
end

if Spring.GetModOptions().singleplayercampaignbattleid then
	return
end

VFS.Include ("LuaRules/Utilities/lobbyStuff.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local window_cpl, scroll_cpl

local colorNames = {}
local colors = {}

local showWins = false
local wins_width = 0

local green		= ''
local red		= ''
local orange	= ''
local yellow	= ''
local cyan		= ''
local white		= ''
	
local function IsFFA()
	local allyteams = Spring.GetAllyTeamList()
	local gaiaT = Spring.GetGaiaTeamID()
	local gaiaAT = select(6, Spring.GetTeamInfo(gaiaT, false))
	local numAllyTeams = 0
	for i=1,#allyteams do
		if allyteams[i] ~= gaiaAT then
			local teams = Spring.GetTeamList(allyteams[i])
			if #teams > 0  then
				numAllyTeams = numAllyTeams + 1
			end
		end
	end
	return numAllyTeams > 2
end
	
local cf = (not Spring.FixedAllies()) and IsFFA()

if not WG.rzones then
	WG.rzones = {
		rZonePlaceMode = false
	}
end

local x_wins			= 0
local x_icon_country	= x_wins + 20
local x_icon_rank		= x_icon_country + 20
local x_icon_clan		= x_icon_rank + 16
local x_cf				= x_icon_clan + 16
local x_team			= x_cf + 20
local x_name			= x_team + 16
local x_share			= x_name + 140 
local x_cpu				= x_share + 16
local x_ping			= x_cpu + 16
local x_postwins		= x_ping + 16

local UPDATE_FREQUENCY = 0.8	-- seconds

local wantsNameRefresh = {}	-- unused
local cfCheckBoxes = {}

local allyTeams = {}	-- [id] = {team1, team2, ...}
local teams = {}	-- [id] = {leaderName = name, roster = {entity1, entity2, ...}}

-- entity = player (including specs) or bot
-- ordered list; contains isAI, isSpec, playerID, teamID, name, namelabel, cpuImg, pingImg
local entities = {}

local pingMult = 2/3	-- lower = higher ping needed to be red
pingCpuColors = {
	{0, 1, 0, 1},
	{0.7, 1, 0, 1},
	{1, 1, 0, 1},
	{1, 0.6, 0, 1},
	{1, 0, 0, 1}
}

local sharePic        = ":n:"..LUAUI_DIRNAME.."Images/playerlist/share.png"
local cpuPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/cpu.png"
local pingPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/ping.png"

--local show_spec = false
local localTeam = 0
local localAlliance = 0

include("keysym.h.lua")



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function SetupPlayerNames() end

options_path = 'Settings/HUD Panels/Player List'
options_order = {'text_height', 'backgroundOpacity', 'reset_wins', 'inc_wins_1', 'inc_wins_2','alignToTop','showSpecs','allyTeamPerTeam','debugMessages','mousewheel','win_show_condition'}
options = {
	text_height = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min = 10, max = 18, step = 1,
		OnChange = function() SetupPlayerNames() end,
		advanced = true
	},
	backgroundOpacity = {
		name = "Background opacity",
		type = "number",
		value = 0, min = 0, max = 1, step = 0.01,
		OnChange = function(self)
			scroll_cpl.backgroundColor = {1,1,1,self.value}
			scroll_cpl.borderColor = {1,1,1,self.value}
			scroll_cpl:Invalidate()
		end,
	},
	reset_wins = {
		name = "Reset Wins",
		desc = "Reset the win counts of all players",
		type = 'button',
		OnChange = function() 
			if WG.WinCounter_Reset ~= nil then 
				WG.WinCounter_Reset()
				SetupPlayerNames()
			end 
		end,
	},	
	inc_wins_1 = {
		name = "Increment Team 1 Wins",
		desc = "",
		type = 'button',
		OnChange = function()
			if WG.WinCounter_Increment ~= nil then 
				local allyTeams = Spring.GetAllyTeamList()
				WG.WinCounter_Increment(allyTeams[1]) 
				SetupPlayerNames()
			end
		end,
		advanced = true
	},
	inc_wins_2 = {
		name = "Increment Team 2 Wins",
		desc = "",
		type = 'button',
		OnChange = function()
			if WG.WinCounter_Increment ~= nil then 
				local allyTeams = Spring.GetAllyTeamList()
				WG.WinCounter_Increment(allyTeams[2]) 
				SetupPlayerNames()
			end
		end,
		advanced = true
	},
	win_show_condition = {
		name = 'Show Wins',
		type = 'radioButton',
		value = 'whenRelevant',
		items = {
			{key ='always', 	name='Always'},
			{key ='whenRelevant', 		name='When someone has wins'},
			{key ='never', 		name='Never'},
		},
		OnChange = function() SetupPlayerNames() end,
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
		desc = "Show spectators in main window (rather than confining them to tooltip. Note: tooltip might block mouse click in some cases)",
		OnChange = function() SetupPlayerNames() end,
	},
	allyTeamPerTeam = {
		name = "Display team for each player",
		type = 'bool',
		value = true,
		desc = "Write the team number next to each player's name (rather than only for first player)",
		OnChange = function() SetupPlayerNames() end,
	},
	debugMessages = {
		name = "Enable debug messages",
		type = 'bool',
		value = false,
		desc = "Enables some debug messages (disable if it starts flooding console)",
	},
	mousewheel = {
		name = "Scroll with mousewheel",
		type = 'bool',
		value = true,
		OnChange = function(self) 
				scroll_cpl.ignoreMouseWheel = not self.value;
			end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function CheckShowWins()
	return WG.WinCounter_currentWinTable ~= nil and (WG.WinCounter_currentWinTable.hasWins and options.win_show_condition.value == "whenRelevant") or options.win_show_condition.value == "always"
end

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
		Spring.Echo('Player List: No units selected to share.')
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
	
	if Spring.GetGameRulesParam('cf_' .. localAlliance .. '_' .. allyTeam) == 1 then
		tooltip = tooltip .. green .. 'Ceasefire in effect.' .. white
	else
		local theyOffer = Spring.GetGameRulesParam('cf_offer_' .. localAlliance .. '_' .. allyTeam) == 1
		local youOffer = Spring.GetGameRulesParam('cf_offer_' .. allyTeam.. '_' .. localAlliance) == 1
		if theyOffer then
			tooltip = tooltip .. yellow .. 'They have offered a ceasefire.' .. white .. '\n'
		end
		if youOffer then
			tooltip = tooltip .. cyan .. 'Your team has offered a ceasefire.' .. white .. '\n'
		end
		
		tooltip = tooltip .. red .. 'No ceasefire in effect.' .. white
	end
	
	tooltip = tooltip .. '\n\n'
	
	tooltip = tooltip .. 'Your team\'s votes: \n'
	local teamList = Spring.GetTeamList(localAlliance)
	for _,teamID in ipairs(teamList) do
		local _,playerID = Spring.GetTeamInfo(teamID, false)
		local name = Spring.GetPlayerInfo(playerID, false) or '-'
		local vote = Spring.GetTeamRulesParam(teamID, 'cf_vote_' ..allyTeam)==1 and green..'Y'..white or red..'N'..white
		local teamColor = color2incolor(Spring.GetTeamColor(teamID))
		tooltip = tooltip .. teamColor .. ' <' .. name .. '> ' .. white.. vote ..'\n'
	end
	
	tooltip = tooltip .. '\n'
	
	tooltip = tooltip .. 'Check this box to vote for a ceasefire with '.. yellow ..'<Team ' .. (allyTeam+1) .. '>'..white..'. \n\n'
		..'If everyone votes Yes, an offer will be made. If there is a ceasefire, '
		..'unchecking the box will break it.'
	
	return tooltip
end

-- spectator tooltip
-- not shown if they're in playerlist as well
local function MakeSpecTooltip()
	if options.showSpecs.value then
		scroll_cpl.tooltip = nil
		return
	end
	
	local players = Spring.GetPlayerList()
	
	local specsSorted = {}
	for i = 1, #players do
		local name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage = Spring.GetPlayerInfo(players[i], false)
		if spectator and active then
			specsSorted[#specsSorted + 1] = {name = name, ping = pingTime, cpu = math.min(cpuUsage,1)}
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
		local pingCol = pingCpuColors[ math.ceil( math.min(specsSorted[i].ping*pingMult,1) * 5 ) ]
		pingCol = GetColorChar(pingCol)
		local cpu = math.round(specsSorted[i].cpu*100)
		windowTooltip = windowTooltip .. "\n\t"..specsSorted[i].name.."\t"..cpuCol..(cpu)..'%\008' .. "\t"..pingCol..PingTimeOut(specsSorted[i].ping).."\008"
	end
	scroll_cpl.tooltip = windowTooltip --tooltip in display region only (window_cpl have soo much waste space)
end

-- updates ping and CPU for all players; name if needed
local function UpdatePlayerInfo()
	for i = 1, #entities do
		if not entities[i].isAI then
			local playerID = entities[i].playerID
			local name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage = Spring.GetPlayerInfo(playerID, false)
			--Spring.Echo("Player Update", playerID, name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, #(Spring.GetPlayerList(teamID, true)))
			
			local name_out = name or ''
			if name_out == '' or #(Spring.GetPlayerList(teamID, true)) == 0 or (spectator and not entities[i].isSpec) or Spring.GetTeamRulesParam(teamID, "isDead") == 1 then
				if Spring.GetGameSeconds() < 0.1 or cpuUsage > 1 then
					name_out = "<Waiting> " ..(name or '')
				elseif Spring.GetTeamUnitCount(teamID) > 0 then
					name_out = "<Aband. units> " .. (name or '')
				else
					name_out = "<Dead> " .. (name or '')
				end
			end
			if entities[i].nameLabel then 
				entities[i].nameLabel:SetCaption(name_out)
			end
			
			if ((not spectator) or options.showSpecs.value) then
				-- update ping and CPU
				pingTime = pingTime or 0
				cpuUsage = cpuUsage or 0
				local min_pingTime = math.min(pingTime, 1)
				local min_cpuUsage = math.min(cpuUsage, 1)
				local cpuColIndex = math.ceil( min_cpuUsage * 5 )
				local pingColIndex = math.ceil( min_pingTime * 5 )
				local pingTime_readable = PingTimeOut(pingTime)
				local blank = not active
				
				local cpuImg = entities[i].cpuImg
				if cpuImg then
					cpuImg.tooltip = (blank and nil or 'CPU: ' .. math.round(cpuUsage*100) .. '%')
					if cpuColIndex ~= entities[i].cpuIndexOld then
						entities[i].cpuIndexOld = cpuColIndex
						cpuImg.color = pingCpuColors[cpuColIndex]
						cpuImg:Invalidate()
					end
				end
				
				local pingImg = entities[i].pingImg
				if pingImg then
					pingImg.tooltip = (blank and nil or 'Ping: ' .. pingTime_readable)
					if pingColIndex ~= entities[i].pingIndexOld then
						entities[i].pingIndexOld = pingColIndex
						pingImg.color = pingCpuColors[pingColIndex]
						pingImg:Invalidate()
					end
				end
			end

			local wins = 0
			if name ~= nil and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[name] ~= nil then
				wins = WG.WinCounter_currentWinTable[name].wins
			end
			if entities[i].winsLabel then
				entities[i].winsLabel:SetCaption(wins)
			end
		end -- if not isAI
	end -- for entities
	MakeSpecTooltip()
	
	for allyTeam, cb in pairs(cfCheckBoxes) do
		cb.tooltip = CfTooltip(allyTeam)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddCfCheckbox(allyTeam)
	local fontsize = options.text_height.value
	if cf and allyTeam ~= -1 and allyTeam ~= localAlliance then
		local cfCheck = Checkbox:New{
			x=x_cf,y=(fontsize+1) * row + 3,width=20,
			caption='',
			checked = Spring.GetTeamRulesParam(localTeam, 'cf_vote_' ..allyTeam)==1,
			tooltip = CfTooltip(allyTeam),
			OnChange = { function(self)
				Spring.SendLuaRulesMsg('ceasefire:'.. (self.checked and 'n' or 'y') .. ':' .. allyTeam)
				self.tooltip = CfTooltip(allyTeam)
			end },
		}
		scroll_cpl:AddChild(cfCheck)
		cfCheckBoxes[allyTeam] = cfCheck
	end
end


local function	WriteAllyTeamNumbers(allyTeam)
	local fontsize = options.text_height.value
	local aCol = {1,0,0,1}
	if allyTeam == -1 then
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
			x=x_team,
			y=(fontsize+1) * row,
			caption = (allyTeam == -1 and 'S' or allyTeam+1),
			textColor = aCol,
			fontsize = fontsize,
			fontShadow = true,
			autosize = false,
		}
	)
end

-- adds all the entity information
local function AddEntity(entity, teamID, allyTeamID)
	local fontsize = options.text_height.value

	local deadTeam = false
	if entity == nil then
		entity = {}
		deadTeam = true
	end	
	
	local name,active,spectator,pingTime,cpuUsage,country,_, customKeys
	local playerID = entity.playerID or teams[teamID].leader
	if playerID then
		name,active,spectator,_,_,pingTime,cpuUsage,country,_, customKeys = Spring.GetPlayerInfo(playerID)
	end
	--Spring.Echo("Entity with team ID " .. teamID .. " is " .. (active and '' or "NOT ") .. "active")
	if not active then deadTeam = true end

	pingTime = pingTime or 0
	cpuUsage = cpuUsage or 0

	local name_out = entity.name or ''
	if (name_out == '' or deadTeam or (spectator and teamID >= 0)) and not entity.isAI then
		if Spring.GetGameSeconds() < 0.1 or cpuUsage > 1 then
			name_out = "<Waiting> " ..(name or '')
		elseif Spring.GetTeamUnitCount(teamID) > 0  then
			name_out = "<Aband. units> " ..(name or '')
		else
			name_out = "<Dead> " ..(name or '')
		end
	end
	local icon = nil
	local icRank = nil 
	local icCountry = country and country ~= '' and "LuaUI/Images/flags/" .. (country) .. ".png" or nil
	
	-- clan/faction emblems, level, country
	if (not entity.isAI and customKeys ~= nil) then 
		if (customKeys.clan~=nil and customKeys.clan~="") then 
			icon = "LuaUI/Configs/Clans/" .. customKeys.clan ..".png"
		elseif (customKeys.faction~=nil and customKeys.faction~="") then
			icon = "LuaUI/Configs/Factions/" .. customKeys.faction ..".png"
		end 
		icRank = "LuaUI/Images/LobbyRanks/" .. (customKeys.icon or "0_0") .. ".png"
	end
	
	local min_pingTime = math.min(pingTime, 1)
	local min_cpuUsage = math.min(cpuUsage, 1)
	local cpuCol = pingCpuColors[ math.ceil( min_cpuUsage * 5 ) ] 
	local pingCol = pingCpuColors[ math.ceil( min_pingTime * 5 ) ]
	local pingTime_readable = PingTimeOut(pingTime)

	local wins = 0
	if name ~= nil and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[name] ~= nil then wins = WG.WinCounter_currentWinTable[name].wins end

	if not entity.isAI then 
		-- flag
		if icCountry ~= nil  then 
			scroll_cpl:AddChild(
				Chili.Image:New{
					file=icCountry;
					width= fontsize + 3;
					height=fontsize + 3;
					x=x_icon_country,
					y=(fontsize+1) * row,
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
					y=(fontsize+1) * row,
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
					y=(fontsize+1) * row,
				}
			)
		end

	end 
	
	-- name
	local nameLabel = Label:New{
		x=x_name,
		y=(fontsize+1) * row,
		width=150,
		autosize=false,
		--caption = (spectator and '' or ((teamID+1).. ') ') )  .. name, --do not remove, will add later as option
		caption = name_out,
		realText = name_out,
		textColor = teamID and {Spring.GetTeamColor(teamID)} or {1,1,1,1},
		fontsize = fontsize,
		fontShadow = true,
	}
	entity.nameLabel = nameLabel
	scroll_cpl:AddChild(nameLabel)
	-- because for some goddamn stupid reason the names won't show otherwise
	nameLabel:UpdateLayout()
	nameLabel:Invalidate()
	
	-- share button
	if active and allyTeamID == localAlliance and teamID ~= localTeam then
		scroll_cpl:AddChild(
			Button:New{
				x=x_share,
				y=(fontsize+1) * (row+0.5)-2.5,
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
	if not (entity.isAI) then
		local cpuImg = Image:New{
			x=x_cpu,
			y=(fontsize+1) * row,
			height = (fontsize+3),
			width = (fontsize+3)*10/16, 
			tooltip = 'CPU: ' .. math.round(cpuUsage*100) .. '%',
			file = cpuPic,
			keepAspect = false,
		}
		function cpuImg:HitTest(x,y) return self end
		entity.cpuImg = cpuImg
		scroll_cpl:AddChild(cpuImg)
		local pingImg = Image:New{
			x=x_ping,
			y=(fontsize+1) * row,
			height = (fontsize+3),
			width = (fontsize+3)*10/16, 			
			tooltip = 'Ping: ' .. pingTime_readable,
			file = pingPic,
			keepAspect = false,
		}
		function pingImg:HitTest(x,y) return self end
		entity.pingImg = pingImg
		scroll_cpl:AddChild(pingImg)

		if showWins and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[name] ~= nil then
			local winsLabel = Label:New{
				x=x_wins,
				y=(fontsize+1) * row,
				width=20,
				autosize=false,
				--caption = (spectator and '' or ((teamID+1).. ') ') )  .. name, --do not remove, will add later as option
				caption = wins,
				realText = wins,
				textColor = teamID and {Spring.GetTeamColor(teamID)} or {1,1,1,1},
				fontsize = fontsize,
				fontShadow = true,
			}
			scroll_cpl:AddChild(winsLabel)
		end
	end

	row = row + 1
end

-- adds:	ally team number if applicable
local function AddTeam(teamID, allyTeamID)
	if options.allyTeamPerTeam.value then
		WriteAllyTeamNumbers(allyTeamID)
	end
	
	-- add each entity in the team
	local count = #teams[teamID].roster
	if count == 0 then
		AddEntity(nil, teamID, allyTeamID)
		return
	end
	for i=1,count do
		AddEntity(teams[teamID].roster[i], teamID, allyTeamID)
	end
end

-- adds:	ally team number if applicable, ceasefire button
local function AddAllyTeam(allyTeamID)
	if #(allyTeams[allyTeamID] or {}) == 0 then
		return
	end

	-- sort teams by leader name, putting own team at top
	--table.sort(allyTeams[allyTeamID], function(a,b)
	--		if a == localTeam then return true
	--		elseif b == localTeam then return false end
	--		return a.name:lower() < b.name:lower()
	--	end)	

	if not options.allyTeamPerTeam.value then
		WriteAllyTeamNumbers(allyTeamID)
	end
	AddCfCheckbox(allyTeamID)
	
	-- add each team in the allyteam
	for i=1,#allyTeams[allyTeamID] do
		AddTeam(allyTeams[allyTeamID][i], allyTeamID)
	end
end

local function AlignScrollPanel()
	--push things to bottom of window if needed
	local height = math.ceil(row * (options.text_height.value+1.5) + 10)
	if height < window_cpl.height then
		scroll_cpl.height = height
		scroll_cpl.verticalScrollbar = false
	else
		scroll_cpl.height = window_cpl.height
		scroll_cpl.verticalScrollbar = true
	end
	if not (options.alignToTop.value) then
		scroll_cpl.y = (window_cpl.height) - scroll_cpl.height - 2
	else
		scroll_cpl.y = 0
	end
end

SetupPlayerNames = function()
	showWins = CheckShowWins()

	if options.debugMessages.value then
		Spring.Echo("Generating playerlist")
	end
	entities = {}
	teams = {}
	allyTeams = {}
	
	local specTeam = {roster = {}}

	local fontsize = options.text_height.value
	scroll_cpl:ClearChildren()
	
	scroll_cpl:AddChild( Label:New{ x=x_team, 		caption = 'T', 		fontShadow = true, 	fontsize = fontsize, } )
	if cf then
		scroll_cpl:AddChild( Label:New{ x=x_cf,		caption = 'CF',		fontShadow = true, 	fontsize = fontsize, } )
	end
	scroll_cpl:AddChild( Label:New{ x=x_name, 	caption = 'Name', 	fontShadow = true,  fontsize = fontsize,} )
	scroll_cpl:AddChild( Label:New{ x=x_cpu, 	caption = 'C', 	fontShadow = true,  fontsize = fontsize,} )
	scroll_cpl:AddChild( Label:New{ x=x_ping, 	caption = 'P', 	fontShadow = true,  fontsize = fontsize,} )
	if showWins then scroll_cpl:AddChild( Label:New{ x=x_wins, 	caption = 'W', 	fontShadow = true,  fontsize = fontsize,} ) end
	
	local playerlist = Spring.GetPlayerList()
	local teamsSorted = Spring.GetTeamList()
	local allyTeamsSorted = Spring.GetAllyTeamList()
	
	local myID = Spring.GetMyPlayerID()
	local myName = Spring.GetPlayerInfo(myID, false)
	localTeam = Spring.GetMyTeamID()
	localAlliance = Spring.GetMyAllyTeamID()
	
	-- register any AIs as entities, assign teams to allyTeams
	for i = 1, #teamsSorted do
		local teamID = teamsSorted[i]
		if teamID ~= Spring.GetGaiaTeamID() then
			teams[teamID] = teams[teamID] or {roster = {}}
			local _,leader,isDead,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID, false)
			if isAI then
				local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
				name = '<'.. name ..'> '.. shortName
				local entityID = #entities + 1
				entities[entityID] = {name = name, teamID = teamID, isAI = true}
				local index = #teams[teamID].roster + 1
				teams[teamID].roster[index] = entities[entityID]
			end
			teams[teamID].leader = leader
			allyTeams[allyTeamID] = allyTeams[allyTeamID] or {}
			allyTeams[allyTeamID][#allyTeams[allyTeamID]+1] = teamID
		end --if teamID ~= Spring.GetGaiaTeamID() 
	end --for each team

	-- go through all players, register as entities, assign to teams
	for i = 1, #playerlist do
		local playerID = playerlist[i]
		local name, active, spectator, teamID, allyTeamID, pingTime, cpuUsage, country = Spring.GetPlayerInfo(playerID, false)
		local isSpec = (teamID == 0 and spectator and Spring.GetPlayerRulesParam(playerID, "initiallyPlayingPlayer") ~= 1)
		local entityID = #entities + 1
		entities[entityID] = {name = name, isSpec = isSpec, playerID = playerID, teamID = teamID}--(not spectator) and teamID or nil}
		if not isSpec then
			local index = #teams[teamID].roster + 1
			teams[teamID].roster[index] = entities[entityID]
		end
		if active and spectator then
			specTeam.roster[#(specTeam.roster) + 1] = entities[entityID]
		end
	end
	
	-- sort allyteams: own at top, others in order
	table.sort(allyTeamsSorted, 
		function(a,b)
			if a == localAlliance then return true
			elseif b == localAlliance then return false end
			return a < b
		end
	)
	
	row = 1
	for i = 1, #allyTeamsSorted do
		AddAllyTeam(allyTeamsSorted[i])
	end

	if options.showSpecs.value and #specTeam.roster ~= 0 then
		teams[-1] = specTeam
		allyTeams[-1] = {-1}
		AddAllyTeam(-1)
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
			x=5, y=(fontsize+1) * (row + 0.5),
			height=fontsize * 1.5, width=160,
			caption = 'Place Restricted Zones',
			checked = WG.rzones.rZonePlaceMode,
			OnChange = { function(self) WG.rzones.rZonePlaceMode = not WG.rzones.rZonePlaceMode; end },
		} )
		row = row + 1.5
	end
	
	AlignScrollPanel()
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
		if (window_cpl.hidden) then --//don't update when window is hidden.
			return
		end
		if (lastSizeX ~= window_cpl.width or lastSizeY ~= window_cpl.height) then --//if user resize the player-list OR if the simple-color state have changed, then refresh the player list.
			AlignScrollPanel()
			lastSizeX = window_cpl.width
			lastSizeY = window_cpl.height
		else
			if showWins ~= CheckShowWins() then
				SetupPlayerNames()
			end
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

-- workaround for stupidity
function widget:GameStart()
	SetupPlayerNames()
end
-----------------------------------------------------------------------

function widget:Initialize()
	if not WG.Chili then
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

	-- Set the size for the default settings.
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local x_bound = 310
	
	window_cpl = Window:New{  
		dockable = true,
		name = "Player List",
		color = {0,0,0,0},
		right = 0,  
		bottom = 0,
		width  = x_bound,
		height = 150,
		padding = {8, 2, 2, 2};
		--autosize   = true;
		parent = screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		parentWidgetName = widget:GetInfo().name, --for gui_chili_docking.lua (minimize function)
		minWidth = x_bound,
	}
	scroll_cpl = ScrollPanel:New{
		parent = window_cpl,
		width = "100%",
		maxWidth = x_bound, --in case window_cpl is upsized to ridiculous size
		--height = "100%",
		backgroundColor  = {1,1,1,options.backgroundOpacity.value},
		borderColor = {1,1,1,options.backgroundOpacity.value},
		--padding = {0, 0, 0, 0},
		--autosize = true,
		scrollbarSize = 6,
		horizontalScrollbar = false,
		ignoreMouseWheel = not options.mousewheel.value,
		NCHitTest = function(self,x,y)
			local alt,ctrl, meta,shift = Spring.GetModKeyState()
			local _,_,lmb,mmb,rmb = Spring.GetMouseState()
			if (shift or ctrl or alt) or (mmb or rmb) or ((not self.tooltip or self.tooltip=="") and not (meta and lmb))  then --hover over window will intercept mouse, pressing right-mouse or middle-mouse or shift or ctrl or alt will stop intercept
				return false 
			end
			return self --mouse over panel
		end,	
		OnMouseDown={ function(self)
			local alt, ctrl, meta, shift = Spring.GetModKeyState()
			if not meta then return false end
			WG.crude.OpenPath(options_path)
			WG.crude.ShowMenu()
			return true
		end },
	}
	
	function scroll_cpl:IsAboveVScrollbars(x, y)  -- this override default Scrollpanel's HitTest. It aim to: reduce chance of click stealing. It exclude any modifier key (shift,alt,ctrl, except spacebar which is used for Space+click shortcut), and only allow left-click to reposition the vertical scrollbar
		local alt,ctrl, meta,shift = Spring.GetModKeyState()
		if (x< self.width - self.scrollbarSize) or (shift or ctrl or alt) or (not select(3,Spring.GetMouseState())) then 
			return false 
		end
		return self
	end

	SetupPlayerNames()
	
	Spring.SendCommands({"info 0"})
	lastSizeX = window_cpl.width
	lastSizeY = window_cpl_height
	
	WG.LocalColor = WG.LocalColor or {}
	WG.LocalColor.listeners = WG.LocalColor.listeners or {}
	WG.LocalColor.listeners["Chili Crude Playerlist"] = SetupPlayerNames
end

function widget:Shutdown()
	if WG.LocalColor and WG.LocalColor.listeners then
		WG.LocalColor.listeners["Chili Crude Playerlist"] = nil
	end
end

