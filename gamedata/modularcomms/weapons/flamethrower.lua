local name = "commweapon_flamethrower"
local weaponDef = {
    name                    = [[Flame Thrower]],
    areaOfEffect            = 64,
    avoidFeature            = false,
    collideFeature          = false,
    collideGround           = false,
    craterBoost             = 0,
    craterMult              = 0,
	
	customParams			= {
		slot = [[5]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
		flamethrower = [[1]],
		setunitsonfire = "1",
		burntime = [[450]],
	},

    damage                  = {
        default = 10,
        subs    = 0.1,
    },

	duration				  = 0.1,
    explosionGenerator      = [[custom:SMOKE]],
	fallOffRate             = 1,
	fireStarter             = 100,
	impulseBoost            = 0,
    impulseFactor           = 0,
    intensity               = 0.1,
    interceptedByShieldType = 1,
    noExplode               = true,
    noSelfDamage            = true,
    numbounce               = 5,
	--predictBoost			  = 1,
    range                   = 280,
    reloadtime              = 0.16,
	rgbColor                = [[1 1 1]],
	soundStart              = [[weapon/flamethrower]],
    soundTrigger            = true,
	texture1				  = [[fireball]],
	texture2				  = [[fireball]],
	thickness	              = 12,
    tolerance               = 5000,
    turret                  = true,
	waterbounce             = 1,
    weaponType              = [[LaserCannon]],
    weaponVelocity          = 500,
}

return name, weaponDef
