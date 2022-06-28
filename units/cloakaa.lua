return { cloakaa = {
  unitname               = [[cloakaa]],
  name                   = [[Gremlin]],
  description            = [[Cloaked Anti-Air Bot]],
  acceleration           = 1.5,
  brakeRate              = 1.92,
  buildCostMetal         = 140,
  buildPic               = [[cloakaa.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  cloakCost              = 0.1,
  cloakCostMoving        = 0.5,
  collisionVolumeOffsets = [[0 1 0]],
  collisionVolumeScales  = [[22 28 22]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
    bait_level_default = 0,
    modelradius    = [[11]],
    cus_noflashlight = 1,
  },

  explodeAs              = [[BIG_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotaa]],
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 550,
  maxSlope               = 36,
  maxVelocity            = 2.9,
  maxWaterDepth          = 22,
  minCloakDistance       = 140,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM LAND SINK TURRET SHIP SWIM FLOAT SUB HOVER]],
  objectName             = [[spherejeth.s3o]],
    script               = [[cloakaa.lua]],
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:NONE]],
      [[custom:NONE]],
    },

  },

  sightDistance          = 660,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ComTrack]],
  trackWidth             = 16,
  turnRate               = 2640,
  upright                = true,

  weapons                = {

    {
      def                = [[AA_LASER]],
      --badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    AA_LASER      = {
      name                    = [[Anti-Air Laser]],
      areaOfEffect            = 12,
      beamDecay               = 0.736,
      beamTime                = 1/30,
      beamttl                 = 15,
      canattackground         = false,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting       = 1,

      customParams              = {
        isaa = [[1]],
        light_color = [[0.2 1.2 1.2]],
        light_radius = 120,
      },

      damage                  = {
        default = 2,
        planes  = 20.001,
      },

      explosionGenerator      = [[custom:flash_teal7]],
      fireStarter             = 100,
      impactOnly              = true,
      impulseFactor           = 0,
      interceptedByShieldType = 1,
      laserFlareSize          = 3.25,
      minIntensity            = 1,
      range                   = 720,
      reloadtime              = 0.3,
      rgbColor                = [[0 1 1]],
      soundStart              = [[weapon/laser/rapid_laser]],
      soundStartVolume        = 4,
      thickness               = 2.3,
      tolerance               = 8192,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2200,
    },

  },

  featureDefs            = {

    DEAD = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherejeth_dead.s3o]],
    },

    HEAP = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2a.s3o]],
    },

  },

} }
