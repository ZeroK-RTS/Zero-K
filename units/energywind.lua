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
  collisionVolumeOffsets        = [[0 5 0]],
  collisionVolumeScales         = [[30 80 30]],
  collisionVolumeType           = [[CylY]],
  corpse                        = [[DEAD]],

  customParams                  = {
    bait_level_target = 1,
    pylonrange     = 60,
    windgen        = true,
    modelradius    = [[12]],
    removewait     = 1,
    removestop     = 1,
    default_spacing = 2,

    tidal_health = 400,

    outline_x = 140,
    outline_y = 115,
    outline_yoff = 30,
  },

  energyMake                    = 1.2, --[[ as tidal; NOT added to wind (which is fully gadgeted
                                            and cannot be found in this unit def file). Also used
                                            as the income of a "generic" turbine, i.e. unspecified
                                            whether wind or tidal (for example when hovering over
                                            the icon on the UI to check OD payback ETA) since it
                                            approximately averages the income of a wind with some
                                            penalty for unreliability. ]]
  energyUse                     = 0,
  explodeAs                     = [[SMALL_BUILDINGEX]],
  floater                       = true,
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[energywind]],
  levelGround                   = false,
  losEmitHeight                 = 30,
  maxDamage                     = 150, -- as wind; see customparams for tidal
  maxSlope                      = 75,
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
