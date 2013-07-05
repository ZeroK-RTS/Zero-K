local name = "commweapon_multistunner"
local weaponDef = {
    name                    = [[Multi-Stunner]],
    areaOfEffect            = 128,
    avoidFeature            = false,
	burst					= 10,
	burstRate				= 0.16,
	commandFire			    = true,
	
	customParams            = {
		muzzleEffectFire = [[custom:YELLOW_LIGHTNING_MUZZLE]],
		slot = [[3]],
	},

    craterBoost             = 0,
    craterMult              = 0,
    cylinderTargeting       = 0,

    damage                  = {
		default        = 800,
		empresistant75 = 200,
		empresistant99 = 8,
    },

    duration                = 8,
    dynDamageExp            = 0,
    edgeEffectiveness       = 0.8,
    explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
    fireStarter             = 0,
    impulseBoost            = 0,
    impulseFactor           = 0,
    intensity               = 10,
    interceptedByShieldType = 1,
    noSelfDamage            = true,
    paralyzer               = true,
    paralyzeTime            = 3,
    range                   = 360,
    reloadtime              = 12,
    rgbColor                = [[1 1 0.25]],
    soundStart              = [[weapon/lightning_fire]],
    soundTrigger            = false,
	sprayAngle			    = 1536,
    texture1                = [[lightning]],
    thickness               = 10,
    turret                  = true,
    weaponType              = [[LightningCannon]],
    weaponVelocity          = 450,
}

return name, weaponDef
