local name = "commweapon_shotcannon"
local weaponDef = {
	name                    = [[12 gauge]],
	alphaDecay              = 0.3,
	areaOfEffect            = 32,
	burst                   = 3,
	burstRate               = 0.033,
	burnblow                = true,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire   = [[custom:RIOT_SHELL_L]],
		altforms = {
			green = {
				-- explosionGenerator = [[custom:BEAMWEAPON_HIT_GREEN]],
				rgbColor = [[0 1 0]],
			},
		},

		light_camera_height = 2000,
		light_color = [[0.3 0.3 0.05]],
		light_radius = 50,
		reaim_time = 1,
	},

	damage                  = {
		default = 32,
	},

	duration                = 0.02,
	explosionGenerator      = [[custom:ARCHPLOSION]],
	fireStarter             = 50,
	heightMod               = 1,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	projectiles             = 4,
	range                   = 285,
	reloadtime              = 54/30,
	rgbColor                = [[1 1 0]],
	separation              = 1.2,
	size                    = 2,
	sizeDecay               = 0,
	soundHit                = [[impacts/shotgun_impactv5]],
	soundStart              = [[weapon/shotgun_firev4]],
	soundStartVolume        = 0.6,
	soundTrigger            = true,
	sprayangle              = 1600,
	stages                  = 20,
	tolerance               = 10000,
	turret                  = true,
	weaponType              = [[Cannon]],
	weaponVelocity          = 950,
}

return name, weaponDef
