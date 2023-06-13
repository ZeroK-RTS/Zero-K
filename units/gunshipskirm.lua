return { gunshipskirm = {
  unitname               = [[gunshipskirm]],
  name                   = [[Harpy]],
  description            = [[Multi-Role Support Gunship]],
  acceleration           = 0.152,
  brakeRate              = 0.145,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[gunshipskirm.png]],
  canFly                 = true,
  canMove                = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = true,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[42 16 42]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 140,

  customParams           = {
    bait_level_default = 0,
    airstrafecontrol = [[1]],
    modelradius    = [[16]],
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  hoverAttack            = true,
  iconType               = [[gunshipskirm]],
  maxDamage              = 1200,
  maxVelocity            = 3.8,
  noChaseCategory        = [[TERRAFORM SUB]],
  objectName             = [[rapier.s3o]],
  script                 = [[gunshipskirm.lua]],
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:rapiermuzzle]],
    },

  },

  sightDistance          = 550,
  turnRate               = 594,

  weapons                = {

    {
      def                = [[VTOL_ROCKET]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    VTOL_ROCKET = {
      name                    = [[Disruptor Missiles]],
      areaOfEffect            = 16,
      avoidFeature            = false,
      burnblow                = true,
      cegTag                  = [[missiletrailpurple]],
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        burst = Shared.BURST_RELIABLE,

        timeslow_damagefactor = 3,
        
        light_camera_height = 2500,
        light_color = [[1.3 0.5 1.6]],
        light_radius = 220,
      },

      damage                  = {
        default = 220.1,
      },

      explosionGenerator      = [[custom:disruptor_missile_hit]],
      fireStarter             = 70,
      flightTime              = 2.2,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_maverick.s3o]],
      range                   = 360,
      reloadtime              = 5,
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med11]],
      soundStart              = [[weapon/missile/rocket_fire]],
      soundTrigger            = true,
      startVelocity           = 250,
      texture2                = [[purpletrail]],
      tolerance               = 32767,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = false,
      weaponAcceleration      = 250,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 1000,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[rapier_d.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
