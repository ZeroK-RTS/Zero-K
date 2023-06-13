return { chicken_blimpy = {
  unitname            = [[chicken_blimpy]],
  name                = [[Blimpy]],
  description         = [[Dodo Bomber]],
  airHoverFactor      = 0,
  activateWhenBuilt   = true,
  brakerate           = 0.4,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_blimpy.png]],
  buildTime           = 750,
  canFly              = true,
  canGuard            = true,
  canLand             = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  cruiseAlt           = 250,

  customParams        = {
  },

  explodeAs           = [[NOWEAPON]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[bomberassault]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maneuverleashlength = [[64000]],
  maxDamage           = 1850,
  maxSlope            = 18,
  maxVelocity         = 5,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP STUPIDTARGET]],
  objectName          = [[chicken_blimpy.s3o]],
  power               = 750,
  script              = [[chicken_blimpy.lua]],
  reclaimable         = false,
  selfDestructAs      = [[NOWEAPON]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 512,
  sonarDistance       = 512,
  turnRate            = 6000,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[BOGUS_BOMB]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[BOMBTRIGGER]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 70,
      onlyTargetCategory = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER SUB]],
    },


    {
      def                = [[DODOBOMB]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 90,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER SUB]],
    },

  },


  weaponDefs          = {

    BOGUS_BOMB  = {
      name                    = [[Fake Bomb]],
      areaOfEffect            = 80,
      commandfire             = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        bogus = 1,
      },

      damage                  = {
        default = 0,
      },

      edgeEffectiveness       = 0,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[wep_b_fabby.s3o]],
      myGravity               = 1000,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.5,
      weaponType              = [[AircraftBomb]],
    },


    BOMBTRIGGER = {
      name                    = [[Fake BOMBTRIGGER]],
      accuracy                = 12000,
      areaOfEffect            = 1,
      beamTime                = 0.1,
      canattackground         = true,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1,
        planes  = 1,
      },

      explosionGenerator      = [[custom:none]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      lodDistance             = 10000,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 14,
      rgbColor                = [[0 0 0]],
      thickness               = 0,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 100,
    },


    DODOBOMB    = {
      name                    = [[Dodo Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 1,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      burst                   = 1,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customparams            = {
          spawns_name = "chicken_dodo",
          spawns_expire = 30,
      },

      damage                  = {
        default = 1,
        planes  = 1,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chicken_dodobomb.s3o]],
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },

  },

} }
