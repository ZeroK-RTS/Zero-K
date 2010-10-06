unitDef = {
  unitname            = [[cormortgold]],
  name                = [[Golden Morty]],
  description         = [[Elite Skirmisher Walker]],
  acceleration        = 0.132,
  bmcode              = [[1]],
  brakeRate           = 0.225,
  buildCostEnergy     = 320,
  buildCostMetal      = 320,
  builder             = false,
  buildPic            = [[cormortgold.png]],
  buildTime           = 320,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[An upgraded veteran Morty, this version has two guns for twice the fun!]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 160,
  maxDamage           = 650,
  maxSlope            = 36,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[CorMort_gold.s3o]],
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
  turnRate            = 1099,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CORE_MORTGOLD]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORE_MORTGOLD = {
      name                    = [[PlasmaCannon]],
      accuracy                = 400,
      areaOfEffect            = 16,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 160,
        planes  = 160,
        subs    = 8,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-35]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 1.5,
      renderType              = 4,
      soundHit                = [[OTAunit/XPLOMED3]],
      soundStart              = [[OTAunit/CANNON1]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Golden Morty]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 650,
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
      description = [[Debris - Golden Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 650,
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
      description = [[Debris - Golden Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 650,
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

return lowerkeys({ cormortgold = unitDef })
