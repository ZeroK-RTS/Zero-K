return { amphimpulse = {
  unitname               = [[amphimpulse]],
  name                   = [[Archer]],
  description            = [[Amphibious Raider/Riot Bot]],
  acceleration           = 0.6,
  activateWhenBuilt      = true,
  brakeRate              = 2.4,
  buildCostMetal         = 180,
  buildPic               = [[amphimpulse.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 40,
    amph_submerged_at = 40,
    sink_on_emp    = 1,
    floattoggle    = [[1]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 36,
  maxVelocity            = 2.5,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP HOVER SHIP SWIM SUB LAND FLOAT SINK TURRET]],
  objectName             = [[amphraider2.s3o]],
  script                 = [[amphimpulse.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:watercannon_muzzle]],
    },
  },

  sightDistance          = 500,
  sonarDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1200,
  upright                = true,

  weapons                = {
    {
      def                = [[WATERCANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[FAKE_WATERCANNON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    WATERCANNON = {
      name                    = [[Water Cutter]],
      areaOfEffect            = 128,
      beamTime                = 1/30,
      beamTtl                 = 10,
      beamDecay               = 0.80,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        impulse = [[460]],
        impulsemaxdepth = [[20]],
        impulsedepthmult = [[0.5]],
        normaldamage = [[1]],

        --stats_damage = 10.4,
        --stats_hide_damage = 1, -- continuous laser
        --stats_hide_reload = 1,
        
        light_camera_height = 1500,
        light_color = [[0 0.03 0.07]],
        light_radius = 100,
      },

      damage                  = {
        default = 24,
        subs    = 1,
      },

      explosionGenerator      = [[custom:watercannon_impact]],
      impactOnly              = false,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 0,
      minIntensity            = 1,
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 275,
      reloadtime              = 20/30,
      rgbColor                = [[0.5 0.5 0.65]],
      scrollSpeed             = 10,
      soundStart              = [[weapon/watershort]],
      soundStartVolume        = 5,
      sweepfire               = false,
      texture1                = [[corelaser]],
      texture2                = [[wake]],
      texture3                = [[wake]],
      texture4                = [[wake]],
      thickness               = 7,
      tileLength              = 100,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  
    FAKE_WATERCANNON = {
      name                    = [[Fake Water Cutter]],
      areaOfEffect            = 128,
      beamTime                = 1/30,
      beamTtl                 = 10,
      beamDecay               = 0.80,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        impulse = [[30]],
        normaldamage = [[1]],
      },

      damage                  = {
        default = 1.3,
        subs    = 1,
      },

      explosionGenerator      = [[custom:watercannon_impact]],
      impactOnly              = false,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 0,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 280,
      reloadtime              = 0.1,
      rgbColor                = [[0.2 0.2 0.3]],
      scrollSpeed             = 10,
--      soundStart              = [[weapon/laser/laser_burn8]],
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[corelaser]],
      texture2                = [[wake]],
      texture3                = [[wake]],
      texture4                = [[wake]],
      thickness               = 7,
      tileLength              = 100,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },
  
  },

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[amphraider2_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
