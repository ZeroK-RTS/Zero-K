local name = "commweapon_flamethrower"
local weaponDef = {
    name                    = [[Flame Thrower]],
    areaOfEffect            = 64,
    avoidFeature            = false,
    collideFeature          = false,
    craterBoost             = 0,
    craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		setunitsonfire = "1",
		burntime = [[450]],
	},

    damage                  = {
        default = 8.75,
        planes  = 8.75,
        subs    = 0.0875,
    },

    explosionGenerator      = [[custom:SMOKE]],
    fireStarter             = 150,
    flameGfxTime            = 1.6,
    impulseBoost            = 0,
    impulseFactor           = 0,
    intensity               = 0.1,
    interceptedByShieldType = 0,
    noExplode               = true,
    noSelfDamage            = true,
    range                   = 280,
    reloadtime              = 0.16,
    sizeGrowth              = 1.05,
    soundStart              = [[weapon/flamethrower]],
    soundTrigger            = true,
    sprayAngle              = 50000,
    tolerance               = 2500,
    turret                  = true,
    weaponType              = [[Flame]],
    weaponVelocity          = 800,
}

return name, weaponDef
