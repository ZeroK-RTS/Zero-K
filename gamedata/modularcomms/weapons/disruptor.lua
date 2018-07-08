local name = "commweapon_disruptor"
local weaponDef = {
	name                    = [[Disruptor Pulse Beam]],
	areaOfEffect            = 32,
	beamdecay               = 0.9,
	beamTime                = 1/30,
	beamttl                 = 30,
	coreThickness           = 0.25,
	craterBoost             = 0,
	craterMult              = 0,

	customParams            = {
		--timeslow_preset       = [[module_disruptorbeam]],
		timeslow_damagefactor = [[2]],

		light_color = [[1.88 0.63 2.5]],
		light_radius = 320,
	},

	damage                  = {
		default = 165,
	},

	explosionGenerator      = [[custom:flash2purple]],
	fireStarter             = 30,
	impactOnly              = true,
	impulseBoost            = 0,
	impulseFactor           = 0.4,
	interceptedByShieldType = 1,
	largeBeamLaser          = true,
	laserFlareSize          = 4.33,
	minIntensity            = 1,
	noSelfDamage            = true,
	range                   = 310,
	reloadtime              = 2,
	rgbColor                = [[0.3 0 0.4]],
	soundStart              = [[weapon/laser/heavy_laser5]],
	soundStartVolume        = 3,
	soundTrigger            = true,
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
