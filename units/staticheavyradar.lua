return { staticheavyradar = {
  unitname                      = [[staticheavyradar]],
  name                          = [[Advanced Radar]],
  description                   = [[Long-Range Radar]],
  activateWhenBuilt             = true,
  buildCostMetal                = 500,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 4,
  buildingGroundDecalSizeY      = 4,
  buildingGroundDecalType       = [[staticheavyradar_aoplane.dds]],
  buildPic                      = [[staticheavyradar.png]],
  category                      = [[UNARMED FLOAT]],
  collisionVolumeOffsets        = [[0 -8 0]],
  collisionVolumeScales         = [[32 83 32]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    modelradius    = [[16]],
    removewait     = 1,
    priority_misc  = 2, -- High
  },

  energyUse                     = 3,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[advradar]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 330,
  maxSlope                      = 36,
  minCloakDistance              = 150,
  objectName                    = [[novaradar.s3o]],
  script                        = [[staticheavyradar.lua]],
  onoffable                     = true,
  radarDistance                 = 4000,
  radarEmitHeight               = 32,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 800,
  useBuildingGroundDecal        = true,
  yardMap                       = [[oooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[novaradar_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
