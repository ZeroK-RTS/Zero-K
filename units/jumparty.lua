return { jumparty = {
  unitname               = [[jumparty]],
  name                   = [[Firewalker]],
  description            = [[Saturation Artillery Walker]],
  acceleration           = 0.36,
  brakeRate              = 1.44,
  buildCostMetal         = 900,
  builder                = false,
  buildPic               = [[jumparty.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[55 55 55]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 1,
    selection_scale   = 0.92,

    outline_x = 125,
    outline_y = 125,
    outline_yoff = 21,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[fatbotarty]],
  leaveTracks            = true,
  maxDamage              = 1250,
  maxSlope               = 36,
  maxVelocity            = 1.4,
  maxWaterDepth          = 22,
  movementClass          = [[KBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM SATELLITE SUB]],
  objectName             = [[firewalker.s3o]],
  script                 = [[jumparty.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:shellshockflash]],
      [[custom:SHELLSHOCKSHELLS]],
      [[custom:SHELLSHOCKGOUND]],
    },

  },
  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.6,
  trackType              = [[ComTrack]],
  trackWidth             = 33,
  turnRate               = 720,
  upright                = true,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[NAPALM_SPRAYER]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs             = {
    NAPALM_SPRAYER = {
      name                    = [[Napalm Mortar]],
      accuracy                = 400,
      areaOfEffect            = 128,
      avoidFeature            = false,
      craterBoost             = 1,
      craterMult              = 2,
      cegTag                  = [[flamer]],

      customParams              = {
        setunitsonfire = "1",
        burntime = 60,
        force_ignore_ground = [[1]],

        area_damage = 1,
        area_damage_radius = 64,
        area_damage_dps = 19,
        area_damage_duration = 16,

        --lups_heat_fx = [[firewalker]],
        light_camera_height = 2500,
        light_color = [[0.25 0.13 0.05]],
        light_radius = 460,
      },
      
      damage                  = {
        default = 68,
      },

      explosionGenerator      = [[custom:napalm_firewalker_small]],
      firestarter             = 180,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.1,
      projectiles             = 10,
      range                   = 900,
      reloadtime              = 12,
      rgbColor                = [[1 0.5 0.2]],
      size                    = 5,
      soundHit                = [[weapon/cannon/wolverine_hit]],
      soundStart              = [[weapon/cannon/wolverine_fire]],
      soundStartVolume        = 3.2,
      sprayangle              = 2500,
      turret                  = true,
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
      object           = [[firewalker_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 4,
      footprintZ       = 4,
      object           = [[debris4x4c.s3o]],
    },

  },

} }
