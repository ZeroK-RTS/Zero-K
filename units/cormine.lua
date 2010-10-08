unitDef = {
  unitname            = [[cormine]],
  name                = [[Porcupine]],
  description         = [[Minelaying artillery vehicle]],
  acceleration        = 0.03,
  bmcode              = [[1]],
  brakeRate           = 0.012,
  buildCostEnergy     = 320,
  buildCostMetal      = 320,
  builder             = false,
  buildPic            = [[CORMIST.png]],
  buildTime           = 320,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[Keep the Slasher at maximum range to harass the opponent's units. The Slasher's missiles track, so they are ideal to kill fast-moving crawling bombs. It is able to hit both air and land, allowing you to counter an enemy who is using both. Cannot fire over terraform walls, and does poorly if an enemy is allowed to close range.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[vehiclesupport]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 160,
  maxDamage           = 800,
  maxSlope            = 18,
  maxVelocity         = 1,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[cormine.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:wolvmuzzle1]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  trackOffset         = -6,
  trackStrength       = 5,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 30,
  turnInPlace         = 0,
  turnRate            = 400,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[CORTRUCK_MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    CORTRUCK_MISSILE = {
      name                    = [[Missiles]],
      areaOfEffect            = 48,
      burst                   = 10,
      burstrate               = 0.58,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 0.1,
        subs    = 1.68,
      },

      explosionGenerator      = [[custom:MEDMISSILE_EXPLOSION]],
      fireStarter             = 10,
      flightTime              = 4,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[corbanishrk.s3o]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 16,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.8]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[golgotha/ground_vehicle]],
      startsmoke              = [[1]],
      startVelocity           = 350,
      tolerance               = 8000,
      tracks                  = true,
      trajectoryHeight        = 2.8,
      turnRate                = 3000,
      turret                  = true,
      weaponAcceleration      = 109,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 145,
      wobble                  = 7500,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Porcupine]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 800,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[cormist_dead_new.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Porcupine]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 800,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Porcupine]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 800,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ cormine = unitDef })
