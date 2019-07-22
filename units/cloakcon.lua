unitDef = {
  unitname               = [[cloakcon]],
  name                   = [[Conjurer]],
  description            = [[Cloaked Construction Bot, Builds at 5 m/s]],
  acceleration           = 0.5,
  activateWhenBuilt      = true,
  brakeRate              = 1.5,
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
  cloakCost              = 0,
  cloakCostMoving        = 0,
  collisionVolumeOffsets = [[0 4 0]],
  collisionVolumeScales  = [[28 40 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
	modelradius    = [[14]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 450,
  maxSlope               = 36,
  maxVelocity            = 1.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  objectName             = [[spherecon.s3o]],
  radarDistanceJam       = 256,
	script                 = [[cloakcon.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 375,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2200,
  upright                = true,
  workerTime             = 5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherejeth_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ cloakcon = unitDef })
