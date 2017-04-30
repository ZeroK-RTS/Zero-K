unitDef = {
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

    description_de = [[Erweitert den Bereich des Overdrive-Energienetzes]],
    helptext       = [[Energy Transmission Pylons help extend energy grids and connect more Extractors or energy sources. This in turn helps Extractors overdrive, producing more metal. Pylons can also provide a fast way to power defenses that rely on the energy grid. Note that over short distances or in low-energy situations using energy producers like solar collectors to connect grids can be a more cost efficient alternative.]],
    helptext_de    = [[Durch das Energy Pylon wird es dir ermöglicht, weitere Energiequellen oder Metallextraktoren an ein bestehendes Overdrive-Energienetz anzuschließen.]],
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -6 0]],
    modelradius    = [[24]],
	removewait     = 1,
  },

  explodeAs                     = [[ESTOR_BUILDINGEX]],
  footprintX                    = 3,
  footprintZ                    = 3,
  iconType                      = [[pylon]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 1000,
  maxSlope                      = 18,
  minCloakDistance              = 150,
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
      object           = [[energypylon_DEAD.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris4x4b.s3o]],
    },

  },

}

return lowerkeys({ energypylon = unitDef })
