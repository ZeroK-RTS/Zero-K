local name = "commweapon_disruptor"
local weaponDef = {
	name                    = [[Disruptor Pulse Beam]],
	beamdecay               = 0.85,
	beamTime                = 1/30,
	beamttl                 = 45,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		--timeslow_preset       = [[module_disruptorbeam]],
		timeslow_damagefactor = [[2]],

		light_color = [[1.88 0.63 2.5]],
		light_radius = 80,
		reaim_time = 1,
	},

	damage                  = {
		default = 53,
		subs    = 3,
	},

	explosionGenerator      = [[custom:flash2purple]],
	fireStarter             = 100,
	impactOnly              = true,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	laserFlareSize          = 4.5,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 300,
	reloadtime              = 10/30,
	rgbColor                = [[0.3 0 0.4]],
	soundStart              = [[weapon/laser/mini_laser]],
	soundStartVolume        = 5,
	soundTrigger            = true,
	thickness               = 4,
	tolerance               = 8192,
	turret                  = true,
	weaponType              = [[BeamLaser]],
}

return name, weaponDef
