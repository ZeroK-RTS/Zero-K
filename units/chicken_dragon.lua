return { chicken_dragon = {
  unitname               = [[chicken_dragon]],
  name                   = [[White Dragon]],
  description            = [[Prime Assault Chicken]],
  acceleration           = 6.0,
  activateWhenBuilt      = true,
  autoHeal               = 0,
  brakeRate              = 36.0,
  buildCostEnergy        = 0,
  buildCostMetal         = 0,
  builder                = false,
  buildPic               = [[chicken_dragon.png]],
  buildTime              = 10500,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  cantBeTransported      = true,
  category               = [[LAND SWIM]],
  collisionSphereScale   = 1,
  collisionVolumeOffsets = [[0 -5 -5]],
  collisionVolumeScales  = [[30 70 70]],
  collisionVolumeType    = [[box]],

  customParams           = {
    outline_x = 270,
    outline_y = 270,
    outline_yoff = 40,
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 5,
  footprintZ             = 5,
  iconType               = [[chickenminiq]],
  idleAutoHeal           = 20,
  idleTime               = 300,
  leaveTracks            = true,
  maxDamage              = 32000,
  maxSlope               = 36,
  maxVelocity            = 2.1,
  minCloakDistance       = 225,
  movementClass          = [[BHOVER5]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE FIXEDWING GUNSHIP STUPIDTARGET MINE]],
  objectName             = [[chicken_dragon.s3o]],
  power                  = 10500,
  reclaimable            = false,
  script                 = [[chicken_dragon.cob]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:blood_spray]],
      [[custom:blood_explode]],
      [[custom:dirt]],
    },

  },
  sightDistance          = 1200,
  sonarDistance          = 1200,
  trackOffset            = 18,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrack]],
  trackWidth             = 100,
  turninplace            = 0,
  turnRate               = 640,
  upright                = false,
  waterLine              = 42,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MELEE]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 150,
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
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
      def                = [[GOO]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },


    {
      def                = [[QUEENCRUSH]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    GOO        = {
      name                    = [[Blob]],
      areaOfEffect            = 160,
      burst                   = 8,
      burstrate               = 0.033,
      cegTag                  = [[queen_trail]],
      craterBoost             = 0,
      craterMult              = 0,
            
            customParams            = {
        light_radius = 0,
      },

      damage                  = {
        default = 500,
      },

      explosionGenerator      = [[custom:large_green_goo]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      proximityPriority       = -4,
      range                   = 700,
      reloadtime              = 8,
      rgbColor                = [[0.2 0.6 0]],
      size                    = 5,
      sizeDecay               = 0,
      soundStart              = [[chickens/bigchickenroar]],
      sprayAngle              = 6100,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      waterWeapon             = true,
      weaponVelocity          = 600,
    },


    MELEE      = {
      name                    = [[Chicken Jaws]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 0,

      damage                  = {
        default = 1200,
        planes  = 1200,
      },

      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 0,
      impulseFactor           = 1,
      interceptedByShieldType = 0,
      range                   = 160,
      reloadtime              = 3,
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
      areaOfEffect            = 300,
      collideFriendly         = false,
      craterBoost             = 0.001,
      craterMult              = 0.002,

      damage                  = {
        default    = 10,
        chicken    = 0.001,

        planes     = 10,
      },

      edgeEffectiveness       = 1,
      explosionGenerator      = [[custom:NONE]],
      impulseBoost            = 300,
      impulseFactor           = 1,
      intensity               = 1,
      interceptedByShieldType = 1,
      range                   = 384,
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
      burst                   = 5,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        light_radius = 0,
      },

      damage                  = {
        default = 60,
        planes  = 60,
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
      range                   = 600,
      reloadtime              = 5,
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
