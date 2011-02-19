unitDef = {
  unitname               = [[coresupp]],
  name                   = [[Typhoon]],
  description            = [[Corvette (Assault/Raider)]],
  acceleration           = 0.0768,
  activateWhenBuilt      = true,
  bmcode                 = [[1]],
  brakeRate              = 0.042,
  buildAngle             = 16384,
  buildCostEnergy        = 320,
  buildCostMetal         = 320,
  builder                = false,
  buildPic               = [[CORESUPP.png]],
  buildTime              = 320,
  canAttack              = true,
  canGuard               = true,
  canMove                = true,
  canPatrol              = true,
  canstop                = [[1]],
  category               = [[SHIP]],
  collisionVolumeOffsets = [[0 4 -2]],
  collisionVolumeScales  = [[27 36 104]],
  collisionVolumeTest    = 1,
  collisionVolumeType    = [[ellipsoid]],
  corpse                 = [[DEAD]],

  customParams           = {
    description_fr = [[Corvette d'Assaut/Pillage]],
	description_de = [[Korvette (Sturmangriff/Raider)]],
    helptext       = [[The Typhoon is a brawler, combining high speed, decent armor, and strong firepower at a low cost--for a ship. Use corvette packs against anything on the surface, but watch out for submarine attacks.]],
    helptext_fr    = [[La corvette est ? la fois bon-march? et rapide. Son blindage moyen et sa forte puissance de feu laser en font un bon compromis, mais est vuln?rable aux attaques sousmarines. ]],
	helptext_de    = [[Der Typhoon ist ein Streithahn, der hohe Geschwindigkeite, anständige Panzerung und starke Feuerkraft zu geringen Kosten für ein Schiff verbindet. Nutze Korvetten gegen alles auf der Oberfläche, achte aber auf feindliche U-Boot-Angriffe.]],
  },

  defaultmissiontype     = [[Standby]],
  explodeAs              = [[BIG_UNITEX]],
  floater                = true,
  footprintX             = 3,
  footprintZ             = 3,
  iconType               = [[corvette]],
  idleAutoHeal           = 5,
  idleTime               = 1800,
  maneuverleashlength    = [[640]],
  mass                   = 237,
  maxDamage              = 2400,
  maxVelocity            = 3.5,
  minCloakDistance       = 75,
  minWaterDepth          = 5,
  movementClass          = [[BOAT3]],
  noAutoFire             = false,
  noChaseCategory        = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName             = [[vette.s3o]],
  scale                  = [[0.5]],
  seismicSignature       = 4,
  selfDestructAs         = [[BIG_UNITEX]],

  sfxtypes               = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_l]],
    },

  },

  side                   = [[CORE]],
  sightDistance          = 429,
  smoothAnim             = true,
  steeringmode           = [[1]],
  TEDClass               = [[SHIP]],
  turninplace            = 0,
  turnRate               = 571,
  workerTime             = 0,

  weapons                = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 300,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 320,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs             = {

    EMG = {
      name                    = [[Medium Pulse MG]],
      areaOfEffect            = 64,
      burst                   = 4,
      burstrate               = 0.1,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      damage                  = {
        default = 10,
        planes  = 10,
        subs    = 5,
      },

      edgeEffectiveness       = 0.5,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 270,
      reloadtime              = 0.4,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.4]],
      soundHit                = [[weapon/cannon/emg_hit]],
      soundStart              = [[weapon/emg]],
      sprayAngle              = 1180,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs            = {

    DEAD = {
      description      = [[Wreckage - Typhoon]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 2400,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[vette_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP = {
      description      = [[Debris - Typhoon]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2400,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ coresupp = unitDef })
