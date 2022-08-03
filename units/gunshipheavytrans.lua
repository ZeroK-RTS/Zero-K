return { gunshipheavytrans = {
  unitname               = [[gunshipheavytrans]],
  name                   = [[Hercules]],
  description            = [[Armed Heavy Air Transport]],
  acceleration           = 0.2,
  airStrafe              = 0,
  brakeRate              = 0.248,
  buildCostMetal         = 750,
  builder                = false,
  buildPic               = [[gunshipheavytrans.png]],
  canFly                 = true,
  canGuard               = true,
  canload                = [[1]],
  canMove                = true,
  canPatrol              = true,
  canSubmerge            = false,
  category               = [[GUNSHIP]],
  collide                = false,
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[60 25 100]],
  collisionVolumeType    = [[Box]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[55 25 90]],
  selectionVolumeType    = [[Box]],
  corpse                 = [[DEAD]],
  cruiseAlt              = 250,

  customParams           = {
    midposoffset   = [[0 0 0]],
    aimposoffset   = [[0 10 0]],
    modelradius    = [[15]],
    transport_speed_light   = [[1]],
    transport_speed_medium  = [[0.75]],
    transport_speed_heavy   = [[0.5]],

    outline_x = 145,
    outline_y = 145,
    outline_yoff = 17.5,
  },

  explodeAs              = [[GUNSHIPEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  hoverAttack            = true,
  iconType               = [[heavygunshiptransport]],
  maneuverleashlength    = [[1280]],
  maxDamage              = 1800,
  maxVelocity            = 9,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[largeTransport.s3o]],
  script                 = [[gunshipheavytrans.lua]],
  releaseHeld            = true,
  selfDestructAs         = [[GUNSHIPEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:VINDIMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:BEAMWEAPON_MUZZLE_RED]],
    },

  },
  sightDistance          = 660,
  transportCapacity      = 1,
  transportSize          = 25,
  turninplace            = 0,
  turnRate               = 420,
  upright                = true,
  verticalSpeed          = 30,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      mainDir            = [[-1 -1 1]],
      maxAngleDif        = 200,
    },


    {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      mainDir            = [[1 -1 1]],
      maxAngleDif        = 200,
    },
    
    
    {
      def                = [[AALASER]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
      mainDir            = [[0 -1 1]],
      maxAngleDif        = 160,
    },

  },


  weaponDefs             = {

    LASER = {
      name                    = [[Light Laser Blaster]],
      areaOfEffect            = 8,
      avoidFeature            = false,
      collideFriendly         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        combatrange = 60,
        light_camera_height = 1200,
        light_radius = 160,
      },
      
      damage                  = {
        default = 10,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_RED]],
      fireStarter             = 50,
      impactOnly              = true,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 320,
      reloadtime              = 0.2,
      rgbColor                = [[1 0 0]],
      soundHit                = [[weapon/laser/lasercannon_hit]],
      soundStart              = [[weapon/laser/lasercannon_fire]],
      soundTrigger            = true,
      thickness               = 2.4,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 2400,
    },
    
    AALASER  = {
      name                    = [[Anti-Air Laser]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamTime                = 1/30,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 1,
      
      customParams        = {
        combatrange = 100,
      },

      damage                  = {
        default = 2,
        planes  = 20,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 450,
      reloadtime              = 0.4,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.3,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },
  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      collisionVolumeScales  = [[40 40 80]],
      collisionVolumeType    = [[CylZ]],
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[heavytrans_d.dae]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
