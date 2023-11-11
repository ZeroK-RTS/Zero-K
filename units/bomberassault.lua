return { bomberassault = {
  name                = [[Ragnarok]],
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
  collisionVolumeOffsets = [[0 2 -5]],
  collisionVolumeScales  = [[60 52 120]],
  collisionVolumeType    = [[ellipsoid]],
  corpse              = [[DEAD]],
  crashDrag           = 0.02,
  cruiseAltitude      = 280,

  customParams        = {
    refuelturnradius = [[350]],
    reammoseconds    = 30,
    modelradius      = [[10]],
    can_set_target   = [[1]],
  },

  selfDestructAs         = [[ESTOR_BUILDING]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  health              = 4000,
  iconType            = [[bomberassaultarty]],
  maneuverleashlength = [[1280]],
  maxAcc              = 0.5,
  maxBank             = 0.008,
  maxAileron          = 0.003,
  maxElevator         = 0.005,
  maxPitch            = 0.3,
  maxRudder           = 0.0044,
  maxFuel             = 1000000,
  metalCost           = 1600,
  mygravity           = 1,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[zeppelin.dae]],
  script              = [[bomberassault.lua]],
  selfDestructAs         = [[ESTOR_BUILDING]],
  sightDistance       = 660,
  speed               = 185,
  turnRadius          = 150,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[ZEPPELIN_BOMB]],
      badTargetCategory  = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    {
      def                = [[DISINTEGRATOR]],
      badTargetCategory  = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },
    {
      def                = [[DISINTEGRATOR_REAL]],
      badTargetCategory  = [[GUNSHIP FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SINK SUB TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
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
        child_chain_speed = 7,
      },

      damage                  = {
        default = 2000,
      },

      explosionGenerator      = [[custom:DGUNTRACE]],
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      leadLimit               = 30,
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
        stats_burst_damage  = 18000,
      },

      damage                  = {
        default = 2000,
      },

      explosionGenerator      = [[custom:DGUNTRACE]],
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      interceptedByShieldType = 0,
      leadLimit               = 30,
      myGravity               = 0.08,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 60,
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
