
function widget:GetInfo() return {
	name    = "Vertical Line on Radar Dots v2",
	desc    = "Helps you identify enemy air units by adding vertical line on radar dots",
	author  = "msafwan",
	date    = "Nov 11, 2012",
	license = "GNU GPL, v2 or later",
	layer   = 20,
	enabled = true,
} end


local last_frame = 0
local disabled = false
local enemyDots = {}
local allyDots = {}
local needsUpdate = false
local myAllyTeamID

local function forceUpdate ()
	needsUpdate = true
end

options_path = 'Settings/Graphics/Unit Visibility/Vertical Lines'
options_order = { 'enable_vertical_lines_air', 'enable_vertical_lines_water', 'enable_vertical_lines_ally' }
options = {
	enable_vertical_lines_air = {
		name = 'Show for enemy aircraft',
		desc = 'Draw a line perpendicular to the ground for enemy airborne units',
		type = 'radioButton',
		value = 'radar',
		items = {
			{key ='always', name='Always'},
			{key ='radar',  name='In radar, not in sight'},
			{key ='never',  name='Never'},
		},
		noHotkey = true,
		OnChange = forceUpdate,
	},
	enable_vertical_lines_water = {
		name = 'Show for enemy underwater',
		desc = 'Draw a line perpendicular to the surface for enemy submerged units',
		type = 'radioButton',
		value = 'radar',
		items = {
			{key ='always', name='Always'},
			{key ='radar',  name='In radar, not in sight'},
			{key ='never',  name='Never'},
		},
		noHotkey = true,
	},
	enable_vertical_lines_ally = {
		name = 'Show for allied units',
		desc = 'Draw the lines for allied units',
		type = 'radioButton',
		value = 'never',
		items = {
			{key ='always', name='Aircraft and Underwater'},
			{key ='air',    name='Aircraft'},
			{key ='water',  name='Underwater'},
			{key ='never',  name='None'},
		},
		noHotkey = true,
	},
}

local function UpdateSpec ()
	if Spring.GetSpectatingState() then
		widgetHandler:RemoveCallIn("DrawWorld")
	else
		widgetHandler:UpdateCallIn("DrawWorld")
	end
	myAllyTeamID = Spring.GetMyAllyTeamID()
end

function widget:Initialize()
	UpdateSpec()
end

function widget:PlayerChanged (playerID)
	UpdateSpec()
end

function widget:UnitEnteredRadar (unitID, unitTeam)
	if (Spring.GetUnitAllyTeam(unitID) ~= myAllyTeamID) then
		local x, y, z = Spring.GetUnitPosition (unitID)
		local losState = Spring.GetUnitLosState(unitID, myAllyTeamID)
		local r, g, b = Spring.GetTeamColor (Spring.GetUnitTeam(unitID))
		enemyDots[unitID] = {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), losState.los, r, g, b} -- x, y, z, ground, inlos, r, g, b
	end
end

function widget:UnitLeftRadar (unitID, unitTeam)
	enemyDots[unitID] = nil
end

function widget:UnitDestroyed (unitID, unitTeam)
	enemyDots[unitID] = nil
	allyDots[unitID] = nil
end

function widget:UnitCreated (unitID)
	if (Spring.GetUnitAllyTeam(unitID) == myAllyTeamID) then
		local x, y, z = Spring.GetUnitPosition (unitID)
		local r, g, b = Spring.GetTeamColor (Spring.GetUnitTeam(unitID))
		allyDots[unitID] = {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), true, r, g, b} -- x, y, z, ground, inlos, r, g, b
	end
end

function widget:DrawWorld()
	local needs_update = needsUpdate
	needsUpdate = false
	local f = Spring.GetGameFrame()
	if f > last_frame then
		last_frame = f
		needs_update = true
	end

	gl.PushAttrib (GL.LINE_BITS)
	gl.DepthTest (true)
	gl.LineWidth (1.4)

	local removals = {}
	for unitID, data in pairs (enemyDots) do
		if needs_update then
			if not Spring.ValidUnitID(unitID) then
				removals[unitID] = true
			else
				local x, y, z = Spring.GetUnitPosition (unitID)
				local losState = Spring.GetUnitLosState(unitID)
				local r, g, b = Spring.GetTeamColor (Spring.GetUnitTeam(unitID))
				data[1] = x
				data[2] = y
				data[3] = z
				data[4] = math.max(Spring.GetGroundHeight(x,z), 0)
				data[5] = losState.los
				data[6] = r
				data[7] = g
				data[8] = b
			end
		end
		if (((data[2] > 0) and ((options.enable_vertical_lines_air.value == "always") or ((options.enable_vertical_lines_air.value == "radar") and (not data[5])))) or ((data[2] < 0) and ((options.enable_vertical_lines_water.value == "always") or ((options.enable_vertical_lines_water.value == "radar") and (not data[5]))))) then
			gl.Color (data[6], data[7], data[8], 1)
			gl.BeginEnd(GL.LINES, function()
				gl.Vertex(data[1],data[4],data[3])
				gl.Vertex(data[1],data[2],data[3])
			end)
		end
	end
	for unitID in pairs (removals) do
		enemyDots[unitID] = nil
	end

	if options.enable_vertical_lines_ally.value ~= "never" then
		local show_air   = ((options.enable_vertical_lines_ally.value == "always") or (options.enable_vertical_lines_ally.value == "air"))
		local show_water = ((options.enable_vertical_lines_ally.value == "always") or (options.enable_vertical_lines_ally.value == "water"))
		for unitID, data in pairs (allyDots) do
			if needs_update then
				local x, y, z = Spring.GetUnitPosition (unitID)
				local r, g, b = Spring.GetTeamColor (Spring.GetUnitTeam(unitID))
				data[1] = x
				data[2] = y
				data[3] = z
				data[4] = math.max(Spring.GetGroundHeight(x,z), 0)
				data[5] = true
				data[6] = r
				data[7] = g
				data[8] = b
			end
			if ((data[2] > 0) and show_air) or ((data[2] < 0) and show_water) then
				gl.Color (data[6], data[7], data[8], 1)
				gl.BeginEnd(GL.LINES, function()
					gl.Vertex(data[1],data[4],data[3])
					gl.Vertex(data[1],data[2],data[3])
				end)
			end
		end
	end

	gl.DepthTest (false)
	gl.Color (1,1,1,1)
	gl.PopAttrib ()
end
