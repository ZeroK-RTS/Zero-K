return { amphlaunch = {
  name                   = [[Lobster]],
  description            = [[Amphibious Launcher Bot]],
  acceleration           = 0.6,
  activateWhenBuilt      = true,
  brakeRate              = 2.4,
  buildPic               = [[amphlaunch.png]],
  canGuard               = true,
  canManualFire          = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND SINK]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 45 45]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen         = 10,
    amph_submerged_at  = 40,
    thrower_gather     = 160,
    attack_toggle      = [[1]],
    can_target_allies  = 1,
    manualfire_num = 2,
  },

  explodeAs              = [[BIG_UNITEX]],
  fireState              = 0,
  footprintX             = 2,
  footprintZ             = 2,
  health                 = 960,
  highTrajectory         = 1,
  iconType               = [[ampharty]],
  leaveTracks            = true,
  maxSlope               = 36,
  maxWaterDepth          = 5000,
  metalCost              = 340,
  movementClass          = [[AKBOT2]],
  noChaseCategory        = [[TERRAFORM SATELLITE STUPIDTARGET]],
  objectName             = [[behecrash.s3o]],
  script                 = [[amphlaunch.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:thrower_shockwave]],
    },
  },

  sightDistance          = 500,
  sonarDistance          = 500,
  speed                  = 54,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 28,
  turnRate               = 2160,
  upright                = true,

  weapons                = {
    {
      def                = [[TELEPORT_GUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
    {
      def                = [[BOGUS_TELEPORTER_GUN]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },
  },

  weaponDefs             = {

    TELEPORT_GUN = {
      name                    = [[Unit Launcher]],
      accuracy                = 0,
      areaOfEffect            = 224, -- UI
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      burnblow                = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        ui_manual_fire = 1,
        lups_noshockwave = [[1]],
        thower_weapon    = 1,
      },
      
      damage                  = {
        default = 0,
      },

      explosionSpeed          = 50,
      intensity               = 0.9,
      interceptedByShieldType = 1,
      leadLimit               = 0,
      myGravity               = 0.05,
      projectiles             = 1,
      range                   = 620,
      reloadtime              = 14,
      rgbColor                = [[0.05 0.45 0.95]],
      size                    = 0.005,
      soundStart              = [[Launcher]],
      soundStartVolume        = 6000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
      waterweapon             = true,
    },

    BOGUS_TELEPORTER_GUN = {
      name                    = [[Bogus Unit Launcher]],
      accuracy                = 0,
      areaOfEffect            = 224, -- UI
      avoidFeature            = false,
      avoidFriendly           = false,
      avoidGround             = false,
      burnblow                = true,
      commandfire             = true,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        lups_noshockwave = [[1]],
        thower_weapon    = 1,
        bogus = 1,
      },
      
      damage                  = {
        default = 0,
      },

      explosionSpeed          = 50,
      intensity               = 0.9,
      interceptedByShieldType = 1,
      leadLimit               = 0,
      myGravity               = 0.05,
      projectiles             = 1,
      range                   = 620,
      reloadtime              = 14,
      rgbColor                = [[0.05 0.45 0.95]],
      size                    = 0.005,
      soundStart              = [[Launcher]],
      soundStartVolume        = 6000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
      waterweapon             = true,
    },

  },

  featureDefs            = {

    DEAD      = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 3,
      footprintZ       = 3,
      object           = [[behecrash_dead.s3o]],
    },

    HEAP      = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }