local name = "commweapon_clusterbomb"
local weaponDef = {
    name                    = [[Cluster Bomb]],
    accuracy                = 200,
    areaOfEffect            = 160,
	burst					= 2,
	burstRate				= 0.03,
    commandFire             = true,
    craterBoost             = 1,
    craterMult              = 2,
	
	customParams			= {
		slot = [[3]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_H]],
	},
	
    damage                  = {
      default = 300,
      planes  = 300,
      subs    = 15,
    },

    explosionGenerator      = [[custom:MEDMISSILE_EXPLOSION]],
    fireStarter             = 180,
    impulseBoost            = 0,
    impulseFactor           = 0.2,
    interceptedByShieldType = 2,
    model                   = [[wep_b_canister.s3o]],
    projectiles             = 4,
    range                   = 360,
    reloadtime              = 12,
    smokeTrail              = true,
    soundHit                = [[explosion/ex_med6]],
    soundHitVolume          = 8,
    soundStart              = [[weapon/cannon/cannon_fire3]],
    soundStartVolume        = 2,
    soundTrigger			= true,
    sprayangle              = 2048,
    startsmoke              = [[1]],
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 400,
}

return name, weaponDef
