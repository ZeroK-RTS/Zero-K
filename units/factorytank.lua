unitDef = {
  unitname                      = [[factorytank]],
  name                          = [[Tank Foundry]],
  description                   = [[Produces Heavy Tracked Vehicles, Builds at 10 m/s]],
  acceleration                  = 0,
  brakeRate                     = 0,
  buildCostMetal                = 600,
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
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[110 28 44]],
  collisionVolumeType           = [[box]],
  selectionVolumeOffsets        = [[0 -10 35]],
  selectionVolumeScales         = [[110 28 110]],
  selectionVolumeType           = [[box]],

  customParams                  = {
    sortName = [[6]],
    solid_factory = [[4]],
    default_spacing = 8,
    aimposoffset   = [[0 15 -35]],
    midposoffset   = [[0 15 -35]],
    modelradius    = [[30]],
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 8,
  footprintZ                    = 8,
  iconType                      = [[factank]],
  idleAutoHeal                  = 5,
  idleTime                      = 1800,
  levelGround                   = true,
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
  workerTime                    = 10,
  yardMap                       = "oooooooo oooooooo oooooooo oooooooo cccccccc cccccccc cccccccc cccccccc",

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
