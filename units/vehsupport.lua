return { vehsupport = {
  unitname               = [[vehsupport]],
  name                   = [[Fencer]],
  description            = [[Deployable Missile Rover (must stop to fire)]],
  acceleration           = 0.18,
  brakeRate              = 0.36,
  buildCostMetal         = 145,
  builder                = false,
  buildPic               = [[vehsupport.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[26 30 36]],
  collisionVolumeType    = [[box]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 45 45]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[13]],
    aimposoffset   = [[0 10 0]],
    chase_everything = [[1]], -- Does not get stupidtarget added to noChaseCats
    okp_damage = 35,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[vehiclesupport]],
  leaveTracks            = true,
  maxDamage              = 530,
  maxSlope               = 18,
  maxVelocity            = 2.8,
  maxWaterDepth          = 22,
  movementClass          = [[TANK3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[cormist_512.s3o]],
  script                 = [[vehsupport.lua]],
  pushResistant          = 0,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:SLASHMUZZLE]],
      [[custom:SLASHREARMUZZLE]],
    },

  },
  sightDistance          = 660,
  trackOffset            = -6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 34,
  turninplace            = 0,
  turnRate               = 672,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[CORTRUCK_MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    CORTRUCK_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 48,
      avoidFeature            = true,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 2000,
        light_radius = 200,
      },

      damage                  = {
        default = 40.01,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_frostshard.s3o]],
      range                   = 600,
      reloadtime              = 0.766,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med17]],
      soundStart              = [[weapon/missile/missile_fire11]],
      startVelocity           = 450,
      texture2                = [[lightsmoketrail]],
      tolerance               = 8000,
      tracks                  = true,
      turnRate                = 33000,
      turret                  = true,
      weaponAcceleration      = 109,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 545,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[cormist_dead_new.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
