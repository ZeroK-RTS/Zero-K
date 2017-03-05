unitDef = {
  unitname                      = [[armmstor]],
  name                          = [[Storage]],
  description                   = [[Stores Metal and Energy (500)]],
  activateWhenBuilt             = true,
  buildCostMetal                = 100,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 5,
  buildingGroundDecalSizeY      = 5,
  buildingGroundDecalType       = [[armmstor_aoplane.dds]],
  buildPic                      = [[ARMMSTOR.png]],
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
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 700,
  maxSlope                      = 18,
  metalStorage                  = 500,
  minCloakDistance              = 150,
  objectName                    = [[pylon.s3o]],
  script                        = "armmstor.lua",
  selfDestructAs                = [[SMALL_BUILDINGEX]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooo ooo ooo]],

  customParams                  = {
    description_de = [[Lagert Energie und Metall (500)]],
    helptext       = [[Storages act as a buffer when one expects a big influx of metal, such as reclaiming a vast wreckage field. However, longer periods of increased metal income are better dealt with by acquiring more buildpower.]],
    helptext_de    = [[Dieser Energie- und Metallspeicher erweitert deine Lagermöglichkeiten um 500.]],
    modelradius    = [[30]],
	removewait     = 1,
  },

  featureDefs                   = {

    DEAD  = {
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[storage_d.dae]],
    },

    HEAP  = {
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ armmstor = unitDef })
