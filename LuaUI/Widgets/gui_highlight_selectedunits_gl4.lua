function widget:GetInfo()
	return {
		name = "Highlight Selected Units GL4",
		desc = "Highlights the selelected units",
		author = "Floris (original: zwzsg, from trepan HighlightUnit)",
		date = "Apr 24, 2009",
		license = "GNU GPL, v2 or later",
		layer = 1,
		enabled = false
	}
end

local hideBelowGameframe = 100
local useTeamcolor = true
local highlightAlpha = 0.05
local teamColorAlphaMult = 1.33
local edgeExponent = 1.7
local minEdgeAlpha = 0.2

local unitshapes = {}

local selectedUnits = Spring.GetSelectedUnits()
local hidden = (Spring.GetGameFrame() <= hideBelowGameframe)

local spGetUnitTeam = Spring.GetUnitTeam

local teamColor = {}
local teams = Spring.GetTeamList()
for i = 1, #teams do
	local r, g, b = Spring.GetTeamColor(teams[i])
	local min = 0.5
	teamColor[teams[i]] = { math.max(r, min), math.max(g, min), math.max(b, min) }
end
teams = nil

local function SetupCommandColors(state)
	local alpha = state and 1 or 0
	local f = io.open('cmdcolors.tmp', 'w+')
	if f then
		f:write('unitBox  0 1 0 ' .. alpha)
		f:close()
		Spring.SendCommands({ 'cmdcolors cmdcolors.tmp' })
	end
	os.remove('cmdcolors.tmp')
end

local function addUnitShape(unitID)
	if not WG.HighlightUnitGL4 then
		widget:Shutdown()
	else
		local r,g,b
		local a = highlightAlpha
		if useTeamcolor then
			local teamID = spGetUnitTeam(unitID)
			if teamID then
				r, g, b = teamColor[teamID][1], teamColor[teamID][2], teamColor[teamID][3]
				a = a * teamColorAlphaMult
			end
		end
		unitshapes[unitID] = WG.HighlightUnitGL4(unitID, 'unitID', 0.2, 1, 0.7, 0.2, 1, 1.4, 0.8, 0, 0, 0)
		return unitshapes[unitID]
	end
end

local function removeUnitShape(unitID)
	if not WG.StopHighlightUnitGL4 then
		widget:Shutdown()
	elseif unitID and unitshapes[unitID] then
		WG.StopHighlightUnitGL4(unitshapes[unitID])
		unitshapes[unitID] = nil
	end
end

local function processSelection()
	local deselectedUnits = {}
	for k, v in next, unitshapes, nil do
		deselectedUnits[k] = true
	end
	for i, unitID in ipairs(selectedUnits) do
		if not unitshapes[unitID] then
			Spring.Echo("addUnitShape")
			addUnitShape(unitID)
		end
		deselectedUnits[unitID] = nil
	end
	for unitID, _ in pairs(deselectedUnits) do
		removeUnitShape(unitID)
	end
end

local function refresh()
	for unitID, _ in pairs(unitshapes) do
		removeUnitShape(unitID)
	end
	processSelection()
end

function widget:UnitDestroyed(unitID)	-- maybe not needed if widget:SelectionChanged(sel) is fast enough, but lets not risk it
	if unitshapes[unitID] then
		removeUnitShape(unitID)
	end
end

function widget:GameFrame(gf)
	if hidden and gf > hideBelowGameframe then
		hidden = false
		processSelection()
	end
end

function widget:Initialize()
	if not WG.HighlightUnitGL4 then
		Spring.Echo("WG.HighlightUnitGL4 not found, removing highlight selected units.")
		widgetHandler:RemoveWidget()
		return
	end

	WG['highlightselunits'] = {}
	WG['highlightselunits'].getOpacity = function()
		return highlightAlpha
	end
	WG['highlightselunits'].setOpacity = function(value)
		highlightAlpha = value
		refresh()
	end
	WG['highlightselunits'].getTeamcolor = function()
		return useTeamcolor
	end
	WG['highlightselunits'].setTeamcolor = function(value)
		useTeamcolor = value
		refresh()
	end

	SetupCommandColors(false)
	processSelection()
end

function widget:Shutdown()
	if WG['selectedunits'] == nil then
		SetupCommandColors(true)
	end
	WG['highlightselunits'] = nil
	if WG.StopHighlightUnitGL4 then
		for id, _ in pairs(unitshapes) do
			removeUnitShape(id)
		end
	end
end

function widget:SelectionChanged(sel)
	selectedUnits = sel
	processSelection()
end

local version = 1
function widget:GetConfigData()
	return {
		version = version,
		highlightAlpha = highlightAlpha,
		useTeamcolor = useTeamcolor,
	}
end

function widget:SetConfigData(data)
	if data.version and data.version >= version then
		if data.highlightAlpha ~= nil then
			highlightAlpha = data.highlightAlpha
		end
		if data.useTeamcolor ~= nil then
			useTeamcolor = data.useTeamcolor
		end
	end
end