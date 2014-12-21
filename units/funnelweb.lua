unitDef = {
  unitname               = [[funnelweb]],
  name                   = [[Funnelweb]],
  description            = [[Drone/Shield Support Strider]],
  acceleration           = 0.0552,
  activateWhenBuilt      = true,
  autoheal               = 20,
  brakeRate              = 0.1375,
  buildCostEnergy        = 4500,
  buildCostMetal         = 4500,
  buildPic               = [[funnelweb.png]],
  buildTime              = 4500,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  category               = [[LAND]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_pl = [[Ciezki pajak wsparcia]],
    helptext       = [[The slow all-terrain Funnelweb features an area shield and a powerful drone complement.]],
    helptext_pl    = [[Funnelweb to ciezki pajak wsparcia. Posiada tarcze obszarowa oraz produkuje zestaw dronow.]],
  },

  energyUse              = 1.5,
  explodeAs              = [[ESTOR_BUILDING]],
  footprintX             = 4,
  footprintZ             = 4,
  iconType               = [[t3special]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  leaveTracks            = true,
  maxDamage              = 11000,
  maxSlope               = 36,
  maxVelocity            = 1.5,
  maxWaterDepth          = 22,
  minCloakDistance       = 150,
  movementClass          = [[TKBOT4]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[funnelweb.s3o]],
  seismicSignature       = 4,
  selfDestructAs         = [[ESTOR_BUILDING]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },
  script                 = [[funnelweb.lua]],
  sightDistance          = 650,
  trackOffset            = 0,
  trackStrength          = 8,
  trackStretch           = 1,
  trackType              = [[ChickenTrackPointy]],
  trackWidth             = 64,
  turnRate               = 240,
  workerTime             = 0,

  weapons                = {

    {
      def                = "BOGUS_FAKE_TARGETER",
      badTargetCategory  = "FIXEDWING",
      onlyTargetCategory = "FIXEDWING LAND SINK TURRET SHIP SWIM FLOAT GUNSHIP HOVER",
    },

    {
      def                = [[SHIELD]],
    },

  },


  weaponDefs             = {

    BOGUS_FAKE_TARGETER = {
      name                    = [[Bogus Fake Targeter]],
      alphaDecay              = 0.1,
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.1,
      colormap                = [[1 0.95 0.4 1   1 0.95 0.4 1    0 0 0 0.01    1 0.7 0.2 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 11.34,
        planes  = 11.34,
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
      projectiles             = 2,
      range                   = 800,
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
	
    SHIELD = {
      name                    = [[Energy Shield]],

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      shieldAlpha             = 0.2,
      shieldBadColor          = [[1 0.1 0.1]],
      shieldGoodColor         = [[0.1 0.1 1]],
      shieldInterceptType     = 3,
      shieldPower             = 3600,
      shieldPowerRegen        = 50,
      shieldPowerRegenEnergy  = 12,
      shieldRadius            = 350,
      shieldRepulser          = false,
      smartShield             = true,
      texture1                = [[shield3mist]],
      visibleShield           = true,
      visibleShieldHitFrames  = 4,
      visibleShieldRepulse    = true,
      weaponType              = [[Shield]],
    },
	
  },


  featureDefs            = {

    DEAD  = {
      description      = [[Wreckage - Funnelweb]],
      blocking         = true,
      damage           = 11000,
      energy           = 0,
      featureDead      = [[HEAP]],
      footprintX       = 4,
      footprintZ       = 4,
      metal            = 1800,
      object           = [[funnelweb_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 1800,
    },

    HEAP  = {
      description      = [[Debris - Funnelweb]],
      blocking         = false,
      damage           = 11000,
      energy           = 0,
      footprintX       = 4,
      footprintZ       = 4,
      metal            = 900,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 900,
    },

  },

}

return lowerkeys({ funnelweb = unitDef })
