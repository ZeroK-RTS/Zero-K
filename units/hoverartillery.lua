unitDef = {
  unitname            = [[hoverartillery]],
  name                = [[Flail]],
  description         = [[Artillery/Skirmish Hover]],
  acceleration        = 0.04,
  bmcode              = [[1]],
  brakeRate           = 0.02,
  buildCostEnergy     = 550,
  buildCostMetal      = 550,
  builder             = false,
  buildPic            = [[hoverartillery.png]],
  buildTime           = 550,
  canAttack           = true,
  canGuard            = true,
  canHover            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[HOVER]],
  corpse              = [[DEAD]],

  customParams        = {
    helptext = [[The Flail's long-ranged missiles have tracking ability, making them good against mobiles and statics alike.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[hoverarty]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 275,
  maxDamage           = 850,
  maxSlope            = 36,
  maxVelocity         = 2.3,
  minCloakDistance    = 75,
  movementClass       = [[HOVER3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[hoverartillery.s3o]],
  onoffable           = true,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:HEAVYHOVERS_ON_GROUND]],
      [[custom:RAIDMUZZLE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 385,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  turninplace         = 0,
  turnRate            = 480,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[WEAPON]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    WEAPON = {
      name                    = [[Cruise Missile]],
      areaOfEffect            = 64,
      cegTag                  = [[raventrail]],
      collideFriendly         = false,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 600,
        planes  = 600,
        subs    = 30,
      },

      edgeEffectiveness       = 0.5,
      explosionGenerator      = [[custom:STARFIRE]],
      fireStarter             = 100,
      fixedlauncher           = true,
      flighttime              = 12,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      metalpershot            = 0,
      model                   = [[hovermissile.s3o]],
      noautorange             = [[1]],
      noSelfDamage            = true,
      range                   = 800,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.1]],
      smokeTrail              = false,
      soundHit                = [[OTAunit/xplomed4]],
      soundStart              = [[OTAunit/Rockhvy1]],
      startsmoke              = [[1]],
      startvelocity           = 100,
      tolerance               = 4000,
      tracks                  = true,
      turnRate                = 17000,
      twoPhase                = true,
      vlaunch                 = true,
      weaponAcceleration      = 200,
      weaponTimer             = 2,
      weaponType              = [[StarburstLauncher]],
      weaponVelocity          = 1000,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Flail]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 850,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[wreck3x3a.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Flail]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 850,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 220,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 220,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Flail]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 850,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      hitdensity       = [[100]],
      metal            = 110,
      object           = [[debris3x3c.s3o]],
      reclaimable      = true,
      reclaimTime      = 110,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ hoverartillery = unitDef })
