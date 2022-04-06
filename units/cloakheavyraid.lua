return { cloakheavyraid = {
  unitname               = [[cloakheavyraid]],
  name                   = [[Scythe]],
  description            = [[Cloaked Raider Bot]],
  acceleration           = 1.5,
  brakeRate              = 1.8,
  buildCostMetal         = 250,
  buildPic               = [[cloakheavyraid.png]],
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -2 0]],
  collisionVolumeScales  = [[28 36 28]],
  collisionVolumeType    = [[cylY]],
  selectionVolumeOffsets = [[0 0 0]],
  selectionVolumeScales  = [[32 32 32]],
  selectionVolumeType    = [[ellipsoid]],
  cloakCost              = 0.2,
  cloakCostMoving        = 1,
  corpse                 = [[DEAD]],

  customParams           = {
    modelradius    = [[14]],
    cus_noflashlight = 1,
  },

  explodeAs              = [[SMALL_UNITEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[stealth]],
  idleAutoHeal           = 10,
  idleTime               = 300,
  initCloaked            = true,
  leaveTracks            = true,
  maxDamage              = 820,
  maxSlope               = 36,
  maxVelocity            = 3,
  maxWaterDepth          = 22,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  moveState              = 0,
  noChaseCategory        = [[TERRAFORM FIXEDWING SUB]],
  objectName             = [[spherepole.s3o]],
  script                 = [[cloakheavyraid.lua]],
  selfDestructAs         = [[SMALL_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  sightDistance          = 425,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 0.9,
  trackType              = [[ComTrack]],
  trackWidth             = 18,
  turnRate               = 2640,
  upright                = true,

  weapons                = {

    {
      def                = [[Blade]],
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },

  weaponDefs             = {

    Blade = {
      name                    = [[Blade]],
      areaOfEffect            = 8,
      beamTime                = 0.13,
      canattackground         = true,
      cegTag                  = [[orangelaser]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      customParams        = {
        light_camera_height = 500,
        light_color = [[1 1 0.7]],
        light_radius = 120,
        light_beam_start = 0.25,
        
        combatrange = 50,
      },
      
      damage                  = {
        default = 200.1,
        planes  = 200,
      },

      explosionGenerator      = [[custom:BEAMWEAPON_HIT_ORANGE]],
      fireStarter             = 90,
      hardStop                = false,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 0,
      lodDistance             = 10000,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 1.4,
      rgbColor                = [[1 0.25 0]],
      soundStart              = [[BladeSwing]],
      targetborder            = 0.9,
      thickness               = 0,
      tolerance               = 10000,
      turret                  = true,
      waterweapon             = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 2000,
    },

  },

  featureDefs            = {

    DEAD  = {
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[scythe_d.dae]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2b.s3o]],
    },

  },

} }
