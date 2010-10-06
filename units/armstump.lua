unitDef = {
  unitname            = [[armstump]],
  name                = [[Stumpy]],
  description         = [[Assault Vehicle]],
  acceleration        = 0.04,
  bmcode              = [[1]],
  brakeRate           = 0.02,
  buildCostEnergy     = 180,
  buildCostMetal      = 180,
  builder             = false,
  buildPic            = [[ARMSTUMP.png]],
  buildTime           = 180,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Veículo de assalto]],
    description_fr = [[V?hicule d'Assault]],
    description_pl = [[Pojazd Szturmowy]],
    helptext       = [[The Stumpy is a manouverable all-rounder with an arcing projectile which allows it to shoot over corpses or other units. Vulnerable to crawling bombs.]],
    helptext_bp    = [[Stumpy é um veículo de assalto manobrável e versátil que dispara projéteis com ângulo tal que possibilita atirar sobre obstáculos sem perder a capacidade de acertar unidades móveis. ? vulnerável a bombas rastejantes.]],
    helptext_fr    = [[Le Stumpy est un tank maniable et basic avec un arc de tir ?lev?, lui permettant de tirer au dessus des carcasses et autre unit?s. Il est vuln?rable au bombes rampantes.]],
    helptext_pl    = [[Stumpy to ?redni pojazd szturmowy posiadaj?cy jednocze?nie zwrotno?? l?ejszych pojazd?w i pancerz szturmowych czo?g?w. Jego dzia?o strzela ponad sprzymierzonymi jednostkami i niskimi przeszkodami. ?atwo pada ofiar? pe?zaj?cym bombom.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[vehicleassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 90,
  maxDamage           = 1500,
  maxSlope            = 18,
  maxVelocity         = 2.8,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[lynx.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:RAIDMUZZLE]],
      [[custom:STOMPSHELLS]],
      [[custom:STOMPDUST]],
      [[custom:STOMPOLLUTE]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 385,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  trackOffset         = 3,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 24,
  turninplace         = 0,
  turnRate            = 550,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[PLASMA]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    PLASMA = {
      name                    = [[Light Plasma Cannon]],
      areaOfEffect            = 32,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 99.5,
        planes  = 99.5,
        subs    = 5.25,
      },

      explosionGenerator      = [[custom:INGEBORG]],
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 340,
      reloadtime              = 1.19,
      renderType              = 4,
      soundHit                = [[OTAunit/XPLOSML3]],
      soundStart              = [[OTAunit/CANLITE3]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 230,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Stumpy]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 1500,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 72,
      object           = [[lynx_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 72,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Stumpy]],
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
      metal            = 72,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 72,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Stumpy]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1500,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 36,
      object           = [[debris2x2c.s3o]],
      reclaimable      = true,
      reclaimTime      = 36,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armstump = unitDef })
