return { amphcon = {
  unitname            = [[amphcon]],
  name                = [[Conch]],
  description         = [[Amphibious Construction Bot, Armored When Idle]],
  acceleration        = 1.2,
  activateWhenBuilt   = true,
  brakeRate           = 1.5,
  buildCostMetal      = 150,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[amphcon.png]],
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND UNARMED]],
  corpse              = [[DEAD]],

  customParams        = {
    bait_level_target_armor = 1,
    morphto        = [[amphtele]],
    morphtime      = 20,
    amph_regen = 10,
    amph_submerged_at = 40,
  },

  damageModifier      = 0.333,
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  leaveTracks         = true,
  maxDamage           = 850,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  movementClass       = [[AKBOT2]],
  objectName          = [[amphcon.s3o]],
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
  turnRate            = 1200,
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

} }
