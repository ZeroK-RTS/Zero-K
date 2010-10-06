unitDef = {
  unitname            = [[armbrawl_he]],
  name                = [[Brawler HE]],
  description         = [[Heavy Riot Gunship]],
  acceleration        = 0.24,
  amphibious          = true,
  bankscale           = [[1]],
  bmcode              = [[1]],
  brakeRate           = 4.41,
  buildCostEnergy     = 800,
  buildCostMetal      = 800,
  builder             = false,
  buildPic            = [[armbrawl_he.png]],
  buildTime           = 800,
  canAttack           = true,
  canFly              = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  canSubmerge         = false,
  category            = [[GUNSHIP]],
  collide             = false,
  corpse              = [[HEAP]],
  cruiseAlt           = 100,

  customParams        = {
    helptext = [[This variant of the Brawler carries high-explosive EMGs similar to that of the Warrior. Though highly inaccurate, these EMGs boast a high rate of fire and explode in a small radius upon impact, making the Brawler HE a good choice against masses of ground units.]],
  },

  defaultmissiontype  = [[VTOL_standby]],
  explodeAs           = [[GUNSHIPEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  hoverAttack         = true,
  iconType            = [[heavygunship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[1280]],
  mass                = 400,
  maxDamage           = 1500,
  maxVelocity         = 5.7,
  minCloakDistance    = 75,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE GUNSHIP SUB]],
  objectName          = [[ARMBRAWL]],
  scale               = [[1]],
  seismicSignature    = 0,
  selfDestructAs      = [[GUNSHIPEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:brawlermuzzle]],
      [[custom:emg_shells_m]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 480,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[VTOL]],
  turnRate            = 792,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMG]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    EMG = {
      name                    = [[HE EMG]],
      areaOfEffect            = 84,
      avoidFeature            = false,
      burst                   = 4,
      burstrate               = 0.1,
      collideFriendly         = false,
      craterBoost             = 0.15,
      craterMult              = 0.3,

      damage                  = {
        default = 40,
        planes  = 4,
        subs    = 2,
      },

      edgeEffectiveness       = 0.5,
      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT_HE]],
      firestarter             = 70,
      impulseBoost            = 0,
      impulseFactor           = 0.2,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noSelfDamage            = true,
      pitchtolerance          = 12000,
      range                   = 380,
      reloadtime              = 0.4,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.5]],
      soundHit                = [[OTAunit/XPLOSML3]],
      soundStart              = [[brawlemg]],
      sprayAngle              = 4096,
      startsmoke              = [[0]],
      sweepfire               = false,
      tolerance               = 6000,
      turret                  = false,
      weaponTimer             = 1,
      weaponType              = [[Cannon]],
      weaponVelocity          = 450,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Brawler HE]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[40]],
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[ARMHAM_DEAD]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Brawler HE]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 320,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 320,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Brawler HE]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 160,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 160,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armbrawl_he = unitDef })
