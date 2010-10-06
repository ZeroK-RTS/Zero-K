unitDef = {
  unitname            = [[logsiren]],
  name                = [[Siren]],
  description         = [[Anti-Air Gunboat]],
  acceleration        = 0.084,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.019,
  buildAngle          = 16384,
  buildCostEnergy     = 215,
  buildCostMetal      = 215,
  builder             = false,
  buildPic            = [[logsiren.png]],
  buildTime           = 215,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[The Siren is a cheap, dependable solution to enemy air raids. It packs a short-range, rapid-fire surface-to-air missile launcher on a fast, durable hull.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[aaboat]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 107.5,
  maxDamage           = 1200,
  maxVelocity         = 3.6,
  minCloakDistance    = 75,
  minWaterDepth       = 5,
  movementClass       = [[BOAT3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[logsiren.s3o]],
  scale               = [[0.5]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:STORMMUZZLE]],
      [[custom:STORMBACK]],
      [[custom:WhiteLight]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[SHIP]],
  turnRate            = 500,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[SIREN_MISSILE]],
      badTargetCategory  = [[GUNSHIP]],
      onlyTargetCategory = [[FIXEDWING GUNSHIP]],
    },

  },


  weaponDefs          = {

    SIREN_MISSILE = {
      name                    = [[Light SAM]],
      areaOfEffect            = 48,
      canattackground         = false,
      craterBoost             = 1,
      craterMult              = 2,
      cylinderTargetting      = 1,

      damage                  = {
        default = 10,
        planes  = 100,
        subs    = 5,
      },

      explosionGenerator      = [[custom:FLASH2]],
      fireStarter             = 70,
      flightTime              = 3,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[wep_m_fury.s3o]],
      noSelfDamage            = true,
      range                   = 760,
      reloadtime              = 1,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOSML2]],
      soundStart              = [[OTAunit/ROCKLIT1]],
      startsmoke              = [[1]],
      startVelocity           = 650,
      tolerance               = 9000,
      tracks                  = true,
      turnRate                = 63000,
      turret                  = true,
      weaponAcceleration      = 141,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 850,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Siren]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 86,
      object           = [[CORESUPP_DEAD]],
      reclaimable      = true,
      reclaimTime      = 86,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Siren]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 86,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 86,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Siren]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1200,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 43,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 43,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ logsiren = unitDef })
