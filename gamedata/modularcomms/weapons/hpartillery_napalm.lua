local name = "commweapon_hpartillery_napalm"
local weaponDef = {
	name                    = [[Napalm Artillery]],
	accuracy                = 600,
	areaOfEffect            = 256,
	craterBoost             = 1,
	craterMult              = 2,

	customParams            = {
		is_unit_weapon = 1,
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		burntime = [[60]],
		setunitsonfire = [[1]],

		area_damage = 1,
		area_damage_radius = 128,
		area_damage_dps = 20,
		area_damage_duration = 20,
		reaim_time = 1,

		light_color = [[1.5 0.7 0.3]],
	},

	damage                  = {
		default = 100,
		subs    = 5,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:napalm_firewalker]],
	fireStarter             = 120,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	myGravity               = 0.1,
	range                   = 800,
	reloadtime              = 8,
	rgbcolor                = [[1 0.5 0.2]],
	size                    = 8,
	soundHit                = [[weapon/cannon/wolverine_hit]],
	soundStart              = [[weapon/cannon/wolverine_fire]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 320,
}

return name, weaponDef
