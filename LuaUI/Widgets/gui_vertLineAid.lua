
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

local IterableMap = VFS.Include("LuaRules/Gadgets/Include/IterableMap.lua")

local last_frame = 0
local disabled = false
local enemyDots = IterableMap.New()
local enemyDraw = IterableMap.New()
local allyDots = IterableMap.New()
local allyDraw = IterableMap.New()
local myAllyTeamID

local UNDERWATER_THRESHOLD = -20
local VERT_LINE_THRESHOLD = 30
local HIGH_THRESHOLD = 750
local HIGH_UPPER = 700
local HIGH_LOWER = 350
local UPDATE_RATE = 18

local ALLY_THROW_ALPHA = 0.5
local WARN_TEXTURE  = "icons/kbotexclaim.dds"

local iconTypesPath = LUAUI_DIRNAME.."Configs/icontypes.lua"
local _, iconFormat = VFS.Include(LUAUI_DIRNAME .. "Configs/chilitip_conf.lua" , nil, VFSMODE)
local icontypes = VFS.FileExists(iconTypesPath) and VFS.Include(iconTypesPath)
local iconCache = {}

local spectating, fullview = Spring.GetSpectatingState()

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Unit Handling

local ally_air, ally_water, ally_high, enemy_air, enemy_water, enemy_high
local enemy_air_radar_only, enemy_water_radar_only

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
		if not ud then
			return true
		end
		wantDrawCache[unitDefID] = (ud.customParams.completely_hidden or ud.isImmobile)and 0 or 1
	end
	return (wantDrawCache[unitDefID] == 1)
end

local function GetEnemyDraw(data)
	local airDraw = (data[2] > 0 and data[2] - data[4] > VERT_LINE_THRESHOLD) and enemy_air and ((not enemy_air_radar_only) or (not data[5]))
	local waterDraw = (data[2] < UNDERWATER_THRESHOLD) and enemy_water and ((not enemy_water_radar_only) or (not data[5]))
	local highDraw = (enemy_high and data[9] and data[2] - data[4] > HIGH_LOWER)
	if data[9] and not highDraw then
		data[9] = nil
	elseif enemy_high and data[2] - data[4] > HIGH_THRESHOLD then
		highDraw = true
		data[9] = true
	end
	return airDraw, waterDraw, highDraw
end

local function GetAllyDraw(data)
	local airDraw = (ally_air and (data[2] > 0 and data[2] > data[4] + VERT_LINE_THRESHOLD))
	local waterDraw = ((data[2] < UNDERWATER_THRESHOLD) and ally_water)
	local highDraw = (ally_high and data[9] and data[2] - data[4] > HIGH_LOWER)
	if data[9] and not highDraw then
		data[9] = nil
	elseif ally_high and data[2] - data[4] > HIGH_THRESHOLD then
		highDraw = true
		data[9] = true
	end
	return airDraw, waterDraw, highDraw
end

local function UpdateUnit(unitID, data, index, isEnemy)
	if not Spring.ValidUnitID(unitID) then
		return true
	end
	local x, y, z = Spring.GetUnitViewPosition(unitID, true)
	data[1] = x
	if not data[1] then
		return true
	end
	data[2] = y
	data[3] = z
	data[4] = math.max(Spring.GetGroundHeight(x,z), 0)
	if isEnemy then
		local losState = (enemy_air_radar_only or enemy_water_radar_only) and Spring.GetUnitLosState(unitID)
		losState = losState and losState.los
		data[5] = losState
		if not IterableMap.Get(enemyDraw, unitID) then
			local airDraw, waterDraw, highDraw = GetEnemyDraw(data)
			if airDraw or waterDraw or highDraw then
				local drawData = {}
				IterableMap.Add(enemyDraw, unitID, drawData)
				UpdateUnit(unitID, drawData, false, isEnemy)
			end
		end
	else
		if not IterableMap.Get(allyDraw, unitID) then
			local airDraw, waterDraw, highDraw = GetAllyDraw(data)
			if airDraw or waterDraw or highDraw then
				local drawData = {}
				IterableMap.Add(allyDraw, unitID, drawData)
				UpdateUnit(unitID, drawData, false, isEnemy)
			end
		end
	end
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Settings

local function UpdateShowSettings()
	ally_air   = ((options.enable_vertical_lines_ally.value == "always") or (options.enable_vertical_lines_ally.value == "air"))
	ally_water = ((options.enable_vertical_lines_ally.value == "always") or (options.enable_vertical_lines_ally.value == "water"))
	ally_high  = options.enable_high.value == "always"
	
	enemy_high  = options.enable_high.value == "always" or options.enable_high.value == "enemies"
	enemy_air   = (options.enable_vertical_lines_air.value == "always") or (options.enable_vertical_lines_air.value == "radar")
	enemy_water = (options.enable_vertical_lines_water.value == "always") or (options.enable_vertical_lines_water.value == "radar")
	enemy_air_radar_only = (options.enable_vertical_lines_air.value == "radar")
	enemy_water_radar_only = (options.enable_vertical_lines_water.value == "radar")
	
	IterableMap.Apply(enemyDots, UpdateUnit, true)
	IterableMap.Apply(allyDots, UpdateUnit)
end

options_path = 'Settings/Interface/Height Indicator'
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
		OnChange = forceUpdate,
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
		OnChange = forceUpdate,
	},
}
UpdateShowSettings() -- Set {ally,enemy}_{air,water, high} correctly

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Callins

function widget:UnitLeftLos(unitID, unitDefID, unitTeam)
	-- Instant update when passing from LOS into radar
	if not WantDrawUnit(unitDefID) then
		return
	end
	if (Spring.GetUnitAllyTeam(unitID) ~= myAllyTeamID) then
		local data = IterableMap.Get(enemyDots, unitID) or {}
		if not UpdateUnit(unitID, data, false, true) then
			IterableMap.Add(enemyDots, unitID, data)
		end
	end
end

function widget:UnitEnteredLos(unitID, unitTeam)
	widget:UnitLeftLos(unitID, unitDefID, unitTeam)
end

function widget:UnitEnteredRadar(unitID, unitTeam)
	widget:UnitLeftLos(unitID, Spring.GetUnitDefID(unitID), unitTeam)
end

function widget:UnitLeftRadar(unitID, unitTeam)
	if not fullview then
		IterableMap.Remove(enemyDots. unitID)
	end
end

function widget:UnitDestroyed(unitID, unitTeam)
	IterableMap.Remove(enemyDots, unitID)
	IterableMap.Remove(enemyDraw, unitID)
	IterableMap.Remove(allyDots, unitID)
	IterableMap.Remove(allyDraw, unitID)
end

function widget:UnitCreated(unitID, unitDefID)
	if not WantDrawUnit(unitDefID) then
		return
	end
	local x, y, z = Spring.GetUnitPosition(unitID)
	local r, g, b = Spring.GetTeamColor(Spring.GetUnitTeam(unitID) or Spring.GetGaiaTeamID())
	if (Spring.GetUnitAllyTeam(unitID) == myAllyTeamID) then
		IterableMap.Add(allyDots, unitID, {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), true, r, g, b}) -- x, y, z, ground, inlos, r, g, b
	else
		local losState = Spring.GetUnitLosState(unitID, myAllyTeamID)
		IterableMap.Add(enemyDots, unitID, {x, y, z, math.max(Spring.GetGroundHeight(x,z), 0), losState.los, r, g, b}) -- x, y, z, ground, inlos, r, g, b
	end
end

local function DoFullUnitReload()
	local myAllyTeam = Spring.GetMyAllyTeamID()
	local units = Spring.GetAllUnits()
	enemyDots = IterableMap.New()
	allyDots = IterableMap.New()
	enemyDraw = IterableMap.New()
	allyDraw = IterableMap.New()
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

function widget:GameFrame(n)
	IterableMap.ApplyFraction(enemyDots, UPDATE_RATE, n%UPDATE_RATE, UpdateUnit, true)
	IterableMap.ApplyFraction(allyDots, UPDATE_RATE, n%UPDATE_RATE, UpdateUnit)
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Drawing

local warningDraw = false

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

local function DrawUnit(unitID, data, index, isEnemy)
	if not (data and data[1]) then
		return true
	end
	UpdateUnit(unitID, data, index, isEnemy, true)
	local airDraw, waterDraw, highDraw
	if isEnemy then
		airDraw, waterDraw, highDraw = GetEnemyDraw(data)
	else
		airDraw, waterDraw, highDraw = GetAllyDraw(data)
	end
	if not (airDraw or waterDraw or highDraw) then
		return true
	end
	local alpha = 1
	local teamID = Spring.GetUnitTeam(unitID)
	if not teamID then
		return true
	end
	local r, g, b = Spring.GetTeamColor(teamID)
	if not (x and r) then
		return false
	end
	if highDraw then
		warningAlpha = math.max(0, math.min(1, (data[2] - data[4] - HIGH_LOWER) / (HIGH_UPPER - HIGH_LOWER)))
		warningDraw = warningDraw or {}
		warningDraw[#warningDraw + 1] = {data[1], data[4], data[3], warningAlpha, Spring.GetUnitDefID(unitID), r, g, b}
		if not(airDraw or waterDraw) then
			alpha = warningAlpha
		end
	end
	gl.Color(r, g, b, alpha)
	gl.BeginEnd(GL.LINES, function()
		gl.Vertex(data[1], data[4], data[3])
		gl.Vertex(data[1], data[2], data[3])
	end)
end

function widget:DrawWorld()
	if IterableMap.IsEmpty(enemyDraw) and IterableMap.IsEmpty(allyDraw) then
		return
	end
	gl.PushAttrib(GL.LINE_BITS)
	gl.DepthTest(true)
	gl.LineWidth(1.4)

	warningDraw = false
	IterableMap.Apply(enemyDraw, DrawUnit, true)
	IterableMap.Apply(allyDraw, DrawUnit)

	gl.DepthTest (false)
	gl.Color (1,1,1,1)
	gl.PopAttrib()
	DrawWarnings(warningDraw)
end
