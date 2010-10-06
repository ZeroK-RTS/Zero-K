unitDef = {
  unitname            = [[cormort]],
  name                = [[Morty]],
  description         = [[Impulse Walker]],
  acceleration        = 0.132,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.225,
  buildCostEnergy     = 320,
  buildCostMetal      = 320,
  builder             = false,
  buildPic            = [[CORMORT.png]],
  buildTime           = 220,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô escaramuçador]],
    description_fr = [[Marcheur Tirailleur]],
    helptext       = [[The Morty offers cheap, mobile skirmishing capability. It can outrange light defenses such as LLTs, although it is vulnerable to swarms of raiders.]],
    helptext_bp    = [[Morty é um escaramuçador barato e rápido. Tem maior alcançe que defesas leves com torres de laser leves, mas é vulnerável a grupos de agressores.]],
    helptext_fr    = [[Le Morty offre des capacités de tirailleur idéales pour un prix réduit. Son canon plasma lui permet une longue portée pour une cadence de tir honorable. Il pourra détruire la plupart des tourelles sans risquer d'y laisser sa carcasse. ]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 110,
  maxDamage           = 550,
  maxSlope            = 36,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[CORMORT.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turninplace         = 0,
  turnRate            = 1099,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[GRAVITY_POS]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND]],
    },


    {
      def                = [[GRAVITY_NEG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING HOVER SWIM LAND]],
    },

  },


  weaponDefs          = {

    GRAVITY_NEG = {
      name                    = [[Attractive Gravity]],
      accuracy                = 512,
      areaOfEffect            = 8,
      avoidFriendly           = true,
      burst                   = 14,
      burstrate               = 0.01,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 25,
      impulseFactor           = -100,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 600,
      reloadtime              = 2,
      renderType              = 4,
      rgbColor                = [[0 0 1]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      sprayangle              = 200,
      startsmoke              = [[0]],
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2200,
    },


    GRAVITY_POS = {
      name                    = [[Repulsive Gravity]],
      areaOfEffect            = 8,
      avoidFriendly           = true,
      burst                   = 14,
      burstrate               = 0.01,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 0.001,
        planes  = 0.001,
        subs    = 5E-05,
      },

      duration                = 0.0333,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 25,
      impulseFactor           = 100,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 600,
      reloadtime              = 2,
      renderType              = 4,
      rgbColor                = [[1 0 0]],
      rgbColor2               = [[1 0.5 1]],
      size                    = 2,
      soundStart              = [[weapon/gravity_fire]],
      soundTrigger            = true,
      sprayangle              = 200,
      startsmoke              = [[0]],
      thickness               = 4,
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Morty]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 550,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[CORMORT_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description = [[Debris - Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 550,
      energy      = 0,
      featureDead = [[HEAP]],
      footprintX  = 2,
      footprintZ  = 2,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 128,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 128,
      world       = [[All Worlds]],
    },


    HEAP  = {
      description = [[Debris - Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 550,
      energy      = 0,
      footprintX  = 2,
      footprintZ  = 2,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 64,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 64,
      world       = [[All Worlds]],
    },

  },

}

return lowerkeys({ cormort = unitDef })
