unitDef = {
  unitname            = [[corstorm]],
  name                = [[Rogue]],
  description         = [[Skirmisher Bot (Indirect Fire)]],
  acceleration        = 0.108,
  bmcode              = [[1]],
  brakeRate           = 0.188,
  buildCostEnergy     = 120,
  buildCostMetal      = 120,
  builder             = false,
  buildPic            = [[CORSTORM.png]],
  buildTime           = 120,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô escaramuçador]],
    description_fr = [[Robot Tirailleur]],
    helptext       = [[The Rogue's arcing missiles have a low rate of fire, but do a lot of damage, making it very good at dodging in and out of range of enemy units or defense, or in a powerful initial salvo. Counter them by attacking them with fast units, or crawling bombs when massed.]],
    helptext_bp    = [[O Rogue é um robô escaramuçador. Seus mísseis com trajetória verticalmente curva tem uma baixa velocidade de disparo, mas causam muito dano, tornando-o muito bom em mover-se para dentro e para fora do alcançe das unidades ou defesas inimigas, ou causar grande dano na aproximaç?o inicial. Defenda-se dele atacando-o com unidades rápidas ou com bombas rastejantes se estiverem juntos.]],
    helptext_fr    = [[Le Rogue est un tirailleur typique: longue port?e, cadence de tir lente et faible blindage. Ces deux puissants missiles ? t?tes chercheuse sont tr?s puissant mais cette unit? doit fuir le corps ? corps ? tout prix.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkerskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 124,
  maxDamage           = 570,
  maxSlope            = 36,
  maxVelocity         = 1.95,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[storm.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 523,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  trackOffset         = 0,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[ComTrack]],
  trackWidth          = 22,
  turninplace         = 0,
  turnRate            = 1103,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[STORM_ROCKET]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    STORM_ROCKET = {
      name                    = [[Heavy Rocket]],
      areaOfEffect            = 68,
      cegTag                  = [[missiletrailred]],
      craterBoost             = 0,
      craterMult              = 2,

      damage                  = {
        default = 280,
        planes  = 280,
        subs    = 16.25,
      },

      fireStarter             = 70,
      flightTime              = 16,
      guidance                = false,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[wep_m_hailstorm.s3o]],
      noSelfDamage            = true,
      predictBoost            = 1,
      range                   = 520,
      reloadtime              = 7,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[explosion/ex_med4]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/missile2_fire_bass]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 170,
      texture2                = [[darksmoketrail]],
      tracks                  = false,
      trajectoryHeight        = 0.6,
      turret                  = true,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 170,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Rogue]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 570,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 48,
      object           = [[wreck2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 48,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Rogue]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 570,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 48,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 48,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Rogue]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 570,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 24,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 24,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corstorm = unitDef })
