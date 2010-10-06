unitDef = {
  unitname            = [[armjanus]],
  name                = [[Janus]],
  description         = [[Skirmisher Vehicle]],
  acceleration        = 0.035,
  bmcode              = [[1]],
  brakeRate           = 0.2,
  buildCostEnergy     = 220,
  buildCostMetal      = 220,
  builder             = false,
  buildPic            = [[ARMJANUS.png]],
  buildTime           = 220,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[LAND]],
  corpse              = [[DEAD]],

  customParams        = {
    description_bp = [[Veículo escaramuçador]],
    description_fr = [[V?hicule Tirailleur]],
    helptext       = [[Use the Janus for hit-and-run attacks. Has a long reload time and not too many hit points, and should always be kept at range with the enemy. An arcing projectile allows it to shoot over obstacles and friendly units, such as stumpies.]],
    helptext_bp    = [[Janus é um escaramuçador: Use-o para ataques de bater e correr. Demora para recarregar e n?o é muito resistente, devendo sempre ser mantido a distância do inimigo. Seus projéteis de trajetória curva superam obstáculos.]],
    helptext_fr    = [[Le Janus est un tirailleur, il est utile pour harrasser l'ennemi ? l'aide de son lance roquette. Il tire des roquettes ? t?te chercheuse au dessus des obstacles, mais son temps de rechargement, sa maniabilit? et son faible blindage le rendent vuln?rable aux contre attaques.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  footprintX          = 3,
  footprintZ          = 3,
  iconType            = [[vehicleskirm]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  leaveTracks         = true,
  maneuverleashlength = [[640]],
  mass                = 110,
  maxDamage           = 620,
  maxSlope            = 18,
  maxVelocity         = 2.1,
  maxWaterDepth       = 22,
  minCloakDistance    = 75,
  movementClass       = [[TANK3]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[ARMJANUS]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:JANUSMUZZLE]],
      [[custom:JANUSBACK]],
    },

  },

  side                = [[ARM]],
  sightDistance       = 484,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[TANK]],
  trackOffset         = 3,
  trackStrength       = 6,
  trackStretch        = 1,
  trackType           = [[StdTank]],
  trackWidth          = 24,
  turninplace         = 0,
  turnRate            = 350,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[MISSILE]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    MISSILE = {
      name                    = [[Heavy Missile Battery]],
      areaOfEffect            = 96,
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 300,
        planes  = 300,
        subs    = 15,
      },

      fireStarter             = 70,
      flightTime              = 3.5,
      guidance                = true,
      impulseBoost            = 0.75,
      impulseFactor           = 0.3,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[wep_m_dragonsfang.s3o]],
      noSelfDamage            = true,
      projectiles             = 2,
      range                   = 440,
      reloadtime              = 10,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[.1]],
      smokeTrail              = true,
      soundHit                = [[OTAunit/XPLOSML2]],
      soundHitVolume          = 8,
      soundStart              = [[OTAunit/ROCKLIT1]],
      soundStartVolume        = 7,
      startsmoke              = [[1]],
      startVelocity           = 190,
      tracks                  = true,
      trajectoryHeight        = 0.4,
      turnRate                = 22000,
      turret                  = true,
      weaponAcceleration      = 100,
      weaponTimer             = 3,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 190,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Janus]],
      blocking         = true,
      category         = [[corpses]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[DEAD2]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[20]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[ARMJANUS_DEAD]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Janus]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 88,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 88,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Janus]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 620,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 2,
      footprintZ       = 2,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 44,
      object           = [[debris2x2b.s3o]],
      reclaimable      = true,
      reclaimTime      = 44,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ armjanus = unitDef })
