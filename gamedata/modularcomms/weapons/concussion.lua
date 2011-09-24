local name = "commweapon_concussion"
local weaponDef = {
    name                    = [[Concussion Shell]],
    alphaDecay              = 0.12,
    areaOfEffect            = 192,
    --cegTag                  = [[gauss_tag_m]],
    commandfire             = true,
    craterBoost             = 1,
    craterMult              = 2,

	customParams			= {
		slot = [[3]],
		muzzleEffectFire = [[custom:RAIDMUZZLE]],
	},	
	
    damage                  = {
		default = 750,
		planes  = 750,
		subs    = 37.5,
    },

	edgeEffectiveness		= 0.5,
    explosionGenerator      = [[custom:100rlexplode]],
    impulseBoost            = 0.4,
    impulseFactor           = 0.75,
    interceptedByShieldType = 0,
    range                   = 500,
    reloadtime              = 8,
    rgbColor                = [[1 0.6 0]],
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
