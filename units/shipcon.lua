return { shipcon = {
  unitname               = [[shipcon]],
  name                   = [[Mariner]],
  description            = [[Construction Ship]],
  acceleration           = 0.307,
  activateWhenBuilt      = true,
  brakeRate              = 0.732,
  buildCostMetal         = 200,
  buildDistance          = 330,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[shipcon.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP UNARMED]],
  collisionVolumeOffsets = [[0 8 0]],
  collisionVolumeScales  = [[25 25 96]],

  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[40]],
    turnatfullspeed = [[1]],
    selection_scale = 1.2,

    outline_x = 128,
    outline_y = 128,
    outline_yoff = 16,
  },

  energyUse              = 0,
  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  maxDamage              = 1400,
  maxVelocity            = 2.5,
  minWaterDepth          = 5,
  movementClass          = [[BOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[shipcon.s3o]],
  script                 = [[shipcon.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 375,
  sonarDistance          = 375,
  turninplace            = 0,
  turnRate               = 813,
  workerTime             = 7.5,

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[shipcon_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
