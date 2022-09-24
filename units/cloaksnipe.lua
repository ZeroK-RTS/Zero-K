return { cloaksnipe = {
  unitname               = [[cloaksnipe]],
  name                   = [[Phantom]],
  description            = [[Cloaked Skirmish/Anti-Heavy Artillery Bot]],
  acceleration           = 0.9,
  brakeRate              = 1.2,
  buildCostMetal         = 750,
  buildPic               = [[cloaksnipe.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 1,
  cloakCostMoving        = 5,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 60 30]],
  collisionVolumeType    = [[cylY]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 45 45]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 1,
    modelradius    = [[15]],
    dontfireatradarcommand = '0',
    no_decloak_on_weapon_fire = 1,
    reload_move_penalty = 0.66,

    outline_x = 120,
    outline_y = 120,
    outline_yoff = 32.5,
  },

  decloakOnFire          = false,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[sniper]],
  leaveTracks            = true,
  losEmitHeight          = 40,
  initCloaked            = true,
  maxDamage              = 560,
  maxSlope               = 36,
  maxVelocity            = 1.4,
  maxWaterDepth          = 22,
  minCloakDistance       = 155,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SUB]],
  objectName             = [[sharpshooter.s3o]],
  script                 = [[cloaksnipe.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WEAPEXP_PUFF]],
      [[custom:MISSILE_EXPLOSION]],
    },

  },

  sightDistance          = 400,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2500,
  upright                = true,

  weapons                = {

    {
      def                = [[SHOCKRIFLE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    SHOCKRIFLE = {
      name                    = [[Pulsed Particle Projector]],
      areaOfEffect            = 16,
      colormap                = [[0 0 0.4 0   0 0 0.6 0.3   0 0 0.8 0.6   0 0 0.9 0.8   0 0 1 1   0 0 1 1]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams              = {
        reaim_time = 1, -- Keep aiming at target to prevent sideways gun, which can lead to teamkill.
        burst = Shared.BURST_RELIABLE,
        light_radius = 0,
      },
      
      damage                  = {
        default = 1500.1,
        planes  = 1500.1,
      },

      explosionGenerator      = [[custom:spectre_hit]],
      fireTolerance           = 512, -- 2.8 degrees
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 700,
      reloadtime              = 17,
      rgbColor                = [[1 0.2 0.2]],
      separation              = 1.5,
      size                    = 5,
      sizeDecay               = 0,
      soundHit                = [[weapon/laser/heavy_laser6]],
      soundStart              = [[weapon/gauss_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 850,
    },

  },

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[sharpshooter_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
