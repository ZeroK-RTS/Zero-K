local name = "commweapon_concussion"
local weaponDef = {
    name                    = [[Concussion Shell]],
    alphaDecay              = 0.12,
    areaOfEffect            = 160,
    cegTag                  = [[gauss_tag_m]],
    commandfire             = true,
    craterBoost             = 1,
    craterMult              = 2,

	customParams			= {
		slot = [[3]],
		muzzleEffect = [[custom:RAIDMUZZLE]],
	},	
	
    damage                  = {
		default = 650,
		planes  = 650,
		subs    = 32.5,
    },

    explosionGenerator      = [[custom:100rlexplode]],
    impactOnly              = false,
    impulseBoost            = 1,
    impulseFactor           = 2,
    interceptedByShieldType = 0,
    noExplode               = false,
    noSelfDamage            = true,
    range                   = 500,
    reloadtime              = 8,
    rgbColor                = [[0 1 0.5]],
    separation              = 0.5,
    size                    = 0.8,
    sizeDecay               = -0.1,
    soundHit                = [[weapon/cannon/earthshaker]],
    soundStart              = [[weapon/gauss_fire]],
    stages                  = 32,
    startsmoke              = [[1]],
    turret                  = true,
    waterbounce             = 1,
    weaponType              = [[Cannon]],
    weaponVelocity          = 1000,
}

return name, weaponDef
