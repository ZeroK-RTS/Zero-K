function widget:GetInfo()
	return {
		name      = "Ungoliant Pulse Radius",
		desc      = "Shows the EMP radius of allied Ungoliants while they deploy, and lights their emitters as they charge",
		author    = "Anarchid",
		date      = "2026",
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = true,
	}
end

local unitDef = UnitDefNames.strideremp
if not unitDef then
	return false
end
local UNIT_DEF_ID = unitDef.id
local blast = WeaponDefNames.strideremp_emp_blast
local RADIUS = blast and blast.damageAreaOfEffect or 640

local STATE_DEPLOYING, STATE_CHARGING = 1, 2

local spGetUnitRulesParam = Spring.GetUnitRulesParam
local spGetUnitPosition = Spring.GetUnitPosition
local spIsUnitAllied = Spring.IsUnitAllied
local spGetUnitPieceMap = Spring.GetUnitPieceMap
local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glDrawGroundCircle = gl.DrawGroundCircle
local random = math.random

local tracked = {} -- Ungoliants we can see

--------------------------------------------------------------------------------
-- emitter light: an uneven blue glow on the emitter core, growing with the charge

local function Lights()
	return WG['lightsgl4']
end

-- Each sim frame attaches a fresh short-lived light to the emitter piece. Lights with a lifetime
-- are removed by the lights widget's own expiry queue, so when the charge stops (pulse, stun,
-- death) the glow is gone within LIGHT_LIFE frames. A single persistent unit light cannot be used:
-- AddPointLight does not register it for RemoveLight, so it would linger on the stunned unit.
local LIGHT_LIFE = 2

local function SpawnLight(unitID, state)
	local lights = Lights()
	if not lights then
		return
	end
	local charge = (state == STATE_CHARGING) and (spGetUnitRulesParam(unitID, "strideremp_charge") or 0) or 0
	-- the glow spreads as the charge builds, and thins out as it spreads
	local radius = (state == STATE_CHARGING) and (120 + 420*charge) or 110
	local brightness = (state == STATE_CHARGING) and (0.5 - 0.075*charge) or 0.15
	local flicker = 0.55 + 0.45*random()
	if random() < 0.04 + 0.06*charge then
		flicker = flicker + 0.8 -- the odd arc flashes the surroundings
	end
	local pieceMap = spGetUnitPieceMap(unitID)
	if not pieceMap then
		return
	end
	-- LIGHT_LIFE of these overlap at any time, hence the division
	lights.AddPointLight(nil, unitID, pieceMap.emit_core, nil, 0, 0, 0, radius, 0.45, 0.72, 1.0,
		brightness*flicker/LIGHT_LIFE, 0, 0, 0, 0, 0.8, 0.8, 0.6, 0.5, nil, LIGHT_LIFE, LIGHT_LIFE)
end

--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID)
	if unitDefID == UNIT_DEF_ID and tracked[unitID] == nil then
		tracked[unitID] = true
	end
end

function widget:UnitEnteredLos(unitID)
	widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
end

function widget:UnitDestroyed(unitID)
	tracked[unitID] = nil
end

function widget:UnitLeftLos(unitID)
	if not spIsUnitAllied(unitID) then
		widget:UnitDestroyed(unitID)
	end
end

function widget:UnitGiven(unitID, unitDefID)
	widget:UnitCreated(unitID, unitDefID)
end

function widget:Initialize()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		widget:UnitCreated(units[i], Spring.GetUnitDefID(units[i]))
	end
end

function widget:GameFrame(n)
	for unitID in pairs(tracked) do
		local state = spGetUnitRulesParam(unitID, "strideremp_state")
		if state == STATE_DEPLOYING or state == STATE_CHARGING then
			SpawnLight(unitID, state)
		end
	end
end

function widget:DrawWorldPreUnit()
	local _, fullView = Spring.GetSpectatingState()
	local t = Spring.GetGameSeconds()
	local drew = false
	for unitID in pairs(tracked) do
		local state = spGetUnitRulesParam(unitID, "strideremp_state")
		if (state == STATE_DEPLOYING or state == STATE_CHARGING) and (fullView or spIsUnitAllied(unitID)) then
			local x, y, z = spGetUnitPosition(unitID)
			if x then
				local charge = spGetUnitRulesParam(unitID, "strideremp_charge") or 0
				local pulse = 0.5 + 0.5*math.sin(t*(3 + 9*charge))
				glLineWidth(2 + 2*charge)
				glColor(0.45, 0.8, 1.0, 0.3 + 0.4*pulse)
				glDrawGroundCircle(x, y, z, RADIUS, 96)
				if charge > 0 then
					glColor(0.75, 0.92, 1.0, 0.25 + 0.4*charge)
					glDrawGroundCircle(x, y, z, RADIUS*charge, 64)
				end
				drew = true
			end
		end
	end
	if drew then
		glLineWidth(1)
		glColor(1, 1, 1, 1)
	end
end
