unitDef = {
  unitname               = [[spidercon]],
  name                   = [[Weaver]],
  description            = [[Construction Spider, Builds at 7.5 m/s]],
  acceleration           = 0.2,
  activateWhenBuilt      = true,
  brakeRate              = 0.6,
  buildCostMetal         = 170,
  buildDistance          = 220,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[spidercon.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND UNARMED]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[30 30 30]],
  collisionVolumeType    = [[ellipsoid]], 
  corpse                 = [[DEAD]],

  customParams           = {
	modelradius    = [[15]],
  },

  energyUse              = 0,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 72,
  maxVelocity            = 1.8,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  objectName             = [[weaver.s3o]],
  radarDistance          = 1200,
  radarEmitHeight        = 12,
  script                 = [[spidercon.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 380,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 54,
  turnRate               = 1400,
  workerTime             = 7.5,

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[weaver_wreck.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

}

return lowerkeys({ spidercon = unitDef })
