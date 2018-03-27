include "constants.lua"

local base, wheel, radar = piece('base', 'wheel', 'radar')

local smokePiece = {base}
local spin = math.rad(60)
local spinAccel = math.rad(6)

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.Activate()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") ~= 1 then
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
		Explode(base, sfxNone)
		Explode(wheel, sfxNone)
		Explode(radar, sfxShatter)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(wheel, sfxShatter)
		Explode(radar, sfxShatter)
		return 2
	end
end