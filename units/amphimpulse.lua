return { amphimpulse = {
  unitname               = [[amphimpulse]],
  name                   = [[Archer]],
  description            = [[Amphibious Raider/Riot Bot]],
  acceleration           = 0.6,
  activateWhenBuilt      = true,
  brakeRate              = 2.4,
  buildCostMetal         = 200,
  buildPic               = [[amphimpulse.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 10,
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
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_l]],
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
      def                = [[SONIC]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      --mainDir            = [[0 -1 0]],
      --maxAngleDif        = 330,
    },
    {
      def                = [[FAKE_SONIC]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

    SONIC         = {
        name                    = [[Sonic Blaster]],
        areaOfEffect            = 128,
        avoidFeature            = true,
        avoidFriendly           = true,
        burnblow                = true,
        craterBoost             = 0,
        craterMult              = 0,

        customParams            = {
            --muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
            --miscEffectFire   = [[custom:RIOT_SHELL_L]],
            lups_explodelife = 1.5,
            lups_explodespeed = 0.8,
            light_radius = 200
        },

        damage                  = {
            default = 80.01,
        },
        
        cegTag                  = [[sonictrail]],
        cylinderTargeting       = 1,
        explosionGenerator      = [[custom:sonic_40]],
        edgeEffectiveness       = 0.5,
        fireStarter             = 150,
        impulseBoost            = 200,
        impulseFactor           = 0.5,
        interceptedByShieldType = 1,
        myGravity               = 0.01,
        noSelfDamage            = true,
        range                   = 260,
        reloadtime              = 0.66,
        size                    = 50,
        sizeDecay               = 0.2,
        soundStart              = [[weapon/sonicgun2]],
        soundHit                = [[weapon/sonicgun_hit]],
        soundStartVolume        = 6,
        soundHitVolume          = 10,
        stages                  = 1,
        texture1                = [[sonic_glow2]],
        texture2                = [[null]],
        texture3                = [[null]],
        rgbColor                = {0.2, 0.6, 0.8},
        turret                  = true,
        weaponType              = [[Cannon]],
        weaponVelocity          = 300,
        waterweapon             = true,
        duration                = 0.15,
    },
    FAKE_SONIC         = {
      name                    = [[Sonic Blaster]],
      areaOfEffect            = 128,
      avoidFeature            = true,
      avoidFriendly           = true,
      burnblow                = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
          bogus = 1,
          lups_explodelife = 1.5,
          lups_explodespeed = 0.8,
          light_radius = 200
      },

      damage                  = {
          default = 80,
      },
      
      cegTag                  = [[sonictrail]],
      cylinderTargeting       = 1,
      explosionGenerator      = [[custom:sonic_40]],
      edgeEffectiveness       = 0.5,
      fireStarter             = 150,
      impulseBoost            = 300,
      impulseFactor           = 0.5,
      interceptedByShieldType = 1,
      myGravity               = 0.01,
      noSelfDamage            = true,
      range                   = 260,
      reloadtime              = 0.5,
      size                    = 50,
      sizeDecay               = 0.2,
      soundStart              = [[weapon/sonicgun2]],
      soundHit                = [[weapon/sonicgun_hit]],
      soundStartVolume        = 6,
      soundHitVolume          = 10,
      stages                  = 1,
      texture1                = [[sonic_glow2]],
      texture2                = [[null]],
      texture3                = [[null]],
      rgbColor                = {0.2, 0.6, 0.8},
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 300,
      waterweapon             = true,
      duration                = 0.15,
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
