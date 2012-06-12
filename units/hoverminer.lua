unitDef = {
  unitname            = [[hoverminer]],
  name                = [[Dampener]],
  description         = [[Minelaying Hover]],
  acceleration        = 0.0435,
  brakeRate           = 0.205,
  buildCostEnergy     = 200,
  buildCostMetal      = 200,
  builder             = false,
  buildPic            = [[hoverminer.png]],
  buildTime           = 200,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext       = [[The Dampener deploys mines a short distance from itself.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  mass                = 153,
  maxDamage           = 400,
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
      accuracy                = 1600,
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
      reloadtime              = 5,
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
      damage           = 400,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 80,
      object           = [[hoverminer_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 80,
    },


    HEAP  = {
      description      = [[Debris - Dampener]],
      blocking         = false,
      damage           = 400,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
    },

  },

}

return lowerkeys({ hoverminer = unitDef })
