unitDef = {
  unitname            = [[armfido]],
  name                = [[Fido]],
  description         = [[Artillery/Skirmish Walker]],
  acceleration        = 0.12,
  activateWhenBuilt   = false,
  bmcode              = [[1]],
  brakeRate           = 0.375,
  buildCostEnergy     = 320,
  buildCostMetal      = 320,
  builder             = false,
  buildPic            = [[ARMFIDO.png]],
  buildTime           = 320,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Robô escaramuçador ou de artilharia]],
    description_fr = [[Marcheur Artillerie/Tirailleur]],
    helptext       = [[Fast and cheap, Fido excels against assault units by shooting them from outside of their range.]],
    helptext_bp    = [[Fido é um escaramuçador rápido e barato. Use-o contra unidades de assalto atirando nelas de fora de seu alcançe.]],
    helptext_fr    = [[Rapide et peux couteux, le Fido excelle contre les unités d'assaut en les attaquan de loin.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[kbotskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 160,
  maxDamage           = 1150,
  maxSlope            = 36,
  maxVelocity         = 2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[KBOT2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[ARMFIDO]],
  onoffable           = false,
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],
  side                = [[ARM]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[2]],
  TEDClass            = [[KBOT]],
  turnRate            = 990,
  upright             = false,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },


    {
      def                = [[BFIDO]],
      onlyTargetCategory = [[SWIM LAND SINK FLOAT SHIP HOVER]],
    },

  },


  weaponDefs          = {

    BFIDO  = {
      name                    = [[BallisticCannon]],
      areaOfEffect            = 80,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 335,
        planes  = 335,
        subs    = 16.75,
      },

      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      minbarrelangle          = [[-15]],
      noSelfDamage            = true,
      range                   = 620,
      reloadtime              = 3.5,
      renderType              = 4,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/CANNON1]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 275,
    },


    PLASMA = {
      name                    = [[Plasma Cannon]],
      accuracy                = 200,
      areaOfEffect            = 5,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 160,
        planes  = 160,
        subs    = 8,
      },

      explosionGenerator      = [[custom:INGEBORG]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      minbarrelangle          = [[-15]],
      movingAccuracy          = 400,
      noSelfDamage            = true,
      range                   = 620,
      reloadtime              = 2,
      renderType              = 4,
      soundHit                = [[OTAunit/XPLOMED2]],
      soundStart              = [[OTAunit/CANNHVY1]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 350,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Fido]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1150,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[ARMFIDO_DEAD]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Fido]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1150,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 128,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 128,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Fido]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1150,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 64,
      object           = [[debris2x2a.s3o]],
      reclaimable      = true,
      reclaimTime      = 64,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armfido = unitDef })
