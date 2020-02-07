return { amphriot = {
  unitname               = [[amphriot]],
  name                   = [[Scallop]],
  description            = [[Amphibious Riot Bot (Anti-Sub)]],
  acceleration           = 0.54,
  activateWhenBuilt      = true,
  brakeRate              = 2.25,
  buildCostMetal         = 280,
  buildPic               = [[amphriot.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[30 30 30]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen = 10,
    amph_submerged_at = 40,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[amphtorpriot]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1100,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  minCloakDistance       = 75,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP HOVER]],
  objectName             = [[amphriot.s3o]],
  script                 = [[amphriot.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:HEAVY_CANNON_MUZZLE]],
      [[custom:RIOT_SHELL_L]],
    },
  },

  sightDistance          = 430,
  sonarDistance          = 430,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 28,
  turnRate               = 1000,
  upright                = false,

  weapons                = {

    {
      def                = [[FLECHETTE]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

    {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM LAND SUB SINK TURRET FLOAT SHIP HOVER]],
    },

  },

  weaponDefs             = {

    TORPEDO = {
      name                    = [[Undersea Charge Launcher]],
      areaOfEffect            = 100,
      burst                   = 2,
      burstRate               = 0.2,
      avoidFriendly           = false,
      bouncerebound           = 1,
      bounceslip              = 1,
      burnblow                = true,
      canAttackGround         = false, -- also workaround for range hax
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      damage                  = {
        default = 90.1,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      flightTime              = 1.6,
      groundbounce            = 1,
      impactOnly              = false,
      impulseBoost            = 0,
      impulseFactor           = 0.6,
      interceptedByShieldType = 1,
      leadlimit               = 1,
      myGravity               = 2,
      model                   = [[diskball.s3o]],
      numBounce               = 1,
      range                   = 230,
      reloadtime              = 1.4,
      soundHit                = [[TorpedoHitVariable]],
      soundHitVolume          = 2.6,
      --soundStart            = [[weapon/torpedo]],
      startVelocity           = 90,
      tracks                  = true,
      turnRate                = 30000,
      turret                  = true,
      waterWeapon             = true,
      weaponAcceleration      = 300,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 400,
    },

    FLECHETTE = {
      name                    = [[Flechette]],
      areaOfEffect            = 32,
      burst                   = 3,
      burstRate               = 0.033,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        light_camera_height = 2000,
        light_color = [[0.3 0.3 0.05]],
        light_radius = 120,
      },

      damage                  = {
        default = 26,
        subs    = 1.6,
      },

      duration                = 0.02,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_YELLOW]],
      fireStarter             = 50,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      projectiles             = 3,
      range                   = 300,
      reloadtime              = 0.8,
      rgbColor                = [[1 1 0]],
      soundHit                = [[impacts/shotgun_impactv5]],
      soundStart              = [[weapon/shotgun_firev4]],
      soundStartVolume        = 0.5,
      soundTrigger            = true,
      sprayangle              = 1500,
      thickness               = 2,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 880,
    }
  },

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[amphriot_wreck.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
