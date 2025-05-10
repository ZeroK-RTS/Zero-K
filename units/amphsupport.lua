return { amphsupport = {
  name                   = [[Bulkhead]],
  description            = [[Deployable Amphibious Fire Support (must stop to fire)]],
  acceleration           = 0.4,
  activateWhenBuilt      = true,
  brakeRate              = 2.4,
  builder                = false,
  buildPic               = [[amphsupport.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  collisionVolumeOffsets = [[0 6 0]],
  collisionVolumeScales  = [[38 50 38]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    amph_regen        = 15,
    amph_submerged_at = 30,
    sink_on_emp       = 0,
    floattoggle       = [[1]],
    modelradius       = [[13]],
    aimposoffset      = [[0 10 0]],
    chase_everything  = [[1]], -- Does not get stupidtarget added to noChaseCats
    selection_scale   = 0.85,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  health                 = 1540,
  iconType               = [[amphsupport]],
  leaveTracks            = true,
  maxSlope               = 36,
  metalCost              = 240,
  movementClass          = [[AKBOT3]],
  moveState              = 0,
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[amphdeploy.s3o]],
  script                 = [[amphsupport.lua]],
  pushResistant          = 0,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:RAIDDUST]],
      [[custom:THUDDUST]],
      [[custom:bubbles_small]],
    },

  },

  sightDistance          = 700,
  sonarDistance          = 700,
  speed                  = 48,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 32,
  turnRate               = 1100,
  upright                = true,

  weapons                = {
    {
      def                = [[CANNON]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[FAKE_CANNON]],
      badTargetCategory  = [[FIXEDWING GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

    CANNON = {
      name                    = [[Plasma Cannon]],
      accuracy                = 480,
      areaOfEffect            = 40,
      cegTag                  = [[light_arty_trail]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 1400,
        light_color = [[0.80 0.54 0.23]],
        light_radius = 230,
      },

      damage                  = {
        default = 165.1,
        planes  = 165.1,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.12,
      noSelfDamage            = true,
      range                   = 640,
      reloadtime              = 1.9,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

    FAKE_CANNON = {
      name                    = [[Fake Plasma Cannon]],
      accuracy                = 480,
      areaOfEffect            = 40,
      avoidFriendly           = false,
      craterBoost             = 0,
      craterMult              = 0,

      customparams = {
        bogus = 1,
      },

      damage                  = {
        default = 165.1,
        planes  = 165.1,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.12,
      noSelfDamage            = true,
      range                   = 640,
      reloadtime              = 1.8,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      turret                  = true,
      waterWeapon             = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 320,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[amphdeploy_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[debris3x3c.s3o]],
    },

  },

} }
