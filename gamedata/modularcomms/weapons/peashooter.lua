local name = "commweapon_peashooter"
local weaponDef = {
	name                    = [[Laser Blaster]],
	areaOfEffect            = 8,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_RED]],

		light_camera_height = 1200,
		light_radius = 120,
		reaim_time = 1,
	},

	damage                  = {
		default = 12,
		subs    = 0.6,
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
	range                   = 300,
	reloadtime              = 0.1,
	rgbColor                = [[1 0 0]],
	soundHit                = [[weapon/laser/lasercannon_hit]],
	soundStart              = [[weapon/laser/small_laser_fire2]],
	soundTrigger            = true,
	thickness               = 2.55,
	tolerance               = 1000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
}

return name, weaponDef
