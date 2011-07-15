local name = "commweapon_partillery"
local weaponDef = {
	name                    = [[Light Plasma Artillery]],
    accuracy                = 350,
    areaOfEffect            = 48,

    customParams			= {
    	muzzleEffect = [[custom:THUDMUZZLE]],
		miscEffect = [[custom:THUDDUST]],
    },
    
    craterBoost             = 0,
    craterMult              = 0,

    damage                  = {
		default = 300,
		planes  = 300,
		subs    = 15,
    },

    edgeEffectiveness       = 0.5,
    explosionGenerator      = [[custom:PLASMA_HIT_32]],
    impulseBoost            = 0,
    impulseFactor           = 0.4,
    interceptedByShieldType = 1,
    minbarrelangle          = [[-35]],
    movingAccuracy          = 850,
    noSelfDamage            = true,
    range                   = 900,
    reloadtime              = 4,
    soundHit                = [[explosion/ex_med5]],
    soundStart              = [[weapon/cannon/cannon_fire1]],
    startsmoke              = [[1]],
    targetMoveError         = 0.3,
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 350,
}

return name, weaponDef
