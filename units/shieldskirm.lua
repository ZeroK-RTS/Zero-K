return { shieldskirm = {
  unitname               = [[shieldskirm]],
  name                   = [[Rogue]],
  description            = [[Skirmisher Bot (Indirect Fire)]],
  acceleration           = 0.75,
  brakeRate              = 1.2,
  buildCostMetal         = 120,
  buildPic               = [[shieldskirm.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -8 0]],
  collisionVolumeScales  = [[28 42 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    aimposoffset   = [[0 5 0]],
    midposoffset   = [[0 5 0]],
    modelradius    = [[14]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[walkerskirm]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 580,
  maxSlope               = 36,
  maxVelocity            = 1.95,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SUB]],
  objectName             = [[storm.s3o]],
  script                 = [[shieldskirm.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  sightDistance          = 583,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2200,
  upright                = true,

  weapons                = {

    {
      def                = [[STORM_ROCKET]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs             = {

    STORM_ROCKET = {
      name                    = [[Heavy Rocket]],
      areaOfEffect            = 75,
      cegTag                  = [[rocket_trail_bar_flameboosted]],
      craterBoost             = 1,
      craterMult              = 2,

      customParams        = {
        burst = Shared.BURST_RELIABLE,

        light_camera_height = 1800,
      },
      
      damage                  = {
        default = 350,
        planes  = 350,
        subs    = 17.5,
      },

      fireStarter             = 70,
      flightTime              = 3.5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      predictBoost            = 0.75,
      range                   = 530,
      reloadtime              = 7,
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med4]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/missile2_fire_bass]],
      soundStartVolume        = 7,
      startVelocity           = 192,
      tracks                  = false,
      trajectoryHeight        = 0.6,
      turnrate                = 1000,
      turret                  = true,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 192,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[storm_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
