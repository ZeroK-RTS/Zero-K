local name = "commweapon_beamlaser"
local weaponDef = {
	name                    = [[Beam Laser]],
    areaOfEffect            = 12,
    beamTime                = 0.1,
    coreThickness           = 0.5,
    craterBoost             = 0,
    craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:BEAMWEAPON_MUZZLE_BLUE]],
	},
	
    damage                  = {
		default = 16.5,
		subs    = 8.25,
    },

    duration                = 0.11,
    edgeEffectiveness       = 0.99,
    explosionGenerator      = [[custom:flash1blue]],
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
    rgbColor                = [[0 1 1]],
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
