return { factoryplane = {
  unitname                      = [[factoryplane]],
  name                          = [[Airplane Plant]],
  description                   = [[Produces Airplanes]],
  activateWhenBuilt             = false,
  buildCostMetal                = Shared.FACTORY_COST,
  buildDistance                 = Shared.FACTORY_PLATE_RANGE,
  builder                       = true,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 11,
  buildingGroundDecalSizeY      = 11,
  buildingGroundDecalType       = [[factoryplane_aoplane.dds]],

  buildoptions                  = {
    [[planecon]],
    [[planefighter]],
    [[planeheavyfighter]],
    [[bomberprec]],
    [[bomberriot]],
    [[bomberdisarm]],
    [[bomberheavy]],
    [[planescout]],
    [[planelightscout]],
  },

  buildPic                      = [[factoryplane.png]],
  canMove                       = true,
  canPatrol                     = true,
  category                      = [[FLOAT UNARMED]],
  collisionVolumeOffsets        = [[0 -8 -25]],
  collisionVolumeScales         = [[110 46 0]],
  collisionVolumeType           = [[cylX]],
  corpse                        = [[DEAD]],

  customParams                  = {
    ploppable = 1,
    pad_count = 1,
    landflystate   = [[0]],
    factory_land_state = 1,
    sortName = [[4]],
    modelradius    = [[51]], -- at 50 planefighter won't respond to Bugger Off calls
    aimposoffset   = [[0 23 -25]],
    midposoffset   = [[0 20 0]],
    default_spacing = 8,
    factorytab       = 1,
    shared_energy_gen = 1,
    ispad         = 1,
    parent_of_plate   = [[plateplane]],
    buggeroff_radius    = 40,
    buggeroff_offset    = 15,

    outline_x = 250,
    outline_y = 250,
    outline_yoff = 5,
  },

  energyUse                     = 0,
  explodeAs                     = [[LARGE_BUILDINGEX]],
  fireState                     = 0,
  footprintX                    = 8,
  footprintZ                    = 7,
  iconType                      = [[facair]],
  maxDamage                     = 4000,
  maxSlope                      = 15,
  maxVelocity                   = 0,
  noAutoFire                    = false,
  objectName                    = [[CORAP.s3o]],
  script                        = [[factoryplane.lua]],
  selfDestructAs                = [[LARGE_BUILDINGEX]],
  showNanoSpray                 = false,
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  waterline                     = 0,
  workerTime                    = Shared.FACTORY_BUILDPOWER,
  yardMap                       = [[oooooooo oooooooo oooooooo occooooo occooooo oooooooo oooooooo]],

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 6,
      object           = [[corap_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 6,
      footprintZ       = 6,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
