include "constants.lua"

local base = piece('base')
local wheels = {}
local coolers = {}

for i=1,3 do
	wheels[i] = piece("wheel"..i)
	coolers[i] = piece("cooler"..i)
end

local spin = math.rad(60)

function script.Create()
	local rand = math.random(0,1)
	if rand == 1 then spin = -spin end
	for i=1,3 do
	local rot = math.rad(120*i - 120)
	Turn(wheels[i], y_axis, rot)
	Spin(wheels[i], x_axis, spin)
	
	if i == 1 then
		Turn(coolers[i], y_axis, math.rad(60))
	elseif i == 3 then
		Turn(coolers[i], y_axis, math.rad(-60))
	end
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity>50 then
	Explode(base, sfxNone)
	for i=1,3 do
		Explode(wheels[i], sfxFall)
	end
	else
	Explode(base, sfxShatter)
	for i=1,3 do
		Explode(wheels[i], sfxFall + sfxSmoke + sfxFire)
	end
	end
	return 0
end