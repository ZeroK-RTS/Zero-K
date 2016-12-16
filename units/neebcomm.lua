unitDef = {
  unitname            = [[neebcomm]],
  name                = [[Neeb Comm]],
  description         = [[Ugly Turkey]],
  acceleration        = 0.2,
  brakeRate           = 0.205,
  buildCostEnergy     = 1200,
  buildCostMetal      = 1200,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[chickenbroodqueen.png]],
  buildTime           = 1200,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = true,
  cantBeTransported   = true,
  category            = [[LAND UNARMED]],

  customParams        = {
    helptext       = [[This fat chicken is presented to you as a reward for your misdeeds. Behave next time!]],
	level		   = [[1]],
  },

  energyMake		  = 2,
  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[chickenc]],
  idleAutoHeal        = 0,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 2000,
  maxSlope            = 36,
  maxVelocity         = 1.2,
  maxWaterDepth       = 22,
  metalMake           = 2,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[chickenbroodqueen.s3o]],
  power               = 2500,
  reclaimable         = false,
  script			  = [[chickenbroodqueen.cob]],
  seismicSignature    = 4,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },

  showNanoSpray       = false,
  showPlayerName      = true,
  sightDistance       = 500,
  sonarDistance       = 300,
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrack]],
  trackWidth          = 40,
  turnRate            = 573,
  upright             = false,
  workerTime          = 7.5,

}

return lowerkeys({ neebcomm = unitDef })
