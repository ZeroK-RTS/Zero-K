return { gunshipaa = {
  unitname               = [[gunshipaa]],
  name                   = [[Trident]],
  description            = [[Anti-Air Gunship]],
  acceleration           = 0.18,
  airStrafe              = 0,
  bankingAllowed         = false,
  brakeRate              = 0.4,
  buildCostMetal         = 270,
  builder                = false,
  buildPic               = [[gunshipaa.png]],
  canFly                 = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[36 36 36]],
  collisionVolumeType    = [[ellipsoid]],
  collide                = true,
  corpse                 = [[DEAD]],
  cruiseAlt              = 110,

  customParams           = {
    bait_level_default = 0,
    modelradius    = [[18]],
    midposoffset   = [[0 15 0]],
    selection_velocity_heading = 1,
    okp_damage = 190.1,
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunshipaa]],
  maxDamage              = 900,
  maxVelocity            = 3.8,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[trifighter.s3o]],
  script                 = [[gunshipaa.lua]],
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rapiermuzzle]],
    },

  },
  sightDistance          = 660,
  turnRate               = 0,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[AA_MISSILE]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    AA_MISSILE = {
      name                    = [[Homing Missiles]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      canattackground         = false,
      cegTag                  = [[missiletrailblue]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargeting       = 1,

      customParams              = {
        burst = Shared.BURST_RELIABLE,

        isaa = [[1]],
        script_reload = [[10]],
        script_burst = [[3]],
        
        light_camera_height = 2500,
        light_radius = 200,
        light_color = [[0.5 0.6 0.6]],
      },

      damage                  = {
        default = 20.01,
        planes  = 200.1,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 3,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_fury_cent.s3o]], -- Model radius 150 for QuadField fix.
      noSelfDamage            = true,
      range                   = 750,
      reloadtime              = 1.2,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/rocket_hit]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 650,
      texture1                = [[flarescale01]],
      texture2                = [[AAsmoketrail]],
      texture3                = [[null]],
      tolerance               = 32767,
      tracks                  = true,
      turnRate                = 90000,
      turret                  = false,
      weaponAcceleration      = 550,
      weaponTimer             = 0.2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 700,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[trifighter_dead.s3o]],
    },

    
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
