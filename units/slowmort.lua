unitDef = {
  unitname            = [[slowmort]],
  name                = [[Morty]],
  description         = [[Slow-Blast Walker]],
  acceleration        = 0.132,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.225,
  buildCostEnergy     = 280,
  buildCostMetal      = 280,
  builder             = false,
  buildPic            = [[CORMORT.png]],
  buildTime           = 280,
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
  iconType            = [[walkersupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 164,
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
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SLOWBEAM = {
      name                    = [[Slow Blob]],
      accuracy                = 200,
      areaOfEffect            = 48,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 200,
        subs    = 50,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:flash1green]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-35]],
      movingAccuracy          = 450,
      noSelfDamage            = true,
      range                   = 600,
	  rgbColor                = [[0.3 1 0.3]],
      reloadtime              = 2,
      renderType              = 4,
	  size					  = 5,
      --soundHit                = [[weapon/laser/mini_laser]],
      soundStart              = [[weapon/laser/mini_laser]],
      startsmoke              = [[1]],
      targetMoveError         = 0.3,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 450,
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
      metal            = 112,
      object           = [[CORMORT_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
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
      metal       = 112,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 112,
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
      metal       = 56,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 56,
      world       = [[All Worlds]],
    },

  },

}

return lowerkeys({ slowmort = unitDef })
