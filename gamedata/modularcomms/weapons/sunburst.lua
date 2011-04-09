local name = "commweapon_sunburst"
local weaponDef = {
    name                    = [[Sunburst Cannon]],
    areaOfEffect            = 128,
    avoidFriendly           = true,
    commandfire             = true,
    craterBoost             = 1,
    craterMult              = 6,
	
	customParams			= {
		slot = [[3]],
		muzzleEffect = [[custom:ARMBRTHA_FLARE]],
	},

    damage                  = {
		default    = 2500,
    },

    explosionGenerator      = [[custom:blue_explosion]],
    impulseBoost            = 0,
    impulseFactor           = 0.2,
    interceptedByShieldType = 1,
	myGravity				= 0.01,
    noExplode               = false,
    noSelfDamage            = true,
    range                   = 450,
    reloadtime              = 12,
    rgbColor                = [[0.2 0.2 1]],
    separation              = 0.5,
    size                    = 10,
    sizeDecay               = 0.05,
    soundHit                = [[weapon/laser/heavy_laser6]],
    soundStart              = [[weapon/laser/heavy_laser4]],
    soundTrigger            = true,
    tolerance               = 10000,
	stages					= 20,
    turret                  = true,
    weaponTimer             = 4.2,
    weaponType              = [[Cannon]],
    weaponVelocity          = 600,
}

return name, weaponDef
