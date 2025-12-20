return { spiderassault = {
  name                   = [[Hermit]],
  description            = [[All Terrain Assault Bot]],
  acceleration           = 0.54,
  brakeRate              = 1.32,
  buildPic               = [[spiderassault.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -3 0]],
  collisionVolumeScales  = [[24 30 24]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    modelradius    = [[12]],
    cus_noflashlight = 1,
    selection_scale = 1.05,
    normaltex = [[unittextures/hermit_normals.dds]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  health                 = 1550,
  iconType               = [[spiderassault]],
  leaveTracks            = true,
  maxSlope               = 36,
  maxWaterDepth          = 22,
  metalCost              = 145,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB DRONE]],
  objectName             = [[hermit.s3o]],
  selfDestructAs         = [[BIG_UNITEX]],
  script                 = [[spiderassault.lua]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 420,
  speed                  = 54,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 30,
  turnRate               = 1920,

  weapons                = {

    {
      def                = [[THUD_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    THUD_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 36,
      cegTag                  = [[light_plasma_trail]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 1800,
        light_color = [[0.80 0.54 0.23]],
        light_radius = 200,
        burst = Shared.BURST_RELIABLE,
      },

      damage                  = {
        default = 141,
        planes  = 141,
      },

      explosionGenerator      = [[custom:MARY_SUE]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 350,
      reloadtime              = 2.6,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 280,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[hermit_wreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
