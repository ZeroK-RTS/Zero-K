return { cloakcon = {
  unitname               = [[cloakcon]],
  name                   = [[Conjurer]],
  description            = [[Cloaked Construction Bot]],
  acceleration           = 1.5,
  activateWhenBuilt      = true,
  brakeRate              = 9.0,
  buildCostMetal         = 120,
  buildDistance          = 128,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[cloakcon.png]],
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  canCloak               = true,
  cloakCost              = 0, -- resource drain would be counterproductive on a con; default-off would hurt discoverability
  cloakCostMoving        = 0,
  collisionVolumeOffsets = [[0 4 0]],
  collisionVolumeScales  = [[28 40 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[14]],
    cus_noflashlight = 1,

    area_cloak = 1,
    area_cloak_init = 0,
    area_cloak_upkeep = 10,
    area_cloak_radius = 175,
    area_cloak_self_decloak_distance = 220,
    area_cloak_grow_rate = 320,
    area_cloak_shrink_rate = 1400,
    area_cloak_move_mult = 0.666,

    priority_misc = 2, -- High
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[builder]],
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 600,
  maxSlope               = 36,
  maxVelocity            = 1.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  objectName             = [[spherecon.s3o]],
  radarDistanceJam       = 175,
  script                 = [[cloakcon.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 375,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2640,
  upright                = true,
  workerTime             = 5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[cloakcon_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
