return { tankheavyraid = {
  unitname               = [[tankheavyraid]],
  name                   = [[Blitz]],
  description            = [[Lightning Assault/Raider Tank]],
  acceleration           = 0.625,
  brakeRate              = 1.375,
  buildCostMetal         = 285,
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
    modelradius    = [[10]],
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[tankraider]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 1100,
  maxSlope               = 18,
  maxVelocity            = 3.4,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
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
  turnRate               = 616,
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
      craterBoost             = 0,
      craterMult              = 0,

      customParams            = {
        burst = Shared.BURST_RELIABLE,
        extra_damage = 500,
        light_camera_height = 1600,
        light_color = [[0.85 0.85 1.2]],
        light_radius = 180,
      },

      cylinderTargeting      = 0,

      damage                  = {
        default        = 180,
      },

      duration                = 10,
      explosionGenerator      = [[custom:LIGHTNINGPLOSION]],
      fireStarter             = 150,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 12,
      interceptedByShieldType = 1,
      paralyzeTime            = 1,
      range                   = 245,
      reloadtime              = 2.6 + 1/30,
      rgbColor                = [[0.5 0.5 1]],
      soundStart              = [[weapon/more_lightning_fast]],
      soundTrigger            = true,
      texture1                = [[lightning]],
      thickness               = 10,
      turret                  = true,
      weaponType              = [[LightningCannon]],
      weaponVelocity          = 400,
    },

    PANTHER_DEATH = {
      name = [[Death]],
      areaOfEffect = 320,
      craterBoost = 0,
      craterMult = 0,
      edgeEffectiveness = 0,
      explosionGenerator = [[custom:cloakbomb_EXPLOSION]],
      explosionSpeed = 10000,
      fireStarter = 0,
      impulseBoost = 0,
      impulseFactor = 0,
      paralyzer = true,
      paralyzeTime = 4,
      soundhit = [[explosion/small_emp_explode]],
      
      damage = {
        default = 600,
      },
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
