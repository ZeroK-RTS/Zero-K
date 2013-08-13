local name = "commweapon_slamrocket"

local weaponDef = {
	name                    = [[S.L.A.M.]],
	avoidFeature            = false,
	avoidGround             = false, 
	collideFriendly         = false,
	areaOfEffect            = 180,
	burnblow                = false,
	cegTag                  = [[BANISHERTRAIL]],
	collisionSize           = 1,
	commandFire             = true,
	craterBoost             = 0,
	craterMult              = 0.45,

	customParams            = {
		slot = [[3]],
		muzzleEffectFire = [[custom:STORMMUZZLE]],
	},
	cylinderTargeting       = 1.0,

	damage                  = {
		default = 670,
		subs    = 33.5,
	},

	edgeEffectiveness       = 0.98,
	explosionGenerator      = [[custom:xamelimpact_slam]],
	fireStarter             = 180,
	flightTime              = 14,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	interceptedByShieldType = 2,
	leadLimit               = 0.0,
	model                   = [[wep_m_phoenix.s3o]],
	predictBoost            = 0.0,
	range                   = 725,
	reloadtime              = 24,
	smokeTrail              = false,
	soundHit                = [[weapon/bomb_hit]],
	soundStart              = [[weapon/missile/missile_fire2]],
	startVelocity           = 0,
--	texture2                = [[darksmoketrail]],
	targetBorder            = 0.66667,
	targetMoveError         = 0.9,
	tolerance               = 4000, 
	turret                  = true,
	weaponTimer             = 2.5,
	weaponAcceleration      = 450,
	weaponType              = [[StarburstLauncher]],
	weaponVelocity          = 6750,
}

return name, weaponDef
