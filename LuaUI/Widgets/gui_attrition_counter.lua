local version = 2.131
function widget:GetInfo()
  return {
    name      = "Attrition Counter",
    desc      = "Shows a counter that keeps track of player/team kills/losses",
    author    = "Anarchid, Klon",
    date      = "Dec 2012, Aug 2015",
    license   = "GPL",
    layer     = -10,
    enabled   = false  --  loaded by default?
  }
end

include("colors.h.lua")
VFS.Include("LuaRules/Configs/constants.lua")

options_path = 'Settings/HUD Panels/Attrition Counter'
options_order = {'updateFrequency'}
options = {
	updateFrequency = {
		name = "Update every N Frames",
		type = 'number',
		min = 1,
		max = 150,
		value = 10,
		step = 1,
	},
}

local Chili
local Window
local Label
local Image

local red = {1,0,0,1}
local green = {0,1,0,1}
local blue = {.2,.2,1,1}
local grey = {.5,.5,.5,1}
local white = {1,1,1,1}

local abs = math.abs
local floor = math.floor
local Echo = Spring.Echo

local GetUnitHealth = Spring.GetUnitHealth
local GetTeamColor = Spring.GetTeamColor
local GetTeamInfo = Spring.GetTeamInfo
local GetPlayerInfo = Spring.GetPlayerInfo
local UnitDestroyed = Spring.UnitDestroyed -- (unitID, unitDefID, unitTeam, attackerID, attackerDefID, attackerTeam)

local spectating = Spring.GetSpectatingState();

local window_main
local label_rate

local label_self
local label_other

local label_own_kills_units
local label_own_kills_metal
local label_other_kills_units
local label_other_kills_metal

local icon_own_skull
local icon_own_bars
local icon_other_skull
local icon_other_bars

-- local ICON_LOST_FILE = 'luaui/images/AttritionCounter/chicken.png'
local ICON_KILLS_FILE = 'luaui/images/AttritionCounter/skull.png'
local ICON_METAL_FILE = 'luaui/images/ibeam.png'

local font -- dummy, need this to call GetTextWidth without looking up an instance

local myTeam
local myAllyTeam
local gaiaTeam
local enemyAllyTeam

local h = 0.00000001

local teams = {
	--	[teamID] = {
	--		lostUnits = <number>
	--		lostMetal = <number>	
	-- 		rate = (allyTeams[other].lostMetal / #allyTeams[other].teamIDs) / lostMetal : <number> -- unused
	--		friendAllyTeamID = teamID <number>
	--		enemyAllyTeamID = teamID <number>
	--		color = {R,G,B,A} <table<number, ..., string>>
	--		name = playername <string>
}setmetatable(teams, {__index = function (t, k) rawset(t, k, {lostUnits = 0, lostMetal = h, rate = -1}); return t[k] end})

local allyTeams = {
	--	[allyTeamID] = {
	--		lostUnits = <number>
	--		lostMetal = <number>
	-- 		rate = allyTeams[other].lostMetal / lostMetal : <number>
	--		teamIDs = { <number>  teamID = true, ... }
	--		color = {R,G,B,A}
	--		name = allyteam# or playername <string>
	--		numPlayers = <number>
	--		highestElo = teamID <number>
	--      name = <string>
}setmetatable(allyTeams, {__index = function (t, k) rawset(t, k, {lostUnits = 0, lostMetal = h, rate = -1, numPlayers = 0, teamIDs = {}}); return t[k] end}) -- 

local frame = 0 -- options.updateFrequency.value
local doUpdate = false


------------------------------------------------------------------------------------------------------------------------------------
--------------- local functions
------------------------------------------------------------------------------------------------------------------------------------

local function rgbToString(c) 
	if(c) then
		return '\255'..string.char(floor(c[1]*255))..string.char(floor(c[2]*255))..string.char(floor(c[3]*255))
	else
		return rgbToString({1,1,1,1});
	end
end

local function cap (x) return math.max(math.min(x,1),0) end

local function GetTeamName(teamID)
	local _,leader,_,isAI,_,allyTeamID = Spring.GetTeamInfo(teamID)
	if teamID == gaiaTeamID then
		return "gaia"
	else
		local name = "player";
		if isAI then
			_,name = Spring.GetAIInfo(teamID)
		else
			name,_,_,_,_,_,_,_,_,customKeys = GetPlayerInfo(leader)
		end
		return name;
	end
end

local function GetOpposingAllyTeams()
	local gaiaAllyTeamID = select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
	local returnData = {}
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		local allyTeamID = allyTeamList[i]

		local teamList = Spring.GetTeamList(allyTeamID)
		if allyTeamID ~= gaiaAllyTeamID and #teamList > 0 then

			local name = Spring.GetGameRulesParam("allyteam_long_name_" .. allyTeamID)
			if string.len(name) > 10 then
				name = Spring.GetGameRulesParam("allyteam_short_name_" .. allyTeamID)
			end

			returnData[#returnData + 1] = {
				allyTeamID = allyTeamID, -- allyTeamID for the team
				name = name, -- Large display name of the team
				teamID = teamList[1], -- representitive teamID
				color = {Spring.GetTeamColor(teamList[1])} or {1,1,1,1}, -- color of the teams text (color of first player)
			}
		end
	end

	if #returnData ~= 2 then
		return
	end
	
	if returnData[1].allyTeamID > returnData[2].allyTeamID then
		returnData[1], returnData[2] = returnData[2], returnData[1]
	end
	
	return returnData
end

local function UpdateCounters()

	local rate = allyTeams[myAllyTeam].rate
	local caption	
	if rate < 0 then caption 'N/A'; label_rate_player.font.color = grey	
	elseif rate > 9.99 then caption = 'PWN!'; label_rate_player.font.color = blue
	else
		caption = tostring(floor(rate*100))..'%'
		label_rate_player.font.color = {
			cap(3-rate*2),
			cap(2*rate-1),
			cap((rate-2) / 2),
			1}	
	end
	
	label_rate_player:SetCaption(caption)	
	label_rate_player.x = (window_main.width / 2) - (font:GetTextWidth(caption, 30) / 2)
	
	label_own_kills_units:SetCaption(allyTeams[enemyAllyTeam].lostUnits)
	label_own_kills_metal:SetCaption('/ '..floor(allyTeams[enemyAllyTeam].lostMetal))
	
	label_other_kills_units:SetCaption(allyTeams[myAllyTeam].lostUnits)
	label_other_kills_metal:SetCaption(' / '..floor(allyTeams[myAllyTeam].lostMetal))
	
	icon_own_skull.x = font:GetTextWidth(label_own_kills_units.caption) + label_own_kills_units.x + 1; icon_own_skull:Invalidate()
	label_own_kills_metal.x = icon_own_skull.x + 20
	icon_own_bars.x = font:GetTextWidth(label_own_kills_metal.caption) + 1 + label_own_kills_metal.x; icon_own_bars:Invalidate()	
	
	label_other_kills_metal.x = icon_other_bars.x - (font:GetTextWidth(label_other_kills_metal.caption) + 1)
	icon_other_skull.x = label_other_kills_metal.x - 17; icon_other_skull:Invalidate()
	label_other_kills_units.x = icon_other_skull.x - (font:GetTextWidth(label_other_kills_units.caption) + 1)

end


local function UpdateTooltips()
	local at = allyTeams[myAllyTeam]			
	local ttip = rgbToString(at.color)..at.name..'\n\n'..'\008'..'Units Lost: \t\t\t'..floor(at.lostUnits)
		..'\nMetal Lost: \t\t\t'..floor(at.lostMetal)..'\n\n\nLost Units / Metal by Player:\n\n'
	for team, _ in pairs (at.teamIDs) do
		local t = teams[team]
		ttip = ttip..rgbToString(t.color)..(t.name or 'Unnamed Player')..'\008'..':  '..floor(t.lostUnits)..' / '..floor(t.lostMetal).."\n"
	end
	label_self.tooltip = ttip
	
	at = allyTeams[enemyAllyTeam]			
	ttip = rgbToString(at.color)..at.name..'\n\n'..'\008'..'Units Lost: \t\t\t'..floor(at.lostUnits)
		..'\nMetal Lost: \t\t\t'..floor(at.lostMetal)..'\n\n\nLost Units / Metal by Player:\n\n'
	for team, _ in pairs (at.teamIDs) do
		local t = teams[team]
		ttip = ttip..rgbToString(t.color)..(t.name or 'Unnamed Player')..'\008'..':  '..floor(t.lostUnits)..' / '..floor(t.lostMetal).."\n"
	end
	label_other.tooltip = ttip
end


local function UpdateRates()
	local friendTeam = allyTeams[myAllyTeam]
	local enemyTeam = allyTeams[enemyAllyTeam]
	
	-- player vs enemy team average. the information is largely misleading as no connection to players' individual kills can be made
	-- -> players with no activity at all will show good rates, more active players will show bad rates even when possibly making cost
	--[[
	for i, _ in pairs(teams) do	
		enemyTeam = allyTeams[teams[i].enemyAllyTeam]
		teams[i].rate = enemyTeam.lostMetal / (enemyTeam.numPlayers * teams[i].lostMetal)
		
	end
	--]]
	
	friendTeam.rate = enemyTeam.lostMetal / friendTeam.lostMetal
	enemyTeam.rate = friendTeam.lostMetal / enemyTeam.lostMetal
end


------------------------------------------------------------------------------------------------------------------------------------
--------------- widget: functions
------------------------------------------------------------------------------------------------------------------------------------

function widget:Initialize()
	Chili = WG.Chili; 
	if (not Chili) then 
		widgetHandler:RemoveWidget() 
		return 
	end

	Window = Chili.Window
	Label = Chili.Label	
	Image = Chili.Image	
	
	font = Chili.Font:New{} -- need this to call GetTextWidth without looking up an instance
	
	myAllyTeam = Spring.GetMyAllyTeamID()
	myTeam = Spring.GetMyTeamID()
	gaiaTeam = Spring.GetGaiaTeamID()

	local _teams = Spring.GetTeamList()
	local opposingTeams = GetOpposingAllyTeams();

	if(opposingTeams) then
		for i,td in pairs(opposingTeams) do
			allyTeams[td.allyTeamID].color = td.color;
			allyTeams[td.allyTeamID].name = td.name;
			allyTeams[td.allyTeamID].numPlayers = td.name;
			
			if(myAllyTeam ~= td.allyTeamID) then enemyAllyTeam = td.allyTeamID end
		end
		
		for i, t in pairs(_teams) do
			local _,leader,_,isAI,_,allyTeamID,_ = Spring.GetTeamInfo(t);
			local elo = 0;
			
			allyTeams[allyTeamID].teamIDs[t] = true;
			teams[t].name = GetTeamName(t);
			teams[t].friendlyAllyTeam = allyTeamID;
			teams[t].enemyAllyTeam = (allyTeamID == myAllyTeam and enemyAllyTeam or myAllyTeam);
			
			if(isAI) then
				elo = 1000;
			else
				local keys = select(10,GetPlayerInfo(leader));
				elo = (keys and keys.elo) or 1000;
			end
			
			teams[t].elo = elo;
			
			if allyTeams[allyTeamID].highestElo then
				if elo > teams[allyTeams[allyTeamID].highestElo].elo then 
					allyTeams[allyTeamID].highestElo = teamID 
				end
			else 
				allyTeams[allyTeamID].highestElo = teamID
			end
		end
	else
		Echo("<AttritionCounter>: unsupported team configuration (FFA?), disabling");
		widgetHandler:RemoveWidget()
		return
	end
	
	CreateWindow()
	UpdateTooltips()
	
	if not allyTeams[myAllyTeam].name:find("\n") then
		label_self.y = label_self.y+18;
	end
	
	if not allyTeams[enemyAllyTeam].name:find("\n") then
		label_other.y = label_other.y+18;
	end
	
end


function widget:Shutdown()
	if window_main then window_main:Dispose() end
end


function widget:GameFrame(n)
	frame = frame - 1
	if frame <= 0 and doUpdate or frame <= - 3000 then -- force update every so and so many seconds
		frame = options.updateFrequency.value
		UpdateRates()
		UpdateCounters()
		UpdateTooltips()
		doUpdate = false
	end	
end


local deadUnits = {} -- in spec mode UnitDestroyed would sometimes be called twice for the same unit, so we need to prevent it from counting twice

function widget:UnitDestroyed(unitID, unitDefID, teamID, attUnitID, attDefID, attTeamID)	
	
	-- if its also the same kind of unit, its safe to assume that it is the very same unit
	-- else it is most likely not the same unit but an old table entry and a re-used unitID. we just keep the entry
	-- small margin of error remains
	
	if teamID == gaiaTeam or GetUnitHealth(unitID) > 0 then return end
	
	if deadUnits[unitID] and deadUnits[unitID] == unitDefID then
		deadUnits[unitID] = nil
		return 		
	end
	
	deadUnits[unitID] = unitDefID

		-- might just ignore gaia, it will set up a table for it and track its losses but nothing else will happen?
		-- not sure about the health check?

	local ud = UnitDefs[unitDefID]
	if ud.customParams.dontcount or ud.customParams.is_drone then return end
		
	local buildProgress = select(5, GetUnitHealth(unitID))
	local worth = Spring.Utilities.GetUnitCost(unitID, unitDefID) * buildProgress
	
	-- if teamID and unitID and unitDefID and teamID ~= gaiaTeam then 	
	local team = teams[teamID]
	team.lostUnits = team.lostUnits + 1
	team.lostMetal = team.lostMetal + worth
	
	local allyTeam = allyTeams[team.friendlyAllyTeam]
	allyTeam.lostUnits = allyTeam.lostUnits + 1
	allyTeam.lostMetal = allyTeam.lostMetal + worth
		
	doUpdate = true
		
	-- else Echo("<AttritionCounter>: missing param"..(teamID or 'teamID').." - "..(unitID or 'unitID').." - "..(unitDefID or 'UnitDefID')) return end	
end


------------------------------------------------------------------------------------------------------------------------------------
--------------- layout
------------------------------------------------------------------------------------------------------------------------------------

function CreateWindow()	
	-- local screenWidth,screenHeight = Spring.GetWindowGeometry()
	local countsOffset = 43;
	
	--// WINDOW
	window_main = Window:New{
		color = {1,1,1,0.8},
		parent = Chili.Screen0,
		dockable = true,
		name = "AttritionCounter",
		classname = "main_window_small_flat",
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		right = 0,
		y = "10%",
		height = 60,
		clientWidth  = 400,
		clientHeight = 65,
		minHeight = 65,
		maxHeight = 65,
		minWidth = 250,
		draggable = true,
		resizable = false,
		tweakDraggable = true,
		tweakResizable = true,
		minimizable = true,
		parentWidgetName = widget:GetInfo().name, --for gui_chili_docking.lua (minimize function)		
	}
		
	label_rate_player = Label:New {		
		parent = window_main,
		x = (window_main.width / 2) - (font:GetTextWidth('---', 30) / 2), -- window_main.width * 0.415,
		y = 15,		
		fontSize = 30,
		textColor = grey,
		caption = '---',			
	}
	
	-- first team labels
	label_self = Label:New {
		parent = window_main,
		x = 20,
		y = 0,
		fontSize = 16,
		align = 'left',
		caption = allyTeams[myAllyTeam].name,
		textColor = allyTeams[myAllyTeam].color,
		tooltip = '',
		HitTest = function (self, x, y) return self end,		
	}
	label_own_kills_units = Label:New{
		parent = window_main,
		x = 22,
		y = countsOffset+1,
		fontSize = 12,
		align = 'left',
		caption = '0',
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	icon_own_skull = Image:New{
		parent = window_main,
		file = ICON_KILLS_FILE,
		width = 16,
		height = 16,
		x = font:GetTextWidth(label_own_kills_units.caption) + label_own_kills_units.x + 1,
		y = countsOffset,
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	label_own_kills_metal = Label:New{
		parent = window_main,
		x = icon_own_skull.x + 20,
		y = countsOffset+1,
		fontSize = 12,
		align = 'left',
		caption = '/ 0',
		tooltip = 'Metal Value Destroyed',
		HitTest = function (self, x, y) return self end,
	}	
	icon_own_bars = Image:New{
		parent = window_main,
		file = ICON_METAL_FILE,
		width = 16,
		height = 16,
		x = font:GetTextWidth(label_own_kills_metal.caption) + 1 + label_own_kills_metal.x,
		y = countsOffset,
		tooltip = 'Metal Value Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	
	-- second team labels
	label_other = Label:New {
		parent = window_main,
		right = 20,		
		y = 0,
		fontSize = 16,
		align = 'right',
		caption = allyTeams[enemyAllyTeam].name,
		textColor = allyTeams[enemyAllyTeam].color,
		HitTest = function (self, x, y) return self end,			
	}
	icon_other_bars = Image:New{
		parent = window_main,
		file = ICON_METAL_FILE,
		width = 16,
		height = 16,
		x = window_main.clientWidth - (22 + 17),
		--right = 22,		
		y = countsOffset,
		tooltip = 'Metal Value Destroyed',
		HitTest = function (self, x, y) return self end,
	}	
	label_other_kills_metal = Label:New{
		parent = window_main,		
		y = countsOffset+1,
		x = icon_other_bars.x - (font:GetTextWidth('/ 0') + 1), --window_main.clientWidth - (22 + 17 + font:GetTextWidth('/ ---')),
		--right = 22 + 17,
		fontSize = 12,
		--align = 'right',
		caption = '/ 0',		
		--right = icon_own_skull.x + 1 + font:GetTextWidth('/ ---'),
		tooltip = 'Metal Value Destroyed',
		HitTest = function (self, x, y) return self end,
	}		
	icon_other_skull = Image:New{
		parent = window_main,
		file = ICON_KILLS_FILE,
		width = 16,
		height = 16,
		x = label_other_kills_metal.x - 17, --window_main.clientWidth - (22 + 17 + font:GetTextWidth('/ ---') + 1),
		--right = 22 + 17 + font:GetTextWidth('/ ---') + 1, --font:GetTextWidth(label_own_kills_metal.caption) + 1 + label_own_kills_metal.x,
		y = countsOffset,
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
		-- align = 'right',
	}
	label_other_kills_units = Label:New{
		parent = window_main,
		x = icon_other_skull.x - (font:GetTextWidth('0') + 1),
		--right = icon_other_skull.right + 17, --- font:GetTextWidth('---'),
		y = countsOffset+1,
		fontSize = 12,
		--align = 'right',
		caption = '0',
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	
	window_main.OnResize = {
		function(self,...)		
			label_rate_player.x = (self.clientWidth / 2) - (font:GetTextWidth('---', 30) / 2); label_rate_player:Invalidate()
			
			icon_own_skull.x = font:GetTextWidth(label_own_kills_units.caption) + label_own_kills_units.x + 1; icon_own_skull:Invalidate()
			label_own_kills_metal.x = icon_own_skull.x + 20
			icon_own_bars.x = font:GetTextWidth(label_own_kills_metal.caption) + 1 + label_own_kills_metal.x; icon_own_bars:Invalidate()	
			
			icon_other_bars.x = window_main.clientWidth - (22 + 17); icon_other_bars:Invalidate()
			label_other_kills_metal.x = icon_other_bars.x - (font:GetTextWidth(label_other_kills_metal.caption) + 1); label_other_kills_metal:Invalidate()
			icon_other_skull.x = label_other_kills_metal.x - 17; icon_other_skull:Invalidate()
			label_other_kills_units.x = icon_other_skull.x - (font:GetTextWidth(label_other_kills_units.caption) + 1); label_other_kills_units:Invalidate()
		end
	}
	
	return
end


function DestroyWindow()
	window_main:Dispose()
	window_main = nil
end
