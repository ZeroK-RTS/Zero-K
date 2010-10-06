unitDef = {
  unitname            = [[armflash]],
  name                = [[Flash]],
  description         = [[Raider Vehicle]],
  acceleration        = 0.06,
  bmcode              = [[1]],
  brakeRate           = 0.065,
  buildCostEnergy     = 100,
  buildCostMetal      = 100,
  builder             = false,
  buildPic            = [[ARMFLASH.png]],
  buildTime           = 100,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Veículo agressor]],
    description_fr = [[Véhicule Pilleur]],
    helptext       = [[The Flash does a lot of damage, but cant take much of a beating. It has a strong regeneration capability and a high speed, so should it survive a hit, it should run out of harm's way, repair itself, and come back with a vengeance. Though more capable in a firefight than bot raiders, it is no match for anti-swarm or riot units and defenses.]],
    helptext_bp    = [[Flash é um veículo agressor. Causa bastante danoe mas n?o poder suportar muito. Tem uma capacidade de regeneraç?o forte e alta velocidade, ent?o se sobreviver um combate deve recuar, se reparar e ent?o atacar novamente. Embora seja mais capaz em uma batalha que robôs agressores, n?o é pareo para unidades ou defesas dispersadoras.]],
    helptext_fr    = [[Le Flash fait beaucoup de dégâts, mais ne peut pas en encaisser énormément. Il dispose cependant de nanobots autoréparateurs lui permettant de se soigner rapidement. Couplé avec sa grande vitesse, celr le rends plus efficace que les Robots pour les rushs. Il est cepandent pas de taille face aux émeutiers et autre défense anti-horde.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 2,
  footprintZ          = 2,
  iconType            = [[vehicleraider]],
  idleAutoHeal        = 16,
  idleTime            = 10,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 50,
  maxDamage           = 320,
  maxSlope            = 18,
  maxVelocity         = 4.2,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK2]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[ARMFLASH]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:emg_shells_l]],
      [[custom:flashmuzzle1]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 360,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  trackOffset         = 5,
  trackStrength       = 4,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 22,
  turninplace         = 0,
  turnInPlace         = 0,
  turnRate            = 692,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[EMGX]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    EMGX = {
      name                    = [[Twin Pulse MGs]],
      alphaDecay              = 0.1,
      areaOfEffect            = 8,
      burst                   = 3,
      burstrate               = 0.1,
      colormap                = [[1 0.95 0.4 1   1 0.95 0.4 1    0 0 0 0.01    1 0.7 0.2 1]],
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 11.06,
        planes  = 11.06,
        subs    = 0.553,
      },

      endsmoke                = [[0]],
      explosionGenerator      = [[custom:EMG_HIT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      intensity               = 0.7,
      interceptedByShieldType = 1,
      lineOfSight             = true,
      noGap                   = false,
      noSelfDamage            = true,
      range                   = 180,
      reloadtime              = 0.31,
      renderType              = 4,
      rgbColor                = [[1 0.95 0.4]],
      separation              = 1.5,
      size                    = 1.75,
      sizeDecay               = 0,
      soundStart              = [[flashemg]],
      sprayAngle              = 1180,
      stages                  = 10,
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
      description      = [[Wreckage - Flash]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 320,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[ARMFLASH_DEAD]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Flash]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 320,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 40,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 40,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Flash]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 320,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 20,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 20,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armflash = unitDef })
