return { shiptransport = {
  unitname            = [[shiptransport]],
  name                = [[Surfboard]],
  description         = [[Transport Platform]],
  acceleration        = 0.51,
  activateWhenBuilt   = true,
  brakeRate           = 1.15,
  buildCostMetal      = 220,
  builder             = false,
  buildPic            = [[shiptransport.png]],
  canMove             = true,
  cantBeTransported   = true,
  category            = [[SHIP UNARMED]],
  collisionVolumeOffsets = [[0 0 -3]],
  collisionVolumeScales  = [[35 20 55]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    turnatfullspeed = [[1]],
    modelradius    = [[15]],
  },

  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  holdSteady          = true,
  iconType            = [[shiptransport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  isFirePlatform      = true,
  maxDamage           = 1200,
  maxVelocity         = 3.3,
  minCloakDistance    = 75,
  movementClass       = [[BOAT4]],
  noChaseCategory     = [[TERRAFORM FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[shiptransport]],
  releaseHeld         = true,
  script              = [[shiptransport.lua]],
  selfDestructAs      = [[BIG_UNITEX]],
  sightDistance       = 325,
  sonarDistance       = 325,
  transportCapacity   = 1,
  transportSize       = 3,
  turnRate            = 590,

  featureDefs         = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[shiptransport_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
