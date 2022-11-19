return { striderbantha = {
  unitname               = [[striderbantha]],
  name                   = [[Paladin]],
  description            = [[Ranged Support Strider]],
  acceleration           = 0.314,
  autoheal               = 20,
  brakeRate              = 1.327,
  buildCostMetal         = 10000,
  builder                = false,
  buildPic               = [[striderbantha.png]],
  canGuard               = true,
  canManualFire          = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 -2]],
  collisionVolumeScales  = [[60 80 60]],
  collisionVolumeType    = [[CylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default    = 0,
    extradrawrange        = 465,
    aimposoffset          = [[0 -8 0]],
    midposoffset          = [[0 -8 0]],
    modelradius           = [[17]],
    decloak_footprint     = 5,
  },

  explodeAs              = [[ATOMIC_BLAST]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3generic]],
  leaveTracks            = true,
  losEmitHeight          = 60,
  maxDamage              = 32000,
  maxSlope               = 36,
  maxVelocity            = 1.45,
  maxWaterDepth          = 22,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING SATELLITE SUB DRONE]],
  objectName             = [[Bantha.s3o]],
  selfDestructAs         = [[ATOMIC_BLAST]],
  script                 = [[striderbantha.lua]],
  
  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
      [[custom:opticblast_charge]]
    },

  },
  sightDistance          = 720,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.5,
  trackType              = [[ComTrack]],
  trackWidth             = 42,
  turnRate               = 1166,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[ATA]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP FIXEDWING HOVER]],
    },


    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[EMP_MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },


  weaponDefs             = {

    ATA            = {
      name                    = [[Tachyon Accelerator]],
      areaOfEffect            = 20,
      beamTime                = 1,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        burst = Shared.BURST_RELIABLE,

        light_color = [[1.25 0.8 1.75]],
        light_radius = 320,
        reaim_time = 1,
      },

      damage                  = {
        default = 3000.1,
        planes  = 3000.1,
      },

      explosionGenerator      = [[custom:ataalaser]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 16.94,
      leadLimit               = 18,
      minIntensity            = 1,
      range                   = 950,
      reloadtime              = 10,
      rgbColor                = [[0.25 0 1]],
      soundStart              = [[weapon/laser/heavy_laser6]],
      soundStartVolume        = 15,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 16.9,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 1500,
    },
    
    EMP_MISSILE = {
      name                    = [[EMP Missiles]],
      areaOfEffect            = 128,
      accuracy                = 512,
      avoidFeature            = false,
      avoidFriendly           = false,
      burst                   = 12,
      burstrate               = 0.167,
      cegTag                  = [[emptrail]],
      commandFire             = true,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        combatrange = 900,
        light_color = [[0.65 0.65 0.18]],
        light_radius = 380,
        reaim_time = 1,
      },

      damage                  = {
        default        = 1250,
      },

      dance                   = 20,
      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:YELLOW_LIGHTNINGPLOSION]],
      fireStarter             = 100,
      fixedlauncher           = true,
      flightTime              = 12,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 2,
      model                   = [[banthamissile.s3o]],
      noSelfDamage            = true,
      paralyzer               = true,
      paralyzeTime            = 20,
      range                   = 1200,
      reloadtime              = 30,
      smokeTrail              = false,
      soundHit                = [[weapon/missile/vlaunch_emp_hit]],
      soundStart              = [[weapon/missile/missile_launch_high]],
      soundStartVolume        = 5,
      startVelocity           = 100,
      tracks                  = true,
      trajectoryHeight        = 1,
      tolerance               = 512,
      turnRate                = 8000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 250,
      wobble                  = 18000,
    },
    
    LIGHTNING      = {
      name                    = [[Lightning Cannon]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = 960,
        
        light_camera_height = 2200,
        light_color = [[0.85 0.85 1.2]],
        light_radius = 200,
        reaim_time = 1,
      },

      damage                  = {
        default        = 320,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzeTime            = 1,
      range                   = 465,
      reloadtime              = 1,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/LightningBolt]],
      soundStartVolume        = 3.8,
      soundTrigger            = true,
      sprayAngle              = 800,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },
    
  },


  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[bantha_wreck.s3o]],
    },


    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4b.s3o]],
    },

  },

} }
