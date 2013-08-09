local name = "commweapon_slamrocket"
local weaponDef = {
	name                    = [[SLAM Rocket]],
	accuracy                = 0,
	avoidFeature            = false,
	areaOfEffect            = 320,
	burnblow                = true,
	cegTag                  = [[BANISHERTRAIL]],
	commandFire             = true,
	craterBoost             = 0,
	craterMult              = 0.75,

	customParams            = {
		slot = [[3]],
		muzzleEffectFire = [[custom:STORMMUZZLE]],
	},
	cylinderTargeting       = 1.0,

	damage                  = {
		default = 820,
		subs    = 41,
	},

	edgeEffectiveness       = 0.6,
	explosionGenerator      = [[custom:xamelimpact_slam]],
	fireStarter             = 180,
	flightTime              = 8,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	model                   = [[wep_m_phoenix.s3o]],
	predictBoost            = 0.0,
	range                   = 850,
	reloadtime              = 20,
	smokeTrail              = true,
	soundHit                = [[weapon/bomb_hit]],
	soundStart              = [[weapon/missile/missile_fire2]],
	startVelocity           = 250,
	texture2                = [[darksmoketrail]],
	tolerance               = 300,
	tracks                  = false,
	trajectoryHeight        = 2.14451, 
	turret                  = true,
	weaponAcceleration      = 0,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 250,
}

return name, weaponDef
