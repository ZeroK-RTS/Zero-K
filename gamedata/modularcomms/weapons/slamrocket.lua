local name = "commweapon_slamrocket"
local weaponDef = {
	name                    = [[SLAM Rocket]],
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
		default = 500,
		subs    = 25,
	},

	edgeEffectiveness       = 0.6,
	explosionGenerator      = [[custom:xamelimpact_slam]],
	fireStarter             = 180,
	flightTime              = 8.5,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	leadLimit               = 0.0,
	model                   = [[wep_m_phoenix.s3o]],
	predictBoost            = 0.0,
	range                   = 645,
	reloadtime              = 20,
	smokeTrail              = true,
	soundHit                = [[weapon/bomb_hit]],
	soundStart              = [[weapon/missile/missile_fire2]],
	startVelocity           = 250,
	texture2                = [[darksmoketrail]],
	targetMoveError         = 0.9,
	tolerance               = 300,
	trajectoryHeight        = 0.83910, 
	turret                  = true,
	turnrate                = 825,
	weaponAcceleration      = 0,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 250,
}

return name, weaponDef
