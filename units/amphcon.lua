unitDef = {
  unitname            = [[amphcon]],
  name                = [[Conch]],
  description         = [[Amphibious Construction Bot, Builds at 7.5 m/s]],
  acceleration        = 0.4,
  activateWhenBuilt   = true,
  brakeRate           = 0.25,
  buildCostEnergy     = 180,
  buildCostMetal      = 180,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[amphcon.png]],
  buildTime           = 180,
  canAssist           = true,
  canBuild            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    amph_regen = 10,
    amph_submerged_at = 40,
    helptext       = [[The Conch is a sturdy constructor that can build or reclaim in the deep sea as well as it does on land.]],
  },

  energyMake          = 0.225,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 850,
  maxSlope            = 36,
  maxVelocity         = 1.7,
  metalMake           = 0.225,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  objectName          = [[amphcon.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  script              = [[amphcon.lua]],
  showNanoSpray       = false,
  sightDistance       = 375,
  sonarDistance       = 375,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ChickenTrackPointy]],
  trackWidth          = 22,
  terraformSpeed      = 450,
  turnRate            = 1000,
  upright             = false,
  workerTime          = 7.5,

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[amphcon_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

}

return lowerkeys({ amphcon = unitDef })
