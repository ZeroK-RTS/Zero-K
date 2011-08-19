local name = "commweapon_disintegrator"
local weaponDef = {
    name                    = [[Disintegrator]],
    areaOfEffect            = 64,
    avoidFeature            = false,
    avoidFriendly           = false,
    avoidNeutral            = false,
    commandfire             = true,
    craterBoost             = 1,
    craterMult              = 6,
	
	customParams			= {
		slot = [[3]],
	},

    damage                  = {
		default    = 1400,
    },

    explosionGenerator      = [[custom:DGUNTRACE]],
    impulseBoost            = 0,
    impulseFactor           = 0,
    interceptedByShieldType = 1,
    noExplode               = true,
    noSelfDamage            = true,
    range                   = 250,
    reloadtime              = 12,
	size					= 6,
    soundHit                = [[explosion/ex_med6]],
    soundStart              = [[weapon/laser/heavy_laser4]],
    soundTrigger            = true,
    tolerance               = 10000,
    turret                  = true,
    weaponTimer             = 4.2,
    weaponType              = [[DGun]],
    weaponVelocity          = 300,
}

return name, weaponDef
