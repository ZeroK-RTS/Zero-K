return { amphraid = {
  unitname               = [[amphraid]],
  name                   = [[Duck]],
  description            = [[Amphibious Raider (Anti-Sub, Undersea Fire)]],
  acceleration           = 0.54,
  activateWhenBuilt      = true,
  brakeRate              = 2.25,
  buildCostMetal         = 80,
  buildPic               = [[amphraid.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK TOOFAST SMALL]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[28 28 28]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    amph_regen        = 5,
    amph_submerged_at = 40,
    aim_lookahead     = 80,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphtorpraider]],
  leaveTracks            = true,
  maxDamage              = 360,
  maxSlope               = 36,
  maxVelocity            = 3,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP]],
  objectName             = [[amphraider3.s3o]],
  script                 = [[amphraid.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
    },
  },

  sightDistance          = 560,
  sonarDistance          = 560,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 2100,
  upright                = true,

  weapons                = {
    {
      def                = [[TORPMISSILE]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[SWIM FIXEDWING HOVER LAND SINK TURRET FLOAT SHIP GUNSHIP]],
    },
    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING HOVER LAND SINK TURRET FLOAT SHIP GUNSHIP SUB]],
    },
  },

  weaponDefs             = {

    TORPMISSILE = {
      name                    = [[Torpedo Missile]],
      areaOfEffect            = 32,
      cegTag                  = [[missiletrailyellow]],
      craterBoost             = 1,
      craterMult              = 2,

      customparams = {
        burst = Shared.BURST_RELIABLE,

        light_color = [[1 0.6 0.2]],
        light_radius = 180,
      },

      damage                  = {
        default = 130.01,
      },

      explosionGenerator      = [[custom:INGEBORG]],
      flightTime              = 2,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      leadlimit               = 1,
      model                   = [[wep_m_ajax.s3o]],
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 235,
      reloadtime              = 2,
      smokeTrail              = true,
      soundHit                = [[weapon/cannon/cannon_hit2]],
      soundStart              = [[weapon/missile/missile_fire9]],
      startVelocity           = 140,
      texture2                = [[lightsmoketrail]],
      tolerance               = 1000,
      tracks                  = true,
      trajectoryHeight        = 0.4,
      turnRate                = 25000,
      turret                  = true,
      weaponAcceleration      = 90,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 220,
    },

    TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 32,
      avoidFriendly           = false,
      bouncerebound           = 0.5,
      bounceslip              = 0.8,
      canAttackGround         = false,
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cegTag                  = [[torpedo_trail]],

      customparams = {
        radar_homing_distance = 200,
        stays_underwater = 1,
      },

      damage                  = {
        default = 130.01,
      },

      edgeEffectiveness       = 0.99,
      explosionGenerator      = [[custom:TORPEDO_HIT]],
      flightTime              = 1.3,
      groundbounce            = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      leadlimit               = 0,
      model                   = [[wep_m_ajax.s3o]],
      numbounce               = 4,
      noSelfDamage            = true,
      projectiles             = 1,
      range                   = 160,
      reloadtime              = 2,
      soundHit                = [[explosion/wet/ex_underwater]],
      --soundStart              = [[weapon/torpedo]],
      soundStartVolume        = 0.7,
      soundHitVolume          = 0.7,
      startVelocity           = 140,
      tolerance               = 1000,
      tracks                  = true,
      turnRate                = 25000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 75,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 240,
    },
  },

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[amphraider3_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
