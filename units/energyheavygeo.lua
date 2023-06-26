return { energyheavygeo = {
  unitname                      = [[energyheavygeo]],
  name                          = [[Advanced Geothermal]],
  description                   = [[Large Powerplant (+100) - HAZARDOUS]],
  activateWhenBuilt             = true,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 9,
  buildingGroundDecalType       = [[energyheavygeo_aoplane.dds]],
  buildPic                      = [[energyheavygeo.png]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pylonrange     = 150,
    removewait     = 1,
    removestop     = 1,
    aimposoffset = [[0 30 0]],

    stats_show_death_explosion = 1,
  },

  energyMake                    = 100,
  explodeAs                     = [[NUCLEAR_MISSILE]],
  footprintX                    = 5,
  footprintZ                    = 5,
  iconType                      = [[energyheavygeo]],
  maxDamage                     = 3250,
  maxSlope                      = 255,
  metalCost                     = 1500,
  objectName                    = [[energyheavygeo.s3o]],
  script                        = [[energyheavygeo.lua]],
  selfDestructAs                = [[NUCLEAR_MISSILE]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooooo ogggo ogggo ogggo ooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[energyheavygeo_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
