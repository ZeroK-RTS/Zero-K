local name = "commweapon_hpartillery"
local weaponDef = {
	name                    = [[Plasma Artillery]],
	accuracy                = 600,
	areaOfEffect            = 96,
	craterBoost             = 1,
	craterMult              = 2,

	customParams            = {
		is_unit_weapon = 1,
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_H]],

		light_color = [[1.4 0.8 0.3]],
		reaim_time = 1,
	},

	damage                  = {
		default = 800,
		subs    = 40,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:PLASMA_HIT_96]],
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	myGravity               = 0.1,
	range                   = 800,
	reloadtime              = 8,
	soundHit                = [[weapon/cannon/arty_hit]],
	soundStart              = [[weapon/cannon/pillager_fire]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 320,
}

return name, weaponDef
