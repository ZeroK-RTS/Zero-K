return { chickenlandqueen = {
  unitname               = [[chickenlandqueen]],
  name                   = [[Chicken Queen]],
  description            = [[Clucking Hell!]],
  acceleration           = 3.0,
  activateWhenBuilt      = true,
  autoHeal               = 0,
  brakeRate              = 18.0,
  buildCostEnergy        = 0,
  buildCostMetal         = 0,
  builder                = false,
  buildPic               = [[chickenflyerqueen.png]],
  buildTime              = 40000,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  cantBeTransported      = true,
  category               = [[LAND]],
  collisionSphereScale   = 1,
  collisionVolumeOffsets = [[0 0 15]],
  collisionVolumeScales  = [[46 110 120]],
  collisionVolumeType    = [[box]],

  customParams           = {
    selection_scale       = 2,

    outline_x = 400,
    outline_y = 400,
    outline_yoff = 90,
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[chickenq]],
  idleAutoHeal           = 20,
  idleTime               = 300,
  leaveTracks            = true,
  maxDamage              = 200000,
  maxVelocity            = 2.5,
  minCloakDistance       = 250,
  movementClass          = [[AKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP STUPIDTARGET MINE]],
  objectName             = [[chickenflyerqueen.s3o]],
  power                  = 65536,
  reclaimable            = false,
  script                 = [[chickenlandqueen.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance          = 2048,
  sonarDistance          = 2048,
  trackOffset            = 18,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrack]],
  trackWidth             = 100,
  turnRate               = 480,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MELEE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 150,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[FIREGOO]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 150,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[SPORES]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[QUEENCRUSH]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },
    
    {
      def                = [[DODOBOMB]],
      onlyTargetCategory = [[NONE]],
    },


    {
      def                = [[BASILISKBOMB]],
      onlyTargetCategory = [[NONE]],
    },


    {
      def                = [[TIAMATBOMB]],
      onlyTargetCategory = [[NONE]],
    },
  },


  weaponDefs             = {
  
    BASILISKBOMB = {
      name                    = [[Basilisk Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      
      customparams            = {
          spawns_name = "chickenc",
          spawns_expire = 0,
      },

      damage                  = {
        default = 180,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chickenc.s3o]],
      range                   = 500,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },


    DODOBOMB     = {
      name                    = [[Dodo Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 1,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customparams            = {
          spawns_name = "chicken_dodo",
          spawns_expire = 30,
      },

      damage                  = {
        default = 1,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chicken_dodobomb.s3o]],
      range                   = 500,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },

    TIAMATBOMB   = {
      name                    = [[Tiamat Bomb]],
      accuracy                = 60000,
      areaOfEffect            = 72,
      avoidFeature            = false,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      
      customparams            = {
          spawns_name = "chicken_tiamat",
          spawns_expire = 0,
      },

      damage                  = {
        default = 350,
      },

      explosionGenerator      = [[custom:none]],
      fireStarter             = 70,
      flightTime              = 0,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      model                   = [[chickenbroodqueen.s3o]],
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 10,
      smokeTrail              = false,
      startVelocity           = 200,
      tolerance               = 8000,
      tracks                  = false,
      turnRate                = 4000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 200,
      weaponType              = [[AircraftBomb]],
      weaponVelocity          = 200,
    },
    
    FIREGOO    = {
      name                    = [[Napalm Goo]],
      areaOfEffect            = 256,
      burst                   = 8,
      burstrate               = 0.033,
      cegTag                  = [[queen_trail_fire]],
      
      customParams            = {
    light_radius = 500,
      },
      
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 400,
        planes  = 400,
      },

      explosionGenerator      = [[custom:napalm_koda]],
      firestarter             = 400,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      proximityPriority       = -4,
      range                   = 1200,
      reloadtime              = 6,
      rgbColor                = [[0.8 0.4 0]],
      size                    = 8,
      sizeDecay               = 0,
      soundHit                = [[weapon/burn_mixed]],
      soundStart              = [[chickens/bigchickenroar]],
      sprayAngle              = 6100,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },


    MELEE      = {
      name                    = [[Chicken Claws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 1000,
        planes  = 1000,
      },

      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 0,
      noSelfDamage            = true,
      range                   = 200,
      reloadtime              = 1,
      size                    = 0,
      soundStart              = [[chickens/bigchickenbreath]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 600,
    },


    QUEENCRUSH = {
      name                    = [[Chicken Kick]],
      areaOfEffect            = 400,
      collideFriendly         = false,
      craterBoost             = 0.001,
      craterMult              = 0.002,

      customParams           = {
    lups_noshockwave = "1",
      },
      
      
      damage                  = {
        default    = 10,
        chicken    = 0.001,
        planes     = 10,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 500,
      impulseFactor           = 1,
      intensity               = 1,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 512,
      reloadtime              = 1,
      rgbColor                = [[1 1 1]],
      thickness               = 1,
      tolerance               = 100,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 0.8,
    },


    SPORES     = {
      name                    = [[Spores]],
      areaOfEffect            = 24,
      avoidFriendly           = false,
      burst                   = 8,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },

      damage                  = {
        default = 75,
        planes  = [[150]],
      },

      dance                   = 60,
      explosionGenerator      = [[custom:NONE]],
      fireStarter             = 0,
      flightTime              = 5,
      groundbounce            = 1,
      heightmod               = 0.5,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      metalpershot            = 0,
      model                   = [[chickeneggpink.s3o]],
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 4,
      smokeTrail              = true,
      startVelocity           = 100,
      texture1                = [[]],
      texture2                = [[sporetrail]],
      tolerance               = 10000,
      tracks                  = true,
      turnRate                = 24000,
      turret                  = true,
      waterweapon             = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 500,
      wobble                  = 32000,
    },

  },

} }
