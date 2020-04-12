local name = "commweapon_heavy_disruptor"
local weaponDef = {
	name                    = [[Heavy Disruptor Pulse Beam]],
	beamdecay               = 0.9,
	beamTime                = 1/30,
	beamttl                 = 75,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		--timeslow_preset       = [[module_disruptorbeam]],
		timeslow_damagefactor = [[2]],

		light_color = [[1.88 0.63 2.5]],
		light_radius = 120,
		reaim_time = 1,
	},

	damage                  = {
		default = 600,
		subs    = 40,
	},

	explosionGenerator      = [[custom:flash2purple_large]],
	fireStarter             = 100,
	impactOnly              = true,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	laserFlareSize          = 10,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 390,
	reloadtime              = 3.1,
	rgbColor                = [[0.3 0 0.4]],
	soundStart              = [[weapon/laser/heavy_laser5]],
	soundStartVolume        = 7,
	thickness               = 8,
	tolerance               = 8192,
	turret                  = true,
	weaponType              = [[BeamLaser]],
}

return name, weaponDef
