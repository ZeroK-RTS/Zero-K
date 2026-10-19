function widget:GetInfo()
	return {
		name      = "Ungoliant Pulse Radius",
		desc      = "Shows the EMP radius and charge of allied Ungoliants while they deploy",
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
local glColor = gl.Color
local glLineWidth = gl.LineWidth
local glDrawGroundCircle = gl.DrawGroundCircle

local tracked = {}

function widget:UnitCreated(unitID, unitDefID)
	if unitDefID == UNIT_DEF_ID then
		tracked[unitID] = true
	end
end

function widget:UnitDestroyed(unitID)
	tracked[unitID] = nil
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
