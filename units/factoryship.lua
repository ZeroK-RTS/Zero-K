unitDef = {
  unitname               = [[factoryship]],
  name                   = [[Shipyard]],
  description            = [[Produces Ships, Builds at 10 m/s]],
  acceleration           = 0,
  brakeRate              = 0,
  buildCostMetal         = 600,
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
  canAttack              = true,
  canMove                = true,
  canPatrol              = true,
  canStop                = true,
  category               = [[UNARMED FLOAT]],
  collisionVolumeOffsets = [[-22 5 0]],
  collisionVolumeScales  = [[48 48 184]],
  collisionVolumeType    = [[cylZ]],
  selectionVolumeOffsets = [[18 0 0]],
  selectionVolumeScales  = [[130 50 184]],
  selectionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_de = [[Produziert Schiffe, Baut mit 10 M/s]],
	helptext       = [[Shipyard is where both ships and submarines are built. Other waterborne units such as hovercraft and amphibious bots have separate factories.]],
	helptext_de    = [[Im Shipyard kannst du Schiffe jeder Art und f�r jeden Zweck bauen.]],
    sortName       = [[7]],
	unstick_help   = 1,
    aimposoffset   = [[60 0 -15]],
    midposoffset   = [[0 0 -15]],
	solid_factory = [[3]],
	modelradius    = [[50]],
	solid_factory_rotation = [[1]], -- 90 degrees counter clockwise
  },

  energyUse              = 0,
  explodeAs              = [[LARGE_BUILDINGEX]],
  footprintX             = 8,
  footprintZ             = 12,
  iconType               = [[facship]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maxDamage              = 6000,
  maxSlope               = 15,
  maxVelocity            = 0,
  minCloakDistance       = 150,
  minWaterDepth          = 15,
  moveState        		 = 1,
  objectName             = [[seafac.s3o]],
  script				 = [[factoryship.lua]],
  selfDestructAs         = [[LARGE_BUILDINGEX]],
  showNanoSpray          = false,
  sightDistance          = 273,
  turnRate               = 0,
  waterline              = 0,
  workerTime             = 10,
  yardMap                = [[oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc oooccccc]],

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

}

return lowerkeys({ factoryship = unitDef })
