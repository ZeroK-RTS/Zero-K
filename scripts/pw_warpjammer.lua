include "constants.lua"

local base, wheel, radar  = piece('base', 'wheel', 'radar')

local spin = math.rad(60)

function script.Create()
    local rand = math.random(0,1)
    if rand == 1 then spin = -spin end
    Spin(wheel, y_axis, spin)
    Spin(radar, y_axis, -spin*2)
end

function script.Killed(recentDamage, maxHealth)
    local severity = recentDamage/maxHealth
    if severity>50 then
	Explode(base, sfxNone)
	Explode(wheel, sfxNone)
	Explode(radar, sfxFall)
    else
	Explode(base, sfxShatter)
	Explode(wheel, sfxShatter)
	Explode(radar, sfxShatter)
    end
    return 0
end