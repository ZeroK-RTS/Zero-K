return { cloakassault = {
  name                   = [[Knight]],
  description            = [[Lightning Assault Bot]],
  acceleration           = 0.6,
  brakeRate              = 3.6,
  buildPic               = [[cloakassault.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 7]],
  collisionVolumeScales  = [[35 50 35]],
  collisionVolumeType    = [[cylY]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[68 68 68]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[12]],
    cus_noflashlight = 1,
    bait_level_default = 0,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[kbotassault]],
  leaveTracks            = true,
  losEmitHeight          = 35,
  maxDamage              = 2400,
  maxSlope               = 36,
  maxVelocity            = 1.7,
  maxWaterDepth          = 22,
  metalCost              = 350,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[spherezeus.s3o]],
  script                 = [[cloakassault.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:zeusmuzzle]],
      [[custom:zeusgroundflash]],
    },

  },

  sightDistance          = 385,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.8,
  trackType              = [[ComTrack]],
  trackWidth             = 24,
  turnRate               = 1680,
  upright                = true,

  weapons                = {

    {
      def                = [[LIGHTNING]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    LIGHTNING = {
      name                    = [[Lightning Gun]],
      accuracy                = 900,
      beamTTL                 = 1,
      burst                   = 10,
      burstrate               = 0.033,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        extra_damage = 60,
        
        light_camera_height = 1600,
        light_color = [[0.2 0.6 1.2]],
        light_radius = 200,
      },

      cylinderTargeting      = 0,

      damage                  = {
        default        = 23,
      },

      explosionGenerator      = [[custom:lightningplosion_continuous]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 24,
      interceptedByShieldType = 1,
      paralyzeTime            = 1,
      range                   = 340,
      reloadtime              = 2.2,
      rgbColor                = [[0 0.25 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      thickness               = 3.5,
      turret                  = true,
      waterweapon             = false,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherezeus_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
