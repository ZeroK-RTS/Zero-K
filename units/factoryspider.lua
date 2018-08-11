unitDef = {
  unitname                      = [[factoryspider]],
  name                          = [[Spider Factory]],
  description                   = [[Produces Spiders, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 10,
  buildingGroundDecalType       = [[factoryspider_aoplane.dds]],

  buildoptions                  = {
    [[spidercon]],
    [[spiderscout]],
	[[spiderassault]],
    [[spideremp]],
	[[spiderriot]],
    [[spiderskirm]],
    [[spidercrabe]],
    [[spideraa]],
    [[spiderantiheavy]],
  },

  buildPic                      = [[factoryspider.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 -16]],
  collisionVolumeScales         = [[104 50 36]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 0 14]],
  selectionVolumeScales         = [[104 50 96]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    aimposoffset   = [[0 0 -26]],
    midposoffset   = [[0 0 -10]],
    sortName       = [[5]],
	modelradius    = [[100]],
	solid_factory = [[3]],
	default_spacing = 8,
	unstick_help   = 1,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[facspider]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState                     = 1,
  noAutoFire                    = false,
  objectName                    = [[factory3.s3o]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  script                        = [[factoryspider.lua]],
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[ooooooo ooooooo ooooooo ccccccc ccccccc ccccccc ccccccc]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 5,
      footprintZ       = 6,
      object           = [[factory3_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 5,
      footprintZ       = 5,
      object           = [[debris4x4c.s3o]],
    },

  },

}

return lowerkeys({ factoryspider = unitDef })
