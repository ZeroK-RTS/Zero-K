return { staticmex = {
  unitname               = [[staticmex]],
  name                   = [[Metal Extractor]],
  description            = [[Produces Metal]],
  activateWhenBuilt      = true,
  buildCostMetal         = 85,
  builder                = false,
  buildingMask           = 0,
  buildPic               = [[staticmex.png]],
  category               = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[0 -8 0]],
  collisionVolumeScales  = [[40 58 40]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    occupationStrength = 1,
    pylonrange         = 50,
    ismex              = 1,
    aimposoffset       = [[0 11 0]],
    midposoffset       = [[0 0 0]],
    modelradius        = [[15]],
    removewait         = 1,
    removestop     = 1,
    selectionscalemult = 1.4,

    outline_x = 75,
    outline_y = 75,
    outline_yoff = 10,
    outline_sea_x = 200,
    outline_sea_y = 260,
    outline_sea_yoff = -70,
  },

  energyUse              = 0,
  explodeAs              = [[SMALL_BUILDINGEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[mex]],
  levelGround            = false,
  maxDamage              = 600,
  maxSlope               = 28,
  maxVelocity            = 0,
  maxWaterDepth          = 5000,
  noAutoFire             = false,
  objectName             = [[AMETALEXTRACTORLVL1.S3O]],
  onoffable              = false,
  script                 = "staticmex.lua",
  selfDestructAs         = [[SMALL_BUILDINGEX]],
  sightDistance          = 273,
  waterline              = 1,
  workerTime             = 0,
  yardMap                = [[ooooooooo]],

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[AMETALEXTRACTORLVL1_DEAD.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
