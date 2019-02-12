unitDef = {
  unitname               = [[cloakriot]],
  name                   = [[Reaver]],
  description            = [[Riot Bot]],
  acceleration           = 0.25,
  brakeRate              = 0.2,
  buildCostMetal         = 220,
  buildPic               = [[cloakriot.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 1 -1]],
  collisionVolumeScales  = [[26 36 26]],
  collisionVolumeType    = [[cylY]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[45 45 45]],
  selectionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[7]],
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[kbotriot]],
  idleAutoHeal           = 20,
  idleTime               = 150,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 36,
  maxVelocity            = 1.71,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT3]],
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[Spherewarrior.s3o]],
  script                 = [[cloakriot.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:WARMUZZLE]],
      [[custom:emg_shells_l]],
    },

  },

  sightDistance          = 345,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.8,
  trackType              = [[ComTrack]],
  trackWidth             = 20,
  turnRate               = 1800,
  upright                = true,

  weapons                = {

    {
      def                = [[WARRIOR_WEAPON]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },

  weaponDefs             = {

    WARRIOR_WEAPON = {
      name                    = [[Heavy Pulse MG]],
      accuracy                = 350,
      alphaDecay              = 0.7,
      areaOfEffect            = 96,
      burnblow                = true,
      burst                   = 3,
      burstrate               = 0.1,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      customParams        = {
		light_camera_height = 1600,
		light_color = [[0.8 0.76 0.38]],
		light_radius = 150,
      },

      damage                  = {
        default = 40,
        planes  = 40,
        subs    = 2.1,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 270,
      reloadtime              = 0.4 + 2/30,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/heavy_emg]],
      stages                  = 10,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 550,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[spherewarrior_dead.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris3x3a.s3o]],
    },

  },

}

return lowerkeys({ cloakriot = unitDef })
