return { shipriot = {
  unitname               = [[shipriot]],
  name                   = [[Corsair]],
  description            = [[Raider/Riot Corvette]],
  acceleration           = 0.25,
  activateWhenBuilt      = true,
  brakeRate              = 1.7,
  buildCostMetal         = 240,
  builder                = false,
  buildPic               = [[shipriot.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[32 32 102]],
  collisionVolumeType    = [[cylZ]],
  corpse                 = [[DEAD]],

  customParams           = {
    turnatfullspeed = [[1]],
    --extradrawrange = 420,
  },

  explodeAs              = [[SMALL_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[shipriot]],
  maxDamage              = 1350,
  maxVelocity            = 2.7,
  minWaterDepth          = 10,
  movementClass          = [[BOAT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName             = [[shipriot.s3o]],
  script                 = [[shipriot.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],
  sightDistance          = 500,
  
  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
    },

  },
  
  sonarDistance          = 500,
  turninplace            = 0,
  turnRate               = 800,
  waterline              = 0,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[SHOTGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SHOTGUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

      SHOTGUN = {
      name                    = [[Shotgun]],
      areaOfEffect            = 48,
      burst                    = 3,
      burstRate                = 0.033,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_camera_height = 2000,
        light_color = [[0.3 0.3 0.05]],
        light_radius = 120,
      },
      
      damage                  = {
          default = 26,
          planes  = 26,
      },
      
      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
      fireStarter             = 50,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      projectiles                = 3,
      range                   = 293,
      reloadtime              = 2.0,
      rgbColor                = [[1 1 0]],
      soundHit                = [[impacts/shotgun_impactv5]],
      soundStart              = [[weapon/cannon/cannon_fire4]],
      soundStartVolume        = 0.05,
      soundTrigger            = true,
      sprayangle                = 1500,
      thickness               = 2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
   },
    
    
  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[shipriot_dead.s3o]],
    },
    
    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
