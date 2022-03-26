return { staticsonar = {
  unitname          = [[staticsonar]],
  name              = [[Sonar Station]],
  description       = [[Locates Water Units]],
  activateWhenBuilt = true,
  buildCostMetal    = 450,
  builder           = false,
  buildPic          = [[staticsonar.png]],
  category          = [[UNARMED FLOAT]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[32 48 32]],
  collisionVolumeType           = [[CylY]],
  corpse            = [[DEAD]],
  energyUse         = 1.5,
  explodeAs         = [[SMALL_BUILDINGEX]],
  floater           = true,
  footprintX        = 2,
  footprintZ        = 2,
  iconType          = [[sonar]],
  maxDamage         = 750,
  maxSlope          = 18,
  minWaterDepth     = 10,
  objectName        = [[novasonar.s3o]],
  onoffable         = true,
  script            = "staticsonar.lua",
  selfDestructAs    = [[SMALL_BUILDINGEX]],
  sightDistance     = 640,
  sonarDistance     = 640,
  waterLine         = 0,
  yardMap           = [[oo oo]],
  
  customParams                  = {
    modelradius    = [[16]],
    removewait     = 1,
    removestop     = 1,
    priority_misc  = 2, -- High
    sonar_can_be_disabled = 1,
  },

  featureDefs       = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[novasonar_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
