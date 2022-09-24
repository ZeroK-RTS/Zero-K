return { tankarty = {
  unitname            = [[tankarty]],
  name                = [[Emissary]],
  description         = [[General-Purpose Artillery]],
  acceleration        = 0.17,
  brakeRate           = 1.632,
  buildCostMetal      = 700,
  builder             = false,
  buildPic            = [[tankarty.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[42 42 42]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 1,
    unstick_leeway    = 30, -- Don't lose move orders if stuck while packing.
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[tankarty]],
  leaveTracks         = true,
  maxDamage           = 840,
  maxSlope            = 18,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[cormart.s3o]],
  pushResistant       = 0,
  selfDestructAs      = [[BIG_UNITEX]],
  script              = [[tankarty.lua]],
  sightDistance       = 660,
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 34,
  turninplace         = 0,
  turnRate            = 640,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CORE_ARTILLERY]],
      mainDir            = [[0 0 1]],
--      maxAngleDif        = 180,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORE_ARTILLERY = {
      name                    = [[Plasma Artillery]],
      accuracy                = 180,
      areaOfEffect            = 84,
      avoidFeature            = false,
      avoidGround             = true,
      craterBoost             = 1,
      craterMult              = 2,

      customParams            = {
        burst = Shared.BURST_RELIABLE,

        reaim_time = 8, -- COB
        light_color = [[1.4 0.8 0.3]],
      },

      damage                  = {
        default = 600.5,
        planes  = 600.5,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:DOT_Pillager_Explo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.090,
      noSelfDamage            = true,
      range                   = 1120,
      reloadtime              = 7,
      soundHit                = [[weapon/cannon/arty_hit]],
      soundStart              = [[weapon/cannon/pillager_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[cormart_dead.s3o]],
    },

    
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
