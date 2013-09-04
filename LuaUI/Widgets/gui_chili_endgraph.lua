--[[
	TO DO:
		Add amount label when mouseover line on graph (e.g to see exact metal produced at a certain time),
		Implement camera control to pan in the background while viewing graph,
		Add minimize option
		Come up with better way of handling specs, active players and players who died (currently doesn't show players who have died

	Graph Ideas:
		Total metal in units and/or buildings
		Total metal in units/# of units, (Average cost of units)
		Metal spent - damage recieved = total metal in units?

]]
function widget:GetInfo()
	return {
		name		    = "EndGame Stats v0.9",
		desc		    = "v0.91 Chili replacement for default end game statistics",
		author		  = "Funkencool",
		date		    = "2013",
		license     = "public domain",
		layer		    = -1,
		enabled   	= true
	}
end

--[[
	changelog:
		0.91 - CarRepairer
			- Added fixes to prevent widget crash when running spring.exe.
			- Integrated with awards gadget.
--]]

local testing = false
-- INCLUDES

--comment out any stats you don't want included, order also directly effects button layout.. [1] = engineName, [2] = Custom Widget Name (can change)
local engineStats = {
	--{"time"            , "time"},
	-- {"frame"           , ""},
	{"metalUsed"       , "Metal Used"},
	{"metalProduced"   , "Metal Produced"},
	{"metalExcess"     , "Metal Excess"},
	{"metalReceived"   , "Metal Received"},
	{"metalSent"       , "Metal Sent"},
	{"energyUsed"      , "Energy Used"},
	{"energyProduced"  , "Energy Produced"},
	{"energyExcess"    , "Energy Excess"},
	{"energyReceived"  , "Energy Received"},
	{"energySent"      , "Energy Sent"},
	{"damageDealt"     , "Damage Dealt"},
	{"damageReceived"  , "Damage Received"},
	{"unitsProduced"   , "Units Built"},
	{"unitsKilled"     , "Units Killed"},
	{"unitsDied"       , "Units Lost"},
	{"unitsReceived"   , "Units Received"},
	{"unitsSent"       , "Units Sent"},
	{"unitsCaptured"   , "Units Captured"},
	-- {"unitsOutCaptured", ""},
}

local graphLength = 0
local gameOver = false
local isDelta = false
local curGraph = {}

local echo = Spring.Echo

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
	local minutes = math.floor(seconds/60)
	local hours = math.floor(minutes/60)
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
	--get's all the needed info about players and teams
	local _,teamLeader,isDead,isAI = Spring.GetTeamInfo(teamID)
	local playerName, isActive, isSpec = Spring.GetPlayerInfo(teamLeader)
	local r,g,b,a = Spring.GetTeamColor(teamID)
	local teamColor = {r,g,b,a}
	local lineLabel = numFormat(graphArray[#graphArray])
	local shortName
	--playerName = playerNames[teamID]
	--Sets AI name to reflect AI used and player hosting it
	if isAI then
		local _,botID,_,shortName = Spring.GetAIInfo(teamID)
		playerName = shortName .."-" .. botID .. ""
	end


--	if isActive or wasActive[teamID] then --Prevents specs from being included in Graph
	if isActive or isDead then --Prevents specs from being included in Graph
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
		local label2 = Chili.Label:New{parent = graphPanel, x = 55, y = (teamID)*20 + 5, width = "100%", height  = 20, caption = playerName, font = {color = teamColor}}

		--creates graph element
		local graph = Chili.Control:New{
			parent	= graphPanel,
			x       = 0,
			y       = 0,
			height  = "100%",
			width   = "100%",
			padding = {0,0,0,0},
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
end
----------------------------------------------------------------
----------------------------------------------------------------
local function getEngineArrays(statistic, labelCaption)
	local teamScores = {}
	local teams	= Spring.GetTeamList()
	local teams = (#teams - 1)
	local graphLength = Spring.GetTeamStatsHistory(0)-1
	local time = Spring.GetTeamStatsHistory(0, 0, graphLength)
	local time = time[graphLength]["time"]
	--Applies label of the selected graph at bottom of window
	graphLabel:SetCaption(labelCaption)
	
	graphTime:SetCaption("Total Time: " .. formatTime(time))
	curGraph.caption = labelCaption
	curGraph.name = statistic

	--finds highest stat out all the player stats, i.e. the highest point of the graph
	local teamScores = {}
	local graphMax = 0
	for a=0, teams do
		local temp = {}
		local stats = Spring.GetTeamStatsHistory(a, 0, graphLength)
		for b=1, graphLength - 1 do
			temp[b] = stats[b][statistic]
			if isDelta then temp[b] = stats[b+1][statistic] - stats[b][statistic] end
			if (graphMax < temp[b]) then graphMax = temp[b] end --TODO: check for to see if team has any stats, if not don't show
		end
		teamScores[a] = temp
	end
	if graphMax > 5 then drawIntervals(graphMax) end
	for a=0, teams do
		drawGraph(teamScores[a], graphMax, a)	--Applies per player elements
	end
	fixLabelAlignment()
end
-----------------------------------------------------------------------
-- Starting point: Draws all the main elements which are later tailored
function loadpanel()
echo 'LOAD PANEL'
	Chili = WG.Chili
	local screen0 = Chili.Screen0
	local selW  = 150
	window0 		= Chili.Window:New{parent = screen0, x = "20%", y = "20%", width = "60%", height = "60%", padding = {5,5,5,5}}

	lineLabels 	= Chili.Control:New{parent = window0, right = 0, y = 0, width = 37, height = "100%", padding = {0,0,0,0},}
	graphSelect	= Chili.StackPanel:New{minHeight = 70, parent = window0, x =  0, y = 0, width = selW, height = "100%",}
	graphPanel 	= Chili.Panel:New{parent = window0, x = selW, right = 30, y = 0, bottom = 40, padding = {10,10,10,10}}
	graphLabel  = Chili.Label:New{autosize = true, parent = window0, bottom = 0,caption = "", align = "center", width = "70%", x = "20%", height = "10%", font = {size = 30,},}
	graphTime		= Chili.Label:New{parent = window0, bottom = 30,caption = "", width = 50, right = 50, height = 10}

	for a=1, #engineStats do
		local engineButton =	Chili.Button:New{name = engineStats[a][1], caption = engineStats[a][2], maxHeight = 30, parent = graphSelect, OnClick = {
			function(obj) graphPanel:ClearChildren();lineLabels:ClearChildren();getEngineArrays(obj.name,obj.caption);end}}
	end

	local exitButton = Chili.Button:New{name = "exit", caption = "Exit", bottom = 0, right = 0, height = 30, width = 40 , parent = window0, OnClick = {
		function() Spring.SendCommands("quit");end}}
	local exitButton = Chili.Button:New{caption = "Delta", bottom = 0, right = 45, height = 30, width = 50 , parent = window0, OnClick = {
		function()  isDelta = not isDelta; if curGraph.name then graphPanel:ClearChildren();lineLabels:ClearChildren();getEngineArrays(curGraph.name,curGraph.caption)end;end}}

end

--to do: possible to run from start when playing as spec
function widget:GameStart()
	local teams	= Spring.GetTeamList()
	local teams = (#teams - 1)
	for teamID=0, teams do
		playerNames[teamID],_ = Spring.GetPlayerInfo(teamID)
		--Spring.Echo(playerNames[teamID])
	end
end

function widget:GameOver()
	gameOver = true
	Spring.SendCommands("endgraph 0")
	--loadpanel()
end

function widget:Initialize()
	widgetHandler:RegisterGlobal("LoadEndGamePanel", loadpanel)
end

function widget:Shutdown()
	widgetHandler:DeregisterGlobal("LoadEndGamePanel")
end
