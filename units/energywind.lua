return { energywind = {
  unitname                      = [[energywind]],
  name                          = [[Wind/Tidal Generator]],
  description                   = [[Small Powerplant]],
  activateWhenBuilt             = true,
  buildCostMetal                = 35,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[energywind_aoplane.dds]],
  buildPic                      = [[energywind.png]],
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 15 0]],
  collisionVolumeScales         = [[30 60 30]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pylonrange     = 60,
    windgen        = true,
    modelradius    = [[15]],
    removewait     = 1,
    default_spacing = 2,
  },

  energyMake                    = 1.2,
  energyUse                     = 0,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[energywind]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  losEmitHeight                 = 30,
  maxDamage                     = 150,
  maxSlope                      = 75,
  minCloakDistance              = 150,
  objectName                    = [[arm_wind_generator.s3o]],
  script                        = [[energywind.lua]],
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooooooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[arm_wind_generator_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4a.s3o]],
    },

    DEADWATER = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[arm_wind_generator_dead_water.s3o]],
      customparams = {
        health_override = 400,
      },
    }

  },

} }
