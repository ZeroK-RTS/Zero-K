local name = "commweapon_aalaser"
local weaponDef = {
	name                    = [[Anti-Air Laser]],
	areaOfEffect            = 12,
	beamDecay               = 0.736,
	beamTime                = 0.01,
	beamttl                 = 15,
	canattackground         = false,
	coreThickness           = 0.5,
	craterBoost             = 0,
	craterMult              = 0,
	cylinderTargeting      = 1,
	
	customParams			= {
		slot = [[5]],
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
	pitchtolerance          = 8192,
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
