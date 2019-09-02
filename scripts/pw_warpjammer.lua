include "constants.lua"

local base, wheel, radar = piece('base', 'wheel', 'radar')

local smokePiece = {base}
local spin = math.rad(60)
local spinAccel = math.rad(6)

function script.Create()
	StartThread(GG.Script.SmokeUnit, unitID, smokePiece)
end

function script.Activate()
	if (Spring.GetUnitRulesParam(unitID, "planetwarsDisable") ~= 1) and not GG.applyPlanetwarsDisable then
		Spin(wheel, y_axis, spin, spinAccel/2)
		Spin(radar, y_axis, -spin*2, spinAccel)
	end
end

function script.Deactivate()
	StopSpin(wheel, y_axis, spinAccel)
	StopSpin(radar, y_axis, spinAccel*2)
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < .5 then
		Explode(base, SFX.NONE)
		Explode(wheel, SFX.NONE)
		Explode(radar, SFX.SHATTER)
		return 1
	else
		Explode(base, SFX.SHATTER)
		Explode(wheel, SFX.SHATTER)
		Explode(radar, SFX.SHATTER)
		return 2
	end
end
