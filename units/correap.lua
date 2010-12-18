unitDef = {
  unitname            = [[correap]],
  name                = [[Reaper]],
  description         = [[Assault Tank]],
  acceleration        = 0.0237,
  bmcode              = [[1]],
  brakeRate           = 0.04786,
  buildCostEnergy     = 900,
  buildCostMetal      = 900,
  builder             = false,
  buildPic            = [[correap.png]],
  buildTime           = 900,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Tanque de assalto]],
    description_fr = [[Tank d'Assaut]],
    helptext       = [[A heavy duty battle tank. The Reaper excels at absorbing damage in pitched battles, but its low rate of fire means it is not so good at dealing with swarms, and its heavy armor comes at the price of manuverability.]],
    helptext_bp    = [[Reaper é um tanque de batalha pesado que excede em absorver danos e servir de escudo para unidades mais fracas, mas sua baixa velocidade de disparo e agilidade o tornam pouco eficiente contra grandes grupos de pequenas unidades inimigas.]],
    helptext_fr    = [[Le Reaper est un tank d'assaut lourd. Lourd par le blindage, lourd par les dégâts. La lente cadence de tir de son double canon plasma ne conviendra pas aux situations d'encerclement et aux nuées d'ennemis et son blindage le rends peu maniable.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[tankassault]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 430,
  maxDamage           = 6800,
  maxSlope            = 18,
  maxVelocity         = 2.45,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK4]],
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM FIXEDWING SATELLITE SUB]],
  objectName          = [[correap.s3o]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:LARGE_MUZZLE_FLASH_FX]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 506,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  trackOffset         = 8,
  trackStrength       = 8,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 33,
  turninplace         = 0,
  turnRate            = 364,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[COR_REAP]],
      badTargetCategory  = [[FIXEDWING]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    COR_REAP = {
      name                    = [[Medium Plasma Cannon]],
      areaOfEffect            = 16,
      burst                   = 2,
      burstRate               = 0.2,
      craterBoost             = 0,
      craterMult              = 0,

      damage                  = {
        default = 316,
        planes  = 316,
        subs    = 16.65,
      },

      explosionGenerator      = [[custom:DEFAULT]],
      impactOnly              = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 1,
      noSelfDamage            = true,
      range                   = 360,
      reloadtime              = 4,
      renderType              = 4,
      soundHit                = [[weapon/cannon/reaper_hit]],
      soundStart              = [[weapon/cannon/cannon_fire5]],
      startsmoke              = [[1]],
      turret                  = true,
      weaponType              = [[Cannon]],
      weaponVelocity          = 255,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Reaper]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 7100,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[correap_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Reaper]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 7100,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 360,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 360,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Reaper]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 7100,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 3,
      footprintZ       = 3,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 180,
      object           = [[debris3x3b.s3o]],
      reclaimable      = true,
      reclaimTime      = 180,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ correap = unitDef })
