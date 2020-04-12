local name = "commweapon_hparticlebeam"
local weaponDef = {
	name                    = [[Heavy Particle Beam]],
	beamDecay               = 0.9,
	beamTime                = 1/30,
	beamttl                 = 75,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],

		light_color = [[0.4 1.6 0.4]],
		light_radius = 120,
		reaim_time = 1,
	},

	damage                  = {
		default = 800,
		subs    = 40,
	},

	explosionGenerator      = [[custom:flash2green_large]],
	fireStarter             = 100,
	impactOnly              = true,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	laserFlareSize          = 10,
	minIntensity            = 1,
	range                   = 390,
	reloadtime              = 3.1,
	rgbColor                = [[0 1 0]],
	soundStart              = [[weapon/laser/small_laser_fire4]],
	soundStartVolume        = 5,
	thickness               = 8,
	tolerance               = 8192,
	turret                  = true,
	weaponType              = [[BeamLaser]],
}

return name, weaponDef
