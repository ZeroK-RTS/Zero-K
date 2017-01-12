unitDef = {
  unitname               = [[dynstrike1]],
  name                   = [[Strike Commander]],
  description            = [[Mobile Assault Commander]],
  acceleration           = 0.18,
  activateWhenBuilt      = true,
  brakeRate              = 0.375,
  buildCostEnergy        = 1200,
  buildCostMetal         = 1200,
  buildDistance          = 128,
  builder                = true,

  buildoptions           = {
  },

  buildPic               = [[commstrike.png]],
  buildTime              = 1200,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[45 50 45]],
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
	description_de = [[Mobiler Sturmkommandant]],
	helptext       = [[The Strike Commander is a well-balanced command platform that can mount most modules, with decent speed, armor, and regeneration.]],
	helptext_de    = [[Der Strike Commander bietet ein sehr ausgeglichenes Gerüst, das mit den meisten Modulen ausgerüstet werden kann, mit anständiger Geschwindigkeit, Panzerung und Selbstreparierung.]],
	level = [[1]],
	statsname = [[dynstrike1]],
	soundok = [[heavy_bot_move]],
	soundselect = [[bot_select]],
	soundbuild = [[builder_start]],
	commtype = [[1]],
	--decorationicons = {chest = "friendly", shoulders = "arrows-dot"},
    aimposoffset   = [[0 15 0]],
	modelradius    = [[25]],
	dynamic_comm   = 1,
  },

  energyStorage          = 500,
  explodeAs              = [[ESTOR_BUILDINGEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[commander1]],
  idleAutoHeal           = 5,
  idleTime               = 0,
  leaveTracks            = true,
  losEmitHeight          = 40,
  maxDamage              = 2500,
  maxSlope               = 36,
  maxVelocity            = 1.35,
  maxWaterDepth          = 5000,
  metalStorage           = 500,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[strikecom.dae]],
  script                 = [[dynstrike.lua]],
  seismicSignature       = 16,
  selfDestructAs         = [[ESTOR_BUILDINGEX]],

  sfxtypes               = {

    explosiongenerators = {
    	[[custom:BEAMWEAPON_MUZZLE_BLUE]],
		[[custom:NONE]],
    },

  },

  showNanoSpray          = false,
  sightDistance          = 500,
  sonarDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 26,
  terraformSpeed         = 600,
  turnRate               = 1148,
  upright                = true,
  workerTime             = 10,

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[strikecom_dead_1.dae]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },


  },

}

return lowerkeys({ dynstrike1 = unitDef })
