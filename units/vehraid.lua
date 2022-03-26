return { vehraid = {
  unitname               = [[vehraid]],
  name                   = [[Scorcher]],
  description            = [[Raider Rover]],
  acceleration           = 0.342,
  brakeRate              = 0.84,
  buildCostMetal         = 130,
  builder                = false,
  buildPic               = [[vehraid.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SMALL TOOFAST]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[26 26 36]],
  collisionVolumeType    = [[cylZ]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[28 28 34]],
  selectionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius        = [[10]],
    aim_lookahead      = 80,
    set_target_range_buffer = 30,
    set_target_speed_buffer = 8,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[vehicleraider]],
  leaveTracks            = true,
  maxDamage              = 480,
  maxSlope               = 18,
  maxVelocity            = 3.7,
  maxWaterDepth          = 22,
  movementClass          = [[TANK2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[corgator_512.s3o]],
  script                 = [[vehraid.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_ORANGE_SMALL]],
    },

  },
  sightDistance          = 560,
  trackOffset            = 5,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 28,
  turninplace            = 0,
  turnRate               = 1125,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[HEATRAY]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    HEATRAY = {
      name                    = [[Heat Ray]],
      accuracy                = 512,
      areaOfEffect            = 20,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 1500,
        light_color = [[0.9 0.4 0.12]],
        light_radius = 180,
        light_fade_time = 25,
        light_fade_offset = 10,
        light_beam_mult_frames = 9,
        light_beam_mult = 8,
      },

      damage                  = {
        default = 30,
        planes  = 30,
      },

      duration                = 0.3,
      dynDamageExp            = 1,
      dynDamageInverted       = false,
      dynDamageRange          = 270,
      explosionGenerator      = [[custom:HEATRAY_HIT]],
      fallOffRate             = 1,
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      leadLimit               = 5,
      lodDistance             = 10000,
      noSelfDamage            = true,
      proximityPriority       = 10,
      range                   = 262,
      reloadtime              = 0.1,
      rgbColor                = [[1 0.1 0]],
      rgbColor2               = [[1 1 0.25]],
      soundStart              = [[weapon/heatray_fire]],
      thickness               = 3,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 491.25,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[gatorwreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
