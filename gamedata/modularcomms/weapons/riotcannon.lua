local name = "commweapon_riotcannon"
local weaponDef = {
	name                    = [[Riot Cannon]],
    areaOfEffect            = 128,
    avoidFeature            = true,
    avoidFriendly           = true,
    burnblow                = true,
    craterBoost             = 1,
    craterMult              = 2,
	
	customParams			= {
		slot = [[5]],
		muzzleEffect = [[custom:RAIDMUZZLE]],
		miscEffect = [[custom:LEVLRMUZZLE]],
		rangeperlevel = [[14.5]],
		damageperlevel = [[12.5]],
	},

    damage                  = {
      default = 240,
      planes  = 240,
      subs    = 12.5,
    },

    edgeEffectiveness       = 0.75,
    explosionGenerator      = [[custom:FLASH64]],
	fireStarter				= 150,
    impulseBoost            = 0,
    impulseFactor           = 0.4,
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
