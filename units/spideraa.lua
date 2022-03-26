return { spideraa = {
  unitname               = [[spideraa]],
  name                   = [[Tarantula]],
  description            = [[Anti-Air Spider]],
  acceleration           = 0.66,
  brakeRate              = 3.96,
  buildCostMetal         = 380,
  buildPic               = [[spideraa.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    cus_noflashlight = 1,
    okp_damage = 250.1,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spideraa]],
  leaveTracks            = true,
  maxDamage              = 1200,
  maxSlope               = 72,
  maxVelocity            = 2.3,
  maxWaterDepth          = 22,
  movementClass          = [[TKBOT3]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[tarantula.s3o]],
  script                 = [[spideraa.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 55,
  turnRate               = 2040,

  weapons                = {

    {
      def                = [[AA]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    AA = {
      name                    = [[Missiles]],
      areaOfEffect            = 48,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

      customParams              = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        light_color = [[0.58 0.7 0.7]],
      },

      damage                  = {
        default = 20,
        planes  = 260,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 5,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 1000,
      reloadtime              = 1.9,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 400,
      texture1                = [[flarescale01]],
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 82000,
      turret                  = true,
      weaponAcceleration      = 200,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      collisionVolumeOffsets = [[0 -5 0]],
      collisionVolumeScales  = [[40 30 40]],
      collisionVolumeType    = [[ellipsoid]],
      object           = [[tarantula_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3a.s3o]],
    },

  },

} }
