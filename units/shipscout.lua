return { shipscout = {
  unitname               = [[shipscout]],
  name                   = [[Cutter]],
  description            = [[Scout Ship (Disarming)]],
  acceleration           = 0.6,
  activateWhenBuilt      = true,
  brakeRate              = 0.57,
  buildCostMetal         = 65,
  builder                = false,
  buildPic               = [[shipscout.png]],
  canMove                = true,
  category               = [[SHIP SMALL TOOFAST]],
  collisionVolumeOffsets = [[0 5 0]],
  collisionVolumeScales  = [[25 25 60]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[12]],
    turnatfullspeed = [[1]],
    bait_level_default = 0,
  },

  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[shipscout]],
  maxDamage              = 260,
  maxVelocity            = 5.2,
  movementClass          = [[BOAT3]],
  noChaseCategory        = [[TERRAFORM SUB]],
  objectName             = [[shipscout.s3o]],
  script                 = [[shipscout.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes                      = {
  
    explosiongenerators = {
      [[custom:PULVMUZZLE]],
    },

  },
  
  sightDistance          = 800,
  sonarDistance          = 800,
  turninplace            = 0,
  turnRate               = 1184,
  waterline              = 2,

  weapons                = {

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP LAND SINK TURRET SHIP SWIM FLOAT HOVER]],
    },

  },

  weaponDefs             = {

    MISSILE   = {
      name                    = [[Light Disarm Missile]],
      areaOfEffect            = 8,
      --burst                 = 2,
      --burstRate             = 0.4,
      cegTag                  = [[yellowdisarmtrail]],
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams        = {
        disarmDamageMult = 5.0,
        disarmDamageOnly = 0,
        disarmTimer      = 3, -- seconds
        
        light_color = [[1 1 1]],
      },
      
      damage                  = {
        default = 35,
      },

      explosionGenerator      = [[custom:mixed_white_lightning_bomb_small]],
      fireStarter             = 70,
      fixedlauncher           = true,
      flightTime              = 4,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_armpt.s3o]],
      range                   = 265,
      reloadtime              = 2.0,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/small_lightning_missile]],
      soundStart              = [[weapon/missile/missile_fire7]],
      startVelocity           = 100,
      texture2                = [[lightsmoketrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 60000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 800,
    },

  },

  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[shipscout_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
