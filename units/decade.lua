unitDef = {
  unitname            = [[decade]],
  name                = [[Decade]],
  description         = [[Corvette (Assault/Raider)]],
  acceleration        = 0.084,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.019,
  buildAngle          = 16384,
  buildCostEnergy     = 320,
  buildCostMetal      = 320,
  builder             = false,
  buildPic            = [[DECADE.png]],
  buildTime           = 320,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Corvette d'Assaut/Pillage]],
    helptext       = [[This Corvette combines high speed, decent armor, and strong firepower at a low cost--for a ship. Use Corvette packs against anything on the surface, but watch out for submarine attacks.]],
    helptext_fr    = [[Cette Corvette combine une grande vitesse, un blindage d?cent et une forte puissance de feu. Reine des mers, elle est cependant vuln?rable aux attaques sous-marines. ]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[corvette]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 160,
  maxDamage           = 2145,
  maxVelocity         = 4,
  minCloakDistance    = 75,
  minWaterDepth       = 5,
  movementClass       = [[BOAT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[DECADE]],
  scale               = [[0.5]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 429,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[SHIP]],
  turninplace         = 0,
  turnRate            = 509,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      mainDir            = [[0 0 1]],
      maxAngleDif        = 290,
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[EMG]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

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
      soundStart              = [[flashemg]],
      sprayAngle              = 1180,
      startsmoke              = [[0]],
      tolerance               = 5000,
      turret                  = true,
      weaponTimer             = 0.1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Decade]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 2145,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[DECADE_DEAD]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Decade]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2145,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Decade]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 2145,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ decade = unitDef })
