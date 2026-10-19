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

local tracked = {} -- unitID -> light instance ID, or false

--------------------------------------------------------------------------------
-- emitter light: an uneven blue glow on the emitter core, growing with the charge

local function Lights()
	return WG['lightsgl4']
end

local function DropLight(unitID)
	local lights = Lights()
	if tracked[unitID] and lights then
		lights.RemoveLight('point', tracked[unitID], unitID)
	end
	if tracked[unitID] ~= nil then
		tracked[unitID] = false
	end
end

local function UpdateLight(unitID, state)
	local lights = Lights()
	if not lights then
		return
	end
	local charge = spGetUnitRulesParam(unitID, "strideremp_charge") or 0
	local level = (state == STATE_CHARGING) and (0.25 + 0.75*charge) or 0.12
	local flicker = 0.55 + 0.45*random()
	if random() < 0.08*level then
		flicker = flicker + 0.8 -- the odd arc flashes the surroundings
	end
	local piece = spGetUnitPieceMap(unitID).emit_core
	tracked[unitID] = lights.AddPointLight(tracked[unitID] or nil, unitID, piece, nil, 0, 0, 0,
		120 + 420*level, 0.45, 0.72, 1.0, 1.4*level*flicker, 0, 0, 0, 0, 0.8, 0.8, 0.6, 0.5)
end

--------------------------------------------------------------------------------

function widget:UnitCreated(unitID, unitDefID)
	if unitDefID == UNIT_DEF_ID and tracked[unitID] == nil then
		tracked[unitID] = false
	end
end

function widget:UnitEnteredLos(unitID)
	widget:UnitCreated(unitID, Spring.GetUnitDefID(unitID))
end

function widget:UnitDestroyed(unitID)
	DropLight(unitID)
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

function widget:Shutdown()
	for unitID in pairs(tracked) do
		DropLight(unitID)
	end
end

local lightTimer = 0
function widget:Update(dt)
	lightTimer = lightTimer + dt
	if lightTimer < 1/30 then
		return
	end
	lightTimer = 0
	for unitID in pairs(tracked) do
		local state = spGetUnitRulesParam(unitID, "strideremp_state")
		if state == STATE_DEPLOYING or state == STATE_CHARGING then
			UpdateLight(unitID, state)
		elseif tracked[unitID] then
			DropLight(unitID)
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
