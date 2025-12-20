
function widget:GetInfo()
	return {
		name    = "Vertical Line on Radar Dots v2",
		desc    = "Helps you identify enemy air units by adding vertical line on radar dots",
		author  = "msafwan, GoogleFrog",
		date    = "Nov 11, 2012",
		license = "GNU GPL, v2 or later",
		layer   = 20,
		enabled = true,
	}
end


local last_frame = 0
local disabled = false
local enemyDots = {}
local allyDots = {}
local needsUpdate = false
local myAllyTeamID

local function forceUpdate ()
	needsUpdate = true
end

local VERT_LINE_THRESHOLD = 30
local HIGH_THRESHOLD = 750
local HIGH_UPPER = 700
local HIGH_LOWER = 350

local ALLY_THROW_ALPHA = 0.5
local WARN_TEXTURE  = "icons/kbotexclaim.dds"

local iconTypesPath = LUAUI_DIRNAME.."Configs/icontypes.lua"
local _, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)
local iconCache = {}

local function GetUnitIcon(unitDefID)
	if not unitDefID then
		return WARN_TEXTURE
	end
	if not iconCache[unitDefID] then
		ud = UnitDefs[unitDefID]
		iconCache[unitDefID] = icontypes[(ud and ud.iconType or "default")].bitmap or 'icons/'.. ud.iconType ..iconFormat
	end
	return iconCache[unitDefID]
end

local wantDrawCache = {}
local function WantDrawUnit(unitDefID)
	if not unitDefID then
		return true -- Fake enemy units are never detectable
	end
	if unitDefID and not wantDrawCache[unitDefID] then
		ud = UnitDefs[unitDefID]
		wantDrawCache[unitDefID] = ud.customParams.completely_hidden and 0 or 1
	end
	return (wantDrawCache[unitDefID] == 1)
end

local spectating, fullview = Spring.GetSpectatingState()

options_path = 'Settings/Graphics/Unit Visibility/Vertical Lines'
options_order = { 'enable_high', 'high_fly_size', 'ally_high_alpha', 'enable_vertical_lines_air', 'enable_vertical_lines_water', 'enable_vertical_lines_ally' }
options = {
	enable_high = {
		name = 'Show for high up units',
		desc = 'Draw a line for very high up enemies',
		type = 'radioButton',
		value = 'always',
		items = {
			{key ='always', name='All units'},
			{key ='enemies', name='Enemy units'},
			{key ='never',  name='Never'},
		},
		noHotkey = true,
		OnChange = forceUpdate,
	},
	high_fly_size = {
		name = 'High unit icon size',
		type = 'number',
		min = 10, max = 400, step = 5,
		value = 45,
	},
	ally_high_alpha = {
		name = 'Ally high unit opacity',
		type = 'number',
		min = 0, max = 1, step = 0.05,
		value = 0.35,
	},
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

function widget:UnitEnteredRadar(unitID, unitTeam)
	if spectating and not WantDrawUnit(Spring.GetUnitDefID(unitID)) then
		-- Spectators can see fake enemy units, so check for them
		return
	end
	if (Spring.GetUnitAllyTeam(unitID) ~= myAllyTeamID) then
		local x, y, z = Spring.GetUnitPosition (unitID)
		local losState = Spring.GetUnitLosState(unitID, myAllyTeamID)
		local r, g, b = Spring.GetTeamColor(Spring.GetUnitTeam(unitID) or unitTeam or Spring.GetGaiaTeamID())
		enemyDots[unitID] = {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), losState.los, r, g, b} -- x, y, z, ground, inlos, r, g, b
	end
end

function widget:UnitLeftRadar(unitID, unitTeam)
	if not fullview then
		enemyDots[unitID] = nil
	end
end

function widget:UnitDestroyed(unitID, unitTeam)
	enemyDots[unitID] = nil
	allyDots[unitID] = nil
end

function widget:UnitCreated(unitID, unitDefID)
	if not WantDrawUnit(unitDefID) then
		return
	end
	local x, y, z = Spring.GetUnitPosition(unitID)
	local r, g, b = Spring.GetTeamColor(Spring.GetUnitTeam(unitID) or Spring.GetGaiaTeamID())
	if (Spring.GetUnitAllyTeam(unitID) == myAllyTeamID) then
		allyDots[unitID] = {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), true, r, g, b} -- x, y, z, ground, inlos, r, g, b
	else
		local losState = Spring.GetUnitLosState(unitID, myAllyTeamID)
		enemyDots[unitID] = {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), losState.los, r, g, b} -- x, y, z, ground, inlos, r, g, b
	end
end

local function DoFullUnitReload()
	local myAllyTeam = Spring.GetMyAllyTeamID()
	local units = Spring.GetAllUnits()
	enemyDots = {}
	allyDots = {}
	for i = 1, #units do
		local unitID = units[i]
		local unitAllyTeam = Spring.GetUnitAllyTeam(unitID)
		if unitAllyTeam == myAllyTeam then
			widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
		else
			widget:UnitEnteredRadar(unitID)
		end
	end
end

local function UpdateSpec()
	--if Spring.GetSpectatingState() then
	--	widgetHandler:RemoveCallIn("DrawWorld")
	--else
	--	widgetHandler:UpdateCallIn("DrawWorld")
	--end
	spectating, fullview = Spring.GetSpectatingState()
	myAllyTeamID = Spring.GetMyAllyTeamID()
end

function widget:PlayerChanged(playerID)
	UpdateSpec()
end

function widget:Initialize()
	UpdateSpec()
	DoFullUnitReload()
end

local function DrawGroundquad(x, y, z, size)
	gl.TexCoord(0, 0)
	gl.Vertex(x - size, y, z - size)
	gl.TexCoord(0, 1)
	gl.Vertex(x - size, y, z + size)
	gl.TexCoord(1, 1)
	gl.Vertex(x + size, y, z + size)
	gl.TexCoord(1, 0)
	gl.Vertex(x + size, y, z - size)
end

local function DrawWarnings(warnings)
	if not warnings then
		return
	end
	gl.MatrixMode(GL.TEXTURE)
	
	gl.Culling(GL.BACK)
	gl.DepthTest(false)
	for i = 1, #warnings do
		local data = warnings[i]
		gl.Texture(GetUnitIcon(data[5]))
		gl.Color(data[6] or 1, data[7] or 1, data[8] or 1, 0.65*data[4])
		gl.PushMatrix()
		--gl.Translate(data[1], data[2], data[3])
		gl.BeginEnd(GL.QUADS, DrawGroundquad, data[1], data[2], data[3], options.high_fly_size.value*(0.5 + 0.5*data[4]))
		gl.PopMatrix()
	end
	gl.Texture(false)
	gl.DepthTest(false)
	gl.Culling(false)
	gl.PolygonOffset(false)
	
	gl.MatrixMode(GL.MODELVIEW)
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

	local warningDraw
	local removals = {}
	for unitID, data in pairs (enemyDots) do
		if needs_update then
			if not Spring.ValidUnitID(unitID) then
				removals[unitID] = true
			else
				local x, y, z = Spring.GetUnitPosition(unitID)
				local losState = Spring.GetUnitLosState(unitID)
				local r, g, b = Spring.GetTeamColor(Spring.GetUnitTeam(unitID) or Spring.GetGaiaTeamID())
				data[1] = x
				if data[1] then
					data[2] = y
					data[3] = z
					data[4] = math.max(Spring.GetGroundHeight(x,z), 0)
					data[5] = losState.los
					data[6] = r
					data[7] = g
					data[8] = b
				end
			end
		end
		if data and data[1] then
			local show_high = options.enable_high.value == "always" or options.enable_high.value == "enemies"
			local airDraw = ((data[2] > 0 and data[2] - data[4] > VERT_LINE_THRESHOLD) and (
					(options.enable_vertical_lines_air.value == "always") or 
					((options.enable_vertical_lines_air.value == "radar") and (not data[5]))))
			local waterDraw = ((data[2] < 0) and (
					(options.enable_vertical_lines_water.value == "always") or 
					((options.enable_vertical_lines_water.value == "radar") and (not data[5]))))
			local highDraw = (show_high and data[9] and data[2] - data[4] > HIGH_LOWER)
			if data[9] and not highDraw then
				data[9] = nil
			elseif show_high and data[2] - data[4] > HIGH_THRESHOLD then
				highDraw = true
				data[9] = true
			end
			if airDraw or waterDraw or highDraw then
				local alpha = 1
				if highDraw then
					warningAlpha = math.max(0, math.min(1, (data[2] - data[4] - HIGH_LOWER) / (HIGH_UPPER - HIGH_LOWER)))
					warningDraw = warningDraw or {}
					warningDraw[#warningDraw + 1] = {data[1], data[4], data[3], warningAlpha, Spring.GetUnitDefID(unitID), data[6], data[7], data[8]}
					if not(airDraw or waterDraw) then
						alpha = warningAlpha
					end
				end
				gl.Color(data[6], data[7], data[8], alpha)
				gl.BeginEnd(GL.LINES, function()
					gl.Vertex(data[1],data[4],data[3])
					gl.Vertex(data[1],data[2],data[3])
				end)
			end
		end
	end
	for unitID in pairs (removals) do
		enemyDots[unitID] = nil
	end

	if options.enable_vertical_lines_ally.value ~= "never" or options.enable_high.value == "always" then
		local show_air   = ((options.enable_vertical_lines_ally.value == "always") or (options.enable_vertical_lines_ally.value == "air"))
		local show_water = ((options.enable_vertical_lines_ally.value == "always") or (options.enable_vertical_lines_ally.value == "water"))
		local show_high  = options.enable_high.value == "always"
		for unitID, data in pairs (allyDots) do
			if needs_update then
				local x, y, z = Spring.GetUnitPosition(unitID)
				data[1] = x
				if data[1] then
					local r, g, b = Spring.GetTeamColor(Spring.GetUnitTeam(unitID) or Spring.GetGaiaTeamID())
					data[2] = y
					data[3] = z
					data[4] = math.max(Spring.GetGroundHeight(x, z), 0)
					data[5] = true
					data[6] = r
					data[7] = g
					data[8] = b
				end
			end
			if data and data[1] then
				local airDraw = (show_air and (data[2] > 0 and data[2] > data[4] + VERT_LINE_THRESHOLD))
				local waterDraw = ((data[2] < 0) and show_water)
				local highDraw = (show_high and data[9] and data[2] - data[4] > HIGH_LOWER)
				if data[9] and not highDraw then
					data[9] = nil
				elseif show_high and data[2] - data[4] > HIGH_THRESHOLD then
					highDraw = true
					data[9] = true
				end
				if airDraw or waterDraw or highDraw then
					local alpha = 1
					if highDraw then
						warningAlpha = math.max(0, math.min(1, (data[2] - data[4] - HIGH_LOWER) / (HIGH_UPPER - HIGH_LOWER))) * options.ally_high_alpha.value
						warningDraw = warningDraw or {}
						warningDraw[#warningDraw + 1] = {data[1], data[4], data[3], warningAlpha, Spring.GetUnitDefID(unitID), data[6], data[7], data[8]}
						if not (airDraw or waterDraw) then
							alpha = warningAlpha
						end
					end
					gl.Color(data[6], data[7], data[8], alpha)
					gl.BeginEnd(GL.LINES, function()
						gl.Vertex(data[1],data[4],data[3])
						gl.Vertex(data[1],data[2],data[3])
					end)
				end
			end
		end
	end

	gl.DepthTest (false)
	gl.Color (1,1,1,1)
	gl.PopAttrib ()
	
	DrawWarnings(warningDraw)
end
