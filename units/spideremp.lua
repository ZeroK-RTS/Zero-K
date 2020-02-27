return { spideremp = {
  unitname               = [[spideremp]],
  name                   = [[Venom]],
  description            = [[Lightning Riot Spider]],
  acceleration           = 0.78,
  brakeRate              = 4.68,
  buildCostMetal         = 200,
  buildPic               = [[spideremp.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[38 38 38]],
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    aimposoffset   = [[0 0 0]],
    midposoffset   = [[0 -6 0]],
    modelradius    = [[19]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[spiderriotspecial]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 750,
  maxSlope               = 72,
  maxVelocity            = 2.7,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[TKBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[venom.s3o]],
  script                 = [[spideremp.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:YELLOW_LIGHTNING_MUZZLE]],
      [[custom:YELLOW_LIGHTNING_GROUNDFLASH]],
    },

  },

  sightDistance          = 440,
  trackOffset            = 0,
  trackStrength          = 10,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointyShort]],
  trackWidth             = 54,
  turnRate               = 1600,

  weapons                = {

    {
      def                = [[spider]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER FIXEDWING GUNSHIP]],
    },

  },

  weaponDefs             = {

    spider = {
      name                    = [[Electro-Stunner]],
      areaOfEffect            = 160,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,
      
      customParams            = {
        extra_damage = 600,
        
        light_color = [[0.75 0.75 0.56]],
        light_radius = 190,
      },

      damage                  = {
        default        = 18,
      },

      duration                = 8,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION160AoE]],
      fireStarter             = 0,
      heightMod               = 1,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      paralyzeTime            = 3,
      range                   = 240,
      reloadtime              = 1.733,
      rgbColor                = [[1 1 0.7]],
      soundStart              = [[weapon/lightning_fire]],
      soundTrigger            = true,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 450,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      collisionVolumeOffsets = [[0 0 0]],
      collisionVolumeScales  = [[40 30 50]],
      collisionVolumeType    = [[ellipsoid]],
      object           = [[venom_wreck.s3o]],
    },
    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
