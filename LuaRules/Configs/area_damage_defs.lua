local array = {}

local DAMAGE_PERIOD = 2 -- how often damage is applied

local weapons = {
	napalmmissile_weapon = { radius = 256, damage = 60, duration = 900, rangeFall = 0.6, timeFall = 0.5},
	slowmissile_weapon = { radius = 512, damage = 3000, duration = 1800, rangeFall = 0, timeFall = 0},
	firewalker_napalm_mortar = { radius = 128, damage = 45, duration = 450, rangeFall = 0.6, timeFall = 0.5 },
}

-- radius		- defines size of sphereical area in which damage is dealt
-- damage		- maximun damage over 1 second that can be dealt to a unit
-- duration		- how long the area damage stays around for
-- rangeFall	- the proportion of damage not dealt increases linearly with distance from 0 to rangeFall at the radius
-- timeFall		- the proportion of damage not dealt increases linearly with elapsed time from 0 to timeFall at the duration

for i=1,#WeaponDefs do
	for weapon, data in pairs(weapons) do
		if WeaponDefs[i].name == weapon then 
			data.damage = data.damage*DAMAGE_PERIOD/30
			data.timeLoss = data.damage*data.timeFall*DAMAGE_PERIOD/data.duration
			array[i] = data 
		end
	end
end

return DAMAGE_PERIOD, array