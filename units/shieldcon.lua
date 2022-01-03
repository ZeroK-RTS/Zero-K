return { shieldcon = {
  unitname            = [[shieldcon]],
  name                = [[Convict]],
  description         = [[Shielded Construction Bot]],
  acceleration        = 1.5,
  activateWhenBuilt   = true,
  brakeRate           = 1.8,
  buildCostMetal      = 120,
  buildDistance       = 128,
  builder             = true,

  buildoptions        = {
  },

  buildPic            = [[shieldcon.png]],
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND UNARMED]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[30 30 30]],
  selectionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],

  customParams        = {
    shield_emit_height = 17,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[builder]],
  leaveTracks         = true,
  maxDamage           = 780,
  maxSlope            = 36,
  maxVelocity         = 2.05,
  maxWaterDepth       = 22,
  movementClass       = [[KBOT2]],
  objectName          = [[conbot.s3o]],
  onoffable           = false,
  script              = [[shieldcon.lua]],
  selfDestructAs      = [[BIG_UNITEX]],
  showNanoSpray       = false,
  sightDistance       = 375,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 2640,
  upright             = true,
  workerTime          = 5,

  weapons             = {

    {
      def = [[SHIELD]],
    },

  },

  weaponDefs          = {

    SHIELD      = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1 1]],
      shieldGoodColor         = [[0.1 0.1 1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 900,
      shieldPowerRegen        = 11,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 80,
      shieldRepulser          = false,
      shieldStartingPower     = 900,
      smartShield             = true,
      visibleShield           = false,
      visibleShieldRepulse    = false,
      weaponType              = [[Shield]],
    },

  },

  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[conbot_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
