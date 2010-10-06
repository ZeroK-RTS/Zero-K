unitDef = {
  unitname            = [[coramph]],
  name                = [[Gimp]],
  description         = [[Torpedo Amph]],
  acceleration        = 0.09,
  activateWhenBuilt   = true,
  amphibious          = [[1]],
  bmcode              = [[1]],
  brakeRate           = 0.188,
  buildCostEnergy     = 450,
  buildCostMetal      = 450,
  builder             = false,
  buildPic            = [[CORAMPH.png]],
  buildTime           = 450,
  canAttack           = true,
  canDGun             = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Amphibien Lance Torpille]],
    helptext       = [[The Gimp is a light amphib, capable of fighting both in and out of the water. On the surface, it attacks enemies with its lasers; underwater, it puts its torpedoes to good use.]],
    helptext_fr    = [[Le Gimp est un amphibien multifonction. Lance-torpille sous l'eau, laser sur terre, il sait se d?fendre partout, mais son blindage ne lui permet pas d'?tre une unit? d'assaut principale.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[kbotassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 225,
  maxDamage           = 1000,
  maxSlope            = 36,
  maxVelocity         = 2.2,
  maxWaterDepth       = 5000,
  minCloakDistance    = 75,
  movementClass       = [[AKBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE]],
  objectName          = [[CORAMPH]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:BEAMWEAPON_MUZZLE_ORANGE]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 440,
  smoothAnim          = true,
  sonarDistance       = 300,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turninplace         = 0,
  turnRate            = 998,
  upright             = true,
  workerTime          = 0,

  weapons             = {

    [1] = {
      def                = [[LASER]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    [3] = {
      def                = [[TORPEDO]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[SWIM FIXEDWING LAND SUB SINK FLOAT SHIP GUNSHIP]],
    },

  },


  weaponDefs          = {

    LASER   = {
      name                    = [[Heavy Laser]],
      areaOfEffect            = 8,
      beamWeapon              = true,
      canattackground         = true,
      cegTag                  = [[orangelaser]],
      coreThickness           = 0.5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 30,
        planes  = 30,
        subs    = 1.5,
      },

      duration                = 0.03,
      energypershot           = 0.3,
      explosionGenerator      = [[custom:BEAMWEAPON_HIT_ORANGE]],
      fireStarter             = 90,
      heightMod               = 1,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      lodDistance             = 10000,
      noSelfDamage            = true,
      range                   = 300,
      reloadtime              = 0.2,
      renderType              = 0,
      rgbColor                = [[1 0.25 0]],
      soundHit                = [[medlaserhit]],
      soundStart              = [[OTAunit/LASRHVY3]],
      targetMoveError         = 0.2,
      thickness               = 3.87298334620742,
      tolerance               = 10000,
      turret                  = true,
      weaponType              = [[LaserCannon]],
      weaponVelocity          = 1200,
    },


    TORPEDO = {
      name                    = [[Torpedo]],
      areaOfEffect            = 16,
      avoidFriendly           = false,
      burnblow                = true,
      collideFriendly         = false,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 180,
        subs    = 180,
      },

      explosionGenerator      = [[custom:TORPEDO_HIT]],
      guidance                = true,
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      model                   = [[torpedo]],
      noSelfDamage            = true,
      propeller               = [[1]],
      range                   = 400,
      reloadtime              = 4,
      renderType              = 1,
      selfprop                = true,
      soundHit                = [[OTAunit/XPLODEP1]],
      soundStart              = [[OTAunit/TORPEDO1]],
      startVelocity           = 100,
      tolerance               = 32000,
      tracks                  = true,
      turnRate                = 16000,
      turret                  = false,
      waterWeapon             = true,
      weaponAcceleration      = 50,
      weaponTimer             = 4,
      weaponType              = [[TorpedoLauncher]],
      weaponVelocity          = 200,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Gimp]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Gimp]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Gimp]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1000,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      hitdensity       = [[100]],
      metal            = 90,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 90,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ coramph = unitDef })
