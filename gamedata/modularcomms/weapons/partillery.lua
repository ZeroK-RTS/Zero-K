local name = "commweapon_partillery"
local weaponDef = {
	name                    = [[Light Plasma Artillery]],
    accuracy                = 350,
    areaOfEffect            = 48,

    customParams			= {
    	muzzleEffectFire = [[custom:thud_fire_fx]],
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
	myGravity               = 0.1,
    noSelfDamage            = true,
    range                   = 750,
    reloadtime              = 4,
    soundHit                = [[explosion/ex_med5]],
    soundStart              = [[weapon/cannon/cannon_fire1]],
    startsmoke              = [[1]],
    targetMoveError         = 0.3,
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 300,
}

return name, weaponDef
