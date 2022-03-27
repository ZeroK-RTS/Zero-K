return { vehaa = {
  unitname               = [[vehaa]],
  name                   = [[Crasher]],
  description            = [[Fast Anti-Air Rover]],
  acceleration           = 0.36,
  brakeRate              = 1.8,
  buildCostMetal         = 220,
  builder                = false,
  buildPic               = [[vehaa.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[18 20 40]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    modelradius    = [[9]],
    okp_damage = 280.1,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[vehicleaa]],
  leaveTracks            = true,
  maneuverleashlength    = [[30]],
  maxDamage              = 900,
  maxSlope               = 18,
  maxVelocity            = 3.7,
  maxWaterDepth          = 22,
  movementClass          = [[TANK3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[vehaa.s3o]],
  script                 = [[vehaa.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  
  sfxtypes               = {

  explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },
  sightDistance          = 660,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 1044,
  upright                = false,
  workerTime             = 0,

  weapons                       = {

    {
      def                = [[MISSILE]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs                    = {

    MISSILE = {
      name                    = [[Heavy Missile]],
      areaOfEffect            = 32,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        light_color = [[0.5 0.6 0.6]],
      },

      damage                  = {
        default = 29.01,
        planes  = 290.1,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fixedlauncher           = true,
      fireStarter             = 70,
      flightTime              = 3,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_phoenix.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 730,
      reloadtime              = 4,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/sabot_hit]],
      soundStart              = [[weapon/missile/missile_fire]],
      startVelocity           = 300,
      texture1                = [[flarescale01]],
      texture2                = [[AAsmoketrail]],
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 250,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 700,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[32 40 52]],
      collisionVolumeType    = [[box]],
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[vehaa_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
