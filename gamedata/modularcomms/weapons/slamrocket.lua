local name = "commweapon_slamrocket"
local weaponDef = {
	name                    = [[SLAM Rocket]],
	areaOfEffect            = 128,
	burnblow                = true,
	cegTag                  = [[BANISHERTRAIL]],
	commandFire             = true,
	craterBoost             = 1,
	craterMult              = 2,

	customParams            = {
		slot = [[3]],
		muzzleEffectFire = [[custom:STORMMUZZLE]],
	},

	damage                  = {
		default = 1200,
		subs    = 60,
	},

	edgeEffectiveness       = 0.4,
	explosionGenerator      = [[custom:xamelimpact]],
	fireStarter             = 180,
	flightTime              = 5,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 2,
	model                   = [[wep_m_phoenix.s3o]],
	predictBoost            = 1,
	range                   = 850,
	reloadtime              = 12,
	smokeTrail              = true,
	soundHit                = [[weapon/bomb_hit]],
	soundStart              = [[weapon/missile/missile_fire2]],
	startVelocity           = 100,
	texture2                = [[darksmoketrail]],
	tracks                  = false,
	trajectoryHeight        = 0.05,
	turret                  = true,
	weaponAcceleration      = 150,
	weaponType              = [[MissileLauncher]],
	weaponVelocity          = 500,
}

return name, weaponDef
