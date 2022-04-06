return { energypylon = {
  unitname                      = [[energypylon]],
  name                          = [[Energy Pylon]],
  description                   = [[Extends overdrive grid]],
  activateWhenBuilt             = true,
  buildCostMetal                = 200,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[energypylon_aoplane.dds]],
  buildPic                      = [[energypylon.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[48 48 48]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pylonrange = 500,
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -6 0]],
    modelradius    = [[24]],
    removewait     = 1,
    removestop     = 1,
    default_spacing = 41, -- Diagonal connection.
    selectionscalemult = 1.15,
  },

  explodeAs                     = [[ESTOR_BUILDINGEX]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[pylon]],
  levelGround                   = false,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  noAutoFire                    = false,
  objectName                    = [[armestor.s3o]],
  script                        = "energypylon.lua",
  selfDestructAs                = [[ESTOR_BUILDINGEX]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooo ooo ooo]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[ARMESTOR_DEAD.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
