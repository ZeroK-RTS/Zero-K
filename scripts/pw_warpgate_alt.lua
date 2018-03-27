include "constants.lua"

local base, cylinder, radars = piece('base', 'cylinder', 'radars')

local smokePiece = {base}
local spin = math.rad(60)
local spinAccel = math.rad(6)

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.Activate()
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") ~= 1 then
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
		Explode(base, sfxNone)
		Explode(cylinder, sfxNone)
		Explode(radars, sfxShatter)
		return 1
	else
		Explode(base, sfxShatter)
		Explode(cylinder, sfxShatter)
		Explode(radars, sfxShatter)
		return 2
	end
end