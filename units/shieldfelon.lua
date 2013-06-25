unitDef = {
  unitname            = [[shieldfelon]],
  name                = [[Felon]],
  description         = [[Shielded Skirmisher]],
  acceleration        = 0.25,
  activateWhenBuilt   = true,
  brakeRate           = 0.22,
  buildCostEnergy     = 620,
  buildCostMetal      = 620,
  buildPic            = [[shieldfelon.png]],
  buildTime           = 620,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext       = [[The Felon draws energy from its shield, discharging it in accurate bursts. Link it to other shields to increase its rate of fire.]],
  },

  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkersupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maxDamage           = 1400,
  maxSlope            = 36,
  maxVelocity         = 1.5,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noChaseCategory     = [[TERRAFORM FIXEDWING SUB]],
  objectName          = [[shieldfelon.s3o]],
  onoffable           = false,
  script              = [[shieldfelon.lua]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:lightningplosion_smallbolts_purple]],
    },

  },

  sightDistance       = 520,
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 30,
  turnRate            = 1000,
  upright             = true,

  weapons             = {
    {
      def                = [[SHIELDGUN]],
      badTargetCategory  = [[UNARMED]],
      onlyTargetCategory = [[FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER]],
	  --mainDir            = [[0 1 0]],
	  --maxAngleDif        = 270,
    },
    {
      def = [[SHIELD]],
    },
  },

  weaponDefs          = {

    SHIELD      = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.4,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 1200,
      shieldPowerRegen        = 18,
      shieldPowerRegenEnergy  = 0,
      shieldRadius            = 120,
      shieldRepulser          = false,
      shieldStartingPower     = 800,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },

    SHIELDGUN = {
      name                    = [[Shield Gun]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,
      cylinderTargeting      = 0,

      damage                  = {
        default        = 100,
      },

      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 50,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 6,
      interceptedByShieldType = 1,
      range                   = 430,
      reloadtime              = 0.15,
      rgbColor                = [[0.5 0 0.7]],
      soundStart              = [[weapon/constant_electric]],
      soundStartVolume        = 9,
      soundTrigger            = true,
      targetMoveError         = 0,
      texture1                = [[corelaser]],
      thickness               = 2,
      turret                  = true,
      weaponType              = [[LightningCannon]],
    },

  },

  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Felon]],
      blocking         = true,
      damage           = 1400,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 248,
      object           = [[shieldfelon_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 248,
    },

    HEAP  = {
      description      = [[Debris - Felon]],
      blocking         = false,
      damage           = 1400,
      energy           = 0,
      footprintX       = 2,
      footprintZ       = 2,
      metal            = 124,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 124,
    },

  },

}

return lowerkeys({ shieldfelon = unitDef })
