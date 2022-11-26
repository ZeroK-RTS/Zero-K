return { factoryship = {
  unitname               = [[factoryship]],
  name                   = [[Shipyard]],
  description            = [[Produces Naval Units]],
  buildCostMetal         = Shared.FACTORY_COST,
  buildDistance          = Shared.FACTORY_PLATE_RANGE,
  builder                = true,

  buildoptions           = {
    [[shipcon]],
    [[shipscout]],
    [[shiptorpraider]],
    [[subraider]],
    [[shipriot]],
    [[shipskirm]],
    [[shipassault]],
    [[shiparty]],
    [[shipaa]],
  },

  buildPic               = [[FACTORYSHIP.png]],
  canMove                = true,
  canPatrol              = true,
  category               = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[-22 5 0]],
  collisionVolumeScales  = [[48 48 184]],
  collisionVolumeType    = [[cylZ]],
  selectionVolumeOffsets = [[18 0 0]],
  selectionVolumeScales  = [[130 50 184]],
  selectionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    ploppable = 1,
    sortName       = [[7]],
    unstick_help   = 1,
    aimposoffset   = [[60 0 -15]],
    midposoffset   = [[0 0 -15]],
    solid_factory = [[2]],
    modelradius    = [[100]],
    solid_factory_rotation = [[1]], -- 90 degrees counter clockwise
    default_spacing = 8,
    selectionscalemult = 1,
    factorytab       = 1,
    shared_energy_gen = 1,
    cus_noflashlight = 1,
    parent_of_plate   = [[plateship]],
    buggeroff_offset    = 0,
    buggeroff_radius    = 42,

    outline_x = 340,
    outline_y = 340,
    outline_yoff = 25,
  },

  energyUse              = 0,
  explodeAs              = [[LARGE_BUILDINGEX]],
  footprintX             = 8,
  footprintZ             = 12,
  iconType               = [[facship]],
  maxDamage              = 6000,
  maxSlope               = 15,
  maxVelocity            = 0,
  minWaterDepth          = 15,
  moveState              = 1,
  objectName             = [[seafac.s3o]],
  script                 = [[factoryship.lua]],
  selfDestructAs         = [[LARGE_BUILDINGEX]],
  showNanoSpray          = false,
  sightDistance          = 273,
  waterline              = 0,
  workerTime             = Shared.FACTORY_BUILDPOWER,
  yardMap                = [[oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc oocccccc]],

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 9,
      footprintZ       = 14,
      object           = [[seafac_dead.s3o]],
    },



    HEAP  = {
      blocking         = false,
      footprintX       = 8,
      footprintZ       = 8,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
