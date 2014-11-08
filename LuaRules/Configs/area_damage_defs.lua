local array = {}

local DAMAGE_PERIOD = 2 -- how often damage is applied

local weapons = {
	napalmmissile_weapon = { 
		radius = 256, 
		damage = 20, 
		duration = 1400, 
		rangeFall = 0.6, 
		timeFall = 0.5
	},
	slowmissile_weapon = { 
		radius = 512, 
		damage = 3000, 
		duration = 1800, 
		rangeFall = 0, 
		timeFall = 0
	},
	firewalker_napalm_mortar = { 
		radius = 128, 
		damage = 20, 
		duration = 600, 
		rangeFall = 0.6,
		timeFall = 0.5 
	},
	jumpblackhole_black_hole = { 
		radius = 70, 
		damage = 5600,
		impulse = true,
		duration = 400, 
		rangeFall = 0.4,
		timeFall = 0.6
	},
	chickenwurm_napalm = { 
		radius = 128, 
		damage = 30, 
		duration = 600, 
		rangeFall = 0.6, 
		timeFall = 0.5 
	},
	raveparty_orange_roaster = { 
		radius = 320, 
		damage = 40, 
		duration = 450, 
		rangeFall = 0.6, 
		timeFall = 0.5 
	},
	logkoda_napalm_bomblet = { 
		radius = 96, 
		damage = 20, 
		duration = 400, 
		rangeFall = 0.6, 
		timeFall = 0.5 
	},
	logkoda_bogus_fake_napalm_bomblet = { 
		radius = 32, 
		damage = 20, 
		duration = 400, 
		rangeFall = 0.6, 
		timeFall = 0.5 
	},
	infernal_napalm = { 
		radius = 192, 
		damage = 60, 
		duration = 300, 
		rangeFall = 0.6, 
		timeFall = 0.5 
	},
}

-- radius		- defines size of sphereical area in which damage is dealt
-- damage		- maximun damage over 1 second that can be dealt to a unit
-- duration		- how long the area damage stays around for (in frames)
-- rangeFall	- the proportion of damage not dealt increases linearly with distance from 0 to rangeFall at the radius
-- timeFall		- the proportion of damage not dealt increases linearly with elapsed time from 0 to timeFall at the duration

local presets = {
	module_napalmgrenade = { radius = 128, damage = 20, duration = 1400, rangeFall = 0.6, timeFall = 0.5 },
	module_napalmarty = { radius = 128, damage = 20, duration = 600, rangeFall = 0.6, timeFall = 0.5 },
	module_napalmarty_long = { radius = 128, damage = 20, duration = 840, rangeFall = 0.6, timeFall = 0.5 },
}

------------------------
-- Send the Config

for name,data in pairs(WeaponDefNames) do
	if data.customParams.areadamage_preset then
		weapons[name] = Spring.Utilities.CopyTable(presets[data.customParams.areadamage_preset])
	end
	if weapons[name] then
		weapons[name].damage = weapons[name].damage *DAMAGE_PERIOD/30
		weapons[name].timeLoss = weapons[name].damage*weapons[name].timeFall*DAMAGE_PERIOD/weapons[name].duration
		array[data.id] = weapons[name]
	end
end

return DAMAGE_PERIOD, array
