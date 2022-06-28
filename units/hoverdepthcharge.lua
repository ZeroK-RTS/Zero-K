return { hoverdepthcharge = {
  unitname            = [[hoverdepthcharge]],
  name                = [[Claymore]],
  description         = [[Riot Hovercraft (Anti-Sub)]],
  acceleration        = 0.12,
  activateWhenBuilt   = true,
  brakeRate           = 1.3,
  buildCostMetal      = 300,
  builder             = false,
  buildPic            = [[hoverdepthcharge.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  collisionVolumeOffsets  = [[0 -3 0]],
  collisionVolumeScales   = [[48 32 48]],
  collisionVolumeType     = [[cylY]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 0,
    modelradius    = [[25]],
    turnatfullspeed_hover = [[1]],
    okp_damage = 440,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverspecial]],
  maxDamage           = 1300,
  maxSlope            = 36,
  maxVelocity         = 2.35,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverassault.s3o]],
  script              = [[hoverdepthcharge.lua]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },
  sightDistance       = 385,
  sonarDistance       = 385,
  turninplace         = 0,
  turnRate            = 624,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },
    
    {
      def                = [[FAKEGUN]],
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },

    {
      def                = [[FAKE_DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK TURRET FLOAT SHIP GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    DEPTHCHARGE = {
      name                    = [[Depth Charge]],
      areaOfEffect            = 160,
      avoidFriendly           = false,
      bounceSlip              = 0.94,
      bounceRebound           = 0.8,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cegTag                  = [[torpedo_trail]],

      customParams = {
        burst = Shared.BURST_UNRELIABLE,
      },

      damage                  = {
        default = 520.1,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:TORPEDOHITHUGE]],
      fixedLauncher           = true,
      flightTime              = 2.3,
      groundBounce            = true,
      heightMod               = 0,
      impulseBoost            = 0.2,
      impulseFactor           = 0.9,
      interceptedByShieldType = 1,
      leadLimit               = 0,
      model                   = [[depthcharge_big.s3o]],
      myGravity               = 0.2,
      noSelfDamage            = true,
      numbounce               = 3,
      range                   = 280,
      reloadtime              = 3.1,
      soundHitDry             = [[explosion/mini_nuke]],
      soundHitWet             = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 8.5,
      soundHitVolume          = 11,
      startVelocity           = 5,
      tolerance               = 1000000,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 25,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },
    
    FAKE_DEPTHCHARGE = {
      name                    = [[Rolled Charge]],
      areaOfEffect            = 160,
      avoidFriendly           = false,
      bounceSlip              = 0.4,
      bounceRebound           = 0.4,
      canAttackGround         = false,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 520.1,
      },

      edgeEffectiveness       = 0.75,
      explosionGenerator      = [[custom:TORPEDOHITHUGE]],
      fixedLauncher           = true,
      flightTime              = 4,
      groundBounce            = true,
      heightMod               = 0,
      impulseBoost            = 0.2,
      impulseFactor           = 0.9,
      interceptedByShieldType = 1,
      model                   = [[depthcharge_big.s3o]],
      myGravity               = 0.2,
      noSelfDamage            = true,
      numbounce               = 1,
      range                   = 280,
      reloadtime              = 3.1,
      soundHitDry             = [[explosion/mini_nuke]],
      soundHitWet             = [[explosion/wet/ex_underwater]],
      soundStart              = [[weapon/torp_land]],
      soundStartVolume        = 8.5,
      soundHitVolume          = 11,
      tolerance               = 1000000,
      tracks                  = false,
      turnRate                = 0,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 400,
    },
    
    FAKEGUN = {
      name                    = [[Fake Weapon]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 1E-06,
        planes  = 1E-06,
      },

      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 1,
      impactOnly              = true,
      interceptedByShieldType = 1,
      range                   = 280,
      reloadtime              = 2.8,
      size                    = 1E-06,
      smokeTrail              = false,
      targetborder            = 0.9,
      
      textures                = {
        [[null]],
        [[null]],
        [[null]],
      },

      turnrate                = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 240,
      weaponTimer             = 0.1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[hoverdepthcharge_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
