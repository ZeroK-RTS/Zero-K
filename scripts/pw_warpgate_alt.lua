include "constants.lua"

local base, cylinder, radars = piece('base', 'cylinder', 'radars')

local smokePiece = {base}
local spin = math.rad(60)
local spinAccel = math.rad(6)

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Activate()
	if (Spring.GetUnitRulesParam(unitID, "planetwarsDisable") ~= 1) and not GG.applyPlanetwarsDisable then
		Spin(cylinder, y_axis, spin*2, spinAccel)
		Spin(radars, y_axis, -spin*2, spinAccel)
	end
end

function script.Deactivate()
	StopSpin(cylinder, y_axis, spin*2, spinAccel)
	StopSpin(radars, y_axis, -spin*2, spinAccel)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		Explode(cylinder, SFX.NONE)
		Explode(radars, SFX.SHATTER)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(cylinder, SFX.SHATTER)
		Explode(radars, SFX.SHATTER)
		return 2
	end
end
