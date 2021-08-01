return { tankheavyraid = {
  unitname               = [[tankheavyraid]],
  name                   = [[Blitz]],
  description            = [[Lightning Assault/Raider Tank]],
  acceleration           = 0.75,
  brakeRate              = 1.65,
  buildCostMetal         = 300,
  builder                = false,
  buildPic               = [[tankheavyraid.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 0 0]],
  collisionVolumeScales  = [[28 12 28]],
  collisionVolumeType    = [[box]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius       = [[10]],
    selection_scale   = 0.85,
    aim_lookahead     = 120,
    bait_level_default = 0,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[tankraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1250,
  maxSlope               = 18,
  maxVelocity            = 3.25,
  maxWaterDepth          = 22,
  movementClass          = [[TANK3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[corseal.s3o]],
  script                 = [[tankheavyraid.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:PANTHER_SPARK]],
    },

  },
  sightDistance          = 560,
  trackOffset            = 6,
  trackStrength          = 5,
  trackStretch           = 1,
  trackType              = [[StdTank]],
  trackWidth             = 32,
  turninplace            = 0,
  turnRate               = 985,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[ARMLATNK_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    ARMLATNK_WEAPON = {
      name                    = [[Lightning Gun]],
      areaOfEffect            = 8,
      beamTTL                 = 1,
      burst                   = 10,
      burstrate               = 0.033,
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        burst = Shared.BURST_RELIABLE,
        extra_damage = 50,
        light_camera_height = 1600,
        light_color = [[0.85 0.85 1.2]],
        light_radius = 180,
      },

      cylinderTargeting      = 0,

      damage                  = {
        default        = 18,
      },

      duration                = 10,
      explosionGenerator      = [[custom:none]],
      fireStarter             = 150,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzeTime            = 1,
      range                   = 245,
      reloadtime              = 2.6,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
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
      object           = [[corseal_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

} }
