unitDef = {
  unitname                      = [[factorytank]],
  name                          = [[Tank Foundry]],
  description                   = [[Produces Heavy Tracked Vehicles, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = Shared.FACTORY_COST,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[factorytank_aoplane.dds]],

  buildoptions                  = {
    [[tankcon]],
    [[tankraid]],
    [[tankheavyraid]],
    [[tankriot]],
    [[tankassault]],
    [[tankheavyassault]],
    [[tankarty]],
    [[tankheavyarty]],
    [[tankaa]],
  },

  buildPic                      = [[factorytank.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[SINK UNARMED]],
  corpse                        = [[DEAD]],
  collisionVolumeOffsets        = [[0 0 -25]],
  collisionVolumeScales         = [[110 28 44]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 0 10]],
  selectionVolumeScales         = [[120 28 120]],
  selectionVolumeType           = [[box]],

  customParams                  = {
    sortName = [[6]],
    solid_factory = [[4]],
    default_spacing = 8,
    aimposoffset   = [[0 15 -35]],
    midposoffset   = [[0 15 -10]],
	modelradius    = [[100]],
	unstick_help   = 1,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[factank]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = false,
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  maxWaterDepth                 = 0,
  minCloakDistance              = 150,
  moveState                     = 1,
  noAutoFire                    = false,
  objectName                    = [[factorytank.s3o]],
  script                        = [[factorytank.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  turnRate                      = 0,
  useBuildingGroundDecal        = true,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = "xoooooox xoooooox xoooooox xoooooox xccccccx xccccccx xccccccx xccccccx",

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 8,
      footprintZ       = 8,
      object           = [[factorytank_dead.s3o]],
      collisionVolumeOffsets = [[0 14 -34]],
      collisionVolumeScales  = [[110 28 44]],
      collisionVolumeType    = [[box]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4a.s3o]],
    },

  },

}

return lowerkeys({ factorytank = unitDef })
