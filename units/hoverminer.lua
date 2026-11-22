return { hoverminer = {
  name                = [[Dampener]],
  description         = [[Minelaying Hover]],
  acceleration        = 0.2175,
  brakeRate           = 2.05,
  builder             = false,
  buildPic            = [[hoverminer.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    unit_class_tags = {sectiontags = "extraUnits", classtags ={"riot","skirm","support"}},
    modelradius    = [[25]],
    turnatfullspeed_hover = [[1]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  health              = 600,
  iconType            = [[hoverskirm]],
  leaveTracks         = true,
  maxSlope            = 18,
  maxWaterDepth       = 22,
  metalCost           = 300,
  movementClass       = [[HOVER3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[hoverminer.s3o]], -- has a bos script :O
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
    },

  },
  sightDistance       = 484,
  speed               = 63,
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
      name                    = [[Teleporting Mine]],
      accuracy                = 0,
      avoidFriendly           = false,
      avoidNeutral            = false,
      burnblow                = false,
      burst                   = 3,
      burstRate               = 0.1,
      burntime                = 0.0033,
      collideEnemy            = false,
      collideFriendly         = false,
      collideNeutral          = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        spawns_name = "wolverine_mine",--TODO implement unique mine!
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
      --model                   = [[logmine.s3o]], --Theres an alternative that tosses them out slowly like disks
      myGravity               = 100,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 5,
      size                    = 0,
      sprayangle              = 3600,
      startVelocity           = 2000,
      --soundHit                = [[misc/teleport2]],
      --soundStart              = [[misc/teleport2]],
      trajectoryHeight        = 1.5,
      turret                  = true,
      weaponType              = [[MissileLauncher]],
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
