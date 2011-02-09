local name = "commweapon_slowbeam"
local weaponDef = {
    name                    = [[Slowing Beam]],
    areaOfEffect            = 8,
    beamDecay               = 0.9,
    beamlaser               = 1,
    beamTime                = 0.1,
    beamttl                 = 50,
    coreThickness           = 0,
    craterBoost             = 0,
    craterMult              = 0,

    customParams            = {
		timeslow_preset = [[commrecon_slowbeam]],
    },

    damage                  = {
      default = 120,
    },

    explosionGenerator      = [[custom:flash2purple]],
    fireStarter             = 30,
    impactOnly              = true,
    impulseBoost            = 0,
    impulseFactor           = 0.4,
    interceptedByShieldType = 1,
    largeBeamLaser          = true,
    laserFlareSize          = 6,
    lineOfSight             = true,
    minIntensity            = 1,
    noSelfDamage            = true,
    range                   = 300,
    reloadtime              = 1.5,
    renderType              = 0,
    rgbColor                = [[0.4 0 0.5]],
    soundStart              = [[weapon/laser/pulse_laser2]],
    soundStartVolume        = 0.9,
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
