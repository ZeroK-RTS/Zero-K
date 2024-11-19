return { slicer = {
  name                = [[Slicer]],
  description         = [[Melee Assault Walker]],
  acceleration        = 0.12,
  brakeRate           = 0.188,
  builder             = false,
  buildPic            = [[core_slicer.png]],
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    canjump        = 1,
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  health              = 4000,
  iconType            = [[jumpjetassault]],
  leaveTracks         = true,
  maxSlope            = 36,
  maxWaterDepth       = 5000,
  metalCost           = 550,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP]],
  objectName          = [[slicer]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:rockomuzzle]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  sightDistance       = 350,
  speed               = 54,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 970,
  upright             = true,

  weapons             = {

    [1] = {
      def                = [[Punch]],
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP HOVER]],
    },


    [3] = {
      def                = [[LaserBlade]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    LaserBlade = {
      name                    = [[Tachyon Beam]],
      areaOfEffect            = 20,
      beamTime                = 1/30,
      coreThickness           = 0.8,
      craterBoost             = 0,
      craterMult              = 0,

      customParams = {
        nofriendlyfire = 1,
      },

      damage                  = {
        default = 100,
      },

      explosionGenerator      = [[custom:LASERBLADESTRIKE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4.93,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 55,
      reloadtime              = 0.1,
      rgbColor                = [[1.00 0.1 0.01]],
      soundStart              = [[weapon/hiss]],
      soundStartVolume        = 1,
      targetMoveError         = 0,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 2.93,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
    },


    Punch      = {
      name                    = [[Punch]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1,
        planes  = 1,
        subs    = 1,
      },

      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 80,
      reloadtime              = 0.5,
      size                    = 0,
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      blocking         = true,
      featureDead      = [[MID_HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[slicer_dead]],
    },

    MID_HEAP  = { -- ancient script with 3 levels, but maybe good to keep for modding capability reasons
      blocking         = false,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

    HEAP  = {
      blocking         = false,
      footprintX       = 2,
      footprintZ       = 2,
      object           = [[debris2x2c.s3o]],
    },

  },

}}
