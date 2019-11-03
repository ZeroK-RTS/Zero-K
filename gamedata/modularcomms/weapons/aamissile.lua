local name = "commweapon_aamissile"
local weaponDef = {
	name                    = [[AA Missile]],
	areaOfEffect            = 48,
	canattackground         = false,
	cegTag                  = [[missiletrailblue]],
	craterBoost             = 1,
	craterMult              = 2,
	cylinderTargeting       = 1,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire   = [[custom:CRASHMUZZLE]],
		onlyTargetCategory = [[FIXEDWING GUNSHIP]],

		light_color = [[0.5 0.6 0.6]],
		light_radius = 380,
		reaim_time = 1,
	},

	damage                  = {
		default = 12,
		planes  = 120,
		subs    = 6,
	},

	explosionGenerator      = [[custom:FLASH2]],
	fireStarter             = 70,
	flightTime              = 3,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	model                   = [[wep_m_fury.s3o]],
	noSelfDamage            = true,
	range                   = 950,
	reloadtime              = 1,
	smokeTrail              = true,
	soundHit                = [[weapon/missile/rocket_hit]],
	soundStart              = [[weapon/missile/missile_fire7]],
	startVelocity           = 650,
	texture2                = [[AAsmoketrail]],
	tolerance               = 9000,
	tracks                  = true,
	turnRate                = 63000,
	turret                  = true,
	weaponAcceleration      = 141,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 850,
}

return name, weaponDef
