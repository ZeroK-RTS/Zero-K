return { staticstorage = {
  unitname                      = [[staticstorage]],
  name                          = [[Storage]],
  description                   = [[Stores Metal and Energy (500)]],
  activateWhenBuilt             = true,
  buildCostMetal                = 100,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[staticstorage_aoplane.dds]],
  buildPic                      = [[staticstorage.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[60 60 60]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],
  energyStorage                 = 500,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[storage]],
  maxDamage                     = 700,
  maxSlope                      = 18,
  metalStorage                  = 500,
  objectName                    = [[pylon.s3o]],
  script                        = "staticstorage.lua",
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooo ooo ooo]],

  customParams                  = {
    modelradius    = [[30]],
    removewait     = 1,
    removestop     = 1,
    default_spacing = 0,
    selectionscalemult = 1.15,
  },

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[storage_d.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
