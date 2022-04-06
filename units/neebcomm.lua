return { neebcomm = {
  unitname            = [[neebcomm]],
  name                = [[Neeb Comm]],
  description         = [[Ugly Turkey]],
  acceleration        = 0.6,
  brakeRate           = 1.23,
  buildCostMetal      = 1200,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[chickenbroodqueen.png]],
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = true,
  cantBeTransported   = true,
  category            = [[LAND UNARMED]],

  customParams        = {
    level             = [[1]],
  },

  energyMake          = 2,
  energyStorage       = 500,
  explodeAs           = [[SMALL_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[chickenc]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = true,
  maxDamage           = 2000,
  maxSlope            = 36,
  maxVelocity         = 1.2,
  maxWaterDepth       = 22,
  metalMake           = 2,
  metalStorage        = 500,
  movementClass       = [[AKBOT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName          = [[chickenbroodqueen.s3o]],
  power               = 2500,
  reclaimable         = false,
  script              = [[chickenbroodqueen.cob]],
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
  turnRate            = 687,
  upright             = false,
  workerTime          = 7.5,

} }
