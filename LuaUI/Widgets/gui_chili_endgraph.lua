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
		{"unit_value_def"  , "Defense Value", "Value of armed structures (and shields) with range up to and including Cerebus and Aretemis."},
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
local echo 		= Spring.Echo

-- CHILI CONTROLS
local Chili, window0, graphPanel, graphSelect, graphLabel, graphTime
local wasActive = {}
local playerNames = {}

local SELECT_BUTTON_COLOR = {0.98, 0.48, 0.26, 0.85}
local SELECT_BUTTON_FOCUS_COLOR = {0.98, 0.48, 0.26, 0.85}
local BUTTON_COLOR
local BUTTON_FOCUS_COLOR

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
				caption = numFormat(graphMax*i/5)
			}
		end
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
local function drawGraph(graphArray, graphMax, teamID, team_num)
	if #graphArray == 0 then
		return
	end
	
	local r,g,b,a = Spring.GetTeamColor(
		usingAllyteams
		and ((teamID == Spring.GetMyAllyTeamID()) and Spring.GetMyTeamID() or Spring.GetTeamList(teamID)[1])
		or teamID
	)
	local teamColor = {r,g,b,a}
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
		font = {color = teamColor},
	}

	--adds player to Legend
	if team_num then
		local label2 = Chili.Label:New{
			parent = graphPanel,
			x = 55, y = (team_num)*20 + 5,
			width = "100%",
			height = 20,
			caption = name,
			font = {color = teamColor}
		}
	end

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

local function getEngineArrays(statistic, labelCaption)
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
			fontsize = 60,
		}
		return
	end

	--finds highest stat out all the player stats, i.e. the highest point of the graph
	local teamScores = {}
	local graphMax = 0
	local gaia = usingAllyteams
		and select(6, Spring.GetTeamInfo(Spring.GetGaiaTeamID(), false))
		or Spring.GetGaiaTeamID()

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
	
	local team_i = 1
	for k, v in pairs(teamScores) do
		if k ~= gaia then
			drawGraph(v, graphMax*1.005, k, team_i)
		end
		team_i = team_i + 1
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
		font = {size = 30,},
	}
	graphTime = Chili.Label:New {
		parent = window0,
		bottom = 25,
		right = 50,
		width = 50,
		height = 10,
		caption = "",
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
			font = {
				size          = 16,
				color         = {1,1,0,1},
			},

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
		caption = " ",
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

