--[[
	TO DO:
		Add amount label when mouseover line on graph (e.g to see exact metal produced at a certain time),
		Implement camera control to pan in the background while viewing graph,
		Add minimize option
		Come up with better way of handling specs, active players and players who died (currently doesn't show players who have died
]]
function widget:GetInfo() return {
	name    = "EndGame Stats",
	desc    = "v0.913 Chili replacement for default end game statistics",
	author  = "Funkencool",
	date    = "2013",
	license = "public domain",
	layer   = -1,
	enabled = true
} end

local buttons = {
	{"metalProduced"   , "Metal Produced"},
	{"metalUsed"       , "Metal Used"},
	{"metal_income"    , "Metal Income"},
	{"metal_reclaim"   , "Metal Reclaimed"},
	{"metalExcess"     , "Metal Excess"},

	{"energy_income"   , "Energy Income"},

	{"damage_dealt"     , "Damage Dealt"},
	{"damage_received"  , "Damage Received"},

	{"unitsProduced"   , "Units Built"},
	{"unit_value"      , "Unit Value"},
	{"unitsKilled"     , "Units Killed"},
	{"unitsDied"       , "Units Lost"},
}

local rulesParamStats = {
	metal_reclaim = true,
	unit_value = true,
	metal_income = true,
	energy_income = true,
	damage_dealt = true,
	damage_received = true,
}

local graphLength = 0
local usingAllyteams = false
local curGraph = {}

-- CHILI CONTROLS
local Chili, window0, graphPanel, graphSelect, graphLabel, graphTime
local wasActive = {}
local playerNames = {}
------------------------------------
--formats final stat to fit in label
local function numFormat(label)
	if not label then
		return ''
	end
	local number = math.floor(label)
	local string = ""
	if number/1000000000 >= 1 then
		string = string.sub(number/1000000000 .. "", 0, 4) .. "B"
	elseif number/1000000 >= 1 then
		string = string.sub(number/1000000 .. "", 0, 4) .. "M"
	elseif number/10000 >= 1 then
		string = string.sub(number/1000 .. "", 0, 4) .. "k"
	else
		string = math.floor(number) .. ""
	end
	return string
end
local function formatTime(seconds)
	local hours = math.floor(seconds/3600)
	local minutes = math.floor(seconds/60) % 60
	local seconds = seconds % 60
	if minutes < 10 then minutes = "0" .. minutes end
	if seconds < 10 then seconds = "0" .. seconds end
	return hours .. ":" .. minutes .. ":" .. seconds
end
local function drawIntervals(graphMax)
	for i=1, 4 do
		local line = Chili.Line:New{parent = graphPanel, x = 0, bottom = (i)/5*100 .. "%", width = "100%", color = {0.1,0.1,0.1,0.1}}
		local label = Chili.Label:New{parent = graphPanel, x = 0, bottom = (i)/5*100 .. "%", width = "100%", caption = numFormat(graphMax*i/5)}
	end
end

local function fixLabelAlignment()
	local doAgain
	for a=1, #lineLabels.children do
		for b=1, #lineLabels.children do
			if lineLabels.children[a] ~= lineLabels.children[b] then
				if lineLabels.children[a].y >= lineLabels.children[b].y and lineLabels.children[a].y < lineLabels.children[b].y+11 then
					lineLabels.children[a]:SetPos(0, lineLabels.children[b].y+11)
					doAgain = false
	end end end end
	if doAgain then fixLabelAlignment() end
end
------------------------------------------------------------------------
--Total package of graph: Draws graph and labels for each nonSpec player
local function drawGraph(graphArray, graph_m, teamID)
	if #graphArray == 0 then
		return
	end

	local r,g,b,a = Spring.GetTeamColor( usingAllyteams
		and ((teamID == Spring.GetMyAllyTeamID())
			and Spring.GetMyTeamID()
			or Spring.GetTeamList(teamID)[1])
		or teamID
	)
	local teamColor = {r,g,b,a}
	local lineLabel = numFormat(graphArray[#graphArray])

	local name = ""
	if usingAllyteams then
		name = Spring.GetGameRulesParam("allyteam_long_name_" .. teamID)
	else
		local _,playerID,_,isAI = Spring.GetTeamInfo(teamID)
		if isAI then
			local _,botID,_,shortName = Spring.GetAIInfo(teamID)
			name = (shortName or "Bot") .." - " .. (botID or "")
		else
			name = Spring.GetPlayerInfo(playerID) or playerNames[teamID] or "???"
		end
	end

	for i=1, #graphArray do
		if (graph_m < graphArray[i]) then graph_m = graphArray[i] end
	end

	--gets vertex's from array and plots them
	local drawLine = function()
		for i=1, #graphArray do
			local ordinate = graphArray[i]
			gl.Vertex((i - 1)/(#graphArray - 1), 1 - ordinate/graph_m)
		end
	end

	--adds value to end of graph
	local label1 = Chili.Label:New{parent = lineLabels, y = (1 - graphArray[#graphArray]/graph_m) * 88 - 1 .. "%", width = "100%", caption = lineLabel, font = {color = teamColor}}

	--adds player to Legend
	local label2 = Chili.Label:New{parent = graphPanel, x = 55, y = (teamID)*20 + 5, width = "100%", height  = 20, caption = name, font = {color = teamColor}}

	--creates graph element
	local graph = Chili.Control:New{
		parent	= graphPanel,
		x       = 0,
		y       = 0,
		height  = "100%",
		width   = "100%",
		padding = {0,0,0,0},
		drawcontrolv2 = true,
		DrawControl = function (obj)
			local x = obj.x
			local y = obj.y
			local w = obj.width
			local h = obj.height

			gl.Color(teamColor)
			gl.PushMatrix()
			gl.Translate(x, y, 0)
			gl.Scale(w, h, 1)
			gl.LineWidth(3)
			gl.BeginEnd(GL.LINE_STRIP, drawLine)
			gl.PopMatrix()
		end
		}
end
----------------------------------------------------------------
----------------------------------------------------------------
local function getEngineArrays(statistic, labelCaption)
	local teamScores = {}
	local teams	= Spring.GetTeamList()
	local graphLength = Spring.GetTeamStatsHistory(0)-1
	local generalHistory = Spring.GetTeamStatsHistory(0, 0, graphLength)
	local time = generalHistory[graphLength]["time"]
	--Applies label of the selected graph at bottom of window
	graphLabel:SetCaption(labelCaption)
	
	graphTime:SetCaption("Total Time: " .. formatTime(time))
	curGraph.caption = labelCaption
	curGraph.name = statistic

	--finds highest stat out all the player stats, i.e. the highest point of the graph
	local teamScores = {}
	local graphMax = 0
	local gaia = usingAllyteams
		and select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID()))
		or Spring.GetGaiaTeamID()

	for i=1, #teams do
		local teamID = teams[i]
		local effectiveTeam = usingAllyteams
			and select(6, Spring.GetTeamInfo(teamID))
			or teamID

		teamScores[effectiveTeam] = teamScores[effectiveTeam] or {}
		local stats
		if rulesParamStats[statistic] then
			stats = {}
			for i = 0, graphLength do
				stats[i] = {}
				stats[i][statistic] = Spring.GetTeamRulesParam(teamID, "stats_history_" .. statistic .. "_" .. i) or 0
			end
		else
			stats = Spring.GetTeamStatsHistory(teamID, 0, graphLength)
		end
		for b = 1, graphLength do
			teamScores[effectiveTeam][b] = (teamScores[effectiveTeam][b] or 0) + stats[b][statistic]
			if graphMax < teamScores[effectiveTeam][b] then
				graphMax = teamScores[effectiveTeam][b]
			end
		end
	end

	if graphMax > 5 then drawIntervals(graphMax) end

	for k, v in pairs(teamScores) do
		if k ~= gaia then
			drawGraph(v, graphMax, k)
		end
	end
	fixLabelAlignment()
end

function widget:GameFrame(n)
	-- remember people's names in case they leave
	if n > 0 then
		local teams	= Spring.GetTeamList()
		for i = 1, #teams do
			local teamID = teams[i]
			playerNames[teamID] = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(teamID)))
		end
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

function loadpanel()
	Chili = WG.Chili
	local screen0 = Chili.Screen0
	local selW = 150

	window0 = Chili.Panel:New {
		x = "0", y = "0",
		width = "100%", height = "100%",
		padding = {5,5,5,5}
	}
	lineLabels 	= Chili.Control:New {
		parent = window0,
		right = 0, y = 0,
		width = 37, height = "100%",
		padding = {0,0,0,0},
	}
	graphSelect	= Chili.StackPanel:New {
		parent = window0,
		minHeight = 70,
		x = 0, y = 0,
		width = selW, height = "100%",
		padding = {0,0,0,0},
		itemMargin = {0,0,0,0},
		resizeItems = true,
	}
	graphPanel = Chili.Panel:New {
		parent = window0,
		x = selW, right = 30,
		y = 0, bottom = 40,
		padding = {10,10,10,10}
	}
	graphLabel = Chili.Label:New {
		parent = window0,
		caption = "",
		x = "20%", bottom = 5,
		width = "70%", height = 30, 
		align = "center",
		autosize = true,
		font = {size = 30,},
	}
	graphTime = Chili.Label:New {
		parent = window0,
		bottom = 25, right = 50,
		width = 50, height = 10,
		caption = "",
	}

	for i = 1, #buttons do
		local engineButton = Chili.Button:New {
			name = buttons[i][1],
			caption = buttons[i][2],
			parent = graphSelect,
			OnClick = { function(obj)
				graphPanel:ClearChildren()
				lineLabels:ClearChildren()
				getEngineArrays(obj.name,obj.caption)
			end }
		}
	end

	local allyToggle = Chili.Checkbox:New {
		parent = window0,
		caption = " ",
		right = 32, bottom = 2,
		checked = false,
		OnClick = { function()
			usingAllyteams = not usingAllyteams
			if curGraph.name then
				graphPanel:ClearChildren()
				lineLabels:ClearChildren()
				getEngineArrays(curGraph.name,curGraph.caption)
			end
		end}
	}

	local allyToggleLabel = Chili.Label:New {
		parent = window0,
		caption = "Teams",
		bottom = 5, right = 50,
		width = 50, height = 10,
		align = "right",
	}

	WG.statsPanel = window0
end

function widget:GameOver()
	Spring.SendCommands ("endgraph 0")
	loadpanel()
end
