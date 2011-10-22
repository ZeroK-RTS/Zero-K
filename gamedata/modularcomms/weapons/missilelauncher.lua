local name = "commweapon_missilelauncher"
local weaponDef = { 
    name                    = [[Missile Launcher]],
    areaOfEffect            = 48,
	avoidFeature            = true,
    cegTag                  = [[missiletrailyellow]],
    craterBoost             = 1,
    craterMult              = 2,

	customParams			= {
		slot = [[5]],
		muzzleEffectFire = [[custom:SLASHMUZZLE]],
	},
	
	damage                  = {
		default = 75,
		planes  = 75,
		subs    = 3.75,
	},
	
	explosionGenerator      = [[custom:FLASH2]],
	fireStarter             = 70,
	flightTime              = 3,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	model                   = [[wep_m_frostshard.s3o]],
	noSelfDamage            = true,
	range                   = 450,
	reloadtime              = 1,
	smokedelay              = [[0.1]],
	smokeTrail              = true,
	soundHit                = [[explosion/ex_med17]],
	soundStart              = [[weapon/missile/missile_fire11]],
	startsmoke              = [[1]],
	startVelocity           = 450,
	texture2                = [[lightsmoketrail]],
	tolerance               = 8000,
	tracks                  = true,
	turnRate                = 33000,
	turret                  = true,
	weaponAcceleration      = 109,
	weaponTimer             = 5,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 545,
}

return name, weaponDef
