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
	Turn(coolers[1], y_axis, math.rad(60))
	Turn(coolers[3], y_axis, math.rad(-60))
	
	if Spring.GetUnitRulesParam(unitID, "planetwarsDisable") == 1 or GG.applyPlanetwarsDisable then
		return
	end
	
	local rand = math.random(0,1)
	if rand == 1 then
		spin = -spin
	end
	
	for i = 1, 3 do
		local rot = math.rad(120*i - 120)
		Turn(wheels[i], y_axis, rot)
		Spin(wheels[i], x_axis, spin)
	end
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if severity < 0.5 then
		Explode(base, SFX.NONE)
		for i=1,3 do
			Explode(wheels[i], SFX.FALL)
		end
		return 1
	else
		Explode(base, SFX.SHATTER)
		for i=1,3 do
			Explode(wheels[i], SFX.FALL + SFX.SMOKE + SFX.FIRE)
		end
		return 2
	end
end