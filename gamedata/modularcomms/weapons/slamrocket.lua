local name = "commweapon_slamrocket"

local weaponDef = {
	name                    = [[S.L.A.M.]],
	avoidFeature            = false,
	avoidGround             = false, 
	collideFriendly         = false,
	areaOfEffect            = 160,
	burnblow                = false,
	cegTag                  = [[slam_trail]],
	collisionSize           = 1,
	commandFire             = true,
	--craterAreaOfEffect      = 106.66667,
	craterBoost             = 800,
	craterMult              = 1.0,

	customParams            = {
		slot = [[3]],
		muzzleEffectFire = [[custom:STORMMUZZLE]],
	},
	cylinderTargeting       = 1.0,

	damage                  = {
		default = 1120,
		subs    = 56,
	},

	edgeEffectiveness       = 1,
	explosionGenerator      = [[custom:slam]],
	fireStarter             = 180,
	flightTime              = 16,
	impulseBoost            = 0,
	impulseFactor           = 0.2,
	interceptedByShieldType = 2,
	leadLimit               = 0.0,
	model                   = [[wep_m_phoenix.s3o]],
	predictBoost            = 0.0,
	range                   = 700,
	reloadtime              = 21,
	smokeTrail              = false,
	soundHit                = [[weapon/bomb_hit]],
	soundStart              = [[weapon/missile/missile_fire2]],
	startVelocity           = 0,
--	texture2                = [[darksmoketrail]],
	targetBorder            = 1,
	targetMoveError         = 0.9,
	tolerance               = 4000,
	turret                  = true,
	weaponTimer             = 4.4,
	weaponAcceleration      = 75,
	weaponType              = [[StarburstLauncher]],
	weaponVelocity          = 1125,
}

return name, weaponDef
