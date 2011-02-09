local name = "commweapon_disruptor"
local weaponDef = {
    name                    = [[Disruptor Pulse Beam]],
    areaOfEffect            = 32,
	beamdecay 				= 0.9,
    beamlaser               = 1,
    beamTime                = 0.2,
	beamttl                 = 50,
    coreThickness           = 0.5,
    craterBoost             = 0,
    craterMult              = 0,

	customParams			= {
		slot = [[4]],
		timeslow_preset = [[commrecon_slowbeam]],
	},
	
    damage                  = {
		default = 250,
    },

    explosionGenerator      = [[custom:flash1teal]],
    fireStarter             = 30,
	impactOnly              = true,
    impulseBoost            = 0,
    impulseFactor           = 0.4,
    interceptedByShieldType = 1,
    largeBeamLaser          = true,
    laserFlareSize          = 4.33,
    lineOfSight             = true,
    minIntensity            = 1,
    noSelfDamage            = true,
    range                   = 350,
    reloadtime              = 2,
    renderType              = 0,
    rgbColor                = [[0.2 1 1]],
    soundStart              = [[weapon/laser/heavy_laser4]],
    soundStartVolume        = 2,
    soundTrigger            = true,
    sweepfire               = false,
    texture1                = [[largelaser]],
    texture2                = [[flare]],
    texture3                = [[flare]],
    texture4                = [[smallflare]],
    thickness               = 4.33,
    tolerance               = 18000,
    turret                  = true,
    weaponType              = [[BeamLaser]],
    weaponVelocity          = 500,
}

return name, weaponDef
