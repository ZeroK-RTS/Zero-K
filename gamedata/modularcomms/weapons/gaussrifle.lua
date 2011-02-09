local name = "commweapon_gaussrifle"
local weaponDef = {
    name                    = [[Gauss Rifle]],
    alphaDecay              = 0.12,
    areaOfEffect            = 16,
    bouncerebound           = 0.15,
    bounceslip              = 1,
    cegTag                  = [[gauss_tag_l]],
    craterBoost             = 0,
    craterMult              = 0,

	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:flashmuzzle1]],
	},
	
    damage                  = {
		default = 90,
		planes  = 90,
		subs    = 4.5,
    },

    explosionGenerator      = [[custom:gauss_hit_l]],
    groundbounce            = 1,
    impactOnly              = true,
    impulseBoost            = 0,
    impulseFactor           = 0,
    interceptedByShieldType = 0,
    lineOfSight             = true,
    noExplode               = true,
    noSelfDamage            = true,
    numbounce               = 40,
    range                   = 450,
    reloadtime              = 3,
    renderType              = 4,
    rgbColor                = [[0.5 1 1]],
    separation              = 0.5,
    size                    = 0.8,
    sizeDecay               = -0.1,
    soundHit                = [[weapon/gauss_hit]],
    soundHitVolume          = 3,
    soundStart              = [[weapon/gauss_fire]],
    soundStartVolume        = 2.5,
    stages                  = 32,
    startsmoke              = [[1]],
    turret                  = true,
    waterbounce             = 1,
    weaponType              = [[Cannon]],
    weaponVelocity          = 1000,
}

return name, weaponDef
