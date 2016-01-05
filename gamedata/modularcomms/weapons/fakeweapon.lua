local name = "commweapon_fake"
local weaponDef = {
	name                    = [[Fake Bogus Weapon]],
	areaOfEffect            = 8,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	
	damage                  = {
		default = 10,
	},

	duration                = 0.02,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
	fireStarter             = 50,
	heightMod               = 1,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	noSelfDamage            = true,
	range                   = 100,
	reloadtime              = 0.1,
	rgbColor                = [[1 0 0]],
	soundHit                = [[weapon/laser/lasercannon_hit]],
	soundStart              = [[weapon/laser/small_laser_fire2]],
	soundTrigger            = true,
	thickness               = 2.55,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
}

return name, weaponDef