unitDef = {
  unitname              = [[coresupp]],
  name                  = [[Typhoon]],
  description           = [[Corvette (Assault/Raider)]],
  acceleration          = 0.0768,
  activateWhenBuilt     = true,
  bmcode                = [[1]],
  brakeRate             = 0.042,
  buildAngle            = 16384,
  buildCostEnergy       = 320,
  buildCostMetal        = 320,
  builder               = false,
  buildPic              = [[CORESUPP.png]],
  buildTime             = 320,
  canAttack             = true,
  canGuard              = true,
  canMove               = true,
  canPatrol             = true,
  canstop               = [[1]],
  category              = [[SHIP]],
  collisionVolumeOffset = [[0 20 -20]],
  collisionVolumeScales = [[30 35 110]],
  collisionVolumeTest   = 1,
  collisionVolumeType   = [[box]],
  corpse                = [[DEAD]],

  customParams          = {
    description_fr = [[Corvette d'Assaut/Pillage]],
    helptext       = [[The Typhoon is a brawler, combining high speed, decent armor, and strong firepower at a low cost--for a ship. Use corvette packs against anything on the surface, but watch out for submarine attacks.]],
    helptext_fr    = [[La corvette est ? la fois bon-march? et rapide. Son blindage moyen et sa forte puissance de feu laser en font un bon compromis, mais est vuln?rable aux attaques sousmarines. ]],
  },

  defaultmissiontype    = [[Standby]],
  explodeAs             = [[BIG_UNITEX]],
  floater               = true,
  footprintX            = 3,
  footprintZ            = 3,
  iconType              = [[corvette]],
  idleAutoHeal          = 5,
  idleTime              = 1800,
  maneuverleashlength   = [[640]],
  mass                  = 237,
  maxDamage             = 2210,
  maxVelocity           = 3.4,
  minCloakDistance      = 75,
  minWaterDepth         = 5,
  movementClass         = [[BOAT3]],
  noAutoFire            = false,
  noChaseCategory       = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName            = [[vette.s3o]],
  scale                 = [[0.5]],
  seismicSignature      = 4,
  selfDestructAs        = [[BIG_UNITEX]],

  sfxtypes              = {

    explosiongenerators = {
      [[custom:flashmuzzle1]],
    },

  },

  side                  = [[CORE]],
  sightDistance         = 429,
  smoothAnim            = true,
  steeringmode          = [[1]],
  TEDClass              = [[SHIP]],
  turninplace           = 0,
  turnRate              = 571,
  workerTime            = 0,

  weapons               = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 -1]],
      maxAngleDif        = 290,
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


  weaponDefs            = {

    EMG = {
      name                    = [[EMG]],
      areaOfEffect            = 8,
      burst                   = 2,
      burstrate               = 0.12,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 7,
        planes  = 7,
        subs    = 0.35,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      range                   = 270,
      reloadtime              = 0.16,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.4]],
      size                    = 1.75,
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


  featureDefs           = {

    DEAD  = {
      description      = [[Wreckage - Supporter]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 2210,
      energy           = 0,
      featureDead      = [[DEAD2]],
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


    DEAD2 = {
      description      = [[Debris - Supporter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2210,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[debris4x4a.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Supporter]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2210,
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
