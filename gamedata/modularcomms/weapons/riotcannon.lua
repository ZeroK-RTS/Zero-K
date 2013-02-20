local name = "commweapon_riotcannon"
local weaponDef = {
	name                    = [[Riot Cannon]],
    areaOfEffect            = 144,
    avoidFeature            = true,
    avoidFriendly           = true,
    burnblow                = true,
    craterBoost             = 1,
    craterMult              = 2,
	
	customParams			= {
		slot = [[5]],
		muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
		miscEffectFire = [[custom:RIOT_SHELL_L]],
	},

    damage                  = {
      default = 240,
      planes  = 240,
      subs    = 12,
    },

    edgeEffectiveness       = 0.75,
    explosionGenerator      = [[custom:FLASH64]],
	fireStarter				= 150,
    impulseBoost            = 140,
    impulseFactor           = 1.5,
    interceptedByShieldType = 1,
    lineOfSight             = true,
    noSelfDamage            = true,
    range                   = 270,
    reloadtime              = 2.2,
    soundHit                = [[weapon/cannon/generic_cannon]],
    soundStart              = [[weapon/cannon/outlaw_gun]],
    soundStartVolume        = 3,
    startsmoke              = [[1]],
    turret                  = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 750,
}

return name, weaponDef
