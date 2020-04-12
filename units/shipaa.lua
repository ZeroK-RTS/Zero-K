return { shipaa = {
  unitname               = [[shipaa]],

  name                   = [[Zephyr]],
  description            = [[Anti-Air Frigate]],
  acceleration           = 0.249,
  activateWhenBuilt   = true,
  brakeRate              = 0.808,

  buildCostMetal         = 400,
  builder                = false,

  buildPic               = [[shipaa.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 4]],
  collisionVolumeScales  = [[32 32 128]],
  collisionVolumeType    = [[CylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[45]],
    turnatfullspeed = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[shipaa]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  losEmitHeight          = 40,
  maxDamage              = 1900,
  maxVelocity            = 2.84,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT4]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SATELLITE SWIM FLOAT SUB HOVER]],
  objectName             = [[shipaa.s3o]],
  radarDistance          = 1000,
  script                 = [[shipaa.lua]],
  selfDestructAs         = [[BIG_UNITEX]],
  sightDistance          = 660,
  sonarDistance          = 660,
  turninplace            = 0,
  turnRate               = 486,
  waterline              = 4,
  workerTime             = 0,

  weapons                = {

    [1] = {
      def                = [[AALASER]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },


    [2] = {
      def                = [[AALASER]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs             = {

    AALASER       = {
      name                    = [[Anti-Air Laser]],
      accuracy                = 128,
      areaOfEffect            = 8,
      canattackground         = false,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        isaa = [[1]],
        
        light_camera_height = 2600,
        light_radius = 220,
      },

      damage                  = {
        default = 1.3,
        planes  = 12.7,
        subs    = 1.5,
      },

      duration                = 0.02,
      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:flash1orange]],
      fireStarter             = 10,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      lodDistance             = 10000,
      proximityPriority       = 4,
      range                   = 1040,
      reloadtime              = 0.1,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      thickness               = 2.25346954716499,
      tolerance               = 1000,
      turnRate                = 48000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1500,
    },


    BOGUS_MISSILE = {
      name                    = [[Missiles]],
      areaOfEffect            = 48,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 0,
      },

      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      metalpershot            = 0,
      range                   = 800,
      reloadtime              = 0.5,
      startVelocity           = 450,
      tolerance               = 9000,
      turnRate                = 33000,
      turret                  = true,
      weaponAcceleration      = 101,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },


    FLAK          = {
      name                    = [[Flak Cannon]],
      accuracy                = 1000,
      areaOfEffect            = 64,
      burnblow                = true,
      canattackground         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 10,
        planes  = 100,
        subs    = 2.5,
      },

      edgeEffectiveness       = 0.85,
      explosionGenerator      = [[custom:FLAK_HIT_24]],
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 900,
      reloadtime              = 0.4,
      soundHit                = [[weapon/flak_hit]],
      soundStart              = [[weapon/flak_fire]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 2000,
    },

  },


  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[shipaa_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
