return { planefighter = {
  unitname               = [[planefighter]],
  name                   = [[Swift]],
  description            = [[Multi-role Fighter]],
  brakerate              = 0.4,
  buildCostMetal         = 150,
  buildPic               = [[planefighter.png]],
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[FIXEDWING]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 5]],
  collisionVolumeScales  = [[30 14 50]],
  collisionVolumeType    = [[ellipsoid]],
  selectionVolumeOffsets = [[0 0 10]],
  selectionVolumeScales  = [[50 50 70]],
  selectionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],
  crashDrag              = 0.02,
  cruiseAlt              = 200,

  customParams           = {
    bait_level_default = 0,

    specialreloadtime = [[850]],
    specialreload_userate = [[1]],
    boost_speed_mult = 5,
    boost_accel_mult = 6,
    boost_duration = 30, -- frames

    fighter_pullup_dist = 400,

    midposoffset   = [[0 3 0]],
    modelradius    = [[10]],
    refuelturnradius = [[80]],
    okp_damage = 130,

    outline_x = 85,
    outline_y = 85,
    outline_yoff = 16,
  },

  explodeAs              = [[GUNSHIPEX]],
  fireState              = 2,
  floater                = true,
  footprintX             = 2,
  footprintZ             = 2,
  frontToSpeed           = 0,
  iconType               = [[fighter]],
  maneuverleashlength    = [[1280]],
  maxAcc                 = 0.5,
  maxDamage              = 300,
  maxRudder              = 0.007,
  maxVelocity            = 13,
  mygravity              = 1,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
  objectName             = [[fighter.s3o]],
  script                 = [[planefighter.lua]],
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:MUZZLE_ORANGE]],
      [[custom:FF_PUFF]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
      [[custom:FLAMER]],
    },

  },
  sightDistance          = 520,
  speedToFront           = 0,
  turnRadius             = 150,
  turnRate               = 839,

  weapons                = {

    {
      def                = [[SWIFT_GUN]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 60,
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      badTargetCategory  = [[LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },


    {
      def                = [[MISSILE]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs             = {

    SWIFT_GUN  = {
      name                    = [[Mini Laser Blaster]],
      areaOfEffect            = 8,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        light_camera_height = 1500,
        light_ground_height = 120,
        light_radius = 100,
      },

      damage                  = {
        default = 7.1,
      },

      duration                = 0.012,
      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      range                   = 667,
      reloadtime              = 0.2,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/small_laser_fire3]],
      soundTrigger            = true,
      sweepfire               = false,
      thickness               = 2.85043856274785,
      tolerance               = 2000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2000,
    },


    MISSILE = {
      name                    = [[Guided Missiles]],
      areaOfEffect            = 48,
      avoidFriendly           = true,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 6,

      customParams              = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        light_color = [[0.5 0.6 0.6]],
      },

      damage                  = {
        default = 13.5,
        planes  = 135,
      },

      explosionGenerator      = [[custom:WEAPEXP_PUFF]],
      fireStarter             = 70,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[wep_m_fury.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 530,
      reloadtime              = 5.2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 200,
      texture1                = [[flarescale01]],
      texture2                = [[AAsmoketrail]],
      tolerance               = 22000,
      tracks                  = true,
      turnRate                = 40000,
      weaponAcceleration      = 550,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 750,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[fighter_dead.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
