local name = "commweapon_slowbeam"
local weaponDef = {
	name                    = [[Slowing Beam]],
	areaOfEffect            = 8,
	beamDecay               = 0.9,
	beamTime                = 0.1,
	beamttl                 = 30,
	coreThickness           = 0,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		is_unit_weapon = 1,
		slot = [[5]],
		--timeslow_preset = [[commrecon_slowbeam]],
		timeslow_damagefactor = [[2]],
		timeslow_onlyslow = [[1]],
		timeslow_smartretarget = [[0.5]],

		light_camera_height = 1800,
		light_color = [[0.6 0.22 0.8]],
		light_radius = 200,
		reaim_time = 1,
	},

	damage                  = {
		default = 225,
	},

	explosionGenerator      = [[custom:flashslow]],
	fireStarter             = 30,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	largeBeamLaser          = true,
	laserFlareSize          = 6,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 450,
	reloadtime              = (1 + (1/3)),
	rgbColor                = [[0.4 0 0.5]],
	soundStart              = [[weapon/laser/pulse_laser2]],
	soundStartVolume        = 3,
	soundTrigger            = true,
	sweepfire               = false,
	texture1                = [[largelaser]],
	texture2                = [[flare]],
	texture3                = [[flare]],
	texture4                = [[smallflare]],
	thickness               = 8,
	tolerance               = 18000,
	turret                  = true,
	weaponType              = [[BeamLaser]],
	weaponVelocity          = 500,
}

return name, weaponDef
