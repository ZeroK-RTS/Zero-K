return { staticheavyradar = {
  unitname                      = [[staticheavyradar]],
  name                          = [[Advanced Radar]],
  description                   = [[Long-Range Radar]],
  activateWhenBuilt             = true,
  buildCostMetal                = 400,
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
    removestop     = 1,
    priority_misc  = 2, -- High

    outline_x = 110,
    outline_y = 120,
    outline_yoff = 32.5,
  },

  energyUse                     = 3,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 2,
  footprintZ                    = 2,
  iconType                      = [[advradar]],
  levelGround                   = false,
  maxDamage                     = 330,
  maxSlope                      = 36,
  objectName                    = [[novaradar.s3o]],
  script                        = [[staticheavyradar.lua]],
  onoffable                     = true,
  radarDistance                 = 5600,
  radarEmitHeight               = 32,
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 1120,
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
