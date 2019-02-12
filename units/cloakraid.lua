unitDef = {
  unitname               = [[cloakraid]],
  name                   = [[Glaive]],
  description            = [[Light Raider Bot]],
  acceleration           = 0.5,
  brakeRate              = 0.4,
  buildCostMetal         = 65,
  buildPic               = [[cloakraid.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND TOOFAST]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[18 28 18]],
  collisionVolumeType    = [[cylY]],
  corpse                 = [[DEAD]],

  customParams           = {
	modelradius    = [[16]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotraider]],
  idleAutoHeal           = 20,
  idleTime               = 150,
  leaveTracks            = true,
  maxDamage              = 200,
  maxSlope               = 36,
  maxVelocity            = 3.85,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[spherebot.s3o]],
  script                 = [[cloakraid.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance          = 500,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.9,
  trackType              = [[ComTrack]],
  trackWidth             = 14,
  turnRate               = 2500,
  upright                = true,

  weapons                = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    EMG = {
      name                    = [[Pulse MG]],
      alphaDecay              = 0.1,
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.1,
      colormap                = [[1 0.95 0.4 1   1 0.95 0.4 1    0 0 0 0.01    1 0.7 0.2 1]],
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
		light_camera_height = 1200,
		light_color = [[0.8 0.76 0.38]],
		light_radius = 120,
      },

      damage                  = {
        default = 12,
        subs    = 0.567,
      },

      explosionGenerator      = [[custom:FLASHPLOSION]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noGap                   = false,
      noSelfDamage            = true,
      range                   = 185,
      reloadtime              = 0.31,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      size                    = 1.75,
      sizeDecay               = 0,
      soundStart              = [[weapon/emg]],
      soundStartVolume        = 4,
      sprayAngle              = 1180,
      stages                  = 10,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherebot_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

}

return lowerkeys({ cloakraid = unitDef })
