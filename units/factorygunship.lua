return { factorygunship = {
  name                          = [[Gunship Plant]],
  description                   = [[Produces Gunships]],
  buildDistance                 = Shared.FACTORY_PLATE_RANGE,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 10,
  buildingGroundDecalSizeY      = 10,
  buildingGroundDecalType       = [[factorygunship_aoplane.dds]],

  buildoptions                  = {
    [[gunshipcon]],
    [[gunshipbomb]],
    [[gunshipemp]],
    [[gunshipraid]],
    [[gunshipskirm]],
    [[gunshipheavyskirm]],
    [[gunshipassault]],
    [[gunshipkrow]],
    [[gunshipaa]],
    [[gunshiptrans]],
    [[gunshipheavytrans]],
  },

  buildPic                      = [[factorygunship.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[86 86 86]],
  collisionVolumeType           = [[ellipsoid]],
  selectionVolumeOffsets        = [[0 10 0]],
  selectionVolumeScales         = [[104 60 96]],
  selectionVolumeType           = [[box]],
  corpse                        = [[DEAD]],

  customParams                  = {
    ploppable = 1,
    landflystate   = [[0]],
    factory_land_state = 0,
    sortName = [[3]],
    modelradius    = [[43]],
    default_spacing = 8,
    factorytab       = 1,
    shared_energy_gen = 1,
    parent_of_plate   = [[plategunship]],
    buggeroff_offset    = 0,

    stats_show_death_explosion = 1,

    outline_x = 250,
    outline_y = 250,
    outline_yoff = 5,
  },

  explodeAs                     = [[LARGE_BUILDINGEX]],
  footprintX                    = 7,
  footprintZ                    = 7,
  iconType                      = [[facgunship]],
  maxDamage                     = 4000,
  maxSlope                      = 15,
  metalCost                     = Shared.FACTORY_COST,
  moveState                     = 1,
  noAutoFire                    = false,
  objectName                    = [[factorygunship.s3o]],
  script                        = [[factorygunship.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  waterline                     = 0,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[yyoooyy yoooooy ooooooo ooooooo ooooooo yoooooy yyoooyy]],

  featureDefs                   = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[factorygunship_dead.s3o]],
      collisionVolumeOffsets        = [[0 -20 0]],
      collisionVolumeScales         = [[86 86 86]],
      collisionVolumeType           = [[ellipsoid]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
