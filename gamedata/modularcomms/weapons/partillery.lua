local name = "commweapon_partillery"
local weaponDef = {
	name                    = [[Light Plasma Artillery]],
	accuracy                = 350,
	areaOfEffect            = 64,

	customParams            = {
		is_unit_weapon = 1,
		muzzleEffectFire = [[custom:thud_fire_fx]],
		reaim_time = 1,
	},

	craterBoost             = 0,
	craterMult              = 0,

	damage                  = {
		default = 320,
		subs    = 16,
	},

	edgeEffectiveness       = 0.5,
	explosionGenerator      = [[custom:INGEBORG]],
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	myGravity               = 0.09,
	noSelfDamage            = true,
	range                   = 800,
	reloadtime              = 4,
	soundHit                = [[explosion/ex_med5]],
	soundStart              = [[weapon/cannon/cannon_fire1]],
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 300,
}

return name, weaponDef
