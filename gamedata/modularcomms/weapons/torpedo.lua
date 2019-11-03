local name = "commweapon_torpedo"
local weaponDef = {
	name                    = [[Torpedo Launcher]],
	areaOfEffect            = 16,
	avoidFriendly           = false,
	bouncerebound           = 0.5,
	bounceslip              = 0.5,
	burnblow                = true,
	collideFriendly         = false,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		badTargetCategory  = [[FIXEDWING]],
		onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
		slot = [[5]],
		reaim_time = 1,
	},

	damage                  = {
		default = 220,
		subs    = 220,
	},

	explosionGenerator      = [[custom:TORPEDO_HIT]],
	flightTime              = 6,
	groundbounce            = 1,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	model                   = [[wep_t_longbolt.s3o]],
	numbounce               = 4,
	noSelfDamage            = true,
	range                   = 330,
	reloadtime              = 3.5,
	soundHit                = [[explosion/wet/ex_underwater]],
	soundStart              = [[weapon/torpedo]],
	startVelocity           = 90,
	tracks                  = true,
	turnRate                = 10000,
	turret                  = true,
	waterWeapon             = true,
	weaponAcceleration      = 25,
	weaponType              = [[TorpedoLauncher]],
	weaponVelocity          = 140,
}

return name, weaponDef
