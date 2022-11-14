return { vehcon = {
  unitname               = [[vehcon]],
  name                   = [[Mason]],
  description            = [[Construction Rover]],
  acceleration           = 0.4,
  brakeRate              = 18.0,
  buildCostMetal         = 120,
  buildDistance          = 180,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[vehcon.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[28 28 40]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[20]],
    selection_scale = 1.2,
    cus_noflashlight = 1,
  },

  energyUse              = 0,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[builder]],
  leaveTracks            = true,
  maxDamage              = 1000,
  maxSlope               = 18,
  maxVelocity            = 2.3,
  maxWaterDepth          = 22,
  movementClass          = [[TANK2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[corcv.s3o]],
  script                 = [[vehcon.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 300,
  trackOffset            = -3,
  trackStrength          = 6,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 1000,
  workerTime             = 5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[corcv_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
