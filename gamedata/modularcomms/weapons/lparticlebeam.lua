local name = "commweapon_lparticlebeam"
local weaponDef = {
	name                    = [[Light Particle Beam]],
	beamDecay               = 0.85,
	beamTime                = 1/30,
	beamttl                 = 45,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],

		light_color = [[0.9 0.22 0.22]],
		light_radius = 80,
		reaim_time = 1,
	},

	damage                  = {
		default = 70,
		subs    = 3,
	},

	explosionGenerator      = [[custom:flash1red]],
	fireStarter             = 100,
	impactOnly              = true,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	laserFlareSize          = 4.5,
	minIntensity            = 1,
	range                   = 300,
	reloadtime              = 10/30,
	rgbColor                = [[1 0 0]],
	soundStart              = [[weapon/laser/mini_laser]],
	soundStartVolume        = 5,
	thickness               = 4,
	tolerance               = 8192,
	turret                  = true,
	weaponType              = [[BeamLaser]],
}

return name, weaponDef
