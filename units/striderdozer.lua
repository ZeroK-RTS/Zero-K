return { striderdozer = {
  name                = [[Dozer]],
  description         = [[Heavy Buster, Very Tank]],
  acceleration        = 0.17,
  brakeRate           = 0.624,
  builder             = false,
  buildPic            = [[tankheavyassault.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[96 96 96]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_default = 0,
    decloak_footprint     = 5,

    outline_x = 110,
    outline_y = 110,
    outline_yoff = 13.5,
  },

  explodeAs           = [[BIG_UNIT]],
  footprintX          = 4,
  footprintZ          = 4,
  health              = 12000,
  iconType            = [[tankskirm]],
  leaveTracks         = true,
  maxSlope            = 18,
  maxWaterDepth       = 22,
  metalCost           = 2200,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[terraTank.s3o]],
  script              = [[striderdozer.lua]],
  selfDestructAs      = [[BIG_UNIT]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },
  sightDistance       = 540,
  speed               = 57,
  trackOffset         = 8,
  trackStrength       = 10,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 50,
  turninplace         = 0,
  turnRate            = 500,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[TERRA_SPRAY]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 160,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs          = {

    TERRA_SPRAY    = {
      name                    = [[Ramp Gun]],
      areaOfEffect            = 256,
      burnblow                = true,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      burst                   = 1,
      burstrate               = 0.2,
      
      customParams            = {
        gatherradius = [[180]],
        smoothradius = [[200]],
        detachmentradius = [[200]],
        smoothmult   = [[0.4]],
        smoothexponent = [[0.4]],
        movestructures = [[0.8]],

        light_color = [[1.2 1.6 0.55]],
        light_radius = 80,
      },
      
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      explosionGenerator      = [[custom:tremor]],
      firestarter             = 400,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      myGravity               = 0.25,
      noSelfDamage            = true,
      proximityPriority       = -4,
      range                   = 800,
      reloadtime              = 0.2,
      rgbColor                = [[0.1 1 0.1]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/tremor_fire]],
      sprayAngle              = 1200,
      tolerance               = 2000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },

  },


  featureDefs         = {

    DEAD       = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[golly_d.s3o]],
    },

    
    HEAP       = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
