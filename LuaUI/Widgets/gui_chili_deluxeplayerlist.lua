--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Chili Deluxe Player List - Alpha 2.02",
    desc      = "v0.210 Chili Deluxe Player List, Alpha Release",
    author    = "CarRepairer, KingRaptor, CrazyEddie",
    date      = "2012-06-30",
    license   = "GNU GPL, v2 or later",
    layer     = 50,
    enabled   = false,
    -- based on v1.31 Chili Crude Player List by CarRepairer, KingRaptor, et al
  }
end

--[[
TODO:
 * Fast-and-Easy switching between large and small views, and between a single view hidden or shown
 * More granular control over which columns are displayed, and how (text vs. icons, etc)
 * More and better tooltips, and options for controlling whether and how they are displayed
 * Scaling x-axis dimensions proportionally with the fontsize
 * Double-click on resource bars to share resources with allies
 * Profiling and improving performance
 * Tons of minor bugfixes, cosmetic enhancements, and code cleanup
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/constants.lua")
VFS.Include ("LuaRules/Utilities/lobbyStuff.lua")

function SetupPlayerNames() end
function ToggleVisibility() end

local echo = Spring.Echo
local spGetUnitIsStunned = Spring.GetUnitIsStunned
local spGetTeamRulesParam = Spring.GetTeamRulesParam

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

options_path = 'Settings/HUD Panels/Player List'
options_order = { 'visible', 'backgroundOpacity', 'reset_wins', 'inc_wins_1', 'inc_wins_2','win_show_condition', 'text_height', 'name_width', 'stats_width', 'income_width', 'mousewheel', 'alignToTop', 'alignToLeft', 'showSummaries', 'show_stats', 'colorResourceStats', 'show_ccr', 'show_cpu_ping', 'cpu_ping_as_text', 'show_tooltips', 'list_size'}
options = {
	visible = {
		name = "Visible",
		type = 'bool',
		value = true,
		desc = "Set a hotkey here to toggle the playerlist on and off",
		OnChange = function() ToggleVisibility() end,
	},
	backgroundOpacity = {
		name = "Background Opacity",
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
		if WG.WinCounter_Reset ~= nil then WG.WinCounter_Reset() end 
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
		OnChange = function() SetupPanels() end,
	},
	text_height = {
		name = 'Font Size (10-18)',
		type = 'number',
		value = 13,
		min=10,max=18,step=1,
		OnChange = function() SetupPanels() end,
		advanced = true
	},
	name_width = {
		name = 'Name Width (50-200)',
		type = 'number',
		value = 120,
		min=50,max=200,step=10,
		OnChange = function() SetupPanels() end,
		advanced = true
	},
	stats_width = {
		name = 'Metal worth stats width (2-5)',
		type = 'number',
		value = 4,
		min=2,max=5,step=1,
		OnChange = function() SetupPanels() end,
		advanced = true
	},
	income_width = {
		name = 'Income width (2-5)',
		type = 'number',
		value = 3,
		min=2,max=5,step=1,
		OnChange = function() SetupPanels() end,
		advanced = true
	},
	mousewheel = {
		name = "Scroll with mousewheel",
		type = 'bool',
		value = false,
		OnChange = function(self) 
				scroll_cpl.ignoreMouseWheel = not self.value;
			end,
	},
	alignToTop = {
		name = "Align to top",
		type = 'bool',
		value = false,
		desc = "Align to top and grow downwards (vs. align to bottom and grow upwards)",
		OnChange = function() SetupPlayerNames() end,
	},
	alignToLeft = {
		name = "Align to left",
		type = 'bool',
		value = false,
		desc = "Align to left and grow rightwards (vs. align to right and grow leftwards)",
		OnChange = function() SetupScrollPanel() end,
	},
	showSummaries = {
		name = "Show team summaries",
		type = 'bool',
		value = true,
		desc = "Display summary information for each team (note: even with this checked, summaries won't be displayed if all the teams are very small)",
		OnChange = function() SetupPlayerNames() end,
	},
	show_stats = {
		name = "Show unit and income stats",
		type = 'bool',
		value = true,
		desc = "Display resource statistics: metal in mobile units and static defenses; metal and energy income.",
		OnChange = function() SetupPanels() end,
	},
	colorResourceStats = {
		name = "Show stats in color",
		type = 'bool',
		value = false,
		desc = "Display resource statistics such as unit metal and income in each player's color (vs. white)",
		OnChange = function() SetupPlayerNames() end,
	},
	show_ccr = {
		name = "Show clan/country/rank",
		type = 'bool',
		value = true,
		desc = "Show the clan, country, and rank columns",
		OnChange = function() SetupPanels() end,
	},
	show_cpu_ping = {
		name = "Show ping and cpu",
		type = 'bool',
		value = true,
		desc = "Show player's ping and cpu",
		OnChange = function() SetupPanels() end,
	},
	cpu_ping_as_text = {
		name = "Show ping/cpu as text",
		type = 'bool',
		value = false,
		desc = "Show ping and cpu stats as text (vs. as an icon)",
		OnChange = function() SetupPanels() end,
	},
	show_tooltips = {
		name = "Show tooltips",
		type = 'bool',
		value = true,
		desc = "Show tooltips where available (vs. hiding all tooltips. Note: tooltip might block mouse click in some cases)",
		OnChange = function() SetupPanels() end,
	},
	list_size = {
		name = 'List Size: Who should be included?',
		type = 'list',
		value = 3,
		items = {
				{ key = 0, name = "Nobody" },
				{ key = 1, name = "Just you" },
				{ key = 2, name = "Just your team" },
				{ key = 3, name = "All players" },
				{ key = 4, name = "All players and spectators" },
		},
		OnChange = function() SetupPlayerNames() end,
	},
}

local name_width
local showWins = false
local wins_width

local green		= ''
local red		= ''
local orange	= ''
local yellow	= ''
local cyan		= ''
local white		= ''

local IsMission
if VFS.FileExists("mission.lua") then
	IsMission = true
else
	IsMission = false
end

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

-- The ceasefire functionality isn't working right now.
-- I'm leaving all the code in place, but disabling the buttons.
-- Someone can come back in and fix it later.
--
local cf = (not Spring.FixedAllies()) and IsFFA()
--local cf = false

local localTeam = 0
local localAlliance = 0
local myID
local myName
local amSpec

myID = Spring.GetMyPlayerID()
myName,_,amSpec = Spring.GetPlayerInfo(myID, false)
localTeam = Spring.GetMyTeamID()
localAlliance = Spring.GetMyAllyTeamID()

-- This is awkward, but it's okay for now.
-- I'll make it elegant when I implement x-scaling with fontsize
--
local x_icon_clan
local x_icon_country
local x_icon_rank
local x_cf
local x_status
local x_name
local x_teamsize
local x_teamsize_dude
local x_share
local x_m_mobiles
local x_m_defense
local x_m_income
local x_e_income
local x_m_fill
local x_e_fill
local x_cpu
local x_ping
local x_postping
local x_bound
local x_windowbound

local x_m_mobiles_width
local x_m_defense_width
local x_m_income_width
local x_e_income_width

local function CheckShowWins()
	return WG.WinCounter_currentWinTable ~= nil and (WG.WinCounter_currentWinTable.hasWins and options.win_show_condition.value == "whenRelevant") or options.win_show_condition.value == "always"
end

local function CalculateWidths()
	wins_width = 0
	if showWins then wins_width = (options.text_height.value * 3 + 10) end
	name_width = options.name_width.value or 120
	x_icon_clan		= wins_width + 10
	x_icon_country	= x_icon_clan + 18
	x_icon_rank		= x_icon_country + 20
	x_cf			= options.show_ccr.value and x_icon_rank + 16 or x_icon_clan
	x_status		= cf and x_cf + 20 or x_cf
	x_name			= x_status + 12
	x_teamsize		= x_icon_clan
	x_teamsize_dude	= x_icon_rank 
	x_share			= x_name + name_width
	x_m_mobiles		= not amSpec and x_share + 12 or x_share
	x_m_mobiles_width = options.stats_width.value * options.text_height.value / 2 + 10
	x_m_defense		= x_m_mobiles + x_m_mobiles_width -- + 34
	x_m_defense_width = options.stats_width.value * options.text_height.value / 2 + 10
	x_m_income		= x_m_defense + x_m_defense_width
	x_m_income_width = options.income_width.value * options.text_height.value / 2 + 10
	x_e_income		= x_m_income + x_m_income_width
	x_e_income_width = options.income_width.value * options.text_height.value / 2 + 10
	x_m_fill		= options.show_stats.value and x_e_income + x_e_income_width or x_m_mobiles
	x_e_fill		= x_m_fill + 30
	x_cpu			= x_e_fill + (options.show_cpu_ping.value and (options.cpu_ping_as_text.value and 52 or 30) or 0)
	x_ping			= x_cpu + (options.show_cpu_ping.value and (options.cpu_ping_as_text.value and 46 or 16) or 10)
	x_bound			= x_ping + 28
	x_windowbound	= x_bound + 0
end
CalculateWidths()

local UPDATE_FREQUENCY = 0.8	-- seconds

local cfCheckBoxes = {}

local allyTeams = {}	-- [id] = {team1, team2, ...}
local teams = {}	-- [id] = {leaderName = name, roster = {entity1, entity2, ...}}
local teamZeroPlayers = {}

-- entity = player (including specs) or bot
-- ordered list; contains isAI, isSpec, playerID, teamID, name, namelabel, cpuImg, pingImg
local entities = {}
local allyTeamEntities = {}
local allyTeamOrderRank = {}
local allyTeamsDead = {}
local allyTeamsElo = {}
local playerTeamStatsCache = {}
local finishedUnits = {}
local numBigTeams = 0
local existsVeryBigTeam = nil
local myTeamIsVeryBig = nil
local specTeam = {roster = {}}

local sharePic        = ":n:"..LUAUI_DIRNAME.."Images/playerlist/share.png"
local cpuPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/cpu.png"
local pingPic		  = ":n:"..LUAUI_DIRNAME.."Images/playerlist/ping.png"

local row
local fontsize
local list_size
local timer = 0
local lastSizeX
local lastSizeY
local lastChosenSizeX = 0
include("keysym.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ShareUnits(playername, team)
	local selcnt = Spring.GetSelectedUnitsCount()
	if selcnt > 0 then
		Spring.SendCommands("say a: I gave "..selcnt.." units to "..playername..".")
		Spring.ShareResources(team, "units")     
	else
		echo 'Player List: No units selected to share.'
	end
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

local function FormatPingCpu(ping,cpu)
	-- guard against being called with nils
	ping = ping or 0
	cpu = cpu or 0
	-- guard against silly values
	ping = math.max(math.min(ping,999),0)
	cpu = math.max(math.min(cpu,9.99),0)

	local pingMult = 2/3	-- lower = higher ping needed to be red
	local pingCpuColors = {
		{0, 1, 0, 1},
		{0.7, 1, 0, 1},
		{1, 1, 0, 1},
		{1, 0.6, 0, 1},
		{1, 0, 0, 1}
	}

	local pingCol = pingCpuColors[ math.ceil( math.min(ping * pingMult, 1) * 5) ] or {.85,.85,.85,1}
	local cpuCol = pingCpuColors[ math.ceil( math.min(cpu, 1) * 5 ) ] or {.85,.85,.85,1}

	local pingText
	if ping < 1 then
		pingText = (math.floor(ping*1000) ..'ms')
	else
		pingText = ('' .. (math.floor(ping*100)/100)):sub(1,4) .. 's'
	end

	local cpuText = math.round(cpu*100) .. '%'
	
	return pingCol,cpuCol,pingText,cpuText
end

local function FormatMetalStats(stat,k)
--	if k then
--		stat = 1000 * math.floor((stat/1000) + .5)
--		return string.format("%.0f", stat/1000) .. "k"
--	else
--		stat = 50 * math.floor((stat/50) + .5)
		return stat < 1000
			and string.format("%.0f", stat)
			or string.format("%.1f", stat/1000) .. "k"
--	end
end

local function FormatElo(elo,full)
	local mult = full and 1 or 10
	local elo_out = mult * math.floor((elo/mult) + .5)
	local eloCol = {}

	-- FIXME mismatch with rank colours
	local top = 1800
	local mid = 1600
	local bot = 1400
	local tc = {1,1,1,1}
	local mc = {1,1,.2,1}
	local bc = {1,.4,.3,1}
	
	if elo_out >= top then eloCol = tc
	elseif elo_out >= mid then
		local r = (elo_out-mid)/(top-mid)
		for i = 1,4 do
			eloCol[i] = (r * tc[i]) + ((1-r) * mc[i])
		end
	elseif elo_out >= bot then
		local r = (elo_out-bot)/(mid-bot)
		for i = 1,4 do
			eloCol[i] = (r * mc[i]) + ((1-r) * bc[i])
		end
	else eloCol = bc
	end

	return elo_out, eloCol
end

local function FormatWins(name) --Assumes Win Counter is on and all tables are valid, and the given name is in the wins table
	local winCount = WG.WinCounter_currentWinTable[name].wins
	if WG.WinCounter_currentWinTable[name].wonLastGame then
		return "*"..winCount.."*"
	end
	return winCount
end

local function ProcessUnit(unitID, unitDefID, unitTeam, remove)
	local stats = playerTeamStatsCache[unitTeam]
	if UnitDefs[unitDefID] and stats then -- shouldn't need to guard against nil here, but I've had it happen
		local metal = Spring.Utilities.GetUnitCost(unitID, unitDefID)
		local unarmed = UnitDefs[unitDefID].springCategories.unarmed
		local isbuilt = not select(3, spGetUnitIsStunned(unitID))	
		if metal and metal < 1000000 then -- tforms show up as 1million cost, so ignore them
			if remove then
				metal = -metal
			end
			-- for mobiles, count only completed units
			if not UnitDefs[unitDefID].isImmobile then
				if remove then
					finishedUnits[unitID] = nil
					stats.mMobs = stats.mMobs + metal
					-- [f=0087651] [cawidgets.lua] Error: Error in UnitGiven(): [string "LuaUI/Widgets/gui_chili_deluxeplayerlist.lu..."]:410: attempt to index local 'stats' (a nil value)
				elseif isbuilt then
					finishedUnits[unitID] = true
					stats.mMobs = stats.mMobs + metal
				end
			-- for static defense, include full cost of unfinished units so you can see when your teammates are trying to build too much
			elseif not unarmed then
				stats.mDefs = stats.mDefs + metal
			end
		end
	end
end

local function GetPlayerTeamStats(teamID)
	if not playerTeamStatsCache[teamID] then
		playerTeamStatsCache[teamID] = {mMobs = 0, mDefs = 0}
		local units = Spring.GetTeamUnits(teamID)
		for i=1,#units do
			local unitID = units[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			ProcessUnit(unitID, unitDefID, teamID)
		end
	end
	
	local stats = playerTeamStatsCache[teamID]
	
	local eCurr, eStor, ePull, eInco, eExpe, eShar, eSent, eReci = Spring.GetTeamResources(teamID, "energy")
	local mCurr, mStor, mPull, mInco, mExpe, mShar, mSent, mReci = Spring.GetTeamResources(teamID, "metal")

	if eInco then	
		local energyIncome = spGetTeamRulesParam(teamID, "OD_energyIncome") or 0
		local energyChange = spGetTeamRulesParam(teamID, "OD_energyChange") or 0
		eInco = eInco + energyIncome - math.max(0, energyChange)
	end
	
	if mStor then
		mStor = mStor - HIDDEN_STORAGE
	end
	if eStor then
		eStor = eStor - HIDDEN_STORAGE					-- eStor has a "hidden 10k" to account for
		if eStor > 50000 then eStor = 1000 end	-- fix for weirdness where sometimes storage is reported as huge, assume it should be 1000
	end
	-- guard against dividing by zero later, when the fill bar percentage is calculated
	-- these probably aren't ever going to be zero, but better safe than sorry
	if mStore and mStore == 0 then mStore = 1000 end
	if eStore and eStore == 0 then eStore = 1000 end

	-- Default these to 1 if the value is nil for some reason.
	-- These should never be 1 in normal play, so if you see
	--   them showing up as 1 then that means that something got nil,
	--   which should perhaps then be looked into further.
	-- Whereas it's quite reasonable for them to sometimes be zero.
	stats.mInco = mInco or 1
	stats.eInco = eInco or 1
	stats.mCurr = mCurr or 1
	stats.mStor = mStor or 1
	stats.eCurr = eCurr or 1
	stats.eStor = eStor or 1
	
	return playerTeamStatsCache[teamID]
end

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


local function MakeSpecTooltip()

	if (not options.show_tooltips.value) or list_size == 4 or (list_size == 3 and #specTeam.roster == 0) then
		scroll_cpl.tooltip = nil
		return
	end
	
	local windowTooltip
	local players = {}
	local spectators = {}

	local playerlist = Spring.GetPlayerList()
	for i=1, #playerlist do
		local playerID = playerlist[i]
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,rank = Spring.GetPlayerInfo(playerID, false)
		local pingCol, cpuCol, pingText, cpuText = FormatPingCpu(pingTime,cpuUsage)
		local cpuColChar = GetColorChar(cpuCol)
		local pingColChar = GetColorChar(pingCol)
		if active and not spectator then
			players[#players+1] = { name = name, pingText = pingText, cpuText = cpuText, pingColChar = pingColChar, cpuColChar = cpuColChar }
		elseif spectator then
			spectators[#spectators+1] = { name = name, pingText = pingText, cpuText = cpuText, pingColChar = pingColChar, cpuColChar = cpuColChar }
		end
	end
	
	table.sort (players, function(a,b)
			return a.name:lower() < b.name:lower()
		end
	)

	table.sort (spectators, function(a,b)
			return a.name:lower() < b.name:lower()
		end
	)

	if list_size <= 2 then
		windowTooltip = windowTooltip or "PLAYERS"
		for i=1, #players do
			windowTooltip = windowTooltip .. "\n\t"..players[i].name.."\t"..players[i].cpuColChar..(players[i].cpuText)..'\008' .. "\t"..players[i].pingColChar..(players[i].pingText).."\008"
		end
	end

	if #spectators ~= 0 then
		windowTooltip = windowTooltip and (windowTooltip .. "\n\n") or ""
		windowTooltip = windowTooltip .. "SPECTATORS"
		for i=1, #spectators do
			windowTooltip = windowTooltip .. "\n\t"..spectators[i].name.."\t"..spectators[i].cpuColChar..(spectators[i].cpuText)..'\008' .. "\t"..spectators[i].pingColChar..(spectators[i].pingText).."\008"
		end
	end

	scroll_cpl.tooltip = windowTooltip --tooltip in display region only (window_cpl have soo much waste space)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function MakeNewLabel(entity,name,o) -- "o" is for options
	-- pass in x, width, caption, textColor
	-- pass in any optional params like align
	-- pass in anything to override these defaults:
	o.y 			= o.y 			or (fontsize+1) * row
	o.fontsize		= o.fontsize 	or fontsize
	o.fontShadow	= o.fontShadow 	or true
	o.autosize 		= o.autosize 	or false

	local newLabel = Label:New(o)
	entity[name] = newLabel
	scroll_cpl:AddChild(newLabel)
end

local function MakeNewBar(entity,name,o)
	-- pass in x, width, color, value
	-- pass in anything to override these defaults:
	o.y				= o.y			or ((fontsize+1) * row) + 6
	o.height		= o.height		or 5
	o.min 			= o.min 		or 0
	o.max 			= o.max 		or 1
	o.autosize 		= o.autosize 	or false

	local newBar = Chili.Progressbar:New(o)
	entity[name] = newBar
	scroll_cpl:AddChild(newBar)
end

local function MakeNewIcon(entity,name,o)
	-- pass in x, file
	-- pass in anything to override these defaults:
	o.y				= o.y			or ((fontsize+1) * row) + 2
	o.width			= o.width		or fontsize + 3
	o.height		= o.height		or fontsize + 3
	
	o.tooltip = options.show_tooltips.value and o.tooltip or nil

	local newIcon = Chili.Image:New(o)
	entity[name] = newIcon
	scroll_cpl:AddChild(newIcon)
end

local function AccumulatePlayerTeamStats(r,s)
	r.eCurr = r.eCurr + s.eCurr
	r.eStor = r.eStor + s.eStor
	r.eInco = r.eInco + s.eInco
	r.mCurr = r.mCurr + s.mCurr
	r.mStor = r.mStor + s.mStor
	r.mInco = r.mInco + s.mInco
	r.mMobs = r.mMobs + s.mMobs
	r.mDefs = r.mDefs + s.mDefs
end

local function DrawPlayerTeamStats(entity,teamcolor,s)
	if not options.colorResourceStats.value then teamcolor = {.85,.85,.85,1} end
	if options.show_stats.value then
		MakeNewLabel(entity,"m_mobilesLabel",{x=x_m_mobiles,width=x_m_mobiles_width,caption = FormatMetalStats(s.mMobs,true),textColor = teamcolor,align = 'right',})
		MakeNewLabel(entity,"m_defenseLabel",{x=x_m_defense,width=x_m_defense_width,caption = FormatMetalStats(s.mDefs),textColor = teamcolor,align = 'right',})
		MakeNewLabel(entity,"m_incomeLabel",{x=x_m_income,width=x_m_income_width,caption = string.format("%." .. (0) .. "f", s.mInco),textColor = teamcolor,align = 'right',})
		MakeNewLabel(entity,"e_incomeLabel",{x=x_e_income,width=x_e_income_width,caption = string.format("%." .. (0) .. "f", s.eInco),textColor = teamcolor,align = 'right',})
	end
	MakeNewBar(entity,"m_fillBar",{x=x_m_fill + 6,width=24,color = {.7,.75,.9,1},value = s.mCurr/s.mStor,})
	MakeNewBar(entity,"e_fillBar",{x=x_e_fill + 2,width=24,color = {1,1,0,1},    value = s.eCurr/s.eStor,})
end

local function UpdatePlayerTeamStats(entity,s)
	if entity.m_mobilesLabel then entity.m_mobilesLabel:SetCaption(FormatMetalStats(s.mMobs,true)) end
	if entity.m_defenseLabel then entity.m_defenseLabel:SetCaption(FormatMetalStats(s.mDefs)) end
	if entity.e_incomeLabel then entity.e_incomeLabel:SetCaption(string.format("%." .. (0) .. "f", s.eInco)) end
	if entity.m_incomeLabel then entity.m_incomeLabel:SetCaption(string.format("%." .. (0) .. "f", s.mInco)) end
	if entity.m_fillBar then entity.m_fillBar:SetValue(s.mCurr/s.mStor) end
	if entity.e_fillBar then entity.e_fillBar:SetValue(s.eCurr/s.eStor) end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UpdatePingCpu(entity,pingTime,cpuUsage,pstatus)
	if options.show_cpu_ping.value then
		pingTime = pingTime or 0
		cpuUsage = cpuUsage or 0
		if pstatus == 'gone' then
			pingTime = 0
			cpuUsage = 0
		end
		local pingCol, cpuCol, pingText, cpuText = FormatPingCpu(pingTime,cpuUsage)
		if options.cpu_ping_as_text.value then
			if entity.cpuLabel then	entity.cpuLabel.font:SetColor(cpuCol) ; entity.cpuLabel:SetCaption(cpuText) end
			if entity.pingLabel then entity.pingLabel.font:SetColor(pingCol) ; entity.pingLabel:SetCaption(pingText) end
		else
			if entity.cpuImg then
				entity.cpuImg.color = cpuCol
				if options.show_tooltips.value then entity.cpuImg.tooltip = ('CPU: ' .. cpuText) end
				entity.cpuImg:Invalidate()
			end
			if entity.pingImg then
				entity.pingImg.color = pingCol
				if options.show_tooltips.value then entity.pingImg.tooltip = ('Ping: ' .. pingText) end
				entity.pingImg:Invalidate()
			end
		end
	end
end

-- updates as needed: status, name, ping, cpu, resource stats, etc.
local function UpdatePlayerInfo()
	for i=1,#entities do
		local teamID
		if entities[i].isAI then
			teamID = entities[i].teamID
		else
			local playerID = entities[i].playerID
			local name,active,spectator,localteamID,allyTeamID,pingTime,cpuUsage = Spring.GetPlayerInfo(playerID, false)
			teamID = localteamID
			local teamcolor = teamID and {Spring.GetTeamColor(teamID)} or {1,1,1,1}
			
			-- status (player status and team status)
			local pstatus = nil
			local tstatus = ''
			local tstatuscolor = {1,1,1,1}

			if not active then
				if Spring.GetGameSeconds() < 0.1 or cpuUsage > 1 then tstatus = '?' ; tstatuscolor = teamcolor
				else pstatus = 'gone'
				end
			elseif spectator and (teamID ~= 0 or teamZeroPlayers[playerID]) then
				pstatus = 'spec'
			end

			if pstatus == 'spec' or pstatus == 'gone' then
				if Spring.GetTeamUnitCount(teamID) > 0  then
					tstatus = '!!'
					tstatuscolor = {1,1,0,1}
				else
					tstatus = 'X'
					tstatuscolor = {1,0,0,1}
				end
			end

			local displayname
			local whitestring = GetColorChar({1,1,1,1})
			local greystring = GetColorChar({.5,.5,.5,1})
			local teamcolorstring = GetColorChar(teamcolor)
			-- these were part of a failed experiment that I might try to fix later

			if pstatus == 'spec' then displayname = (" ss: " .. name)
			elseif pstatus == 'gone' then displayname = (" xx: " .. name)
			else displayname = (name)
			end

			if entities[i].nameLabel then entities[i].nameLabel:SetCaption(displayname) end
			if entities[i].statusLabel then entities[i].statusLabel:SetCaption(tstatus) ; entities[i].statusLabel.font:SetColor(tstatuscolor) end
			if entities[i].winsLabel and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[name] ~= nil then 
				entities[i].winsLabel:SetCaption(FormatWins(name)) 
			end

			UpdatePingCpu(entities[i],pingTime,cpuUsage,pstatus)
		end	-- if not isAI

		-- update the resource stats for all entities, including AIs
		local s = GetPlayerTeamStats(teamID)
		UpdatePlayerTeamStats(entities[i],s)

	end	-- for entities

	-- update ping and cpu for the spectators
	if #specTeam.roster ~= 0 then
		for i = 1,#specTeam.roster do
			local playerID = specTeam.roster[i].playerID
			local name,active,spectator,localteamID,allyTeamID,pingTime,cpuUsage = Spring.GetPlayerInfo(playerID, false)
			specTeam.roster[i].pingTime = pingTime
			specTeam.roster[i].cpuUsage = cpuUsage
			if list_size == 4 then
				UpdatePingCpu(specTeam.roster[i],pingTime,cpuUsage)
			end
		end
	end
	MakeSpecTooltip()

	for allyTeam, cb in pairs(cfCheckBoxes) do
		cb.tooltip = CfTooltip(allyTeam)
	end

	-- update resource totals for the allyTeams
	if allyTeamEntities then
		for k,v in pairs(allyTeamEntities) do
			local r = { eCurr = 0, eStor = 0, eInco = 0, mCurr = 0, mStor = 0, mInco = 0, mMobs = 0, mDefs = 0 }
			if allyTeams[k] then
				for j=1,#allyTeams[k] do
					local teamID = allyTeams[k][j]
					if teamID then
						local s = GetPlayerTeamStats(teamID)
						AccumulatePlayerTeamStats(r,s)
						local _,leader = Spring.GetTeamInfo(teamID, false)
						local name = Spring.GetPlayerInfo(leader, false)
						if v.winsLabel and name ~= nil and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[name] ~= nil then
							v.winsLabel:SetCaption(FormatWins(name)) 
						end
					end
				end
			end
			UpdatePlayerTeamStats(v,r)
		end
	end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function AddTableHeaders()
	if cf then
		scroll_cpl:AddChild( Label:New{ x=x_cf,	y=(fontsize+1) * row,	caption = 'CF',		fontShadow = true, 	fontsize = fontsize, } )
	end
	if options.show_stats.value then
		scroll_cpl:AddChild( Image:New{ x=x_m_mobiles - 10, y=((fontsize+1) * row) + 3,	height = (fontsize)+1, color =	{1, .3, .3, 1},  file = 'LuaUI/Images/commands/Bold/attack.png',} )
		scroll_cpl:AddChild( Image:New{ x=x_m_defense - 7, y=((fontsize+1) * row) + 3,	height = (fontsize)+1, color = {.3, .3, 1, 1}, file = 'LuaUI/Images/commands/Bold/guard.png',} )
		scroll_cpl:AddChild( Image:New{ x=x_e_income - 15, y=((fontsize+1) * row) + 3,	height = (fontsize)+1,  file = 'LuaUI/Images/energyplus.png',} )
		scroll_cpl:AddChild( Image:New{ x=x_m_income - 15, y=((fontsize+1) * row) + 3,	height = (fontsize)+1, file = 'LuaUI/Images/metalplus.png',} )
	end
	if options.show_cpu_ping.value then
		scroll_cpl:AddChild( Label:New{ x=x_cpu, y=(fontsize+1) * row,	caption = 'C', 	fontShadow = true,  fontsize = fontsize,} )
		scroll_cpl:AddChild( Label:New{ x=x_ping, y=(fontsize+1) * row,	caption = 'P', 	fontShadow = true,  fontsize = fontsize,} )
	end
	if showWins then scroll_cpl:AddChild( Label:New{ x=0, width = wins_width, y=(fontsize+1) * row,	caption = 'Wins', 	fontShadow = true,  fontsize = fontsize, align = "right"} ) end
end

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

-- adds all the entity information
local function AddEntity(entity, teamID, allyTeamID)
	local teamcolor = (teamID and teamID ~= -1) and {Spring.GetTeamColor(teamID)} or {1,1,1,1}

	if entity.isAI then
		MakeNewLabel(entity,"nameLabel",{x=x_name,width=name_width,caption = entity.name,textColor = teamcolor,})

	else

		-- clan/faction emblems, level, country, elo
		local icon = nil
		local icRank = nil 
		local elo = nil
		local eloCol = nil
		local icCountry = entity.country and entity.country ~= '' and entity.country ~= '??' and "LuaUI/Images/flags/" .. (entity.country) .. ".png" or nil
		if options.show_ccr.value then
			if entity.clan and entity.clan ~= "" then 
				icon = "LuaUI/Configs/Clans/" .. entity.clan ..".png"
			elseif entity.faction and entity.faction ~= "" then
				icon = "LuaUI/Configs/Factions/" .. entity.faction ..".png"
			end
			icRank = "LuaUI/Images/LobbyRanks/" .. (entity.rank or "0_0") .. ".png"
			if icCountry then MakeNewIcon(entity,"countryIcon",{x=x_icon_country,file=icCountry,}) end 
			if icRank then MakeNewIcon(entity,"rankIcon",{x=x_icon_rank,file=icRank,}) end
			if icon then MakeNewIcon(entity,"clanIcon",{x=x_icon_clan,file=icon,y=((fontsize+1)*row)+5,width=fontsize-1,height=fontsize-1}) end 
		end

		-- status (player status and team status)
		local pstatus = nil
		local tstatus = ''
		local tstatuscolor = {1,1,1,1}

		if teamID ~= -1 then
			if not entity.isActive then
				if Spring.GetGameSeconds() < 0.1 or entity.cpuUsage > 1 then tstatus = '?' ; tstatuscolor = teamcolor
				else pstatus = 'gone'
				end
			elseif entity.isSpec and (teamID ~= 0 or teamZeroPlayers[entity.playerID]) then
				pstatus = 'spec'
			end
		end

		if pstatus == 'spec' or pstatus == 'gone' then
			if Spring.GetTeamUnitCount(teamID) > 0  then
				tstatus = '!!'
				tstatuscolor = {1,1,0,1}
			else
				tstatus = 'X'
				tstatuscolor = {1,0,0,1}
			end
		end

		MakeNewLabel(entity,"statusLabel",{x=x_status,width=16,caption = tstatus,textColor = tstatuscolor,})

		-- name, including player status designators
		local displayname
		local whitestring = GetColorChar({1,1,1,1})
		local greystring = GetColorChar({.5,.5,.5,1})
		local teamcolorstring = GetColorChar(teamcolor)
		-- these were part of a failed experiment that I might try to fix later

		if pstatus == 'spec' then displayname = (" ss: " .. entity.name)
		elseif pstatus == 'gone' then displayname = (" xx: " .. entity.name)
		else displayname = (entity.name)
		end

		MakeNewLabel(entity,"nameLabel",{x=x_name,width=name_width,caption = displayname,textColor = teamcolor,})

		-- ping and cpu icons / labels
		local pingCol, cpuCol, pingText, cpuText = FormatPingCpu(pstatus == 'gone' and 0 or entity.pingTime,pstatus == 'gone' and 0 or entity.cpuUsage)
		if options.show_cpu_ping.value then
			if options.cpu_ping_as_text.value then
				MakeNewLabel(entity,"cpuLabel",{x=x_cpu,width = (fontsize+3)*10/16,caption = cpuText,textColor = cpuCol,align = 'right',})
				MakeNewLabel(entity,"pingLabel",{x=x_ping,width = (fontsize+3)*10/16,caption = pingText,textColor = pingCol,align = 'right',})
			else
				MakeNewIcon(entity,"cpuImg",{x=x_cpu,file=cpuPic,width = (fontsize+3)*10/16,keepAspect = false,tooltip = 'CPU: ' .. cpuText,})
				MakeNewIcon(entity,"pingImg",{x=x_ping,file=pingPic,width = (fontsize+3)*10/16,keepAspect = false,tooltip = 'Ping: ' .. pingText,})
				entity.cpuImg.color = cpuCol
				entity.pingImg.color = pingCol
				function entity.cpuImg:HitTest(x,y) return self end
				function entity.pingImg:HitTest(x,y) return self end
			end
		end

		if showWins and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[entity.name] ~= nil then 
			MakeNewLabel(entity,"winsLabel",{x=0,width=wins_width,caption = FormatWins(entity.name),textColor = teamcolor, align = "right"})
		end

	end -- if not isAI

	-- share button
	if teamID ~= -1 and (teams[teamID] and (teams[teamID].isPlaying and not teams[teamID].isDead)) and allyTeamID == localAlliance and teamID ~= localTeam and not amSpec then
		scroll_cpl:AddChild(
			Button:New{
				x=x_share,
				y=(fontsize+1) * (row+0.5)-2.5,
				height = fontsize,
				width = fontsize,
				tooltip = options.show_tooltips.value and 'Double click to share selected units to ' .. entity.name or nil,
				caption = '',
				padding ={0,0,0,0},
				OnDblClick = { function(self) ShareUnits(entity.name, teamID) end, },
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

	-- mobile and defense metal, metal and energy income, resource bars
	if teamID ~= -1 and (allyTeamID == localAlliance or amSpec) then
		local s = GetPlayerTeamStats(teamID)
		DrawPlayerTeamStats(entity,teamcolor,s)
	end

	row = row + 1
end

local function AddAllAllyTeamSummaries(allyTeamsSorted)
	local allyTeamResources
	local allyTeamWins
	local allyTeamsNumActivePlayers = {}
	for i=1,#allyTeamsSorted do
		local allyTeamID = allyTeamsSorted[i]
		if allyTeams[allyTeamID] then
			allyTeamsNumActivePlayers[allyTeamID] = 0			
			for j=1,#allyTeams[allyTeamID] do
				local teamID = allyTeams[allyTeamID][j]
				if teamID then
					if not teams[teamID].isDead and teams[teamID].isPlaying then --and teams[teamID].isActive
						allyTeamsNumActivePlayers[allyTeamID] = allyTeamsNumActivePlayers[allyTeamID] + 1
					end
					local s = GetPlayerTeamStats(teamID)
					allyTeamResources = allyTeamResources or {}
					allyTeamResources[allyTeamID] = allyTeamResources[allyTeamID] or { eCurr = 0, eStor = 0, eInco = 0, mCurr = 0, mStor = 0, mInco = 0, mMobs = 0, mDefs = 0 }
					AccumulatePlayerTeamStats(allyTeamResources[allyTeamID],s)
				end
			end
		end
	end
	if allyTeamResources then
		for i=1,#allyTeamsSorted do
			local allyTeamID = allyTeamsSorted[i]
			if allyTeamResources[allyTeamID] and allyTeams[allyTeamID] then
				allyTeamEntities[allyTeamID] = allyTeamEntities[allyTeamID] or {}
				local allyTeamColor
				if (localTeam ~= 0 or teamZeroPlayers[myID]) and allyTeamID == localAlliance then
					allyTeamColor = {Spring.GetTeamColor(localTeam)}
				else
					allyTeamColor = {Spring.GetTeamColor(allyTeams[allyTeamID][1])}
				end
				local teamName = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID)
				if string.len(teamName) > 10 then
					teamName = Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID)
				end
				MakeNewLabel(allyTeamEntities[allyTeamID],"nameLabel",{x=x_name,width=150,caption = teamName,textColor = allyTeamColor,})
				MakeNewLabel(allyTeamEntities[allyTeamID],"teamsizeLabel", {x=x_teamsize,width=32,caption = (allyTeamsNumActivePlayers[allyTeamID] .. "/" .. #allyTeams[allyTeamID]), textColor = {.85,.85,.85,1}, align = "right"})
				DrawPlayerTeamStats(allyTeamEntities[allyTeamID],allyTeamColor,allyTeamResources[allyTeamID])
				MakeNewIcon(allyTeamEntities[allyTeamID],"teamsizeIcon", {x=x_teamsize_dude,file="LuaUI/Images/dude.png",})
				AddCfCheckbox(allyTeamID)
				if allyTeamsDead[allyTeamID] then MakeNewLabel(allyTeamEntities[allyTeamID],"statusLabel",{x=x_status,width=16,caption = "X",textColor = {1,0,0,1},}) end

				local _,leader = Spring.GetTeamInfo(allyTeams[allyTeamID][1], false)
				local leaderName = Spring.GetPlayerInfo(leader, false)

				if showWins and leaderName ~= nil and WG.WinCounter_currentWinTable ~= nil and WG.WinCounter_currentWinTable[leaderName] ~= nil then 
					MakeNewLabel(allyTeamEntities[allyTeamID],"winsLabel",{x=0,width=wins_width,caption = FormatWins(leaderName),textColor = allyTeamColor, align = "right"})
				end
				row = row + 1
			end
		end
	end
end

local function AlignScrollPanel()
	local height = math.ceil(row * (fontsize+1.5) + 8)
	scroll_cpl.height = math.min(height,window_cpl.height)
	if not (options.alignToTop.value) then
		scroll_cpl.y = (window_cpl.height) - scroll_cpl.height
	else
		scroll_cpl.y = 0
	end
end

function ToggleVisibility()
	if window_cpl and scroll_cpl then
		if options.visible.value then
			window_cpl:AddChild(scroll_cpl)
		else
			window_cpl:RemoveChild(scroll_cpl)
		end
	end
end

SetupPlayerNames = function()
	entities = {}
	teams = {}
	allyTeams = {}
	allyTeamsElo = {}
	
	specTeam = {roster = {}}
	playerTeamStatsCache = {}

	fontsize = options.text_height.value
	scroll_cpl:ClearChildren()
	
	local playerlist = Spring.GetPlayerList()
	local teamsSorted = Spring.GetTeamList()
	local allyTeamsSorted = Spring.GetAllyTeamList()
	
	list_size = options.list_size.value or 3
	if not (localTeam ~= 0 or teamZeroPlayers[myID]) then
		if list_size == 1 then list_size = 0 end
		if list_size == 2 then list_size = 3 end
	end

	-- register any AIs as entities, assign teams to allyTeams
	for i=1,#teamsSorted do
		local teamID = teamsSorted[i]
		if teamID ~= Spring.GetGaiaTeamID() then
			teams[teamID] = teams[teamID] or {roster = {}}
			local _,leader,isDead,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID, false)
			if isAI then
				local skirmishAIID, name, hostingPlayerID, shortName, version, options = Spring.GetAIInfo(teamID)
				if (IsMission == false) then
					name = '<'.. name ..'> '.. shortName
				end
				local entityID = #entities + 1
				entities[entityID] = {name = name, teamID = teamID, isAI = true}
				local index = #teams[teamID].roster + 1
				teams[teamID].roster[index] = entities[entityID]
				teams[teamID].isPlaying = true
			end
			teams[teamID].leader = leader
			allyTeams[allyTeamID] = allyTeams[allyTeamID] or {}
			allyTeams[allyTeamID][#allyTeams[allyTeamID]+1] = teamID
			if isDead then
				teams[teamID].isDead = true
			end
		end --if teamID ~= Spring.GetGaiaTeamID()
	end --for each team

	-- go through all players, register as entities, assign to teams
	-- also store the data needed later to calculate the team average elo
	for i=1, #playerlist do
		local playerID = playerlist[i]
		local name,active,spectator,teamID,allyTeamID,pingTime,cpuUsage,country,_,customKeys = Spring.GetPlayerInfo(playerID)
		local clan, faction, level, elo, wins, rank
		if customKeys then
			clan = customKeys.clan
			faction = customKeys.faction
			level = customKeys.level
			elo = customKeys.elo
			rank = customKeys.icon
		end

		if teamID == 0 and not spectator then
			teamZeroPlayers[playerID] = true
		end
		if teamID ~= 0 or teamZeroPlayers[playerID] then
			local entityID = #entities + 1
			entities[entityID] = {
				playerID = playerID,
				name = name,
				isActive = active,
				isSpec = spectator,
				teamID = teamID,
				pingTime = pingTime,
				cpuUsage = cpuUsage,
				country = country,
				rank = rank,
				clan = clan,
				faction = faction,
				level = level,
				elo = elo,
				wins = wins,
			}
			local index = #teams[teamID].roster + 1
			teams[teamID].roster[index] = entities[entityID]
			if not (spectator or (not active and Spring.GetGameSeconds() > 0.1 and cpuUsage < 1)) then
				teams[teamID].isPlaying = true
				if allyTeamID and elo then
					if allyTeamsElo[allyTeamID] then
						allyTeamsElo[allyTeamID].total = allyTeamsElo[allyTeamID].total + elo
						allyTeamsElo[allyTeamID].count = allyTeamsElo[allyTeamID].count + 1
					else
						allyTeamsElo[allyTeamID] = { ["total"] = elo, ["count"] = 1}
					end
				end
			end
		end
		if spectator and active then
			specTeam.roster[#(specTeam.roster) + 1] = {
				playerID = playerID,
				name = name,
				isActive = active,
				isSpec = spectator,
				teamID = teamID,
				pingTime = pingTime,
				cpuUsage = cpuUsage,
				country = country,
				rank = rank,
				clan = clan,
				faction = faction,
				level = level,
				elo = elo,
			}
		end

	end

	-- sort each playerteam's roster: self first, then by elo, and alphabetically otherwise
	for i=1,#teams do
		if teams[i].roster then
			table.sort (teams[i].roster, function(a,b)
					if localTeam ~= 0 or teamZeroPlayers[myID] then
						if a.playerID == myID then return true end
						if b.playerID == myID then return false end
					end
					if not a.elo then
						return false
					end
					if not b.elo then
						return true
					end
					return a.elo > b.elo
				end
			)
		end
	end

	-- sort each allyteam's list of playerteams:
	-- own pteam first, then by elo of the first player on the pteam, and alphabetically otherwise
	-- dead pteams (even your own) come after alive pteams
	-- dead pteams whose first player is speccing come before dead pteams whose first player is gone
	for i=1,#allyTeamsSorted do  -- for every ally team
		local allyTeamID = allyTeamsSorted[i]
		if allyTeams[allyTeamID] then
			table.sort(allyTeams[allyTeamID], 
				function(a,b)
					if not teams[a] or not teams[b] then
						Spring.Echo('<ChiliDeluxePlayerlist> Critical Error #1!')
						return a > b
					else
						if (teams[a].isDead or not teams[a].isPlaying) and not (teams[b].isDead or not teams[b].isPlaying) then
							return false
						end
						if (teams[b].isDead or not teams[b].isPlaying) and not (teams[a].isDead or not teams[a].isPlaying) then
							return true
						end
						if (teams[a].isDead or not teams[a].isPlaying) and (teams[b].isDead or not teams[b].isPlaying) then
							local aActive = teams[a].roster and teams[a].roster[1] and teams[a].roster[1].isActive
							local bActive = teams[b].roster and teams[b].roster[1] and teams[b].roster[1].isActive
							if aActive and not bActive then
								return true
							end
							if bActive and not aActive then
								return false
							end
						end
					if localTeam ~= 0 or teamZeroPlayers[myID] then
						if a == localTeam then
							return true
						end
						if b == localTeam then return
							false
						end
					end
					local aElo = teams[a].roster and teams[a].roster[1] and teams[a].roster[1].elo
					local bElo = teams[b].roster and teams[b].roster[1] and teams[b].roster[1].elo
					if aElo and bElo then
						return aElo > bElo
					end
					return a > b
				end
			end
			)
		end
	end
	
	-- if we haven't ever done so before, build the ally team sort order
	-- ally teams are sorted by total elo, so larger teams will be above smaller teams
	-- ally team sort order is determined at the very start, and doesn't change even if
	-- the team composition changes (except that dead teams will fall to the bottom)
	--
	-- while we're at it, determine whether or not to show the ally team summary lines
	--
	if #allyTeamOrderRank == 0 then
		if allyTeams[localAlliance] and #allyTeams[localAlliance] > 2 then
			myTeamIsVeryBig = true
		end
		for i=1,#allyTeamsSorted do  -- for every ally team
			local allyTeamID = allyTeamsSorted[i]
			allyTeamOrderRank[allyTeamID] = 0
			if allyTeams[allyTeamID] then
				if #allyTeams[allyTeamID] > 2 then existsVeryBigTeam = true end
				if #allyTeams[allyTeamID] > 1 then numBigTeams = numBigTeams + 1 end
				for j=1,#allyTeams[allyTeamID] do  -- for every player team on the ally team
					local teamID = allyTeams[allyTeamID][j]
					if teams[teamID] and teams[teamID].roster then
						for k=1,#teams[teamID].roster do -- for every player on the player team
							if teams[teamID].roster[k].elo then allyTeamOrderRank[allyTeamID] = allyTeamOrderRank[allyTeamID] + teams[teamID].roster[k].elo end
						end
					end
				end
			end
		end
	end

	-- find out which ally teams are dead
	allyTeamsDead = {}
	for i=1,#allyTeamsSorted do  -- for every ally team
		local allyTeamID = allyTeamsSorted[i]
		allyTeamsDead[allyTeamID] = true
		if allyTeams[allyTeamID] then
			for j=1,#allyTeams[allyTeamID] do  -- for every player team on the ally team
				local teamID = allyTeams[allyTeamID][j]
				if teams[teamID] and not (teams[teamID].isDead or not teams[teamID].isPlaying) then
					allyTeamsDead[allyTeamID] = nil
				end
			end
		end
	end

	-- sort allyteams: own at top, others in order by total elo, dead teams at bottom
	table.sort(allyTeamsSorted, function(a,b)
			if allyTeamsDead[a] and not allyTeamsDead[b] then return false end
			if allyTeamsDead[b] and not allyTeamsDead[a] then return true end
			if allyTeamsDead[b] and allyTeamsDead[a] and allyTeams[a] and allyTeams[b] then
				local teamIDa = allyTeams[a][1]
				local teamIDb = allyTeams[b][1]
				if teamIDa and teamIDb and teams[teamIDa].roster and teams[teamIDb].roster and teams[teamIDa].roster[1] and teams[teamIDb].roster[1]  then
					if teams[teamIDa].roster[1].isActive and not teams[teamIDb].roster[1].isActive then return true end
					if teams[teamIDb].roster[1].isActive and not teams[teamIDa].roster[1].isActive then return false end
				end
			end
			if localTeam ~= 0 or teamZeroPlayers[myID] then
				if a == localAlliance then return true end
				if b == localAlliance then return false end
			end
			return allyTeamOrderRank[a] > allyTeamOrderRank[b]
		end
	)

	-- sort the specteam
	table.sort(specTeam.roster, function(a,b)
		return a.name:lower() < b.name:lower()
	end)

	row = 0
	AddTableHeaders()
	row = row + 1

	-- add the team summaries
	if cf then
		AddAllAllyTeamSummaries(allyTeamsSorted)
		row = row + 0.5
	elseif options.showSummaries.value then
		if existsVeryBigTeam or numBigTeams > 2 then
			AddAllAllyTeamSummaries(allyTeamsSorted)
			row = row + 0.5
		end
		--[[
		if amSpec then
			if existsVeryBigTeam or numBigTeams > 2 then
				AddAllAllyTeamSummaries(allyTeamsSorted)
				row = row + 0.5
			end
		else
			if myTeamIsVeryBig or cf then
				AddAllAllyTeamSummaries({localTeam})
				row = row + 0.5
			end
		end
		--]]
	end

	-- add the player entities
	if list_size ~= 0 then
		for i=1,#allyTeamsSorted do  -- for every ally team
			local allyTeamID = allyTeamsSorted[i]
			if allyTeams[allyTeamID] and (list_size >= 3 or allyTeamID == localAlliance) then
				--AddCfCheckbox(allyTeamID)
				for j=1,#allyTeams[allyTeamID] do  -- for every player team on the ally team
					local teamID = allyTeams[allyTeamID][j]
					if teams[teamID] and teams[teamID].roster and (list_size >= 2 or teamID == localTeam) then
						for k=1,#teams[teamID].roster do -- for every player on the player team
							AddEntity(teams[teamID].roster[k], teamID, allyTeamID)
						end
					end
				end
				if existsVeryBigTeam or numBigTeams > 1 then row = row + 0.35 end
			end
		end
	end

	-- add the spectator entities
	if list_size == 4 and #specTeam.roster ~= 0 then
		teams[-1] = specTeam
		allyTeams[-1] = {-1}
		for k=1,#specTeam.roster do
			AddEntity(specTeam.roster[k], -1, -1)
		end
	end
	MakeSpecTooltip()

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

SetupScrollPanel = function ()
	if scroll_cpl then scroll_cpl:Dispose() end
	local scpl = {
		parent = window_cpl,
		--width = "100%",
		height = "100%",
		backgroundColor  = {1,1,1,options.backgroundOpacity.value},
		borderColor = {1,1,1,options.backgroundOpacity.value},
		padding = {0, 0, 0, 0},
		--autosize = true,
		--right = 0,
		scrollbarSize = 6,
		width = x_bound,
		horizontalScrollbar = false,
		ignoreMouseWheel = not options.mousewheel.value,
		NCHitTest = function(self,x,y)
			local alt,ctrl, meta,shift = Spring.GetModKeyState()
			local _,_,lmb,mmb,rmb = Spring.GetMouseState()
			if (shift or ctrl or alt) or (mmb or rmb) or ((not self.tooltip or self.tooltip=="") and not (meta and lmb)) then --hover over window will intercept mouse, pressing right-mouse or middle-mouse or shift or ctrl or alt will stop intercept
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
	if options.alignToLeft.value then
		scpl.left = 0
	else
		scpl.right = 0
	end
	scroll_cpl = ScrollPanel:New(scpl)
	
	function scroll_cpl:IsAboveVScrollbars(x, y)  -- this override default Scrollpanel's HitTest. It aim to: reduce chance of click stealing. It exclude any modifier key (shift,alt,ctrl, except spacebar which is used for Space+click shortcut), and only allow left-click to reposition the vertical scrollbar
		local alt,ctrl, meta,shift = Spring.GetModKeyState()
		if (x< self.width - self.scrollbarSize) or (shift or ctrl or alt) or (not select(3,Spring.GetMouseState())) then 
			return false 
		end
		return self
	end
	
	SetupPlayerNames()
end

SetupPanels = function ()

	showWins = CheckShowWins()

	CalculateWidths()
	local x,y,height,width
	if window_cpl then
		y = window_cpl.y
		height = window_cpl.height
		width = math.max(x_windowbound, lastChosenSizeX)
		x = options.alignToLeft.value and window_cpl.x or (window_cpl.x + window_cpl.width - width)
		window_cpl:Dispose()
	else
		x = screen0.width - x_windowbound
		y = screen0.height - 150
		width = x_windowbound
		height = 150
	end
	lastSizeX = width
	
	window_cpl = Window:New{  
		dockable = true,
		name = "Player List",
		color = {0,0,0,0},
		x = x,
		y = y,
		width = width,
		height = height,
		padding = {0, 0, 0, 0};
		parent = screen0,
		draggable = false,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = false,
		minWidth = x_windowbound,
	}
	SetupScrollPanel()

	ToggleVisibility()
end

function PlayersChanged()
	if amSpec then
		SetupPlayerNames()
	else
		local _,_,amNowSpec = Spring.GetPlayerInfo(myID, false)
		if amNowSpec then
			amSpec = amNowSpec
			SetupPanels()
		else
			SetupPlayerNames()
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
	Spring.SendCommands({"info 1"})
end

-- Part of an experiment to try to improve performance, will come back to it later
-- local updateModulus = 8
-- local updateCount = 0

function widget:Update(s)
	timer = timer + s
	if timer > UPDATE_FREQUENCY then
		timer = 0
		if (lastSizeX ~= window_cpl.width or lastSizeY ~= window_cpl.height) then --//if user resize the player-list
			AlignScrollPanel()
			lastChosenSizeX = window_cpl.width
			lastSizeX = window_cpl.width
			lastSizeY = window_cpl.height
		else
--			for i=updateCount+1,#playerTeamStatsCache,updateModulus do
--				playerTeamStatsCache[i] = nil
--			end
--			updateCount = (updateCount + 1) % updateModulus
			if (not scroll_cpl.parent) then return end --//don't update when window is hidden
			if showWins ~= CheckShowWins() then
				SetupPanels()
			end
			UpdatePlayerInfo()
		end

	end
end

function widget:PlayerChanged(playerID)
	PlayersChanged()
end

function widget:PlayerAdded(playerID)
	PlayersChanged()
end

function widget:PlayerRemoved(playerID)
	PlayersChanged()
end

function widget:TeamDied(teamID)
	PlayersChanged()
end

function widget:TeamChanged(teamID)
	PlayersChanged()
end

-- workaround for stupidity
function widget:GameStart()
	SetupPanels()
end

-----------------------------------------------------------------------
-- we need both UnitCreated and UnitFinished because mobiles and static defense aren't treated the same >:<
function widget:UnitCreated(unitID, unitDefID, unitTeam)
	local unarmed = UnitDefs[unitDefID].springCategories.unarmed
	if UnitDefs[unitDefID].isImmobile and not unarmed then -- is static-d
		ProcessUnit(unitID, unitDefID, unitTeam)
	end
end

function widget:UnitFinished(unitID, unitDefID, unitTeam)
	local unarmed = UnitDefs[unitDefID].springCategories.unarmed
	if not UnitDefs[unitDefID].isImmobile and (not finishedUnits[unitID]) then -- mobile unit
		ProcessUnit(unitID, unitDefID, unitTeam)
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local unarmed = UnitDefs[unitDefID].springCategories.unarmed
	if not UnitDefs[unitDefID].isImmobile then -- mobile unit
	      if finishedUnits[unitID] then
		      ProcessUnit(unitID, unitDefID, unitTeam, true)
	      end
	elseif not unarmed then	-- static defense
	      ProcessUnit(unitID, unitDefID, unitTeam, true)
	end
end

function widget:UnitGiven(unitID, unitDefID, newTeamID, teamID)
	-- doing this twice is a bit inefficient but bah
	ProcessUnit(unitID, unitDefID, teamID, true)
	ProcessUnit(unitID, unitDefID, newTeamID)
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

	SetupPanels()
	
	Spring.SendCommands({"info 0"})
	lastSizeX = window_cpl.width
	lastSizeY = window_cpl.height
	
	self:LocalColorRegister()
end

function widget:Shutdown()
        self:LocalColorUnregister()
end

function widget:LocalColorRegister()
	if WG.LocalColor and WG.LocalColor.RegisterListener then
		WG.LocalColor.RegisterListener(widget:GetInfo().name, SetupPlayerNames)
	end
end

function widget:LocalColorUnregister()
	if WG.LocalColor and WG.LocalColor.UnregisterListener then
		WG.LocalColor.UnregisterListener(widget:GetInfo().name)
	end
end
