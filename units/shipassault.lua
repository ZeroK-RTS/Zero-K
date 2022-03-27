return { shipassault = {
  unitname               = [[shipassault]],
  name                   = [[Siren]],
  description            = [[Riot/Assault Destroyer (Anti-Sub)]],
  acceleration           = 0.46,
  activateWhenBuilt      = true,
  brakeRate              = 0.6,
  buildCostMetal         = 600,
  builder                = false,
  buildPic               = [[shipassault.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 6 0]],
  collisionVolumeScales  = [[55 55 110]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],
  --Core_color.dds Core_other.dds
  customParams           = {
    bait_level_default = 0,
    modelradius    = [[55]],
    turnatfullspeed = [[1]],
    extradrawrange = 800,

    outline_x = 160,
    outline_y = 160,
    outline_yoff = 25,
  },

  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[shipassault]],
  losEmitHeight          = 25,
  maxDamage              = 5200,
  maxVelocity            = 2.0,
  minWaterDepth          = 5,
  movementClass          = [[BOAT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB SINK TURRET]],
  objectName             = [[shipassault.s3o]],
  script                 = [[shipassault.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:sonicfire_80]],
      [[custom:emg_shells_l]],
    },

  },

  sightDistance          = 440,
  sonarDistance          = 440,
  turninplace            = 0,
  turnRate               = 384,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[SONIC]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
      mainDir            = [[0 -1 0]],
      maxAngleDif        = 240,
    },

    {
      def                = [[MISSILE]],
      badTargetCategory  = [[SWIM LAND SHIP HOVER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {

    SONIC         = {
        name                    = [[Sonic Blaster]],
        areaOfEffect            = 190,
        avoidFeature            = true,
        avoidFriendly           = true,
        burnblow                = true,
        craterBoost             = 0,
        craterMult              = 0,

        customParams            = {
            force_ignore_ground = [[1]],
            slot = [[5]],
            muzzleEffectFire = [[custom:HEAVY_CANNON_MUZZLE]],
            miscEffectFire   = [[custom:RIOT_SHELL_L]],
            lups_explodelife = 1.5,
            lups_explodespeed = 0.8,
            light_radius = 240,
        },

        damage                  = {
            default = 280.01,
        },
        
        cegTag                  = [[sonictrail]],
        cylinderTargeting       = 5.0,
        explosionGenerator      = [[custom:sonic_80]],
        edgeEffectiveness       = 0.5,
        fireStarter             = 150,
        impulseBoost            = 300,
        impulseFactor           = 0.5,
        interceptedByShieldType = 1,
        myGravity               = 0.01,
        noSelfDamage            = true,
        range                   = 270,
        reloadtime              = 1.7,
        size                    = 64,
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
        weaponVelocity          = 700,
        waterweapon             = true,
        duration                = 0.15,
    },
    
    MISSILE      = {
      name                    = [[Destroyer Missiles]],
      areaOfEffect            = 48,
      cegTag                  = [[missiletrailyellow]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      customParams            = {
        combatRange = 265,
      },
      damage                  = {
        default = 400.01,
      },

      edgeEffectiveness       = 0.5,
      fireStarter             = 100,
      fixedLauncher           = true,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 16,
      smokeTrail              = true,
      soundHit                = [[weapon/missile/missile_fire12]],
      soundStart              = [[weapon/missile/missile_fire10]],
      startVelocity           = 100,
      tolerance               = 4000,
      turnrate                = 30000,
      turret                  = true,
      --waterWeapon           = true,
      weaponAcceleration      = 300,
      weaponTimer             = 1,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1800,
    },

  },


  featureDefs            = {

    DEAD = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[shipassault_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4a.s3o]],
    },

  },

} }
