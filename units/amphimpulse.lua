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
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[30 30 30]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    amph_regen        = 15,
    amph_submerged_at = 40,
    sink_on_emp       = 1,
    floattoggle       = [[1]],
    selection_scale   = 0.8,
    aim_lookahead     = 120,
    set_target_range_buffer = 50,
    set_target_speed_buffer = 10,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 12.5,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[amphraider]],
  leaveTracks            = true,
  maxDamage              = 760,
  maxSlope               = 36,
  maxVelocity            = 2.35,
  movementClass          = [[AKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP]],
  objectName             = [[amphraider2.s3o]],
  script                 = [[amphimpulse.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {
    explosiongenerators = {
      [[custom:sonicfire]],
      [[custom:bubbles_small]],
    },
  },

  sightDistance          = 500,
  sonarDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1440,
  upright                = true,

  weapons                = {
    {
      def                = [[SONIC]],
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
        force_ignore_ground = [[1]],
        lups_explodelife = 1.0,
        lups_explodespeed = 0.4,
        light_radius = 120
      },

      damage                  = {
        default = 155.01,
      },
      
      cegTag                  = [[sonicarcher]],
      cylinderTargeting       = 1,
      explosionGenerator      = [[custom:sonic]],
      edgeEffectiveness       = 0.5,
      fireStarter             = 150,
      impulseBoost            = 100,
      impulseFactor           = 0.5,
      interceptedByShieldType = 1,
      myGravity               = 0.01,
      noSelfDamage            = true,
      range                   = 255,
      reloadtime              = 35/30,
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
      weaponVelocity          = 580,
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
