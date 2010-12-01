unitDef = {
  unitname            = [[corroy]],
  name                = [[Enforcer]],
  description         = [[Missile Frigate (Skirmisher/Riot)]],
  acceleration        = 0.039,
  activateWhenBuilt   = true,
  bmcode              = [[1]],
  brakeRate           = 0.115,
  buildAngle          = 16384,
  buildCostEnergy     = 500,
  buildCostMetal      = 500,
  builder             = false,
  buildPic            = [[CORROY.png]],
  buildTime           = 500,
  canAttack           = true,
  canGuard            = true,
  canMove             = true,
  canPatrol           = true,
  canstop             = [[1]],
  category            = [[SHIP]],
  corpse              = [[DEAD]],

  customParams        = {
    description_fr = [[Destroyer Lance-Missile (Support/Anti-Air)]],
    helptext       = [[This Destroyer packs a powerful, long-range missile, useful for bombarding sea and shore targets and destroying aircraft. Beware of subs and Corvettes.]],
    helptext_fr    = [[Le Enforcer embarque deux batteries de missiles: une lourde et longue port?e pour d?truire les navires et les installation c?ti?res, ainsi qu'un batterie longue port?e anti-air. Il est rapide mais peu solide.]],
  },

  defaultmissiontype  = [[Standby]],
  explodeAs           = [[BIG_UNITEX]],
  floater             = true,
  footprintX          = 4,
  footprintZ          = 4,
  iconType            = [[aaship]],
  idleAutoHeal        = 5,
  idleTime            = 1800,
  maneuverleashlength = [[640]],
  mass                = 253,
  maxDamage           = 1800,
  maxVelocity         = 2.8,
  minCloakDistance    = 75,
  minWaterDepth       = 10,
  movementClass       = [[BOAT4]],
  moveState           = 0,
  noAutoFire          = false,
  noChaseCategory     = [[TERRAFORM SATELLITE SUB]],
  objectName          = [[logsiren.s3o]],
  scale               = [[0.6]],
  seismicSignature    = 4,
  selfDestructAs      = [[BIG_UNITEX]],

  sfxtypes            = {

    explosiongenerators = {
      [[custom:MISSILE_EXPLOSION]],
      [[custom:MEDMISSILE_EXPLOSION]],
    },

  },

  side                = [[CORE]],
  sightDistance       = 660,
  smoothAnim          = true,
  steeringmode        = [[1]],
  TEDClass            = [[SHIP]],
  turninplace         = 0,
  turnRate            = 306,
  waterline           = 4,
  workerTime          = 0,

  weapons             = {

    {
      def                = [[MISSILE1]],
      onlyTargetCategory = [[FIXEDWING LAND SINK SHIP SWIM FLOAT GUNSHIP HOVER]],
    },

  },


  weaponDefs          = {

    MISSILE1 = {
      name                    = [[Heavy Multi-Role Guided Missile]],
      areaOfEffect            = 160,
      cegTag                  = [[KBOTROCKETTRAIL]],
      craterBoost             = 1,
      craterMult              = 2,

      damage                  = {
        default = 900,
        subs    = 45,
      },

      edgeEffectiveness       = 0.4,
      fireStarter             = 20,
      flightTime              = 4,
      guidance                = true,
      impulseBoost            = 0,
      impulseFactor           = 0.4,
      interceptedByShieldType = 2,
      lineOfSight             = true,
      model                   = [[TAWF114a]],
      noSelfDamage            = true,
      range                   = 550,
      reloadtime              = 8,
      renderType              = 1,
      selfprop                = true,
      smokedelay              = [[0.01]],
      smokeTrail              = false,
      soundHit                = [[weapon/bomb_hit]],
      soundStart              = [[weapon/missile/banisher_fire]],
      startsmoke              = [[1]],
      startVelocity           = 400,
      tolerance               = 9000,
      tracks                  = true,
      trajectoryHeight        = 0.45,
      turnRate                = 22000,
      turret                  = true,
      weaponAcceleration      = 70,
      weaponTimer             = 5,
      weaponType              = [[MissileLauncher]],
      weaponVelocity          = 400,
    },

  },


  featureDefs         = {

    DEAD  = {
      description      = [[Wreckage - Enforcer]],
      blocking         = false,
      category         = [[corpses]],
      damage           = 1800,
      energy           = 0,
      featureDead      = [[DEAD2]],
      footprintX       = 5,
      footprintZ       = 5,
      height           = [[4]],
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[logsiren_dead.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    DEAD2 = {
      description      = [[Debris - Enforcer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1800,
      energy           = 0,
      featureDead      = [[HEAP]],
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 200,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 200,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },


    HEAP  = {
      description      = [[Debris - Enforcer]],
      blocking         = false,
      category         = [[heaps]],
      damage           = 1800,
      energy           = 0,
      featurereclamate = [[SMUDGE01]],
      footprintX       = 4,
      footprintZ       = 4,
      hitdensity       = [[100]],
      metal            = 100,
      object           = [[debris4x4c.s3o]],
      reclaimable      = true,
      reclaimTime      = 100,
      seqnamereclamate = [[TREE1RECLAMATE]],
      world            = [[All Worlds]],
    },

  },

}

return lowerkeys({ corroy = unitDef })
