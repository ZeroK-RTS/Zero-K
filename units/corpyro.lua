unitDef = {
  unitname              = [[corpyro]],
  name                  = [[Pyro]],
  description           = [[Raider Jumpjet Walker]],
  acceleration          = 0.3,
  bmcode                = [[1]],
  brakeRate             = 0.45,
  buildCostEnergy       = 220,
  buildCostMetal        = 220,
  builder               = false,
  buildPic              = [[CORPYRO.png]],
  buildTime             = 220,
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[LAND FIREPROOF]],
  corpse                = [[DEAD]],

  customParams          = {
    canjump        = [[1]],
    description_es = [[Invasor Caminante Jumpjet]],
    description_fr = [[Marcheur Pilleur r Jetpack]],
    description_it = [[Invasore Camminatore Jumpjet]],
    fireproof      = [[1]],
    helptext       = [[The Pyro is a cheap, fast walker with a flamethrower. The flamethrower deals incredible damage to large targets but little damage to small ones. It can hit multiple targets at the same time. The Pyro explodes violently when it is destroyed. The Pyro's weapons set targets aflame. Additionally, Pyros also come with jetpacks, allowing them to jump over obstacles or get the drop on enemies.]],
    helptext_es    = [[El Pyro es un invasor caminante barato con un lanzallamas. El lanzallamas hace mucho da?o a unidades grandes, pero poco da?o a las peque?as. Puede da?ar multiples enemigos a la vez. El Pyro explota violentemente cuando es destruido. Sus armas queman a los enemigos. El Pyro viene con jumpjets, que le permiten brincar sobre obstáculos y aterrizar cerca de los enemigos.]],
    helptext_fr    = [[Le Pyro est un marcheur facile r produire et rapide. Son lanceflamme fait des ravage au corps r corps et son jetpack lui permet des attaques par des angles surprenants. Les dommages sont plus ?lev?s sur les cibles de gros calibres comme les b?timents, et il peut tirer sur plusieurs cibles r la fois. Attention cependant r ne pas les grouper, car le Pyro explose fortement et peut entrainer une r?action en chaine.]],
    helptext_it    = [[Il Pyro é un camminatore veloce ed economico con un lanciafiamme. Il lanciafiamme fa un danno incredibile alle unita grandi, ma poco a quelle piccole. Puo colpire molte cose alla stessa volta. Il Pyro esplode violentamente quando é distrutto. Le armi del Pyro bruciano i nemici. Il Pyro viene con jumpjets, che gli permettono di saltare sopra gli ostacoli e atterrare vicino ai nemici.]],
  },

  defaultmissiontype    = [[Standby]],
  explodeAs             = [[CORPYRO_NAPALM]],
  footprintX            = 2,
  footprintZ            = 2,
  iconType              = [[jumpjetraider]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  leaveTracks           = true,
  maneuverleashlength   = [[640]],
  mass                  = 157,
  maxDamage             = 700,
  maxSlope              = 36,
  maxVelocity           = 2.95,
  maxWaterDepth         = 22,
  minCloakDistance      = 75,
  movementClass         = [[KBOT2]],
  noAutoFire            = false,
  noChaseCategory       = [[FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName            = [[m-5.s3o]],
  seismicSignature      = 4,
  selfDestructAs        = [[CORPYRO_NAPALM]],
  selfDestructCountdown = 1,

  sfxtypes              = {

    explosiongenerators = {
      [[custom:PILOT]],
      [[custom:PILOT2]],
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
    },

  },

  side                  = [[CORE]],
  sightDistance         = 318,
  smoothAnim            = true,
  steeringmode          = [[2]],
  TEDClass              = [[KBOT]],
  trackOffset           = 0,
  trackStrength         = 8,
  trackStretch          = 1,
  trackType             = [[ComTrack]],
  trackWidth            = 22,
  turninplace           = 0,
  turnRate              = 1145,
  upright               = true,
  workerTime            = 0,

  weapons               = {

    {
      def                = [[FLAMETHROWER]],
      badTargetCategory  = [[FIREPROOF]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER GUNSHIP FIXEDWING]],
    },

  },


  weaponDefs            = {

    FLAMETHROWER = {
      name                    = [[Flame Thrower]],
      areaOfEffect            = 64,
      avoidFeature            = false,
      collideFeature          = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 7,
        planes  = 7,
        subs    = 0.0015,
      },

      explosionGenerator      = [[custom:SMOKE]],
      fireStarter             = 100,
      flameGfxTime            = 1.6,
      impulseBoost            = 0,
      impulseFactor           = 0,
      intensity               = 0.1,
      interceptedByShieldType = 0,
      lineOfSight             = true,
      noExplode               = true,
      noSelfDamage            = true,
      range                   = 280,
      reloadtime              = 0.16,
      renderType              = 5,
      sizeGrowth              = 1.05,
      soundStart              = [[weapon/flamethrower]],
      soundTrigger            = true,
      sprayAngle              = 50000,
      tolerance               = 2500,
      turret                  = true,
      weaponType              = [[Flame]],
      weaponVelocity          = 800,
    },

  },


  featureDefs           = {

    DEAD  = {
      description      = [[Wreckage - Pyro]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Pyro]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Pyro]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 700,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 44,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corpyro = unitDef })
