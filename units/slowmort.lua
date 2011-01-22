unitDef = {
  unitname            = [[slowmort]],
  name                = [[Moderator]],
  description         = [[Slowbeam Walker]],
  acceleration        = 0.132,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.2275,
  buildCostEnergy     = 280,
  buildCostMetal      = 280,
  builder             = false,
  buildPic            = [[CORMORT.png]],
  buildTime           = 280,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô escaramuçador]],
    description_fr = [[Marcheur Tirailleur]],
    helptext       = [[The Moderator's slow-ray reduces enemy speed and rate of fire by up to two-thirds. Though doing no damage themselves, Morties are effective against almost all targets.]],
    helptext_bp    = [[Moderator é um escaramuçador barato e rápido. Tem maior alcançe que defesas leves com torres de laser leves, mas é vulnerável a grupos de agressores.]],
    helptext_fr    = [[Le Moderator offre des capacités de tirailleur idéales pour un prix réduit. Son canon plasma lui permet une longue portée pour une cadence de tir honorable. Il pourra détruire la plupart des tourelles sans risquer d'y laisser sa carcasse. ]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[walkersupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 164,
  maxDamage           = 550,
  maxSlope            = 36,
  maxVelocity         = 1.8,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[CORMORT.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turninplace         = 0,
  turnRate            = 1099,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SLOWBEAM]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    SLOWBEAM = {
      name                    = [[Slowing Beam]],
      areaOfEffect            = 8,
      beamDecay               = 0.9,
      beamlaser               = 1,
      beamTime                = 0.1,
      beamttl                 = 40,
      coreThickness           = 0,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 50,
      },

      explosionGenerator      = [[custom:flash2purple]],
      fireStarter             = 30,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      largeBeamLaser          = true,
      laserFlareSize          = 4,
      lineOfSight             = true,
      minIntensity            = 1,
      noSelfDamage            = true,
      range                   = 600,
      reloadtime              = 1,
      renderType              = 0,
      rgbColor                = [[0.3 0 0.4]],
      soundStart              = [[weapon/laser/pulse_laser2]],
      soundStartVolume        = 0.9,
      soundTrigger            = true,
      sweepfire               = false,
      texture1                = [[largelaser]],
      texture2                = [[flare]],
      texture3                = [[flare]],
      texture4                = [[smallflare]],
      thickness               = 8,
      tolerance               = 18000,
      turret                  = true,
      weaponType              = [[BeamLaser]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Morty]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 550,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 112,
      object           = [[CORMORT_DEAD.s3o]],
      reclaimable      = true,
      reclaimTime      = 112,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description = [[Debris - Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 550,
      energy      = 0,
      featureDead = [[HEAP]],
      footprintX  = 2,
      footprintZ  = 2,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 112,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 112,
      world       = [[All Worlds]],
    },


    HEAP  = {
      description = [[Debris - Morty]],
      blocking    = false,
      category    = [[heaps]],
      damage      = 550,
      energy      = 0,
      footprintX  = 2,
      footprintZ  = 2,
      height      = [[4]],
      hitdensity  = [[100]],
      metal       = 56,
      object      = [[debris2x2a.s3o]],
      reclaimable = true,
      reclaimTime = 56,
      world       = [[All Worlds]],
    },

  },

}

return lowerkeys({ slowmort = unitDef })
