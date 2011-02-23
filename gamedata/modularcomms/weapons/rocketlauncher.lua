local name = "commweapon_rocketlauncher"
local weaponDef = { 
	name                    = [[Rocket]],
	areaOfEffect            = 48,
	cegTag                  = [[missiletrailred]],
	craterBoost             = 0,
	craterMult              = 0,

	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:STORMMUZZLE]],
		rangeperlevel = [[50]],
		damageperlevel = [[30]],
	},
	
	damage                  = {
		default = 350,
		planes  = 350,
		subs    = 17.5,
	},
	
	fireStarter             = 70,
	flightTime              = 3,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	lineOfSight             = true,
	model                   = [[wep_m_hailstorm.s3o]],
	noSelfDamage            = true,
	predictBoost            = 1,
	range                   = 430,
	reloadtime              = 2,
	smokedelay              = [[.1]],
	smokeTrail              = true,
	soundHit                = [[weapon/missile/sabot_hit]],
	soundHitVolume          = 8,
	soundStart              = [[weapon/missile/sabot_fire]],
	soundStartVolume        = 7,
	startsmoke              = [[1]],
	startVelocity           = 300,
	texture2                = [[darksmoketrail]],
	tracks                  = false,
	trajectoryHeight        = 0.05,
	turret                  = true,
	weaponAcceleration      = 100,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 400,
}

return name, weaponDef
