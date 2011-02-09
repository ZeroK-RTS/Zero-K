local name = "commweapon_shockrifle"
local weaponDef = {
	name                    = [[Pulsed Particle Projector]],
    areaOfEffect            = 16,
    colormap                = [[0 0 0 0   0 0 0.2 0.2   0 0 0.5 0.5   0 0 0.7 0.7   0 0 1 1   0 0 1 1]],
    craterBoost             = 0,
    craterMult              = 0,

	customParams			= {
		slot = [[4]],
	},

      damage                  = {
        default = 1500,
        planes  = 1500,
        subs    = 75,
      },
	
	
    explosionGenerator      = [[custom:megapartgun]],
    impactOnly              = true,
    impulseBoost            = 0,
    impulseFactor           = 0.4,
    interceptedByShieldType = 1,
    lineOfSight             = true,
    noSelfDamage            = true,
    range                   = 700,
    reloadtime              = 15,
    renderType              = 4,
    rgbColor                = [[1 0.2 0.2]],
    separation              = 0.5,
    size                    = 5,
    sizeDecay               = 0,
    soundHit                = [[weapon/laser/heavy_laser6]],
    soundStart              = [[weapon/gauss_fire]],
    startsmoke              = [[1]],
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 1000,
}

return name, weaponDef
