unitDef = {
  unitname            = [[hoverminer]],
  name                = [[Dampener]],
  description         = [[Minelaying Hover]],
  acceleration        = 0.0435,
  brakeRate           = 0.205,
  buildCostEnergy     = 180,
  buildCostMetal      = 180,
  builder             = false,
  buildPic            = [[nsaclash.png]],
  buildTime           = 180,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext       = [[Lays mines]],  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 153,
  maxDamage           = 120,
  maxSlope            = 18,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[hoverminer.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 484,
  smoothAnim          = true,
  turninplace         = 0,
  turnRate            = 500,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[MINE]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    MINE = {
      name                    = [[Light Mine]],
      avoidEnemy              = false,      
      avoidFriendly           = false,
      avoidNeutral            = false,
      burnblow                = true,
      collideEnemy            = false,      
      collideFriendly         = false,
      collideNeutral          = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 20,
        planes  = 20,
        subs    = 0.5,
      },

      explosionGenerator      = [[custom:teleport_progress]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      impactOnly              = true,
      interceptedByShieldType = 0,
      --model                   = [[logmine.s3o]],
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 2,
      size                    = 0,
      soundHit                = [[misc/teleport]],
      --soundStart              = [[misc/teleport2]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Dampener]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[nsaclash_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Dampener]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Dampener]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 44,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoverminer = unitDef })
