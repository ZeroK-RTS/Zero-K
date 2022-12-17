return { cloakriot = {
  unitname               = [[cloakriot]],
  name                   = [[Reaver]],
  description            = [[Riot Bot]],
  acceleration           = 0.75,
  brakeRate              = 1.2,
  buildCostMetal         = 210,
  buildPic               = [[cloakriot.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 1 -1]],
  collisionVolumeScales  = [[26 36 26]],
  collisionVolumeType    = [[cylY]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 45 45]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius       = [[7]],
    cus_noflashlight  = 1,
    selection_scale   = 0.85,
    aim_lookahead     = 120,
    set_target_range_buffer = 35,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 15.5,
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[kbotriot]],
  idleAutoHeal           = 15,
  idleTime               = 150,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 36,
  maxVelocity            = 1.75,
  maxWaterDepth          = 22,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[Spherewarrior.s3o]],
  script                 = [[cloakriot.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:emg_shells_l]],
    },

  },

  sightDistance          = 350,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.8,
  trackType              = [[ComTrack]],
  trackWidth             = 20,
  turnRate               = 1840,
  upright                = true,

  weapons                = {

    {
      def                = [[WARRIOR_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    WARRIOR_WEAPON = {
      name                    = [[Heavy Pulse MG]],
      accuracy                = 350,
      alphaDecay              = 0.7,
      areaOfEffect            = 96,
      burnblow                = true,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      customParams        = {
        reaim_time = 3, -- Moderate sideways gun prevention.
        light_camera_height = 1600,
        light_color = [[0.8 0.76 0.38]],
        light_radius = 150,
        force_ignore_ground = [[1]],
      },

      damage                  = {
        default = 45,
        planes  = 45,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 265,
      reloadtime              = 0.466,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 580,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherewarrior_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
