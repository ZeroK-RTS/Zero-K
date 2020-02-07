return { chicken_digger_b = {
  unitname            = [[chicken_digger_b]],
  name                = [[Digger (burrowed)]],
  description         = [[Burrowing Scout/Raider]],
  acceleration        = 0.78,
  activateWhenBuilt   = false,
  brakeRate           = 1.23,
  buildCostEnergy     = 0,
  buildCostMetal      = 0,
  builder             = false,
  buildPic            = [[chicken_digger.png]],
  buildTime           = 40,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND BURROWED]],

  customParams        = {
    statsname         = "chicken_digger",
  },

  explodeAs           = [[SMALL_UNITEX]],
  fireState           = 1,
  floater             = false,
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[chicken]],
  idleAutoHeal        = 20,
  idleTime            = 300,
  leaveTracks         = false,
  maxDamage           = 180,
  maxSlope            = 72,
  maxVelocity         = 0.9,
  maxWaterDepth       = 15,
  minCloakDistance    = 75,
  movementClass       = [[TKBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[chicken_digger_b.s3o]],
  onoffable           = true,
  power               = 40,
  selfDestructAs      = [[SMALL_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
      [[custom:dirt]],
    },

  },
  sightDistance       = 0,
  stealth             = true,
  trackOffset         = 0,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 18,
  turnRate            = 806,
  upright             = false,
  waterline           = 8,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 120,
      onlyTargetCategory = [[SWIM LAND SINK TURRET FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Claws]],
      alphaDecay              = 0.1,
      areaOfEffect            = 8,
      colormap                = [[1 0.95 0.4 1   1 0.95 0.4 1    0 0 0 0.01    1 0.7 0.2 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 80,
        planes  = 80,
        subs    = 4,
      },

      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      noGap                   = false,
      noSelfDamage            = true,
      range                   = 100,
      reloadtime              = 1.2,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      size                    = 1.75,
      sizeDecay               = 0,
      soundHit                = [[chickens/chickenbig2]],
      soundStart              = [[chickens/chicken]],
      sprayAngle              = 1180,
      stages                  = 10,
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },

} }
