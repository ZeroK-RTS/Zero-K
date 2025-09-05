return { energyfusion = {
  name                          = [[Fusion Reactor]],
  description                   = [[Medium Powerplant]],
  activateWhenBuilt             = true,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  BuildingGroundDecalSizeY      = 6,
  BuildingGroundDecalType       = [[energyfusion_ground.dds]],
  buildPic                      = [[energyfusion.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[80 80 70]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pylonrange = 150,
    removewait = 1,
    removestop     = 1,
    stats_show_death_explosion = 1,
  },

  energyMake                    = 35,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 5,
  footprintZ                    = 4,
  health                        = 2200,
  iconType                      = [[energyfusion]],
  maxSlope                      = 18,
  metalCost                     = 1000,
  objectName                    = [[energyfusion.s3o]],
  script                        = "energyfusion.lua",
  selfDestructAs                = [[ATOMIC_BLAST]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooooo ooooo ooooo ooooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 4,
      object           = [[energyfusion_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
