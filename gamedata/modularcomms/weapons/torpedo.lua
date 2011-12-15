local name = "commweapon_torpedo"
local weaponDef = { 
	name                    = [[Torpedo]],
	areaOfEffect            = 16,
	avoidFriendly           = false,
	burnblow                = true,
	collideFriendly         = false,
	craterBoost             = 0,
	craterMult              = 0,

	damage                  = {
		default = 120,
		subs    = 120,
	},

	explosionGenerator      = [[custom:TORPEDO_HIT]],
	flightTime              = 6,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	lineOfSight             = true,
	model                   = [[wep_t_longbolt.s3o]],
	noSelfDamage            = true,
	range                   = 400,
	reloadtime              = 2,
	soundHit                = [[explosion/ex_underwater]],
	soundStart              = [[weapon/torpedo]],
	startVelocity           = 90,
	tolerance               = 31999,
	tracks                  = true,
	turnRate                = 10000,
	turret                  = true,
	waterWeapon             = true,
	weaponAcceleration      = 25,
	weaponType              = [[TorpedoLauncher]],
	weaponVelocity          = 140,
}

return name, weaponDef
