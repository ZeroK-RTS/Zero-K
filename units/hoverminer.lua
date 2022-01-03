return { hoverminer = {
  unitname            = [[hoverminer]],
  name                = [[Dampener]],
  description         = [[Minelaying Hover]],
  acceleration        = 0.2175,
  brakeRate           = 2.05,
  buildCostMetal      = 200,
  builder             = false,
  buildPic            = [[hoverminer.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    modelradius    = [[25]],
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverskirm]],
  leaveTracks         = true,
  maxDamage           = 400,
  maxSlope            = 18,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[hoverminer.s3o]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
    },

  },
  sightDistance       = 484,
  turninplace         = 0,
  turnRate            = 800,
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
      avoidFriendly           = false,
      avoidNeutral            = false,
      burnblow                = true,
      collideEnemy            = false,
      collideFriendly         = false,
      collideNeutral          = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        spawns_name = "wolverine_mine",
        spawns_expire = 60,
      },

      damage                  = {
        default = 20,
        planes  = 20,
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
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[hoverminer_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
