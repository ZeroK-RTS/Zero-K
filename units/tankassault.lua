return { tankassault = {
  unitname            = [[tankassault]],
  name                = [[Minotaur]],
  description         = [[Assault Tank]],
  acceleration        = 0.119,
  brakeRate           = 0.479,
  buildCostMetal      = 850,
  builder             = false,
  buildPic            = [[tankassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[50 50 50]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 0 0]],
    modelradius    = [[25]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 6800,
  maxSlope            = 18,
  maxVelocity         = 2.45,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[correap.s3o]],
  script              = [[tankassault.cob]],
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance       = 506,
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 42,
  turninplace         = 0,
  turnRate            = 364,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[COR_REAP]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    COR_REAP = {
      name                    = [[Medium Plasma Cannon]],
      areaOfEffect            = 32,
      burst                   = 2,
      burstRate               = 0.2,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        reaim_time = 8, -- COB
      },

      damage                  = {
        default = 320,
        planes  = 320,
        subs    = 16,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 360,
      reloadtime              = 4,
      soundHit                = [[weapon/cannon/reaper_hit]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 255,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[correap_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
