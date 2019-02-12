local name = "commweapon_shotgun_disrupt"
local weaponDef = {
	name                    = [[Disruptor Shotgun]],
	areaOfEffect            = 32,
	burst                   = 3,
	burstRate               = 0.03,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		slot = [[5]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire   = [[custom:RIOT_SHELL_L]],
		timeslow_damagefactor = 2,

		light_camera_height = 2000,
		light_color = [[0.3 0.05 0.3]],
		light_radius = 120,
	},

	damage                  = {
		default = 16,
		subs    = 0.8,
	},

	duration                = 0.02,
	explosionGenerator      = [[custom:BEAMWEAPON_HIT_PURPLE]],
	fireStarter             = 50,
	heightMod               = 1,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	projectiles             = 4,
	range                   = 290,
	reloadtime              = 2,
	rgbColor                = [[0.9 0.1 0.9]],
	soundHit                = [[impacts/shotgun_impactv5]],
	soundStart              = [[weapon/shotgun_firev4]],
	soundStartVolume        = 0.6,
	soundTrigger            = true,
	sprayangle              = 1600,
	thickness               = 2,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[LaserCannon]],
	weaponVelocity          = 880,
}

return name, weaponDef
