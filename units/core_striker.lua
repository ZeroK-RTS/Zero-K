unitDef = {
  unitname            = [[core_striker]],
  name                = [[Striker]],
  description         = [[Melee Assault Walker]],
  acceleration        = 0.12,
  bmcode              = [[1]],
  brakeRate           = 0.188,
  buildCostEnergy     = 550,
  buildCostMetal      = 550,
  builder             = false,
  buildPic            = [[core_striker.png]],
  buildTime           = 550,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext       = [[The Slicers is Core's special assault walker. A few slicers can easily level most fortification lines. In addition, you can't overwhelm it with raiders since its high rate of fire can deal with them easily. Its small range and very low speed make it very vulnerable to skirmishers.]],
    nofriendlyfire = [[1]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[kbotassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 275,
  maxDamage           = 6000,
  maxSlope            = 36,
  maxVelocity         = 1.81,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  objectName          = [[core_striker]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  side                = [[CORE]],
  sightDistance       = 350,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turnRate            = 970,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[Punch]],
      onlyTargetCategory = [[SWIM LAND SUB SINK FLOAT SHIP HOVER]],
    },


    {
      def = [[Shield_SHIELD]],
    },


    {
      def                = [[LaserBlade]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    LaserBlade    = {
      name                    = [[Tachyon Beam]],
      areaOfEffect            = 20,
      beamDecay               = 0.736,
      beamlaser               = 1,
      beamTime                = 0.032,
      beamttl                 = 15,
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 100,
        planes  = 100,
        subs    = 5,
      },

      energypershot           = 0,
      explosionGenerator      = [[custom:LASERBLADESTRIKE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 18.75,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 55,
      reloadtime              = 0.1,
      renderType              = 0,
      rgbColor                = [[1.00 0.1 0.01]],
      soundStart              = [[bladeon1]],
      soundStartVolume        = 1,
      targetMoveError         = 0,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 12.5,
      tolerance               = 10000,
      turret                  = true,
      weaponVelocity          = 1400,
    },


    Punch         = {
      name                    = [[Punch]],
      areaOfEffect            = 8,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 1,
        planes  = 1,
        subs    = 1,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:NONE]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 85,
      reloadtime              = 0.5,
      size                    = 0,
      startsmoke              = [[0]],
      targetborder            = 1,
      tolerance               = 5000,
      turret                  = true,
      waterWeapon             = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },


    Shield_SHIELD = {
      name                    = [[Physical Shield]],
      craterMult              = 0,

      damage                  = {
        default = 10,
      },

      exteriorShield          = true,
      interceptedByShieldType = 1,
      isShield                = true,
      shieldAlpha             = 0.8,
      shieldBadColor          = [[1 1 1]],
      shieldforce             = 10000,
      shieldGoodColor         = [[0.3 0.3 0.3]],
      shieldInterceptType     = 0,
      shieldmaxspeed          = 500,
      shieldPower             = 300,
      shieldPowerRegen        = 25,
      shieldPowerRegenEnergy  = 1,
      shieldRadius            = 22,
      shieldRepulser          = true,
      smartShield             = true,
      visibleShield           = false,
      visibleshieldrepulse    = true,
      weaponType              = [[Shield]],
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Striker]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 6000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[core_striker_DEAD]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Striker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 6000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Striker]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 6000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ core_striker = unitDef })
