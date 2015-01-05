return {

  amphbomb_death = {
    name                    = [[Slow Blast]],
      areaOfEffect            = 550,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 150,
        planes  = 150,
        subs    = 150,
      },

      customParams           = {
	    lups_explodespeed = 1,
	    lups_explodelife = 0.6,
--	    nofriendlyfire = 1,
		timeslow_damagefactor = [[4]],
      },

      edgeeffectiveness       = 1,
      explosionGenerator      = [[custom:RIOTBALL]],
      explosionSpeed          = 11,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      myGravity               = 10,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.95,
      soundHitVolume          = 1,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 230,
    },
}