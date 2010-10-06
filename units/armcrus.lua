unitDef = {
  unitname            = [[armcrus]],
  name                = [[Conqueror]],
  description         = [[Cruiser (Assault/Anti-Sub)]],
  acceleration        = 0.048,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.062,
  buildAngle          = 16384,
  buildCostEnergy     = 1700,
  buildCostMetal      = 1700,
  builder             = false,
  buildPic            = [[ARMCRUS.png]],
  buildTime           = 1700,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Croiseur (Assault/Anti-Sous-Marins)]],
    helptext       = [[The workhorse of the open seas, the Conqueror possesses a hefty complement of weapons: a double-barreled gauss gun, twin deck EMGs, and a depthcharge launcher for fending off sub ambush.]],
    helptext_fr    = [[V?ritable fer de lance des sept mers, le Conqueror est sur?quip?. Un double canon gauss, une paire de mitrailleuse lourde et un lance grenades sous-marines. Un vrai couteau suisse blind?!]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[heavyship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 850,
  maxDamage           = 4500,
  maxVelocity         = 3.08,
  minCloakDistance    = 75,
  minWaterDepth       = 10,
  movementClass       = [[BOAT4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName          = [[ARMCRUS]],
  scale               = [[0.5]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  sonarDistance       = 375,
  steeringmode        = [[1]],
  TEDClass            = [[SHIP]],
  turninplace         = 0,
  turnRate            = 454,
  waterline           = 4,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[GAUSS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DECKEMG]],
      badTargetCategory  = [[FIXEDWING]],
      MainDir            = [[0 0 1]],
      MaxAngleDif        = 300,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DECKEMG]],
      badTargetCategory  = [[FIXEDWING]],
      MainDir            = [[0 0 -1]],
      MaxAngleDif        = 300,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[DEPTHCHARGE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    DECKEMG     = {
      name                    = [[Deck EMG]],
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.3,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 6,
        planes  = 6,
        subs    = 0.3,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 360,
      reloadtime              = 0.45,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.4]],
      size                    = 1.75,
      soundStart              = [[flashemg]],
      sprayAngle              = 590,
      startsmoke              = [[0]],
      tolerance               = 10000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 1000,
    },


    DEPTHCHARGE = {
      name                    = [[Depth Charge]],
      areaOfEffect            = 128,
      avoidFriendly           = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 420,
      },

      edgeEffectiveness       = 0.8,
      explosionGenerator      = [[custom:TORPEDO_HIT]],
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[DEPTHCHARGE]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 500,
      reloadtime              = 6,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[OTAunit/XPLODEP2]],
      soundStart              = [[OTAunit/TORPEDO1]],
      startVelocity           = 110,
      tolerance               = 32767,
      tracks                  = true,
      turnRate                = 9800,
      turret                  = false,
      waterWeapon             = true,
      weaponAcceleration      = 15,
      weaponTimer             = 10,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 200,
    },


    GAUSS       = {
      name                    = [[Gauss Cannon]],
      alphaDecay              = 0.12,
      areaOfEffect            = 16,
      bouncerebound           = 0.15,
      bounceslip              = 1,
      burst                   = 1,
      cegTag                  = [[GAUSS_TAG_H]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 100,
        planes  = 100,
        subs    = 0.5,
      },

      explosionGenerator      = [[custom:gauss_hit_m]],
      groundbounce            = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      noExplode               = true,
      noSelfDamage            = true,
      numbounce               = 40,
      range                   = 600,
      reloadtime              = 3.6,
      renderType              = 4,
      rgbColor                = [[0.5 1 1]],
      separation              = 0.5,
      size                    = 0.8,
      sizeDecay               = -0.1,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[armcomgun]],
      sprayangle              = 800,
      stages                  = 32,
      startsmoke              = [[0]],
      tolerance               = 8000,
      turret                  = true,
      waterbounce             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 900,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Conqueror]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 4500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 680,
      object           = [[ARMCRUS_DEAD]],
      reclaimable      = true,
      reclaimTime      = 680,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Conqueror]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      hitdensity       = [[100]],
      metal            = 680,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 680,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Conqueror]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 4500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 5,
      footprintZ       = 5,
      hitdensity       = [[100]],
      metal            = 340,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 340,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armcrus = unitDef })
