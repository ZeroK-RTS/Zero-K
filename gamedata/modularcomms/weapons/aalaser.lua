local name = "commweapon_aalaser"
local weaponDef = {
	name                    = [[Anti-Air Laser]],
	areaOfEffect            = 12,
	beamDecay               = 0.736,
	beamTime                = 1/30,
	beamttl                 = 15,
	canattackground         = false,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	cylinderTargeting       = 1,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],

		light_color = [[0.2 1.2 1.2]],
		light_radius = 120,
		reaim_time = 1,
	},

	damage                  = {
		default = 1.88,
		planes  = 18.8,
		subs    = 1,
	},

	explosionGenerator      = [[custom:flash_teal7]],
	fireStarter             = 100,
	impactOnly              = true,
	impulseFactor           = 0,
	interceptedByShieldType = 1,
	laserFlareSize          = 3.25,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 800,
	reloadtime              = 0.1,
	rgbColor                = [[0 1 1]],
	soundStart              = [[weapon/laser/rapid_laser]],
	soundStartVolume        = 4,
	thickness               = 2.1650635094611,
	tolerance               = 8192,
	turret                  = true,
	weaponType              = [[BeamLaser]],
	weaponVelocity          = 2200,
}

return name, weaponDef
