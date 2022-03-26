return { energyfusion = {
  unitname                      = [[energyfusion]],
  name                          = [[Fusion Reactor]],
  description                   = [[Medium Powerplant (+35)]],
  activateWhenBuilt             = true,
  buildCostMetal                = 1000,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 6,
  BuildingGroundDecalSizeY      = 6,
  BuildingGroundDecalType       = [[energyfusion_ground.dds]],
  buildPic                      = [[energyfusion.png]],
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pylonrange = 150,
    removewait = 1,
    removestop     = 1,
  },

  energyMake                    = 35,
  energyUse                     = 0,
  explodeAs                     = [[ATOMIC_BLAST]],
  footprintX                    = 5,
  footprintZ                    = 4,
  iconType                      = [[energyfusion]],
  maxDamage                     = 2200,
  maxSlope                      = 18,
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
