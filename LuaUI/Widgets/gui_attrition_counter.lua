local version = 2.0
function widget:GetInfo()
  return {
    name      = "Attrition Counter",
    desc      = "Shows a counter that keeps track of player/team kills/losses",
    author    = "Anarchid, Klon",
    date      = "Dec 2012, Aug 2015",
    license   = "GPL",
    layer     = -10,
    enabled   = true  --  loaded by default?
  }
end

options_path = 'Settings/Misc/Attrition Counter'
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
local blue = {0,0,1,1}
local grey = {1,1,1,0.5}
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
--local label_own_losses
--local label_other_losses
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

local font -- dummy

local myTeam
local myAllyTeam
local gaiaTeam
local enemyAllyTeam

local h = 0.00000001

local teams = {
	--	[teamID] = {
	--		lostUnits = <number>
	--		lostMetal = <number>	
	-- 		rate = (allyTeams[other].lostMetal / #allyTeams[other].teamIDs) / lostMetal : <number>
	--		friendAllyTeamID = <number>
	--		enemyAllyTeamID = <number>
	--		color = {R,G,B,A, asString} <table<number, string>>
	--		name = playername <string>
}setmetatable(teams, {__index = function (t, k) rawset(t, k, {lostUnits = 0, lostMetal = h, rate = -1}); return t[k] end})

local allyTeams = {
	--	[allyTeamID] = {
	--		lostUnits = <number>
	--		lostMetal = <number>
	----		killedUnits = <number>
	----		killedMetal = <number>
	-- 		rate = allyTeams[other].lostMetal / lostMetal : <number>
	--		teamIDs = { <number> = true, ... }
	-- 		enemyTeamIDs = { <number> = true, ... } -- unused
	--		color = {R,G,B,A, asString} <table<number, string>>
	--		name = team or playername <string>
	--		numPlayers = <number>
	--		highestElo = <teamID>
}setmetatable(allyTeams, {__index = function (t, k) rawset(t, k, {lostUnits = 0, lostMetal = h, rate = -1, numPlayers = 0, teamIDs = {}, enemyTeamIDs = {}}); return t[k] end}) -- 

local frame = 0 -- options.updateFrequency.value
local doUpdate = false

local function rgbToString(r,g,b) return '\255'..string.char(floor(r*255))..string.char(floor(g*255))..string.char(floor(b*255)) end

function widget:Initialize()
	Chili = WG.Chili; if (not Chili) then widgetHandler:RemoveWidget() return end

	Window = Chili.Window
	Label = Chili.Label	
	Image = Chili.Image	
	
	font = Chili.Font:New{} -- need this to call GetTextWidth without looking up an instance
	
	-- set up all the teams and allyteams and find out gamemode
	local allAllyTeams = Spring.GetAllyTeamList()	
	local playerlist = Spring.GetPlayerList()
		
	myAllyTeam = Spring.GetMyAllyTeamID()
	myTeam = Spring.GetMyTeamID()
	gaiaTeam = Spring.GetGaiaTeamID()
	
	local name, spectator, teamID, allyTeamID, keys, elo
	local i = 1; while (i < #playerlist) do		
		local playerID = playerlist[i]
		name,_,spectator,teamID,allyTeamID,_,_,_,_,keys = GetPlayerInfo(playerID)
		elo = keys.elo
		i = i + 1
		if not spectator and teamID ~= gaiaTeam then			
			if not enemyAllyTeam then
				if allyTeamID ~= myAllyTeam then enemyAllyTeam = allyTeamID; i = 1	end	-- found enemyAllyTeam team, now need to restart				
			else
				if allyTeamID ~= myAllyTeam and allyTeamID ~= enemyAllyTeam then --ffa
					widgetHandler:RemoveWidget()
				end
				teams[teamID].name = name
				teams[teamID].elo = elo
				teams[teamID].friendlyAllyTeam = allyTeamID
				teams[teamID].enemyAllyTeam = (allyTeamID == myAllyTeam and enemyAllyTeam or myAllyTeam)
				local r,g,b,a = GetTeamColor(teamID)
				teams[teamID].color = {r,g,b,a, asString = rgbToString(r,g,b)}
				--Echo (teamID.." - "..name..' ID: '..teamID.." friend: "..teams[teamID].friendlyAllyTeam.." enemyAllyTeam: "..teams[teamID].enemyAllyTeam..' elo: '..elo)				
				allyTeams[allyTeamID].teamIDs[teamID] = true				
				allyTeams[allyTeamID].numPlayers = allyTeams[allyTeamID].numPlayers + 1
				if allyTeams[allyTeamID].highestElo then
					if elo > teams[allyTeams[allyTeamID].highestElo].elo then allyTeams[allyTeamID].highestElo = teamID end
				else allyTeams[allyTeamID].highestElo = teamID				
				end							
			end
		end
	end
	
	if allyTeams[myAllyTeam].numPlayers == 1 and allyTeams[enemyAllyTeam].numPlayers == 1 then 	-- 1v1
		allyTeams[myAllyTeam].name = teams[allyTeams[myAllyTeam].highestElo].name
		allyTeams[enemyAllyTeam].name = teams[allyTeams[enemyAllyTeam].highestElo].name
	else																						--teams
		allyTeams[myAllyTeam].name = spectating and ("Team "..myAllyTeam) or 'Your Team'
		allyTeams[enemyAllyTeam].name = spectating and ("Team "..enemyAllyTeam) or 'Enemy Team'

	end
	
	allyTeams[myAllyTeam].color = teams[allyTeams[myAllyTeam].highestElo].color
	allyTeams[enemyAllyTeam].color = teams[allyTeams[enemyAllyTeam].highestElo].color
	
	--Echo ("done players, found "..#playerlist..' / '..(#teams + 1)..' players') --< #teams discounts id 0
	--Echo (myAllyTeam.." - "..enemyAllyTeam)
	
	--Echo("Friend team is: "..allyTeams[myAllyTeam].name..'with '..allyTeams[myAllyTeam].numPlayers..' players')
	--Echo("Enemy team team is: "..allyTeams[enemyAllyTeam].name..'with '..allyTeams[enemyAllyTeam].numPlayers..' players')
			
	if spectating then
		Echo('<Attrition Counter>:Running as Spectator'); -- this doesnt seem to do anything
	end
	
	CreateWindow()
end

function widget:Shutdown()
	if window_main then window_main:Dispose() end
end

local function cap (x) return math.max(math.min(x,1),0) end

local function UpdateCounters()

	local rate = allyTeams[myAllyTeam].rate
	local caption	
	if rate < 0 then caption 'N/A'; label_rate_player.font.color = {.7,.7,.7,1}	
	elseif rate > 9.9 then caption = 'PWN!'; label_rate_player.font.color = {.2,.2,1,1}		
	else
		caption = tostring(floor(rate*100))..'%'		
		label_rate_player.font.color = {
			cap(3-rate*2),
			cap(2*rate-1),
			cap((rate-2) / 2),
			1}	
	end		
	
	label_rate_player:SetCaption(caption)	
	label_rate_player.x = (window_main.width / 2) - (font:GetTextWidth(label_rate_player.caption, 30) / 2)
	
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

local function UpdateRates()
	local friendTeam
	local enemyTeam
	
	-- player vs enemy team average. the information is largely misleading as no connection to players' individual kills can be made
	-- -> players with no activity at all will show good rates, more active players will show bad rates even when possibly making cost
	--[[
	for i, _ in pairs(teams) do	
		enemyTeam = allyTeams[teams[i].enemyAllyTeam]
		teams[i].rate = enemyTeam.lostMetal / (enemyTeam.numPlayers * teams[i].lostMetal)
		
	end
	--]]
	
	friendTeam = allyTeams[myAllyTeam]
	enemyTeam = allyTeams[enemyAllyTeam]
	
	friendTeam.rate = enemyTeam.lostMetal / friendTeam.lostMetal
	enemyTeam.rate = friendTeam.lostMetal / enemyTeam.lostMetal
end


function widget:UnitDestroyed(unitID, unitDefID, teamID, attUnitID, attDefID, attTeamID)		
	if GetUnitHealth(unitID) > 0 then return end -- why

	local ud = UnitDefs[unitDefID]
	if ud.customParams.dontcount then return end
	
	local buildProgress = select(5, GetUnitHealth(unitID))
	local worth = ud.metalCost * buildProgress
	
	if teamID and unitID and unitDefID and teamID ~= gaiaTeam then 	
		-- might just ignore gaia, it will set up a table for it and track its losses but nothing else will happen?		
		local team = teams[teamID]
		team.lostUnits = team.lostUnits + 1
		team.lostMetal = team.lostMetal + worth
		
		local allyTeam = allyTeams[team.friendlyAllyTeam]
		allyTeam.lostUnits = allyTeam.lostUnits + 1
		allyTeam.lostMetal = allyTeam.lostMetal + worth
			
		doUpdate = true
		
	else Echo("<AttritionCounter>: missing param"..(teamID or 'teamID').." - "..(unitID or 'unitID').." - "..(unitDefID or 'UnitDefID')) return end	
end

function CreateWindow()	
	local screenWidth,screenHeight = Spring.GetWindowGeometry()
	
	--// WINDOW
	window_main = Window:New{
		color = {1,1,1,0.8},
		parent = Chili.Screen0,
		dockable = true,
		name = "AttritionCounter",
		padding = {0,0,0,0},
		margin = {0,0,0,0},
		right = 0,
		y = "10%",
		height = 60,
		clientWidth  = 400,
		clientHeight = 60,
		minHeight = 60,
		maxHeight = 60,
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
		x = (window_main.width / 2) - font:GetTextWidth('---', 30), --window_main.width * 0.415,
		y = 15,
		--align = 'center',
		fontSize = 30,
		textColor = grey,
		caption = '---',
		--minWidth = 80,
		--width = 80,
		--left = 250,
		--right = 250,		
	}
	
	-- first team labels
	label_self = Label:New {
		parent = window_main,
		x = 20,
		y = 10,
		fontSize = 16,
		align = 'left',
		caption = allyTeams[myAllyTeam].name,
		textColor = allyTeams[myAllyTeam].color,
		tooltip = '',
		HitTest = function (self, x, y) return self end,
		OnMouseOver = {function(self) 
			local at = allyTeams[myAllyTeam]			
			local ttip = at.color.asString..at.name..'\n\n'..'\008'..'Units Lost: \t\t\t'..floor(at.lostUnits)
				..'\nMetal Lost: \t\t\t'..floor(at.lostMetal)..'\n\n\nLost Units / Metal by Player:\n\n'
			for team, _ in pairs (at.teamIDs) do
				local t = teams[team]
				ttip = ttip..t.color.asString..(t.name or 'Unnamed Player')..'\008'..':  '..floor(t.lostUnits)..' / '..floor(t.lostMetal).."\n"
			end
			self.tooltip = ttip
		end},
	}
	label_own_kills_units = Label:New{
		parent = window_main,
		x = 22,
		y = 33,
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
		y = 31,
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	label_own_kills_metal = Label:New{
		parent = window_main,
		x = icon_own_skull.x + 20,
		y = 33,
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
		y = 31,
		tooltip = 'Metal Value Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	
	-- second team labels
	label_other = Label:New {
		parent = window_main,
		right = 20,		
		y = 10,
		fontSize = 16,
		align = 'right',
		caption = allyTeams[enemyAllyTeam].name,
		textColor = allyTeams[enemyAllyTeam].color,
		HitTest = function (self, x, y) return self end,
		OnMouseOver = {function(self) 
			local at = allyTeams[enemyAllyTeam]			
			local ttip = at.color.asString..at.name..'\n\n'..'\008'..'Units Lost: \t\t\t'..floor(at.lostUnits)
				..'\nMetal Lost: \t\t\t'..floor(at.lostMetal)..'\n\n\nLost Units / Metal by Player:\n\n'
			for team, _ in pairs (at.teamIDs) do
				local t = teams[team]
				ttip = ttip..t.color.asString..(t.name or 'Unnamed Player')..'\008'..':  '..floor(t.lostUnits)..' / '..floor(t.lostMetal).."\n"
			end
			self.tooltip = ttip
		end},		
	}
	icon_other_bars = Image:New{
		parent = window_main,
		file = ICON_METAL_FILE,
		width = 16,
		height = 16,
		x = window_main.clientWidth - (22 + 17),
		--right = 22,		
		y = 31,
		tooltip = 'Metal Value Destroyed',
		HitTest = function (self, x, y) return self end,
	}	
	label_other_kills_metal = Label:New{
		parent = window_main,		
		y = 33,
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
		y = 31,
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
		-- align = 'right',
	}
	label_other_kills_units = Label:New{
		parent = window_main,
		x = icon_other_skull.x - (font:GetTextWidth('0') + 1),
		--right = icon_other_skull.right + 17, --- font:GetTextWidth('---'),
		y = 33,
		fontSize = 12,
		--align = 'right',
		caption = '0',
		tooltip = 'Units Destroyed',
		HitTest = function (self, x, y) return self end,
	}
	
	window_main.OnResize = {
		function(self,...)		
			label_rate_player.x = (self.clientWidth / 2) - (font:GetTextWidth('---', 30) / 2)
			label_rate_player:Invalidate()
			
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

function GameFrame(n)
	frame = frame - 1
	if frame <= 0 and doUpdate or frame <= - 3000 then -- force update every so and so many seconds
		frame = options.updateFrequency.value
		UpdateRates()
		UpdateCounters()
		doUpdate = false
	end	
end

	
--[[
	
		
	-- losses of defending player vs attacker + attacking team
	local list = teams[teamdID].losses
	Echo("check 2")
	list[attTeamID] = list[attTeamID] + worth
	Echo("check 3")
	list[attAllyTeamID] = list[attAllyTeamID] + worth
	Echo("check 4")
	list[total] = list[total] + worth	
	Echo("check 5")
	
	-- losses of defending team vs attacker + attacking team
	list = allyTeams[allyTeamID].losses
	list[attTeamID] = list[attTeamID] + worth
	list[attAllyTeamID] = list[attAllyTeamID] + worth
	list[total] = list[total] + worth	
	
	-- defender vs attacker
	local a = teams[teamID].losses[attTeamID]; local b = teams[attTeamID].losses[teamID]
	teams[teamID].rate[attTeamID] = b / a
	teams[attTeamID].rate[teamID] = a / b
	-- defender vs attacking team
	a = teams[teamID].losses[attAllyTeamID]; b = teams[attAllyTeamID].losses[teamID]
	teams[teamID].rate[attAllyTeamID] = b / a
	teams[attAllyTeamID].rate[teamID] = a / b
	-- defending team vs attacking team
	a = teams[allyTeamID].losses[attAllyTeamID]; b = teams[attAllyTeamID].losses[allyTeamID]
	teams[allyTeamID].rate[attAllyTeamID] = b / a
	teams[attAllyTeamID].rate[allyTeamID] = a / b
	Echo("check end")
	-- total cant be done without kills or going through all other lists, but should be same as vs. other team in team games
	
	--updateCounters()
	
	-- kills of attacking player vs defender + defending team
	local list = teams[attTeamID].kills 
	list[teamID] = list[teamID] + worth
	list[allyTeamID] = list[allyTeamID] + worth
	list[total] = list[total] + worth
	
	-- kills of attacking team vs defender + defending team	
	list = allyTeams[attAllyTeamID].kills
	list[teamID] = list[teamID] + worth
	list[allyTeamID] = list[allyTeamID] + worth
	list[total] = list[total] + worth
-]]

