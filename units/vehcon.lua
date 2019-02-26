unitDef = {
  unitname               = [[vehcon]],
  name                   = [[Mason]],
  description            = [[Construction Rover, Builds at 5 m/s]],
  acceleration           = 0.066,
  brakeRate              = 1.5,
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
  },

  energyUse              = 0,
  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[builder]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 900,
  maxSlope               = 18,
  maxVelocity            = 2.4,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[corcv.s3o]],
  selfDestructAs         = [[BIG_UNITEX]],
  showNanoSpray          = false,
  sightDistance          = 273,
  trackOffset            = -3,
  trackStrength          = 6,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 625,
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

}

return lowerkeys({ vehcon = unitDef })
