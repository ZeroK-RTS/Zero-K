unitDef = {
  unitname               = [[staticmex]],
  name                   = [[Metal Extractor]],
  description            = [[Produces Metal]],
  acceleration           = 0,
  activateWhenBuilt      = true,
  brakeRate              = 0,
  buildCostMetal         = 75,
  builder                = false,
  buildingMask           = 0,
  buildPic               = [[staticmex.png]],
  category               = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[40 40 40]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    occupationStrength = 1,
    pylonrange         = 50,
	ismex              = 1,
	aimposoffset       = [[0 -4 0]],
	midposoffset       = [[0 -10 0]],
	modelradius        = [[15]],
	removewait         = 1,
    selectionscalemult = 1.4,
  },

  energyUse              = 0,
  explodeAs              = [[SMALL_BUILDINGEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[mex]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  levelGround            = false,
  maxDamage              = 400,
  maxSlope               = 255,
  maxVelocity            = 0,
  maxWaterDepth          = 5000,
  minCloakDistance       = 150,
  noAutoFire             = false,
  objectName             = [[AMETALEXTRACTORLVL1.S3O]],
  onoffable              = false,
  script                 = "staticmex.lua",
  selfDestructAs         = [[SMALL_BUILDINGEX]],
  sightDistance          = 273,
  turnRate               = 0,
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

}

return lowerkeys({ staticmex = unitDef })
