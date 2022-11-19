return { vehassault = {
  unitname               = [[vehassault]],
  name                   = [[Ravager]],
  description            = [[Assault Rover]],
  acceleration           = 0.162,
  brakeRate              = 0.462,
  buildCostMetal         = 250,
  builder                = false,
  buildPic               = [[vehassault.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[42 42 42]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    aimposoffset   = [[0 8 0]],
    midposoffset   = [[0 3 0]],
    modelradius    = [[21]],

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[vehicleassault]],
  leaveTracks            = true,
  maxDamage              = 2000,
  maxSlope               = 18,
  maxVelocity            = 2.95,
  maxWaterDepth          = 22,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB DRONE]],
  objectName             = [[corraid.s3o]],
  script                 = [[vehassault.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
    },

  },
  sightDistance          = 385,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 38,
  turninplace            = 0,
  turnRate               = 688,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    PLASMA = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        reaim_time = 8, -- COB
        light_camera_height = 1500,
      },

      damage                  = {
        default = 210,
        planes  = 210,
      },

      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 320,
      reloadtime              = 2,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/cannon/medplasma_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 238,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      collisionVolumeOffsets = [[0 -5 0]],
      collisionVolumeScales  = [[42 42 42]],
      collisionVolumeType    = [[ellipsoid]],
      object           = [[corraid_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
