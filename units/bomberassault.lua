return { bomberassault = {
  name                = [[Odin]],
  description         = [[Assault Bomber (Anti-Static)]],
  --autoheal            = 25,
  brakerate           = 0.4,
  builder             = false,
  buildPic            = [[bomberassault.png]],
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canSubmerge         = false,
  category            = [[FIXEDWING]],
  collide             = false,
  collisionVolumeOffsets = [[0 2 -4]],
  collisionVolumeScales  = [[50 48 114]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  crashDrag           = 0.02,
  cruiseAltitude      = 280,

  customParams        = {
    refuelturnradius       = [[300]],
    refuelmaxbank          = 0.015,
    reammoseconds          = 30,
    modelradius            = [[10]],
    can_set_target         = [[1]],
    air_manual_fire_weapon = 4,
    manualfire_desc        = [[Fire Special Weapon: Fire a cluster of temporary shield generators.]],
  },

  selfDestructAs         = [[ESTOR_BUILDING]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  health              = 5200,
  iconType            = [[bomberassaultshield]],
  maneuverleashlength = [[1280]],
  maxAcc              = 0.5,
  maxBank             = 0.008,
  maxAileron          = 0.003,
  maxElevator         = 0.005,
  maxPitch            = 0.3,
  maxRudder           = 0.0044,
  maxFuel             = 1000000,
  metalCost           = 1500,
  mygravity           = 1,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[zeppelin.dae]],
  script              = [[bomberassault.lua]],
  selfDestructAs         = [[ESTOR_BUILDING]],
  sightDistance       = 660,
  speed               = 185,
  turnRadius          = 120,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ZEPPELIN_BOMB]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[DISINTEGRATOR]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[DISINTEGRATOR_REAL]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP]],
    },
    {
      def                = [[DEPLOY_SHIELD]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP]],
    },

  },


  weaponDefs          = {
    ZEPPELIN_BOMB = {
      name                    = [[Bogus Fake Bomber Bomb]],
      areaOfEffect            = 100,
      avoidFeature            = false,
      avoidFriendly           = false,
      collideFeature          = false,
      collideFriendly         = false,
      craterBoost             = 10,
      craterMult              = 1,

      damage                  = {
        default = 2500,
        planes  = 2500,
      },

      edgeEffectiveness       = 0.7,
      explosionGenerator      = [[custom:slam]],
      impulseBoost            = 0,
      impulseFactor           = 0.1,
      interceptedByShieldType = 1,
      model                   = [[zeppelin_bomb.dae]],
      myGravity               = 0.15,
      noSelfDamage            = true,
      range                   = 180,
      reloadtime              = 1,
      soundHit                = [[weapon/missile/liche_hit]],
      soundStart              = [[weapon/missile/liche_fire]],
      weaponType              = [[AircraftBomb]],
    },

    DISINTEGRATOR = {
      name                    = [[Disintegrator but also fake and bogus]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      avoidNeutral            = false,
      cegTag                  = [[beamerray_angry]],
      craterBoost             = 1,
      craterMult              = 6,

      customparams            = {
        child_chain_projectile = "bomberassault_disintegrator_real",
        child_chain_speed      = 28,
        child_max_vertical     = 2.5,
        remove_damage          = 1
      },

      damage                  = {
        default = 2000.1,
      },

      explosionGenerator      = [[custom:none]],
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      leadLimit               = 5,
      myGravity               = 0.08,
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 2,
      size                    = 6,
      soundHit                = [[explosion/ex_med6]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 90,
    },

    DISINTEGRATOR_REAL = {
      name                    = [[Disintegrator Bomb]],
      areaOfEffect            = 48,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      avoidNeutral            = false,
      cegTag                  = [[beamerray_angry]],
      craterBoost             = 1,
      craterMult              = 6,

      customparams            = {
        reammoseconds = "autogenerated in posts",
        truerange     = 200,
        burst = Shared.BURST_UNRELIABLE,
        stats_burst_damage  = 8000,
        stats_typical_damage  = 8000,
        noexplode_speed_damage = 1,
      },

      damage                  = {
        default = 2000.1,
      },

      explosionGenerator      = [[custom:DGUNTRACE]],
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      leadLimit               = 5,
      myGravity               = 0.08,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 120,
      reloadtime              = 2,
      size                    = 6,
      soundHit                = [[explosion/ex_med6]],
      soundStart              = [[weapon/laser/heavy_laser4]],
      soundTrigger            = true,
      tolerance               = 10000,
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 840,
    },

    DEPLOY_SHIELD = {
      name                    = [[Deployable Shield Cluster]],
      accuracy                = 50,
      areaOfEffect            = 8,
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidNeutral            = false,
      burst                   = 7,
      burstRate               = 0.0666,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        reammoseconds = "autogenerated in posts",

        damage_vs_shield = [[3400]], -- Same damage as shield charge? Reversal of polarity?
        spawn_blocked_by_shield = 1,
        force_ignore_ground = [[1]],
        spawns_name = "statictempshield",
        spawns_expire = 85, -- At least the drain-based lifetime of spawned shields
        
        light_radius = 0,

        ui_manual_fire = 1,
        ui_no_friendly_fire = 1,
      },
      
      damage                  = {
        default = 0.0001,
      },

      explosionGenerator      = [[custom:dirt]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      model                   = [[m-8_projectile.s3o]],
      myGravity               = 0.25,
      noSelfDamage            = true,
      range                   = 500,
      reloadtime              = 5.6,
      sprayangle              = 7500,
      soundHit                = [[weapon/cannon/badger_hit]],
      soundStart              = [[weapon/cannon/badger_fire]],
      soundHitVolume          = 10,
      soundStartVolume        = 16,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 250,
    },

  },


  featureDefs         = {
    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[zeppelin_dead.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3b.s3o]],
    },

  },

} }
