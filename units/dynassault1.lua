unitDef = {
  unitname            = [[dynassault1]],
  name                = [[Guardian Commander]],
  description         = [[Heavy Combat Commander]],
  acceleration        = 0.18,
  activateWhenBuilt   = true,
  brakeRate           = 0.375,
  buildCostMetal      = 1200,
  buildDistance       = 144,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[benzcom.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 54 45]],
  collisionVolumeType    = [[CylY]],  
  corpse              = [[DEAD]],

  customParams        = {
	level = [[1]],
	statsname = [[dynassault1]],
	soundok = [[heavy_bot_move]],
	soundselect = [[bot_select]],
	soundbuild = [[builder_start]],
	commtype = [[5]],
	modelradius    = [[27]],
	dynamic_comm   = 1,
	shared_energy_gen = 1,
  },

  energyStorage       = 500,
  energyUse           = 0,
  explodeAs           = [[ESTOR_BUILDINGEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[commander1]],
  idleAutoHeal        = 5,
  idleTime            = 0,
  leaveTracks         = true,
  losEmitHeight       = 40,
  maxDamage           = 4400,
  maxSlope            = 36,
  maxVelocity         = 1.35,
  maxWaterDepth       = 5000,
  metalStorage        = 500,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK]],
  objectName          = [[benzcom1.s3o]],
  script              = [[dynassault.lua]],
  selfDestructAs      = [[ESTOR_BUILDINGEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:LEVLRMUZZLE]],
      [[custom:RAIDMUZZLE]],
	  [[custom:NONE]],
	  [[custom:NONE]],
	  [[custom:NONE]],
    },

  },

  showNanoSpray       = false,
  sightDistance       = 500,
  sonarDistance       = 500,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 1148,
  upright             = true,
  workerTime          = 10,

  featureDefs         = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[benzcom1_wreck.s3o]],
    },


    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}

return lowerkeys({ dynassault1 = unitDef })

