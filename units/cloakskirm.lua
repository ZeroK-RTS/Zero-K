return { cloakskirm = {
  unitname               = [[cloakskirm]],
  name                   = [[Ronin]],
  description            = [[Skirmisher Bot (Direct-Fire)]],
  acceleration           = 0.9,
  brakeRate              = 1.2,
  buildCostMetal         = 90,
  buildPic               = [[cloakskirm.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -5 0]],
  collisionVolumeScales  = [[26 39 26]],
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    aim_lookahead  = 60,
    modelradius    = [[18]],
    midposoffset   = [[0 6 0]],
    reload_move_penalty = 0.8,
    cus_noflashlight = 1,
    bait_level_default = 0,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotskirm]],
  leaveTracks            = true,
  maxDamage              = 380,
  maxSlope               = 36,
  maxVelocity            = 2.3,
  maxWaterDepth          = 20,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB DRONE]],
  objectName             = [[sphererock.s3o]],
  script                 = "cloakskirm.lua",
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rockomuzzle]],
    },

  },

  sightDistance          = 523,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.8,
  trackType              = [[ComTrack]],
  trackWidth             = 16,
  turnRate               = 2244,
  upright                = true,

  weapons                = {

    {
      def                = [[BOT_ROCKET]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    BOT_ROCKET = {
      name                    = [[Rocket]],
      areaOfEffect            = 48,
      burnblow                = true,
      cegTag                  = [[rocket_trail_bar]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        reaim_time = 1, -- Keep aiming at target to prevent sideways gun, which can lead to teamkill.
        burst = Shared.BURST_RELIABLE,

        light_camera_height = 1600,
        light_color = [[0.90 0.65 0.30]],
        light_radius = 250,
        reload_move_mod_time = 3,
      },

      damage                  = {
        default = 180,
      },

      fireStarter             = 70,
      flightTime              = 2.45,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_ajax.s3o]],
      noSelfDamage            = true,
      range                   = 455,
      reloadtime              = 3.5,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startVelocity           = 200,
      tracks                  = false,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 200,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[rocko_d.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
