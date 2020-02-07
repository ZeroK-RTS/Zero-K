return { tankheavyarty = {
  unitname               = [[tankheavyarty]],
  name                   = [[Tremor]],
  description            = [[Heavy Saturation Artillery Tank]],
  acceleration           = 0.3,
  brakeRate              = 1.24,
  buildCostMetal         = 1500,
  builder                = false,
  buildPic               = [[tankheavyarty.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[34 34 50]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[17]],
    cus_noflashlight = 1,
  },

  explodeAs              = [[BIG_UNIT]],
  footprintX             = 4,
  footprintZ             = 4,
  highTrajectory         = 1,
  iconType               = [[tanklrarty]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 2045,
  maxSlope               = 18,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName             = [[cortrem.s3o]],
  selfDestructAs         = [[BIG_UNIT]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:wolvmuzzle1]],
    },

  },
  sightDistance          = 660,
  trackOffset            = 20,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 38,
  turninplace            = 0,
  turnRate               = 312,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 270,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    PLASMA = {
      name                    = [[Rapid-Fire Plasma Artillery]],
      accuracy                = 1400,
      areaOfEffect            = 160,
      avoidFeature            = false,
      avoidGround             = false,
      craterAreaOfEffect      = 5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        reaim_time = 15, -- Some sort of bug prevents firing.
        
        gatherradius     = [[240]],
        smoothradius     = [[120]],
        smoothmult       = [[0.5]],
        quickgather      = [[1]],
        lups_noshockwave = [[1]],
        
        light_ground_height = 200,
      },
      
      damage                  = {
        default = 145,
        planes  = 145,
        subs    = 7,
      },
      
      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:tremor]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      noSelfDamage            = false,
      range                   = 1300,
      reloadtime              = 0.333,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/tremor_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 420,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[tremor_dead_new.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
