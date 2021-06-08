--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name    = "EndGame Stats",
		desc    = "v0.913 Chili replacement for default end game statistics",
		author  = "Funkencool",
		date    = "2013",
		license = "public domain",
		layer   = -1,
		enabled = true
	}
end

--[[
	TO DO:
		Add amount label when mouseover line on graph (e.g to see exact metal produced at a certain time),
		Come up with better way of handling specs, active players and players who died (currently doesn't show players who have died
--]]

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local GetHiddenTeamRulesParam = Spring.Utilities.GetHiddenTeamRulesParam

local buttongroups = {
	{"Economy", {
		{"metalProduced"   , "Metal Produced", "Cumulative total of metal produced."},
		{"metalUsed"       , "Metal Used", "Cumulative total of metal used."},
		{"metal_income"    , "Metal Income", "Total metal income."},
		{"metal_overdrive" , "Metal Overdrive", "Cumulative total of metal produced by overdrive."},
		{"metal_reclaim"   , "Metal Reclaimed", "Cumulative total of metal reclaimed. Includes wreckage, unit reclaim and construction cancellation."},
		{"metal_excess"    , "Metal Excess", "Cumulative total of metal lost to excess."},
		{"energy_income"   , "Energy Income", "Total energy income."},
		},
	},

	{"Units", {
		{"unit_value"      , "Total Value", "Total value of units and structures."},
		{"unit_value_army" , "Army Value", "Value of mobile units excluding constructors, commanders, Iris, Owl, Djinn, Charon and Hercules."},
		{"unit_value_def"  , "Defense Value", "Value of armed structures (and shields) with range up to and including Cerberus and Artemis."},
		{"unit_value_econ" , "Economy Value", "Value of economic structures, factories and constructors."},
		{"unit_value_other", "Other Value", "Value of units and structures that do not fit any other category."},
		{"unit_value_killed", "Value Killed", "Cumulative total of value of enemy units and structured destroyed by the team. Includes nanoframes."},
		{"unit_value_lost" , "Value Lost", "Cumulative total of value of the teams destroyed units and structures. Includes nanoframes."},
		{"damage_dealt"    , "Damage Dealt", "Cumulative damage inflicted measured by the cost of the damaged unit in proportion to damage dealt."},
		{"damage_received" , "Damage Received", "Cumulative damage received measured by the cost of the damaged unit in proportion to damage dealt."},
		},
	},
}

local rulesParamStats = {
	metal_excess = true,
	metal_overdrive = true,
	metal_reclaim = true,
	unit_value = true,
	unit_value_army = true,
	unit_value_def = true,
	unit_value_econ = true,
	unit_value_other = true,
	unit_value_killed = true,
	unit_value_lost = true,
	metal_income = true,
	energy_income = true,
	damage_dealt = true,
	damage_received = true,
}
local hiddenStats = {
	damage_dealt = true,
	unit_value_killed = true,
}

local gameOver = false

local graphLength = 0
local usingAllyteams = false
local curGraph = {}

-- Spring aliases
local echo = Spring.Echo

-- CHILI CONTROLS
local Chili, window0, graphPanel, graphSelect, graphLabel, graphTime
local wasActive = {}
local playerNames = {}
local highlightedTeamId = false
local highlightedAllyTeamId = false

local gaiaTeamID = Spring.GetGaiaTeamID()

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR

local TEAM_WRAP = 20

local teamToPosition = {}
do
	local pos = 1
	
	local spectating = Spring.GetSpectatingState()
	local myAllyTeam = false
	if not spectating then
		myAllyTeam = Spring.GetMyAllyTeamID()
		teamToPosition[Spring.GetMyTeamID()] = pos
		pos = pos + 1
	end
	
	local function SetAllyTeamPositions(allyTeamID)
		local teamList = Spring.GetTeamList(allyTeamID)
		for i = 1, #teamList do
			local teamID = teamList[i]
			if teamID ~= gaiaTeamID and not teamToPosition[teamID] then
				teamToPosition[teamID] = pos
				pos = pos + 1
			end
		end
	end
	
	if myAllyTeam then
		SetAllyTeamPositions(myAllyTeam)
	end
	
	local allyTeamList = Spring.GetAllyTeamList()
	for i = 1, #allyTeamList do
		if allyTeamList[i] ~= myAllyTeam then
			SetAllyTeamPositions(allyTeamList[i])
		end
	end
end

local function TeamToPosition(teamID)
	return teamToPosition[teamID] or 0
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--utilities

local teamNames = {}

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
	if minutes < 10 then
		minutes = "0" .. minutes
	end
	if seconds < 10 then
		seconds = "0" .. seconds
	end
	return hours .. ":" .. minutes .. ":" .. seconds
end

local function drawIntervals(graphMax)
	for i = 1, 4 do
		local line = Chili.Line:New{
			parent = graphPanel,
			x = 0,
			bottom = (0.997*(i)/5*100 - 0.8) .. "%",
			height = 0,
			width = "100%",
			color = {0.1,0.1,0.1,0.1}
		}
		if graphMax then
			local label = Chili.Label:New{
				parent = graphPanel,
				x = 5,
				bottom = ((i)/5*100 + 1) .. "%",
				width = "100%",
				caption = numFormat(graphMax*i/5),
				objectOverrideFont = WG.GetFont(),
			}
		end
	end
end

local getEngineArrays = function(name, caption) end

local function SetHighlightedTeam(teamID)
	if highlightedTeamId == teamID then
		highlightedTeamId = false
	else
		highlightedTeamId = teamID
	end
	if curGraph.name then
		graphPanel:ClearChildren()
		lineLabels:ClearChildren()
		getEngineArrays(curGraph.name,curGraph.caption)
	end
end

local function SetHighlightedAllyTeam(allyTeamID)
	if highlightedAllyTeamId == allyTeamID then
		highlightedAllyTeamId = false
	else
		highlightedAllyTeamId = allyTeamID
	end
	if curGraph.name then
		graphPanel:ClearChildren()
		lineLabels:ClearChildren()
		getEngineArrays(curGraph.name,curGraph.caption)
	end
end

-- This is broken.
--
-- It sets the label's new position in absolute pixels instead of percent, which means
-- that the label is now in a fixed position; if you resize the window, the repositioned
-- label moves out of place relative to the graph. And if you resize the window enough,
-- the repositioned label may move outside the window, creating scrollbars and bogus
-- blank space below the graphs.
--
-- It could set the new position using percentages, but then the problem arises that
-- the adjustment is in pixels (11 pixels, the height of the text), so you have to convert
-- that to percent. You could figure out what that is using adjustment_pct = 11 / parent_window_height,
-- but the parent window height is defined as 100%, and if you query the parent window
-- for its height, it returns it in pixels... but with the wrong value.
--
-- So for now I'm just commenting this out. Even besides the scrollbar issue, it was never
-- working right before - it couldn't correctly deal with multiple overlapping labels.
-- Shouldn't be a problem; overlapping labels are rare, and not that big a deal when
-- they do happen.
--
--[[
local function fixLabelAlignment()
	local doAgain
	for a = 1, #lineLabels.children do
		for b = 1, #lineLabels.children do
			if lineLabels.children[a] ~= lineLabels.children[b] then
				if lineLabels.children[a].y >= lineLabels.children[b].y and lineLabels.children[a].y < lineLabels.children[b].y+11 then
					lineLabels.children[a]:SetPos(0, lineLabels.children[b].y+11)
					doAgain = false
				end
			end
		end
	end
	if doAgain then
		fixLabelAlignment()
	end
end
--]]

local function SetButtonSelected(button, isSelected)
	if isSelected then
		button.backgroundColor = SELECT_BUTTON_COLOR
		button.focusColor = SELECT_BUTTON_FOCUS_COLOR
	else
		button.backgroundColor = BUTTON_COLOR
		button.focusColor = BUTTON_FOCUS_COLOR
	end
	button:Invalidate()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--draw graphs

--Total package of graph: Draws graph and labels for each nonSpec player
local function drawGraph(graphArray, graphMax, teamID, team_num, isHighlighted)
	if #graphArray == 0 then
		return
	end
	
	local r,g,b,a = Spring.GetTeamColor(
		usingAllyteams
		and ((teamID == Spring.GetMyAllyTeamID()) and Spring.GetMyTeamID() or Spring.GetTeamList(teamID)[1])
		or teamID
	)
	local teamColor = {r,g,b,a}
	local teamColorDark = {r*0.32,g*0.32,b*0.32,a}
	local lineLabel = numFormat(graphArray[#graphArray])

	local name = ""
	if usingAllyteams then
		name = Spring.GetGameRulesParam("allyteam_long_name_" .. teamID)
	else
		name = teamNames[teamID] or "???"
	end

	for i = 1, #graphArray do
		if (graphMax < graphArray[i]) then
			graphMax = graphArray[i]
		end
	end

	--gets vertex's from array and plots them
	local drawLine = function()
		for i = 1, #graphArray do
			local ordinate = graphArray[i]
			gl.Vertex((i - 1)/(#graphArray - 1), 0.9975 - ordinate/graphMax)
		end
	end

	--adds value to end of graph
	local labelOffBottom = (graphArray[#graphArray]/graphMax > 0.025)
	local label1 = Chili.Label:New{
		parent = lineLabels,
		y = labelOffBottom and ((1 - graphArray[#graphArray]/graphMax) * 100 - 1 .. "%"),
		bottom = (not labelOffBottom) and 1,
		width = "100%",
		caption = lineLabel,
		font = {color = (isHighlighted and teamColor) or teamColorDark},
	}

	--adds player to Legend
	if team_num then
		local label2 = Chili.Button:New{
			parent = graphPanel,
			x = 40 + 230*math.floor((team_num - 1)/TEAM_WRAP), y = ((team_num - 1)%TEAM_WRAP)*20 + 16,
			width = 230,
			height = 20,

			borderColor     = {0, 0, 0, 0},
			borderColor2    = {0, 0, 0, 0},
			backgroundColor = {0, 0, 0, 0},
			caption = name,
			align= "left",
			alignPadding = 0.08,
			font = {color = (isHighlighted and teamColor) or teamColorDark},
			noClickThrough = true,
			OnClick = {
				function(...)
					if usingAllyteams then
						SetHighlightedAllyTeam(teamID)
					else
						SetHighlightedTeam(teamID)
					end
				 end
			}
		}
	end

	--creates graph element
	local graph = Chili.Control:New{
		parent  = graphPanel,
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

			gl.PushMatrix()
			gl.Translate(x, y, 0)
			gl.Scale(w, h, 1)
			gl.LineWidth((isHighlighted and 3) or 2)
			if isHighlighted then
				gl.Color(teamColor)
			else
				gl.Color(teamColorDark)
			end
			gl.BeginEnd(GL.LINE_STRIP, drawLine)
			gl.PopMatrix()
		end
	}
	
	return graph
end

getEngineArrays = function(statistic, labelCaption)
	local teamScores = {}
	local teams = Spring.GetTeamList()
	local graphLength = Spring.GetGameRulesParam("gameover_historyframe") or (Spring.GetTeamStatsHistory(Spring.GetMyTeamID()) - 1)
	local generalHistory = Spring.GetTeamStatsHistory(0, 0, graphLength)
	local totalTime = Spring.GetGameRulesParam("gameover_second")
		or (generalHistory and generalHistory[graphLength] and generalHistory[graphLength]["time"])
		or 0

	--Applies label of the selected graph at bottom of window
	graphLabel:SetCaption(labelCaption)
	
	graphTime:SetCaption("Total Time: " .. formatTime(totalTime))
	curGraph.caption = labelCaption
	curGraph.name = statistic
	
	-- If there's not at least two data points then don't draw the graph, labels, intervals, or players
	if graphLength < 2 then
		Chili.Label:New{
			parent = graphPanel,
			x = "10%",
			y = "30%",
			width = "80%",
			height = "100%",
			caption = "No Data",
			align = "center",
			textColor = {1,1,0,1},
			objectOverrideFont = WG.GetFont(fontsize),
		}
		return
	end

	--finds highest stat out all the player stats, i.e. the highest point of the graph
	local teamScores = {}
	local graphMax = 0
	local gaia = usingAllyteams
		and select(6, Spring.GetTeamInfo(gaiaTeamID, false))
		or gaiaTeamID

	for i = 1, #teams do
		local teamID = teams[i]
		if Spring.GetTeamStatsHistory(teamID, 0, graphLength) then

			local effectiveTeam = usingAllyteams
				and select(6, Spring.GetTeamInfo(teamID, false))
				or teamID

			teamScores[effectiveTeam] = teamScores[effectiveTeam] or {}
			local stats
			if rulesParamStats[statistic] then
				stats = {}
				for i = 0, graphLength do
					stats[i] = {}
					if hiddenStats[statistic] and gameOver then
						stats[i][statistic] = GetHiddenTeamRulesParam(teamID, "stats_history_" .. statistic .. "_" .. i) or 0
					else
						stats[i][statistic] = Spring.GetTeamRulesParam(teamID, "stats_history_" .. statistic .. "_" .. i) or 0
					end
				end
			else
				stats = Spring.GetTeamStatsHistory(teamID, 0, graphLength)
			end
			for b = 1, graphLength do
				teamScores[effectiveTeam][b] = (teamScores[effectiveTeam][b] or 0) + (stats and stats[b][statistic] or 0)
				if graphMax < teamScores[effectiveTeam][b] then
					graphMax = teamScores[effectiveTeam][b]
				end
			end
		end
	end

	if graphMax < 5 then
		graphMax = 5
	end
	
	local highlightID = (usingAllyteams and highlightedAllyTeamId)
	if not usingAllyteams then
		highlightID = highlightedTeamId
	end
	
	local team_i = 1
	for teamID, v in pairs(teamScores) do
		if teamID ~= gaia and teamID ~= highlightID then
			drawGraph(v, graphMax*1.005, teamID, TeamToPosition(teamID), not highlightID)
		end
	end
	if highlightID then
		local graph = drawGraph(teamScores[highlightID], graphMax*1.005, highlightID, TeamToPosition(highlightID), true)
		if graph then
			graph:BringToFront()
		end
	end

	-- Commented out for now because it's broken; see above
	-- fixLabelAlignment()

	graphPanel:Invalidate()
	graphPanel:UpdateClientArea()
	drawIntervals(graphMax)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--setup

function makePanel()
	Chili = WG.Chili
	local selW = 140

	window0 = Chili.Control:New {
		x = "0",
		y = "0",
		width = "100%",
		height = "100%",
		padding = {0,0,0,4},
		buttonPressed = 1,
	}
	lineLabels = Chili.Control:New {
		parent = window0,
		y = 0,
		right = 0,
		bottom = 40,
		width = 35,
		padding = {0,0,0,0},
	}
	graphSelect	= Chili.StackPanel:New {
		parent = window0,
		minHeight = 70,
		x = 0,
		y = 0,
		width = selW,
		height = "100%",
		padding = {0,0,0,0},
		itemMargin = {0,0,0,0},
		resizeItems = true,
		weightedResize = true,
	}
	graphPanel = Chili.Panel:New {
		parent = window0,
		x = selW + 4,
		right = 40,
		y = 0,
		bottom = 40,
		padding = {2, 2, 2, 2},
	}
	graphLabel = Chili.Label:New {
		parent = window0,
		caption = "",
		x = "20%",
		bottom = 5,
		width = "70%",
		height = 30,
		align = "center",
		autosize = true,
		objectOverrideFont = WG.GetFont(30),
	}
	graphTime = Chili.Label:New {
		parent = window0,
		bottom = 25,
		right = 50,
		width = 50,
		height = 10,
		caption = "",
		objectOverrideFont = WG.GetFont(),
	}

	drawIntervals()
	graphPanel:Invalidate()
	graphPanel:UpdateClientArea()

	window0.graphButtons = {}
	local gb_i = 1
	for i = 1, #buttongroups do
		local grouppanel = Chili.Panel:New {
			parent = graphSelect,
			weight = #buttongroups[i][2] + 0.7,
			padding = {1,1,1,1},
		}
		local grouplabel = Chili.Label:New {
			parent = grouppanel,
			x = 5,
			y = 3,
			caption = buttongroups[i][1],
			objectOverrideFont = WG.GetSpecialFont(16, "yellow", {color = {1,1,0,1}}),

		}
		local groupstack = Chili.StackPanel:New {
			parent = grouppanel,
			x = 0,
			y = 16,
			bottom = 0,
			width = "100%",
			itemMargin = {1,1,1,2},
			resizeItems = true,
		}
		for j = 1, #buttongroups[i][2] do
			local gb_il = gb_i -- even more local instance than gb_i
			window0.graphButtons[gb_i] = Chili.Button:New {
				name = buttongroups[i][2][j][1],
				caption = buttongroups[i][2][j][2],
				tooltip = buttongroups[i][2][j][3],
				parent = groupstack,
				objectOverrideFont = WG.GetFont(),
				OnClick = {
					function(obj)
						if window0.buttonPressed then
							SetButtonSelected(window0.graphButtons[window0.buttonPressed], false)
						end
						window0.buttonPressed = gb_il -- has to be the very local one
						SetButtonSelected(obj, true)
						graphPanel:ClearChildren()
						lineLabels:ClearChildren()
						getEngineArrays(obj.name,obj.caption)
					end
				}
			}
			gb_i = gb_i + 1
		end
	end
	BUTTON_COLOR = window0.graphButtons[1].backgroundColor
	BUTTON_FOCUS_COLOR = window0.graphButtons[1].focusColor

	local allyToggle = Chili.Checkbox:New {
		parent = window0,
		noFont = true,
		right = 32, bottom = 2,
		checked = false,
		OnClick = {
			function()
				usingAllyteams = not usingAllyteams
				if curGraph.name then
					graphPanel:ClearChildren()
					lineLabels:ClearChildren()
					getEngineArrays(curGraph.name,curGraph.caption)
				end
			end
		}
	}

	local allyToggleLabel = Chili.Label:New {
		parent = window0,
		caption = "Teams",
		bottom = 5, right = 50,
		width = 50, height = 10,
		align = "right",
		objectOverrideFont = WG.GetFont(),
	}

	return window0
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--callins

function widget:Initialize()
	WG.MakeStatsPanel = makePanel

	local teams = Spring.GetTeamList()
	for i = 1, #teams do
		local teamID = teams[i]
		local _, playerID, _, isAI = Spring.GetTeamInfo(teamID, false)
		local name
		if isAI then
			name = select(2, Spring.GetAIInfo(teamID))
		else
			name = Spring.GetPlayerInfo(playerID, false)
		end
		teamNames[teamID] = name
	end
end

function widget:GameOver()
	gameOver = true
end

function widget:GameFrame(n)
	-- remember people's names in case they leave
	if n > 0 then
		local teams	= Spring.GetTeamList()
		for i = 1, #teams do
			local teamID = teams[i]
			playerNames[teamID] = Spring.GetPlayerInfo(select(2, Spring.GetTeamInfo(teamID, false)), false)
		end
		widgetHandler:RemoveCallIn("GameFrame")
	end
end

