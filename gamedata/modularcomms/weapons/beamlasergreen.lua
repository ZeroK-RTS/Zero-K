local name = "commweapon_beamlaser_green"
local weaponDef = {
	name                    = [[Beam Laser]],
    areaOfEffect            = 12,
    beamTime                = 0.1,
    coreThickness           = 0.5,
    craterBoost             = 0,
    craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffectShot = [[custom:BEAMWEAPON_MUZZLE_GREEN]],
	},
	
    damage                  = {
        default = 15.5,
        subs    = 0.8,
    },

    duration                = 0.11,
    edgeEffectiveness       = 0.99,
    explosionGenerator      = [[custom:flash1green]],
    fireStarter             = 70,
    impactOnly              = true,
    impulseBoost            = 0,
    impulseFactor           = 0.4,
    interceptedByShieldType = 1,
    largeBeamLaser          = true,
    laserFlareSize          = 3,
    minIntensity            = 1,
    noSelfDamage            = true,
    range                   = 300,
    reloadtime              = 0.11,
    rgbColor                = [[1 1 1]],
    soundStart              = [[weapon/laser/pulse_laser3]],
    soundTrigger            = true,
    targetMoveError         = 0.05,
    texture1                = [[largelaser]],
    texture2                = [[flare]],
    texture3                = [[flare]],
    texture4                = [[smallflare]],
    thickness               = 3,
    tolerance               = 10000,
    turret                  = true,
    weaponType              = [[BeamLaser]],
    weaponVelocity          = 900,
}

return name, weaponDef
