return { cloakarty = {
  unitname               = [[cloakarty]],
  name                   = [[Sling]],
  description            = [[Light Artillery Bot]],
  acceleration           = 0.75,
  brakeRate              = 4.5,
  buildCostMetal         = 100,
  buildPic               = [[cloakarty.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 43 28]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    modelradius       = [[14]],
    selection_scale   = 0.85,

    outline_x = 80,
    outline_y = 80,
    outline_yoff = 15.5,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[kbotarty]],
  leaveTracks            = true,
  maxDamage              = 350,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING GUNSHIP SMALL]],
  objectName             = [[cloakarty.s3o]],
  script                 = [[cloakarty.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:THUDMUZZLE]],
      [[custom:THUDSHELLS]],
      [[custom:THUDDUST]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.9,
  trackType              = [[ComTrack]],
  trackWidth             = 22,
  turnRate               = 1800,
  upright                = true,

  weapons                = {

    {
      def                = [[HAMMER_WEAPON]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[SWIM LAND SHIP SINK TURRET FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    HAMMER_WEAPON = {
      name                    = [[Light Plasma Cannon]],
      accuracy                = 220,
      areaOfEffect            = 16,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 1400,
        light_color = [[0.80 0.54 0.23]],
        light_radius = 200,
      },

      damage                  = {
        default = 140.1,
        planes  = 140.1,
      },

      edgeEffectiveness       = 0.1,
      explosionGenerator      = [[custom:MARY_SUE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      myGravity               = 0.09,
      noSelfDamage            = true,
      range                   = 860,
      reloadtime              = 6,
      soundHit                = [[explosion/ex_med5]],
      soundStart              = [[weapon/cannon/cannon_fire1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 270,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[cloakarty_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
