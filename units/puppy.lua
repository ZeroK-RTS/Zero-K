unitDef = {
  unitname               = [[corroach]],
  name                   = [[Puppy]],
  description            = [[Walking Missile]],
  acceleration           = 0.12,
  activateWhenBuilt      = true,
  bmcode                 = [[1]],
  brakeRate              = 0.16,
  buildCostEnergy        = 50,
  buildCostMetal         = 50,
  builder                = false,
  buildPic               = [[PUPPY.png]],
  buildTime              = 50,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[LAND]],
  collisionVolumeOffsets = [[0 -1 0]],
  collisionVolumeScales  = [[20 20 20]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],

  customParams           = {
    description_bp = [[Bomba rastejante]],
    description_es = [[Bomba móvil]],
    description_fr = [[Bombe Rampante]],
    description_it = [[Bomba mobile]],
    helptext       = [[This fast-moving suicide unit is good for raiding and sniping lightly-armored targets. When standing next to wreckages, it automatically draws metal from them to replicate itself, grey goo style.]],
    helptext_bp    = [[Essa rápida unidade suicida é muito boa contra unidades agrupadas, particularmente tanques de assalto. Explode em cadeia com muita facilidade, ent?o é melhor n?o agrupalas. Defenda-se com defenders ou caminh?es de mísseis, ou com uma única unidade barata para ativar uma explos?o pre-matura.]],
    helptext_es    = [[Esta rápida unidad suicaida es buena contra masas de unidades, especialmente carros armados de asalte. Explotan a cadena terribilmente, asi que es mejor no amasarlas. Contrastalas con torres o carros de misil o síngolas unidades baratas para causar detonaciones inmaduras.]],
    helptext_fr    = [[Le Roach est une unité suicide ultra-rapide. Il est indispensable de savoir la manier pour se débarrasser rapidement des nuées ennemies. Des unités lance-missiles ou tirant avec précision pouront cependant le faire exploser prématurément.]],
    helptext_it    = [[Questa veloce unitá suicida é buona contro unitá ammassate, specialmente carri armati d'assalto. Esplode a catena terribilmente, sicche é meglio non ammassarle. Contrastale con carri o torri lancia-razzi o singole unitá economiche per provocare una detonazione prematura.]],
  },

  defaultmissiontype     = [[Standby]],
  explodeAs              = [[TINY_BUILDINGEX]],
  footprintX             = 2,
  footprintZ             = 2,
  iconType               = [[kbotbomb]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[640]],
  mass                   = 66,
  maxDamage              = 120,
  maxSlope               = 36,
  maxVelocity            = 3.6,
  maxWaterDepth          = 15,
  minCloakDistance       = 75,
  movementClass          = [[KBOT2]],
  noAutoFire             = false,
  noChaseCategory        = [[FIXEDWING LAND SINK SHIP SATELLITE SWIM GUNSHIP FLOAT SUB HOVER]],
  objectName             = [[puppy.s3o]],
  pushResistant          = 1,
  seismicSignature       = 4,
  selfDestructAs         = [[TINY_BUILDINGEX]],
  selfDestructCountdown  = 0,

  sfxtypes               = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:VINDIBACK]],
      [[custom:digdig]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 425,
  smoothAnim             = true,
  steeringmode           = [[1]],
  TEDClass               = [[KBOT]],
  turninplace            = 0,
  turnRate               = 1507,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    MISSILE = {
      name                    = [[Legless Puppy]],
      areaOfEffect            = 32,
      cegTag                  = [[VINDIBACK]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 410,
        planes  = 410,
        subs    = 15,
      },

      fireStarter             = 70,
      fixedlauncher           = 1,
      flightTime              = 0.8,
      guidance                = true,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[puppymissile.s3o]],
      noSelfDamage            = true,
      range                   = 190,
      reloadtime              = 1,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = false,
      soundHit                = [[explosion/ex_med5]],
      soundHitVolume          = 8,
      soundStart              = [[weapon/missile/sabot_fire]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 300,
      tracks                  = true,
      turnRate                = 56000,
      turret                  = true,
      weaponAcceleration      = 300,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs            = {

    DEAD  = {
      description      = [[Debris - Puppy]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 190,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 25,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 25,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Puppy]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 190,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 25,
      object           = [[debris1x1a.s3o]],
      reclaimable      = true,
      reclaimTime      = 25,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ puppy = unitDef })
