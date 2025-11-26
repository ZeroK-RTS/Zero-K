return "commweapon_chickenclaw",{
    name                    = [[Chicken Claws]],
    areaOfEffect            = 28,
    craterBoost             = 1,
    craterMult              = 0,

    customParams={
        
		is_unit_weapon = 1,
    },

    damage                  = {
      default = 600,
    },

    explosionGenerator      = [[custom:NONE]],
    impulseBoost            = 0,
    impulseFactor           = 1,
    interceptedByShieldType = 0,
    noSelfDamage            = true,
    range                   = 140,
    reloadtime              = 1,
    size                    = 0,
    soundStart              = [[chickens/bigchickenbreath]],
    targetborder            = 1,
    tolerance               = 8000,
    --turret                  = true,
    waterWeapon             = true,
    weaponType              = [[Cannon]],
    weaponVelocity          = 600,
  }